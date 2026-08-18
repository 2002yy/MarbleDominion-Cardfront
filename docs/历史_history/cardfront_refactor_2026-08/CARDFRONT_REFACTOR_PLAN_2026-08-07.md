# Cardfront 重构路线图（2026-08-07）

状态：**Design Freeze COMPLETE / P0 READY / ANTI-DRIFT GUARDED**

> 本文件只负责阶段顺序和执行入口。玩法语义与硬不变量看 Engineering Spec；每一步怎么从旧实现迁移、允许改什么、禁止改什么、何时切 authority，看 P0 Execution Guardrails。

## 文档职责与执行顺序

1. **`CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`** — 目标语义与 Frozen Invariants，最高权威。
2. **`CARDFRONT_P0_EXECUTION_GUARDRAILS_2026-08-07.md`** — P0 强制迁移程序与防跑偏施工卡；不得覆盖 Engineering Spec。
3. **本文件** — P0/P1/P2 路线图和阶段入口。
4. **`GRILLME_GAME_DESIGN_INTERVIEW.md`** — 历史设计讨论。

`PROJECT_STATUS.md` 与当前代码负责描述“现在已经实现什么”。

> **实现 Agent 不得只读本 Roadmap 就开始编码。** 每个 P0 micro-step 必须同时读取 Engineering Spec + Execution Guardrails + 上一 checkpoint。

---

# 1. 本轮北极星

解决五个根问题：

1. 左下分桥缺乏战略意义。
2. 双方后方据点作用弱、遮挡视线，而且旧实现把它们做成通用战斗/Draft奖励节点。
3. 三选一“回看战场”通过移动容器造成布局漂移。
4. 玩家 / AI 构筑候选底层随机与上下文隔离不足。
5. 卡牌价值被正面战斗力绑架，无法同时做到“强卡真的强、弱卡仍有阶段/控制价值”。

顶层目标：

> **地图空间参与构筑；战线会成长；双方从相同基础出发，通过英雄身份、实际战场行为和独立三选一形成不同军队。**

必须持续保护：

- `Draft -> Aim -> Volley/Execution`；
- Command Point；
- Core Base 最低反攻能力；
- Combat / Mobility / Control 分轴；
- “强卡可以赢战斗，但不能自己完成战争”；
- AI 信息公平；
- 一个规则只有一个 authority。

---

# 2. 旧实现迁移事实

P0 不是从空白开始。

当前旧据点系统 `CardfrontStrongholdSystem/Rules` 会提供：

- Factory：齐射 +3；
- Energy：临时攻击等级 +1；
- Lab：三选一变四选一。

`RoundDirector` 会采样并真正把这些效果应用到 Draft/Volley；因此新 Deployment Support 上线时必须有显式 **Legacy Stronghold Cutover**，禁止“新支点 + 旧奖励”叠加。

当前 `DefaultDuelMap` 已有 5 个 Stronghold region 和两条 corridor metadata。P0 默认复用几何，通过 support topology/connection/deployment 改战略意义，不先大改地图。

当前 `CardfrontGateConnectivitySystem` 是 projectile/bridge passage 系统，不是 Support Graph。禁止两者合并成一个状态机。

当前部署 authority 基础是 `DeploymentRules.gd`；`CardPlaySystem -> CardTargetValidator -> target rule` 已能委托它。新战线规则沿这条链演进，不建第二套 deploy rules。

当前 Draft owner 是 `CardfrontRoundDirector -> CardfrontUpgradeDraftSystem`；Offer independence 是内部 per-side context/RNG 隔离，不是创建两个 DraftDirector。

当前 Draft Preview owner 已确定为 `CardfrontThreeChoicePanel.gd/.tscn`；修 Bug 就在这里，不另做覆盖层。

当前 Level 状态基础是 `CardfrontFactionRunState.applied_upgrade_counts`。

当前 AI decision owner 是 `CardfrontAiCommander`；P0 只收窄 observation，不重写 AI。

---

# 3. P0 — 按 migration checkpoint 执行

每个子步骤完成后必须产生：

`docs/cardfront_refactor_checkpoints/P0-XX_name.md`

没有 checkpoint，不进入下一步骤。

## P0-00 — 旧实现基线冻结

### P0-00A Ownership & Call-Chain Map

只读仓库并画出：

- Stronghold -> RoundDirector -> Draft/Volley/UI；
- target preview -> validator -> commit；
- RoundDirector -> DraftSystem -> ThreeChoicePanel；
- map / route / gate；
- AI input；
- Level state owner。

