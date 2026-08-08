---
layout: article
title: "JupyterHub 极简部署实践：基于 SystemdSpawner 与本地 PAM 认证 (一期)"
date: 2026-05-16 10:00:00 +0800
categories: [技术]
tags: [JupyterHub, SystemdSpawner, 运维, Linux]
---

## 为什么选择 JupyterHub + SystemdSpawner

多用户 Jupyter 平台常见方案是基于 Kubernetes (Zero to JupyterHub) 或 Docker (DockerSpawner)。但对于中小团队或单机部署，Kubernetes 维护成本过高，DockerSpawner 存在数据权限映射和容器管理开销。

我们需要一个更轻量、贴合宿主机环境的方案。**SystemdSpawner** 是一个理想的选择：它能够利用 Linux 原生 systemd 服务的 cgroup 限制 CPU 和内存资源，且用户打开 Terminal 直接就是真实的宿主机 Shell，方便使用宿主机已安装的各种开发工具。这非常适合单机、多用户的高效共享开发服务器。

<!--more-->

## 分期部署策略

为了平稳上线，部署工作分两期进行：

| | 第一期 | 第二期 |
| :--- | :--- | :--- |
| **认证方式** | Linux PAM（系统用户密码） | Azure AD OAuth2 |
| **用户管理** | 手动创建 Linux 用户 | Azure AD 侧管理，首次登录自动创建 |
| **网络依赖** | 纯内网，无需负载均衡(ALB)/公网域名 | 需要 ALB + 公网回调域名 |
| **外部依赖** | 无 | Azure AD 应用注册 |

**无痛迁移的前提**：第一期创建用户时，命名规则必须与第二期 `normalize_username` 函数输出一致（即邮箱 `@` 前部分，`.` 和 `_` 替换为 `-`，全小写）。例如 `zhang.san@x.com` → `zhang-san`。

这样在切换认证方式时，已有的 Linux 用户和 `/data/jupyter-users/{username}` 目录无需进行任何迁移，已有的用户数据可以完全保留。

---

## 一期架构概览

一期采用纯内网运行方式，架构如下：

```
内网用户
  │
  ▼
http://jupyter.x.com  （内网 DNS，HTTP，80）
  │  内网 DNS 解析到内网 IP
  ▼
JupyterHub（0.0.0.0:8000）
  │
  ├─ 认证：PAM（Linux 系统用户密码）
  │
  └─ Spawner：SystemdSpawner
     └─ 每个用户 → 独立 systemd unit → cgroup 隔离
        └─ 工作目录 /data/jupyter-users/{username}（权限 700，互不可见）
```

---

## 命名规范

为确保第二期无缝切换，第一期创建用户时严格遵循以下规则：

1. 取邮箱 `@` 前面的部分。
2. `.` 替换为 `-`。
3. `_` 替换为 `-`。
4. 全部小写。
5. 最长 32 字符。

示例：

| Azure AD 邮箱 | Linux 用户名 |
| :--- | :--- |
| `zhang.san@x.com` | `zhang-san` |
| `li_si@x.com` | `li-si` |
| `admin@x.com` | `admin` |

---

## 系统依赖安装

首先在 Ubuntu 服务器上安装基础依赖，并为 JupyterHub 构建独立的 Python 虚拟环境。

```bash
# 基础依赖安装
sudo apt update && sudo apt install -y python3-pip python3-venv nodejs npm acl

# 创建虚拟环境（指定 conda-forge 源，避免 Anaconda 官方 ToS 拦截）
conda create -y -c conda-forge --override-channels --prefix /data/condaenv/jupyterhub python=3.13
conda activate jupyterhub 

# 安装 JupyterHub 和 SystemdSpawner
pip install jupyterhub jupyterlab jupyterhub-systemdspawner

# 安装代理组件
sudo npm install -g configurable-http-proxy

# 创建数据根目录
sudo mkdir -p /data/jupyter-users
sudo chmod 755 /data/jupyter-users
```

---

## 第一期配置文件

创建配置文件目录并写入 `/etc/jupyterhub/jupyterhub_config.py`。

一期配置文件中，主要使用本地 `PAMAuthenticator`，并在 `pre_spawn_hook` 中修正手动创建的用户的目录权限。

