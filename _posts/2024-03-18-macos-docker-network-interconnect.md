---
layout: article
title:  "mac 下docker多个网段与host间网络互通"
date:   2024-03-18 11:00:07 +0800
categories: docker
tags: 
    - docker
---

## 背景

在macos系统下，如果在docker内部署多个容器，每个容器使用不同的网段，如使用172.17.x.x / 10.x.x.x 网段，则需要解决从宿主机到各个容器的网络通信。

如果是使用其他Linux系统的用户则不用担心这个问题，Linux系统会自动帮我们处理好ip之间的互通（宿主机和各个容器之间）。而Mac想要直接访问容器的ip，则需要曲线救国，通过搭建一个vpn服务，然后通过vpn再去和容器的网段互联。

经过尝试openvpn成为了最佳的解决方案。

其中网络连通的原理，如下图所示，openvpn作为一个转接的桥梁。

<img src="/assets/posts/202403/docker.mac.互通.svg">

> 该容器(openvpn)在Docker For Mac容器和主机Mac本身之间创建VPN网络, 通过挂载多块虚拟网卡打通各个子网间的路由。

使用到的工具：
- Docker Desktop
- docker镜像为 https://github.com/kylemanna/docker-openvpn
- Tunnelblick

## 执行步骤：
1. 初始化一个ovpn数据Volume，用以保存配置文件和凭证。
    ```
    export OVPN_DATA="ovpn-data-example"
    docker volume create --name $OVPN_DATA
    ```
1. 创建所需要的vpn环境配置文件
    ```
    docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn \
        ovpn_genconfig -u udp://localhost \
        -p 'route 172.31.1.0 255.255.255.0'  

    # 注意将需要互通的docker环境下的网段都追加到上述命令中
    ```
1. 创建vpn 链接所需的密钥
   ```
   docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki
   ```
1. 运行vpn server
    ```
    docker run -v $OVPN_DATA:/etc/openvpn  --name openvpn_bridge  -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn
    # openvpn_bridge 为容器名称，可以换掉
    ```
1. 创建一个不含秘钥的客户端凭证
    ```
    docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full CLIENTNAME nopass
    # CLIENTNAME 请更改
    ```
1. 使用上述证书生成客户端配置。
   ```
   docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn
   ```
1. 上面这一步生成的 CLIENTNAME.ovpn 配置需要在Tunnelblink里面使用。Tunnelblink是一款开源免费的针对MacOS的OpenVPN图形化客户端，可以非常方便地使用openvpn配置来连接网络服务。

    下载并安装后Tunnelblink（下载dmg包-双击安装-选择 已有网络配置），运行它，然后再到终端执行如下命令来添加网络配置：
    ```
    open ./CLIENTNAME.ovpn
    ```
1. 将vpn容器挂载到所需要互通的网段上
   ```
   # 在host终端执行
   docker network list
   docker network connect NETWORKNAME openvpn_bridge
   # 注意 NETWORKNAME 为 docker network list 列出的网络组name
   ```
1. 打开Docker Desktop，在容器openvpn_bridge上调整Firewall设置
    ```
    iptables -t nat -A POSTROUTING -d 172.31.1.0/24 -o eth1 -j SNAT --to-source 172.31.1.2
    # 注： 其他网段如是
    ```

如此这番操作，就可以直接通过宿主机去访问docker容器实例的ip了，使用ping命令也能ping通。

注意：
1. 开启Tunnelblink的dockerForMac后可能导致您的有些网页无法打开，本人环境下实测关闭Tunnelblink的DNS功能即可。
   <img src="/assets/posts/202403/openvpn.nodns.png">
   
2. 