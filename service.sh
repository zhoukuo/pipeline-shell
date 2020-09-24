#!/bin/bash

SERVICE_DIR=`pwd`
SERVICE_NAME=$2
JVM_HEAP=$3

source /etc/profile
timestamp=`date +"%Y/%m/%d %H:%M:%S"`


start() {
    echo -e "$timestamp - 正在启动服务 ..."
    if [[ $JVM_HEAP == "" ]] ||  [[ $JVM_HEAP =~ ".jar" ]]; then
        echo "service.sh start|stop|restart jar_name jvm_heap"
    fi
    # 兼容systemd
    if [[ $SERVICE_DIR == "/" ]]; then 
        nohup java -Xms$JVM_HEAP -Xmx$JVM_HEAP -XX:PermSize=256m -jar $SERVICE_NAME >> $SERVICE_DIR/catlina.out 2>&1 &
    else
        nohup java -Xms$JVM_HEAP -Xmx$JVM_HEAP -XX:PermSize=256m -jar $SERVICE_DIR/$SERVICE_NAME >> $SERVICE_DIR/catlina.out 2>&1 &
    fi
}

stop() {
    echo -e "$timestamp - 正在停止服务 ..."
    pid1=`ps -ef |grep -v 'grep' |grep java |grep $SERVICE_DIR/$SERVICE_NAME |awk '{print $2}'`
    pid2=`ps -ef |grep -v 'grep' |grep java |grep $SERVICE_DIR//$SERVICE_NAME |awk '{print $2}'`
    kill -9 $pid1 $pid2 >/dev/null 2>&1

    # wait for process exit...
    for (( i = 10; i > 0; i-- )); do
        sleep 1

        pid1=`ps -ef |grep -v 'grep' |grep java |grep $SERVICE_DIR/$SERVICE_NAME |awk '{print $2}'`
        pid2=`ps -ef |grep -v 'grep' |grep java |grep $SERVICE_DIR//$SERVICE_NAME |awk '{print $2}'`
        if [[ "$pid1" == "" ]] && [[ "$pid2" == "" ]]; then
            echo -e "$timestamp - 服务已停止 ..."
            return 0
        fi
    done

    # timeout, return -1
    echo -e "$timestamp - 停止服务失败 ..."
    tailf catlina.out
    exit -1
}

case "$1" in
    
    start)
        start $SERVICE_NAME
        ;;
  
    stop)
        stop
        ;;
  
    restart)
        stop
        start $SERVICE_NAME
        ;;
    *)
        echo "service.sh start|stop|restart jar_name jvm_heap"
        ;;
esac

exit 0
