#/usr/bin/bash

echo -n "1/4 please input host name: "
read hostname
echo -e "127.0.0.1   localhost "$hostname"\n::1         localhost "$hostname >/etc/hosts
echo $hostname >/etc/hostname

echo -n "2/4 please input internal ip: "
read internal_ip
if [ ! -n "$internal_ip" ]; then
    sed -i s/ONBOOT=\"yes\"/ONBOOT=\"no\"/ /etc/sysconfig/network-scripts/ifcfg-eth0
else
    sed -i s/IPADDR.*/IPADDR=192.168.122.$internal_ip/ /etc/sysconfig/network-scripts/ifcfg-eth0
    sed -i s/ONBOOT=\"no\"/ONBOOT=\"yes\"/ /etc/sysconfig/network-scripts/ifcfg-eth0
fi

echo -n "3/4 please input public ip: "
read public_ip
if [ ! -n "$public_ip" ]; then
    sed -i s/ONBOOT=\"yes\"/ONBOOT=\"no\"/ /etc/sysconfig/network-scripts/ifcfg-eth1
else
    sed -i s/IPADDR.*/IPADDR=192.168.126.$public_ip/ /etc/sysconfig/network-scripts/ifcfg-eth1
    sed -i s/ONBOOT=\"no\"/ONBOOT=\"yes\"/ /etc/sysconfig/network-scripts/ifcfg-eth1
fi

echo -n "4/4 "
passwd ywq

echo "new internal ip: 192.168.122."$internal_ip
echo "new public ip: 192.168.126."$public_ip

echo -e "Please Restart Computer To Update Settings !!!"

