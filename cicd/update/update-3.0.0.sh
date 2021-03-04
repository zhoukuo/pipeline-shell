
# nginx.conf（nginx节点）
events {
    worker_connections  5000;
    use                 epoll;
    accept_mutex        on;
}

# 针对缺失"X-Content-Type-Options"头漏洞整改建议
add_header X-Content-Type-Options nosniff;
# 针对缺失"X-XSS-Protection"头漏洞整改建议
add_header X-XSS-Protection "1; mode=block";
# 针对点击劫持：X-Frame-Options头缺失漏洞的整改建议
add_header X-Frame-Options "SAMEORIGIN";
# 针对缺少HTTP Strict-Transport-Security头漏洞的整改建议
add_header Strict-Transport-Security "max-age=31536000;includeSubdomains;";


# 日志清理
(crontab -l;echo '0 2 * * * rm `ls -t /usr/local/nginx/nginx-1.16.1/logs | tail -n +15`')| crontab

# 日志文件切割
/bin/cp logrotate/nginx /etc/logrotate.d/


# mysql允许最大连接数(存储节点)
# vi /etc/my.cnf
sed -i 's/max_connections=200/max_connections=3000/' /etc/my.cnf


# 启用进程守护(所有节点)
gateway.jar.service
hisca.jar.service
robot.jar.service
nginx.service
mysqld.service
redis.service

# 服务异常退出时拉起，在.service文件[Service]段中增加
Restart=on-failure
# 让配置生效
systemctl daemon-reload

# 重启服务
systemctl restart xxx.service

