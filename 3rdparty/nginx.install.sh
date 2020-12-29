#!/bin/sh

# 服务布署在哪个节点，不要修改
DEST_IP=$1
APP1=$2
APP2=$3
HOS_NO=$4
NGINX_PORT=$5
# 服务布署在哪个目录，不要修改
DEST_DIR=/usr/local/nginx
# 服务包名称，不要修改
APP_NAME=nginx-1.16.1.tar.gz
# 从哪个服务器获取服务包，不要修改
SOURCE_DIR=release/3rdparty/nginx
# 从哪个目录获取服务包，不要修改
SOURCE_IP=`cat license | grep repo.ip | awk -F = '{print $2}'`
PORT=`cat license | grep repo.port | awk -F = '{print $2}'`
# set default value if SOURCE_IP or PORT is null
SOURCE_IP=${SOURCE_IP:=47.95.231.203}
PORT=${PORT:=8082}

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
    if [[ "$NGINX_PORT" == "" ]]; then
        echo -e "`date '+%D %T'` - \e[00;31mparameter not found, sh nginx.install.sh <nginx_ip> <app1_ip> <app2_ip> <hos_no> <nginx_port>\e[00m"
        exit -1
    fi
}

function get_pkg() {
    mkdir $CURRENT_DIR/pkg -pv
    cd $CURRENT_DIR/pkg

    if [[ ! -f "$APP_NAME" ]]; then
        echo -e "`date '+%D %T'` - $APP_NAME not found in local, downloading ..."
        wget http://$SOURCE_IP:${PORT}/shared/$SOURCE_DIR/$APP_NAME
    else
        echo -e "`date '+%D %T'` - $APP_NAME is found, install from local ..."
    fi
    cd $CURRENT_DIR
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

    if [[ ! -f "nginx.service" ]]; then
        echo -e "`date '+%D %T'` - nginx.service not found in local, downloading ..."
        wget http://$SOURCE_IP:${PORT}/shared/devops/3rdparty/nginx.service
    else
        echo -e "`date '+%D %T'` - nginx.service is found ..."
    fi

    chmod 755 *.sh

    cd $CURRENT_DIR
}

function install_local() {
    echo -e "`date '+%D %T'` - remove old nginx ..."
    yum remove nginx -y >/dev/null 2>&1

    echo -e "`date '+%D %T'` - add user and group ..."
    groupadd nginx >/dev/null 2>&1
    useradd -g nginx nginx >/dev/null 2>&1

    cd $CURRENT_DIR
    rm $DEST_DIR -fr
    mkdir $DEST_DIR
    tar -xf ./pkg/$APP_NAME -C $DEST_DIR
    chown -R nginx:nginx $DEST_DIR
    cd $DEST_DIR/nginx*
    /bin/cp logrotate/nginx /etc/logrotate.d/
    echo -e "`date '+%D %T'` - NGINX_HOME=`pwd`"
    ln -sf `pwd`/sbin/nginx /usr/bin/nginx

    if [[ "$APP1" != "0" ]]; then
        sed -i "s/0.0.0.0:9999/$APP1:9999/" ./conf/nginx.conf
        sed -i "s/0.0.0.0:8888/$APP1:8888/" ./conf/nginx.conf
        sed -i "s/0.0.0.0:7777/$APP1:7777/" ./conf/nginx.conf
        sed -i "s/0.0.0.0:9022/$APP1:9022/" ./conf/nginx.conf
        sed -i "s/0.0.0.0:9023/$APP1:9023/" ./conf/nginx.conf
        sed -i "s/0.0.0.0:9024/$APP1:9024/" ./conf/nginx.conf
    fi
    if [[ "$APP2" != "0" ]]; then
        sed -i "s/#server 1.1.1.1:9999/server $APP2:9999/" ./conf/nginx.conf
        sed -i "s/#server 1.1.1.1:8888/server $APP2:8888/" ./conf/nginx.conf
        sed -i "s/#server 1.1.1.1:9022/server $APP2:9022/" ./conf/nginx.conf
        sed -i "s/#server 1.1.1.1:9023/server $APP2:9023/" ./conf/nginx.conf
        sed -i "s/#server 1.1.1.1:9024/server $APP2:9024/" ./conf/nginx.conf
    fi
    if [[ "$HOS_NO" != "0" ]]; then
        sed -i "s/0000000000000000/$HOS_NO/" ./conf/nginx.conf
    fi

    if [[ "$NGINX_PORT" != "0" ]]; then
        sed -i "s/listen                  80;/listen                  $NGINX_PORT;/g" ./conf/nginx.conf
    fi

    # set auto start when server start
    echo -e "`date '+%D %T'` - nginx starting ...\n"
    pkill nginx
    sleep 1s
    /bin/cp $CURRENT_DIR/mod/nginx.service /usr/lib/systemd/system/
    systemctl daemon-reload
    systemctl enable nginx.service
    systemctl start nginx.service
    sleep 1s
    systemctl status nginx.service

    # schedule to cleanup logs
    (crontab -l;echo '0 2 * * * rm `ls -t /usr/local/nginx/nginx-1.16.1/logs | tail -n +15`')| crontab
    ss -lnp | grep "*:$NGINX_PORT "
    if [[ "$?" != "0" ]]; then
        echo -e "`date '+%D %T'` - \e[00;31mnginx installed failed!\e[00m"
        exit -1
    fi

    echo -e "\n`date '+%D %T'` - curl $DEST_IP:$NGINX_PORT ..."
    curl $DEST_IP:$NGINX_PORT 2>&1 |grep '<title>Welcome to nginx!</title>'

    if [[ "$?" == "0" ]]; then
        echo -e "`date '+%D %T'` - \e[00;32mnginx installed successfully!\e[00m"
    else
        echo -e "`date '+%D %T'` - \e[00;31mnginx installed failed!\e[00m"
    fi

    cd $CURRENT_DIR
}

