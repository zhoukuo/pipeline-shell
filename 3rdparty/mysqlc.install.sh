#!/bin/sh
# 等号两侧不要有空格

# 服务布署在哪个节点，不要修改
DEST_IP=$1
# 服务布署在哪个目录，不要修改
DEST_DIR=/usr/bin
# 服务包名称，不要修改
APP_NAME=mysql
# 从哪个服务器获取服务包，不要修改
SOURCE_DIR=release/3rdparty/mysql
# 从哪个目录获取服务包，不要修改
SOURCE_IP=47.95.231.203

USER=`whoami`
CURRENT_DIR=`pwd`
TIMESTAMP=`date +"%Y/%m/%d %H:%M:%S"`


function verify_user() {
    echo -e "$TIMESTAMP - verify user ..."; 
    if [[ "$USER" != "root" ]]; then
        echo -e "$TIMESTAMP - \e[00;31mplease run as root user!\e[00m"
        exit -1
    fi
}

function verify_parameter() {
    echo -e "$TIMESTAMP - verify parameter ..."
    if [[ "$DEST_IP" == "" ]]; then
        echo -e "$TIMESTAMP - \e[00;31mparameter not found, source mysqlc.install.sh <ip>\e[00m"
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

function get_mod() {
    mkdir $CURRENT_DIR/mod -pv
    cd $CURRENT_DIR/mod

    if [[ ! -f "freelogin.sh" ]]; then
        echo -e "$TIMESTAMP - freelogin.sh not found in local, downloading ..."
        wget http://$SOURCE_IP:8082/shared/devops/utils/freelogin.sh
    else
        echo -e "$TIMESTAMP - freelogin.sh is found ..."
    fi

    chmod 755 *.sh

    cd $CURRENT_DIR
}

function install_local() {
    cd $CURRENT_DIR

    cp -f ./pkg/mysql $DEST_DIR
    cd $DEST_DIR
    chmod 755 mysql

    cd $CURRENT_DIR
}

function install_remote() {
    cd $CURRENT_DIR
    
    ./mod/freelogin.sh $DEST_IP

    #check PORT
    ssh -q -o ConnectTimeout=3 root@$DEST_IP -p22222 "exit"
    if [ "$?" == "0" ]; then
        PORT=22222
    else
        PORT=22
    fi
    echo "$TIMESTAMP - ssh PORT:$PORT"

    echo -e "$TIMESTAMP - copy $APP_NAME to $DEST_IP"
    scp ./pkg/$APP_NAME root@$DEST_IP:$DEST_DIR
    chmod 755 /usr/bin/mysql

    cd $CURRENT_DIR
}

function install_pkg() {
    if [[ $DEST_IP == "127.0.0.1" ]]; then
        echo -e "$TIMESTAMP - deploy to localhost ..."
        install_local
    else
        echo -e "$TIMESTAMP - deploy to $DEST_IP ..."
        install_remote
    fi
}

function main() {
    verify_user
    verify_parameter
    get_pkg
    get_mod
    install_pkg
}

main