```python
import os
import pwd
import grp
import subprocess

c = get_config()  #noqa

# ═══════════════════════════════════════════════════════
# 全局变量
# ═══════════════════════════════════════════════════════
JUPYTER_USER_DIR = '/data/jupyter-users'
JUPYTER_GROUP = 'jupyterhub-users'

# ═══════════════════════════════════════════════════════
# 网络配置
# ═══════════════════════════════════════════════════════
c.JupyterHub.ip = '0.0.0.0'
c.JupyterHub.port = 8000
c.JupyterHub.base_url = '/'

# CRYPT_KEY：使用 openssl rand -hex 32 生成
os.environ.setdefault('JUPYTERHUB_CRYPT_KEY', 'xxxx')

# ═══════════════════════════════════════════════════════
# 第一期：PAM 本地认证
# ═══════════════════════════════════════════════════════
c.JupyterHub.authenticator_class = 'jupyterhub.auth.PAMAuthenticator'

# 管理员与允许登录的用户列表
c.Authenticator.admin_users = {'admin'}
c.Authenticator.allowed_users = {'admin'}

# ═══════════════════════════════════════════════════════
# SystemdSpawner 配置
# ═══════════════════════════════════════════════════════
c.JupyterHub.spawner_class = 'systemdspawner.SystemdSpawner'
c.Spawner.default_url = '/lab'
c.SystemdSpawner.unit_name_template = 'jupyter-{USERNAME}'
c.Spawner.notebook_dir = JUPYTER_USER_DIR + '/{username}'
c.SystemdSpawner.default_shell = '/bin/bash'
c.SystemdSpawner.isolate_tmp = True
c.SystemdSpawner.isolate_devices = True
c.SystemdSpawner.disable_user_sudo = True

# ═══════════════════════════════════════════════════════
# pre_spawn_hook（确保目录存在并赋权，一期用户已手动创建）
# ═══════════════════════════════════════════════════════
def ensure_system_user(spawner):
    username = spawner.user.name
    user_dir = f'{JUPYTER_USER_DIR}/{username}'
    os.makedirs(user_dir, exist_ok=True)
    user_info = pwd.getpwnam(username)
    os.chown(user_dir, user_info.pw_uid, user_info.pw_gid)
    os.chmod(user_dir, 0o700)

c.Spawner.pre_spawn_hook = ensure_system_user
```

---

## 用户管理与环境初始化

一期需要手动在 Linux 宿主机上创建用户，并限制其登录权限，同时为其初始化专属的 Conda 环境和内核。

```bash
# 创建用户组（一次性）
sudo groupadd jupyterhub-users

# 禁止 jupyterhub-users 组通过 SSH 登录
echo 'DenyGroups jupyterhub-users' | sudo tee -a /etc/ssh/sshd_config
sudo systemctl reload ssh

# 新增用户（用户名按命名规范命名）
USERNAME=admin
# 使用 -m 选项自动创建目录并拷贝 /etc/skel 默认配置
sudo useradd -m -d /data/jupyter-users/${USERNAME} -s /bin/bash -g jupyterhub-users -G crontab --no-user-group ${USERNAME}
sudo passwd ${USERNAME}

# 修正权限，保证目录仅限用户本人访问
sudo chmod 700 /data/jupyter-users/${USERNAME}

# 写入 conda PATH，使用户 Terminal 能直接使用 conda 命令
echo 'export PATH="/opt/miniconda3/bin:$PATH"' | sudo tee -a /data/jupyter-users/${USERNAME}/.bashrc

# 创建与用户名同名的 conda 环境，并注册为 Jupyter kernel
sudo -u ${USERNAME} /opt/miniconda3/bin/conda create -y -c conda-forge --override-channels --prefix /data/jupyter-users/${USERNAME}/.conda/envs/${USERNAME} python=3.12
sudo -u ${USERNAME} /opt/miniconda3/bin/conda run --prefix /data/jupyter-users/${USERNAME}/.conda/envs/${USERNAME} \
    pip install ipykernel
sudo -u ${USERNAME} /opt/miniconda3/bin/conda run --prefix /data/jupyter-users/${USERNAME}/.conda/envs/${USERNAME} \
    python -m ipykernel install --user --name ${USERNAME} --display-name "Python (${USERNAME})"

# 修正 .conda 目录的所属用户和组
sudo chown -R ${USERNAME}:jupyterhub-users /data/jupyter-users/${USERNAME}/.conda
```

