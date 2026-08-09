# Cardfront P0 Execution Guardrails — 2026-08-07

状态：**MANDATORY EXECUTION CONTRACT / ANTI-DRIFT**  
适用范围：`CARDFRONT_ENGINEERING_SPEC_2026-08-07.md` 的 P0 实现全过程

> 本文解决的不是“还缺什么玩法”，而是“如何防止实现 Agent 每做一小步都偏一点，最终自创成另一个游戏”。
>
> **最高原则：旧实现是迁移起点，新 Engineering Spec 是目标；P0 是定向迁移，不是 Cardfront 2.0 平行重写。**
>
> 若本文与 `CARDFRONT_ENGINEERING_SPEC_2026-08-07.md` 冲突，以 Engineering Spec 为准。本文可以比 Roadmap 更严格，但不得扩展新玩法。

---

# 1. 当前旧实现事实：先认清“从哪里迁移”

P0 开工前必须承认以下现状，禁止把旧系统想象成空白工程。

## 1.1 据点旧语义不是部署支点

当前：

- `scripts/cardfront/strongholds/CardfrontStrongholdRules.gd`
- `scripts/cardfront/strongholds/CardfrontStrongholdSystem.gd`

旧 Stronghold 在区域控制达到阈值后提供：

- Factory：下一轮齐射数量奖励；
- Energy：下一轮临时攻击等级奖励；
- Lab：Draft 从三选一变四选一。

`CardfrontRoundDirector` 每轮 Draft 会 sample stronghold bonus，并在构建 volley 时应用；Draft 数量也读取该 bonus。

**新设计明确不保留这些“据点 = 通用数值奖励节点”的核心语义。**

因此 P0 必须存在显式的 **Legacy Stronghold Cutover / 旧据点语义退役**，不能只把新 Deployment Support 叠在旧 Stronghold 上。

## 1.2 当前地图已经有布局与双路线语义

`DefaultDuelMap.gd` 当前已有：

- 5 个 Stronghold region；
- `strategy_profile.identity = "two_equal_routes"`；
- 两条既有 route corridor / lane metadata。

新设计要求主路与侧翼/备用线路形成不同战略作用，但 **P0 默认复用现有地图几何作为迁移基线**。

禁止在没有 Design Amendment 的情况下：

- 大幅移动河流/桥；
- 新增大量桥梁；
- 彻底重画地图；
- 为了“让分路更明显”顺手改变核心炮台、出生区、目标位置。

P0 优先通过 **Support topology + connectivity + directional deployment** 改变战略意义，而不是先改大地图。

## 1.3 GateConnectivity 不是新战线图

现有：

- `scripts/cardfront/gates/CardfrontGateConnectivitySystem.gd`

它当前负责：

- 河流 crossing；
- lane gate state；
- projectile route filtering；
- round-sampled gate snapshot。

**它不是 Deployment Support connectivity authority。**

P0 可以复用其已有 lane/corridor 空间信息作为输入参考，但禁止把 Support Graph 硬塞进 GateConnectivity，禁止让 projectile gate state 与 support online state 变成一个共享状态机。

二者的职责边界：

```text
GateConnectivity
= projectile / bridge passage rule

SupportGraph
= deployment-line connectivity rule
```

## 1.4 部署合法性已有 authority chain

现有基础层：

- `scripts/cardfront/deployment/DeploymentRules.gd`

战斗卡 commit 路径：

```text
CardPlaySystem
 -> CardTargetValidator
 -> target rule
 -> DeploymentRules
```

例如 `OwnedBorderTargetRule.gd` 已委托 `DeploymentRules.is_owned_border(...)`。

Preview 当前也直接使用 `DeploymentRules` 计算合法格。

因此新战线部署规则的方向是：

> **扩展 DeploymentRules 这一底层 authority，并让 target rule / preview / AI 都委托它。**

禁止新建另一个并行的 `FrontlineDeploymentRules` 后让 UI/AI/commit 各挑一套。

## 1.5 Draft 已经有统一编排器

当前：

```text
CardfrontRoundDirector
 -> CardfrontUpgradeDraftSystem
```

`RoundDirector._open_draft()` 已经分别给 Player 和 AI 调用 `draw_offer()`。

