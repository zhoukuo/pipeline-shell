#!/bin/sh
# 等号两侧不要有空格

# 服务布署在哪个节点，不要修改
DEST_IP=$1
# 服务布署在哪个目录，不要修改
DEST_DIR=/usr/local/redis
# 服务包名称，不要修改
APP_NAME=redis-6.0.9.tar.gz
# 从哪个服务器获取服务包，不要修改
SOURCE_DIR=release/3rdparty/redis
# 从哪个目录获取服务包，不要修改
SOURCE_IP=`cat license | grep repo.ip | awk -F = '{print $2}'`
PORT=`cat license | grep repo.port | awk -F = '{print $2}'`
HOST=`cat license | grep db.ip | awk -F = '{print $2}'`
# set default value if SOURCE_IP or PORT is null
SOURCE_IP=${SOURCE_IP:=47.95.231.203}
PORT=${PORT:=8082}
HOST=${HOST:=0.0.0.0}

# redis 连接密码，不要修改
PASSWD=szyx123456
RPORT=9736

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
        echo -e "`date '+%D %T'` - \e[00;31mparameter not found, sh redis.install.sh <ip>\e[00m"
        exit -1
    fi
}

function get_pkg() {
    mkdir $CURRENT_DIR/pkg -pv
    cd $CURRENT_DIR/pkg

    if [[ ! -f "$APP_NAME" ]]; then
        echo -e "`date '+%D %T'` - $APP_NAME not found in local, downloading ..."
        wget http://$SOURCE_IP:$PORT/shared/$SOURCE_DIR/$APP_NAME
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
        wget http://$SOURCE_IP:$PORT/shared/devops/utils/freelogin.sh
    else
        echo -e "`date '+%D %T'` - freelogin.sh is found ..."
    fi

    if [[ ! -f "redis.service" ]]; then
        echo -e "`date '+%D %T'` - redis.service not found in local, downloading ..."
        wget http://$SOURCE_IP:$PORT/shared/devops/3rdparty/redis.service
    else
        echo -e "`date '+%D %T'` - redis.service is found ..."
    fi

    chmod 755 *.sh

    cd $CURRENT_DIR
}

function install_local() {
    cd $CURRENT_DIR
    rm $DEST_DIR -fr
    mkdir $DEST_DIR
    tar -xf ./pkg/$APP_NAME -C $DEST_DIR
    cd $DEST_DIR/redis*
    echo -e "`date '+%D %T'` - REDIS_HOME=`pwd`"
    ln -sf `pwd`/redis-cli /usr/bin/redis-cli

    # security： bind local ip
    sed -i "s/# bind 127.0.0.1/bind ${HOST}/" ./redis.conf
    
    # set auto start when server start
    echo -e "`date '+%D %T'` - redis starting ...\n"
    PID=`ps -ef |grep -v 'grep' |grep redis-server |awk '{print $2}'`
    pkill -g $PID >/dev/null 2>&1
    /bin/cp $CURRENT_DIR/mod/redis.service /usr/lib/systemd/system/
    systemctl daemon-reload
    systemctl enable redis.service
    systemctl start redis.service
    sleep 2s
    systemctl status redis.service

    if [[ "`./redis-cli -h ${HOST} -a ${PASSWD} -p ${RPORT} ping`" == "PONG" ]]; then
        echo -e "`date '+%D %T'` - \e[00;32mredis installed successfully!\e[00m"
    else
        echo -e "`date '+%D %T'` - \e[00;31mredis installed failed!\e[00m"
    fi

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
    scp ./pkg/$APP_NAME ./mod/redis.service root@$DEST_IP:/root/tmp

    ssh root@$DEST_IP -p$port "
        cd tmp
        rm $DEST_DIR -fr
        mkdir $DEST_DIR
        tar -xf $APP_NAME -C $DEST_DIR
        cd $DEST_DIR/redis*
        echo -e \"`date '+%D %T'` - REDIS_HOME=\`pwd\`\"
        ln -sf \`pwd\`/redis-cli /usr/bin/redis-cli

        # security： bind local ip
        sed -i "s/# bind 127.0.0.1/bind ${HOST}/" ./redis.conf
    
        # set auto start when server start
        echo -e \"`date '+%D %T'` - redis starting ...\n\"
        PID=\`ps -ef |grep -v 'grep' |grep redis-server |awk '{print $2}'\`
        pkill -g $PID >/dev/null 2>&1
        /bin/cp /root/tmp/redis.service /usr/lib/systemd/system/
        systemctl daemon-reload
        systemctl enable redis.service
        systemctl start redis.service
        systemctl status redis.service

        if [[ \"\`./redis-cli -a ${PASSWD} -p ${RPORT} ping\`\" == \"PONG\" ]]; then
            echo -e \"`date '+%D %T'` - \e[00;32mredis installed successfully!\e[00m\"
        else
            echo -e \"`date '+%D %T'` - \e[00;31mredis installed failed!\e[00m\"
        fi
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
