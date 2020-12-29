#!/bin/sh
# 等号两侧不要有空格

# 默认为latest，拉取最新的包，如果布署指定的版本，把latest替换成具体的版本号，例如：1.0.0
version=latest
#version=1.0.0
# 服务部署在哪个节点上，根据医院实际情况修改
dest_ip=$1
# 服务布署在哪个目录，不要修改
dest_dir=/opt/iop-robot
# 服务包名称，不要修改
app_name=robot.jar
# 从哪个服务器获取服务包，不要修改
source_dir=release/3rdparty/iop-robot/build-${version}
# 从哪个目录获取服务包，不要修改
source_ip=`cat license | grep repo.ip | awk -F = '{print $2}'`
port=`cat license | grep repo.port | awk -F = '{print $2}'`
# set default value if source_ip or port is null
source_ip=${source_ip:=47.95.231.203}
port=${port:=8082}
# 服务类型，不要修改
app_type=spring_boot
# 堆内存大小，不要修改
jvm_heap=1024m

if [[ ! -f "./mod/deploy.sh" ]]; then
    wget http://$source_ip:$port/shared/devops/deploy.sh -O ./mod/deploy.sh;
fi
sh ./mod/deploy.sh $source_ip $source_dir $app_name $app_type $dest_ip $dest_dir $jvm_heap;
exit

