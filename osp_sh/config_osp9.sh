#!/bin/sh
set +x
source /home/stack/stackrc

controller_ip=`nova list|grep controlle|awk -F '=' '{print $2}'|awk '{print $1}'`
computer0_ip=`nova list|grep compute-0|awk -F '=' '{print $2}'|awk '{print $1}'`
computer1_ip=`nova list|grep compute-1|awk -F '=' '{print $2}'|awk '{print $1}'`

#scp file

images='BIGIP-13.1.1-0.0.4.qcow2
cirros-0.4.0-x86_64-disk.img
rhel-server-7.6-x86_64-kvm.qcow2
rhel7.6_only_v6.img'


for i in $images;
do
rsync -avP  /home/stack/osp/instance_images/$i heat-admin@$controller_ip:/tmp
done

scp /home/stack/overcloudrc   heat-admin@$controller_ip:~


scp  /home/stack/osp/rpms/*    heat-admin@$controller_ip:/tmp
scp /home/stack/osp/config_osp/controller.sh  heat-admin@$controller_ip:/tmp
scp /home/stack/osp/config_osp/f5_install.sh  heat-admin@$controller_ip:/tmp
scp /home/stack/osp/config_osp/config_net.sh  heat-admin@$controller_ip:/tmp
scp /home/stack/osp/config_osp/config_net.sh  heat-admin@$computer0_ip:/tmp
scp /home/stack/osp/config_osp/config_net.sh  heat-admin@$computer1_ip:/tmp

ssh heat-admin@$controller_ip sh /tmp/config_net.sh &
sleep 10

ssh heat-admin@$computer0_ip sh /tmp/config_net.sh &
sleep 10

ssh heat-admin@$computer1_ip sh /tmp/config_net.sh &
sleep 10

ssh heat-admin@$controller_ip 'sudo sed -i '/^flat/s/datacentre/*/' /etc/neutron/plugins/ml2/ml2_conf.ini'
ssh heat-admin@$controller_ip 'sudo systemctl restart neutron-server'
sleep 30

ssh heat-admin@$controller_ip sh /tmp/controller.sh
#sh heat-admin@$controller_ip sh /tmp/f5_install.sh

