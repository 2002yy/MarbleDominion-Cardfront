# Cardfront P0 Pre-Implementation Freeze Addendum — 2026-08-08

状态：**MANDATORY P0 PRE-IMPLEMENTATION FREEZE / MUST BE READ BEFORE P0-01**

适用范围：`P0-00F` + `P0-01` ～ `P0-05` 的地图支点、部署区、压制/接管、自动出生与 stale-state 语义。

上位文档：

1. `CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`
2. `CARDFRONT_P0_EXECUTION_GUARDRAILS_2026-08-07.md`
3. `CARDFRONT_P0_EXECUTION_DETAIL_BATCH_A_2026-08-08.md`
4. 本文
5. `CARDFRONT_P0_EXECUTION_DETAIL_BATCH_B_2026-08-08.md`
6. `CARDFRONT_P0_EXECUTION_DETAIL_BATCH_C_2026-08-08.md`
7. `CARDFRONT_REFACTOR_PLAN_2026-08-07.md`

> 本文不重新设计 Cardfront，也不推翻 Engineering Spec。
>
> 它只冻结此前仍可能迫使 Coding Agent 临场做玩法决定的六个实现前空洞：
>
> 1. `default_duel` 的真实 Support topology；
> 2. 普通 Support 的 directional deployment geometry；
> 3. Online Support 如何进入 suppressed / non-operational；
> 4. 无人接管时 capture progress 如何处理；
> 5. automatic / upgrade spawn 如何从合法区选实际出生格；
> 6. Preview 与 Commit 之间 battle-line state 变化时如何处理。

任何后续实现若需要改变本文冻结语义，必须显式开 Design/Engineering Amendment；不得在某个 P0 micro-step 内以“实现方便”为理由隐式偏移。

---

# 0. P0-00F — Pre-Implementation Freeze Gate

`P0-00A` ～ `P0-00E` 仍按原顺序执行。

在进入任何 `P0-01 Support gameplay code` 之前，必须新增：

```text
P0-00F Pre-Implementation Battle-line Freeze Verification
```

对应 checkpoint：

```text
docs/cardfront_refactor_checkpoints/P0-00F_PRE_IMPLEMENTATION_BATTLELINE_FREEZE.md
```

该 checkpoint 不是新的玩法讨论。

它只负责证明：

- 当前 `DefaultDuelMap.gd` 几何能无歧义映射到本文冻结的 stable `support_id`；
- 当前矩形 extent matrix 下 deployment profile 能 deterministic 计算；
- 当前 territory / entity / spawn pipeline 中没有事实与本文 suppression/capture/spawn contract 冲突；
- 若发现冲突，停止在 `P0-00F NO-GO / AMENDMENT REQUIRED`，不得自行改规则继续编码。

### P0-00F 必须输出

```text
Source commit:
DefaultDuel support mapping verified: YES/NO
Support IDs and anchor sources:
Frozen topology reproduced exactly: YES/NO
Directional geometry reproduced for 40x40: YES/NO
Directional geometry reproduced for 50x50: YES/NO
Directional geometry reproduced for 40x50: YES/NO
Directional geometry reproduced for 40x60: YES/NO
Suppression event source identified:
Support capture owner identified:
Automatic spawn old bypass path identified:
Deployment revision invalidation sources identified:
Contradictions found:
Decision: GO / NO-GO / AMENDMENT REQUIRED
```

没有 `P0-00F = GO`，不得开始 `P0-01A1`。

---

# 1. `default_duel` Support Topology — 正式冻结

## 1.1 地图战略解释

`default_duel` 不再被新系统解释成：

> 五个 Factory / Energy / Lab 奖励据点。

P0 新语义冻结为：

> **两条真正可持续的纵向战线 + 一个中央横向转线节点。**

现有旧区域几何继续复用，但旧 `ENERGY / FACTORY / LAB` 类型只作为迁移期 region/map 几何事实，不再定义 Support gameplay identity。

### 目标图

