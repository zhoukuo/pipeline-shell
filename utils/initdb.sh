#!/bin/sh

DB=$1

if [[ ! -f "hospital-full.sql" ]]; then
	wget http://47.95.231.203:8082/shared/release/hospital-in/hospital/latest/sql/hospital-full.sql
fi

sed -i "s/use hospital.*/use $DB;/" hospital-full.sql
mysql -h 192.168.2.14 -uhospital -phospital@Rds -e "DROP DATABASE $DB;"
mysql -h 192.168.2.14 -uhospital -phospital@Rds < hospital-full.sql
