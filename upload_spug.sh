#!/bin/bash

target=$1
app_name=$2
dest_ip=$3
dest_dir=/opt/builds/$4

source_dir=output
timestamp=`date +"%Y/%m/%d %H:%M:%S"`
GIT_COMMIT=`git rev-parse --short HEAD`

if [[ "$dest_ip" == "47.95.231.203" ]]; then
    port=22222
    showip=47.95.231.203
elif [[ "$dest_ip" == "192.168.1.17" ]]; then
    port=22222
    showip=47.95.231.203
elif [[ "$dest_ip" == "192.168.122.39" ]]; then
    port=22
    showip="192.168.126.39"
    dest_ip=192.168.126.39
elif [[ "$dest_ip" == "192.168.126.39" ]]; then
    port=22
    showip="192.168.126.39"
    dest_ip=192.168.126.39
else
    echo "文件服务器IP有误！[192.168.122.39/47.95.231.203/192.168.1.17]"
    exit -1
fi

echo -e "\n$timestamp - 正在收集布署文件..."
rm $source_dir -fr
mkdir $source_dir
cd $source_dir

if [[ "$app_name" =~ ".tar" ]];then
    tar -zcf $app_name -C ../$target . --exclude=output --exclude=.svn --exclude=.git --exclude=upload_spug.sh
elif [[ -f "../$target/$app_name" ]]; then
    cp ../$target/$app_name ./
else
    echo "$target/$app_name not found!"
    exit -1
fi

touch ${app_name%%.*}-${SPUG_RELEASE}-${GIT_COMMIT}

ls -lh


echo -e "\n$timestamp - 正在准备文件服务器目录..."
ssh root@$dest_ip -p$port "
    mkdir -pv $dest_dir;
    cd $dest_dir;
    cd ..;

    mkdir -pv build-latest;
    rm build-latest/** -fr;
exit "


echo -e "\n$timestamp - 正在上传布署文件到：http://$showip:8082/#/${dest_dir:12}"
scp -P$port ../output/* root@$dest_ip:$dest_dir

ssh root@$dest_ip -p$port "
    cd $dest_dir
    cp * ../build-latest
exit "

echo -e "$timestamp - 上传完成！\n"

exit