**不得改变 gameplay。**

### P0-00B Baseline Regression Capture

记录：

- 启动/进入对局；
- Draft -> Aim -> Volley；
- Command Point；
- 旧 Stronghold bonus；
- 3/4-choice；
- Peek Bug 复现；
- 两条 bridge/lane；
- FPS/frame-time/log baseline。

### P0-00C Frozen Delta Ledger

明确 Must-change / Must-preserve。

**Gate：A/B/C 全有证据后才可写 P0-01 gameplay code。**

---

## P0-01 — Support 数据模型，不切 gameplay

### P0-01A SupportDefinition / SupportState

只新增：

- static definition；
- `claim_owner`；
- `operational`；
- capture state/progress；
- `network_connected`；
- snapshot/restore + pure tests。

**不改地图、不改部署、不删旧 bonus、不做 UI。**

### P0-01B Legacy Region -> Support Mapping Adapter

把当前旧 stronghold region 映射成 authored support identity/role。

**不允许运行时靠距离猜 topology，不改桥/河/出生区。**

Gate：数据 deterministic；旧正式对局行为仍未切换。

---

## P0-02 — Capture 语义，小范围接入

### P0-02A Capture Influence Calculator

只实现：

- unit capture weight；
- diminishing returns/cap；
- both sides present -> pause。

不实现奖励、路线、额外 Draft。

### P0-02B Support State Transition Runtime

只实现：

- suppress/disable；
- neutral/capture；
- claim；
- CapturedOffline；
- already-deployed units stay。

### P0-02C One Representative Support

先接 1 个代表性支点跑集成测试。

**单点不稳定时禁止铺满全图。**

---

## P0-03 — Battle-line Graph

### P0-03A Authored Topology

- Core roots；
- support nodes/edges；
- per-side directional deployment metadata。

**不得把 `GateConnectivitySystem` 改造成 Support Graph。**

### P0-03B Pure Connectivity Resolver

只做 BFS/DFS connectivity。

### P0-03C Event-driven Cache

claim/operational/topology 改变时重算；idle/hover 不重算。

Gate：主路、分路、孤立、恢复测试全部 deterministic。

---

## P0-04 — 单一部署 authority

### P0-04A Extend `DeploymentRules.gd`

加入：

- Core fallback zone；
- Online Support directional zone；
- offline/isolated rejection；
-明确 reason codes。

### P0-04B Commit Path

保持：

```text
CardPlaySystem
 -> CardTargetValidator
 -> target rule
 -> DeploymentRules
```

禁止 CardPlaySystem/effect 内复制 graph 判定。

### P0-04C Preview Parity

Preview 只显示 `DeploymentRules` 的结果。

### P0-04D AI Parity

AI 从同一 validator 的合法集合中选。

Gate：相同 owner/context/cell，preview / player commit / AI legality 一致。

---

## P0-05 — 路线战略接入 + 旧据点正式退役

### P0-05A Branch Strategic Integration

把现有指定侧翼/分桥 corridor 接成真实 alternate support path。

其价值只能来自：

- 另一条战线；
- 主路断裂时的 connectivity；
- 转线/迂回。

**禁止分桥发资源、加伤害、送卡。**

### P0-05B Legacy Stronghold Cutover

在新 Support 已能工作后，显式退役：

- Factory 齐射奖励；
- Energy attack bonus；
- Lab 四选一；
- RoundDirector 的旧 stronghold volley/Draft bonus 应用；
- ThreeChoicePanel 的实验室四选一文案；
- RegionInfoPanel 的 80% -> 旧据点能力解释。

可暂留 compatibility shell，但正式 runtime 不得同时保留旧 generic bonus authority。

Gate：全局搜索 + runtime test 证明新支点没有偷偷叠旧奖励。

---

## P0-06 — Support Visuals，只做投影

### P0-06A Presenter/View Model

把 runtime state 映射成：

- Active；
- Offline；
- Capturing；
- Contested；
- CapturedOffline。

UI 不得反写规则。

### P0-06B Low-Occlusion Presentation

地面环/小旗/低信标/发光底座等。

**不做全局 HUD redesign，不常驻全图蜘蛛网。**

---

## P0-07 — Draft Preview Bug 精确修复

### P0-07A Geometry Snapshot

Owner 已确认：

- `CardfrontThreeChoicePanel.gd`
- `CardfrontThreeChoicePanel.tscn`

记录 DraftRoot / ChoiceShell / button geometry、Offer IDs、signal count。

