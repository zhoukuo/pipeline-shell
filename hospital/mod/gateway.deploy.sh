#!/bin/sh
# 等号两侧不要有空格

# 默认为latest，拉取最新的包，如果布署指定的版本，把latest替换成具体的版本号，例如：1.0.0
version=latest
#version=1.0.0
# 服务部署在哪个节点上，根据医院实际情况修改
dest_ip=$1
# 服务布署在哪个目录，不要修改
dest_dir=/opt/gateway
# 服务包名称，不要修改
app_name=gateway.jar
# 从哪个服务器获取服务包，不要修改
source_dir=release/hospital-in/ywx/${version}/pkg
# 从哪个目录获取服务包，不要修改
source_ip=47.95.231.203
# 服务类型，不要修改
app_type=spring_boot
# 堆内存大小，不要修改
jvm_heap=1024m

if [[ ! -f "./mod/deploy.sh" ]]; then
    wget http://$source_ip:8082/shared/devops/deploy.sh -O ./mod/deploy.sh;
fi
sh ./mod/deploy.sh $source_ip $source_dir $app_name $app_type $dest_ip $dest_dir $jvm_heap;
exit