问题是：

- DraftSystem 仍只有一个 RNG；
- 旧 eligibility/rarity 模型共享；
- 没有新的 per-side eligible context / route context。

所以 P0 的 Offer Independence 是 **内部状态隔离**，不是另起第二个 PlayerDraftDirector / AiDraftDirector。

## 1.6 Draft Preview Bug 的真实 owner 已定位

真实 UI owner：

- `scenes/ui/cardfront/CardfrontThreeChoicePanel.tscn`
- `scripts/cardfront/ui/CardfrontThreeChoicePanel.gd`

当前 `_toggle_peek()` 会修改 `choice_shell.position`，并在进入/退出时保存/恢复位置；`PeekButton` 还是 `ChoiceShell` 的 child。

这正是“回看后布局位置被永久改变/按钮跟着内容走”的直接风险源。

P0 修复不得再搜索另一个 UI owner，也不得重做整套 Draft UI；就在该 owner 内改成 visibility/state toggle。

## 1.7 Level 已经有状态落点

当前 `CardfrontFactionRunState` 已有：

- `applied_upgrade_counts`；
- `record_upgrade()`；
- snapshot / restore。

P0 只把它升级成明确的 Level API/语义。

禁止另建第二份 `card_levels` 永久状态，除非先完成迁移并删除旧 authority；P0 默认不这样做。

## 1.8 AI 已经有决策 owner

当前：

- `CardfrontAiCommander.gd`
- `CardfrontAiUpgradePolicy.gd`

P0 只收窄输入权限，增加 `AIObservation` 边界。

禁止借此重写 AI、改 archetype、增加搜索深度、做 Hard AI、给 AI 隐藏补偿。

---

# 2. Anti-Drift Constitution：实现 Agent 宪法

任何 P0 子步骤都必须遵守。

## 2.1 每次编码前必须回答 10 个问题

Agent 必须在自己的执行记录中明确：

1. 本步骤只解决哪一个问题？
2. 对应 Engineering Spec 哪一条 frozen invariant？
3. 当前旧 authority 是哪个文件/类/函数？
4. 完成后 authority 是谁？
5. 本步骤允许修改哪些文件/目录？
6. 明确禁止修改什么？
7. 哪些旧行为必须保持？
8. 本步骤**不解决**什么？
9. 哪些测试证明没有跑偏？
10. 哪份 checkpoint 证明可以进入下一步？

如果第 3/4 项答不出来：**不得编码。**

## 2.2 一个 micro-step 只允许一个 semantic cluster

允许：

- 新增 SupportState DTO + tests；
- 新增纯 graph resolver + tests；
- 修 Draft Preview visibility bug + regression。

禁止把以下内容塞进同一个“小步”：

- Support model + UI 美术 + 新卡 + AI；
- Offer RNG 隔离 + 路线系统 + reroll；
- Level API + 大规模卡牌重平衡；
- AIObservation + Hard AI；
- 分桥接图 + 地图大改。

## 2.3 默认是“演进现有 owner”，不是“新增 owner”

新增 class/module 前必须证明至少一项：

- 现有 owner 的职责会被明确污染；
- 新对象是纯 DTO / pure calculator / presenter；
- 新对象承担 Spec 中明确的新领域边界。

“以后可能有用”“更优雅”“方便我写”不是理由。

## 2.4 禁止双 authority 长期共存

迁移时允许短暂：

```text
old authority -> adapter -> new implementation
```

但必须有：

```text
parity/contract test -> one call path cutover -> verification -> deprecate old branch
```

禁止：

```text
UI 用新规则
AI 用旧规则
commit 再用第三套规则
```

也禁止“先都留着，以后再统一”。

## 2.5 未冻结参数 ≠ 可以自由设计玩法

可调参数（Yellow）：

- capture 时间/递减曲线；
- support zone 尺寸；
- AI decision window 秒数；
- bounded resample 次数。

要求：集中在 tuning/config/data，带 TODO 和测试。

不可自由创造（Red）：

- 新奖励；
- 新资源；
- 新路线类型；
- 新据点被动；
- 新 Draft 次数来源；
- 新卡牌来源；
- 新 AI 信息权限；
- 新部署例外；
- 新胜利条件。

