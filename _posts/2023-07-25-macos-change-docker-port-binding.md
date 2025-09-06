---
layout: article
title:  "Docker：MacOS环境下修改容器的端口号"
date:   2023-07-25 20:00:07 +0800
categories: java
tags: Docker、MacOS
---


```
​​注意:​​ MacOS 和Linux 修改Docker 容器配置方式不一样
```
本文中 containername​​ 是容器名称

### 获取容器id


```
# docker inspect 容器id/容器name
$ docker inspect containername​​ | grep Id
"Id": "c05fc37444df75bbf0f3277ee36b9997c8ef401568d7c5149bb4aca1c25160b2"

# 停止容器
docker stop containername​​

```

### 进入Docker终端，获取root权限
```
# 方式一：成功率不高
screen ~/Library/Containers/com.docker.docker/Data/vms/0/tty

# 方式二：使用Justin's repo and image，
# From Justin Cormack (Docker Maintainer)
# 该方法同样适用于 Docker for Windows for getting in Moby Linux VM (但不适用于 Windows Containers).

docker run -it --rm --privileged --pid=host justincormack/nsenter1
```


```
# 进入容器配置目录
$ cd /var/lib/docker/containers/c05fc37444df75bbf0f3277ee36b9997c8ef401568d7c5149bb4aca1c25160b2

# 容器配置目录文件
$ ls
c05fc37444df75bbf0f3277ee36b9997c8ef401568d7c5149bb4aca1c25160b2-json.log
checkpoints
config.v2.json
hostconfig.json
hostname
hosts
mounts
resolv.conf
resolv.conf.hash
docker-desktop:/var/lib/docker/containers/c05fc37444df75bbf0f3277ee36b9997c8ef401568d7c5149bb4aca1c25160b2

# 退出终端
# `ctrl+a+k`退出终端，输入y
```
### 修改端口配置
1. hostconfig.json 添加端口绑定
```
vi hostconfig.json
#### 搜索关键字
/PortBindings

"PortBindings":{"8080/tcp":[{"HostIp":"","HostPort":"8082"}]}
# 修改为 相当于运行参数 -p 8086:3306
"PortBindings":{"8080/tcp":[{"HostIp":"","HostPort":"8082"}], "3306/tcp":[{"HostIp":"","HostPort":"8086"}]}
```
2. config.v2.json 加上要暴露的端口
```vi config.v2.json
#### 搜索关键字
/ExposedPorts

"ExposedPorts":{"8080/tcp":{}}
#### 修改为
"ExposedPorts":{"8080/tcp":{}, "3306/tcp":{}}
```
说明：
​- ​8080/tcp​​ 是容器端口
​​- "HostPort":"8082"​​ 是宿主主机端口，就是MacOS的端口
### 重启docker
（​​重要​​，让docker重新读容器的取配置文件）


