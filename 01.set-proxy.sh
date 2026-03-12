#!/usr/bin/env bash

WK_DIR=${HOME}/.dotfiles

#------------------------------------------------------
# set for Global Scope
#------------------------------------------------------
set_wsl_options() {
    sudo cp ${WK_DIR}/wsl/wsl.conf /etc/
    sudo sed -i "s/CHANGE_ME/${USER}/g" /etc/wsl.conf
}

set_proxy_info() {
    source ./proxy-info/sds-proxy.info
}

set_cert_for_os() {
    sudo cp ${WK_DIR}/SDS-crt/*.crt /usr/local/share/ca-certificates/
    sudo update-ca-certificates --verbose
}

set_apt_proxy() {
    set_proxy_info
    APT_CONF="/etc/apt/apt.conf.d/05proxy"
    sudo tee ${APT_CONF}> /dev/null<<EOF
Acquire::http::proxy::${SDS_NEXUS_IP} "DIRECT";
Acquire::http::Proxy  "http://${SDS_PROXY_IP}:${SDS_PROXY_PORT}/";
Acquire::https::Proxy "http://${SDS_PROXY_IP}:${SDS_PROXY_PORT}/";
Acquire::ftp::Proxy   "http://${SDS_PROXY_IP}:${SDS_PROXY_PORT}/";
Acquire { https::Verify-Peer false }
EOF
}

set_locale() {
    sudo apt update
    sudo apt install -y locales
    sudo locale-gen en_US.UTF-8
    sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
    source /etc/default/locale
}

set_default_profile() {
    set_proxy_info
    PROFILE_CONF="/etc/profile.d/proxy.sh"
    sudo tee ${PROFILE_CONF}> /dev/null<<EOF
export http_proxy="http://${SDS_PROXY_IP}:${SDS_PROXY_PORT}"
export https_proxy="http://${SDS_PROXY_IP}:${SDS_PROXY_PORT}"
export ftp_proxy="http://${SDS_PROXY_IP}:${SDS_PROXY_PORT}"
export no_proxy="${NO_PROXY}"

export HTTP_PROXY="http://${SDS_PROXY_IP}:${SDS_PROXY_PORT}"
export HTTPS_PROXY="http://${SDS_PROXY_IP}:${SDS_PROXY_PORT}"
export FTP_PROXY="http://${SDS_PROXY_IP}:${SDS_PROXY_PORT}"
export NO_PROXY="${NO_PROXY}"

export WS_PROXY="${HTTP_PROXY}"
export WSS_PROXY="${HTTPS_PROXY}"
EOF
}

set_openssl() {
    local SET_CONF=${WK_DIR}/openssl/openssl.cnf
    local BK_DIR=$(dirname ${SET_CONF})/backup
    local TGT_CONF=/etc/ssl/openssl.cnf

    if [ -f ${TGT_CONF} ] ; then
      cp ${TGT_CONF} ${BK_DIR}/$(basename ${SET_CONF})-$(date +'%Y%m%d-%H%m%S')
      sudo rm ${TGT_CONF}
    fi

    sudo cp ${SET_CONF} ${TGT_CONF}

}

#------------------------------------------------------
# User Settings
#------------------------------------------------------
set_bash() {
    set_proxy_info
    local SET_CONF=${WK_DIR}/bash/bashrc
    local BK_DIR=$(dirname ${SET_CONF})/backup
    local TGT_CONF=${HOME}/.bashrc
    if [ -f ${TGT_CONF} ] ; then
      cp ${TGT_CONF} ${BK_DIR}/$(basename ${SET_CONF})-$(date +'%Y%m%d-%H%m%S')
      rm ${TGT_CONF}
    fi

    ln -s ${SET_CONF} ${TGT_CONF}
}

set_curl() {
    set_proxy_info
    local SET_CONF=${WK_DIR}/curl/curlrc
    local BK_DIR=$(dirname ${SET_CONF})/backup
    local TGT_CONF=${HOME}/.curlrc
    if [ -f ${TGT_CONF} ] ; then
      cp ${TGT_CONF} ${BK_DIR}/$(basename ${SET_CONF})-$(date +'%Y%m%d-%H%m%S')
      rm ${TGT_CONF}
    fi

    tee ${SET_CONF}> /dev/null <<EOF
# cacert=/etc/ssl/certs/ca-certificates.crt
# ciphers DEFAULT#SECLEVEL=1
EOF
    ln -s ${SET_CONF} ${TGT_CONF}
}

set_git() {
    set_proxy_info
    local SET_CONF=${WK_DIR}/git/gitconfig
    local BK_DIR=$(dirname ${SET_CONF})/backup
    local TGT_CONF=${HOME}/.gitconfig
    if [ -f ${TGT_CONF} ] ; then
      cp ${TGT_CONF} ${BK_DIR}/$(basename ${SET_CONF})-$(date +'%Y%m%d-%H%m%S')
      rm ${TGT_CONF}
    fi

    tee ${SET_CONF}> /dev/null <<EOF
[http]
    proxy = http://${SDS_PROXY_IP}:${SDS_PROXY_PORT}
    # sslCAInfo = /etc/ssl/certs/ca-certificates.crt
[core]
    editor = vim
EOF
    ln -s ${SET_CONF} ${TGT_CONF}
}

set_uv() {
    set_proxy_info
    local SET_CONF1=${WK_DIR}/uv/pip.conf
    local SET_CONF2=${WK_DIR}/uv/uv.toml

    local BK_DIR1=$(dirname ${SET_CONF1})/backup
    local BK_DIR2=$(dirname ${SET_CONF2})/backup

    local TGT_CONF1=${HOME}/.config/pip/pip.conf
    local TGT_CONF2=${HOME}/.config/uv/uv.toml

    if [ ! -d `dirname ${TGT_CONF1}` ] ; then
      mkdir -p $(dirname ${TGT_CONF1})
    fi
    if [ ! -d `dirname ${TGT_CONF2}` ] ; then
      mkdir -p $(dirname ${TGT_CONF2})
    fi


    #-------------------------------------------
    # pip.conf for uv
    #-------------------------------------------
    if [ -f ${TGT_CONF1} ] ; then
      cp ${TGT_CONF1} ${BK_DIR1}/$(basename ${SET_CONF1})-$(date +'%Y%m%d-%H%m%S')
      rm ${TGT_CONF1}
    fi

    tee ${SET_CONF1}> /dev/null <<EOF
[global]
proxy = http://${SDS_PROXY_IP}:${SDS_PROXY_PORT}
trusted-host = pypi.python.org pypi.org files.pythonhosted.org
EOF
    ln -s ${SET_CONF1} ${TGT_CONF1}

    #-------------------------------------------
    # uv.conf
    #-------------------------------------------
    if [ -f ${TGT_CONF2} ] ; then
      cp ${TGT_CONF2} ${BK_DIR2}/$(basename ${SET_CONF2})-$(date +'%Y%m%d-%H%m%S')
      rm ${TGT_CONF2}
    fi

    tee ${SET_CONF2}> /dev/null <<EOF
allow-insecure-host = [
"pypi.python.org",
"pypi.org",
"files.pythonhosted.org",
"github.com"
]
EOF
    ln -s ${SET_CONF2} ${TGT_CONF2}

}

set_npm() {
    set_proxy_info
    local SET_CONF=${WK_DIR}/npm/npmrc
    local BK_DIR=$(dirname ${SET_CONF})/backup
    local TGT_CONF=${HOME}/.npmrc

    if [ -f ${TGT_CONF} ] ; then
      cp ${TGT_CONF} ${BK_DIR}/$(basename ${SET_CONF})-$(date +'%Y%m%d-%H%m%S')
      rm ${TGT_CONF}
    fi

    tee ${SET_CONF}> /dev/null <<EOF
https-proxy=http://${SDS_PROXY_IP}:${SDS_PROXY_PORT}
http-proxy=http://${SDS_PROXY_IP}:${SDS_PROXY_PORT}
# cafile=/etc/ssl/certs/ca-certificates.crt
EOF
    ln -s ${SET_CONF} ${TGT_CONF}
}

#------------------------------------------------------
# main
#------------------------------------------------------
set_wsl_options
set_cert_for_os
set_locale
set_openssl
set_apt_proxy
set_default_profile
set_bash
set_curl
set_git
set_uv
set_npm

exit $?
