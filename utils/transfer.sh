#!/bin/sh

SOURCE_IP=$1
SOURCE_DIR=$2
SOURCE_DIR=${SOURCE_DIR%*/}
SERVICE_NAME=${SOURCE_DIR##*/}
DEST_IP=$3
DEST_DIR=$4

SOURCE_IP=`cat license | grep repo.ip | awk -F = '{print $2}'`
PORT=`cat license | grep repo.port | awk -F = '{print $2}'`
# set default value if SOURCE_IP or PORT is null
SOURCE_IP=${SOURCE_IP:=47.95.231.203}
PORT=${PORT:=8082}

JVMHEAP=1024m

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
    if [[ "$DEST_DIR" == "" ]]; then
        echo -e "`date '+%D %T'` - \e[00;31mparameter not found, sh transfer.install.sh <source_ip> <service_name> <dest_ip> <dest_dir>\e[00m"
        exit -1
    fi
}

function get_mod() {
    mkdir $CURRENT_DIR/mod -pv
    cd $CURRENT_DIR/mod

    if [[ ! -f "freelogin.sh" ]]; then
        echo -e "`date '+%D %T'` - freelogin.sh not found in local, downloading ..."
        wget http://$SERVER_IP:${PORT}/shared/devops/utils/freelogin.sh
    else
        echo -e "`date '+%D %T'` - freelogin.sh is found ..."
    fi

    chmod 755 *.sh

    cd $CURRENT_DIR
}

