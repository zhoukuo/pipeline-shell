#!/bin/bash

action=$1
tomcat_home=$2

SHUTDOWN=$tomcat_home/bin/shutdown.sh
START=$tomcat_home/bin/startup.sh

source /etc/profile

case $action in
    start)
        echo "启动$tomcat_home"
        $START
        ;;
    stop)
        echo "关闭$tomcat_home"
        $SHUTDOWN
        sleep 10
        ps -ef | grep -v "grep" |grep -v "tomcat.sh"| grep $tomcat_home | awk '{print $2}'| xargs kill -9
        sleep 10

        #删除日志文件，如果你不先删除可以不要下面一行
        #rm  $tomcat_home/logs/* -rf
        #删除tomcat的临时目录
        #rm  $tomcat_home/work/* -rf
        ;;
    restart)
        # echo "关闭$tomcat_home"
        # $SHUTDOWN
        # sleep 10
        ps -ef | grep -v "grep" |grep -v "tomcat.sh"| grep $tomcat_home | awk '{print $2}'| xargs kill -9
        sleep 1
        echo "启动$tomcat_home"
        $START
        ;;
    logs)
        cd $tomcat_home/logs
        tail -f catalina.out
        ;;
esac
