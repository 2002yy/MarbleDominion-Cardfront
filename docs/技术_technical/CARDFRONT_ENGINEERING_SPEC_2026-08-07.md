# Cardfront Design Freeze & Engineering Spec — 2026-08-07

状态：**FROZEN FOR P0**  
范围：2026-08-07 战场空间、部署支点、构筑成长、三选一、卡牌平衡、AI 公平性与 Draft 回看战场重构  

> 本文把 2026-08-07 GrillMe 已确认设计下降为工程合同。它不是新的玩法提案，也不是重新开启 GrillMe。
>
> **在本文范围内，权威顺序为：本 Engineering Spec > `CARDFRONT_REFACTOR_PLAN_2026-08-07.md` > `GRILLME_GAME_DESIGN_INTERVIEW.md` 历史记录。**
>
> `PROJECT_STATUS.md` 继续负责描述仓库当前已经实现了什么；本文负责规定这次重构接下来必须实现成什么。若二者描述的是“当前事实”，以 `PROJECT_STATUS.md`/代码为准；若描述的是“2026-08-07 重构目标与约束”，以本文为准。

---

# 0. Freeze Boundary：冻结边界

## 0.1 本轮顶层目标

本轮不是给旧据点换皮，也不是单纯调卡牌数值，而是建立以下闭环：

> **地图空间参与构筑；战线会成长；双方从相同基础出发，但通过英雄身份、实际战场行为和独立三选一形成不同军队。**

需要解决的根问题：

1. 左下分桥缺乏战略意义。
2. 双方后方据点没有实际用途且遮挡战场。
3. 三选一“回看战场”改变布局并产生永久位置异常。
4. 玩家与 AI 候选过度绑定，构筑无法自然分化。
5. 卡牌强弱缺乏结构：强卡不够强，弱卡又容易彻底失去价值。

## 0.2 本轮必须保留的既有系统

除非后续另开 Design Amendment，P0 不得顺手推翻以下既有设计：

- 核心体验仍是：**Roguelite 构筑深度 × 战场空间控制 × 紧张对抗**。
- 对局体验目标仍约 **8–12 分钟**；本轮不主动改成长局或超短局。
- 最终方向仍是 PvP，PvAI 是训练/过渡与当前主要验证环境。
- 高层循环仍保留 `Draft -> Aim -> Volley / Execution` 的职责分层：
  - Draft：你有什么；
  - Aim：你怎么用；
  - Volley / Execution：战术执行与应变。
- 现有 Command Point / 指挥点系统未被本轮推翻。
- 现有齐射、炮台、领土、卡牌运行时等系统默认继续存在；新战线规则应接入而不是平行重做整个游戏。

## 0.3 P0 明确不做

P0 不得因为“顺手”扩大到以下内容：

- 全量阵营/路线/卡牌内容；
- 完整困难 AI；
- PvP 网络同步；
- 大规模地图重制；
- 空降、渗透、前沿工兵等特殊越线部署卡；
- 精细最终数值平衡；
- 击杀/占点奖励额外 Draft 的追赶或雪球系统；
- 通过 AI 隐藏加伤、加血、加资源、费用折扣制造难度；
- 全局 UI/美术大改版；
- 取消 Aim、Volley 或 Command Point。

---

# 1. Current Repository Integration Map：现有代码接入图

本次重构**优先演进现有边界，不建立第二套平行系统**。

## 1.1 Draft 编排

现有：

- `scripts/cardfront/run/CardfrontRoundDirector.gd`
- `scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd`
- `scripts/cardfront/run/CardfrontFactionRunState.gd`

已确认当前 `CardfrontRoundDirector` 是 Draft 编排中心，并已经分别为 Player / AI 调用 `draw_offer()`；问题不是“完全只有一份数组”，而是双方仍共享同一个 DraftSystem、同一 RNG/稀有度权重模型和旧卡池语义。

**冻结集成规则：**

- 保留 `CardfrontRoundDirector` 作为阶段/Offer 编排中心。
- 演进 `CardfrontUpgradeDraftSystem`，使其接受明确的 side/context，并支持独立 Eligible Pool / Offer state / random stream。
- 不新增另一个与 `CardfrontRoundDirector` 平行的 Draft 总控。
- `CardfrontFactionRunState.applied_upgrade_counts` 可作为已有升级计数基础，但最终 API 应表达 `card_level` / `upgrade_level` 语义，不允许业务代码到处自行解释 raw count。

## 1.2 部署规则

现有：

- `scripts/cardfront/deployment/DeploymentRules.gd`
- `scripts/cardfront/deployment/DeploymentResult.gd`
- `scripts/cardfront/deployment/DropZoneGeometry.gd`
- `scripts/cardfront/deployment/DropZoneVisualizer.gd`

`DeploymentRules.gd` 已经承担统一合法性判断的一部分。

**冻结集成规则：**

