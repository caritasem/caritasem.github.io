---
layout: article
title:  "MAC 如何安装 bsddb3"
date:   2023-10-26 20:00:07 +0800
categories: python
tags: 
    - python
    - mac
    - bsddb3
---

### 可行的方案
```
conda install -c conda-forge bsddb3
```

详细文档见 https://anaconda.org/conda-forge/bsddb3


### 不成功的方式

pip install bsddb3直接安装失败，报错：

```
Collecting bsddb3 (from scrapy-deltafetch)
  Using cached bsddb3-6.2.4.tar.gz
    Complete output from command python setup.py egg_info:
    Can't find a local Berkeley DB installation.
    (suggestion: try the --berkeley-db=/path/to/bsddb option)
```

即使 brew install berkeley-db  之后，再次pip依旧报同样的错误。。。


--- 
1. https://igaojin.me/2018/08/06/MAC-%E5%A6%82%E4%BD%95%E5%AE%89%E8%A3%85-bsddb3/

