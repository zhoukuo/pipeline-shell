#!/bin/sh
# 等号两侧不要有空格

DEST_IP=$1
USER=$2
PASSWD=$3
SQL=$4

SOURCE_IP=`cat license | grep repo.ip | awk -F = '{print $2}'`
PORT=`cat license | grep repo.port | awk -F = '{print $2}'`
# set default value if SOURCE_IP or PORT is null
SOURCE_IP=${SOURCE_IP:=47.95.231.203}
PORT=${PORT:=8082}

CURRENT_USER=`whoami`
CURRENT_DIR=`pwd`



function verify_user() {
    echo -e "`date '+%D %T'` - verify user ..."; 
    if [[ "$CURRENT_USER" != "root" ]]; then
        echo -e "`date '+%D %T'` - \e[00;31mplease run as root user!\e[00m"
        exit -1
    fi
}

function verify_parameter() {
    echo -e "`date '+%D %T'` - verify parameter ..."
    if [[ "$SQL" == "" ]]; then
        echo -e "`date '+%D %T'` - \e[00;31mparameter not found, source runsql.sh <ip> <user> <passwd> <sql>\e[00m"
        exit -1
    fi
}

function get_mod() {
    mkdir $CURRENT_DIR/mod -pv
    cd $CURRENT_DIR/mod

    if [[ ! -f "mysqlc.install.sh" ]]; then
        echo -e "`date '+%D %T'` - mysqlc.install.sh not found in local, downloading ..."
        wget http://$SOURCE_IP:${PORT}/shared/devops/3rdparty/mysqlc.install.sh
    else
        echo -e "`date '+%D %T'` - freelogin.sh is found ..."
    fi

    chmod 755 *.sh

    cd $CURRENT_DIR
}

function get_pkg() {
    mkdir $CURRENT_DIR/pkg -pv
    cd $CURRENT_DIR/pkg

    if [[ ! -f "mysql" ]]; then
        echo -e "`date '+%D %T'` - mysql not found in local, downloading ..."
        wget http://$SOURCE_IP:${PORT}/shared/devops/3rdparty/mysql/mysql
    else
        echo -e "`date '+%D %T'` - $APP_NAME is found, install from local ..."
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