function install_remote() {

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
        mkdir tmp -pv
    "
    echo -e "`date '+%D %T'` - copy $APP_NAME to $DEST_IP"
    scp ./pkg/$APP_NAME ./mod/nginx.service root@$DEST_IP:/root/tmp

    ssh root@$DEST_IP -p$port "
        echo -e \"`date '+%D %T'` - remove old nginx ...\"
        yum remove nginx -y >/dev/null 2>&1

        echo -e \"`date '+%D %T'` - add user and group ...\"
        groupadd nginx >/dev/null 2>&1
        useradd -g nginx nginx >/dev/null 2>&1

        cd tmp
        rm $DEST_DIR -fr
        mkdir $DEST_DIR
        tar -xf $APP_NAME -C $DEST_DIR
        chown -R nginx:nginx $DEST_DIR
        cd $DEST_DIR/nginx*
        /bin/cp logrotate/nginx /etc/logrotate.d/
        echo -e \"`date '+%D %T'` - NGINX_HOME=\`pwd\`\"
        ln -sf \`pwd\`/sbin/nginx /usr/bin/nginx

        if [[ \"\$APP1\" != \"0\" ]]; then
            sed -i \"s/0.0.0.0:9999/$APP1:9999/\" ./conf/nginx.conf
            sed -i \"s/0.0.0.0:8888/$APP1:8888/\" ./conf/nginx.conf
            sed -i \"s/0.0.0.0:7777/$APP1:7777/\" ./conf/nginx.conf
            sed -i \"s/0.0.0.0:9022/$APP1:9022/\" ./conf/nginx.conf
            sed -i \"s/0.0.0.0:9023/$APP1:9023/\" ./conf/nginx.conf
            sed -i \"s/0.0.0.0:9024/$APP1:9024/\" ./conf/nginx.conf
        fi
        if [[ \"\$APP2\" != \"0\" ]]; then
            sed -i \"s/#server 1.1.1.1:9999/server $APP2:9999/\" ./conf/nginx.conf
            sed -i \"s/#server 1.1.1.1:8888/server $APP2:8888/\" ./conf/nginx.conf
            sed -i \"s/#server 1.1.1.1:9022/server $APP2:9022/\" ./conf/nginx.conf
            sed -i \"s/#server 1.1.1.1:9023/server $APP2:9023/\" ./conf/nginx.conf
            sed -i \"s/#server 1.1.1.1:9024/server $APP2:9024/\" ./conf/nginx.conf
        fi
        if [[ \"\$HOS_NO\" != \"0\" ]]; then
            sed -i \"s/0000000000000000/$HOS_NO/\" ./conf/nginx.conf
        fi
        # 可读取外部变量 NGINX_PORT，但不能写入外部变量
        NGINX_PORT=$NGINX_PORT
        if [[ \"\$NGINX_PORT\" != \"0\" ]]; then
            sed -i \"s/listen                  80;/listen                  \$NGINX_PORT;/g\" ./conf/nginx.conf

        # set auto start when server start
        echo -e \"`date '+%D %T'` - nginx starting ...\n\"
        pkill nginx
        sleep 1s
        /bin/cp /root/tmp/nginx.service /usr/lib/systemd/system/
        systemctl daemon-reload
        systemctl enable nginx.service
        systemctl start nginx.service
        sleep 1s
        systemctl status nginx.service

        ss -lnp | grep "*:\$NGINX_PORT "
        if [[ \"\$?\" != \"0\" ]]; then
            echo -e \"`date '+%D %T'` - \e[00;31mnginx installed failed!\e[00m\"
            exit -1
        fi

        echo -e \"\n`date '+%D %T'` - curl $DEST_IP:\$NGINX_PORT ...\"
        curl $DEST_IP:\$NGINX_PORT 2>&1 |grep '<title>Welcome to nginx!</title>'

        if [[ \"\$?\" == \"0\" ]]; then
            echo -e \"`date '+%D %T'` - \e[00;32mnginx installed successfully!\e[00m\"
        else
            echo -e \"`date '+%D %T'` - \e[00;31mnginx installed failed!\e[00m\"
        fi
    "

    cd $CURRENT_DIR
}

function install_pkg() {
    if [[ $DEST_IP == "127.0.0.1" ]]; then
        echo -e "`date '+%D %T'` - deploy to localhost ..."
        install_local
    else
        echo -e "`date '+%D %T'` - deploy to $DEST_IP ..."
        install_remote
    fi
}

function main() {
    verify_user
    verify_parameter
    get_pkg
    get_mod
    install_pkg
}

main
