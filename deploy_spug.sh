#!/bin/bash

source_ip=$1
source_dir=$2
app_name=$3
app_type=$4         # maven/static
dest_dir=$5



function deploy() {

    if [[ "$app_type" != "maven" ]] && [[ "$app_type" != "static" ]]; then
        echo -e "`date '+%D %T'` - 应用类型错误！[maven/static]"
        exit -1
    fi

    if [[ "$SPUG_HOST_NAME" == "$source_ip" ]]; then
        echo "`date '+%D %T'` 构建/出库操作，跳过部署步骤 ..."
        exit 0
    fi

    mkdir -pv $dest_dir
    cd $dest_dir

    echo -e "`date '+%D %T'` - 清理环境，保留日志和本地配置 ..."
    ls | grep -v ".log" | grep -v "logs" | grep -v "archive" |grep -v "catlina.out" | grep -v "config" | grep -v "myconf" | grep -v "disconfig"| grep -v "static" | grep -v "template" | xargs rm -fr
    
    echo -e "`date '+%D %T'` - 获取部署包: http://$source_ip:8082/#//$source_dir" 
    wget -m -nd -nv -e robots=off http://$source_ip:8082/shared//$source_dir
    rm -f index.html build-*
    pwd
    ls -lh

    if [[ "$app_type" == "static" || "$app_type" == "npm" ]]; then
        echo -e "解压缩文件..."
        tar -xvf $app_name > /dev/null
        rm -f $app_name
        pwd
        ls -lh
    fi

    echo -e "`date '+%D %T'` - 获取部署脚本 ..."
    wget -q -m -nd -nv http://$source_ip:8082/shared//devops/verify.sh
    chmod 755 verify.sh
}


function restart() {

    if [[ "$app_type" == "maven" ]]; then
        echo -e "`date '+%D %T'` - 重启服务 ..."
        supervisorctl restart $app_name
        ps -ef | grep -v "grep" | grep $dest_dir/$app_name
        echo -e "`date '+%D %T'` - 服务验证 ..."
        ./verify.sh $dest_dir/$app_name
        exit $?

    elif [[ "$app_type" == "static" || "$app_type" == "npm" ]]; then
        echo -e "`date '+%D %T'` - 服务验证 ..."
        exit $?
    else
        echo -e "`date '+%D %T'` - 应用类型错误！[maven/static]"
        exit -1
    fi
}

deploy
restart
