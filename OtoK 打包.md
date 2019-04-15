## 打包过程

##### 准备打包环境：

```
[root@kolla-b ~]# cat /etc/centos-release
CentOS Linux release 7.6.1810 (Core)

[root@kolla-b ~]# docker --version
Docker version 17.05.0-ce, build 89658be

[root@kolla-b package-test]# git --version
git version 1.8.3.1
```

##### 下载源码

OtoK agent：

​	`git clone https://github.com/zhang-shengping/OtoK-performance-agent.git -b master f5-openstack-agent`

OtoK driver:

​	`git clone https://github.com/zhang-shengping/OtoK-performance-driver.git -b master f5-openstack-lbaasv2-driver`

##### 打包 f5-openstack-agent

```
列出当前文件
[root@kolla-b]# ls
f5-openstack-agent  f5-openstack-lbaasv2-driver

进入 repo 目录
[root@kolla-b]# cd f5-openstack-agent/

设置 package_workdir 环境变量：
[root@kolla-b f5-openstack-agent]# package_workdir=$(pwd)

在当前目录下运行 universal_truth.py
[root@kolla-b f5-openstack-agent]# python f5-openstack-agent-dist/scripts/universal_truth.py
Successfully constructed /root/package-test/f5-openstack-agent/setup.cfg and
/root/package-test/f5-openstack-agent/f5-openstack-agent-dist/deb_dist/stdeb.cfg

运行 build-rpms.sh 打包
[root@kolla-b f5-openstack-agent]# bash -x f5-openstack-agent-dist/Docker/redhat/7/build-rpms.sh ${package_workdir}

进入 build 目录可以找到对应的 RPM 包: f5-openstack-agent-9.6.5-1.el7.noarch.rpm
[root@kolla-b f5-openstack-agent]# cd f5-openstack-agent-dist/rpms/build
[root@kolla-b build]# ls
f5-openstack-agent-9.6.5-1.el7.noarch.rpm
```

#####  打包 f5-openstack-lbaasv2-driver

```
列出当前文件
[root@kolla-b]# ls
f5-openstack-agent  f5-openstack-lbaasv2-driver

进入 repo 目录
[root@kolla-b]# cd f5-openstack-lbaasv2-driver

运行 package.sh 打包
[root@kolla-b f5-openstack-lbaasv2-driver]# bash -x f5-openstack-lbaasv2-driver-dist/scripts/package.sh redhat 7

进入 build 目录可以找到对应的 RPM 包: f5-openstack-lbaasv2-driver-11.0.0-1.el7.noarch.rpm
[root@kolla-b f5-openstack-lbaasv2-driver]# cd f5-openstack-lbaasv2-driver-dist/rpms/
[root@kolla-b rpms]# ls
f5-openstack-lbaasv2-driver-11.0.0-1.el7.noarch.rpm  f5-openstack-lbaasv2-driver-11.0.0-1.src.rpm
```

##### 下载 f5-sdk 和 icontrol 包

```
f5-sdk 使用 3.0.11 版本
[stack@ocata-env install-f5]$ wget https://github.com/F5Networks/f5-common-python/releases/download/v3.0.11/f5-sdk-3.0.11-1.el7.noarch.rpm

icontrol 使用 1.3.2 版本
[stack@ocata-env install-f5]$ wget https://github.com/F5Networks/f5-icontrol-rest-python/releases/download/v1.3.2/f5-icontrol-rest-1.3.2-1.el7.noarch.rpm
```

##### 安装 f5-openstack-lbaav2-driver

```
当前目录所有的 RPM 包
[stack@ocata-env install-f5]$ ls
f5-icontrol-rest-1.3.2-1.el7.noarch.rpm    f5-openstack-lbaasv2-driver-11.0.0-1.el7.noarch.rpm
f5-openstack-agent-9.6.5-1.el7.noarch.rpm  f5-sdk-3.0.11-1.el7.noarch.rpm

安装 f5-openstack-driver 包
[stack@ocata-env install-f5]$ sudo rpm -ihv f5-openstack-lbaasv2-driver-11.0.0-1.el7.noarch.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:f5-openstack-lbaasv2-driver-11.0.################################# [100%]

安装 f5-openstack-agent 包和它的依赖包
[stack@ocata-env install-f5]$ sudo rpm -ivh f5-icontrol-rest-1.3.2-1.el7.noarch.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:f5-icontrol-rest-1.3.2-1         ################################# [100%]
[stack@ocata-env install-f5]$ sudo rpm -ivh f5-sdk-3.0.11-1.el7.noarch.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:f5-sdk-3.0.11-1                  ################################# [100%]
[stack@ocata-env install-f5]$ sudo rpm -ivh f5-openstack-agent-9.6.5-1.el7.noarch.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:f5-openstack-agent-9.6.5-1       ################################# [100%]
```