```text
                         AI_CORE
                       /         \
             LEFT_NORTH           RIGHT_NORTH
                 |  \               /  |
                 |    \           /    |
                 |       CENTER         |
                 |    /           \    |
                 |  /               \  |
             LEFT_SOUTH           RIGHT_SOUTH
                       \         /
                       PLAYER_CORE
```

两条直接主路径：

```text
PLAYER_CORE -> LEFT_SOUTH  -> LEFT_NORTH  -> AI_CORE
PLAYER_CORE -> RIGHT_SOUTH -> RIGHT_NORTH -> AI_CORE
```

中央节点提供转线/替代连接：

```text
LEFT_SOUTH  <-> CENTER <-> RIGHT_NORTH
RIGHT_SOUTH <-> CENTER <-> LEFT_NORTH
```

因此：

- 左线断裂不等于右线断裂；
- 右线断裂不等于左线断裂；
- CENTER 可以让已控制的另一条线为部分前方节点提供替代 supply/connectivity；
- CENTER 不是双方所有路线都必须经过的单点；
- 分桥/侧线的价值来自真实连接与部署来源，而不是资源、伤害或额外 Draft。

## 1.2 Stable Support IDs

正式 stable identity：

```text
core_player
support_left_south
support_right_south
support_center
support_left_north
support_right_north
core_ai
```

禁止使用下列任一内容替代 stable identity：

- runtime `region_id`；
- regions array index；
- `ENERGY / FACTORY / LAB` type；
- screen/world position；
- lane index。

## 1.3 旧区域到 Support 的迁移映射

当前 `DefaultDuelMap.make()` 的五个 region 几何映射冻结为：

| Stable support_id | 现有几何角色 | 迁移期旧 region 类型 | 战略角色 |
|---|---|---|---|
| `support_left_north` | 左上区域 | ENERGY | 左线北侧 Support |
| `support_right_north` | 右上区域 | FACTORY | 右线北侧 Support |
| `support_center` | 中央大区域 | LAB | 横向转线 / 中央争夺 Support |
| `support_left_south` | 左下区域 | FACTORY | 左线南侧 Support |
| `support_right_south` | 右下区域 | ENERGY | 右线南侧 Support |

`core_player` / `core_ai` 是 battle-line root，不要求映射到旧 stronghold region。

### Anchor authority

不得在 runtime 用“第几个 region”猜 anchor。

迁移时应由 map definition 正式 author：

```text
support_id
anchor_cell
neighbors
route_role
player_deploy_direction
ai_deploy_direction
deployment_profile_id
capture_profile_id
suppression_footprint/profile_id
```

初始 anchor 应等价于当前 `DefaultDuelMap.make()` 已计算出的对应 region 几何中心。

实现时可以复用当前 `left_x / right_x / top_y / bottom_y / center_x / center_y` 计算结果，但不得在 Support runtime 复制第二套尺寸公式。

## 1.4 Frozen Edges

P0 默认使用无向 authored connectivity edge；side-specific legality 由 Claim/Operational/Core root 决定。

冻结边集合：

```text
core_player <-> support_left_south
core_player <-> support_right_south

support_left_south  <-> support_left_north
support_right_south <-> support_right_north

support_left_south  <-> support_center
support_right_south <-> support_center
support_center      <-> support_left_north
support_center      <-> support_right_north

support_left_north  <-> core_ai
support_right_north <-> core_ai
```

禁止 P0 runtime 根据距离、region adjacency、lane center 或当前单位位置自行增删边。

## 1.5 Route metadata

至少 author：

```text
support_left_south.route_role  = LEFT
support_left_north.route_role  = LEFT
support_right_south.route_role = RIGHT
support_right_north.route_role = RIGHT
support_center.route_role      = CENTER_TRANSFER
```

这只是战略/placement metadata，不是 P1 route-build identity。

禁止把这里的 `LEFT / RIGHT / CENTER_TRANSFER` 当成第四种 EligiblePool source 或构筑路线。

---

