#!/usr/bin/python
# -*- coding: UTF-8 -*-

import pymysql
import sys

from HttpUtil import http_put
from pytz import utc,timezone

if len(sys.argv) > 1:
    startTime = sys.argv[1]
    endTime = sys.argv[2]
    pageSize = int(sys.argv[3])
    pageNum = int(sys.argv[4])
    sq = sys.argv[5]
else:
    startTime = '2017-01-11 10:22:30'
    endTime = '2019-03-30 19:25:50'
    pageSize = 10
    pageNum = 1
    sq = ''
print(u"开始时间：%s" % (startTime))
print(u"结束时间：%s" % (endTime))
print(u"分页大小：%s" % (pageSize))
print(u"目标表后缀：%s" % (sq))


# config = {
#     'host': '192.168.2.14',
#     'port': 3306,
#     'user': 'tmsbjca',
#     'password': 'tmsbjca@Rds',
#     'db': 'tms_history',
#     'charset': 'utf8mb4',
#     'cursorclass': pymysql.cursors.Cursor,
# }
config = {
    'host': '192.168.126.122',
    'port': 3306,
    'user': 'root',
    'password': 'tiger',
    'db': 'tms',
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.Cursor,
}


def pagebean(pageNum, pageSize):
    if pageNum > 0:
        pageNum -= 1
    start = pageNum * pageSize
    return {
        "start": start,
        "offset": pageSize
    }


# Connect to the database
connection = pymysql.connect(**config)
try:
    table_name = 'doctor_recipe_info' + sq
    table_name_result = 'recipe_sign_info' + sq
    print(u"目标表：%s" % (table_name))
    sql_common1 = ' where CREATE_TIME >= %s and CREATE_TIME <= %s'
    #sql_common1 = ' where CREATE_TIME >= "'+startTime+'" and CREATE_TIME <= "' + endTime +'"'
    limit_sql_page = ' select uniqueid as id from ' + table_name + sql_common1 + ' ORDER BY CREATE_TIME limit %s,%s'
    sql_recipe = ' select uniqueid,recipe_info,firm_id,up_default2,sign_time,subject,status,user_uniqueid,create_time,update_time,patient_name,patient_card_num,stamp_log_id,doctor_name from '+\
table_name + ' a join( '+ limit_sql_page + ') as b on a.uniqueid = b.id'
    sql_recipe = ' select c.*,d.signed_pdf_url,e.department from' + '(' + sql_recipe + ') as c left join ' + table_name_result + ' d on c.uniqueid = d.recipeid' +\
        ' LEFT JOIN user_firm_relations e ON c.user_uniqueid = e.user_id'
    sql_recipe_count = 'select COUNT(*) from ' + table_name + sql_common1

    processCount = 0;
    with connection.cursor() as cursor:
        # 查询目标1
        total = cursor.execute(sql_recipe_count, [startTime, endTime])
        #total = cursor.execute(sql_recipe_count)
        result = cursor.fetchall()
        if result[0][0] == 0:
            exit()

        pageTotal = result[0][0] / pageSize + 1
        print(u"总页数%d" % (pageTotal))
        for i in range(pageNum - 1, pageTotal + 1):
            if i == 0:
                continue
            offsetBean = pagebean(i, pageSize)
            print(offsetBean["start"], offsetBean["offset"])
            count1 = cursor.execute(sql_recipe, [startTime, endTime, offsetBean["start"], offsetBean["offset"]])
            #count1 = cursor.execute(sql_recipe, [offsetBean["start"], offsetBean["offset"]])
            if count1 == 0:
                break
            # 插入es
            print(u"处理页数%d" % (i))
            result = cursor.fetchall()  # 取出所有行
            for j in result:  # 打印结果
                # print(i[0])
                #url = 'http://123.56.30.195:9200/production_ywq_tms/production_ywq_recipe_info/' + j[0]
                url = 'http://192.168.126.73:9200/test_ywq_order/order/' + j[0]

                tz = timezone("Asia/Shanghai")
                if j[4] is not None:
                    signTime = tz.localize(j[4]).astimezone(utc)
                else:
                    signTime = None
                createTime = tz.localize(j[8]).astimezone(utc)
                if j[9] is not None:
                    updateTime = tz.localize(j[9]).astimezone(utc)
                else:
                    updateTime = None
                if j[9] is not None:
                    updateTime = tz.localize(j[9]).astimezone(utc)
                else:
                    updateTime = None
                if j[11] is not None:
                    patient_card_num = j[11]
                else:
                    patient_card_num = None
                if j[13] is not None:
                    pdf_url = j[14]
                else:
                    pdf_url = None
                values = {
                    'uniqueid':j[0],
                    'recipeInfo': j[1],
                    'firmId': j[2],
                    'upDefault2': j[3],
                    'signTime': signTime,
                    'subject': j[5],
                    'status': j[6],
                    'userUniqueid': j[7],
                    'createTime': createTime,
                    'updateTime': updateTime,
                    'patientName':j[10],
                    'patientCardNum': patient_card_num,
                    'stampLogId': j[12],
                    'doctorName': j[13],
                    'signedPdfUrl': pdf_url,
                    'department':j[15],
                }

                http_put(url, values)
                #print(u"处理数据id %s" % j[0])
                processCount += 1
                #break
            print(u"处理当前页码： %d" % (i))
            #break

        print(u"处理总页数%d" % (pageTotal))
        print(u"处理总条数%d" % (processCount))
    # connection.rollback()
    connection.commit()  # 提交事务
except Exception, e:
    connection.rollback()  # 若出错了，则回滚
    print(u"异常了")
    print(repr(e))
finally:
    connection.close()
