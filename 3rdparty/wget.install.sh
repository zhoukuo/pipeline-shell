#!/bin/sh
# 等号两侧不要有空格

# 服务布署在哪个目录，不要修改
DEST_DIR=/usr/bin
# 服务包名称，不要修改
APP_NAME=wget
# 从哪个服务器获取服务包，不要修改
SOURCE_DIR=release/3rdparty/wget
# 从哪个目录获取服务包，不要修改
SOURCE_IP=47.95.231.203

USER=`whoami`
CURRENT_DIR=`pwd`
TIMESTAMP=`date +"%Y/%m/%d %H:%M:%S"`


function verify_version() {
    VERSION=`wget -V |head -1|awk '{print $3}'`
    if [[ $VERSION == "1.20.3" ]]; then
        echo -e "$TIMESTAMP - wget is up to date ..."
        exit 0
    else
        echo -e "$TIMESTAMP - wget will update to version 1.20.3 ..."
    fi
}

function verify_user() {
    echo -e "$TIMESTAMP - verify user ..."; 
    if [[ "$USER" != "root" ]]; then
        echo -e "$TIMESTAMP - \e[00;31mplease run as root user!\e[00m"
        exit -1
    fi
}

function get_pkg() {
    mkdir $CURRENT_DIR/pkg -pv
    cd $CURRENT_DIR/pkg

    if [[ ! -f "$APP_NAME" ]]; then
        echo -e "$TIMESTAMP - $APP_NAME not found in local, downloading ..."
        wget http://$SOURCE_IP:8082/shared/$SOURCE_DIR/$APP_NAME
    else
        echo -e "$TIMESTAMP - $APP_NAME is found, install from local ..."
    fi

    cd $CURRENT_DIR
}

function install_local() {
    cd $CURRENT_DIR
    cp -f pkg/wget $DEST_DIR
    cd $DEST_DIR
    chmod 755 wget
    pwd
    ls -l wget

    cd $CURRENT_DIR
}

function main() {
    verify_version
    verify_user
    get_pkg
    install_local
}

main