遇到 Red：**停止编码，提交 Amendment 提案，不得自己决定。**

## 2.6 禁止 opportunistic cleanup

P0 子步骤中禁止顺手：

- 全局重命名；
- 大范围目录搬迁；
- 与当前步骤无关的 controller 拆分；
- UI 风格统一；
- 架构“现代化”；
- 代码格式全库重写；
- 删除“看起来没用”的旧接口。

除非它阻塞当前步骤，并在 checkpoint 中写明必要性。

---

# 3. 每个 checkpoint 都要做 North-Star Drift Check

每完成一个 micro-step，都必须逐条回答 Yes/No：

1. 地图空间是否仍通过 **战线/支点** 参与战略，而不是又变成通用资源奖励？
2. 战线是否只通过 **connected supports** 扩展？
3. Core Base 是否仍保留最低反攻部署能力？
4. 是否仍满足“强卡能赢战斗，但不能自己完成战争”？
5. Combat / Mobility / Control 是否仍是分开的价值轴？
6. 双方是否仍从相同基础池出发，并通过英雄/行为/独立 Offer 分化？
7. AI 是否仍只看公平信息？
8. `Draft -> Aim -> Volley/Execution` 是否仍存在？
9. Command Point 是否仍存在？
10. 同一规则是否仍只有一个 authority？
11. 是否无 P1/P2 功能被偷跑进 P0？
12. 是否没有为了方便新增未冻结玩法？

任一核心项为 No：**当前步骤不算完成。**

---

# 4. Authority / Migration Matrix

| 领域 | 当前 authority | P0 目标 | Authority transfer |
|---|---|---|---|
| Stronghold 奖励 | `CardfrontStrongholdSystem` + `StrongholdRules` | Deployment Support runtime | **要转移并显式退役旧奖励语义** |
| 地图 region/layout | `RegionMap` + map definitions | 继续保留 | 不转移；只添加 support topology metadata/映射 |
| projectile gate | `CardfrontGateConnectivitySystem` | 继续保留 | 不转移；不承担 support graph |
| deployment legality | `DeploymentRules` | 扩展为 frontline-aware authority | 不转移，只扩展 |
| card target facade | `CardTargetValidator` / target rules | 继续保留 facade | 不转移；委托 DeploymentRules |
| Draft orchestration | `CardfrontRoundDirector` | 继续保留 | 不转移 |
| Offer generation | `CardfrontUpgradeDraftSystem` | per-side context/RNG | 内部演进，不建第二 pipeline |
| Upgrade state | `CardfrontFactionRunState` | explicit Level API | 不转移 |
| Draft UI | `CardfrontThreeChoicePanel` | visibility-state preview | 不转移 |
| AI choice | `CardfrontAiCommander` | 继续为 decision owner | 输入通过 Observation 收窄 |

---

# 5. P0 Detailed Migration Route：逐步施工卡

每个步骤都必须有 checkpoint。建议目录：

`docs/cardfront_refactor_checkpoints/`

## P0-00A — Repository Ownership & Call-Chain Snapshot

### 方向
只记录旧实现，不改变行为。

### 必须产出
- Stronghold sample -> Draft/Volley/UI 的完整调用链；
- deployment preview -> validation -> commit 的调用链；
- Draft RoundDirector -> DraftSystem -> ThreeChoicePanel；
- AI Commander 输入来源；
- map/route/gate owner；
- 当前可运行的测试/手测入口。

### Allowed diff
- docs；
- 必要的只读 debug/test helper。

### Forbidden diff
- gameplay code 行为变化；
- UI 改动；
- balance 改动。

### Exit evidence
`P0-00A_ownership_map.md`

---

## P0-00B — Baseline Regression Capture

### 方向
把“旧版本现在会什么”变成可比较证据。

### 人工验收观察清单
- 启动/进入对局；
- Draft -> Aim -> Volley；
- Command Point；
- 当前 Stronghold bonus 行为；
- 当前 3/4-choice 行为；
- 当前 Peek Bug 的可复现步骤；
- 当前两条 bridge/lane 的表现；
- 当前基础 FPS/日志噪音/异常。

