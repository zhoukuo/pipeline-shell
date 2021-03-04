#!/usr/bin/bash

path=/var/lib/libvirt/images
dname=$2
internal_ip=$3
public_ip=$4

sname=centos7.small
spip=192.168.126.58
siip=192.168.122.58

create() {
    ping=`ping -c 3 $spip | awk 'NR==7 {print $4}'`

    if [[ "$ping" == "3" ]]; then
        echo "[ERROR]: a vm was created, but not change ip yet!"
        exit -1
    fi

    virt-clone -o $sname -n $dname -f $path/$dname.qcow2

    if [ ! -n "$internal_ip" ]; then
        sed -i s/$siip// /etc/libvirt/qemu/$dname.xml
    else
        sed -i s/$siip/192.168.122.$internal_ip/ /etc/libvirt/qemu/$dname.xml
    fi

    if [ ! -n "$public_ip" ]; then
        sed -i s/$spip// /etc/libvirt/qemu/$dname.xml
    else
        sed -i s/$spip/192.168.126.$public_ip/ /etc/libvirt/qemu/$dname.xml
    fi

    sed -i s/$sname/$dname/ /etc/libvirt/qemu/$dname.xml

    virsh define /etc/libvirt/qemu/$dname.xml
    virsh list --all --title | grep $dname | grep 192.168.126.$public_ip
}

delete() {
    echo "name:"$dname
    virsh undefine $dname
    rm $path/$dname.qcow2 -f
    if [ "$?" == "0" ];then
    	echo "域 $dname 已经被成功删除"
    else
        echo "域 $dname 删除失败"
    fi
}

case "$1" in
    
    create)
        create
        ;;

    delete)
        delete
        ;;
    *)
        echo "/shell/kvm.sh create|delete name internal-ip public-ip"
        ;;
esac

exit
