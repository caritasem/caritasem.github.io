---
layout: article
title:  "how to install blender as a python module on Ubuntu 20.04"
date:   2024-03-26 11:00:07 +0800
categories: blender
tags: 
    - blender
    - ubuntu
    - bpy
---

在服务器上需要用到Blender bpy库来处理3D模型，发现普通安装过程非常难解决环境依赖问题，无论是 pip install bpy，还是按照官网推荐的 source code compile方式，都不容易走通。

解决方案是使用 wheel 方式安装，不用关心依赖关系了~

```
# 创建虚拟环境
conda create --prefix /folder/condaenv/blender python=3.10
conda activate /folder/condaenv/blender

# 下载whl
wget https://pypi.tuna.tsinghua.edu.cn/packages/9c/cf/536e231d0fff186e46668ae701f6788cdd740ff48545dadfad234bb0255b/bpy-3.6.0-cp310-cp310-manylinux_2_28_x86_64.whl#sha256=ede2c95ace7848f4f5a075a7d8cc3a9e643c335f4596c3c15087d93c7ae5f56a

# 安装
pip install bpy-3.6.0-cp310-cp310-manylinux_2_28_x86_64.whl

```

all done!

<img src="/assets/posts/202403/bpy.png">

### 附录

#### wheel（.whl）包到底是什么
wheel包本质上是一个zip文件。是已编译发行版的一种格式。需要注意的是，尽管它是已经编译好的，包里面一般不包含.pyc或是Python字节码。一个wheel包的文件名由以下这些部分组成：

{dist}-{version}(-{build})?-{python}-{abi}-{platform}.whl

以上面的bpy为例：

bpy-3.6.0-cp310-cp310-manylinux_2_28_x86_64.whl

bpy是包名（dist）。
3.6.0是包的版本号（version）。
cp310是对python解释器和版本的要求（python）。cp指的是CPython解释器，310指的是版本3.10的Python。
第二个cp310是ABI的标签（python）。ABI即应用二进制接口（Application Binary Interface）。这个一般来说我们不用关心。
manylinux_2_28_x86_64是平台标签（platform），告诉我们这个包是为 Linux 操作系统的，适用于x86-64指令集。

manylinux是一个比较有意思的平台标签。鉴于Linux系统有不同的发行版（Ubuntu，CentOS，Fedora等等），而安装包需要编译C/C++代码，那有可能不同Linux发行版就不能运行安装包了，而为每个Linux发行版生成一个wheel又太麻烦，所以就诞生了manylinux系列标签：manylinux1（PEP513），manylinux2010（PEP571）和manylinux2014（PEP599）。
manylinux标签的核心是一个CentOS的Docker镜像，打包了一些编译器套件、多版本Python和pip、动态库等来确保兼容性。这个在PEP513里面有提到。


