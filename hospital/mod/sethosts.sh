#!/bin/sh

IP=$1
USER=`whoami`
CURRENT_DIR=`pwd`


if [[ "$IP" == "" ]]; then
    echo -e "`date '+%D %T'` - parameter not found, sh sethosts.sh <ip>"
    exit -1
fi

if [[ "$USER" != "root" ]]; then
    echo -e "`date '+%D %T'` - \e[00;31mplease run as root user!\e[00m"
    exit -1
fi

if [[ "$IP" == "127.0.0.1" ]]; then
    echo -e "`date '+%D %T'` - set to localhost ..."
    sed -i '/www.51trust.com/d' /etc/hosts
    sed -i '/pubhos.51trust.com/d' /etc/hosts
    echo "39.106.71.35 tms-production.oss-cn-beijing.aliyuncs.com www.51trust.com yapi.51trust.com" >> /etc/hosts
    echo "39.106.134.199 pubhos.51trust.com" >> /etc/hosts
    echo -e "`date '+%D %T'` - tail -2 /etc/hosts :"
    tail -2 /etc/hosts
else
    echo -e "`date '+%D %T'` - set to remote:$IP ..."
    mkdir $CURRENT_DIR/mod -pv
    cd $CURRENT_DIR/mod

    if [[ ! -f "freelogin.sh" ]]; then
        wget http://$source_ip:8082/shared/devops/utils/freelogin.sh
    fi
    cd $CURRENT_DIR

    ./mod/freelogin.sh $IP

    #check PORT
    ssh -q -o ConnectTimeout=3 root@$dest_ip -p22222 "exit"
    if [ "$?" == "0" ]; then
        PORT=22222
    else
        PORT=22
    fi
    echo "`date '+%D %T'` - ssh PORT:$PORT";    

    ssh root@$IP -p$PORT "
        sed -i '/www.51trust.com/d' /etc/hosts
        sed -i '/pubhos.51trust.com/d' /etc/hosts
        echo "39.106.71.35 tms-production.oss-cn-beijing.aliyuncs.com www.51trust.com yapi.51trust.com" >> /etc/hosts
        echo "39.106.134.199 pubhos.51trust.com" >> /etc/hosts
        echo -e "`date '+%D %T'` - tail -2 /etc/hosts :"
        tail -2 /etc/hosts
    "
fi