*注意：每当手动新增用户后，必须在 `jupyterhub_config.py` 的 `allowed_users` 中添加对应用户名，然后重启 JupyterHub。*

---

## Systemd 服务与资源限制

### 5.1 JupyterHub Systemd 配置

创建 `/etc/systemd/system/jupyterhub.service`：

```ini
[Unit]
Description=JupyterHub
After=network.target

[Service]
# SystemdSpawner 需要 root 权限来管理用户级 systemd unit
User=root
# 必须包含 /usr/sbin，确保 subprocess 能够找到 useradd / groupadd 命令
Environment=PATH=/data/condaenv/jupyterhub/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/data/condaenv/jupyterhub/bin/jupyterhub -f /etc/jupyterhub/jupyterhub_config.py
WorkingDirectory=/etc/jupyterhub
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

启动并使能服务：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now jupyterhub
```

### 5.2 资源限制（systemd slice）

为防止单用户资源超载导致整机崩溃，需要将所有用户进程归入 `jupyter-users.slice` 中进行统一限制。

创建 `/etc/systemd/system/jupyter-users.slice`：

```ini
[Slice]
Description=Resource limits for all JupyterHub user notebooks
# 示例：以 8核 32G 机器为例，限制用户总体 CPU 792%，内存最大 31G，达到 26G 开始触发软限制回收
CPUQuota=792%
MemoryMax=31G
MemoryHigh=26G
```

为了适应机器规格的自动调整，推荐使用动态配置脚本 `/usr/local/bin/set-jupyter-limits.sh`：

```bash
#!/bin/bash
set -e

CPU_CORES=$(nproc)
MEM_TOTAL=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)

# 留出 1% 给系统和 JupyterHub 自身
CPU_LIMIT=$((CPU_CORES * 99))
MEM_LIMIT=$((MEM_TOTAL * 99 / 100))
MEM_HIGH=$((MEM_LIMIT * 85 / 100))

mkdir -p /etc/systemd/system/jupyter-users.slice.d/
cat > /etc/systemd/system/jupyter-users.slice.d/resource-limit.conf << CONF
[Slice]
CPUQuota=${CPU_LIMIT}%
MemoryMax=${MEM_LIMIT}G
MemoryHigh=${MEM_HIGH}G
CONF

systemctl daemon-reload
echo "Jupyter user limits set: CPU=${CPU_LIMIT}%, MemMax=${MEM_LIMIT}G, MemHigh=${MEM_HIGH}G"
```

赋予执行权限并创建开机自启服务：

```bash
sudo chmod +x /usr/local/bin/set-jupyter-limits.sh
sudo /usr/local/bin/set-jupyter-limits.sh

# 创建开机自启动 oneshot 服务
sudo tee /etc/systemd/system/jupyter-resource-limits.service << 'EOF'
[Unit]
Description=Dynamic Jupyter user resource limits
Before=jupyterhub.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-jupyter-limits.sh

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable jupyter-resource-limits.service
```

---

## 数据隔离验证

部署完毕后，登录不同的账户以验证多用户隔离效果：

1. **检查目录权限**：
   ```bash
   ls -la /data/jupyter-users/
   # 应显示：
   # drwx------  zhang-san jupyterhub-users  zhang-san/
   # drwx------  li-si     jupyterhub-users  li-si/
   ```

2. **跨目录访问拦截**：
   使用 `zhang-san` 身份尝试访问 `li-si` 的目录应被系统拦截：
   ```bash
   sudo -u zhang-san ls /data/jupyter-users/li-si/
   # 预期输出：ls: cannot open directory '/data/jupyter-users/li-si/': Permission denied
   ```

3. **Jupyter Terminal 内测试**：
   在 JupyterLab 中打开 Terminal 执行 `ls /data/jupyter-users/`，能够看到目录名称，但尝试读取任何其他用户文件都将返回 `Permission denied`。

---

## 续篇

一期完成后，可继续：[JupyterHub 进阶实践：集成 Azure AD 实现企业级单点登录 (二期)](/2026/05/JupyterHub-and-Azure-AD-step-by-step/)。

