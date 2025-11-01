---
layout: article
title:  "如何在Ubuntu系统上配置PostgreSql并且启用vector"
date:   2025-11-01 11:00:07 +0800
categories: 分布式
tags: 
    - ubuntu 24.04
    - postgresql-16
    - vector
---

# 虚拟机方式

1：安装 PostgreSQL
1.更新系统包列表
sudo apt update

## 虚拟机方式

### 1. 安装 PostgreSQL

- 更新系统包列表
```bash
sudo apt update
```

- 安装 PostgreSQL
```bash
sudo apt install -y postgresql postgresql-contrib
```

- 启动并启用 PostgreSQL 服务
```bash
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 2. 切换到 postgres 用户并设置密码

PostgreSQL 安装后默认创建一个名为 postgres 的系统用户和数据库用户。

- 进入 psql 命令行
```bash
sudo -u postgres psql
```

- 在 psql 中设置密码（建议设置，便于远程连接或管理）
```sql
ALTER USER postgres PASSWORD 'your_strong_password';
```

- 退出命令行
```
\q
```

### 3. 安装 pgvector 扩展（源码编译）

这里有多种安装方式，以下以源码编译为例。

- 安装编译依赖
```bash
sudo apt install -y build-essential postgresql-server-dev-16 git
```

- 克隆 pgvector 源码
```bash
git clone https://github.com/pgvector/pgvector.git
# 如果下载不了，可以从 Gitee 下载：
# git clone https://gitee.com/dgaiot/pgvector.git
```

- 进入源码目录并编译安装
```bash
cd pgvector
make
sudo make install
```

### 4. 在数据库中启用 pgvector 扩展并验证

- 进入 psql 命令行
```bash
sudo -u postgres psql
```

- 创建数据库并连接
```sql
CREATE DATABASE knowledge;
```

```
\c knowledge
```

- 启用扩展并做简单验证
```sql
CREATE EXTENSION vector;
CREATE TABLE items (id serial, emb vector(3));
INSERT INTO items (emb) VALUES ('[1,2,3]');
SELECT * FROM items ORDER BY emb <-> '[1,1,1]' LIMIT 1;
```

若能看到查询结果返回一行记录，则表示向量扩展启用成功。

### 5. 开启远程连接

配置文件位于 `/etc/postgresql/版本号/main` 目录下（例如 16 版本：`/etc/postgresql/16/main`）。

- 修改 `postgresql.conf`
```conf
listen_addresses = '*'
```

- 修改 `pg_hba.conf`（示例为放开所有 IPv4 访问，生产环境请收紧网段范围）
```conf
# IPv4 local connections:
host    all             all             0.0.0.0/0            scram-sha-256
```

## Docker Compose 方式

参考示例仓库：

https://github.com/sibosend/docker-compose-postgresql-pgadmin

---
参考：
- https://www.cnblogs.com/yg_zhang/p/19067843
