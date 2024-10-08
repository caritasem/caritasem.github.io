---
layout: article
title:  "如何在本地搭建latex运行环境以及常用模版"
date:   2024-08-01 11:00:07 +0800
categories: python
tags: 
    - latex
    - overleaf
    - template
---

Latex环境安装是非常繁琐的，本文记录下如何在本地电脑中使用OverleafToolkit和Docker-compose搭建Overleaf服务，来使用全部的latex功能，包括配置、镜像修改和启动服务的步骤。

## 安装 Overleaf

### step 1：clone项目
```
git clone  https://github.com/sibosend/overleaf-toolkit.git

cd ./overleaf-toolkit
```

### step 2: 初始化配置
```
bin/init 

ls config

# config目录下会生成以下三个文件： overleaf.rc：顶级配置文件 variables.env：加载到 docker 容器中的环境变量 version：使用的 docker 镜像版本

```

其中需要注意的是在overleaf.rc 文件中，可以修改其服务端口：

```
# Sharelatex container
SHARELATEX_DATA_PATH=data/sharelatex
SERVER_PRO=false
SHARELATEX_LISTEN_IP=127.0.0.1
SHARELATEX_PORT=9000 #将该行修改为你所需服务端口，默认为80端口
```

### step 3: 修改启动镜像
官方提供的镜像是不完全texlive程序及不支持中文字体，在这里我基于官方开源的 overleaf 镜像搭建了自己的镜像，wrm244/sharelatex:with-texlive-full，如果对 docker 比较熟悉的同学可以跳过该步骤自行拉取官方镜像然后再进行配置，当然官方镜像不包含中文字体支持，可参考文章配置。

```
# 进入overleaf-toolkit文件夹下的 lib 目录
> cd lib

# 修改docker-compose.base.yml文件以下内容
vim docker-compose.base.yml

```
> 将源文件的image: "${IMAGE}" 改为 image: wrm244/sharelatex:with-texlive-full 改这一行即可，以下为修改后文件内容

```
---
version: '2.2'
services:

    sharelatex:
        restart: always
        image: wrm244/sharelatex:with-texlive-full
        container_name: sharelatex
        volumes:
            - "${SHARELATEX_DATA_PATH}:/var/lib/sharelatex"
        ports:
            - "${SHARELATEX_LISTEN_IP:-127.0.0.1}:${SHARELATEX_PORT:-80}:80"
        environment:
          GIT_BRIDGE_ENABLED: "${GIT_BRIDGE_ENABLED}"
          GIT_BRIDGE_HOST: "git-bridge"
          GIT_BRIDGE_PORT: "8000"
          REDIS_HOST: "${REDIS_HOST}"
          REDIS_PORT: "${REDIS_PORT}"
          SHARELATEX_MONGO_URL: "${MONGO_URL}"
          SHARELATEX_REDIS_HOST: "${REDIS_HOST}"
          V1_HISTORY_URL: "http://sharelatex:3100/api"
        env_file:
            - ../config/variables.env
        stop_grace_period: 60s
```

### step 4: 启动服务
```
bin/up
```

#### 创建管理员帐户
 在浏览器中，打开 http://localhost:服务端口/launchpad 后会看到注册界面。 使用要用作管理员帐户的凭据填写，然后点击“注册”。
 服务端口默认为80，即http://localhost/launchpad 缺省条件下即可访问。当然你也可以在./config目录下overleaf.rc文件中修改所需端口。

 然后单击链接以转到登录页面（http://localhost:服务端口/login）。 登录后，你将被带到欢迎页面。

 单击页面底部的绿色按钮以开始使用 Overleaf。

### 迁移与备份

在该overleaf-toolkit目录下的data文件夹会映射docker容器的文件，包括sharelatex redis mongo 文件夹，备份这几个文件夹即可，在迁移的时候，启动容器前先把文件复制到data目录下即可恢复数据。


## 常用latex 模版
- [清华大学论文](https://github.com/tuna/thuthesis)
- [简历模版](https://github.com/sibosend/latex-resume-template)