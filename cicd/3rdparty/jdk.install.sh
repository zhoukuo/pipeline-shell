#!/bin/sh
# 等号两侧不要有空格

# 服务布署在哪个节点，不要修改
DEST_IP=$1
# 服务布署在哪个目录，不要修改
DEST_DIR=/usr/local/java
# 服务包名称，不要修改
APP_NAME=jdk-8u221-linux-x64.tar.gz
# 从哪个服务器获取服务包，不要修改
SOURCE_DIR=release/3rdparty/jdk
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
        echo -e "`date '+%D %T'` - \e[00;31mparameter not found, source jdk.install.sh <ip>\e[00m"
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

    chmod 755 freelogin.sh

    cd $CURRENT_DIR
}

function install_local() {
    cd $CURRENT_DIR
    rm $DEST_DIR -fr
    mkdir $DEST_DIR
    tar -xf ./pkg/$APP_NAME -C $DEST_DIR
    cd $DEST_DIR/jdk*
    echo -e "`date '+%D %T'` - JAVA_HOME=`pwd`"

    sed -i '/JAVA_HOME/d' /etc/profile
    echo "export JAVA_HOME=`pwd`" >> /etc/profile
    echo 'export CLASSPATH=.:$JAVA_HOME/jre/lib/rt.jar:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar' >> /etc/profile
    echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/profile

    source /etc/profile
    ln -sf `pwd`/bin/java /usr/bin/java

    echo -e "`date '+%D %T'` - verify JDK ..."
    java -version

    if [ "$?" == "0" ]; then
        echo -e "`date '+%D %T'` - \e[00;32mJDK installed successfully!\e[00m"
    else
        echo -e "`date '+%D %T'` - \e[00;31mJDK installed failed!\e[00m"
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
    scp ./pkg/$APP_NAME root@$DEST_IP:/root/tmp

    ssh root@$DEST_IP -p$port "
        cd tmp
        rm $DEST_DIR -fr
        mkdir $DEST_DIR
        tar -xf $APP_NAME -C $DEST_DIR
        cd $DEST_DIR/jdk*
        echo -e \"`date '+%D %T'` - JAVA_HOME=\`pwd\`\"

        sed -i '/JAVA_HOME/d' /etc/profile
        echo \"export JAVA_HOME=\`pwd\`\" >> /etc/profile
        echo 'export CLASSPATH=.:\$JAVA_HOME/jre/lib/rt.jar:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar' >> /etc/profile
        echo 'export PATH=\$PATH:\$JAVA_HOME/bin' >> /etc/profile

        source /etc/profile
        ln -sf \`pwd\`/bin/java /usr/bin/java

        echo -e \"`date '+%D %T'` - verify JDK ...\"
        java -version

        if [ \"\$?\" == \"0\" ]; then
            echo -e \"`date '+%D %T'` - \e[00;32mJDK installed successfully!\e[00m\"
        else
            echo -e \"`date '+%D %T'` - \e[00;31mJDK installed failed!\e[00m\"
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

function main()
{
    echo -e "`date '+%D %T'` - \e[00;33mplease use 'source jdk.install.sh <ip>' instead of sh or bash!\e[00m"
    verify_user
    verify_parameter
    get_pkg
    get_mod
    install_pkg
}

main
