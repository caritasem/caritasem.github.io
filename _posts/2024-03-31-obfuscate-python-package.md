---
layout: article
title:  "how to obfuscate a python project"
date:   2024-03-31 11:00:07 +0800
categories: python
tags: 
    - obfuscate
    - python
    - pyarmor
---

一些场景下，需要对python源码进行混淆加密，可选成熟方案是使用 pyarmor。在调研过程中，一些使用说明过于简洁，因此留档此demo项目。

示例工程 https://github.com/sibosend/python_obfuscate_demo

频繁遇到package找不到的错误，关键在于需要对内部package分别进行混淆处理，见 pyarmor.py