function transfer() {
    
    if [[ "$SOURCE_IP" == "127.0.0.1" ]] && [[ "$SOURCE_IP" == "$DEST_IP" ]]; then
        # transfer_local
        if [[ ! "$SOURCE_DIR" =~ "/" ]]; then
            SOURCE_DIR=`ps -ef | grep $SOURCE_DIR.jar | grep -v 'grep' | grep -v 'transfer'| awk '{print $NF}'`
            SOURCE_DIR=${SOURCE_DIR%/*}
            if [[ "$SOURCE_DIR" == "" ]]; then
                echo -e "`date '+%D %T'` - \e[00;31m$SERVICE_NAME srvice process not found!\e[00m"
                exit -1
            fi
        fi
        echo -e "\e[00;33mSOURCE_DIR:$SOURCE_DIR\e[00m"
        if [[ ! -d "$SOURCE_DIR" ]]; then
            echo -e "`date '+%D %T'` - \e[00;31m$SOURCE_DIR dir not found!\e[00m"
            exit -1
        fi
        echo -e "`date '+%D %T'` - transfer from $SOURCE_DIR to $DEST_DIR/$SERVICE_NAME ..."
        if [[ -d "$DEST_DIR/$SERVICE_NAME" ]]; then
            read -p "$DEST_DIR/$SERVICE_NAME is exist, do you want overwrite? (yes/NO): " answer
                if [[ "$answer" != "yes" ]]; then
                    exit -1
                fi
        fi
        cd $SOURCE_DIR
        ./service.sh stop `ls *.jar`
        rm -rf apilogs catlina.out
        cp -rf $SOURCE_DIR $DEST_DIR
        cd $DEST_DIR/$SERVICE_NAME
        sed -i 's#gateway.url.*#gateway.url=http://127.0.0.1:9999#' ./config/application-custom.properties
        ./service.sh restart `ls *.jar` $JVMHEAP

    elif [[ "$SOURCE_IP" == "127.0.0.1" ]]; then
        if [[ ! "$SOURCE_DIR" =~ "/" ]]; then
            SOURCE_DIR=`ps -ef | grep $SOURCE_DIR.jar | grep -v 'grep' | grep -v 'transfer'| awk '{print $NF}'`
            SOURCE_DIR=${SOURCE_DIR%/*}
            if [[ "$SOURCE_DIR" == "" ]]; then
                echo -e "`date '+%D %T'` - \e[00;31m$SERVICE_NAME srvice process not found!\e[00m"
                exit -1
            fi
        fi
        echo -e "\e[00;33mSOURCE_DIR:$SOURCE_DIR\e[00m"
        if [[ ! -d "$SOURCE_DIR" ]]; then
            echo -e "`date '+%D %T'` - \e[00;31m$SOURCE_DIR dir not found!\e[00m"
            exit -1
        fi

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
            if [[ -d \"$DEST_DIR/$SERVICE_NAME\" ]]; then
                echo -e \"$DEST_DIR/$SERVICE_NAME is exist, do you want overwrite? (yes/NO): \" 
                read answer
                if [[ \"\$answer\" != \"yes\" ]]; then
                    exit -1
                fi
            fi
        "
        if [[ "$?" != "0" ]]; then
            exit -1
        fi

        cd $SOURCE_DIR
        ./service.sh stop `ls *.jar`
        rm -rf apilogs catlina.out
        echo -e "`date '+%D %T'` - transfer from $SOURCE_DIR to $DEST_IP:$DEST_DIR/$SERVICE_NAME ..."
        scp -r -P$port $SOURCE_DIR root@$DEST_IP:$DEST_DIR
        ssh root@$DEST_IP -p$port "
            cd $DEST_DIR/$SERVICE_NAME
            sed -i 's#gateway.url.*#gateway.url=http://127.0.0.1:9999#' ./config/application-custom.properties
            ./service.sh restart \`ls *.jar\` $JVMHEAP
        "

    elif [[ "$DEST_IP" == "127.0.0.1" ]]; then
        echo -e "`date '+%D %T'` - not support this case!"
        exit -1

    elif [[ "$SOURCE_IP" == "$DEST_IP" ]]; then
        cd $CURRENT_DIR
        ./mod/freelogin.sh $SOURCE_IP
        #check port
        ssh -q -o ConnectTimeout=3 root@$SOURCE_IP -p22222 "exit"
        if [ "$?" == "0" ]; then
            port=22222
        else
            port=22
        fi
        echo "`date '+%D %T'` - ssh port:$port"

        ssh root@$DEST_IP -p$port "
            if [[ -d \"$DEST_DIR/$SERVICE_NAME\" ]]; then
                echo -e \"$DEST_DIR/$SERVICE_NAME is exist, do you want overwrite? (yes/NO): \" 
                read answer
                if [[ \"\$answer\" != \"yes\" ]]; then
                    exit -1
                fi
            fi
        "
        if [[ "$?" != "0" ]]; then
            exit -1
        fi

        ssh root@$SOURCE_IP -p$port "
            SOURCE_DIR=$SOURCE_DIR
            SERVICE_NAME=\${SOURCE_DIR##*/}
            if [[ ! \"$SOURCE_DIR\" =~ \"/\" ]]; then
                SOURCE_DIR=\`ps -ef | grep \$SOURCE_DIR.jar | grep -v 'grep' | grep -v 'transfer'| awk '{print \$NF}'\`
                SOURCE_DIR=\${SOURCE_DIR%/*}
                if [[ \"\$SOURCE_DIR\" == \"\" ]]; then
                    echo -e \"`date '+%D %T'` - \e[00;31m\$SERVICE_NAME srvice process not found!\e[00m\"
                    exit -1
                fi
            fi
            echo -e \"\e[00;33mSOURCE_DIR:\$SOURCE_DIR\e[00m\"
            if [[ ! -d \"\$SOURCE_DIR\" ]]; then
                echo -e \"`date '+%D %T'` - \e[00;31m\$SOURCE_DIR dir not found!\e[00m\"
                exit -1
            fi
            cd \$SOURCE_DIR
            ./service.sh stop \`ls *.jar\`
            rm -rf apilogs catlina.out

            cp -rf \$SOURCE_DIR $DEST_DIR

            cd $DEST_DIR/$SERVICE_NAME
            sed -i 's#gateway.url.*#gateway.url=http://127.0.0.1:9999#' ./config/application-custom.properties
            ./service.sh restart \`ls *.jar\` $JVMHEAP
        "

    else
        echo -e "`date '+%D %T'` - not support this case!"
        exit -1
    fi
}

function main() {
    verify_parameter
    verify_user
    get_mod
    transfer
}

main