清单用于人工判断当前基线是否足以继续施工，不要求在每个 micro-step 前逐项录像。未覆盖项写入 checkpoint follow-up；只要人工接受当前可玩基线，且不存在启动/解析失败、数据损坏或当前施工 authority 不明，即可继续 P0-00C。完整回归集中在 batch / milestone 边界，避免未完成阶段反复全量检查。

### 重要
这里记录旧 Stronghold bonus 不是为了以后保留，而是为了确认 cutover 时“旧语义确实被有意识移除”，不是误删。

### Exit evidence
`P0-00B_baseline.md`

---

## P0-00C — Frozen Delta Ledger

### 方向
列出“本轮必须改变”和“绝不改变”。

### Must-change
- stronghold generic bonuses -> deployment support semantics；
- support capture/connectivity；
- frontline-aware deployment；
- branch strategic role；
- peek bug；
- Offer independence；
- Duplicate -> Level API；
- AIObservation boundary。

### Must-preserve
- Draft/Aim/Volley；
- Command Point；
- core objective / overall match identity；
- existing card/effect systems unless directly touched；
- gate projectile filtering unless support work proves a specific bug。

### Exit evidence
`P0-00C_delta_ledger.md`

**没有 P0-00A/B/C，不得进入 P0-01。**

---

## P0-01A — SupportDefinition / SupportState Data Only

### Original intent
把“部署支点是什么”建立成独立领域语义。

### Allowed
- 新 support DTO/data files；
- claim_owner / operational / capture / connected 字段；
- snapshot/restore；
- pure tests。

### Forbidden
- 改地图；
- 改部署；
- 改旧 Stronghold bonus；
- 加 UI；
- 加新卡；
- 加资源收益。

### This step is NOT
“把据点真正接进游戏”。

### Exit
DTO tests 全通过；旧对局行为 byte-for-behavior equivalent（除新增无调用代码）。

---

## P0-01B — Legacy Stronghold -> Support Mapping Adapter

### 方向
只解决旧 map region 如何映射到新的 support identity。

### 原则
- 优先复用当前 Stronghold region 的位置/区域作为迁移锚点；
- 不在这里改变河流/桥/出生区；
- 中央与双方侧点如何分类必须写成 authored mapping，不允许运行时按“离谁近”猜角色。

### Forbidden
- 同时启用 support deployment；
- 删除 old Stronghold bonus；
- 改 route geometry。

### Exit
每个旧 stronghold region -> support/static role 映射可打印、可测试、确定性一致。

---

## P0-02A — Capture Influence Pure Calculator

### 方向
只实现占领贡献数学，不触碰 ownership side effect。

### Allowed
- 普通/轻型/重型/不可占领权重输入；
- diminishing returns / cap；
- contested 判定。

### Forbidden
- 新职业；
- 工兵专属占领税；
- 击杀奖励；
- 占点送 Draft；
- 复杂 combo 条件。

### Exit
人数增加不线性无限加速；双方同时存在 -> contested/pause。

---

## P0-02B — Support State Transition Runtime

### 方向
实现：压制 -> 不可工作/中立阶段 -> 接管；claim 与 connected 分离。

### Allowed
- state transition/controller；
- event emission；
- tests。

### Forbidden
- capture 完成立即 spawn-enabled；
- support offline 删除场上单位；
- passive bonus。

### Exit
CapturedOffline 可稳定存在；claim 恢复/断线不串改。

---

## P0-02C — One Representative Support Integration

### 方向
只接 **一个代表性 support** 验证 runtime，不一次切全图。

### Allowed
- 单点 runtime binding；
- debug state view；
- integration tests。

### Forbidden
- 全地图同时切换；
- 旧 Stronghold bonus 退役；
- 新部署区域。

### Stop condition
单点状态模型若仍不稳定，禁止“先铺满再修”。

---

## P0-03A — Authored Support Topology

### 方向
建立 Core -> Support edges 的静态图。

### Allowed
- map-definition support metadata；
- node/edge IDs；
- per-side deterministic deploy direction metadata。

### Forbidden
- 自动从距离推断所有 edges；
- 用 `GateConnectivitySystem` 代替 graph；
- 改 projectile gate semantics；
- 大改桥几何。

### Exit
相同 map definition 每次生成完全相同图。

---

