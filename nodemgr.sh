#!/bin/bash --login
cmd=$1
node_ip=$2
remote="192.168.126.72"
count_node_ip=`echo $node_ip | egrep -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | wc -l`
remote_node_ip=`echo $remote | egrep -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | wc -l`
port="8080"

test_off() {
    node_ip_off=`ssh root@$remote "grep '#server 192.168.*' /etc/nginx/nginx.conf|grep  '$port' |grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}' "`
    #if [ "$node_ip" == "$node_ip_off" ];then
#	echo "当前节点已关闭，不用重复操作"
#	exit -1
#    fi
    result=$(echo $node_ip_off | grep -o $node_ip)
    if [[ "$result" != "" ]]
    then
        echo "当前节点: $result 已关闭，不用重复操作"
        exit -1
    fi
}
test_on() {
    node_ip_on=`ssh root@$remote "grep -E '^[[:space:]]{2,}server 192.168.*' /etc/nginx/nginx.conf|grep  '$port' |grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}' "`
    result=$(echo $node_ip_on | grep -o $node_ip)
    if [[ "$result" != "" ]]
    then
	echo "当前节点: $result 已开启，不用重复操作"
	exit -1
    fi
}
nginx_off_error() {
    count_off=`ssh root@$remote "grep -E '^[[:space:]]{2,}server 192.168.*' /etc/nginx/nginx.conf|grep  '$port' |wc -l"`
    if [ $count_off -le 1 ];then
	echo "已有灰度节点，不能关闭所有online节点"
	echo "当前灰度节点 :"
        echo "$node_ip_off"
	exit -1
    fi
}
list_node_ip() {
    ssh root@$remote "grep 'server 192.168.*' /etc/nginx/nginx.conf|grep '$port' |grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}' "
}
off_server() {
    test_off
    nginx_off_error
    ssh root@$remote "sed -i 's/^.*server '''$node_ip''':8080/      #server '''$node_ip''':8080/' /etc/nginx/nginx.conf"
    ssh root@$remote "sed -i 's/set \$proxy_pass_node.*/set \$proxy_pass_node $node_ip;/' /etc/nginx/common.conf.bak"
    ssh root@$remote "nginx -s reload"
    echo -e "关闭服务节点:$node_ip"
}
on_server() {
    test_on
    node_ip_on=`ssh root@$remote "grep 'server 192.168.*' /etc/nginx/nginx.conf|grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}' "`
    ssh root@$remote "sed -i 's/^.*server '''$node_ip''':8080/      server '''$node_ip''':8080/' /etc/nginx/nginx.conf"
    ssh root@$remote "nginx -s reload"
    echo -e "启动服务节点:$node_ip"
}

usage() {
    echo -e "Usage: bash huidu.sh -on 192.168.1.1 192.168.126.73"
    echo -e "-on <node_ip>\t<remote-node_ip>  节点上线"
    echo -e "-off  <node_ip>\t<remote-node_ip>  节点下线"
    echo -e "-list \t\t<remote-node_ip>  显示当前node_ip-list"
}
node_ip_check() {
    if [[ ! $node_ip ]] || [[ $count_ip == 0 ]];then
	echo -e "node_ip不能为空,或者node_ip不合法"
	exit -1
    fi
    if [[ $node_ip != 192.168.1.1 ]] && [[ $node_ip != 192.168.1.5 ]];then
	echo "$node_ip不存在与配置文件中"
	exit -1
    fi
}


if [[ $cmd == '-on' ]];then
    node_ip_check 2>/dev/null
    on_server 2>/dev/null
elif [[ $cmd == '-off' ]];then
    node_ip_check 2>/dev/null
    off_server 2>/dev/null
elif [[ $cmd == '-list' ]];then
    list_node_ip
else
    usage
fi
