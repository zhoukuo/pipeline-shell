#!/bin/sh

PARAM1=$1
DEST_IP=127.0.0.1
REDIS=redis-3.0.7.tar.gz
MYSQL=mysql-5.7.28.tar.gz

SOURCE_IP=`cat license | grep repo.ip | awk -F = '{print $2}'`
PORT=`cat license | grep repo.port | awk -F = '{print $2}'`

# set default value if SOURCE_IP or PORT is null
SOURCE_IP=${SOURCE_IP:=47.95.231.203}
PORT=${PORT:=8082}

CURRENT_DIR=`pwd`
TIMESTAMP=`date +"%Y/%m/%d %H:%M:%S"`


function install_wget(){
    cd $CURRENT_DIR
    mkdir -pv mod
    if [[ ! -f "./mod/wget.install.sh" ]]; then
        wget http://$SOURCE_IP:$PORT/shared/devops/3rdparty/wget.install.sh -O ./mod/wget.install.sh
        chmod 755 ./mod/wget.install.sh
    fi
    ./mod/wget.install.sh
    cd $CURRENT_DIR
}

function download() {
    mkdir $CURRENT_DIR/mod -pv
    cd $CURRENT_DIR/mod
    wget -N http://$SOURCE_IP:$PORT/shared/devops/3rdparty/wget.install.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/utils/freelogin.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/utils/disable.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/3rdparty/redis.install.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/3rdparty/mysql.install.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/3rdparty/redis.service
    wget -N http://$SOURCE_IP:$PORT/shared/devops/3rdparty/mysqld.service
    chmod 755 *.sh
    mkdir $CURRENT_DIR/pkg -pv
    cd $CURRENT_DIR/pkg
    wget -N http://$SOURCE_IP:$PORT/shared/release/3rdparty/wget/wget
    wget -N http://$SOURCE_IP:$PORT/shared/release/3rdparty/redis/$REDIS
    wget -N http://$SOURCE_IP:$PORT/shared/release/3rdparty/mysql/$MYSQL

    mkdir $CURRENT_DIR/sql -pv
    cd $CURRENT_DIR/sql
    wget -N http://$SOURCE_IP:$PORT/shared/release/hospital-in/ywx/latest/sql/ywx-ddl-full.sql
    wget -N http://$SOURCE_IP:$PORT/shared/release/hospital-in/ywx/latest/sql/ywx-dml-full.sql
    wget -N http://$SOURCE_IP:$PORT/shared/release/hospital-in/hospital/latest/sql/hospital-full.sql
    cd $CURRENT_DIR
}

function check_license() {
    # optional
    if [[ ! -f "license" ]]; then
        echo -e "$TIMESTAMP - \e[00;33m[WARNING] license file not found, use default server !!!\e[00m"
    fi
}

function main() {
    install_wget

    # used for offline deploy
    if [[ "$PARAM1" == "-d" ]]; then
        echo -e "$TIMESTAMP - downloading ... "
        download
        exit 0
    fi

    # get latest version if connection is ok
    wget -T3 -t1 http://$SOURCE_IP:$PORT/shared/devops/3rdparty/wget.install.sh -O ./mod/wget.install.sh
    if [[ "$?" == "0" ]]; then
        download
    fi
    
    echo -e "$TIMESTAMP - check license ..."
    check_license

    echo -e "$TIMESTAMP - init linux ..."
    ./mod/disable.sh $DEST_IP

    echo -e "$TIMESTAMP - install redis ..."
    ./mod/redis.install.sh $DEST_IP

    echo -e "$TIMESTAMP - install mysql ..."
    ./mod/mysql.install.sh $DEST_IP

    read -p "do you want init ywx database? (yes/no): " answer
    if [[ "$answer" == "yes" ]]; then
        echo -e "$TIMESTAMP - run sql for ywx ..."
        mysql -h $DEST_IP -uroot -pszyx123456 < ./sql/ywx-ddl-full.sql
        mysql -h $DEST_IP -uroot -pszyx123456 < ./sql/ywx-dml-full.sql
    fi

    read -p "do you want init hospital database? (yes/no): " answer
    if [[ "$answer" == "yes" ]]; then
        echo -e "$TIMESTAMP - run sql for hospital ..."
        mysql -h $DEST_IP -uroot -pszyx123456 < ./sql/hospital-full.sql
    fi
}

main