## P0-03B — Pure Connectivity Resolver

### 方向
只回答：某方从 Core 能到哪些 claimed+operational nodes。

### Allowed
- BFS/DFS pure resolver；
- deterministic traversal；
- tests。

### Forbidden
- 每帧扫描；
- deployment placement；
- capture math；
- UI network lines。

### Exit
主路/分路/孤立/恢复四类测试通过。

---

## P0-03C — Event-driven Cache / Invalidation

### 方向
只有 relevant state change 才重算图。

### Triggers
- claim changed；
- operational changed；
- topology changed（通常仅 setup/map change）。

### Forbidden
- `_process()` 每帧 BFS；
- hover 触发全图重算。

### Exit
性能日志能证明 idle/hover 不持续重算。

---

## P0-04A — Extend DeploymentRules, Do Not Replace It

### 方向
让现有 `DeploymentRules` 能表达 Core fallback + Online Support directional zone。

### Allowed
- 新 rule type/query fields/reason codes；
- support graph/context 输入；
- deterministic evaluation。

### Forbidden
- 新第二套 deploy authority；
- UI-specific special case；
- AI-specific special case；
- 360° support spawn ring 作为普通规则。

### Exit
纯 rules tests 通过。

---

## P0-04B — Commit Path Through Existing Validator Facade

### 方向
保留当前 facade：

```text
CardPlaySystem
 -> CardTargetValidator
 -> target rule
 -> DeploymentRules
```

需要新 frontline target type 时，让 target rule 委托 `DeploymentRules.evaluate()`。

### Forbidden
- CardPlaySystem 内复制 graph 判定；
- effect resolver 内另写 deploy legality。

### Exit
非法 frontline target 在付费/consume 之前失败；合法规则与 pure validator 一致。

---

## P0-04C — Preview Uses Same Authority

### 方向
Preview 只负责展示 authority 结果。

### Forbidden
- preview 根据“看起来合理”生成额外绿格；
- preview 与 commit 使用不同阈值。

### Exit
抽样/全格 parity：Preview valid == Commit valid。

---

## P0-04D — AI Deployment Uses Same Authority

### 方向
AI 只从合法候选中选。

### Forbidden
- AI 在合法性上获得例外；
- AI 直接 spawn 绕过 Card/Deployment contract。

### Exit
同 owner/context/cell 输入，Player validator 与 AI validator 结果一致。

---

## P0-05A — Branch Strategic Integration

### 方向
把现有两条 corridor 中的指定侧翼/分桥真正接成 alternate support path。

### 关键限制
P0 的“分桥有意义”来自：

- 连接另一条战线；
- 主路断裂时可维持/恢复部分前沿网络；
- 提供转线/迂回价值。

### Forbidden
- 分桥额外发资源；
- 分桥独享伤害加成；
- 分桥自动送卡；
- 为了区分路线大幅重画地图。

### Exit
至少通过：主路断 -> branch 仍连；branch 断 -> main 不受错误影响；两路同时断 -> 前线离线但 Core 可反攻。

---

## P0-05B — Legacy Stronghold Cutover

### 这是必须存在的显式步骤

目标：当 Deployment Support 已经能承担新战略职责后，**一次性切断旧 Stronghold generic bonus authority**。

### 必须移除/改写的旧语义入口
- `CardfrontStrongholdSystem.sample_bonuses()` 对新支点的通用战斗/Draft奖励；
- `RoundDirector._draft_choice_count()` 的 Lab 四选一来源；
- `RoundDirector` 对 volley 的旧 stronghold shot/attack bonus 应用；
- `CardfrontThreeChoicePanel` 中“实验室加成：四选一”等旧文案；
- `CardfrontRegionInfoPanel` 中“80% 激活 -> 据点能力”的旧解释。

### 迁移原则
- 可保留旧 class/file 作为 compatibility shell 一小段时间；
- 但 runtime authoritative output 必须只剩新 Support semantics；
- 不允许“旧 bonus 暂时也留着，更丰富”。

### Forbidden
- 把旧 +3 齐射/+1 attack/4-choice 改名后继续当 support reward；
- 用新 support 再补另一套 passive bonus。

### Exit
全局搜索与 runtime test 能证明旧 generic bonus 不再影响正式 Cardfront 对局。

