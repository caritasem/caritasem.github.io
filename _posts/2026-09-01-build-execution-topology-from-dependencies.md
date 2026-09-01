---
layout: article
title: "由依赖关系构建执行拓扑：风控决策引擎的依赖闭包与分层调度"
date: 2026-09-01 10:00:00 +0800
categories: [Architecture, Algorithm]
tags: [DAG, Topological-Sort, BFS, Python, Risk-Engine]
---

一次信贷或反欺诈决策，往往要串起数十到上百个处理步骤：多源数据查询、特征衍生、模型打分。为了应对特征与模型的频繁迭代和严苛的时延要求（SLA），决策引擎普遍采用声明式依赖编排。本文记录如何由声明式依赖推导出分层执行拓扑，并对其中依赖闭包计算的两版实现做复杂度与实测对比（基准测试：全图规模 $\lvert V \rvert=256$，目标节点数 $\lvert R \rvert=24$，闭包构建耗时从 2,987 ms 降至 2.33 ms）。

<!--more-->

---

## 一、背景

在风控决策系统中，单次调用通常要串起三类工作：

1. **取数（I/O）**：从宽表与文档存储（如 HBase、Elasticsearch）、内存缓存（如 Redis）、关系型数据库以及第三方 RPC 服务拉取原始数据；
2. **算特征（计算）**：多维度指标聚合、滑动窗口统计、关联图谱特征提取；
3. **打分（推理）**：机器学习模型推理、评分卡打分计算。

三者之间是自底向上的数据流动关系，一次典型调用大致长这样：

```text
                     请求参数
                         │
        ┌────────────────┼────────────────┐
        ▼                ▼                ▼
    数据获取         数据获取         数据获取      ← DB / 缓存 / RPC
        │                │                │
        └────────────────┼────────────────┘
                         ▼
                     特征计算                       ← 聚合、滑窗、交叉
                         │
                         ▼
                     模型打分                       ← 评分卡、模型推理
                         │
                         ▼
                     决策结果
```

这张图画的只是类别之间的流向，每一类实际都不止一层：特征可以依赖特征，模型也可以依赖其他模型的输出，展开后是一张网状图。

风控特征与模型迭代频繁。若把全局执行顺序写死在代码里，系统会越来越难维护，也无法根据请求裁掉无关计算。因此实践中改成声明式：每一步只声明自己需要哪些前置结果（`depend`）和可选的顺序约束（`run_after`），完整的执行顺序交给引擎在运行时根据本次请求的目标推导。

## 二、问题

风控请求按业务场景组织，每次调用只显式指定一组目标节点集合 $R$（例如某个评分场景需要的几个打分结果），这些目标底下用到的多级特征与数据源都是隐式依赖，需要引擎自己推。

实际决策图并不是「数据到特征、特征到模型」的固定三层结构，而是多层交织的依赖网络：
- **特征级联依赖（Feature-to-Feature）**：高阶衍生特征（如滑窗统计、交叉特征、图关联特征）依赖基础统计特征，形成多层特征衍生链；
- **模型级联依赖（Model-to-Model）**：综合决策模型或总评分卡（如二阶段 Stacking 模型）直接依赖前置子模型或反欺诈子评分的输出。

```text
    data_user    data_device              feature_other
        └──────┬──────┘                         │
               ▼                                ▼
         feature_base ────────────┐        score_other      ✗ 本次用不到
               │                  │
               ▼                  │
        feature_derived           │
               │                  │
               ▼                  │
          score_sub_a             │
               │                  │
               ▼                  │
         score_final  ◄───────────┘                         ★ 本次的目标
```

箭头方向即数据流向，`A ──> B` 表示 B 依赖 A 的输出。这张小图里已经出现了三种典型结构：`feature_base ──> feature_derived` 是特征依赖特征，`score_sub_a ──> score_final` 是模型依赖模型，而 `feature_base` 同时被 `feature_derived` 和 `score_final` 引用，构成菱形。

