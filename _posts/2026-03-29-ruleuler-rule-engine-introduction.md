---
layout: article
title:  "RulEuler：基于 Rete 算法的开源规则引擎"
date:   2026-03-29 10:00:00 +0800
categories: java
tags: 
    - rule-engine
    - rete
    - spring-boot
    - open-source
---

业务系统里大量的 if-else 判断逻辑（风控策略、审批流程、定价规则等）散落在代码中，每次调整都要改代码、测试、发版。[RulEuler](https://sibosend.github.io/ruleuler/) 是一个基于 Rete 算法的开源规则引擎，将业务规则从代码中剥离，通过可视化编辑和文本表达式管理规则，实现热更新和独立维护。

<!--more-->

## 项目背景

RulEuler 基于 URule 2.1.6（Bstek 开源版）二次开发。URule 核心引擎成熟可靠，但 JCR 存储模型对多数开发者不够直观。RulEuler 在保留核心引擎的基础上做了以下改进：

| 改进项 | URule 开源版 | RulEuler |
|--------|-------------|----------|
| 存储方式 | 仅 JCR（Jackrabbit） | 新增 MySQL 关系表存储 |
| 运行时框架 | Spring Boot 2.x | Spring Boot 3.x + JDK 21 |
| 管理后台 | jQuery + Bootstrap 3 | React 18 + Ant Design 5 |
| 规则编辑 | 操作繁琐 | 新增 REA 文本表达式编辑器 |
| 变量定义 | 需预定义 Java POJO | GeneralEntity 动态类型 |
| 权限控制 | 无 | RBAC 用户/角色/权限体系 |
| 自动测试 | 无 | 路径覆盖 + MC/DC 自动生成测试用例 |
| 认证 | 无 | JWT 认证 |


## 适用场景

- **风控决策** — 信用评分、反欺诈规则、额度审批
- **业务审批** — 多级审批流程、条件分支路由
- **动态定价** — 促销规则、折扣策略、阶梯计价
- **资源分配** — 机位分配、工单派发、负载均衡策略
- **合规校验** — 数据校验规则、业务合规检查

## 核心特性

- **可视化规则编辑** — 决策表、决策树、决策流、评分卡，拖拽式配置
- **REA 文本编辑器** — 自然语言风格的表达式编写规则，效率更高

![REA 文本表达式编辑器](https://sibosend.github.io/ruleuler/assets/images/rea.png)
- **Rete 算法驱动** — 高效模式匹配，适合大量规则并发执行
- **知识包热更新** — 规则修改后客户端自动加载，无需重启
- **自动测试** — 基于路径覆盖自动生成测试用例，回归比对输出变化

![自动测试](https://sibosend.github.io/ruleuler/assets/images/test.png)
- **RBAC 权限控制** — 用户、角色、项目级权限管理

## 架构概览

RulEuler 由两个独立部署的服务组成，通过 MySQL 共享规则数据：

```
浏览器 --> 管理后台 (ruleuler-server + ruleuler-admin) :16009
业务系统 --> 规则执行 (ruleuler-client) :16001
管理后台 --> MySQL
规则执行 --> MySQL
```

- **管理后台** — 规则编辑、项目管理、权限控制
- **规则执行** — 加载知识包，执行决策流，对外提供 REST API

## 快速体验

30 秒用 Docker 跑起来：

```bash
git clone https://github.com/sibosend/ruleuler.git
cd ruleuler
cp .env.example .env
docker compose up -d --build
```

启动完成后访问 `http://localhost:16009/admin/`，
调用规则示例：

```bash
curl -X POST http://localhost:16001/process/airport_gate_allocation_db/gate_pkg/gate_allocation_flow \
  -H 'Content-Type: application/json' \
  -d '{
  "FlightInfo": {
    "aircraft_type": "A380",
    "arrival_time": 8,
    "is_international": true,
    "passenger_count": 260
  },
  "GateResult": {}
}'
```

## 相关链接

- 项目主页：[https://sibosend.github.io/ruleuler/](https://sibosend.github.io/ruleuler/)
- GitHub 仓库：[https://github.com/sibosend/ruleuler](https://github.com/sibosend/ruleuler)
