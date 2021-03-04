#!/bin/bash

source_ip="192.168.2.10"
source_db_name="tms"
source_db_user="tmsbjca"
source_db_pwd="tmsbjcaRds"

dest_ip="192.168.2.14"
dest_db_name="tms_history"
dest_user="tmsbjca"
dest_pwd="tmsbjca@Rds"


operator=$1         # -ei/-e/-i
keywords=$2         # doctor_recipe_info_.* | recipe_sign_info_.* | user_sign_extends_.* | firm_info | archive_catalog_info

tmpdir="./tmp"
timestamp=`date +"%Y/%m/%d %H:%M:%S"`

index_1=0
index_2=0
tables=""
count_index=0
count=0


export_table() {
    for i in $tables
    do
        start_time=`date +%s`
        online_count=`mysql -u$source_db_user -p$source_db_pwd -h $source_ip -D$source_db_name -se "use $source_db_name;select count(*) from $i" 2>/dev/null`
        if [[ "$online_count" != "5000000" ]]; then
            echo -e "\e[00;31m[ERROR] table:$i record != 5000000\e[00m"
            continue
        fi
        timestamp=`date +"%Y/%m/%d %H:%M:%S"`
        echo -e "$timestamp 开始导出：$i"
        mysqldump  --single-transaction -u$source_db_user -p$source_db_pwd $source_db_name -h $source_ip $i > $tmpdir/$i 2>/dev/null
        if [[ "$?" != "0" ]];then
            timestamp=`date +"%Y/%m/%d %H:%M:%S"`
            echo -e "$timestamp \033[31;1m数据导出失败，异常退出！\033[0m"
            exit -1
        fi
        timestamp=`date +"%Y/%m/%d %H:%M:%S"`
        echo -e "$timestamp 导出完成！$i($online_count)"
        end_time=`date +%s`
        time_1=`expr $end_time - $start_time + 1`
        time_minute_1=`expr $time_1 / 60`
        time_second_1=`expr $time_1 % 60`
        table[$index_1]=$i
        count[$index_1]=$online_count
        e_m_time[$index_1]=$time_minute_1
        e_s_time[$index_1]=$time_second_1
        index_1=`expr $index_1 + 1`
    done
}

import_table() {
    for j in $tables
    do
        start_time=`date +%s`
        online_count=`mysql -u$source_db_user -p$source_db_pwd -h $source_ip -D$source_db_name -se "use $source_db_name;select count(*) from $j" 2>/dev/null`
        if [[ "$online_count" != "5000000" ]]; then
            echo -e "\e[00;31m[ERROR] table:$i record != 5000000\e[00m"
            continue
        fi
        timestamp=`date +"%Y/%m/%d %H:%M:%S"`
        echo -e "$timestamp 开始导入: $j"
        mysql -u$dest_user -p$dest_pwd -h$dest_ip $dest_db_name < $tmpdir/$j 2>/dev/null
        if [[ "$?" != "0" ]]; then
            timestamp=`date +"%Y/%m/%d %H:%M:%S"`
            echo -e "$timestamp \033[31;1m数据导入失败，异常退出！\033[0m"
            exit -1
        fi
        local_count=`mysql -u$dest_user -p$dest_pwd -h$dest_ip -D$dest_db_name -se "use $dest_db_name;select count(*) from $j" 2>/dev/null`
        timestamp=`date +"%Y/%m/%d %H:%M:%S"`
        echo -e "$timestamp 导入完成！$j($local_count)"

        if [ $online_count == $local_count ];then
            echo -e "$timestamp 结果验证：\033[32;1m[SUCCESS] \033[0m"
        else
            echo -e "$timestamp 结果验证：\033[31;1m[FAILED] \033[0m"
            echo -e "$timestamp 数据导入失败，异常退出！"
            exit -1
        fi

        end_time=`date +%s`
        time_2=`expr $end_time - $start_time + 1`
        time_minute_2=`expr $time_2 / 60`
        time_second_2=`expr $time_2 % 60`
        table[$index_2]=$j
        count[$index_2]=$local_count
        i_m_time[$index_2]=$time_minute_2
        i_s_time[$index_2]=$time_second_2
        index_2=`expr $index_2 + 1`
    done
}

usage() {
    echo -e "Usage:"
    echo -e "-ei <tablename>\t  导出并导入表"
    echo -e "-e  <tablename>\t  导出表"
    echo -e "-i  <tablename>\t  导入表"
    echo -e "-ei <tablename.*> 批量导出并导入包含tablename的表"
}

# parse keywords
if [ ! -n "$keywords" ];then
    usage
    exit -1
elif [ "$keywords" == "all" ];then
    tables=`mysql -u$source_db_user -p$source_db_pwd -h $source_ip -D$source_db_name  -se "show tables;" 2>/dev/null`
elif [[ "$keywords" =~ ".*" ]];then
    tables=`mysql -u$source_db_user -p$source_db_pwd -h $source_ip -D$source_db_name  -se "show tables;" 2>/dev/null |grep  $keywords`
else
    tables=`mysql -u$source_db_user -p$source_db_pwd -h $source_ip -D$source_db_name  -se "show tables;" 2>/dev/null |grep -w $keywords`
fi

if [ "$tables" == "" ];then
    echo -e "$timestamp table:'$keywords'不存在！"
    exit -1
fi

mkdir -pv ./tmp >/dev/null
# parse operator
if [ "$operator" == "-e" ];then
    echo -e "\n$timestamp 需要导出的表: "
    echo -e "$tables"
    echo -e "$timestamp From $dest_ip/$dest_db_name ..."
    export_table
    count_index=$index_1
elif [ "$operator" == "-i" ];then
    echo -e "\n$timestamp 需要导入的表: "
    echo -e "$tables"
    echo -e "$timestamp To $source_ip/$source_db_name ..."
    import_table
    count_index=$index_2
elif [ "$operator" == "-ei" ];then
    echo -e "\n$timestamp 需要导出并导入的表: "
    echo -e "$tables"
    echo -e "$timestamp From $source_ip/$source_db_name To $dest_ip/$dest_db_name ..."
    export_table
    import_table
    count_index=$index_2
else
    usage
    exit -1
fi
echo -e "\n================================= 执行结果 =================================="
echo -e "+---------------------------------------------------------------------------+"
echo -e "|表名\t\t\t |条数\t\t\t |导出耗时     |导入耗时    |"
echo -e "+---------------------------------------------------------------------------+"
for i in $(seq 0 `expr $count_index - 1`)
do
    if [ "$operator" == "-i" ];then
        e_m_time[$i]="0"
        e_s_time[$i]="0"
    elif [ "$operator" == "-e" ];then
        i_m_time[$i]="0"
        i_s_time[$i]="0"
    fi
    echo -e "|${table[$i]} \t |${count[$i]} \t |${e_m_time[$i]}分${e_s_time[$i]}秒      |${i_m_time[$i]}分${i_s_time[$i]}秒      |"
done
echo -e "+---------------------------------------------------------------------------+"

