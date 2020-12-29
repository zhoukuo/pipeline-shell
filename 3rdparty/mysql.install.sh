#!/bin/sh
# 等号两侧不要有空格

VERSION=5.7.31
# 服务布署在哪个节点，不要修改
DEST_IP=$1
# 服务布署在哪个目录，不要修改
DEST_DIR=/usr/local/mysql
# 服务包名称，不要修改
APP_NAME=mysql-${VERSION}.tar.gz
# 从哪个服务器获取服务包，不要修改
SOURCE_DIR=release/3rdparty/mysql
# 从哪个目录获取服务包，不要修改
SOURCE_IP=`cat license | grep repo.ip | awk -F = '{print $2}'`
PORT=`cat license | grep repo.port | awk -F = '{print $2}'`
APP_IP=`cat license | grep app1.ip | awk -F = '{print $2}'`
HOST=`cat license | grep db.ip | awk -F = '{print $2}'`
# set default value if SOURCE_IP or PORT is null
SOURCE_IP=${SOURCE_IP:=47.95.231.203}
PORT=${PORT:=8082}

# mysql 连接密码，不要修改
PASSWD=szyx123456

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
        echo -e "`date '+%D %T'` - \e[00;31mparameter not found, sh mysql.install.sh <ip>\e[00m"
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

    if [[ ! -f "mysqld.service" ]]; then
        echo -e "`date '+%D %T'` - mysqld.service not found in local, downloading ..."
        wget http://$SOURCE_IP:${PORT}/shared/devops/3rdparty/mysqld.service
    else
        echo -e "`date '+%D %T'` - mysqld.service is found ..."
    fi

    chmod 755 *.sh

    cd $CURRENT_DIR
}

function install_local() {
    echo -e "`date '+%D %T'` - remove mariadb ..."
    rpm -e --nodeps mariadb-libs >/dev/null 2>&1

    echo -e "`date '+%D %T'` - add user and group ..."
    groupadd mysql >/dev/null 2>&1
    useradd -g mysql mysql >/dev/null 2>&1

    echo -e "`date '+%D %T'` - extracting files ..."
    cd $CURRENT_DIR
    # do not remove mysql folder, it is danger for mysql data
    # rm $DEST_DIR -fr

    if [[ -d "$DEST_DIR" ]]; then
        echo -e "`date '+%D %T'` - \e[00;31m[ERROR] mysql is installed at /usr/local/mysql/, please backup data and remove this folder!\e[00m"
        exit -1
    fi
    mkdir $DEST_DIR
    tar -xf ./pkg/$APP_NAME -C $DEST_DIR
    chown -R mysql:mysql $DEST_DIR
    cd $DEST_DIR/mysql*
    echo -e "`date '+%D %T'` - MYSQL_HOME=`pwd`"
    ln -sf `pwd`/bin/mysql /usr/bin/mysql

    # set auto start when server start
    echo -e "`date '+%D %T'` - mysql starting ...\n"
    pkill mysqld
    /bin/cp $CURRENT_DIR/mod/mysqld.service /usr/lib/systemd/system/
    mv $DEST_DIR/mysql-${VERSION}/conf/my.cnf /etc/
    systemctl daemon-reload
    systemctl enable mysqld.service
    systemctl start mysqld.service
    sleep 3s
    systemctl status mysqld.service

    if [[ "$?" == "0" ]]; then
        echo -e "`date '+%D %T'` - \e[00;32mmysql installed successfully!\e[00m"
        # set remote access
        mysql -h $DEST_IP -uroot -p$PASSWD -e "use mysql;update user set host = '${APP_IP}' where host = '%';GRANT ALL PRIVILEGES ON *.* TO 'root'@'${HOST}' IDENTIFIED BY 'szyx123456' WITH GRANT OPTION;flush privileges;"
    else
        systemctl start mysqld.service
        echo "second time starting ..."
        sleep 3s
        systemctl status mysqld.service

        if [[ "$?" == "0" ]]; then
            echo -e "`date '+%D %T'` - \e[00;32mmysql installed successfully!\e[00m"
            # set remote access
            mysql -h $DEST_IP -uroot -p$PASSWD -e "use mysql;update user set host = '${APP_IP}' where host = '%';GRANT ALL PRIVILEGES ON *.* TO 'root'@'${HOST}' IDENTIFIED BY 'szyx123456' WITH GRANT OPTION;flush privileges;"
        else
            echo -e "`date '+%D %T'` - \e[00;31mmysql installed failed!\e[00m"
            rm -fr $DEST_DIR
        fi
    fi

    # ./bin/mysqld_safe --initialize --user=mysql --basedir=/usr/local/mysql/mysql-${VERSION} --datadir=/usr/local/mysql/mysql-${VERSION}/data

    echo -e "\n`date '+%D %T'` - please use command: 'mysql -h $HOST -uroot -p$PASSWD' to verify..."

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

    ssh root@$DEST_IP -p$port " 
        mkdir tmp -pv
    "
    echo -e "`date '+%D %T'` - copy $APP_NAME to $DEST_IP"
    scp ./pkg/$APP_NAME ./mod/mysqld.service root@$DEST_IP:/root/tmp

    ssh root@$DEST_IP -p$port "
        echo -e \"`date '+%D %T'` - remove mariadb ...\"
        rpm -e --nodeps mariadb-libs

        echo -e \"`date '+%D %T'` - add user and group ...\"
        groupadd mysql >/dev/null 2>&1
        useradd -g mysql mysql >/dev/null 2>&1

        echo -e "`date '+%D %T'` - extracting files ..."
        cd tmp
        
        # do not remove mysql folder, it is danger for mysql data
        # rm $DEST_DIR -fr

        if [[ -d \"$DEST_DIR\" ]]; then
            echo -e \"`date '+%D %T'` - \e[00;31m[ERROR] mysql is installed at /usr/local/mysql/, please backup data and remove this folder!\e[00m\"
            exit -1
        fi

        mkdir $DEST_DIR
        tar -xf $APP_NAME -C $DEST_DIR
        chown -R mysql:mysql $DEST_DIR
        cd $DEST_DIR/mysql*
        echo -e \"`date '+%D %T'` - MYSQL_HOME=\`pwd\`\"
        
        ln -sf \`pwd\`/bin/mysql /usr/bin/mysql

        # set auto start when server start
        echo -e \"`date '+%D %T'` - mysql starting ...\n\"
        pkill mysqld
        /bin/cp /root/tmp/mysqld.service /usr/lib/systemd/system/
        /bin/cp $DEST_DIR/mysql-${VERSION}/conf/my.cnf /etc/
        systemctl daemon-reload
        systemctl enable mysqld.service
        systemctl start mysqld.service
        sleep 1s
        systemctl status mysqld.service

        if [[ \"\$?\" == \"0\" ]]; then
            echo -e \"`date '+%D %T'` - \e[00;32mmysql installed successfully!\e[00m\"
            # set remote access
            mysql -h $DEST_IP -uroot -p$PASSWD < \"use mysql;update user set host = '${APP_IP}' where host = '%';flush privileges;\"
        else
            echo -e \"`date '+%D %T'` - \e[00;31mmysql installed failed!\e[00m\"
            rm -fr $DEST_DIR
        fi

        echo -e \"\n`date '+%D %T'` - please use command: 'mysql -h $DEST_IP -uroot -p$PASSWD' to verify...\"

        exit
    "

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
