#!/bin/bash

SOURCE_IP=$1
SOURCE_DIR=$2
APP_NAME=$3
APP_TYPE=$4         #spring_boot/tomcat/static
DEST_IP=$5
DEST_DIR=$6
JVM_HEAP=$7

USER=`whoami`
CURRENT_DIR=`pwd`
TIMESTAMP=`date +"%Y/%m/%d %H:%M:%S"`
TOMCAT_HOME=${DEST_DIR%/*}


function verify_user() {
    echo -e "$TIMESTAMP - verify user ..."; 
    if [[ "$USER" != "root" ]]; then
        echo -e "$TIMESTAMP - \e[00;31mplease run as root user!\e[00m"
        exit -1
    fi
}

function verify_parameter() {

    if [[ "$APP_TYPE" != "spring_boot" ]] && [[ "$APP_TYPE" != "tomcat" ]] && [[ "$APP_TYPE" != "static" ]]; then
        echo -e "$TIMESTAMP - 应用类型错误！[spring_boot/tomcat/static]"
        exit -1
    fi

    if [[ "$SOURCE_IP" != "47.95.231.203" ]] && [[ "$SOURCE_IP" != "192.168.1.17" ]] && [[ "$SOURCE_IP" != "192.168.126.39" ]]; then
        echo -e "$TIMESTAMP - 文件服务器IP有误！[47.95.231.203/192.168.1.17/192.168.126.39]"
        exit -1
    fi

    if ([[ "$JVM_HEAP" == "" ]]); then
        JVM_HEAP=1024m
    fi
    echo -e "JVM_HEAP:" $JVM_HEAP

    #check port
    ssh -q -o ConnectTimeout=3 root@$DEST_IP -p22222 "exit"
    if [ "$?" == "0" ]; then
        PORT=22222
    else
        PORT=22
    fi
    echo "PORT:"$PORT
}

function get_mod() {
    mkdir $CURRENT_DIR/mod -pv
    cd $CURRENT_DIR/mod

    if [[ ! -f "$APP_NAME.service" ]]; then
        echo -e "$TIMESTAMP - $APP_NAME.service not found in local, downloading ..."
        wget http://$SOURCE_IP:8082/shared/devops/hospital/mod/$APP_NAME.service
    else
        echo -e "$TIMESTAMP - $APP_NAME.service is found ..."
    fi

    if [[ ! -f "freelogin.sh" ]]; then
        echo -e "$TIMESTAMP - freelogin.sh not found in local, downloading ..."
        wget http://$SOURCE_IP:8082/shared/devops/utils/freelogin.sh
    else
        echo -e "$TIMESTAMP - freelogin.sh is found ..."
    fi

    if [[ ! -f "servicectl.sh" ]]; then
        echo -e "$TIMESTAMP - servicectl.sh not found in local, downloading ..."
        wget http://$SOURCE_IP:8082/shared/devops/utils/servicectl.sh
    else
        echo -e "$TIMESTAMP - servicectl.sh is found ..."
    fi

    if [[ ! -f "service.sh" ]]; then
        echo -e "$TIMESTAMP - service.sh not found in local, downloading ..."
        wget http://$SOURCE_IP:8082/shared/devops/service.sh
    else
        echo -e "$TIMESTAMP - service.sh is found ..."
    fi

    if [[ ! -f "verify.sh" ]]; then
        echo -e "$TIMESTAMP - verify.sh not found in local, downloading ..."
        wget http://$SOURCE_IP:8082/shared/devops/verify.sh
    else
        echo -e "$TIMESTAMP - verify.sh is found ..."
    fi

    if [[ ! -f "initdb.sh" ]]; then
        echo -e "$TIMESTAMP - initdb.sh not found in local, downloading ..."
        wget http://$SOURCE_IP:8082/shared/devops/utils/initdb.sh
    else
        echo -e "$TIMESTAMP - initdb.sh is found ..."
    fi

    chmod 755 *.sh

    cd $CURRENT_DIR
}

function install_wget(){
    cd $CURRENT_DIR
    mkdir -pv mod
    if [[ ! -f "./mod/wget.install.sh" ]]; then
        wget http://$SOURCE_IP:8082/shared/devops/3rdparty/wget.install.sh -O ./mod/wget.install.sh
        chmod 755 ./mod/wget.install.sh
    fi
    ./mod/wget.install.sh
    cd $CURRENT_DIR
}

function get_pkg() {
    install_wget
    mkdir $CURRENT_DIR/pkg -pv
    cd $CURRENT_DIR/pkg

    if [[ ! -f "$APP_NAME" ]]; then
        echo -e "$TIMESTAMP - $APP_NAME not found in local, downloading ..."
    else
        echo -e "$TIMESTAMP - $APP_NAME is found, install from local ..."
    fi

    # 比较最后修改时间，如果比当前文件新，就重新下载
    echo -e "$TIMESTAMP - try to download package the latest version ..."
    wget -N -T2 -t1 http://$SOURCE_IP:8082/shared/$SOURCE_DIR/$APP_NAME
    cd $CURRENT_DIR
}

function install_local() {
    # clean env
    mkdir -pv $DEST_DIR
    cd $DEST_DIR

    echo -e "$TIMESTAMP - 清理环境，保留日志和本地配置 ..."
    if [[ "$APP_TYPE" == "tomcat" ]]; then
        rm -fr ${APP_NAME%.*}*
        rm -fr build-*
        rm -fr *.sh
        rm -fr template*
    else
        ls | grep -v "initdb.sh" | grep -v ".log" | grep -v "logs" | grep -v "archive" |grep -v "catlina.out" | grep -v "config" | grep -v "myconf" | grep -v "disconfig"| grep -v "static" | xargs rm -fr
    fi

    echo -e "$TIMESTAMP - 拷贝服务包到部署目录 ..."
    cd $CURRENT_DIR
    cp ./pkg/$APP_NAME ./mod/$APP_NAME.service ./mod/service.sh ./mod/servicectl.sh ./mod/verify.sh ./mod/initdb.sh $DEST_DIR
    cd $DEST_DIR
    pwd
    ls -lh

    if [[ "$APP_TYPE" == "static" ]]; then
        echo -e "解压缩文件..."
        tar -xvf $APP_NAME > /dev/null
        pwd
        ls -lh
    fi

    if [[ "$APP_TYPE" == "spring_boot" ]]; then
        echo -e "$TIMESTAMP - 重启服务 ..."
        sed -i "s/1024m/$JVM_HEAP/g" $APP_NAME.service
        sed -i "s#/opt#${DEST_DIR%/*}#g" $APP_NAME.service
        mv -f $APP_NAME.service /usr/lib/systemd/system/
        systemctl daemon-reload
        systemctl enable $APP_NAME.service
        systemctl stop $APP_NAME.service
        sleep 1s
        systemctl restart $APP_NAME.service
        sleep 1s
        # ./service.sh restart $APP_NAME $JVM_HEAP
        ps -ef | grep -v "grep" | grep $DEST_DIR/$APP_NAME

        echo -e "$TIMESTAMP - 服务验证 ..."
        ./verify.sh $DEST_DIR/$APP_NAME
        echo -e ""
        systemctl status $APP_NAME.service
        exit $?

    elif [[ "$APP_TYPE" == "tomcat" ]]; then
        echo -e "$TIMESTAMP - 重启服务 ..."
        ./tomcat.sh restart $TOMCAT_HOME
        ps -ef | grep -v "grep" | grep 'tomcat'| grep $TOMCAT_HOME

        echo -e "$TIMESTAMP - 服务验证 ..."
        ./verify.sh $TOMCAT_HOME
        exit $?

    elif [[ "$APP_TYPE" == "static" ]]; then
        exit 0
    else
        echo -e "$TIMESTAMP - 应用类型错误！[spring_boot/tomcat/static]"
        exit -1
    fi
}

function install_remote() {
    ./mod/freelogin.sh $DEST_IP

    ssh root@$DEST_IP -p$PORT "
        mkdir -pv $DEST_DIR
        cd $DEST_DIR

        echo -e "$TIMESTAMP - 清理环境，保留日志和本地配置 ..."
        if [[ \"$APP_TYPE\" == \"tomcat\" ]]; then
            rm -fr ${APP_NAME%.*}*
            rm -fr build-*
            rm -fr *.sh
            rm -fr template*
        else
            ls | grep -v "initdb.sh" | grep -v ".log" | grep -v "logs" | grep -v "archive" |grep -v "catlina.out" | grep -v "config" | grep -v "myconf" | grep -v "disconfig"| grep -v "static" | xargs rm -fr
        fi
    "
    echo -e "$TIMESTAMP - 拷贝服务包到部署目录 ..."
    scp -P$PORT ./pkg/$APP_NAME ./mod/$APP_NAME.service ./mod/service.sh ./mod/servicectl.sh ./mod/verify.sh ./mod/initdb.sh root@$DEST_IP:/$DEST_DIR

    ssh root@$DEST_IP -p$PORT "

        cd $DEST_DIR
        pwd
        ls -lh

        if [[ \"$APP_TYPE\" == \"static\" ]]; then
            echo -e "解压缩文件..."
            tar -xvf $APP_NAME > /dev/null
            pwd
            ls -lh
        fi

        if [[ \"$APP_TYPE\" == \"spring_boot\" ]]; then
            echo -e "$TIMESTAMP - 重启服务 ..."
            systemctl stop $APP_NAME.service
            sleep 1s
            sed -i \"s/1024m/$JVM_HEAP/g\" $APP_NAME.service
            sed -i \"s#/opt#${DEST_DIR%/*}#g\" $APP_NAME.service
            mv -f $APP_NAME.service /usr/lib/systemd/system/
            systemctl daemon-reload
            systemctl enable $APP_NAME.service
            systemctl restart $APP_NAME.service
            sleep 1s
            ps -ef | grep -v "grep" | grep $DEST_DIR/$APP_NAME

            echo -e "$TIMESTAMP - 服务验证 ..."
            ./verify.sh $DEST_DIR/$APP_NAME
            echo -e ""
            systemctl status $APP_NAME.service
            exit $?

        elif [[ \"$APP_TYPE\" == \"tomcat\" ]]; then
            echo -e "$TIMESTAMP - 重启服务 ..."
            ./tomcat.sh restart $TOMCAT_HOME
            ps -ef | grep -v "grep" | grep 'tomcat'| grep $TOMCAT_HOME

            echo -e "$TIMESTAMP - 服务验证 ..."
            ./verify.sh $TOMCAT_HOME
            exit $?

        elif [[ \"$APP_TYPE\" == \"static\" ]]; then
            exit 0
        else
            echo -e "$TIMESTAMP - 应用类型错误！[spring_boot/tomcat/static]"
            exit -1
        fi

    "
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
    get_mod
    get_pkg
    install_pkg
}

main


