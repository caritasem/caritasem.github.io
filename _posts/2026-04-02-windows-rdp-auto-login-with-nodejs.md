---
layout: article
title:  "用 Node.js 实现 Windows RDP 自动登录"
date:   2026-04-02 10:00:00 +0800
categories: windows
tags: 
    - rdp
    - nodejs
    - automation
    - windows
---

一台 Windows 机器上有多个账号，其中一个需要在后台保持登录来跑依赖桌面会话的定时任务。手动用远程桌面连一下太原始，改注册表 `AutoAdminLogon` 也只能设默认登录账号，无法在 A 账号已登录的情况下让 B 账号也在后台上线。最终方案：**用 Node.js 在本地跑一个 RDP 客户端，连本机 3389 端口把目标账号登上去。**

<!--more-->

## 原理

RDP 协议就是远程桌面用的协议，`mstsc.exe` 通过它连目标机器、发送凭据、建立会话。这个项目用了基于 `node-rdpjs` 改造的协议库，等于用 Node.js 实现了一个精简版 RDP 客户端。连接目标设成 `127.0.0.1:3389`（连自己），把用户名密码发过去，Windows 就会为该账号创建会话。登录完成后客户端退出，但会话保持。

再配一个 VBS 脚本把控制台窗口藏掉，扔到开机启动里，就实现了全自动、无感知的后台登录。

## 使用方式

### 1. 安装依赖

机器上需要先有 Node.js：

```bash
git clone https://github.com/sibosend/rdp-auto-login.git
cd rdp-auto-login
npm install
```

### 2. 修改配置

编辑 `index.js`，把用户名密码改成目标账号的：

```javascript
const protocol = require('./protocol');  

const c = protocol.rdp.createClient({ 
    domain : '',                  // 域用户填域名，本地用户留空
    userName : 'your_username',   // 改成目标账号
    password : 'your_password',   // 改成对应密码
    enablePerf : true,
    autoLogin : true,
    decompress : false,
    screen : { width : 1920, height : 1200 },
    locale : 'en',
    logLevel : 'INFO'
}).connect('127.0.0.1', 3389)     // 连本机，一般不用改
```

改完先跑一下验证：

```bash
npm run start
```

控制台打出 `connected` 就说明成功了。打开任务管理器切到"用户"标签页，应该能看到目标账号已在线。

### 3. 打包成 exe

生产环境不想装 Node.js，用 `pkg` 打包成独立可执行文件：

```bash
npm install -g pkg
pkg -t node18-win-x64 index.js
mv index.exe RDP-logon.exe
```

### 4. 后台静默运行

直接双击 exe 会弹黑框窗口。项目里带了一个 `RDP-logon.vbs`，用 `WScript.Shell` 以隐藏窗口方式启动 exe：

```vbscript
objShell.Run """" & exePath & ".exe""" & strArguments, 0, False
' 第二个参数 0 = 隐藏窗口，False = 不等待进程结束
```

部署步骤：

1. 把 `RDP-logon.exe` 和 `RDP-logon.vbs` 放同一个目录
2. `Win+R` 输入 `shell:startup`，打开启动目录
3. 把 `RDP-logon.vbs`（或其快捷方式）丢进去

这样每次宿主账号登录时，VBS 会自动在后台把目标账号登上去。

## 注意事项

- **远程桌面必须开启** — 系统属性 → 远程 → 勾选"允许远程连接到此计算机"，否则 3389 端口没在监听。
- **多用户并发** — Windows Server 天然支持多会话；Win10/11 专业版默认只允许一个远程会话，需要 RDPWrap 之类的工具解除限制，否则新登录会踢掉当前用户。
- **安全性** — 密码明文写在 `index.js` 中，打包后不容易直接看到但也不算安全。如有要求，建议加密或从配置文件读取。

## 相关链接

- GitHub 仓库：[https://github.com/sibosend/rdp-auto-login](https://github.com/sibosend/rdp-auto-login)
