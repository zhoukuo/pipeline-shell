#!/bin/sh

DEST_IP=$1
SOURCE_IP=47.95.231.203
USER=`whoami`
TIMESTAMP=`date +"%Y/%m/%d %H:%M:%S"`
CURRENT_DIR=`pwd`

function verify_user() {
    if [[ "$USER" != "root" ]]; then
        echo -e "$TIMESTAMP - \e[00;31mplease run as root user!\e[00m"
        exit -1
    fi
}

function verify_parameter() {
    echo -e "$TIMESTAMP - verify parameter ..."
    if [[ "$dest_ip" == "" ]]; then
        echo -e "$TIMESTAMP - \e[00;31mparameter not found, sh disable.sh <ip>\e[00m"
        exit -1
    fi
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

    chmod 755 freelogin.sh

    cd $CURRENT_DIR
}

function disable_selinux() {
    echo -e "$TIMESTAMP - disable SELinux ..."
    setenforce 0
    sed -i 's/enforcing/disabled/' /etc/sysconfig/selinux
}

function disable_firewalld() {
    echo -e "$TIMESTAMP - disable Firewalld ..."
    systemctl stop firewalld
    systemctl disable firewalld
}

function fix_ssh_slowly() {
    echo -e "$TIMESTAMP - fix_ssh_slowly_issue ..."
    sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
    sed -i 's/#GSSAPIAuthentication yes/GSSAPIAuthentication no/' /etc/ssh/sshd_config
    systemctl restart sshd.service
}

function main() {

    if [[ "$DEST_IP" == "127.0.0.1" ]]; then
        disable_selinux
        disable_firewalld
        fix_ssh_slowly
    else
        get_mod
        ./mod/freelogin.sh $DEST_IP

        #check port
        ssh -q -o ConnectTimeout=3 root@$DEST_IP -p22222 "exit"
        if [ "$?" == "0" ]; then
            PORT=22222
        else
            PORT=22
        fi
        echo "$TIMESTAMP - ssh PORT:$PORT"

        ssh root@$DEST_IP -p$PORT "
            echo -e "$TIMESTAMP - disable SELinux ..."
            setenforce 0
            sed -i 's/enforcing/disabled/' /etc/sysconfig/selinux

            echo -e "$TIMESTAMP - disable Firewalld ..."
            systemctl stop firewalld
            systemctl disable firewalld

            echo -e "$TIMESTAMP - fix_ssh_slowly_issue ..."
            sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
            sed -i 's/#GSSAPIAuthentication yes/GSSAPIAuthentication no/' /etc/ssh/sshd_config
            systemctl restart sshd.service
        "
    fi
}

main
