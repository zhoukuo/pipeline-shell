#!/bin/sh

PARAM1=$1
DEST_IP=127.0.0.1

# 移除windows文件行尾的换行符
sed -i 's/\r$//g' license

APP1_IP=`cat license | grep app1.ip | awk -F = '{print $2}'`
APP2_IP=`cat license | grep app2.ip | awk -F = '{print $2}'`
HOS_NO=`cat license | grep hospital.no | awk -F = '{print $2}'`
NGINX_PORT=`cat license | grep nginx.port | awk -F = '{print $2}'`

SOURCE_IP=`cat license | grep repo.ip | awk -F = '{print $2}'`
PORT=`cat license | grep repo.port | awk -F = '{print $2}'`

# set default value if SOURCE_IP or PORT is null
SOURCE_IP=${SOURCE_IP:=47.95.231.203}
PORT=${PORT:=8082}

VERSION=latest
NGINX=nginx-1.16.1.tar.gz
CURRENT_DIR=`pwd`


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
    wget -N http://$SOURCE_IP:$PORT/shared/devops/hospital/mod/sethosts.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/3rdparty/nginx.install.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/hospital/mod/view.deploy.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/deploy.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/service.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/utils/servicectl.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/verify.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/3rdparty/nginx.service
    wget -N http://$SOURCE_IP:$PORT/shared/devops/hospital/mod/webAdmin.tar.gz.service
    chmod 755 *.sh
    mkdir $CURRENT_DIR/pkg -pv
    cd $CURRENT_DIR/pkg
    wget -N http://$SOURCE_IP:$PORT/shared/release/3rdparty/wget/wget
    wget -N http://$SOURCE_IP:$PORT/shared/release/3rdparty/nginx/$NGINX
    wget -N http://$SOURCE_IP:$PORT/shared/release/hospital-in/hospital/${VERSION}/pkg/webAdmin.tar.gz
    cd $CURRENT_DIR
}

function check_license() {
    # required
    if [[ ! -f "license" ]]; then
        echo -e "`date '+%D %T'` - \e[00;31m[ERROR] license file not found !!!\e[00m"
        exit -1
    fi

    # required
    if [[ "$APP1_IP" == "x.x.x.x" ]]; then
        echo -e "`date '+%D %T'` - \e[00;31m[ERROR] license info invalid: app1.ip !!!\e[00m"
        exit -1
    fi

    # optional
    if [[ "$HOS_NO" == "" ]]; then
        echo -e "`date '+%D %T'` - \e[00;33m[WARNING] license: hospital.no is required for patient service\e[00m"
    fi
    
    # optional
    # if [[ "$APP2_IP" == "" ]]; then
    #     echo -e "`date '+%D %T'` - \e[00;33m[INFO] license: app2.ip is required if 2 app node\e[00m"
    # fi
}

function main() {
    
    install_wget

    # used for offline deploy
    if [[ "$PARAM1" == "-d" ]]; then
        echo -e "`date '+%D %T'` - downloading ... "
        download
        exit 0
    fi

    # get latest version if connection is ok
    wget -T3 -t1 http://$SOURCE_IP:$PORT/shared/devops/3rdparty/wget.install.sh -O ./mod/wget.install.sh
    if [[ "$?" == "0" ]]; then
        download
    fi
    
    echo -e "`date '+%D %T'` - check license ..."
    check_license

    echo -e "`date '+%D %T'` - init linux ..."
    ./mod/disable.sh $DEST_IP

    echo -e "`date '+%D %T'` - set hosts ..."
    ./mod/sethosts.sh $DEST_IP

    echo -e "`date '+%D %T'` - install webAdmin.tar.gz ..."
    ./mod/view.deploy.sh $DEST_IP

    echo -e "`date '+%D %T'` - install nginx ..."
    # 这里必须用sh调用，否则shell进程会被结束
    sh ./mod/nginx.install.sh ${DEST_IP:=0} ${APP1_IP:=0} ${APP2_IP:=0} ${HOS_NO:=0} ${NGINX_PORT:=80}
}

main
