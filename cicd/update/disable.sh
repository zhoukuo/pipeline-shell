#!/bin/sh

DEST_IP=$1

SOURCE_IP=`cat license | grep repo.ip | awk -F = '{print $2}'`
PORT=`cat license | grep repo.port | awk -F = '{print $2}'`
# set default value if SOURCE_IP or PORT is null
SOURCE_IP=${SOURCE_IP:=47.95.231.203}
PORT=${PORT:=8082}

USER=`whoami`
CURRENT_DIR=`pwd`

function verify_user() {
    if [[ "$USER" != "root" ]]; then
        echo -e "`date '+%D %T'` - \e[00;31mplease run as root user!\e[00m"
        exit -1
    fi
}

function verify_parameter() {
    echo -e "`date '+%D %T'` - verify parameter ..."
    if [[ "$dest_ip" == "" ]]; then
        echo -e "`date '+%D %T'` - \e[00;31mparameter not found, sh disable.sh <ip>\e[00m"
        exit -1
    fi
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

function disable_selinux() {
    echo -e "`date '+%D %T'` - disable SELinux ..."
    setenforce 0
    sed -i 's/enforcing/disabled/' /etc/sysconfig/selinux
}

function disable_firewalld() {
    echo -e "`date '+%D %T'` - disable Firewalld ..."
    systemctl stop firewalld
    systemctl disable firewalld
}

function fix_ssh_slowly() {
    echo -e "`date '+%D %T'` - fix_ssh_slowly_issue ..."
    sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
    sed -i 's/#GSSAPIAuthentication yes/GSSAPIAuthentication no/' /etc/ssh/sshd_config
    systemctl restart sshd.service
}

function ulimit_n() {
    echo -e "`date '+%D %T'` - update limits.conf ..."
    sed -i '/65535/d' /etc/security/limits.conf
    sed -i '/End of file/i\* soft nofile 65535' /etc/security/limits.conf
    sed -i '/End of file/i\* hard nofile 65535' /etc/security/limits.conf
    ulimit -n 65535
}

function sysctl_p() {
    echo -e "`date '+%D %T'` - update sysctl.conf ..."
    # nginx性能优化
    sed -i '/net.ipv4/d' /etc/sysctl.conf
    echo 'net.ipv4.tcp_syncookies = 1' >> /etc/sysctl.conf
    echo 'net.ipv4.tcp_tw_reuse = 1' >> /etc/sysctl.conf
    echo 'net.ipv4.tcp_tw_recycle = 1' >> /etc/sysctl.conf
    echo 'net.ipv4.ip_local_port_range = 1024 61024' >> /etc/sysctl.conf
    # redis性能优化
    sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
    sed -i '/vm.overcommit_memory/d' /etc/sysctl.conf
    echo 'net.core.somaxconn = 511' >> /etc/sysctl.conf
    echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf
    # 立即生效
    sysctl -p
}

function disable_hugepage() {
    # 禁用大内存页面(某些数据库厂商还是建议直接关闭THP(比如说Oracle、MongoDB等)，否则可能导致性能下降，内存锁，甚至系统重启等问题)
    echo -e "`date '+%D %T'` - disable transparent_hugepage ..."
    sed -i '/transparent_hugepage/d' /etc/rc.d/rc.local
    echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.d/rc.local
    echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.d/rc.local
    chmod +x /etc/rc.d/rc.local

    echo never > /sys/kernel/mm/transparent_hugepage/enabled
    echo never > /sys/kernel/mm/transparent_hugepage/defrag
}

function main() {

    if [[ "$DEST_IP" == "127.0.0.1" ]]; then
        disable_selinux
        disable_firewalld
        fix_ssh_slowly  
        ulimit_n
        sysctl_p
        disable_hugepage
    else
        get_mod
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
            echo -e "`date '+%D %T'` - disable SELinux ..."
            setenforce 0
            sed -i 's/enforcing/disabled/' /etc/sysconfig/selinux

            echo -e "`date '+%D %T'` - disable Firewalld ..."
            systemctl stop firewalld
            systemctl disable firewalld

            echo -e "`date '+%D %T'` - fix_ssh_slowly_issue ..."
            sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
            sed -i 's/#GSSAPIAuthentication yes/GSSAPIAuthentication no/' /etc/ssh/sshd_config
            systemctl restart sshd.service

            echo -e "`date '+%D %T'` - update limits.conf ..."
            sed -i '/65535/d' /etc/security/limits.conf
            sed -i '/End of file/i\* soft nofile 65535' /etc/security/limits.conf
            sed -i '/End of file/i\* hard nofile 65535' /etc/security/limits.conf
            ulimit -n 65535

            echo -e "`date '+%D %T'` - update sysctl.conf ..."
            # nginx性能优化
            sed -i '/net.ipv4/d' /etc/sysctl.conf
            echo 'net.ipv4.tcp_syncookies = 1' >> /etc/sysctl.conf
            echo 'net.ipv4.tcp_tw_reuse = 1' >> /etc/sysctl.conf
            echo 'net.ipv4.tcp_tw_recycle = 1' >> /etc/sysctl.conf
            echo 'net.ipv4.ip_local_port_range = 1024 61024' >> /etc/sysctl.conf
            # redis性能优化
            sed -i 'net.core.somaxconn/d' /etc/sysctl.conf
            sed -i 'vm.overcommit_memory/d' /etc/sysctl.conf
            echo 'net.core.somaxconn = 511' >> /etc/sysctl.conf
            echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf
            # 立即生效
            sysctl -p

            # 禁用大内存页面(某些数据库厂商建议直接关闭THP(比如说Oracle、MongoDB等)，否则可能导致性能下降，内存锁，甚至系统重启等问题)
            echo -e "`date '+%D %T'` - disable transparent_hugepage ..."
            sed -i '/transparent_hugepage/d' /etc/rc.d/rc.local
            echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.d/rc.local
            echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.d/rc.local
            chmod +x /etc/rc.d/rc.local

            echo never > /sys/kernel/mm/transparent_hugepage/enabled
            echo never > /sys/kernel/mm/transparent_hugepage/defrag
        "
    fi
}

main
