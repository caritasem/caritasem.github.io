---
layout: article
title:  "将 Kiro 的 Claude Opus 模型通过 CC Switch 代理到 Claude Code 使用"
date:   2026-03-13 10:00:00 +0800
categories: ai
tags: 
    - kiro
    - claude-code
    - cc-switch
    - cliproxyapi
    - ai-coding
---

Kiro 内置了 Claude Opus 4.6 等模型，但这些模型只能在 Kiro IDE 内使用。本文介绍如何借助 CLIProxyAPI（Plus）和 CC Switch，将 Kiro 的模型 token 代理出来，供 Claude Code（以及 VSCode 中的 Claude Code 扩展）使用。

<!--more-->

## 原理概述

整体链路如下：

```
Kiro IDE 登录 → 本地生成 token 文件
    → CLIProxyAPI Plus 导入 token（--kiro-import）
    → 启动本地代理服务（127.0.0.1:8317）
    → CC Switch 配置 provider 指向该代理
    → Claude Code / VSCode Claude Code 扩展正常使用
```

核心思路：Kiro 登录后会在本地缓存一份 AWS SSO token，CLIProxyAPI Plus 能读取并转换为兼容 Claude API 的代理服务，CC Switch 则负责管理和切换这些配置。

## 前置准备

- 已安装并登录过 Kiro IDE（确保本地已生成 token）
- 已安装 Claude Code CLI（`npm install -g @anthropic-ai/claude-code`）
- 已安装 CC Switch（[GitHub 下载](https://github.com/farion1231/cc-switch)）
- 已下载 CLIProxyAPI Plus（[GitHub 下载](https://github.com/router-for-me/CLIProxyAPIPlus)）

## 第一步：确认 Kiro Token 位置

登录 Kiro IDE 后，token 文件会自动生成在以下路径：

| 系统 | 路径 |
|------|------|
| macOS | `~/.aws/sso/cache/kiro-auth-token.json` |
| Windows | `C:\Users\<用户名>\.aws\sso\cache\kiro-auth-token.json` |
| Linux | `~/.aws/sso/cache/kiro-auth-token.json` |

文件内容大致如下：

```json
{
    "accessToken": "aoa....",
    "expiresIn": 3600,
    "refreshToken": "aor....",
    "tokenType": "Bearer"
}
```

> 如果你从未登录过 Kiro，需要先打开 Kiro IDE 完成一次登录（Google 或 GitHub 均可）。

## 第二步：配置 CLIProxyAPI Plus

### 2.1 初始化配置文件

解压 CLIProxyAPI Plus 后，进入目录：

```bash
cp config.example.yaml config.yaml
```

编辑 `config.yaml`，最小配置如下：

```yaml
port: 8317

auth-dir: "~/.cli-proxy-api"

request-retry: 3

quota-exceeded:
  switch-project: true
  switch-preview-model: true

api-keys:
  - "your-custom-api-key"

remote-management:
  allow-remote: false
  secret-key: "your-management-key"
  disable-control-panel: false
```

其中 `api-keys` 是你自定义的密钥，后续 CC Switch 中需要填写。

### 2.2 导入 Kiro Token

在 CLIProxyAPI Plus 目录下执行：

```bash
# macOS / Linux
./cli-proxy-api-plus --kiro-import

# Windows
cli-proxy-api-plus.exe --kiro-import
```

成功后会看到类似输出：

```
✓ Imported Kiro token from IDE (Provider: )
Authentication saved to /Users/<用户名>/.cli-proxy-api/kiro-imported-xxxx.json
Imported as kiro-imported
Kiro token import successful!
```

> 如果提示找不到 token 文件，请确认 Kiro IDE 已登录，并检查上述路径是否存在 `kiro-auth-token.json`。

### 2.3 启动代理服务

```bash
# macOS / Linux
./cli-proxy-api-plus

# Windows
cli-proxy-api-plus.exe
```

启动后可访问管理界面：`http://127.0.0.1:8317/management.html`

在「中心信息」栏目中可以看到已导入的 Kiro 模型列表，包括：
- `kiro-claude-opus-4-5-agentic`
- `kiro-claude-sonnet-4-5-agentic`
- `kiro-claude-haiku-4-5-agentic`

## 第三步：在 CC Switch 中配置 Provider

打开 CC Switch，点击「Add Provider」，选择自定义配置。


![CC Switch 配置界面](/assets/posts/202603/cc1.png)

关键的环境变量配置如下：

```json
{
    "ANTHROPIC_AUTH_TOKEN": "your-custom-api-key",
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:8317",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "kiro-claude-haiku-4-5-agentic",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "kiro-claude-opus-4-5-agentic",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "kiro-claude-sonnet-4-5-agentic",
    "ANTHROPIC_MODEL": "kiro-claude-opus-4-5-agentic"
}
```

说明：
- `ANTHROPIC_AUTH_TOKEN`：填写你在 `config.yaml` 中设置的 `api-keys`
- `ANTHROPIC_BASE_URL`：指向 CLIProxyAPI Plus 的本地地址
- 模型名称需要使用 Kiro 专属的名称映射（带 `kiro-` 前缀），因为 Kiro 的模型名与标准 Claude 模型名不同

配置完成后，在 CC Switch 中点击「Enable」激活该 Provider。

## 第四步：在 Claude Code 中验证

重启终端，运行 Claude Code：

```bash
claude
```

![Claude Code 使用效果](/assets/posts/202603/cc2.png)

此时 Claude Code 会通过本地代理访问 Kiro 的 Claude Opus 模型。可以用 `/model` 命令确认当前使用的模型。

## 第五步：在 VSCode 中使用 Claude Code 扩展

如果你使用 VSCode 的 Claude Code 扩展，同样可以享受到代理后的模型。CC Switch 的配置对 Claude Code CLI 和 VSCode 扩展都生效。

![VSCode 中的 Claude Code](/assets/posts/202603/cc3.png)

在 VSCode 中打开 Claude Code 面板，即可正常使用 Kiro 的 Opus 模型进行编码辅助。

## Token 过期处理

Kiro 的 token 有效期为 3600 秒（1 小时）。在第一次登录成功后（比如使用 kiro-cli 等方式），CLIProxyAPI 会自动处理每小时的 token 更新，无需手动干预。

如果自动刷新未生效，也可以手动重新导入：

1. 打开 Kiro IDE（会自动刷新 token）
2. 重新执行 `./cli-proxy-api-plus --kiro-import`

> 前提是 Kiro IDE 保持打开状态，这样 token 会被自动续期。

## 常见问题

**Q: 导入时提示找不到 token 文件？**

确保已打开 Kiro IDE 并完成登录。如果路径不存在，可以手动创建 `~/.aws/sso/cache/` 目录，然后将获取到的 token JSON 文件重命名为 `kiro-auth-token.json` 放入。

**Q: Claude Code 报连接错误？**

检查 CLIProxyAPI Plus 是否正在运行，以及端口 8317 是否被占用。可以用 `curl http://127.0.0.1:8317/v1/models` 测试连通性。

**Q: 模型名称不对？**

Kiro 的模型名称带有 `kiro-` 前缀和 `-agentic` 后缀，必须在 CC Switch 的环境变量中正确映射，否则 Claude Code 会找不到模型。

## 参考链接

- [CLIProxyAPI 系列教程](https://linux.do/t/topic/1011966)（配置详解）
- [CLIProxyAPI 项目介绍](https://linux.do/t/topic/1011983)
- [中转转发接入篇](https://linux.do/t/topic/1033149)
- [GUI 管理界面](https://linux.do/t/topic/1011999)
- [Docker 部署](https://linux.do/t/topic/1012017)
- [Kiro Token 代理到 CC 的实践记录](https://linux.do/t/topic/1462220)
- [CC Switch GitHub](https://github.com/farion1231/cc-switch)
- [CLIProxyAPI Plus GitHub](https://github.com/router-for-me/CLIProxyAPIPlus)
