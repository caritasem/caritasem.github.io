---
layout: article
title: "JupyterHub 进阶实践：集成 Azure AD 实现企业级单点登录 (二期)"
date: 2026-05-17 10:00:00 +0800
categories: [技术]
tags: [JupyterHub, Azure AD, OAuth2, 单点登录]
---

## 引言

**前置文章**：[JupyterHub 极简部署实践：基于 SystemdSpawner 与本地 PAM 认证 (一期)](/2026/05/JupyterHub-step-by-step/)

在[一期部署](/2026/05/JupyterHub-step-by-step/)中，我们成功搭建了基于 SystemdSpawner 与本地 PAM 认证的多用户 JupyterHub。随着团队规模的扩大，手动管理 Linux 用户、维护密码不仅繁琐，而且无法满足企业对单点登录（SSO）与多因素认证（MFA）的安全合规要求。

本期我们将 JupyterHub 升级为 **Azure AD（Microsoft Entra ID）OAuth2 认证**。由于一期已经严格遵循了统一的用户名规范，本次升级无需迁移已有用户数据，可以实现无痛过渡。

<!--more-->

## 二期架构与认证时序

### 2.1 网络架构

在二期架构中，为支持 OAuth2 回调，引入了应用负载均衡器（ALB）并配置公网域名：

```
内网用户
  │
  ▼
http://jupyter.x.com  （内网 DNS，HTTP，80）
  │  内网 DNS 解析到 JupyterHub 实例内网 IP
  ▼
JupyterHub 实例
  │
  ▼  OAuth 认证跳转与回调
https://jupyter-callback.x.com  （公网 ALB，HTTPS，443）
  │  ALB 负责终止 TLS 并转发流量
  ▼
JupyterHub 服务（0.0.0.0:8000）
  │
  ├─ 认证：Azure AD OAuth2（用户生命周期完全托管于 Azure 侧）
  │
  └─ Spawner：SystemdSpawner
     └─ 用户首次登录 → 自动创建 Linux 系统用户 → 独立 Systemd 实例
```

### 2.2 认证时序

```
1. 用户访问 http://jupyter.x.com
         │
2. JupyterHub 发起 302 重定向到 Azure AD 登录页面
         │  带上参数 redirect_uri=https://jupyter-callback.x.com/hub/oauth_callback
         │
3. 用户在 Azure AD 侧进行身份验证（如 MFA 校验）
         │
4. Azure AD 认证通过，重定向回公网回调地址：
         │  https://jupyter-callback.x.com/hub/oauth_callback?code=xxx
         │
5. JupyterHub 收到回调请求，通过 ALB 转发至本地服务
         │
6. JupyterHub 用 code 换取 token 并提取用户邮箱 (upn claim)
         │
7. 触发 normalize_username 处理：例如 zhang.san@x.com 规范化为 zhang-san
         │
8. 触发 pre_spawn_hook 钩子：
         │  - 自动创建 Linux 用户 zhang-san （如果一期已存在则直接复用）
         │  - 自动初始化工作目录并设为 700 权限
         │  - 自动为新用户构建 Conda 环境与 Kernel 注册
         │
9. 启动对应的 systemd 实例 jupyter-zhang-san.service，引导用户进入 JupyterLab
```

---

## Azure AD 应用注册

在配置 JupyterHub 之前，需要登录 Azure Portal 注册企业应用。

### 1. 注册应用