---

## P0-06A — Support Presenter / View Model

### 方向
视觉只是 runtime state 的投影。

### Allowed
- Active / Offline / Capturing / Contested / CapturedOffline view state；
- 低遮挡 presentation data。

### Forbidden
- UI 根据百分比自己决定 ownership；
- visual node 反写 rule state；
- 加战斗 bonus。

---

## P0-06B — Low-Occlusion Visual Replacement

### 方向
地面环、小旗、低信标、发光底座等。

### Forbidden
- 高大建筑遮挡；
- 常驻全图蜘蛛网；
- 顺手做全局 HUD redesign。

### Exit
人工验收：信息可辨认、主体战斗无遮挡。

---

## P0-07A — Freeze Existing Draft Geometry Snapshot

### Owner 已确定
`CardfrontThreeChoicePanel.gd/.tscn`

### 必须记录
- `DraftRoot` rect；
- `ChoiceShell` rect；
- button rect；
- anchors/offsets；
- card IDs；
- signal connection count。

### Forbidden
- 先改 layout 再测 bug。

---

## P0-07B — Preview Visibility State Fix Only

### 方向
替换当前“移动 ChoiceShell”的做法。

```text
DRAFT_VISIBLE
 <->
BATTLEFIELD_PREVIEW
```

### Allowed
- 隐藏/显示 Draft 内容层；
- PeekButton 放在不会随内容一起消失/移动的固定 parent；
- 改按钮文字。

### Forbidden
- `choice_shell.position = ...` 用于 peek；
- save/restore layout position；
- reparent 整个 Draft root；
- reroll；
- 重做卡面；
- 恢复 battle simulation。

### Exit
20 次切换 + resize：geometry 不漂、Offer 不变、无重复 signal。

---

## P0-08A — Per-side RNG Streams First

### 方向
先隔离随机状态，保持旧 eligibility/rarity 行为不变。

### Allowed
- Player/AI RNG state；
- deterministic test seed APIs。

### Forbidden
- route cards；
- reroll；
- dominance/diversity 大改同时混入；
- 改 rarity 平衡。

### Exit
一方 draw 不改变另一方之后的随机序列。

---

## P0-08B — Per-side Offer Context / Containers

### 方向
`RoundDirector` 仍是 orchestration owner；DraftSystem 接受 side/context。

### Forbidden
- 两个 RoundDirector；
- PlayerDraftSystem/AiDraftSystem 两套逻辑；
- P1 route unlock 偷跑。

### Exit
Offer objects 独立；共享 immutable card definition 允许；偶然同卡允许。

---

## P0-09A — Level API Around Existing RunState

### 方向
把 `applied_upgrade_counts` 包装成明确 API。

建议：

```text
get_upgrade_level(id)
level_up(id)
```

### Forbidden
- 新建并行 progression store；
- card rebalance；
- route upgrade tree；
- duplicate card instance inflation。

---

## P0-09B — Resolver/UI Migrate to Level API

### Exit
重复选择同 ID：Level +1；deck/eligible IDs 不因为“多一份副本”增长。

---

## P0-10A — AIObservation DTO Schema

### 方向
先定义信息权限，不提高 AI 智商。

只分：

- PublicBattleState；
- OwnPrivateState；
- ObservedEnemyHistory（当前对局）。

### Forbidden
- opponent Offer；
- exact hidden route score；
- future RNG/Offer；
- full GameState/scene-tree escape hatch。

---

## P0-10B — Builder + Commander Adapter

### 方向
让现有 `CardfrontAiCommander` 消费 observation/context。

### Forbidden
- 新 AI planner；
- Hard difficulty；
- stat/resource cheats；
- 跨局玩家画像。

### Exit
secret-leak tests 全通过，现有 AI 基础行为不因输入收窄直接失效。

---

## P0-11A — Automated Contract Suite

必须覆盖：

- Support state；
- capture；
- graph；
- deployment parity；
- legacy stronghold bonuses retired；
- Offer independence；
- Level no inflation；
- Preview geometry；
- AI secret leakage。

---

## P0-11B — Manual North-Star Acceptance

人工只回答核心体验，不因为“功能都能运行”就放行：

