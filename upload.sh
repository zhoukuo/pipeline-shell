#!/bin/bash

target=$1
app_name=$2
dest_ip=$3
source_dir=output
dest_dir=/opt/builds/$4


timestamp=`date +"%Y/%m/%d %H:%M:%S"`


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
    tar -zcf $app_name -C ../$target . --exclude=output --exclude=.svn --exclude=.git --exclude=upload.sh
elif [[ -f "../$target/$app_name" ]]; then
    cp ../$target/$app_name ./
else
    echo "$target/$app_name not found!"
    exit -1
fi

if [[ "$app_name" =~ ".jar" ]] && [[ -d "../$target/lib" ]];then
    tar -zcf lib.tar.gz  -C ../$target lib
fi

touch ${app_name%%.*}-${BUILD_NUMBER}-${GIT_COMMIT:0:8}

ls -lh


echo -e "\n$timestamp - 正在准备文件服务器目录..."
ssh root@$dest_ip -p$port "
    mkdir -pv $dest_dir/build-${BUILD_NUMBER};
    mkdir -pv $dest_dir/build-latest;
    cd $dest_dir/build-latest;
    rm ** -fr;
exit "


echo -e "\n$timestamp - 正在上传布署文件到：http://$showip:8082/#/${dest_dir:12}/build-${BUILD_NUMBER}"
scp -P$port ../output/* root@$dest_ip:$dest_dir/build-${BUILD_NUMBER}

echo -e "$timestamp - 正在上传布署文件到：http://$showip:8082/#/${dest_dir:12}/build-latest\n"
ssh root@$dest_ip -p$port "
    cp -r $dest_dir/build-${BUILD_NUMBER}/* $dest_dir/build-latest
exit "

echo -e "$timestamp - 上传完成！\n"

exit
