#!/bin/bash

source_dir=$1
dest_ip=$2
dest_dir=/opt/builds/$3
latest=$4

timestamp=`date +"%Y/%m/%d %H:%M:%S"`

if [[ "$dest_ip" == "47.95.231.203" ]]; then
    port=22222
    showip=$dest_ip
elif [[ "$dest_ip" == "192.168.126.39" ]]; then
    port=22
    showip=$dest_ip
else
    echo "文件服务器IP有误！[192.168.122.39/47.95.231.203]"
    exit -1
fi

ls $source_dir -lh

echo -e "\n$timestamp - 正在上传布署文件到：http://$showip:8082/#/${dest_dir:12}"
ssh root@$dest_ip -p$port "
    mkdir -pv $dest_dir
exit "

scp -P$port -r $source_dir/* root@$dest_ip:$dest_dir

echo -e "$timestamp - 上传完成！"


if [[ "$latest" == "yes" ]];then
    url=$3
    echo -e "\n$timestamp - 正在上传布署文件到：http://$showip:8082/#/${url%/*}/latest"
    ssh root@$dest_ip -p$port "
        mkdir -pv ${dest_dir%/*}/latest    # 从右至左截取/左边所有字符
        rm ${dest_dir%/*}/latest/* -fr
        cp -rp ${dest_dir}/* ${dest_dir%/*}/latest
        cd ${dest_dir%/*}/latest

        for file in \`ls | grep .apk\`
        do
            newfile=\`echo $file | awk -F - '{print $1}'\`
            echo $newfile
            mv $file ${newfile}.apk
        done

        cd ${dest_dir%/*}/latest/sql
        mv ywx-ddl-full-*.sql ywx-ddl-full.sql
        mv ywx-dml-full-*.sql ywx-dml-full.sql
        mv hospital-full-*.sql hospital-full.sql

        if [[ -d \"${dest_dir%/*}/latest/sql\" ]]; then
            mkdir -pv ${dest_dir%/*}/sql
            cd ${dest_dir%/*}/sql
            rm *-full-*.sql
            cp -fp ${dest_dir%/*}/latest/sql/*.sql .
        fi
        
    exit "
fi

echo -e "$timestamp - 上传完成！\n"

exit
