# Cardfront 重构路线图（2026-08-07）

状态：**Design Freeze COMPLETE / P0 READY**  

> 本文件现在只负责**阶段路线、执行顺序和入口导航**。具体状态模型、接口、不变量、测试矩阵和变更控制，统一以 `CARDFRONT_ENGINEERING_SPEC_2026-08-07.md` 为准。

## 文档权威顺序

在 2026-08-07 这次战线/构筑重构范围内：

1. **`CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`** — 当前工程合同，FROZEN FOR P0。
2. **本文件** — P0/P1/P2 路线图与阶段入口。
3. **`GRILLME_GAME_DESIGN_INTERVIEW.md`** — 设计讨论与历史决策记录。

`PROJECT_STATUS.md` 继续描述“仓库现在已经实现了什么”；Engineering Spec 描述“本轮重构必须实现成什么”。

> `GRILLME_GAME_DESIGN_INTERVIEW.md` 末尾旧的“尚有约5个问题”是中途快照；这些问题已经在后续 GrillMe 中完成，不再作为当前待办。

---

# 1. 本轮目标

解决五个根问题：

1. 左下分桥缺乏战略意义。
2. 双方后方据点作用弱且遮挡视线。
3. 三选一“回看战场”造成布局永久偏移。
4. 玩家 / AI 构筑候选过度绑定，双方成长过于相似。
5. 卡牌强弱缺乏结构，无法同时做到“强卡真的强、弱卡仍有阶段价值”。

顶层目标：

> **地图空间参与构筑；战线会成长；双方从相同基础出发，通过英雄身份、实际战场行为和独立三选一形成不同军队。**

本轮不重写 Draft -> Aim -> Volley/Execution 高层循环，不取消现有 Command Point，也不主动改变约 8–12 分钟对局目标。

---

# 2. P0 — 最小战线闭环 + 工程边界

目标：先证明新战线核心成立，并修掉明确架构/Bug 问题，不铺满内容。

## P0-00 当前回归基线

- 项目启动/进入对局烟雾测试。
- 记录 Draft -> Aim -> Volley 当前行为。
- 验证 Command Point 当前行为。
- 定位三选一 Draft Overlay 与“回看战场”的真实拥有者。
- 记录桌面/窄屏基础 UI 状态和当前日志/测试入口。

## P0-01 Support Domain Model

- 部署支点静态定义与动态状态分离。
- `claim_owner / operational / capture / network_connected` 分离。
- 禁止用一个 `ACTIVE/NEUTRAL/CAPTURED` 枚举包办所有语义。

## P0-02 Capture & Support Semantics

- 支点可压制/摧毁/接管。
- Capture 完成不等于立即能部署。
- 双方争夺时暂停。
- 占领人数采用递减/上限。
- 支点失效不删除已部署单位。

## P0-03 Battle-line Graph

- Core Base 为每方永久根节点。
- 地图 authored nodes/edges。
- 状态变化时 BFS/DFS 重算并缓存；禁止每帧搜索。
- 孤立敌后 Claim 不能部署。
- 分桥成为真正的 alternate flank path。
- 每方部署方向使用确定性的 authored metadata。

## P0-04 Authoritative Deployment

- 扩展现有 `scripts/cardfront/deployment/DeploymentRules.gd`。
- Core 永久部署区。
- Online Support 后方/侧后方定向部署区。
- 普通单位不得越过战线。
- 玩家 UI 与 AI 共用同一 validator。

## P0-05 Branch Integration

- 左下分桥接入侧翼/备用战线。
- 至少验证“主路断裂而分桥仍维持另一条合法路径”的场景。

## P0-06 Support Visuals

- 在稳定状态模型后再做视觉。
- 弱实体化：地面环、小旗、发光底座、矮信标、地表标记。
- 可读 Active / Offline / Capturing / Contested / CapturedOffline。
- 主战场默认不显示网络蜘蛛网；部署时才显示合法区。

## P0-07 Draft Preview Bug

只实现：

```text
DRAFT_VISIBLE <-> BATTLEFIELD_PREVIEW
```

- 固定按钮。
- 只切三选一内容层 visible/state。
- 禁止改 anchor/offset/reparent/移出屏幕。
- 不重新生成 Offer。
- 回看期间仍保持 Draft pause。
- 20 次往返无布局漂移、无重复信号。

**P0 不依赖 reroll。** Reroll 实现后再在 P1 补 `reroll -> preview -> return` 回归。

## P0-08 Player / AI Offer Independence

沿现有：

```text
CardfrontRoundDirector
    -> CardfrontUpgradeDraftSystem
```

演进，不另建平行 Draft 总控。

- 双方 Eligible context 独立。
- 双方 Offer 对象独立。
- 双方 RNG stream/state 独立。
- 可以共享 immutable 卡牌定义。
- 偶然同轮撞到同一基础卡允许。

## P0-09 Duplicate -> Level

