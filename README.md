# migratetbl

## Configration

```bash
source_ip="192.168.2.10"
source_db_name="tms"
source_db_user="tmsbjca"
source_db_pwd="tmsbjcaRds"

dest_ip="192.168.2.14"
dest_db_name="tms_history"
dest_user="tmsbjca"
dest_pwd="tmsbjca@Rds"

operator=$1         # -ei/-e/-i
keywords=$2         # doctor_recipe_info_.*|recipe_sign_info_.*
```

## Usage
- -ei <tablename>  导出并导入表
- -e  <tablename>  导出表
- -i  <tablename>  导入表
- -ei <tablename.*> 批量导出并导入包含tablename的表

## Sample
```Bash
./migratetbl.sh -ei all
./migratetbl.sh -ei doctor_recipe_info_6
./migratetbl.sh -ei doctor_recipe_info_.*
./migratetbl.sh -ei recipe_sign_info_.*
./migratetbl.sh -ei .*recipe.*_info_.*
```

## Demo

``` bash
>$./migratetbl.sh -ei doctor_recipe_info_.*
2019/02/25 13:34:18 需要导出并导入的表: 
doctor_recipe_info_6
doctor_recipe_info_7
doctor_recipe_info_8
doctor_recipe_info_9
2019/02/25 13:34:18 From 192.168.126.73/food To 192.168.126.71/food ...
2019/02/25 13:34:18 开始导出：doctor_recipe_info_6
2019/02/25 13:34:18 导出完成！doctor_recipe_info_6(0)
2019/02/25 13:34:18 开始导出：doctor_recipe_info_7
2019/02/25 13:34:18 导出完成！doctor_recipe_info_7(0)
2019/02/25 13:34:18 开始导出：doctor_recipe_info_8
2019/02/25 13:34:18 导出完成！doctor_recipe_info_8(0)
2019/02/25 13:34:18 开始导出：doctor_recipe_info_9
2019/02/25 13:34:18 导出完成！doctor_recipe_info_9(0)
2019/02/25 13:34:18 开始导入: doctor_recipe_info_6
2019/02/25 13:34:18 导入完成！doctor_recipe_info_6(0)
2019/02/25 13:34:18 结果验证：[SUCCESS] 
2019/02/25 13:34:18 开始导入: doctor_recipe_info_7
2019/02/25 13:34:18 导入完成！doctor_recipe_info_7(0)
2019/02/25 13:34:18 结果验证：[SUCCESS] 
2019/02/25 13:34:18 开始导入: doctor_recipe_info_8
2019/02/25 13:34:18 导入完成！doctor_recipe_info_8(0)
2019/02/25 13:34:18 结果验证：[SUCCESS] 
2019/02/25 13:34:18 开始导入: doctor_recipe_info_9
2019/02/25 13:34:18 导入完成！doctor_recipe_info_9(0)
2019/02/25 13:34:18 结果验证：[SUCCESS] 

======================== 执行结果 ===========================
+----------------------------------------------------------+
|表名			            |条数	 |导出耗时    |导入耗时        |
+----------------------------------------------------------+
|doctor_recipe_info_6 	 |0 	 |0分1秒      |0分1秒       |
|doctor_recipe_info_7 	 |0 	 |0分1秒      |0分1秒       |
|doctor_recipe_info_8 	 |0 	 |0分2秒      |0分1秒       |
|doctor_recipe_info_9 	 |0 	 |0分1秒      |0分1秒       |
+----------------------------------------------------------+
```

