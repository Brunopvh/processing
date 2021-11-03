#!/usr/bin/env bash
#
#======================================================================#
# Este script instala o IDE processing em sistemas Linux.
# Testado no Debian 11 - bash 5.1.4
#
#======================================================================#
# REQUERIMENTOS:
#     Gnu wget: sudo apt install wget -y (Sistemas Debian)
#
#======================================================================#
#
# https://processing.org/
#
# Versão 4:
#    https://github.com/processing/processing4/releases/download/processing-1276-4.0b1/processing-4.0b1-linux64.tgz
#
# Versão 3:
#    https://github.com/processing/processing/releases/download/processing-0270-3.5.4/processing-3.5.4-linux64.tgz
# 
#  
#======================================================================#
# Passos para instalar o IDE Processing.
#
# 0 - Instalar o JDK
# 1 - Baixar o pacote de instalação (Linux).
# 2 - Descompactar o pacote.
# 3 - Executar o instalador.
#
#======================================================================#
#
clear

[[ $(id -u) == 0 ]] && {
	echo -e "[ERRO] você não pode ser o 'root'. Para prosseguir EXECUTE sem sudo."
	exit 1
}


__author__='Bruno Chaves'
__version__='0.1.2'
__appname__='processing_installer'

readonly __script__=$(readlink -f "$0")
readonly app_dir=$(dirname "$__script__")
#readonly URL_PROCESSING='https://github.com/processing/processing4/releases/download/processing-1276-4.0b1/processing-4.0b1-linux64.tgz'
#readonly processing_version='4.0-beta'
readonly URL_PROCESSING='https://github.com/processing/processing/releases/download/processing-0270-3.5.4/processing-3.5.4-linux64.tgz'
readonly processing_version='3.5.4'


# Diretório destino para instalação /opt/processing OU ~/.local/share
#readonly INSTALL_DIR='/opt/processing'
readonly INSTALL_DIR=~/.local/share/processing-"${processing_version}"
readonly CACHE_DIR=~/.cache/"$__appname__" # Cache do Usuário.
readonly CACHE_FILE="$CACHE_DIR/$(basename $URL_PROCESSING)" # Caminho completo do arquivo baixado.
readonly tmp_dir=$(mktemp --directory) # Diretório para descompressão do arquivo. 
readonly workdir=$(pwd)




function print_line()
{
	# Imprime um linha que ocupa todo o terminal.
    if [[ -z $1 ]]; then
	    printf "%$(tput cols)s\n" | tr ' ' '-'
	else
	    printf "%$(tput cols)s\n" | tr ' ' "$1"
	fi
}

function usage()
{
cat << EOF
   Use: 
     $__script__             Instala o IDE Processing na versão ${processing_version}.
     $__script__ uninstall   Desinstala o IDE Processing.
     $__script__ -h|--help   Mostra ajuda.
EOF

	return 0
}

function is_admin()
{
	print_line
	echo -en "Checando se você é Admin "
	if [[ $(sudo id -u) == 0 ]]; then
		echo 'OK'
		return 0
	else
		echo 'ERRO'
		return 1
	fi
}



function download_file()
{
	
	if [[ ! -x $(command -v wget) ]]; then
		echo -e "Nescessário instalar o wget para prosseguir"
		sudo apt install wget
	fi


	if [[ -f "$CACHE_FILE" ]]; then
		echo -e "Arquivo já baixado em cache ... $CACHE_FILE"
		return 0
	fi

	echo -e "Baixando ... $CACHE_FILE"
	wget "$URL_PROCESSING" -O "$CACHE_FILE"
	return "$?"
}


function check_shasum()
{
	# Verificar a integridade do download com sha256sum.
	echo -en "\033[0;32mV\033[merificando hash [sha256sum] do arquivo ... $CACHE_FILE "

	local ORIGINAL_HASH='ded445069db3c6fc384fe4da89ca7aa7d0a4bd2536c5aa8de3fa4e115de3025b'
	local pkg_hash=$(sha256sum "$CACHE_FILE" | cut -d ' ' -f 1)

	if [[ "$ORIGINAL_HASH" != "$pkg_hash" ]]; then
		echo -e "ERRO"
		return 1
	fi
	echo -e "\033[0;33mOK\033[m"
	return 0
}



function unpack()
{
	# Descompactar o pacote de instalação em $temp_dir.
	# $1 = caminho completo do pacote tgz.

	echo -e "Entrando no diretório ... $tmp_dir"
	cd $tmp_dir
	echo -e "Descompactando ... $CACHE_FILE"
	tar -zxvf "$CACHE_FILE" -C "$tmp_dir" 1> /dev/null || return 1
	return 0
}


function install_jdk()
{
	# Instalar o jdk em sistemas Linux. Atualmente com suporte 
	# apenas para sistemas baseados em Debian.
	# 
	echo -e "Instalando ... default-jdk"
	
	if [[ -f /etc/debian_version ]]; then
		sudo apt install default-jdk 
	elif [[ -f /etc/fedora_version ]]; then
		return 1
	else
		return 1
	fi

	print_line
	return 0
}


function uninstall_processing()
{
	echo -en "Deseja apagar o diretório ... $INSTALL_DIR [s/N]? : "
	read -n 1 -t 30 yesno
	echo

	[[ ${yesno,,} == 's' ]] || {
		echo -e "Abortando ..."
		return 1
	}

	echo -e "Executando ... $INSTALL_DIR/uninstall.sh"
	if [[ ! -w "$INSTALL_DIR" ]]; then
		sudo "${INSTALL_DIR}/uninstall.sh"
		sudo rm -rf "$INSTALL_DIR"
	else
		"${INSTALL_DIR}/uninstall.sh"
		rm -rf "$INSTALL_DIR"
	fi
}



function install_processing()
{

	cd $tmp_dir
	mv $(ls -d processing*) processing
	cd ./processing
	echo -e "Copiando processing para $INSTALL_DIR"
	mkdir -p "$INSTALL_DIR"

	[[ ! -d "$INSTALL_DIR" ]] && {
		echo -e "(install_processing) ERRO ... diretório de instalação não encontrado."
		return 1
	}

	if [[ ! -w "$INSTALL_DIR" ]]; then
		sudo cp -R -u * "$INSTALL_DIR"/ 1> /dev/null
		echo -e "Executando ... ${INSTALL_DIR}/install.sh"
		sudo "${INSTALL_DIR}/install.sh"
	else
		cp -R -u * "$INSTALL_DIR"/ 1> /dev/null
		echo -e "Executando ... ${INSTALL_DIR}/install.sh"
		"${INSTALL_DIR}/install.sh"
	fi
}


function main()
{
	case "$1" in 
		-h|--help) usage; return 0;;
		uninstall) uninstall_processing; return 0;;
	esac

	is_admin || return 1
	install_jdk || return 1	

	[[ -d "$INSTALL_DIR" ]] && {
		echo -e "Processing já instalado em ... $INSTALL_DIR"
		return 0
	}

	mkdir -p "$CACHE_DIR"
	download_file || return 1
	check_shasum || return 1
	unpack || return 1
	install_processing || return 1
	return 0
}



main "$@"
rm -rf "$tmp_dir"
cd "$workdir"
