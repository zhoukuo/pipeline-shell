#!/usr/bin/env python
# -*- coding:utf-8 -*-
import urllib2

import urllib2
import json
from datetime import datetime, timedelta
from pytz import utc
from pytz import timezone

cst_tz = timezone('Asia/Shanghai')

url = 'http://192.168.126.73:9200/hd-test/order/1'
now = datetime.now().replace(tzinfo=cst_tz)
nowUtc = now.astimezone(utc)
values = {'name': 'hudand', 'age': 20,"crateTime":nowUtc}

def http_put(url, data):
    jdata = json.dumps(data, cls=ComplexEncoder)                  # 对数据进行JSON格式化编码i
    request = urllib2.Request(url, jdata)
    request.add_header('Content-Type', 'application/json')
    request.get_method = lambda: 'PUT'  # 设置HTTP的访问方式
    request = urllib2.urlopen(request)
    return request.read()

class ComplexEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime):
            obj.astimezone(utc)
            return obj.strftime('%Y-%m-%dT%H:%M:%S.000Z')
        elif isinstance(obj, date):
            return obj.strftime('%Y-%m-%d')
        else:
            return json.JSONEncoder.default(self, obj)
#resp = http_put(url,values)
#print resp
