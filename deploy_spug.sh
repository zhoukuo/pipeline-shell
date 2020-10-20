#!/bin/bash

source_ip=$1
source_dir=$2
app_name=$3
app_type=$4         # maven/npm/static
dest_dir=$5

timestamp=`date +"%Y/%m/%d %H:%M:%S"`


function deploy() {

    if [[ "$app_type" != "maven" ]] && [[ "$app_type" != "npm" ]] && [[ "$app_type" != "static" ]]; then
        echo -e "$timestamp - 应用类型错误！[maven/npm/static]"
        exit -1
    fi

    mkdir -pv $dest_dir
    cd $dest_dir

    echo -e "$timestamp - 清理环境，保留日志和本地配置 ..."
    if [[ "$app_type" == "tomcat" ]]; then
        rm -fr ${app_name%.*}*
        rm -fr *.sh
        rm -fr template*
    else
        ls | grep -v "initdb.sh" | grep -v ".log" | grep -v "logs" | grep -v "archive" |grep -v "catlina.out" | grep -v "config" | grep -v "myconf" | grep -v "disconfig"| grep -v "static" | grep -v "template" | xargs rm -fr
    fi
    
    echo -e "$timestamp - 获取部署包: http://$source_ip:8082/#//$source_dir" 
    wget -m -nd -nv -e robots=off http://$source_ip:8082/shared//$source_dir
    rm -f index.html build-*
    pwd
    ls -lh

    if [[ "$app_type" == "static" ]]; then
        echo -e "解压缩文件..."
        tar -xvf $app_name > /dev/null
        rm -f $app_name
        pwd
        ls -lh
    fi

    echo -e "$timestamp - 获取部署脚本 ..."
    wget -m -nd -nv http://$source_ip:8082/shared//devops/verify.sh
    chmod 755 verify.sh
}


function restart() {
    
    if [[ "$app_type" == "maven" ]]; then
        echo -e "$timestamp - 重启服务 ..."
        supervisorctl restart $app_name
        ps -ef | grep -v "grep" | grep $dest_dir/$app_name
        echo -e "$timestamp - 服务验证 ..."
        ./verify.sh $dest_dir/$app_name
        exit $?

    elif [[ "$app_type" == "npm" ]]; then
        echo -e "$timestamp - 服务验证 ..."
        exit $?

    elif [[ "$app_type" == "static" ]]; then
        echo -e "$timestamp - 服务验证 ..."
        exit $?
    else
        echo -e "$timestamp - 应用类型错误！[maven/npm/static]"
        exit -1
    fi
}

deploy
restart