- 分桥是否真有第二条战线意义？
- 支点失守是否切断增援而非毁掉已有军队？
- Core 是否能反攻？
- 支点是否不再是数值奖励按钮？
- 强攻城单位是否仍需要控制单位完成占领？
- Draft/Aim/Volley 是否仍是原来的主循环？

---

## P0-11C — Performance / Log Diff

比较 P0-00B baseline：

- idle graph recomputation；
- hover recomputation；
- signal duplicates；
- log volume；
- startup/runtime regression；
- visible FPS/frame-time regression if baseline available。

---

## P0-11D — Go / No-Go Freeze

只有 Engineering Spec Go/No-Go + 本文 North-Star Drift Check 均通过才进入 P1。

P0 不通过时：

> 修当前 authority / migration，禁止靠“再加几张卡、再加一个奖励、再加一层 UI”掩盖结构问题。

---

# 6. Checkpoint 文件模板

每个 micro-step 完成后创建：

`docs/cardfront_refactor_checkpoints/P0-XX_name.md`

必须包含：

```text
Step:
Source commit:
Target commit:
Engineering Spec sections:
Original intent:
Old authority:
Target authority:
Files changed:
Allowed mutation surface:
Unexpected files touched:
Behavioral delta:
What this step explicitly did NOT solve:
Old behaviors preserved:
Authority cutover status:
Automated tests:
Manual checks:
Performance/log result:
North-Star Drift Check (12 items):
Known issues:
Red/Yellow decisions encountered:
Prerequisites for next step:
GO / NO-GO:
```

**没有 checkpoint 的代码提交不能作为下一步骤的起点。**

---

# 7. Mutation Budget

Agent 开工前必须声明本步骤的 mutation budget，例如：

```text
Allowed:
- scripts/cardfront/deployment/**
- scripts/cardfront/targets/target_rules/Frontline*.gd
- relevant tests

Read-only unless amendment:
- scripts/cardfront/run/**
- scripts/cardfront/ai/**
- scripts/cardfront/maps/**
```

如果实现中发现必须越界：

1. 停止；
2. 写明为什么当前 owner 无法完成；
3. 扩展 checkpoint / amendment；
4. 再改。

禁止“已经改到这里了就顺手一起提交”。

---

# 8. Explicit Stage Locks

## P0 不得偷跑 P1

- 不实现 route unlock；
- 不实现完整 hero profession pool；
- 不实现 reroll；
- 不实现深度路线；
- 不实现完整 Combat/Mobility/Control 卡面重做；
- 不做完整新卡目录。

只允许为 P1 留接口/data seam/TODO。

## P0 不得偷跑 P2

- 不做 airborne / infiltration / forward engineer 越线例外；
- 不做 Hard AI；
- 不做 PvP netcode；
- 不做全地图大改；
- 不做全局 UI redesign。

---

# 9. Coding-Agent Stop Rules

出现以下任一情况，Agent 必须停在当前步骤，不得自行“合理推断”：

1. Spec 没定义某个 gameplay semantic；
2. 新旧文档冲突；
3. 需要新增一种奖励/资源/路线/部署例外；
4. 需要让 AI 读取新的 private 信息；
5. 需要改变 Draft/Aim/Volley/Command Point；
6. 需要大改地图几何；
7. 需要同时保留两个 gameplay authority 才能“先跑起来”；
8. 当前 step 的 acceptance 无法满足；
9. 测试显示旧非目标系统回归；
10. 为了实现一步必须大量修改不相关目录。

正确行为是生成：

```text
BLOCKED / AMENDMENT REQUIRED
- blocking fact
- current code evidence
- affected frozen invariant
- smallest proposed change
- alternatives
- regression risk
```

不是继续自创。

---

# 10. Final Anti-Drift Rule

每个实现 Agent 开始一批任务前，必须先复述一句：

> **“我是在把当前 Cardfront 定向迁移到冻结设计，不是在借这次重构重新设计 Cardfront。”**

每个 checkpoint 结束再问一句：

> **“如果只看这一批 diff，它是否让游戏更接近冻结目标，而不是仅仅让局部代码看起来更完整？”**

如果答案不能明确为 Yes，本批不得进入下一步。
