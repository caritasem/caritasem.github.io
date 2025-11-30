---
layout: article
title: "免费申请域名 SSL 证书, 无限续期，基于 Let’s Encrypt"
date: 2025-11-10 11:00:07 +0800
categories: Tips
tags:
    - letsencrypt
    - certbot
    - nginx
    - ssl
    - automation
    - linux
---
## 说明

本文记录单域名（A/普通域名）使用 Certbot 自动签发并自动续期的实施过程，着重讲述基于 `--nginx` 的常见流程与注意事项。泛域名（Wildcard）证书需要 DNS-01 验证（DNS API 或手动添加 TXT 记录），不在本文讨论范围。

## 安装 Certbot

以Ubuntu 系统为例：

```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx
```

更多安装方式请参考 Certbot 官方文档。

## 单域名证书：申请流程

假设要为 `test.example.com` 申请证书，并且 Nginx 已经配置好对应的 `server_name` 并能通过 80 端口被外网访问。

1. 使用 nginx 插件自动完成验证与配置（Certbot 会尝试修改 Nginx 配置并在成功后加入 SSL 配置）：

```bash
sudo certbot --nginx -d test.example.com
```

2. 过程要点：
- Certbot 会先验证域名（HTTP-01），要求 80 端口能到达你的 Nginx 服务。
- 成功后，Certbot 会在 Nginx 对应的 `server` 块中插入由它管理的 `listen 443 ssl` / `ssl_certificate` / `ssl_certificate_key` 等配置；同时可选地添加 80→443 的重定向块。

示例（申请前 Nginx 简化配置）：

```nginx
upstream backend.gh {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    server_name test.example.com;

    location / {
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_pass http://backend.gh;
    }
}
```

申请成功后，Certbot 会生成类似的受管理配置（只摘要）：

```nginx
server {
    listen 443 ssl; # managed by Certbot
    server_name test.example.com;

    ssl_certificate /etc/letsencrypt/live/test.example.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/test.example.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

    location / {
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_pass http://backend.gh;
    }
}

server {
    if ($host = test.example.com) {
        return 301 https://$host$request_uri;
    }

    listen 80; # managed by Certbot
    server_name test.example.com;
    return 404; # managed by Certbot
}
```

注意：Certbot 标记为 “managed by Certbot” 的行不应手动删除或随意修改（除非你清楚后果），否则升级或续期时可能出现冲突。

你可以用下面命令查看已安装的证书和路径：

```bash
sudo certbot certificates
```

## 自动续期

Let’s Encrypt 的证书有效期为 90 天，推荐启用自动续期（Certbot 默认会在安装时创建 systemd timer / cron 任务，取决于安装方式）。常见验证方式：

1. 先做一次模拟续期验证：

```bash
sudo certbot renew --dry-run
```

2. 如果模拟续期成功，可以启用自动续期：

- 推荐（现代系统）：使用 systemd timer（通常 Certbot 安装会自动启用）。检查状态：

```bash
systemctl list-timers | grep certbot
```

- 传统方法：加入 crontab（如果你更习惯或系统没有 systemd）：

```cron
0 2 * * * * /usr/bin/certbot renew --quiet
```

该 cron 表示每日凌晨 02:00 执行一次续期检查。`certbot renew` 只有在证书将于 30 天内到期时才会实际尝试续期。

3. 续期后 Certbot 会自动替换 `/etc/letsencrypt/live/<domain>` 下的证书文件，通常无需重载 Nginx，因为 Certbot 会在续期时尝试触发必要的 reload。如果你自定义了部署脚本，确保在替换证书后重载 Nginx：

```bash
sudo systemctl reload nginx
```

## 其他提示

- 如果你使用代理、Cloudflare 或者负载均衡器，请确保 HTTP-01 挑战能被 LetsEncrypt 的验证服务器访问到（或考虑使用 DNS-01 验证）。
- 泛域名（Wildcard）证书需要 DNS-01 验证，通常借助 DNS 提供商 API 自动添加 TXT 记录；此流程和本文不同。
- 遇到问题时查看日志：`/var/log/letsencrypt/letsencrypt.log`，或在命令行加入 `-v` 获取更多调试信息。


-----
参考：

1. https://www.cnblogs.com/michaelshen/p/18538178