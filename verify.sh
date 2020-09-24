  
appname=$1
curtime=`date "+%H:%M"`
starttime=`ps -ef | grep -v 'grep' | grep -v 'supervisorctl' | grep "$appname" | awk '{print $5}'`
timestamp=`date +"%Y/%m/%d %H:%M:%S"`

if [[ $appname != 'null' ]]; then
    echo "服务名称："$appname
    echo "启动时间："$starttime
    echo "当前时间："$curtime


    if [ "$curtime" != "$starttime"  ];then
        echo -e "$timestamp - 服务启动失败！"
        exit -1
    fi

    # timeout=30 seconds
    for (( i = 30; i > 0; i-- )); do
        sleep 1

        pid=`ps -ef | grep -v 'grep' | grep -v 'bash' | grep -v 'supervisorctl' | grep $appname | awk '{print $2}'`
        if [[ ! "$pid" ]]; then
            echo -e "$timestamp - 服务异常退出！"
            exit -1
        fi

        ss -lnp |grep $pid

        if [[ "$?" == "0" ]]; then
            echo -e "$timestamp - 服务启动完成！"
            exit 0;
        fi
    done

    echo -e "$timestamp - 等待服务进程启动超时(60秒)"
    exit -1
fi