> **新战线/支点合法部署必须扩展现有 DeploymentRules 层，禁止玩家 UI、AI、卡牌效果各写一套“能不能放”的判断。**

## 1.3 AI

现有：

- `scripts/cardfront/ai/CardfrontAiCommander.gd`
- `scripts/cardfront/run/CardfrontAiUpgradePolicy.gd`

现有 AI Commander 已有 archetype 和对 Offer 的评分能力。

**冻结集成规则：**

- 保留 `CardfrontAiCommander` 作为决策器之一。
- P0 在它前面加入最小 `AIObservationBuilder` / observation DTO 边界。
- 不再让未来 AI 直接拿“整个 GameState / 任意运行时对象”当便利入口。
- P1/P2 提升 Decision Strength，不另写一套作弊 AI。

## 1.4 UI

现有 `scripts/cardfront/ui/CardfrontCardSelectionController.gd` 负责战斗中卡牌目标选择，但**不能仅凭名字假设它就是三选一 Draft Overlay 的拥有者**。

实现 P0 Draft Preview Bug 前必须先定位：

- 谁订阅 `draft_opened`；
- 谁创建/拥有三选一 Root；
- 谁当前实现“回看战场”；
- 按钮是否与 Draft 内容处于同一容器。

冻结规则：**修现有 Draft UI 拥有者，不建立第二个覆盖层来绕过 Bug。**

---

# 2. Domain Terminology & Global Invariants：术语与全局不变量

## 2.1 核心术语

- **Core Base / 核心基地**：某一方战线图的永久根节点与最低部署源。
- **Deployment Support / 部署支点**：战线网络中的部署锚点，不是普通资源点。
- **Claim / 所有权**：谁完成了该支点的接管。
- **Operational / 可工作**：支点是否处于可工作的非压制状态。
- **Connected / 联网**：该支点能否沿地图预定义边连接到己方 Core Base。
- **Online / 在线**：`claimed by side && operational && connected`。
- **Capture / 接管过程**：把中立/敌方可接管支点转换为己方 Claim 的过程。
- **Deployment Zone / 部署区**：某个 Online 节点向己方侧/侧后方提供的合法出生区域。
- **Eligible Pool**：某一方当前有资格出现在三选一中的定义集合。
- **Offer**：本轮实际抽出的候选集合。

## 2.2 不变量

以下均为 P0 硬不变量：

1. **完成 Capture 不等于立刻获得部署能力。**
2. 支点被压制/离线时，已经存在的单位不得被删除或传送回家。
3. 失去前线支点不能让玩家完全失去出兵能力；Core Base 永远保留最低部署区。
4. 敌后孤立支点即使 Claim 已完成，只要未连回己方图，仍不得部署。
5. 普通支点不是 360° 传送门。
6. 普通单位不能越过当前合法战线部署。
7. 玩家与 AI 的 Offer 对象、随机状态和私有候选不得共用。
8. AI 不能读取玩家的私有 Offer、隐藏路线精确值、未来 RNG、未来 Offer、隐藏战术指令。
9. Draft Preview 只切可见状态；不得改变 Draft 根布局几何。
10. 卡牌重复选择只提升 Level；不向本局牌堆继续加入同卡独立副本。
11. 战斗/机动/控制不得被压缩成一个最终“综合战力分”。

---

# 3. Deployment Support Runtime Model：部署支点运行时模型

## 3.1 禁止单枚举包办所有语义

禁止把支点仅实现为：

```text
ACTIVE -> NEUTRAL -> CAPTURED -> ACTIVE
```

单枚举会把所有权、可工作状态、占领进度和网络连接混在一起，极易导致“占完马上开刷兵”。

## 3.2 建议运行时数据模型

实际类名可以按仓库风格调整，但语义必须等价：

```gdscript
# Proposed: DeploymentSupportState / DeploymentSupportRuntime
var support_id: String
var claim_owner: int          # PLAYER / AI / NEUTRAL
var operational: bool         # false = suppressed/disabled
var capture_side: int         # side currently progressing, or NEUTRAL
var capture_progress: float   # normalized or configured units
var network_connected: bool   # derived for claim_owner
var contested: bool           # may be derived from occupants
```

地图静态定义建议单独存在：

```gdscript
# Proposed: DeploymentSupportDefinition
var support_id: String
var world_or_grid_anchor
var authored_neighbors: Array[String]
var is_core: bool
var player_deploy_direction
var ai_deploy_direction
var deployment_shape_id: String
```

静态拓扑与动态状态不得混在一个“随时被改的 Dictionary”里。

## 3.3 派生 UI 状态

UI/Visualizer 可以派生：

- `ACTIVE`：己方 Claim + operational + connected。
- `DISABLED / NEUTRAL`：无有效工作所有者或被压制。
- `CAPTURING`：存在 capture_side 且 progress > 0。
- `CAPTURED_OFFLINE`：Claim 已完成，但 graph 尚未 connected。
- `CONTESTED`：双方同时进入接管范围，接管暂停。

