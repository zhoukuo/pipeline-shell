#!/bin/sh
# 等号两侧不要有空格

# 服务布署在哪个节点，不要修改
DEST_IP=$1
# 服务布署在哪个目录，不要修改
DEST_DIR=/usr/local/redis
# 服务包名称，不要修改
APP_NAME=redis-3.0.7.tar.gz
# 从哪个服务器获取服务包，不要修改
SOURCE_DIR=release/3rdparty/redis
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
        echo -e "$TIMESTAMP - \e[00;31mparameter not found, sh redis.install.sh <ip>\e[00m"
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

    if [[ ! -f "redis.service" ]]; then
        echo -e "$TIMESTAMP - redis.service not found in local, downloading ..."
        wget http://$SOURCE_IP:8082/shared/devops/3rdparty/redis.service
    else
        echo -e "$TIMESTAMP - redis.service is found ..."
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
    echo -e "$TIMESTAMP - REDIS_HOME=`pwd`"
    ln -sf `pwd`/src/redis-cli /usr/bin/redis-cli

    
    # set auto start when server start
    echo -e "$TIMESTAMP - redis starting ...\n"
    PID=`ps -ef |grep -v 'grep' |grep redis-server |awk '{print $2}'`
    pkill -g $PID >/dev/null 2>&1
    cp $CURRENT_DIR/mod/redis.service /usr/lib/systemd/system/
    systemctl daemon-reload
    systemctl enable redis.service
    systemctl start redis.service
    systemctl status redis.service

    if [[ "`./redis-cli ping`" == "PONG" ]]; then
        echo -e "$TIMESTAMP - \e[00;32mredis installed successfully!\e[00m"
    else
        echo -e "$TIMESTAMP - \e[00;31mredis installed failed!\e[00m"
    fi

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
    scp ./pkg/$APP_NAME ./mod/redis.service root@$DEST_IP:/root/tmp

    ssh root@$DEST_IP -p$PORT "
        cd tmp
        rm $DEST_DIR -fr
        mkdir $DEST_DIR
        tar -xf $APP_NAME -C $DEST_DIR
        cd $DEST_DIR/redis*
        echo -e \"$TIMESTAMP - REDIS_HOME=\`pwd\`\"
        ln -sf \`pwd\`/src/redis-cli /usr/bin/redis-cli

        # set auto start when server start
        echo -e \"$TIMESTAMP - redis starting ...\n\"
        PID=\`ps -ef |grep -v 'grep' |grep redis-server |awk '{print $2}'\`
        pkill -g $PID >/dev/null 2>&1
        cp /root/tmp/redis.service /usr/lib/systemd/system/
        systemctl daemon-reload
        systemctl enable redis.service
        systemctl start redis.service
        systemctl status redis.service

        if [[ \"\`./redis-cli ping\`\" == \"PONG\" ]]; then
            echo -e \"$TIMESTAMP - \e[00;32mredis installed successfully!\e[00m\"
        else
            echo -e \"$TIMESTAMP - \e[00;31mredis installed failed!\e[00m\"
        fi
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
