#!/bin/sh
# 等号两侧不要有空格

# 服务布署在哪个节点，不要修改
DEST_IP=$1
# 服务布署在哪个目录，不要修改
DEST_DIR=/usr/local/mysql
# 服务包名称，不要修改
APP_NAME=mysql-5.7.28.tar.gz
# 从哪个服务器获取服务包，不要修改
SOURCE_DIR=release/3rdparty/mysql
# 从哪个目录获取服务包，不要修改
SOURCE_IP=47.95.231.203
# mysql 连接密码，不要修改
PASSWD=szyx123456

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
        echo -e "$TIMESTAMP - \e[00;31mparameter not found, sh mysql.install.sh <ip>\e[00m"
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

    if [[ ! -f "mysqld.service" ]]; then
        echo -e "$TIMESTAMP - mysqld.service not found in local, downloading ..."
        wget http://$SOURCE_IP:8082/shared/devops/3rdparty/mysqld.service
    else
        echo -e "$TIMESTAMP - mysqld.service is found ..."
    fi

    chmod 755 *.sh

    cd $CURRENT_DIR
}

function install_local() {
    echo -e "$TIMESTAMP - remove mariadb ..."
    rpm -e --nodeps mariadb-libs >/dev/null 2>&1

    echo -e "$TIMESTAMP - add user and group ..."
    groupadd mysql >/dev/null 2>&1
    useradd -g mysql mysql >/dev/null 2>&1

    echo -e "$TIMESTAMP - extracting files ..."
    cd $CURRENT_DIR
    # do not remove mysql folder, it is danger for mysql data
    # rm $DEST_DIR -fr

    if [[ -d "$DEST_DIR" ]]; then
        echo -e "$TIMESTAMP - \e[00;31m[ERROR] mysql is installed at /usr/local/mysql/, please backup data and remove this folder!\e[00m"
        exit -1
    fi
    mkdir $DEST_DIR
    tar -xf ./pkg/$APP_NAME -C $DEST_DIR
    chown -R mysql:mysql $DEST_DIR
    cd $DEST_DIR/mysql*
    echo -e "$TIMESTAMP - MYSQL_HOME=`pwd`"
    ln -sf `pwd`/bin/mysql /usr/bin/mysql

    # set auto start when server start
    echo -e "$TIMESTAMP - mysql starting ...\n"
    pkill mysqld
    cp $CURRENT_DIR/mod/mysqld.service /usr/lib/systemd/system/
    cp -f $DEST_DIR/mysql-5.7.28/conf/my.cnf /etc/
    systemctl daemon-reload
    systemctl enable mysqld.service
    systemctl start mysqld.service
    sleep 1s
    systemctl status mysqld.service

    if [[ "$?" == "0" ]]; then
        echo -e "$TIMESTAMP - \e[00;32mmysql installed successfully!\e[00m"
    else
        echo -e "$TIMESTAMP - \e[00;31mmysql installed failed!\e[00m"
        rm -fr $DEST_DIR
    fi

    # ./bin/mysqld_safe --initialize --user=mysql --basedir=/usr/local/mysql/mysql-5.7.28 --datadir=/usr/local/mysql/mysql-5.7.28/data

    echo -e "\n$TIMESTAMP - please use command: 'mysql -h $DEST_IP -uroot -p$PASSWD' to verify..."

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

    ssh root@$DEST_IP -p$PORT " 
        mkdir tmp -pv
    "
    echo -e "$TIMESTAMP - copy $APP_NAME to $DEST_IP"
    scp ./pkg/$APP_NAME ./mod/mysqld.service root@$DEST_IP:/root/tmp

    ssh root@$DEST_IP -p$PORT "
        echo -e \"$TIMESTAMP - remove mariadb ...\"
        rpm -e --nodeps mariadb-libs

        echo -e \"$TIMESTAMP - add user and group ...\"
        groupadd mysql >/dev/null 2>&1
        useradd -g mysql mysql >/dev/null 2>&1

        echo -e "$TIMESTAMP - extracting files ..."
        cd tmp
        
        # do not remove mysql folder, it is danger for mysql data
        # rm $DEST_DIR -fr

        if [[ -d \"$DEST_DIR\" ]]; then
            echo -e \"$TIMESTAMP - \e[00;31m[ERROR] mysql is installed at /usr/local/mysql/, please backup data and remove this folder!\e[00m\"
            exit -1
        fi

        mkdir $DEST_DIR
        tar -xf $APP_NAME -C $DEST_DIR
        chown -R mysql:mysql $DEST_DIR
        cd $DEST_DIR/mysql*
        echo -e \"$TIMESTAMP - MYSQL_HOME=\`pwd\`\"
        
        ln -sf \`pwd\`/bin/mysql /usr/bin/mysql

        # set auto start when server start
        echo -e \"$TIMESTAMP - mysql starting ...\n\"
        pkill mysqld
        cp /root/tmp/mysqld.service /usr/lib/systemd/system/
        cp -f $DEST_DIR/mysql-5.7.28/conf/my.cnf /etc/
        systemctl daemon-reload
        systemctl enable mysqld.service
        systemctl start mysqld.service
        sleep 1s
        systemctl status mysqld.service

        if [[ \"\$?\" == \"0\" ]]; then
            echo -e \"$TIMESTAMP - \e[00;32mmysql installed successfully!\e[00m\"
        else
            echo -e \"$TIMESTAMP - \e[00;31mmysql installed failed!\e[00m\"
            rm -fr $DEST_DIR
        fi

        echo -e \"\n$TIMESTAMP - please use command: 'mysql -h $DEST_IP -uroot -p$PASSWD' to verify...\"

        exit
    "

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