这些是**显示状态**，不是唯一真相源。

## 3.4 断线与重连

- 已 Claim 支点如果因上游断裂而失去连接：保留 Claim，不要求重新占领；`network_connected=false`，因此 Offline / 不可部署。
- 上游恢复后重新 BFS/DFS；若可达，自动 `network_connected=true`，恢复 Online。
- Core Base 对己方永远视为 connected；除非未来另开玩法提案，否则 P0 不允许把 Core Base 变成可断网节点。

---

# 4. Capture Contract：接管与压制合同

## 4.1 基本规则

对可接管支点：

- 范围内只有一方有效单位：该方推进接管。
- 双方都有有效单位：`contested=true`，进度暂停。
- 一方离开：剩余一方继续。
- 没有单位时：P0 默认**保持当前进度或按配置处理**，具体是否缓慢回退属于未冻结数值；不得在业务代码中自行硬编码不同规则。

## 4.2 占领权重

概念基线：

- 轻型 ≈ 2
- 普通 ≈ 1
- 重型 ≈ 0.5
- 超重型 = 0

玩家不看内部小数，只显示：

- `善于占领`
- `占领缓慢`
- `无法占领`

## 4.3 人数递减

禁止：

```text
capture_speed = sum(all_unit_weights)
```

因为会导致低费单位无限堆叠瞬间占点。

P0 要求一个**有上限或明显递减**的聚合函数。具体曲线未冻结，应集中到 tuning/config 中。

可接受的工程形态示例：

```text
first contributor = 100%
second = reduced
third+ = strongly reduced / capped
```

不要把最终系数散落到单位脚本。

## 4.4 压制、Claim 与激活顺序

标准序列：

```text
Enemy Online Support
        ↓ suppressed/destroyed
Enemy Claim may remain / support becomes non-operational
        ↓ capture becomes legal according to game rule
Capture progresses
        ↓ completed
Claim changes to attacker
        ↓ connectivity recompute
Connected? yes -> Online
Connected? no  -> CapturedOffline
```

核心不变量再次强调：

> **Claim 改变 != `spawn_enabled = true`。**

---

# 5. Battle-line Graph & Connectivity：战线图与连通性

## 5.1 图必须由地图预定义

P0 使用** authored graph edges **。

禁止：

- 运行时根据距离做所有支点 all-to-all 连接；
- “离得近就自动是上游”；
- 每帧重新做几何猜测。

地图/场景明确写出节点和边。

## 5.2 Core Base 是每方根节点

对 side S，连通性定义为：

```text
从 S 的 Core Base 出发
只沿 authored edges
只通过 S 已 Claim 且 operational 的可通行节点
BFS / DFS 可达
=> network_connected = true
```

孤立敌后节点：

```text
Claim = PLAYER
Operational = true
BFS from PLAYER_CORE cannot reach
=> Connected = false
=> no deployment
```

## 5.3 重算时机

Connectivity 只在相关状态变化时重算，例如：

- Claim owner 变化；
- operational 变化；
- 地图边被明确启用/禁用；
- Core/节点初始化；
- 未来特殊规则显式改变拓扑。

**禁止每 physics frame / 每鼠标移动做 BFS。**

## 5.4 分桥拓扑

P0 地图至少存在：

```text
           Main route
Core -> A -> B -> C
        \
         D -> E        # branch / flank path
```

侧路必须提供**不同的合法连接路径和部署方向**，而不是只做视觉岔路或弹体分配槽。

目标体验：

- Main route：直接、火力密集、正面争夺。
- Branch route：绕开主正面，建立另一条可持续增援的侧翼战线。

## 5.5 部署方向必须确定性

为了避免图有多条路径时“上游是谁”发生抖动，P0 不依赖纯几何自动推断部署朝向。

地图静态定义应为每个支点提供：

- Player 侧 preferred deploy direction / upstream hint；
- AI 侧 preferred deploy direction / upstream hint；
- 或等价的 authored deployment region metadata。

多路径连接不会改变同一支点的基本部署朝向，除非以后明确设计动态朝向系统。

---

# 6. Authoritative Deployment Validation：唯一部署合法性

## 6.1 单一权威入口

扩展现有 `DeploymentRules.gd`。

目标接口语义可类似：

```gdscript
validate_deploy(side, card_definition, target_position, context) -> DeploymentResult
```

或继续沿用现有 `evaluate(...)`，但必须加入新 battle-line/support 约束。

UI 与 AI 均调用同一规则层。

## 6.2 普通卡 P0 判定

普通部署至少满足：

1. 目标在地图内；
2. 满足卡自身旧有 rule type / region / owned-cell 等限制；
3. 目标位于：
   - 己方 Core Base 永久部署区；或
   - 己方某个 **Online Support** 的合法定向部署区；
4. 普通卡没有 `deployment_exception`；
5. 不越过当前战线允许范围。