本次请求只指定了 `score_final` 这一个目标，引擎需要沿箭头反向回溯，把它用到的节点全部收集起来，得到依赖闭包 $V_{sub}$；右侧的 `feature_other` 与 `score_other` 不在这条链路上，应当整条剪掉，不做任何初始化和调用。

### 复杂度来源与核心挑战

1. **同类与跨类多层级联**：
   节点之间不只有跨类别依赖（数据源 $\to$ 特征 $\to$ 模型），还大量存在同类级联（特征衍生特征、模型依赖模型输出）。依赖拓扑深度大，且多条长短不一的依赖路径相互交错。
2. **多目标驱动的隐式子图提取（$\lvert R \rvert \ge 1$）**：
   单次请求通常会指定多个目标（如主评分 `score_final` 与辅助模型 `score_sub_a`），引擎必须从包含数百个节点的全量图 $V$ 中逆向推导，界定出最小必要闭包 $V_{sub}$，未被引用的无关节点（如 `score_other`）必须彻底剔除。
3. **多重菱形汇聚（Diamond Dependencies）**：
   多个模型共同依赖同一衍生特征，多个衍生特征又依赖同一基础特征与底层数据源。这种多对一的拓扑汇聚使得朴素的图遍历算法极易在没有状态记忆的情况下，对公共子树进行指数级的重复递归展开。

在此场景下，执行引擎面临两个核心问题：
1. **隐式依赖子图推导的算法效率**：如何从多目标集合出发，在包含多级特征衍生与模型级联的复杂菱形图中以最优复杂度求解可达闭包 $V_{sub}$，避免指数级计算膨胀。
2. **时序保证与最大化并发调度**：在满足依赖约束的前提下，如何把 $V_{sub}$ 划分为互无依赖的执行代（Generations），让同一代内的节点尽可能并发，满足毫秒级决策 SLA。

## 三、模型抽象

### 1. 为什么抽象「算子（Operator）」概念

在风控决策执行流中，处理单元涵盖了网络 I/O（数据源拉取）、特征加工（指标衍生）与模型推理（评分卡/ML打分）。将它们统一抽象为**算子（Operator）**，核心依据如下：
- **统一执行契约，消除特殊分支**：每个算子遵循一致的生命周期与接口契约（声明输入依赖、执行数据变换、产出结构化结果）。调度引擎无需针对特定业务编写独立分支，全量处理单元共用依赖解析、并发分批、超时熔断与指标监控逻辑。
- **解耦声明与时序**：算子内部仅关注局部前置输入，不感知下游调用方或全局执行位置，便于特征与模型在不同风控场景中复用与动态组装。

### 2. 为什么将「数据库连接与数据源」也抽象为算子

系统通常倾向于将基础设施（如数据源连接池、远程服务客户端配置）视为全局预加载对象，但在此模型中将其同样封装为 DAG 的底层数据源算子（如 `data_user`、`data_device`），依据如下：
- **按需激活（Lazy Initialization）**：在闭包推导阶段，未被目标算子引用的数据源不会被纳入执行子图，彻底避免了无关请求对底层连接池与 I/O 资源的无谓消耗。
- **并发初始化与同层对齐**：独立数据源算子入度为 0，自然归入拓扑图第 1 层级，可由调度器直接并行拉起预热。

### 3. 图模型定义

将算子依赖关系建模为有向图 $G = (V, E)$，其中 $V$ 为全量算子集合，$E$ 为依赖边集合。

依赖关系分为两类：
- **数据依赖（`depend`）**：若算子 $u \in \text{depend}(v)$，则建立有向边 $u \to v$。表示算子 $u$ 的输出为 $v$ 的输入，$u$ 必须先于 $v$ 执行完毕。
- **顺序约束（`run_after`）**：若算子 $w \in \text{run\_after}(v)$ 且 $w, v \in V_{sub}$，则建立临时约束边 $w \to v$。仅约束执行先后，不激活非依赖算子。

仍以第二节那张图为例，写成声明就是：