# 2. Directional Deployment Geometry — 正式冻结

## 2.1 P0 唯一普通 Support shape

P0 普通 Support 只实现：

```text
DIRECTIONAL_REAR_RECT_V1
```

不同时实现 circle / cone / polygon / dynamic-frontline hull 多套生产规则。

特殊形状以后可以扩 profile，但不得改变 NORMAL 的基本约束。

## 2.2 Side-specific forward direction

`default_duel` 初版 authored direction：

```text
PLAYER forward = Vector2i(0, -1)
AI     forward = Vector2i(0, +1)
```

五个普通 Support 初版都使用上述 side-specific vertical forward direction。

禁止：

- 根据最近敌人实时旋转；
- 根据 projectile lane allocation 动态旋转；
- 因 graph predecessor 改变而抖动；
- 因 CENTER 当前从哪条路径联网而改变朝向。

如果未来某地图确实需要斜向/非轴向部署，必须通过 authored profile/direction 扩展，而不是修改 `default_duel` 当前合同。

## 2.3 几何定义

对：

```text
anchor = support anchor cell
forward = side authored forward direction
offset = target_cell - anchor
```

定义：

```text
forward_component = dot(offset, forward)
lateral_component = abs(dot(offset, perpendicular(forward)))
rear_distance = -forward_component
```

普通 Support 几何合法的必要条件：

```text
forward_component <= 0
0 <= rear_distance <= rear_depth_cells
lateral_component <= lateral_half_width_cells
```

因此：

- Support 正前方第一格起即不属于该 Support 普通部署区；
- Support 左右两侧可属于合法区；
- Support 后方为主要合法区；
- 不是 360° 出生圈；
- 不因当前敌人位置扩大到前方。

## 2.4 V1 尺寸公式

尺寸基于：

```text
min_axis = min(grid_width, grid_height)
```

冻结默认公式：

```text
lateral_half_width_cells = max(2, round(min_axis * 0.075))
rear_depth_cells         = max(2, round(min_axis * 0.10))
```

示例：

```text
40x40 / 40x50 / 40x60 -> half width 3, rear depth 4
50x50                 -> half width 4, rear depth 5
```

这些数值属于集中 tuning 常量，可以在后续有证据时调整；但 P0 首次实现不得由不同 consumer 各自选择尺寸。

## 2.5 Geometry != final placement legality

`DIRECTIONAL_REAR_RECT_V1` 只生成候选 geometry。

最终目标格仍必须满足：

- inside map；
- cell/card 原有规则；
- source Online；
- not blocked/reserved according to existing placement contract；
- 当前 `DeploymentRules` 最终返回 `allowed=true`。

禁止把“落在 rectangle 内”直接等同于完整 legal deploy。

## 2.6 Core fallback

Core fallback 不另造新圆形规则。

P0 `default_duel` 首版优先复用当前 map definition 已 author 的 faction `spawn_zones` 作为 Core candidate area，并通过统一 `DeploymentRules` 暴露为：

```text
source_kind = CORE
```

硬不变量：

```text
all non-core supports offline/disconnected
=> side still has at least one legal Core deployment cell
```

## 2.7 Overlapping Support zones

多个 Online Support 的 geometry 可以重叠。

合法格集合：

```text
union(all currently legal source cells)
```

不得因为 overlap 判非法。

如果一个 target cell 同时由多个 Online Support 证明合法，`DeploymentResult.resolved_support_id` 的 deterministic tie-break：

1. anchor 到 target 的 squared grid distance 更小者；
2. 相同则 `support_id` lexical ascending。

该 resolved source 只用于 deterministic explanation / telemetry / visual origin；不表示其它覆盖该格的 source 失效。

---

# 3. Support Suppression Contract — 正式冻结

## 3.1 Combat 与 Control 的职责分离

P0 冻结战争转换链：