建议为 `DeploymentResult.reason` 增加明确原因，例如：

- `support_offline`
- `outside_battleline`
- `no_connected_support`
- `deployment_exception_not_allowed`

## 6.3 视觉与规则同源

`DropZoneVisualizer` / Target Preview 只能展示 validator/geometry 层声明的区域。

禁止：

```text
UI 算一套合法区
CardSystem 再算另一套
AI 再猜第三套
```

否则必然出现“亮着但不能放”或“AI 能放玩家不能放”。

## 6.4 性能约束

- Graph connectivity 在状态变化时缓存。
- Deployment region geometry 在 support online/offline/ownership/topology 变化时更新。
- Hover 可以查询缓存后的 geometry/validator。
- 禁止 cursor 每帧触发 BFS。
- 禁止 hover 每帧写日志。
- 只对最终 deploy accepted/rejected 等有意义事件记录 telemetry。

## 6.5 特殊部署扩展点

P0 不实现空降/渗透，但可以预留显式枚举/字段：

```text
NORMAL
AIRBORNE
INFILTRATION
FORWARD_ENGINEER
```

P0 只允许 `NORMAL` 正式生效。

---

# 7. Support Visual & Battlefield Readability Contract

## 7.1 弱实体化

推荐：

- 地面环；
- 小旗；
- 发光底座；
- 很矮的通讯节点；
- 地表标记。

禁止重新做成大塔、大柱、大面积遮挡物。

## 7.2 状态反馈

至少可读：

- Online / Active；
- Disabled / Neutral；
- Capturing；
- Contested；
- CapturedOffline（需要和 Active 区分，避免玩家误以为已能部署）。

## 7.3 战线不常驻画满屏

默认：不显示复杂网络箭头。

玩家选中需要部署的卡时：

- 显示半透明合法部署区；
- 非法区域不高亮；
- 可给极短提示如 `超出战线`；
- 不显示内部 BFS、权重、节点 ID。

---

# 8. Draft / Offer Engineering Contract

## 8.1 独立上下文

目标结构：

```text
PlayerEligiblePool
    -> PlayerOfferContext / Generator State
    -> [A, B, C]

EnemyEligiblePool
    -> EnemyOfferContext / Generator State
    -> [D, E, F]
```

双方可共享**不可变卡牌定义 Manifest**，但不得共享：

- 当前 EligiblePool 结果对象；
- 当前 Offer；
- RNG stream/state；
- reroll exclusion；
- 私有路线状态；
- 英雄私有构筑上下文。

## 8.2 从现有 DraftSystem 演进

现有 `CardfrontUpgradeDraftSystem` 已有：

- eligibility；
- rarity weight；
- weighted sampling；
- timeout fallback；
- test seed。

P0 不另建完全平行的第二套 DraftSystem，而应演进为：

```text
build_eligible_pool(side_context)
weight_candidate(candidate, side_context)
generate_offer(side_context, offer_size)
```

随机测试要支持：

- 为 Player / AI 指定可复现 seed/stream；
- 能证明两方状态互不消费彼此 RNG 序列。

## 8.3 有条件的相对随机

完整顺序：

```text
Hard Eligibility
    -> Soft Weights
    -> Sample 3
    -> Bounded Offer Guards
    -> Offer
```

**不固定槽位角色。**

禁止：

- Slot 1 永远是当前问题答案；
- Slot 2 永远是主路线；
- Slot 3 永远是转型；
- 战场检测到敌人重装就必送反坦克答案牌。

## 8.4 两个 Soft Guard

### Diversity Guard

避免三张功能几乎完全相同，以至于没有真实选择。

### Dominance Guard

避免“一张显然统治另外两张”的极端 Offer，使另外两张成为假按钮。

注意：

- Guard 不是综合战力排序器；
- Guard 不要求三张数值等价；
- 允许三张都很强的“神仙三选一”；
- 允许同一路线的三张牌，只要作用不同、选择有意义；
- Guard 必须 bounded resample，例如最多 N 次，超过次数接受当前结果，防止无限循环；N 属 tuning 未冻结常数。

## 8.5 Reroll 阶段边界

完整设计已冻结：

- 每次 Draft 一次免费整体重抽；
- 不累计；
- 不允许第二次连续重抽；
- 与首次生成使用同一 eligibility/weight/rarity；
- 不偷偷提高强牌概率；
- 刚放弃的 3 个 ID 本轮暂时排除。

**实现阶段：P1。**

P0 Draft Preview Bug 不得依赖 reroll 功能存在。

---

# 9. Draft Battlefield Preview State Machine：回看战场

## 9.1 唯一状态机

```text
DRAFT_VISIBLE
   -- preview button -->
BATTLEFIELD_PREVIEW
   -- same fixed button -->
DRAFT_VISIBLE
```

## 9.2 DRAFT_VISIBLE -> BATTLEFIELD_PREVIEW

允许：

