#!/bin/bash

source_ip=$1
source_dir=$2
app_name=$3
app_type=$4;         #spring_boot/tomcat/static
dest_ip=$5
dest_dir=$6
patch_file=$7


function params_prepare() {
    tomcat_home=${dest_dir%/*}
    timestamp=`date +"%Y/%m/%d %H:%M:%S"`

    if [[ "$app_type" != "spring_boot" ]] && [[ "$app_type" != "tomcat" ]] && [[ "$app_type" != "static" ]]; then
        echo -e "$timestamp - 应用类型错误！[spring_boot/tomcat/static]"
        exit -1
    fi

    # 无论用户输入哪个网段，生产访问都走1网段
    if [[ "$source_ip" == "192.168.1.17" ]]; then
        show_ip=47.95.231.203
        source_ip=192.168.1.17
    elif [[ "$source_ip" == "47.95.231.203" ]]; then
        show_ip=47.95.231.203
        source_ip=192.168.1.17
    # 无论用户输入哪个网段，内网访问都走122网段
    elif [[ "$source_ip" == "192.168.122.39" ]]; then
        show_ip=192.168.126.39
        source_ip=192.168.126.39
    elif [[ "$source_ip" == "192.168.126.39" ]]; then
        show_ip=192.168.126.39
        source_ip=192.168.126.39
    else
        echo -e "$timestamp - 文件服务器IP有误！[192.168.122.39/47.95.231.203/192.168.1.17]"
        exit -1
    fi

    #check port
    ssh -q -o ConnectTimeout=3 root@$dest_ip -p22222 "exit"
    if [ "$?" == "0" ]; then
        port=22222
    else
        port=22
    fi
    echo "PORT:"$port
}

params_prepare

ssh root@$dest_ip -p$port "

    function deploy() {
        mkdir -pv $dest_dir
        cd $dest_dir

        echo -e "$timestamp - 清理环境，保留日志和本地配置 ..."
        if [[ \"$app_type\" == \"tomcat\" ]]; then
            rm -fr ${app_name%.*}*
            rm -fr *.sh
            rm -fr template*
        else
            ls | grep -v "initdb.sh" | grep -v ".log" | grep -v "logs" | grep -v "archive" |grep -v "catlina.out" | grep -v "config" | grep -v "myconf" | grep -v "disconfig"| grep -v "static" | grep -v "template" | xargs rm -fr
        fi
        
        echo -e "$timestamp - 获取部署包: http://$show_ip:8082/#//$source_dir" 
        wget -m -nd -nv http://$source_ip:8082/shared//$source_dir
        rm -f index.html build-*
        pwd
        ls -lh

        if [[ \"$app_type\" == \"static\" ]]; then
            echo -e "解压缩文件..."
            tar -xvf $app_name > /dev/null
            rm -f $app_name
            pwd
            ls -lh
        elif [[ -f \"lib.tar.gz\" ]]; then
            tar -xvf lib.tar.gz > /dev/null
        fi

        echo -e "$timestamp - 获取部署脚本 ..."        
        wget -m -nd -nv http://$source_ip:8082/shared//devops/verify.sh
        chmod 755 verify.sh
    }

    function patches() {
        mkdir -pv $dest_dir
        cd $dest_dir

        echo -e "$timestamp - 获取补丁包: http://$show_ip:8082/#//$patch_file" 
        mkdir -pv patch
        cd patch
        rm ** -fr
        wget -nv http://$source_ip:8082/shared//$patch_file
        if [[ ! -f \"${patch_file##*/}\" ]]; then
            echo -e "$timestamp - ${patch_file##*/} - 找不到补丁包文件！"
            exit -1
        fi

        echo -e "$timestamp - 提取补丁文件 ..."
        pwd
        # 去掉路径，只保留文件名
        if [[ \"${patch_file##*.}\" == \"zip\" ]]; then
            unzip ${patch_file##*/} | grep inflating
        else
            echo -e "$timestamp - ${patch_file##*/} - 补丁文件格式不正确，请上传.zip文件！"
            exit -1
        fi

        echo -e "$timestamp - 制作布署包 ..."
        cd ../
        mkdir -pv tmp
        cd tmp
        rm ** -fr
        jar -xf ../${app_name}
        cp -fr ../patch/* .
        jar -cfm0 ${app_name} META-INF/MANIFEST.MF .
        mv ${app_name} ../
        cd ../
        ls -lh | grep ${app_name}
        # rm tmp patch -fr
    }

    function restart() {
        if [[ \"$app_type\" == \"spring_boot\" ]]; then
            echo -e "$timestamp - 重启服务 ..."
            supervisorctl restart $app_name
            ps -ef | grep -v "grep" | grep $dest_dir/$app_name
            echo -e "$timestamp - 服务验证 ..."
            ./verify.sh $dest_dir/$app_name
            exit $?

        elif [[ \"$app_type\" == \"tomcat\" ]]; then
            echo -e "$timestamp - 重启服务 ..."
            supervisorctl restart $tomcat_home
            ps -ef | grep -v "grep" | grep 'tomcat'| grep $tomcat_home

            echo -e "$timestamp - 服务验证 ..."
            ./verify.sh $tomcat_home
            exit $?

        elif [[ \"$app_type\" == \"static\" ]]; then
            echo -e "$timestamp - 服务验证 ..."
            exit $?
        else
            echo -e "$timestamp - 应用类型错误！[spring_boot/tomcat/static]"
            exit -1
        fi
    }

    if [[ \"$patch_file\" != \"\" ]]; then
        patches
        restart
    else
        deploy
        restart
    fi
"
