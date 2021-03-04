#!/bin/sh

FROM=127.0.0.1
JUMPSERVER=47.95.231.203
SLB=101.201.170.153
NGINX1=39.106.71.35
NGINX2=39.106.134.199

user=`whoami`
current_dir=`pwd`
timestamp=`date +"%Y/%m/%d %H:%M:%S"`


function verify_nc() {
    nc >/dev/null 2>&1
    if [[ "$?" == "127" ]]; then
        wget http://$JUMPSERVER:8082/shared/release/3rdparty/nc/nc-1.84-22.el6.x86_64.rpm
        rpm -ivh nc-1.84-22.el6.x86_64.rpm
    fi
}

function verify_user() {
    echo -e "$timestamp - verify user ..."; 
    if [[ "$user" != "root" ]]; then
        echo -e "$timestamp - \e[00;31mplease run as root user!\e[00m"
        exit -1
    fi
}

function verify_parameter() {
    if [[ "$FROM" == "" ]]; then
        echo -e "\e[00;31myou must specify a host to check from - rulecheck_netout.sh <ip>\e[00m"
        exit -1
    fi
}

function get_mod() {
    mkdir $current_dir/mod -pv
    cd $current_dir/mod

    if [[ ! -f "freelogin.sh" ]]; then
        echo -e "$timestamp - $app_name not found in local, downloading ..."
        wget http://$JUMPSERVER:8082/shared/devops/utils/freelogin.sh
    else
        echo -e "$timestamp - freelogin.sh is found ..."
    fi

    cd $current_dir
}

function check_from_local() {
    # check to jumpserver
    nc -z -w 1 $JUMPSERVER 8082
    if [[ "$?" == "0" ]]; then
        echo -e "[JUMPSERVER]\t - try to connect $JUMPSERVER 8082 from $FROM ... \t\t\t[\e[00;32mPASS\e[00m]"
    else
        echo -e "[JUMPSERVER]\t - try to connect $JUMPSERVER 8082 from $FROM ... \t\t\t[\e[00;31mFAIL\e[00m]"; 
    fi

    # check to SLB
    nc -z -w 1 $SLB 443
    if [[ "$?" == "0" ]]; then
        echo -e "[SLB]\t\t - try to connect $SLB 443 from $FROM ... \t\t\t[\e[00;32mPASS\e[00m]"
    else
        echo -e "[SLB]\t\t - try to connect $SLB 443 from $FROM ... \t\t\t[\e[00;31mFAIL\e[00m]"; 
    fi

    # check to nginx1
    nc -z -w 1 $NGINX1 443
    if [[ "$?" == "0" ]]; then
        echo -e "[NGINX1]\t - try to connect $NGINX1 443 from $FROM ... \t\t\t\t[\e[00;32mPASS\e[00m]"
    else
        echo -e "[NGINX1]\t - try to connect $NGINX1 443 from $FROM ... \t\t\t\t[\e[00;31mFAIL\e[00m]"; 
    fi

    # check to nginx2
    nc -z -w 1 $NGINX2 443
    if [[ "$?" == "0" ]]; then
        echo -e "[NGINX2]\t - try to connect $NGINX2 443 from $FROM ... \t\t\t[\e[00;32mPASS\e[00m]"
    else
        echo -e "[NGINX2]\t - try to connect $NGINX2 443 from $FROM ... \t\t\t[\e[00;31mFAIL\e[00m]"; 
    fi
}

function check_from_remote() {
    ./mod/freelogin.sh $FROM

    #check port
    ssh -q -o ConnectTimeout=3 root@$FROM -p22222 "exit"
    if [ "$?" == "0" ]; then
        port=22222
    else
        port=22
    fi
    echo "$timestamp - ssh port:$port"

    ssh root@$FROM -p$port "
        # check to jumpserver
        nc -z -w 1 $JUMPSERVER 8082
        if [[ \"\$?\" == \"0\" ]]; then
            echo -e \"[JUMPSERVER]\t - try to connect $JUMPSERVER 8082 from $FROM ... \t\t\t[\e[00;32mPASS\e[00m]\"
        else
            echo -e \"[JUMPSERVER]\t - try to connect $JUMPSERVER 8082 from $FROM ... \t\t\t[\e[00;31mFAIL\e[00m]\"; 
        fi

        # check to SLB
        nc -z -w 1 $SLB 443
        if [[ \"\$?\" == \"0\" ]]; then
            echo -e \"[SLB]\t - try to connect $SLB 443 from $FROM ... \t\t\t\t[\e[00;32mPASS\e[00m]\"
        else
            echo -e \"[SLB]\t - try to connect $SLB 443 from $FROM ... \t\t\t\t[\e[00;31mFAIL\e[00m]\"; 
        fi

        # check to nginx1
        nc -z -w 1 $NGINX1 443
        if [[ \"\$?\" == \"0\" ]]; then
            echo -e \"[NGINX1]\t - try to connect $NGINX1 443 from $FROM ... \t\t\t[\e[00;32mPASS\e[00m]\"
        else
            echo -e \"[NGINX1]\t - try to connect $NGINX1 443 from $FROM ... \t\t\t[\e[00;31mFAIL\e[00m]\"; 
        fi

        # check to nginx2
        nc -z -w 1 $NGINX2 443
        if [[ \"\$?\" == \"0\" ]]; then
            echo -e \"[NGINX2]\t - try to connect $NGINX2 443 from $FROM ... \t\t\t[\e[00;32mPASS\e[00m]\"
        else
            echo -e \"[NGINX2]\t - try to connect $NGINX2 443 from $FROM ... \t\t\t[\e[00;31mFAIL\e[00m]\"; 
        fi
    "
}

function check() {
    if [[ $FROM == "127.0.0.1" ]]; then
        echo -e "$timestamp - check from localhost ..."
        check_from_local
    else
        echo -e "$timestamp - check from $FROM ..."
        get_mod
        check_from_remote
    fi
}

function main() {
    verify_nc
    verify_user
    verify_parameter
    check
}

main