- 已有卡重复选择 -> Level +1。
- 数量/数值/机制属于固定 per-card upgrade track。
- 不继续向牌堆加入同 ID 独立副本。
- 优先封装现有 `CardfrontFactionRunState.applied_upgrade_counts` 为明确 Level API。

## P0-10 Minimal AIObservationBuilder

从 P1 前移到 P0：

```text
Game runtime
    -> AIObservationBuilder
    -> PublicBattleState
       + OwnPrivateState
       + ObservedEnemyHistory
    -> CardfrontAiCommander
```

P0 只建立信息权限边界，不做完整困难 AI。

## P0-11 Full Regression + Go/No-Go

进行完整单元、集成、性能和人工验收。

### P0 强弱关系测试的阶段修正

P0 不提前实现完整深度路线，而使用测试夹具，例如：

`SiegePlatform_Test = 极高攻坚 / 低机动 / 控制0`

用它验证：强卡能把支点打下来，但仍需要低费控制单位完成接管。

---

# 3. P0 Go / No-Go

全部核心条件基本成立后才进入 P1：

1. 玩家一局后能解释 Main route / Branch route 的不同作用。
2. 支点失守切断前沿增援，但 Core 仍允许反攻。
3. CapturedOffline 不会被误当成 Active。
4. 孤立敌后支点不会成为传送出生点。
5. 定向部署规则可理解。
6. 玩家与 AI 使用同一部署规则层。
7. Player / AI Offer 真正独立。
8. Duplicate -> Level 不造成牌池膨胀。
9. 回看战场连续 20 次无布局漂移/Offer 重生成/重复信号。
10. `SiegePlatform_Test` 证明“强卡能赢战斗但不能自己完成战争”。
11. 没有“夺一个支点 -> 前沿刷兵 -> 自动滚穿全图”的明显雪球。
12. AIObservation 不包含对方 Offer、隐藏路线精确值、future RNG/Offer。
13. Draft -> Aim -> Volley 和 Command Point 未被重构破坏。

失败时回到 Support / Graph / Deployment / Offer 边界修正，不用“继续加卡”掩盖核心问题。

---

# 4. P1 — 构筑分化 + 平衡闭环

P0 通过后再做：

- 基础 / 英雄 / 路线三类 Eligible Pool。
- 实际战场行为形成路线倾向。
- 路线反馈：未形成 / 正在形成 / 接近解锁 / 已解锁。
- 一局最多 2 条深度路线。
- 先完整实现 2–3 条代表路线，不一次铺满。
- 一级路线卡 + 真正强的深度路线卡。
- 每次 Draft 一次免费整体 reroll。
- reroll 不累计、不偷偷提高稀有度、刚放弃的 3 张暂时排除。
- `reroll -> preview -> return` 回归测试。
- 首批核心卡独立升级轨。
- 玩家卡面 Combat / Mobility / Control 三轴。
- 内部能力画像 + 六类固定测试场景。
- Easy / Normal AI Decision Strength；信息权限不变。
- 调整成长节奏，让成熟 Build 至少有约最后 1/3 的实际使用窗口。

路线解锁遵循：

> **解锁的是“可能性”，不是直接发卡。**

主要由实际战场行为驱动，选卡只做辅助倾向。

---

# 5. P2 — 内容扩展 + 特殊规则 + 高级 AI

- 完整路线和高阶卡目录。
- 空降突击队、渗透小队、前沿工兵等明确越线例外。
- 更完整英雄职业差异。
- Hard AI：较长规划、当前对局玩家行为记忆、路线推断、资源保留。
- 高级平衡统计与实战数据分析。
- 桌面 / 窄屏 / 移动端整体视觉整理。
- 后续 PvP 复用同一 Information Fairness 边界。

---

# 6. 设计冻结的核心原则索引

详细规则见 Engineering Spec。这里仅保留导航：

- 后方据点 = 弱实体化 Deployment Support。
- Capture / Claim / Operational / Connectivity 是不同维度。
- Core Base 永远是最低部署源。
- 普通支点不是 360° 出生圈。
- 普通单位不能越过战线部署。
- 深度强卡可以极强，但不能 Combat/Mobility/Control 三轴全顶级。
- **强卡可以赢战斗，但不能自己完成战争。**
- 弱卡不追求后期正面等强；必须存在明确的阶段/战术选择理由。
- 平衡 = 玩家三轴 + 内部多维画像 + 固定场景/实战验证；禁止单一综合分。
- 卡牌来源只分基础 / 英雄职业 / 局内路线三类。
- 深度路线最多 2 条。
- Offer = hard eligibility + soft weight + bounded guards + randomness。
- Diversity Guard 与 Dominance Guard 都是软保护，不强制等价三选一。
- AI 难度 = Decision Strength，不是作弊 Information。
- AI 不使用隐藏属性加成伪装成“更聪明”。

---

# 7. 下一步

**不再继续 GrillMe。**

从：

> `P0-00 当前回归基线`

开始执行。

编码前、实现中和验收时，均以：

> `docs/CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`

作为本轮重构工程合同。
