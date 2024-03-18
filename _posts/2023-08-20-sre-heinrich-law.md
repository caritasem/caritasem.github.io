---
layout: article
title:  "稳定性之heinrich’s law"
date:   2023-08-20 20:00:07 +0800
categories: engineering
tags: 
    - sre
    - model
---

### 海因里希法则和稳定性

海因里希法则是美国著名安全工程师海因里希提出的300：29：1法则。意思是：当一个企业有300起隐患或违章，非常可能要发生29起轻伤或故障，另外还有一起重伤、死亡事故。"海因里希法则”原是通过分析工伤事故的发生概率，为保险公司的经营提出的法则。

<img src="/assets/posts/202308/Snip20230821_79.png">


对于稳定性方面的启发是：如果能在发生第一个隐患时找到事情的根因，就可以避免后续的故障和事故。即在一件重大的事故背后必有29件“轻度”的事故，还有300件潜在的隐患。可怕的是对潜在性事故毫无觉察，或是麻木不仁，结果导致无法挽回的损失。了解“海因里希法则”的目的，是通过对事故成因的分析，让人们少走弯路，把事故消灭在萌芽状态。


### 根因探查 5Why模型


---
- https://en.wikipedia.org/wiki/Accident_triangle

- https://blog.csdn.net/so_geili/article/details/110293117