```text
Combat / projectile / territory pressure
        ↓
reduce local territorial control around Support
        ↓
Support becomes suppressed / non-operational
        ↓
Control-capable creatures hold capture footprint
        ↓
Support Capture progresses
        ↓
Claim changes
        ↓
Operational + Connectivity checks
        ↓
Online deployment source
```

因此：

> **战斗可以打瘫支点，但不能仅靠一次高伤害事件直接把 Claim 改成己方。**

> **控制单位负责把已经打开的战果转成 Claim。**

这与 P1 “强卡可以赢战斗，但不能自己完成战争”保持一致。

## 3.2 Suppression authority

P0 不新增独立 Support HP 建筑战斗系统。

首版 suppression 使用现有 territory ownership 结果作为输入，但 Support runtime 保持独立 state transition owner。

每个 non-core Support 定义 authored `suppression_footprint`；首版可以与 capture footprint 相同，但两个 profile 字段必须语义独立，避免未来无法分离。

计算当前 Claim owner 在 suppression footprint 内的 territory share：

```text
claim_owner_local_share
```

冻结 hysteresis：

```text
SUPPRESS_OFF_THRESHOLD = 0.40
RECOVER_ON_THRESHOLD   = 0.60
```

规则：

```text
if currently operational
and claim_owner_local_share < 0.40
    -> operational = false

if currently non-operational
and claim unchanged
and claim_owner_local_share >= 0.60
    -> operational = true
```

使用 40% / 60% 而不是单一 50% 阈值，避免 territory projectile 在边界附近导致 Support 每 tick 抖动。

### Important separation

Territory system 只提供 local ownership evidence。

禁止：

```text
CardfrontCaptureInterceptor
 -> directly change support claim
```

也禁止 Support Capture runtime 反向成为 projectile territory capture owner。

两者仍是不同 pipeline。

## 3.3 Capture prerequisite

对一个当前仍由敌方 Claim 的 Support：

```text
operational == true
=> enemy takeover capture does not progress
```

必须先被打到 `operational=false`，攻击方 eligible creature 才能推进 takeover capture。

这样避免“一个廉价控制单位偷偷站圈，就无视正面战斗直接夺走正常工作的敌方前线”。

## 3.4 Claim changed 后不保证立即 Online

Capture 完成后：

```text
claim_owner = attacker
```

随后重新检查：

1. 新 Claim owner 的 operational recovery 条件；
2. SupportGraph connectivity。

因此允许：

```text
Captured + non-operational
Captured + operational + disconnected
Captured + operational + connected = Online
```

Capture completion 绝不直接写：

```text
spawn_enabled = true
```

---

# 4. Capture Idle Policy — 正式冻结

此前“无人时保持还是回退”不再留给实现 Agent 自选。

P0 冻结为：

> **无人贡献时，短暂 grace 后缓慢回退。**

## 4.1 State rules

### 单方 eligible contributors

```text
progress toward that side
```

### 双方均有 eligible contributors

```text
contested = true
progress frozen
idle decay does not run
```

### 无 eligible contributors

先保持：

```text
CAPTURE_IDLE_GRACE_SECONDS = 2.0
```

随后：

```text
capture_progress decays toward 0
```

冻结默认 decay magnitude：

```text
CAPTURE_IDLE_DECAY_MULTIPLIER = 0.25
```

即相对于集中 tuning 中“单个标准普通 contributor 的基准推进率”的 25%。

当进度回到 0：

```text
capture_side = NEUTRAL / NONE
```

## 4.2 Why

该语义阻止：

```text
cheap unit touches support
-> leaves forever
-> another unit minutes later continues permanent stored progress
```

但 2 秒 grace 又允许短暂位移、碰撞、路径抖动而不立刻把玩家努力清空。

## 4.3 Tuning boundary

以下仍是 Yellow tuning：

- total capture duration；
- per-profile capture weight；
- diminishing curve；
- 2.0 秒 grace 的后续微调；
- 0.25 decay multiplier 的后续微调。

但**语义不能从“会回退”改回“永久保存”而不经过 Amendment**。

---