- 隐藏三选一内容层；
- 切换按钮文本/图标为“返回选卡”。

禁止：

- 改 Root anchor；
- 改 Root offset；
- reparent；
- 把整个容器移动到屏幕外；
- 重新生成 Offer；
- 清空候选 ID；
- 恢复战斗模拟。

> **“回看”只是视觉预览，不是离开 Draft。对局仍保持 Draft-paused 语义。**

## 9.3 返回

只恢复内容层可见性。

必须保持：

- 三张 candidate ID；
- card definition identity；
- Draft timer/phase 的正确语义；
- selection context；
- route display context。

不得触发：

- 选择；
- 结算；
- 下一阶段；
- Offer 再生成。

## 9.4 P0 验收

- 连续往返 20 次，Root Rect / anchors / offsets 无漂移。
- 候选 ID 前后一致。
- Offer generation count 不增加。
- 不改变玩家/AI choice progress。
- 窗口尺寸变化、窄屏后返回仍正确。
- 不产生重复 UI Node、重复 signal connection、多次 callback。

## 9.5 P1 追加回归

Reroll 实现后增加：

```text
reroll -> preview -> return
```

并验证 reroll availability / exclusion set 不变。

---

# 10. Card Level Contract：重复选择与升级

## 10.1 唯一外显成长维度

重复选择已拥有卡：

> **Level +1**

不再：

- 向牌堆塞第二张同 ID 实例；
- 额外建立一个“数量等级”；
- 让数量和等级两个旋钮乘法失控。

## 10.2 每卡固定升级轨

Level 节点可以改变：

- 数量；
- 数值；
- 机制；
- 标签/角色能力。

例如：

```text
征召兵
L1: 2 人
L2: 3 人
L3: 控制强化
L4: 4 人
L5: 快速接管
```

```text
重型突破车
L1: 1 辆
L2: 装甲强化
L3: 支点压制强化
L4: 突破机制
```

其身份应不同，禁止所有卡统一变成 `+20%攻击 +20%血 +1数量`。

## 10.3 现有状态接入

`CardfrontFactionRunState.applied_upgrade_counts` 已能记录同 ID 应用次数。

P0 可以把它封装为明确 API，例如：

```text
get_upgrade_level(id)
level_up(id)
```

业务/UI 不应直接到处读取 `applied_upgrade_counts[id] + 1` 自行解释。

---

# 11. Balance Contract & P0 Test Fixture

## 11.1 玩家看到三个轴

- 战斗力：能否把敌人打掉。
- 机动力：能否快速到达需要的位置。
- 控制力：能否把战果变成领土。

示意：

| 卡/单位 | 战斗 | 机动 | 控制 |
|---|---:|---:|---:|
| 征召兵 | ★ | ★★★ | ★★★★ |
| 侦察队 | ★★ | ★★★★★ | ★★★ |
| 普通步兵 | ★★★ | ★★★ | ★★★ |
| 重型突破车 | ★★★★★ | ★★ | ★ |
| 快速突击队 | ★★★★ | ★★★★★ | ★★ |
| 攻城平台 | ★★★★★★ | ★ | 0 |

硬原则：

> **深入路线强卡可以在一个轴上突破上限，甚至两个轴很强，但不能三个轴全顶级。**

> **强卡可以赢战斗，但不能自己完成战争。**

## 11.2 策划内部能力画像

至少拆：

- DPS / 爆发；
- 生存；
- 射程；
- 对轻型/集群/重型/固定目标效率；
- 转线时间；
- 部署灵活度；
- 单独接管时间；
- 支点压制。

**禁止最终加权成单一 Power Score。**

## 11.3 固定测试场景

1. 同费用正面交战；
2. 对大量低级单位；
3. 对高质量/重型单位；
4. 后方到远端支点；
5. 单独接管中立支点；
6. 压制部署支点。

真实对局后再记录选择率、胜率、部署率、平均存活、路线胜率。

## 11.4 P0 强卡测试不依赖 P1 路线系统

旧路线图存在阶段冲突：P0 想验证“强卡 + 低费控制卡”，但真正深度路线系统在 P1。

修正：P0 使用明确测试夹具，例如：

```text
SiegePlatform_Test
- 高/极高战斗与支点压制
- 低机动
- 控制 = 0
- 不要求路线解锁
```

只用于验证：

> 攻城平台可以把点打成中立，但仍需要征召兵/快速控制单位完成战争目标。

测试夹具不代表正式卡池内容，不得借机提前实现完整路线树。

---

# 12. Route Model：P1 已冻结设计边界

P0 只保留事件/数据扩展点；P1 才实现完整路线闭环。

## 12.1 卡牌来源只有三类

1. 基础卡：所有人共享。
2. 英雄职业卡：表达“我是谁”。
3. 阵营/路线卡：表达“这一局我正在变成什么”。

暂不增加第四、第五来源。

## 12.2 路线解锁的是可能性

路线达成后：