```text
data_user        depend: [request_param]
data_device      depend: [request_param]
feature_base     depend: [data_user, data_device]
feature_derived  depend: [feature_base]
score_sub_a      depend: [feature_derived]
score_final      depend: [feature_base, score_sub_a]   ← feature_base 被两条路径共用，即菱形
```

每个算子只写自己这一行，谁都不需要知道全局顺序。

计算目标：
1. **依赖可达闭包求解**：给定目标算子集 $R \subseteq V$，在逆向数据依赖边构成的子图上求解可达节点集合 $V_{sub} \subseteq V$。
2. **分层拓扑排序（Topological Generations）**：在导出子图 $G[V_{sub}]$ 上添加有效的 `run_after` 顺序约束边，随后计算分层拓扑序列 $[L_0, L_1, \dots, L_k]$，其中每代 $L_i$ 内的算子入度为 0。

## 四、实现效果（初始版本）

执行拓扑的构建与调度由以下三步完成：

1. **计算依赖闭包**：由目标集合 $R$ 反向遍历 `depend` 边，收集所有前置可达算子构成集合 $V_{sub}$。在初始版本中，闭包求解由函数 `get_related` 实现（采用朴素递归与全表匹配）：

```python
def get_related(all_operators, operators):
    """初始版本依赖闭包：递归遍历全量字典提取依赖"""
    ref_ops = []
    for op_name, op_conf in all_operators.items():            # 遍历全量配置
        if op_name not in operators:                          # list 线性查找
            continue
        ref_ops.append(op_name)
        ref_ops.extend(get_related(all_operators, op_conf.get("depend") or []))
    return ref_ops
```

2. **补充顺序边**：遍历 $V_{sub}$ 中算子的 `run_after` 配置，若目标节点亦属于 $V_{sub}$，则注入临时约束边；不在 $V_{sub}$ 中的算子予以忽略。
3. **分层拓扑排序**：基于 Kahn 算法按入度计算拓扑分代，核心代码如下：

```python
import networkx as nx

# active_ops 即依赖闭包提取出的算子集合
active_ops = set(get_related(all_operators, target_operators))

G = nx.DiGraph()
for name in active_ops:
    G.add_node(name)
    conf = all_operators[name]
    for dep in conf.get("depend") or []:
        if dep in active_ops:
            G.add_edge(dep, name)  # dep 完成后 name 方可执行
    for prior in conf.get("run_after") or []:
        if prior in active_ops:
            G.add_edge(prior, name)

order = list(nx.topological_generations(G))
```

对第二节那张图跑一遍，得到的分层结果是：

```text
Layer 0: [request_param]
Layer 1: [data_user, data_device]      ← 互无依赖，并发拉取
Layer 2: [feature_base]
Layer 3: [feature_derived]
Layer 4: [score_sub_a]
Layer 5: [score_final]
```

调度执行机制：
- **同层并发**：同一层内的算子互不依赖，由调度框架整批并发提交。
- **层间串行推进**：一层全部执行完毕，才推进到下一层。进入某层之前它的前置数据已经就绪，此时可以顺便做一次准入判断，根据上游数据状态决定本层算子是否跳过，省掉昂贵的外部调用与特征计算。

在业务早期算子数量较少（如 $\lvert V \rvert \le 20$）且依赖链较短时，该初版实现逻辑直观，能够正常推导拓扑并驱动分层并发调度。

## 五、性能问题：量级放大时的性能坍塌

在拓扑构建的三步流程中，第 2 步（顺序边注入）与第 3 步（Kahn 分层排序）均直接在规模较小的导出子图节点集 $V_{sub}$ 上操作，单次执行耗时通常不到 1 ms。

然而，随着系统演进与算子规模扩大（全图节点数增多、目标算子集扩大，且特征间存在深层菱形共享依赖），第 1 步的初版实现 `get_related` 出现了严重的性能退化：计算耗时随图规模由亚毫秒级迅速退化至数秒量级，直接违背了在线服务毫秒级时延的基线要求。

### 瓶颈归因剖析

性能坍塌的根源在于三个低效设计在量级放大时产生了**乘法级放大效应**：