# 5. Automatic / Upgrade Spawn Placement Resolver — 正式冻结

## 5.1 分离 legality 与 placement strategy

唯一合法性 authority 仍是：

```text
DeploymentRules
```

新增/演进一个 placement resolver seam 是允许的，但职责只能是：

> **从 DeploymentRules 已证明合法的候选格中 deterministic 选一个。**

概念边界：

```text
DeploymentRules
    -> can this cell be used?

DeploymentPlacementResolver
    -> among legal cells, which one should automatic spawn choose?
```

`DeploymentPlacementResolver` 不是第二套 deployment authority。

## 5.2 Resolver input

建议最小输入：

```text
side
spawn/deployment profile
preferred_route_role optional
preferred_support_id optional
current deployment_revision
```

禁止输入后自行：

- BFS graph；
- 猜 support Online；
- 绕过 DeploymentRules；
- 给 AI/upgrade entity 隐式越线特权。

## 5.3 Source ranking

P0 automatic / upgrade spawn source 选择顺序：

1. 若 action 明确提供 `preferred_support_id` 且其存在合法格，优先该 Support；
2. 若 action 提供 `preferred_route_role`，先在该 role 的 Online Supports 中找；
3. 其余 Online Supports 按**从己方 Core 的 authored graph depth 较深者优先**；
4. graph depth 相同按 `support_id` lexical ascending；
5. 所有 Support 无合法格时，进入 Core fallback；
6. Core 也无合法格时，返回显式 failure。

禁止隐藏 fallback：

```text
spawn at origin
spawn at old route building slot
spawn at arbitrary owned cell
```

## 5.4 Candidate cell ranking inside one Support

对 `DIRECTIONAL_REAR_RECT_V1` 中通过 DeploymentRules 的合法 cell：

排序冻结为：

1. `rear_distance` 更小：更靠近 Support / 前线；
2. `lateral_component` 更小：更靠近路线中心；
3. squared distance to anchor 更小；
4. `cell.y` ascending；
5. `cell.x` ascending。

这样自动出生稳定、可测试，不引入 P0 不需要的随机抖动。

## 5.5 Failure semantics

无合法 cell：

```text
allowed = false
reason = no_valid_deployment_source
```

实际 upgrade/resource rollback 由上位 card/effect transaction owner 处理。

Placement resolver 不自行决定：

- refund；
- 改抽卡结果；
- 换另一张卡；
- 强行生成。

---

# 6. Deployment Revision & Stale-State Contract — 正式冻结

## 6.1 Monotonic deployment revision

P0 增加/暴露 monotonic：

```text
deployment_revision: int
```

只要任一变化可能改变 NORMAL deployment legality，就使 revision 前进：

- Support `claim_owner` 改变；
- Support `operational` 改变；
- connectivity result/revision 改变；
- authored topology/runtime topology 被合法规则显式改变；
- deployment profile/geometry revision 改变；
- map/support runtime 初始化或 restore 后重建。

以下不应推进 deployment revision：

- hover；
- UI redraw；
- Draft timer tick；
- capture progress 小幅变化但尚未改变 Claim/Operational；
- projectile frame step 本身；
- camera motion。

## 6.2 Geometry cache key

至少包含：

```text
side
spawn/deployment profile
deployment_revision
```

不得每 cursor frame 重新 BFS 或重建全部 Support geometry。

## 6.3 Preview semantics

Preview 可以记录：

```text
preview_revision
```

用于判断当前高亮是否可能 stale。

但：

> **Preview revision 不是 Commit permission token。**

UI 不得因为“当时绿过”就在 Commit 时跳过 rules。

## 6.4 Commit semantics

最终 Commit 必须对当前 state 再调用 authoritative DeploymentRules。

如果：

```text
preview_revision != current deployment_revision
```

正确行为是：

```text
revalidate current target
```

而不是无条件失败，也不是无条件成功。

若当前 cell 仍合法：

```text
commit succeeds
```

若已非法：

返回当前真实原因，例如：

