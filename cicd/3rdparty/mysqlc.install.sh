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
SOURCE_IP=`cat license | grep repo.ip | awk -F = '{print $2}'`
PORT=`cat license | grep repo.port | awk -F = '{print $2}'`
# set default value if SOURCE_IP or PORT is null
SOURCE_IP=${SOURCE_IP:=47.95.231.203}
PORT=${PORT:=8082}

USER=`whoami`
CURRENT_DIR=`pwd`



function verify_user() {
    echo -e "`date '+%D %T'` - verify user ..."; 
    if [[ "$USER" != "root" ]]; then
        echo -e "`date '+%D %T'` - \e[00;31mplease run as root user!\e[00m"
        exit -1
    fi
}

function verify_parameter() {
    echo -e "`date '+%D %T'` - verify parameter ..."
    if [[ "$DEST_IP" == "" ]]; then
        echo -e "`date '+%D %T'` - \e[00;31mparameter not found, source mysqlc.install.sh <ip>\e[00m"
        exit -1
    fi
}

function get_pkg() {
    mkdir $CURRENT_DIR/pkg -pv
    cd $CURRENT_DIR/pkg

    if [[ ! -f "$APP_NAME" ]]; then
        echo -e "`date '+%D %T'` - $APP_NAME not found in local, downloading ..."
        wget http://$SOURCE_IP:${PORT}/shared/$SOURCE_DIR/$APP_NAME
    else
        echo -e "`date '+%D %T'` - $APP_NAME is found, install from local ..."
    fi

    cd $CURRENT_DIR
}

function get_mod() {
    mkdir $CURRENT_DIR/mod -pv
    cd $CURRENT_DIR/mod

    if [[ ! -f "freelogin.sh" ]]; then
        echo -e "`date '+%D %T'` - freelogin.sh not found in local, downloading ..."
        wget http://$SOURCE_IP:${PORT}/shared/devops/utils/freelogin.sh
    else
        echo -e "`date '+%D %T'` - freelogin.sh is found ..."
    fi

    chmod 755 *.sh

    cd $CURRENT_DIR
}

function install_local() {
    cd $CURRENT_DIR

    /bin/cp ./pkg/mysql $DEST_DIR
    cd $DEST_DIR
    chmod 755 mysql

    cd $CURRENT_DIR
}

function install_remote() {
    cd $CURRENT_DIR
    
    ./mod/freelogin.sh $DEST_IP

    #check port
    ssh -q -o ConnectTimeout=3 root@$DEST_IP -p22222 "exit"
    if [ "$?" == "0" ]; then
        port=22222
    else
        port=22
    fi
    echo "`date '+%D %T'` - ssh port:$port"

    echo -e "`date '+%D %T'` - copy $APP_NAME to $DEST_IP"
    scp ./pkg/$APP_NAME root@$DEST_IP:$DEST_DIR
    chmod 755 /usr/bin/mysql

    cd $CURRENT_DIR
}

function install_pkg() {
    if [[ $DEST_IP == "127.0.0.1" ]]; then
        echo -e "`date '+%D %T'` - deploy to localhost ..."
        install_local
    else
        echo -e "`date '+%D %T'` - deploy to $DEST_IP ..."
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