1. **字典全表扫描乘数**：
   要匹配的仅是 `operators` 中的少数名称，`get_related` 每次递归却遍历全量算子配置字典 `all_operators`（循环次数为全图节点数 $N=\lvert V \rvert$），失去了哈希表 $O(1)$ 寻址的优势。
2. **列表线性检索乘数**：
   `op_name not in operators` 是基于 `list` 的线性检索（时间复杂度 $O(K)$，其中 $K=\lvert\text{operators}\rvert$）。全表扫描与线性查找叠加，使单次递归调用需执行 $\lvert V \rvert \times K$ 次字符串比较。
3. **缺乏访问标记（visited），菱形依赖指数级展开（核心硬伤）**：
   在复杂特征体系中，菱形依赖（多个算子依赖同一上游算子）极为普遍。`get_related` 缺乏已访问状态标记，导致共享子图每被一条新路径触达就完整重递归一次，调用次数随图深度与分叉度呈树状指数膨胀。

### 基准测试数据（典型图规模案例）

为了量化上述乘法效应在实际依赖图中的影响，在全图规模 $\lvert V \rvert=256$、目标节点集合 $\lvert R \rvert=24$ 的基准图结构下进行实测：
- **递归调用次数**：2,605 次
- **配置行扫描次数**：$2,605 \times 256 = 666,880$ 次
- **输出列表长度**：2,604 项（实际去重后仅 129 个算子，重复率达 95.0%）
- **闭包计算耗时**：2,987 ms

## 六、算法对比与优化

### 1. 如何优化：基于 BFS 与 Visited 的闭包求解

针对量级放大暴露的乘法瓶颈，优化版本将闭包求解重构为函数 `collect_related`：改用队列迭代（BFS）、引入 `visited` 集合记忆化剪枝、通过字典键值直接索引：

```python
from collections import deque

def collect_related(all_operators, operators):
    """优化版本依赖闭包：BFS 迭代 + 哈希判重"""
    visited, queue = set(), deque(operators)
    while queue:
        name = queue.popleft()
        if name in visited:                  # 哈希判重，菱形依赖仅展开一次
            continue
        visited.add(name)
        for dep in all_operators[name].get("depend") or []:
            if dep not in visited:
                queue.append(dep)
    return visited
```

三个核心优化针对性消除了原有的计算乘数：
- **`visited` 集合记忆化**：每个节点与边在逆向遍历中仅访问一次，直接消除菱形依赖的重复展开，将理论复杂度从 $O(\text{TreeSize} \times N)$ 降至图遍历的 $O(\lvert V_{sub} \rvert + \lvert E_{sub} \rvert)$；
- **`all_operators[name]` 键值直取**：$O(1)$ 字典索引替代全表扫描，仅触达闭包内的 $\lvert V_{sub} \rvert$ 个关联配置节点；
- **`set` 判重替代 `list` 线性检索**：成员检查由 $O(K)$ 降为 $O(1)$。

### 2. 优化效果对比

在完全相同的基准测试场景下（图规模 $\lvert V \rvert=256$，目标节点数 $\lvert R \rvert=24$），优化前后的算法特征与实测性能对比如下：

| 指标 | 递归全表扫描（初始版本） | BFS + Visited（优化版本） | 优化收益 |
|---|---|---|---|
| 时间复杂度 | $O(\text{TreeSize} \times N)$ | $O(\lvert V_{sub} \rvert + \lvert E_{sub} \rvert)$ | 消除指数膨胀 |
| 配置访问次数 | 666,880 次 | 129 次 | 访问次数减少 99.98% |
| 输出元素数量 | 2,604 项（含大量重复） | 129 项（去重集合） | 消除冗余展开 |
| 依赖闭包构建耗时 | 2,987 ms | 2.33 ms | **耗时降低约 99.92%** |

基准测试显示，优化后的 `collect_related` 将依赖闭包构建耗时从 2,987 ms 降至 2.33 ms，降幅约 99.92%。更重要的是，优化后的计算量由导出子图的节点数和边数决定，不再随着重复依赖路径迅速膨胀。