```text
support_offline
support_disconnected
outside_deployment_zone
no_valid_deployment_source
```

随后 UI 刷新当前 geometry。

## 6.5 AI / Auto Spawn parity

AI 与 automatic placement 也必须消费 current revision/current rules。

禁止 AI 缓存旧合法格列表跨 revision 使用。

---

# 7. Required Tests Before P0-05

本文冻结内容必须至少有以下 contract tests。

## 7.1 Topology

```text
T1 left direct path works
T2 right direct path works
T3 left broken, right survives
T4 right broken, left survives
T5 center enables alternate cross-route connectivity
T6 center loss does not destroy both direct routes
T7 opponent-claimed node cannot carry own connectivity
```

## 7.2 Directional geometry

每个 supported extent：

```text
40x40
50x50
40x50
40x60
```

至少验证：

```text
front cell = illegal
rear cell = legal when source Online
side cell = legal when within width
outside lateral width = illegal
outside rear depth = illegal
offline source = no legal contribution
disconnected source = no legal contribution
```

## 7.3 Suppression/capture

```text
operational + share 39% -> suppressed
suppressed + share 50% -> remains suppressed
suppressed + share 60% -> recovers if Claim unchanged
operational enemy support -> takeover capture blocked
suppressed enemy support -> takeover capture allowed
both sides contributors -> pause
nobody <= 2s -> hold
nobody > 2s -> decay
progress reaches 0 -> capture_side cleared
```

## 7.4 Placement resolver

```text
preferred valid support wins
invalid preferred support falls through legally
front-most/deeper legal support selected deterministically
same-depth tie deterministic
all supports invalid -> Core fallback
Core blocked too -> explicit failure
no old route-slot fallback
```

## 7.5 Stale state

```text
preview at revision N legal
support disconnect -> revision N+1
commit same cell -> revalidate and reject

preview at revision N legal
unrelated revision-changing source changes
same target remains legal
commit -> revalidate and succeed
```

---

# 8. Mandatory Forbidden Diff List

P0-01 ～ P0-05 因本文不得顺手加入：

- Airborne；
- Infiltration；
- Forward Engineer 越线例外；
- 360° Support spawn circle；
- dynamic deploy direction toward nearest enemy；
- Support generic damage/resource/Draft bonus；
- Support capture reward extra Draft；
- support HP / armor / building combat tree；
- global Creature free movement across neutral/enemy cells；
- second graph authority inside placement resolver；
- AI-only illegal spawn；
- random automatic placement；
- cursor-frame BFS；
- stale Preview token bypassing Commit validation。

P2 的特殊部署卡设计空间必须继续保留。

---

# 9. P0-04 Four-Consumer Parity — 更新后的最终解释

四个 consumer：

```text
1. Player Preview
2. Player Commit
3. AI Placement
4. Automatic / Upgrade Spawn
```

必须共享同一 NORMAL legality authority。

但职责允许不同：

```text
Preview
 -> enumerate/show legal cells

Commit
 -> validate requested cell

AI
 -> choose among current legal cells

Auto Spawn
 -> deterministic PlacementResolver chooses among current legal cells
```

“共享 authority”不要求四个 consumer API 一模一样；要求相同 side/profile/cell/current revision 得到相同 legality 结论。

---

# 10. Final Pre-Coding Restatement

开始 `P0-01A1` 前，实现 Agent 必须复述：

> **`default_duel` 是两条可持续纵向战线加一个中央转线节点；普通 Support 只向己方侧/侧后方提供 deterministic rectangular deployment zone；Combat/territory pressure 先把敌方 Support 打到 non-operational，Control units 再完成 Claim；无人接管会在 grace 后回退；自动出生只能从 DeploymentRules 的当前合法格里 deterministic 选择；Preview 永远不能替代 Commit 时的当前规则复核。**

若 Agent 无法从当前代码和地图事实证明这些合同可实现：

> **停止在 P0-00F，开 Amendment；不得用局部实现偷偷改设计。**
