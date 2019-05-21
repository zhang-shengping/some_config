#!/bin/sh
set +x

ip=`sudo cat /etc/sysconfig/network-scripts/ifcfg-em1 |grep IPADDR |cut -d "=" -f 2`
mask=`sudo cat /etc/sysconfig/network-scripts/ifcfg-em1 |grep NETMASK |cut -d "=" -f 2`
sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-em1
sudo touch  /etc/sysconfig/network-scripts/ifcfg-em1
sudo touch  /etc/sysconfig/network-scripts/ifcfg-br_ex

##init ifcfg-em1
sudo chmod 777 /etc/sysconfig/network-scripts/ifcfg-em1
sudo echo "DEVICE=em1" >>/etc/sysconfig/network-scripts/ifcfg-em1
sudo echo "ONBOOT=yes" >>/etc/sysconfig/network-scripts/ifcfg-em1
sudo echo "HOTPLUG=no" >>/etc/sysconfig/network-scripts/ifcfg-em1
sudo echo "NM_CONTROLLED=no" >>/etc/sysconfig/network-scripts/ifcfg-em1
sudo echo "PEERDNS=no" >>/etc/sysconfig/network-scripts/ifcfg-em1
sudo echo "DEVICETYPE=ovs" >>/etc/sysconfig/network-scripts/ifcfg-em1
sudo echo "TYPE=OVSPort" >>/etc/sysconfig/network-scripts/ifcfg-em1
sudo echo "OVS_BRIDGE=br_ex" >>/etc/sysconfig/network-scripts/ifcfg-em1
sudo echo "BOOTPROTO=none" >>/etc/sysconfig/network-scripts/ifcfg-em1
sudo echo "MTU=1500" >>/etc/sysconfig/network-scripts/ifcfg-em1
sudo chmod 640 /etc/sysconfig/network-scripts/ifcfg-em1

##init ifcfg-br_ex
sudo chmod 777 /etc/sysconfig/network-scripts/ifcfg-br_ex
sudo echo "DEVICE=br_ex" >>/etc/sysconfig/network-scripts/ifcfg-br_ex
sudo echo "TYPE=OVSBridge" >>/etc/sysconfig/network-scripts/ifcfg-br_ex
sudo echo "DEVICETYPE=ovs" >>/etc/sysconfig/network-scripts/ifcfg-br_ex
sudo echo "ONBOOT=yes" >>/etc/sysconfig/network-scripts/ifcfg-br_ex
sudo echo "NM_CONTROLLED=no" >>/etc/sysconfig/network-scripts/ifcfg-br_ex
sudo echo "BOOTPROTO=static" >>/etc/sysconfig/network-scripts/ifcfg-br_ex
sudo echo "IPADDR=$ip" >>/etc/sysconfig/network-scripts/ifcfg-br_ex
sudo echo "NETMASK=$mask" >>/etc/sysconfig/network-scripts/ifcfg-br_ex
sudo echo "DNS1=114.114.114.114" >>/etc/sysconfig/network-scripts/ifcfg-br_ex
sudo chmod 640 /etc/sysconfig/network-scripts/ifcfg-br_ex

##restart network
sudo systemctl restart network 


