#!/bin/sh
set +x

source /home/heat-admin/overcloudrc
#add  flaver
nova flavor-create --is-public true m1.tiny 201901 512 1 1
nova flavor-create --is-public true m1.small 201902 2048 20 1
nova flavor-create --is-public true m1.medium 201903 4096 20 2
nova flavor-create --is-public true m1.large 201904 8192 20 4
nova flavor-create --is-public true m1.xlarge 201905 16384 20 8
nova flavor-create --is-public true 13.1-flavor 201906 8192 180 4

#add net
neutron net-create --router:external --provider:network_type=vlan --provider:physical_network=tenant --provider:segmentation_id=54 --shared Floating_ipv4 --availability-zone-hint=nova
neutron net-create --provider:network_type=vlan --provider:physical_network=tenant --provider:segmentation_id=55 --shared vlan55_ipv4 --availability-zone-hint=nova
neutron net-create --provider:network_type=vlan --provider:physical_network=tenant --provider:segmentation_id=56 --shared vlan56_ipv4 --availability-zone-hint=nova
neutron net-create --provider:network_type=vlan --provider:physical_network=tenant --provider:segmentation_id=57 --shared vlan57_ipv4 --availability-zone-hint=nova
neutron net-create --provider:network_type=vlan --provider:physical_network=tenant --provider:segmentation_id=58 --shared vlan58_ipv4 --availability-zone-hint=nova
neutron net-create --provider:network_type=vlan --provider:physical_network=tenant --provider:segmentation_id=59 --shared vlan59_ipv6 --availability-zone-hint=nova
neutron net-create --provider:network_type=vxlan  --provider:segmentation_id=109 --shared vxlan_ipv4 --availability-zone-hint=nova
neutron net-create --provider:network_type=flat --provider:physical_network=flat  --shared flat_ipv6 --availability-zone-hint=nova

 
neutron subnet-create --name 10.250.54.0/24 --enable_dhcp=True --allocation_pool start=10.250.54.100,end=10.250.54.200 --gateway=10.250.54.1 Floating_ipv4 10.250.54.0/24
neutron subnet-create --name 10.250.55.0/24 --enable_dhcp=True --allocation_pool start=10.250.55.100,end=10.250.55.200 --gateway=10.250.55.1 vlan45_ipv4 10.250.55.0/24
neutron subnet-create --name 10.250.56.0/24 --enable_dhcp=True --allocation_pool start=10.250.56.100,end=10.250.56.200 --gateway=10.250.56.1 vlan46_ipv4 10.250.56.0/24
neutron subnet-create --name 10.250.57.0/24 --enable_dhcp=True --allocation_pool start=10.250.57.100,end=10.250.57.200 --gateway=10.250.57.1 vlan47_ipv4 10.250.57.0/24
neutron subnet-create --name 10.250.58.0/24 --enable_dhcp=True --allocation_pool start=10.250.58.100,end=10.250.58.200 --gateway=10.250.58.1 vlan48_ipv4 10.250.58.0/24
neutron subnet-create --name 192.168.1.0/24 --enable_dhcp=True --allocation_pool start=192.168.1.100,end=192.168.1.200 --gateway=192.168.1.1 vxlan_ipv4 192.168.1.0/24
admin_tenant_id=`openstack project list|grep admin|awk '{print $2}'`
neutron subnet-create --ip-version 6 --ipv6_address_mode=dhcpv6-stateful --tenant-id $admin_tenant_id vlan59_ipv6  2019::/64
neutron subnet-create --ip-version 6 --ipv6_address_mode=dhcpv6-stateful --tenant-id $admin_tenant_id flat_ipv6  2018::/64

neutron router-create router 
neutron router-interface-add router 192.168.1.0/24
neutron router-gateway-set router Floating_ipv4
 
#modify quotas for admin project
nova quota-update --instances 100 --cores 200 --ram 5120000 ${admin_tenant_id}
  
#put  images

glance image-create --name "13.1.1" --file /tmp/BIGIP-13.1.1-0.0.4.qcow2 \
 --disk-format qcow2 --container-format bare  --visibility public --progress

glance image-create --name "cirros" --file /tmp/cirros-0.4.0-x86_64-disk.img \
 --disk-format qcow2 --container-format bare  --visibility public --progress
  
glance image-create --name "rhel7.6" --file /tmp/rhel-server-7.6-x86_64-kvm.qcow2 \
 --disk-format qcow2 --container-format bare  --visibility public --progress 

glance image-create --name "rhel7.6_ipv6" --file /tmp/rhel7.6_only_v6.img \
 --disk-format qcow2 --container-format bare  --visibility public --progress
 
#config SG
nova secgroup-add-rule default icmp -1 -1 ::/0
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule default tcp 1 65535 ::/0
nova secgroup-add-rule default tcp 1 65535 0.0.0.0/0
nova secgroup-add-rule default udp 1 65535 0.0.0.0/0
nova secgroup-add-rule default udp 1 65535 ::/0

