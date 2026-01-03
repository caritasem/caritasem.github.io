---
layout: article
title:  "本地部署 Overleaf + VS Code 打通 + Copilot / Gemini / Claude 辅助写 LaTeX"
date:   2026-01-03 11:00:07 +0800
categories: python
tags: 
    - latex
    - overleaf
    - template
    - vscode
    - copilot
---

上文（本地化部署 Overleaf）：https://caritasem.github.io/2024/08/latex-on-premise-overleaf-template/

本文记录两件事：
- 用 VS Code（Overleaf Workshop 插件）把项目同步到本地编辑，并用 Copilot 做润色/改写等 AI 协作。


## 1. VS Code 打通 Overleaf（Overleaf Workshop）

### step 1：安装插件

在 VS Code 扩展里搜索并安装：`Overleaf Workshop`。

![search-btn](/assets/posts/202601/0.search.png)

类 VS Code 编辑器一般也可用（例如 Antigravity），步骤基本一致。

### step 2：用 Cookie 登录（相当于以 co-author 身份接入）

插件目前常见的方式是「Login with Cookie」。从网页端 Overleaf 取 Cookie：

1) 打开 Overleaf 网页端，F12 -> DevTools -> Network。
2) 过滤 `/project`，然后刷新页面。
3) 点开对应请求，在 Request Headers 里找到 `Cookie`，复制完整内容。

![cookie](/assets/posts/202601/2.cookie.png)


回到 VS Code：
- Overleaf Workshop 侧边栏 -> `Login with Cookie` -> 粘贴 Cookie。

![cookie-btn](/assets/posts/202601/1.cookiebtn.png)


### step 3：同步项目到本地并编译

登录成功后，插件会列出你的项目（含已删除的项目）。选择一个项目打开，就会把 `.tex` 等文件同步到本地工作区。

在本地 `.tex` 文件里触发编译即可看到和网页端类似的效果。

编译快捷键（参考文章）：macOS 为 `Option+Command+V`（Windows/Linux 按插件默认/自定义为准）。

![result](/assets/posts/202601/3.res.png)

### 常见问题：连的是哪个 Overleaf？

如果你是自建 Overleaf（本地 or 内网），需要在插件/配置里把 Overleaf 服务器地址指向你的服务。

![add-server](/assets/posts/202601/1.addserver.png)

（不同版本的插件入口可能略有差异，核心就是：让插件访问到你的 Overleaf 域名/端口，然后再用 Cookie 做登录。）

## 2. Copilot 辅助写 LaTeX（润色/改写/结构化）

有了 VS Code 后，AI 协作基本等价于「对着本地 `.tex` 文件用 Copilot」。常用用法：
- 让 Copilot 帮你把口语化表达改成更学术/更简洁的句式。
- 让 Copilot 生成表格/公式骨架（你再补数据）。
- 让 Copilot 按某个会议/期刊风格做引用格式微调（仍建议你最终用 bibtex/biblatex 管理）。



## 常用latex 模版
- [清华大学论文](https://github.com/tuna/thuthesis)
- [简历模版](https://github.com/sibosend/latex-resume-template)