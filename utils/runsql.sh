#!/bin/sh
# 等号两侧不要有空格

DEST_IP=$1
USER=$2
PASSWD=$3
SQL=$4

SOURCE_IP=47.95.231.203
CURRENT_USER=`whoami`
CURRENT_DIR=`pwd`
TIMESTAMP=`date +"%Y/%m/%d %H:%M:%S"`


function verify_user() {
    echo -e "$TIMESTAMP - verify user ..."; 
    if [[ "$CURRENT_USER" != "root" ]]; then
        echo -e "$TIMESTAMP - \e[00;31mplease run as root user!\e[00m"
        exit -1
    fi
}

function verify_parameter() {
    echo -e "$TIMESTAMP - verify parameter ..."
    if [[ "$SQL" == "" ]]; then
        echo -e "$TIMESTAMP - \e[00;31mparameter not found, source runsql.sh <ip> <user> <passwd> <sql>\e[00m"
        exit -1
    fi
}

function get_mod() {
    mkdir $CURRENT_DIR/mod -pv
    cd $CURRENT_DIR/mod

    if [[ ! -f "mysqlc.install.sh" ]]; then
        echo -e "$TIMESTAMP - mysqlc.install.sh not found in local, downloading ..."
        wget http://$SOURCE_IP:8082/shared/devops/3rdparty/mysqlc.install.sh
    else
        echo -e "$TIMESTAMP - freelogin.sh is found ..."
    fi

    chmod 755 *.sh

    cd $CURRENT_DIR
}

function get_pkg() {
    mkdir $CURRENT_DIR/pkg -pv
    cd $CURRENT_DIR/pkg

    if [[ ! -f "mysql" ]]; then
        echo -e "$TIMESTAMP - mysql not found in local, downloading ..."
        wget http://$SOURCE_IP:8082/shared/devops/3rdparty/mysql/mysql
    else
        echo -e "$TIMESTAMP - $APP_NAME is found, install from local ..."
    fi
    cd $CURRENT_DIR
}

function run_sql() {
    mysql -h$DEST_IP -u$USER -p$PASSWD < $SQL
    mysql -h$DEST_IP -u$USER -p$PASSWD -e "SHOW DATABASES;"
}

function main() {
    verify_user
    verify_parameter
    get_mod
    get_pkg
    ./mod/mysqlc.install.sh 127.0.0.1
    run_sql
}

main
