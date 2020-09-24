#!/bin/sh

IP=$1
USER=`whoami`
CURRENT_DIR=`pwd`
TIMESTAMP=`date +"%Y/%m/%d %H:%M:%S"`

if [[ "$IP" == "" ]]; then
    echo -e "$TIMESTAMP - parameter not found, sh sethosts.sh <ip>"
    exit -1
fi

if [[ "$USER" != "root" ]]; then
    echo -e "$TIMESTAMP - \e[00;31mplease run as root user!\e[00m"
    exit -1
fi

if [[ "$IP" == "127.0.0.1" ]]; then
    echo -e "$TIMESTAMP - set to localhost ..."
    sed -i '/www.51trust.com/d' /etc/hosts
    sed -i '/pubhos.51trust.com/d' /etc/hosts
    echo "39.106.71.35 tms-production.oss-cn-beijing.aliyuncs.com www.51trust.com yapi.51trust.com" >> /etc/hosts
    echo "39.106.134.199 pubhos.51trust.com" >> /etc/hosts
    echo -e "$TIMESTAMP - tail -2 /etc/hosts :"
    tail -2 /etc/hosts
else
    echo -e "$TIMESTAMP - set to remote:$IP ..."
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
    echo "$TIMESTAMP - ssh PORT:$PORT";    

    ssh root@$IP -p$PORT "
        sed -i '/www.51trust.com/d' /etc/hosts
        sed -i '/pubhos.51trust.com/d' /etc/hosts
        echo "39.106.71.35 tms-production.oss-cn-beijing.aliyuncs.com www.51trust.com yapi.51trust.com" >> /etc/hosts
        echo "39.106.134.199 pubhos.51trust.com" >> /etc/hosts
        echo -e "$TIMESTAMP - tail -2 /etc/hosts :"
        tail -2 /etc/hosts
    "
fi