```text
route card -> EligiblePool
```

而不是：

```text
route completed -> immediate card grant
```

## 12.3 行为驱动

主要依据实际行为，选卡只做辅助倾向：

- 快速/侧翼行为 -> 机动；
- 重型突破 -> 重装；
- 夺取/守住支点 -> 控制；
- 建筑 -> 工事；
- 有效火力压制 -> 火力。

条件必须粗颗粒，不做“1350伤害 + 2据点 + 90秒”的隐藏数学题。

## 12.4 深度上限与反馈

- 可存在多种倾向；
- 真正深度路线最多 2 条；
- UI 只显示粗状态：未形成 / 正在形成 / 接近解锁 / 已解锁；
- 显示位置只在 Draft / 卡组查看 / 小型路线图标区域；
- 成熟 Build 目标至少拥有整局最后约 1/3 的实际使用窗口；精确时间未冻结。

## 12.5 Draft 机会同步

- 双方成长机会由统一、可预测节奏提供；
- 击杀/夺点/压制不额外送 Draft；
- 战场行为决定“解锁什么”，不是“多抽几次”。

---

# 13. AI Fairness & AIObservation Contract

## 13.1 两个完全分开的概念

### Information Fairness

AI 能知道什么。所有难度相同。

### Decision Strength

AI 用合法信息做多好的判断。随难度变化。

难度不能来自作弊权限。

## 13.2 允许信息

AI 可直接读取结构化的：

- 公开单位、位置、生命、公开类型；
- 支点 Claim/Online/Capture 等公开战场状态；
- 合法战线/己方部署区域；
- 双方公开英雄；
- 已公开使用的卡与本局行为历史；
- 自己的 Offer、资源、路线状态。

不要求 AI 真的截图做视觉识别。

## 13.3 禁止信息

AI 不得读取：

- 玩家当前私有 3 选 1；
- 玩家隐藏路线精确 score；
- 未来 RNG；
- 未来 Offer；
- 玩家未公开战术指令；
- 任何“为了方便”直接暴露的秘密字段。

## 13.4 当前对局内推断允许

AI 可以基于 `ObservedEnemyHistory` 推断：

> 玩家连续抢左侧 -> 可能倾向机动/侧翼 -> 提高左翼防守优先级。

这是推断，不是读取 `player.secret_route`。

P0/P1 默认历史范围为**当前对局**，不偷偷建立跨局玩家档案。

## 13.5 AIObservationBuilder 前移到 P0

目标：

```text
Game runtime
    -> AIObservationBuilder
    -> AIObservation
        - PublicBattleState
        - OwnPrivateState
        - ObservedEnemyHistory
    -> CardfrontAiCommander / policies
```

P0 只需最小 DTO 和权限边界；P1/P2 再增加聪明程度。

**禁止 `CardfrontAiCommander` 未来随意拿完整场景树/GameState 读取秘密。**

## 13.6 Decision Strength

建议：

- Easy：局部当前战况。
- Normal：战线 + 构筑 + 费用 + 基础反制。
- Hard：预测约 1–2 个决策阶段、识别倾向、保留资源。

所有难度仍使用相同 Information Fairness。

## 13.7 反应窗口

AI 使用离散决策窗口：

- `normal_decision_window`：常规全局/局部重新评估；
- `reactive_decision_window`：明确紧急事件可更快响应。

但二者都不得变成同帧 0.001 秒完美反制，也不得枚举全部未来弹道/部署形成物理预言机。

具体秒数未冻结，进入 tuning。

## 13.8 禁止隐藏难度加成

困难 AI 不得暗中：

- +伤害；
- +HP；
- +收入；
- 费用折扣；
- 多一次 Draft。

如果未来需要这些玩法，必须显式命名为 **Handicap / Challenge Modifier**，不能伪装成“AI 更聪明”。

---

# 14. Telemetry / Event Contract

P0 至少需要能追踪以下事件，名称可按现有事件总线调整：

- `support_suppressed`
- `capture_started`
- `capture_paused`
- `capture_completed`
- `support_connectivity_changed`
- `deploy_committed_accepted`
- `deploy_committed_rejected`
- `offer_generated(side, offer_ids)`
- `card_selected`
- `card_leveled`
- `draft_preview_toggled`

P1 再加入：

- `route_signal_event`
- `route_state_changed`
- `reroll_used`

AI 调试可保留：

- decision timestamp；
- difficulty / policy；
- decision window type；
- ranked candidate summary。

## 14.1 禁止遥测噪音

禁止：

- 每 hover cell 打一条 deploy rejected；
- 每帧打印 graph connectivity；
- 每物理帧记录 AI 全量评分。

Telemetry 记录**决策/状态变化**，不是鼠标轨迹垃圾。

---

# 15. P0 Test Matrix

## 15.1 单元测试

### Support