### P0-07B Visibility-State Fix

只实现：

```text
DRAFT_VISIBLE <-> BATTLEFIELD_PREVIEW
```

- 固定按钮；
- 隐藏/显示内容层；
- 不再用 `choice_shell.position` 实现 peek；
- 不 save/restore layout position；
- Draft 仍 paused；
- 不 reroll。

Gate：连续 20 次 + resize 无漂移、Offer 不变、无重复 signal。

---

## P0-08 — Offer Independence，不偷跑路线系统

### P0-08A Per-side RNG Streams

先隔离 RNG，保持旧 eligibility/rarity 行为。

### P0-08B Per-side Offer Context / Containers

`RoundDirector` 继续唯一 orchestration owner。

允许同一基础卡偶然同时出现；共享 immutable definitions。

**P0 不实现 route unlock、reroll、深度卡池。**

Gate：一方 draw 不改变另一方 RNG sequence/current Offer。

---

## P0-09 — Duplicate -> Level API

### P0-09A RunState Level API

基于现有 `applied_upgrade_counts` 提供明确接口。

### P0-09B Resolver/UI Migration

重复选择同 ID -> Level +1；牌堆/eligible IDs 不新增第二份同 ID instance。

**不在这里做卡牌全面重平衡。**

---

## P0-10 — AI 信息边界，不提高 AI 智商

### P0-10A AIObservation DTO

只定义：

- PublicBattleState；
- OwnPrivateState；
- ObservedEnemyHistory（当前对局）。

### P0-10B Builder + Existing Commander Adapter

现有 `CardfrontAiCommander` 消费 observation/context。

**不做 Hard AI、不加搜索深度、不加隐藏数值补偿。**

Gate：secret-leak tests 通过。

---

## P0-11 — 总回归与 Freeze

### P0-11A Automated Contract Suite

Support / Capture / Graph / Deployment parity / legacy bonus retired / Offer independence / Level / Preview / AI fairness。

### P0-11B Manual North-Star Acceptance

重点不是“功能都能跑”，而是：

- 分桥是否真的成为另一条战线；
- 支点是否只承担战线/部署职责；
- 前线断裂是否痛但仍可从 Core 反攻；
- 强卡是否仍需要控制单位完成目标；
- Draft/Aim/Volley 是否没被重构掉。

### P0-11C Performance & Log Diff

与 P0-00B baseline 比较 graph 重算、hover、signal、log、FPS/frame-time。

### P0-11D Go / No-Go

Engineering Spec Go/No-Go + Execution Guardrails North-Star Check 均通过才进入 P1。

---

# 4. P1 — 构筑分化 + 平衡闭环

P0 通过后再做：

- 基础 / 英雄 / 路线三类 Eligible Pool；
- 实际战场行为形成 route signals；
- 粗粒度路线反馈；
- 一局最多 2 条深度路线；
- 先完整实现 2–3 条代表路线；
- 一级路线卡 + 真正强的深度路线卡；
- 每次 Draft 一次免费整体 reroll；
- `reroll -> preview -> return` 回归；
- per-card upgrade tracks；
- Combat / Mobility / Control 卡面；
- 固定平衡测试场景；
- Easy / Normal Decision Strength；
- 成熟 Build 至少保留最后约 1/3 使用窗口。

路线解锁原则：

> **解锁的是“可能性”，不是直接发卡。**

实际行为是主要依据，选卡只做辅助倾向。

---

# 5. P2 — 内容扩展 + 特殊规则 + 高级 AI

- 完整路线和高阶卡目录；
- airborne / infiltration / forward engineer 等明确越线例外；
- 更完整英雄职业差异；
- Hard AI；
- 高级实战数据平衡；
- 桌面/窄屏/移动端整体视觉整理；
- PvP 复用同一 information-fairness 边界。

---

# 6. Agent 开工入口

任何 Agent 开始下一批前必须按顺序：

1. 读 `CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`；
2. 读 `CARDFRONT_P0_EXECUTION_GUARDRAILS_2026-08-07.md`；
3. 读本 Roadmap 中当前 micro-step；
4. 读上一 checkpoint；
5. 声明本步 mutation budget / forbidden diff；
6. 只实现一个 semantic cluster；
7. 测试；
8. 写 checkpoint；
9. checkpoint = GO 后才能下一步。

开工前必须明确：

> **我是在把当前 Cardfront 定向迁移到冻结设计，不是在借这次重构重新设计 Cardfront。**
