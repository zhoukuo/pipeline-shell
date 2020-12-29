#!/bin/bash

IP=$1
USER=`whoami`
CURRENT_DIR=`pwd`



if [[ "$1" == "" ]]; then
    echo -e "`date '+%D %T'` - parameter not found, sh freelogin.sh <ip>"
    exit -1
fi

echo -e "`date '+%D %T'` - verify ssh-copy-id is installed or not ..."
ssh-copy-id >/dev/null 2>&1

if [[ "$?" -ne "1" ]]; then
    echo -e "ssh-copy-id is not found, install ssh-copy-id first ..."
    yum install -y openssh-clients* -y
fi

cd ~/.ssh
if [[ ! -f "id_rsa.pub" ]]; then
    echo -e "`date '+%D %T'` - id_rsa file not found, ssh-keygen first ..."
    ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
fi

#check port
ssh -q -o ConnectTimeout=3 root@$IP -p22222 "exit"
if [ "$?" == "0" ]; then
    port=22222
else
    ssh -q -o ConnectTimeout=3 root@$IP -p2222 "exit"
    if [ "$?" == "0" ]; then
        port=2222
    else
        port=22
    fi
fi
echo "`date '+%D %T'` - ssh port:$port"

echo -e "`date '+%D %T'` - copy `pwd`/.ssh/id_rsa.pub to $IP ..."
ssh-copy-id -i ~/.ssh/id_rsa.pub $USER@$IP -p$port >/dev/null 2>&1

cd $CURRENT_DIR