- Claim / operational / capture / connected 维度互不串改。
- 双方同时在范围内 -> Capture 暂停。
- 人数增长不会线性无限提高 Capture。
- Capture 完成但孤立 -> `CapturedOffline` / 不可部署。
- 上游断裂 -> 已 Claim 节点离线但 Claim 保留。
- 上游恢复 -> 自动 reconnect，不要求二次占领。
- Core Base 永远是己方在线根节点。

### Graph

- 主路可达。
- 分桥备用路径可达。
- 孤立敌后节点不可达。
- Claim/operational 改变才触发重算；测试不得依赖每帧 BFS。

### Deployment

- Core 部署区始终合法。
- Online support 的后方/侧后方合法。
- support 前方普通部署非法。
- Offline support 附近普通部署非法。
- 玩家/AI 调用同一 authoritative validator。

### Draft

- Player / AI Offer 对象独立。
- 一方生成 Offer 不应修改另一方当前 Offer。
- 可控制 seed 验证 RNG stream/state 独立。
- 偶然同卡允许。
- Duplicate -> Level+1，不增加重复实例。

### AIObservation

- DTO 包含己方私有 + 公共状态。
- DTO 不包含 opponent_offer。
- DTO 不包含 enemy_route_exact_score。
- DTO 不包含 future_rng/future_offer。

## 15.2 集成测试

1. 压制支点 -> 现有单位仍留场 -> 后续部署被切断。
2. 占下孤立侧后支点 -> 所有权变化 -> 不可部署 -> 战线接通 -> 自动可部署。
3. 主路断裂但分桥仍连通 -> 对应节点保持可用。
4. Core 被压回场景 -> 玩家仍能从 Core 区部署并反攻。
5. Player 与 AI 尝试同一位置/同规则 -> validator 结论一致。
6. Draft Preview 连续切换 20 次 -> 无布局漂移/Offer 重生成/信号重复。
7. `SiegePlatform_Test` 压制支点后仍需控制单位完成接管。

## 15.3 回归/性能

P0-00 先记录当前基线，再比较：

- 启动/进入对局烟雾测试；
- Draft -> Aim -> Volley 正常循环；
- Command Point 仍可用；
- 现有卡牌基础操作无明显回归；
- 窄屏/桌面 Draft 基础布局；
- Graph 不每帧重算；
- Hover 不产生日志洪流；
- UI 不重复 signal connection。

如果仓库当前没有稳定 FPS 基线，P0 不虚构一个数字；先记录真实基线，再设置允许回归阈值。

## 15.4 人工验收

- 支点视觉不再成为主要遮挡源。
- 测试者能在一局后说清 Main route 与 Branch route 的不同作用。
- 不显示满屏网络线也能理解“为什么这里能/不能部署”。
- 丢失前线支点明显痛，但仍能从 Core 组织反攻。
- 强攻城测试卡很强，但不能独自占点/完成战争。
- 低费控制单位在强卡出现后仍被真实使用。

---

# 16. P0 Dependency DAG & Execution Order

旧计划把视觉放在最前，容易先画 UI 后返工数据语义；冻结后的顺序调整如下。

## P0-00 当前回归基线

- 记录当前项目可启动/可对局基线。
- 确认 Draft/Aim/Volley/Command Point 当前行为。
- 定位 Draft Overlay 和“回看战场”真实拥有者。
- 记录现有关键测试/手工步骤。

## P0-01 Support Domain Model

- 静态 SupportDefinition；
- 动态 SupportState；
- Claim / operational / capture / connected 分离。

## P0-02 Capture & Support State Semantics

- 压制；
- 争夺暂停；
- 接管；
- 递减占领；
- 不删除已部署单位。

## P0-03 Battle-line Graph

- authored nodes/edges；
- Core roots；
- BFS/DFS connectivity cache；
- branch alternate path；
- deterministic per-side deploy direction metadata。

## P0-04 Authoritative Deployment

- 扩展 `DeploymentRules.gd`；
- directional zones；
- Core fallback zone；
- shared by player UI and AI。

## P0-05 Branch Integration

- 左下分桥接入真正备用/侧翼路径；
- 验证主路断裂/侧路仍可形成合法网络的场景。

## P0-06 Support Visuals

- 最后再基于稳定状态模型制作 Active / Offline / Capturing 等视觉；
- 保证弱实体化。

## P0-07 Draft Preview Bug

- `DRAFT_VISIBLE <-> BATTLEFIELD_PREVIEW`；
- visibility/state only；
- P0 不依赖 reroll。

## P0-08 Offer Independence

- 演进现有 `RoundDirector -> DraftSystem`；
- side-specific contexts/streams/offers；
- 保留共享 immutable definitions。

## P0-09 Duplicate -> Level

- 封装现有 upgrade count 为 Level API；
- 不膨胀牌堆。

## P0-10 Minimal AIObservationBuilder

- 建权限边界；
- 让现有 `CardfrontAiCommander` 逐步消费 observation/context；
- 不在 P0 做完整 Hard AI。