1. 打开 [Azure Portal](https://portal.azure.com)，依次进入 **Microsoft Entra ID** (原 Azure Active Directory) -> **应用注册** -> **新注册**。
2. 填写注册信息：
   - **名称**：`JupyterHub`
   - **受支持的账户类型**：根据租户范围选择（通常选择单租户）。
   - **重定向 URI**：平台选择 `Web`，值填写 `https://jupyter-callback.x.com/hub/oauth_callback`。

### 2. 获取必要凭证

在应用概述页和凭证页，记录以下关键信息用于 JupyterHub 配置：

- **目录（租户）ID** (`tenant_id`)：`xxxx`
- **应用程序（客户端）ID** (`client_id`)：`xxxx`
- **客户端密码** (`client_secret`)：在“证书和密码”页，新建客户端密码，并立即复制记录其 **Value**（注意不是密码 ID）。

### 3. 配置 API 权限

在“API 权限”中，添加以下 **Microsoft Graph** 委托权限：
- `openid`
- `email`
- `profile`
- `User.Read`

*添加完成后，务必点击“代表 [您的组织] 授予管理员同意”。*

---

## 环境依赖更新

由于增加了 OAuth2 认证支持，需要在已有的 JupyterHub 虚拟环境中追加安装 `oauthenticator` 库：

```bash
conda activate jupyterhub
pip install oauthenticator
```

---

## 完整 JupyterHub 配置

修改 `/etc/jupyterhub/jupyterhub_config.py`，配置 Azure AD 认证器，并实现自动创建 Linux 用户与环境的完整版钩子函数。

```python
import os
import pwd
import grp
import re
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
# Azure AD OAuth 认证与用户名规范化
# ═══════════════════════════════════════════════════════
from oauthenticator.azuread import AzureAdOAuthenticator

class NormalizedAzureAdOAuthenticator(AzureAdOAuthenticator):
    """
    覆写 normalize_username，确保 Azure AD 传回的邮箱格式能够无缝转换为合法的 Linux 用户名。
    转换示例：zhang.san@x.com → zhang-san
    """
    def normalize_username(self, username):
        # 取 @ 前面的邮箱前缀
        name = username.split('@')[0]
        # 将点、下划线、空格等统一转换为短横线，并转为小写
        name = name.replace('.', '-').replace('_', '-').replace(' ', '-').lower()
        # 移除非法字符，限制仅能包含小写字母、数字和短横线
        name = re.sub(r'[^a-z0-9-]', '', name)
        # 截断长度（Linux 用户名限制最长 32 字符）
        name = name[:32]
        return super().normalize_username(name)

c.JupyterHub.authenticator_class = NormalizedAzureAdOAuthenticator

# Azure AD 凭证配置
c.AzureAdOAuthenticator.tenant_id = 'xxxx'
c.AzureAdOAuthenticator.client_id = 'xxxx'
c.AzureAdOAuthenticator.client_secret = 'xxxx'
c.AzureAdOAuthenticator.oauth_callback_url = 'https://jupyter-callback.x.com/hub/oauth_callback'

# 关键：指定 username_claim 为 upn（用户主体名），确保获取到合法的邮箱格式
c.AzureAdOAuthenticator.username_claim = 'upn'

# 允许所有通过当前 Azure AD 租户认证的用户登录
c.AzureAdOAuthenticator.allow_all = True

# 管理员用户配置（配置为规范化后的 Linux 用户名）
c.Authenticator.admin_users = {'admin'}

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
c.SystemdSpawner.slice = 'jupyter-users.slice'

# ═══════════════════════════════════════════════════════
# 自动化用户供给：pre_spawn_hook
# ═══════════════════════════════════════════════════════
CONDA_BIN = '/opt/miniconda3/bin/conda'
USERADD_BIN = '/usr/sbin/useradd'
GROUPADD_BIN = '/usr/sbin/groupadd'

def ensure_system_user(spawner):
    """
    当用户首次通过 Azure AD 登录时，自动执行以下供给逻辑：
    1. 创建 JupyterHub 共享用户组
    2. 创建对应的 Linux 系统用户（禁止 SSH 登录但允许 Terminal 内执行 cron）
    3. 自动初始化 700 隔离工作目录
    4. 写入 Conda 环境变量至其 .bashrc
    5. 构建专属 Conda 隔离沙箱并注册 Jupyter 内核
    """
    username = spawner.user.name

    # 严格校验：确保用户名必须符合规范化正则，拒绝非法输入直接写入系统命令
    if not re.fullmatch(r'[a-z0-9-]{1,32}', username):
        raise ValueError(
            f'Refusing to spawn: username {username!r} is not normalized. '
            f'请检查配置的 username_claim 或清理 jupyterhub.sqlite 中的脏数据。'
        )

    user_dir = f'{JUPYTER_USER_DIR}/{username}'
    conda_env_prefix = f'{user_dir}/.conda/envs/{username}'

    # 1. 确保 jupyterhub-users 组存在
    try:
        grp.getgrnam(JUPYTER_GROUP)
    except KeyError:
        subprocess.run([GROUPADD_BIN, JUPYTER_GROUP], check=True)

    # 2. 如果用户不存在则创建 Linux 用户
    is_new_user = False
    try:
        pwd.getpwnam(username)
    except KeyError:
        subprocess.run([
            USERADD_BIN,
            '-m',
            '-d', user_dir,
            '-s', '/bin/bash',
            '-g', JUPYTER_GROUP,
            '-G', 'crontab',
            '--no-user-group',
            username
        ], check=True)
        spawner.log.info(f'Created system user: {username}')
        is_new_user = True

    # 3. 确保目录存在并强制设定权限
    os.makedirs(user_dir, exist_ok=True)
    user_info = pwd.getpwnam(username)
    os.chown(user_dir, user_info.pw_uid, user_info.pw_gid)
    os.chmod(user_dir, 0o700)

    # 4. 配置 .bashrc 中的 Conda PATH
    if is_new_user:
        bashrc = f'{user_dir}/.bashrc'
        with open(bashrc, 'a') as f:
            f.write('\nexport PATH="/opt/miniconda3/bin:$PATH"\n')
        os.chown(bashrc, user_info.pw_uid, user_info.pw_gid)

    # 5. 构建专属 Conda 沙箱及注册内核（仅在新环境未被初始化时执行）
    if not os.path.exists(conda_env_prefix):
        spawner.log.info(f'Creating conda env: {conda_env_prefix}')
        subprocess.run([
            CONDA_BIN, 'create', '-y',
            '-c', 'conda-forge', '--override-channels',
            '--prefix', conda_env_prefix,
            'python=3.12'
        ], check=True)
        
        subprocess.run([
            CONDA_BIN, 'run', '--prefix', conda_env_prefix,
            'pip', 'install', 'ipykernel'
        ], check=True)

        kernel_prefix = f'{user_dir}/.local'
        subprocess.run([
            CONDA_BIN, 'run', '--prefix', conda_env_prefix,
            'python', '-m', 'ipykernel', 'install',
            '--prefix', kernel_prefix,
            '--name', username,
            '--display-name', f'Python ({username})'
        ], check=True)

        # 递归修正 conda 和 kernel specs 目录权限，以防以 root 身份创建时发生权限溢出
        conda_dir = f'{user_dir}/.conda'
        for root, dirs, files in os.walk(conda_dir):
            for d in dirs:
                os.chown(os.path.join(root, d), user_info.pw_uid, user_info.pw_gid)
            for f in files:
                os.chown(os.path.join(root, f), user_info.pw_uid, user_info.pw_gid)
        os.chown(conda_dir, user_info.pw_uid, user_info.pw_gid)

        for root, dirs, files in os.walk(kernel_prefix):
            for d in dirs:
                os.chown(os.path.join(root, d), user_info.pw_uid, user_info.pw_gid)
            for f in files:
                os.chown(os.path.join(root, f), user_info.pw_uid, user_info.pw_gid)
        os.chown(kernel_prefix, user_info.pw_uid, user_info.pw_gid)
        spawner.log.info(f'Conda env and kernel ready for user: {username}')

    spawner.log.info(f'User environment setup completed: {user_dir}')

c.Spawner.pre_spawn_hook = ensure_system_user

# ═══════════════════════════════════════════════════════
# 反向代理集成与 Cookie 域配置
# ═══════════════════════════════════════════════════════
c.JupyterHub.tornado_settings = {
    'cookie_options': {'domain': '.x.com'},
    'headers': {
        'Content-Security-Policy': "frame-ancestors 'self'"
    }
}
```

---

## 负载均衡器（ALB）配置要点

为了保证 OAuth2 的回调安全及 WebSocket 长连接的连贯性，ALB 侧的配置应遵循以下指标：

| 配置项目 | 建议设定值 | 作用与说明 |
| :--- | :--- | :--- |
| **监听器** | HTTPS 443 | 绑定 `jupyter-callback.x.com` 的 SSL/TLS 证书 |
| **目标组** | HTTP 端口 | 转发至后端 JupyterHub 宿主机内网 IP 的 8000 端口 |
| **健康检查** | `/hub/health` | 状态码预期 200，用以监控 JupyterHub 活动状态 |
| **会话粘性** | 开启 (Sticky Session) | 基于 Cookie 保证 Jupyter 容器的 WebSocket 连接不发生跨节点漂移 |
| **空闲超时** | 3600 秒 | 避免由于长连接无心跳包被 ALB 提前掐断 |
| **转发头** | `X-Forwarded-Proto: https` | 告知 Tornado 后端当前请求为安全连接，防止重定向死循环 |

---

## 用户生命周期管理策略对照

在两种架构下，系统管理员对用户的生命周期管理操作如下：

| 管理动作 | 第一期 (本地 PAM) | 第二期 (Azure AD OAuth2) |
| :--- | :--- | :--- |
| **新增用户** | 手动执行 `useradd` -> 手动设定密码 -> 手动将用户名追加进 `allowed_users` 列表并重启服务 | 仅需在 Azure AD 侧为用户分配该企业应用访问权。用户首次登录时系统将全自动完成宿主机账户供给与 Conda 沙箱初始化。 |
| **禁用用户** | 执行 `passwd -l [username]` 锁死本地账户 -> 从 `allowed_users` 列表中移除 | 仅需在 Azure AD 侧禁用或删除该用户账号，用户再次访问将无法通过 OAuth2 验证。 |
| **删除用户数据** | 手动执行 `userdel [username]` 并不加 `-r` 改为手动 `rm -rf /data/jupyter-users/[username]` | 手动执行 `userdel [username]` 并不加 `-r` 改为手动 `rm -rf /data/jupyter-users/[username]` |
| **管理员权限** | 在 `admin_users` 集合中硬编码加入本地 Linux 用户名 | 在 `admin_users` 中填入规范化后的管理员邮箱前缀。登录后可直接通过 JupyterHub 后台的 Admin 控制面板进行界面化管理。 |

---

## 共享只读数据目录（可选拓展）

如果团队内有公共数据集或共享代码包，需要提供给所有用户只读挂载：

1. **在宿主机创建共享目录并赋权**：
   ```bash
   sudo mkdir -p /data/jupyter-shared
   sudo chown root:jupyterhub-users /data/jupyter-shared
   sudo chmod 750 /data/jupyter-shared
   ```

2. **在 `ensure_system_user` 函数末尾追加软链接建立逻辑**：
   ```python
   # 在 pre_spawn_hook 钩子函数的最后加入：
   shared_link = os.path.join(user_dir, 'shared-data')
   if not os.path.exists(shared_link):
       os.symlink('/data/jupyter-shared', shared_link)
   ```

这样，每个用户在登录 JupyterLab 后，工作目录下都会自动出现一个名为 `shared-data` 的软链接，从而实现数据零拷贝的高效共享。

---

## 相关阅读

- [JupyterHub 极简部署实践：基于 SystemdSpawner 与本地 PAM 认证 (一期)](/2026/05/JupyterHub-step-by-step/)
