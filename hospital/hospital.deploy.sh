#!/bin/sh

PARAM1=$1
DEST_IP=127.0.0.1
VERSION=latest
BJCAROOT=bjcaroot.tar.gz
JDK=jdk-8u221-linux-x64.tar.gz

# 移除windows文件行尾的换行符
sed -i 's/\r$//g' license

DBIP=`cat license | grep db.ip | awk -F = '{print $2}'`
DOMAIN=`cat license | grep cloud.domain | awk -F = '{print $2}'`
USER=`cat license | grep db.user | awk -F = '{print $2}'`
PASSWD=`cat license | grep db.password | awk -F = '{print $2}'`
BUCKET=`cat license | grep oss.bucketName | awk -F = '{print $2}'`
SOURCE_IP=`cat license | grep repo.ip | awk -F = '{print $2}'`
PORT=`cat license | grep repo.port | awk -F = '{print $2}'`

# set default value if SOURCE_IP or PORT is null
SOURCE_IP=${SOURCE_IP:=47.95.231.203}
PORT=${PORT:=8082}

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
    wget -N http://$SOURCE_IP:$PORT/shared/devops/utils/freelogin.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/utils/disable.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/utils/servicectl.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/deploy.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/service.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/verify.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/3rdparty/bjcaroot.install.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/3rdparty/jdk.install.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/3rdparty/wget.install.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/hospital/mod/sethosts.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/hospital/mod/patient.deploy.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/hospital/mod/patient.jar.service
    wget -N http://$SOURCE_IP:$PORT/shared/devops/hospital/mod/doctor.deploy.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/hospital/mod/doctor.jar.service
    wget -N http://$SOURCE_IP:$PORT/shared/devops/hospital/mod/hosadmin.deploy.sh
    wget -N http://$SOURCE_IP:$PORT/shared/devops/hospital/mod/hosAdmin.jar.service
    wget -N http://$SOURCE_IP:$PORT/shared/devops/hospital/mod/application.properties
    wget -N http://$SOURCE_IP:$PORT/shared/devops/hospital/mod/init.properties
    chmod 755 *.sh
    mkdir $CURRENT_DIR/pkg -pv
    cd $CURRENT_DIR/pkg
    wget -N http://$SOURCE_IP:$PORT/shared/release/3rdparty/bjcaroot/$BJCAROOT
    wget -N http://$SOURCE_IP:$PORT/shared/release/3rdparty/jdk/$JDK
    wget -N http://$SOURCE_IP:$PORT/shared/release/3rdparty/wget/wget
    wget -N http://$SOURCE_IP:$PORT/shared/release/hospital-in/hospital/${VERSION}/pkg/patient.jar
    wget -N http://$SOURCE_IP:$PORT/shared/release/hospital-in/hospital/${VERSION}/pkg/doctor.jar
    wget -N http://$SOURCE_IP:$PORT/shared/release/hospital-in/hospital/${VERSION}/pkg/hosAdmin.jar
    cd $CURRENT_DIR
}

function init() {
    SERVICE=$1

    mkdir -pv /opt/${SERVICE}/config
    /bin/cp ./mod/application.properties /opt/${SERVICE}/config
    sed -i "s/1.1.1.1/${DBIP}/" /opt/${SERVICE}/config/application.properties
    sed -i "s/spring.datasource.username.*/spring.datasource.username=${USER}/" /opt/${SERVICE}/config/application.properties
    sed -i "s/spring.datasource.password.*/spring.datasource.password=${PASSWD}/" /opt/${SERVICE}/config/application.properties
    mkdir -pv /opt/${SERVICE}/myconf
    /bin/cp ./mod/init.properties /opt/${SERVICE}/myconf
    sed -i "s/ywq.core.common.redis.host.*/ywq.core.common.redis.host=${DBIP}/" /opt/${SERVICE}/myconf/init.properties
    sed -i "s#cloud.domain.*#cloud.domain=${DOMAIN}#" /opt/${SERVICE}/myconf/init.properties
    sed -i "s/oss.bucketName.*/oss.bucketName=${DOMAIN}/" /opt/${SERVICE}/myconf/init.properties
    
}

function check_network() {
    echo -e "`date '+%D %T'` - ping mysql service ..."
    nc -z -w 1 $DBIP 3306
    if [[ \"\$?\" == \"0\" ]]; then
        echo -e \"try to connect mysql 3306 ... \t\t\t[\e[00;32mPASS\e[00m]\"
    else
        echo -e \"try to connect mysql 3306 ... \t\t\t[\e[00;31mFAIL\e[00m]\"; 
    fi

    echo -e "`date '+%D %T'` - ping redis service ..."
    nc -z -w 1 $DBIP 3306
    if [[ \"\$?\" == \"0\" ]]; then
        echo -e \"try to connect redis 6379 ... \t\t\t[\e[00;32mPASS\e[00m]\"
    else
        echo -e \"try to connect redis 6379 ... \t\t\t[\e[00;31mFAIL\e[00m]\"; 
    fi

    echo -e "`date '+%D %T'` - ping pubhos.51trust.com ..."
    nc -z -w 1 pubhos.51trust.com 443
    if [[ \"\$?\" == \"0\" ]]; then
        echo -e \"try to connect pubhos.51trust.com 443 ... \t\t\t[\e[00;32mPASS\e[00m]\"
    else
        echo -e \"try to connect pubhos.51trust.com 443 ... \t\t\t[\e[00;31mFAIL\e[00m]\"; 
    fi
}

function check_license() {
    # required
    if [[ ! -f "license" ]]; then
        echo -e "`date '+%D %T'` - \e[00;31m[ERROR] license file not found !!!\e[00m"
        exit -1
    fi

    # required
    if [[ "$DBIP" == "x.x.x.x" ]]; then
        echo -e "`date '+%D %T'` - \e[00;31m[ERROR] license info invalid: db.ip !!!\e[00m"
        exit -1
    fi

    # required, but not block at current stage
    if [[ "$APP1_IP" == "x.x.x.x" ]]; then
        echo -e "`date '+%D %T'` - \e[00;33m[WARNING] license info invalid: app1.ip !!!\e[00m"
    fi
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

    echo -e "`date '+%D %T'` - install jdk ..."
    ./mod/jdk.install.sh $DEST_IP

    echo -e "`date '+%D %T'` - install bjcaroot ..."
    ./mod/bjcaroot.install.sh $DEST_IP

    echo -e "`date '+%D %T'` - install service patient ..."
    init patient
    ./mod/patient.deploy.sh $DEST_IP

    echo -e "`date '+%D %T'` - install service doctor ..."
    init doctor
    ./mod/doctor.deploy.sh $DEST_IP

    echo -e "`date '+%D %T'` - install service hosadmin ..."
    init hosadmin
    ./mod/hosadmin.deploy.sh $DEST_IP

}

main