## P0-11 Full Regression + Go/No-Go

- 单元/集成/人工/性能回归一起执行。

依赖关系核心为：

```text
P0-00
  ↓
P0-01 -> P0-02 -> P0-03 -> P0-04 -> P0-05 -> P0-06
                       \
                        -> P0-10

P0-00 -> P0-07
P0-00 -> P0-08 -> P0-09

全部 -> P0-11
```

允许独立分支并行，但同一依赖链不得反序实现。

---

# 17. P0 Go / No-Go

只有以下基本成立才进入 P1：

1. 分桥/侧路用途不再需要设计者额外解释。
2. 支点失守会切断前沿增援，但玩家仍能从 Core 反攻。
3. CapturedOffline 与 Active 的行为/视觉区别明确。
4. 孤立敌后 Claim 不会变成前沿传送点。
5. 定向部署可理解，没有大量“为什么这里不能放”的困惑。
6. 玩家和 AI 使用同一个部署合法性规则层。
7. Player / AI Offer 真正独立，偶然撞牌仍允许。
8. Duplicate -> Level 不造成牌池膨胀。
9. Draft Preview 20 次往返无漂移、无重生成、无重复信号。
10. `SiegePlatform_Test` 能证明“强卡能赢战斗但不能自己完成战争”。
11. 没有出现“抢一个支点 -> 前沿刷兵 -> 自动连续滚穿全图”的明显雪球。
12. AIObservation 中不存在对方 Offer / 隐藏精确路线 / future RNG 等秘密字段。
13. Draft -> Aim -> Volley 与 Command Point 没有被本轮重构意外破坏。

任一核心项失败：优先回到 support model / graph / deployment / Offer boundary 修正，不用“继续加卡”掩盖问题。

---

# 18. P1 / P2 Gate

## P1 — 构筑分化与平衡闭环

P0 通过后再做：

- 基础 / 英雄 / 路线三类 Eligible Pool；
- 战场行为 route signals；
- 粗粒度路线反馈；
- 最多两条深度路线；
- 先做 2–3 条代表路线；
- 一级 + 真正强的深度卡；
- 一次免费 reroll；
- 独立 per-card upgrade tracks；
- Combat/Mobility/Control 卡面；
- 六类固定平衡测试自动化/半自动化；
- Easy/Normal Decision Strength；
- 成熟 Build 最后约 1/3 使用窗口调节。

P1 追加 Preview 回归：`reroll -> preview -> return`。

## P2 — 内容扩展与高级 AI

- 完整路线/高阶卡目录；
- Airborne / Infiltration / Forward Engineer 等规则例外；
- 更完整英雄职业差异；
- Hard AI：更长规划、路线推断、资源保留；
- 完整数据分析/平衡统计；
- 桌面/窄屏/移动端整体视觉整理；
- 后续 PvP 复用相同 Information Fairness 边界。

---

# 19. Change Control：变更控制

## 19.1 Frozen Invariants

本文标记为硬不变量的规则，如果实现发现确实不成立，必须：

1. 写明为什么；
2. 修改本 Engineering Spec；
3. 同步修改对应测试；
4. 再提交代码。

禁止：

- “先临时把占完直接 spawn_enabled=true”；
- “AI 先读一下玩家 Offer 以后再改”；
- “UI 先移动到屏幕外绕过布局 Bug”；
- “先再写一套 deploy 判定以后合并”。

临时绕过如果破坏不变量，就不是临时实现，而是设计回归。

## 19.2 Intentionally Unfrozen Constants

以下**故意不在 Design Freeze 阶段锁死具体数值**：

- Capture 递减曲线/上限；
- Capture 秒数；
- 基础/一级/深度卡精确费用；
- Draft 精确时间点和频率；
- Offer Guard 最大重采样次数；
- AI normal/reactive decision window 秒数；
- Support deployment shape 精确尺寸；
- 性能回归允许百分比（先有 P0-00 基线）。

这些必须：

- 进入集中 tuning/config/data；或
- 明确 TODO + 测试夹具；

不得散落为无法追踪的 magic numbers。

## 19.3 Historical Note

`GRILLME_GAME_DESIGN_INTERVIEW.md` 末尾曾记录“尚有约 5 个问题未锁定”。那是中途快照；升级语义、成长节奏、反雪球底线、AI 公平性、最小原型/验收已经在之后完成。

> **该“尚未锁定”清单从本文起视为历史记录，不再是当前待办。**

---

# 20. Freeze Conclusion

2026-08-07 GrillMe 的设计讨论到此已完成 Engineering Freeze。

现在不再继续扩展玩法问题。

下一步是：

> **从 P0-00 建立当前回归基线开始，按依赖顺序实现 P0。**

任何实现都应优先保护本文的不变量，而不是为了减少几行代码重新引入：传送式支点、共享 Offer、AI 偷看、牌堆膨胀、布局搬移式回看、每帧图搜索或第二套部署规则。