yum install /tmp/*.rpm   -y
sudo tar xvf /tmp/f5.tgz -C /usr/lib/python2.7/site-packages/neutron_lbaas/drivers/


#install barbican


# barbican

sudo mysql  -e "CREATE DATABASE barbican;"
sudo mysql  -e " GRANT ALL PRIVILEGES ON barbican.* TO 'barbican'@'localhost' IDENTIFIED BY 'barbican';"
sudo mysql  -e " GRANT ALL PRIVILEGES ON barbican.* TO 'barbican'@'%' IDENTIFIED BY 'barbican';"

openstack user create  --password barbican  --email barbican@localhost barbican
openstack role add --project service --user barbican admin
openstack role create creator
openstack role add --project service --user barbican creator
openstack service create --name barbican --description "Key Manager" key-manager


barbican_public_ip=`openstack endpoint list --long|grep neutron |awk  '{print $10}'|awk -F :9696 '{print $1}'`
barbican_admin_ip=`openstack endpoint list --long|grep neutron |awk  '{print $12}'|awk -F :9696 '{print $1}'`
barbican_internal_ip=`openstack endpoint list --long|grep neutron |awk  '{print $14}'|awk -F :9696 '{print $1}'`


openstack endpoint create --region regionOne   key-manager --publicurl ${barbican_public_ip}:9311/  --adminurl ${barbican_admin_ip}:9311/  --internalurl ${barbican_internal_ip}:9311/


rabbit_hosts=`sudo grep rabbi /etc/nova/nova.conf|egrep -v "^#"|grep rabbit_hosts`
rabbit_use_ssl=`sudo grep rabbi /etc/nova/nova.conf|egrep -v "^#"|grep rabbit_use_ssl`
rabbit_userid=`sudo grep rabbi /etc/nova/nova.conf|egrep -v "^#"|grep rabbit_userid`
rabbit_password=`sudo grep rabbi /etc/nova/nova.conf|egrep -v "^#"|grep rabbit_password`
rabbit_virtual_host=`sudo grep rabbi /etc/nova/nova.conf|egrep -v "^#"|grep rabbit_virtual_host`
rabbit_ha_queues=`sudo grep rabbi /etc/nova/nova.conf|egrep -v "^#"|grep rabbit_ha_queues`

sudo sed   -i -e  "s/^#rabbit_hosts  = .*/$rabbit_hosts/"  \
-e "s/^#rabbit_use_ssl/$rabbit_use_ssl/"   -e "s/^#rabbit_userid = .*/$rabbit_userid" -e "s/^#rabbit_password = .*/$rabbit_password" -e "s/^#rabbit_virtual_host = .*/$rabbit_virtual_host"  -e "s/^#rabbit_ha_queues = .*/$rabbit_ha_queues"   /etc/barbican/barbican.conf




sudo chmod 777 /etc/barbican/barbican.conf
sudo cat << EOF >> /etc/barbican/barbican.conf

[DEFAULT]
sql_connection = mysql+pymysql://barbican:barbican@${barbican_admin_ip}/barbican
log_file = /var/log/barbican/api.log

[keystone_authtoken]
auth_uri = ${barbican_admin_ip}
auth_url = http://${barbican_public_ip}:5000
memcached_servers = overcloud-controller-0.internalapi.localdomain:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = barbican
password = barbican

EOF

sudo chmod 644 /etc/barbican/barbican.conf

sudo systemctl enable openstack-barbican-api
sudo systemctl enable  openstack-barbican-worker
sudo systemctl restart openstack-barbican-api
sudo systemctl restart openstack-barbican-worker









export BIGIP_IP=1.2.3.4
keystone_ip=`openstack endpoint list --long|grep keystone |awk  '{print $10}'|awk -F // '{print $2}'`
keystone_admin_ip=`openstack endpoint list --long|grep keystone |awk  '{print $10}'|awk -F // '{print $2}'`

             


#configure lbaasv2 
sudo sed   -i -e "s/^icontrol_hostname = .*/icontrol_hostname = ${BIGIP_IP}/" -e  "s/^# cert_manager = .*/cert_manager = f5_openstack_agent.lbaasv2.drivers.bigip.barbican_cert.BarbicanCertManager/"  \
-e "s/^auth_version = .*/auth_version = v2/"   -e "s|^os_auth_url = .*|os_auth_url = http:\/\/${keystone_ip}|"  \
-e  "s/^os_username = .*/os_username = admin/" -e "s/^os_password = .*/os_password = ${OS_PASSWORD}/" -e "s/^os_tenant_name = */os_tenant_name = admin/"   /etc/neutron/services/f5/f5-openstack-agent.ini
    
    
sudo sed -i s'/#region = RegionOne/region = regionOne/'g  /etc/neutron/neutron_lbaas.conf
sudo sed -i '/^#service_provider/ a service_provider = LOADBALANCERV2:F5Networks:neutron_lbaas.drivers.f5.driver_v2.F5LBaaSV2Driver:default'  /etc/neutron/neutron_lbaas.conf
sudo sed -i -e "s/^service_plugins=.*/service_plugins = router,qos,trunk,neutron_lbaas.services.loadbalancer.plugin.LoadBalancerPluginv2,neutron.services.firewall.fwaas_plugin.FirewallPlugin/" /etc/neutron/neutron.conf



sudo chmod 777 /etc/neutron/neutron.conf
sudo cat << EOF >> /etc/neutron/neutron.conf
[service_auth]
auth_url=http://${keystone_admin_ip}
admin_user = admin
admin_tenant_name = admin
admin_password=${OS_PASSWORD}
auth_version = v2

EOF
sudo chmod 640 /etc/neutron/neutron.conf
sudo systemctl enable f5-openstack-agent
sudo systemctl restart f5-openstack-agent
sudo systemctl restart neutron-server

