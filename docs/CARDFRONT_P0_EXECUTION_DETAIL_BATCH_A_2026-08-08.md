# Cardfront P0 Execution Detail — Batch A — 2026-08-08

状态：**MANDATORY ADDENDUM / ANTI-DRIFT BATCH A**  
适用：P0-00 ～ P0-05  
上位文档：

1. `CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`
2. `CARDFRONT_P0_EXECUTION_GUARDRAILS_2026-08-07.md`
3. 本文
4. `CARDFRONT_REFACTOR_PLAN_2026-08-07.md`

> 本文不增加玩法，只把 P0-00～P0-05 继续下降成能直接交给 Coding Agent 的迁移边界。
>
> **目的不是“告诉 Agent 怎么写得漂亮”，而是堵住旧实现中会让每个局部步骤逐渐偏离冻结设计的暗门。**

---

# 1. 本批新增确认的旧实现事实

这些事实必须在 P0-00A Ownership Map 中明确记录。

## 1.1 当前仓库没有可直接假定为现役的 `tests/`

仓库当前存在：

- `tests_legacy_disabled/`
- `TestRunner.gd.disabled`
- `TestAssert.gd.disabled`
- 一批 `.gd.disabled` 测试

旧 `TestRunner` 仍假定从 `res://tests` 自动发现测试。

因此后续任何步骤写“tests PASS”之前，必须先确定**哪一个测试入口才是本轮 P0 的证据 authority**。

禁止：

- Agent 临时写一个只测自己新代码的脚本，然后把它称为“完整回归”；
- 把整个 `tests_legacy_disabled` 一次性恢复并顺手修几十个无关旧测试；
- 因为 legacy tests 是 disabled 就直接跳过回归基线。

---

## 1.2 `region_id` 是运行时分配结果，不是稳定 Support 身份

当前：

```text
CardfrontMapDefinition
 -> CardfrontMapBuilder.apply_to_region_map()
 -> RegionMap.paint_region_*
 -> RegionMap._allocate_region()
```

`RegionMap.next_region_id` 按 region 应用顺序递增。

所以：

> **禁止把 `region_id == 1/2/3/...` 当作某个部署支点的永久 identity。**

本轮稳定 identity 必须是 authored `support_id`。

P0 推荐映射方式：

```text
support_id
 -> authored anchor_cell
 -> RegionMap.get_region_id(anchor_cell)
 -> runtime region_id
```

`runtime region_id` 只是当前地图实例引用，不得写进长期规则、卡牌定义、路线逻辑或保存档当作 Support identity。

---

## 1.3 旧 `CaptureInterceptor` 不是新的 Support Capture 系统

当前：

- `CardfrontCaptureInterceptor.gd`
- `CardfrontBattlefieldEntityRuntime.resolve_capture_contact()`
- `CardfrontEntityProjectileBridge.resolve_capture_contact()`

这里的 capture 语义是：

> **炮弹尝试改变 battlefield territory owner 时，实体/防御是否阻挡此次领土占领。**

它处理：

- projectile/entity contact；
- fortify interception；
- territory capture application。

它**不是**：

- 单位站在支点范围；
- 占领权重；
- contested pause；
- support claim；
- support operational/connectivity。

因此冻结：

```text
Territory Capture Pipeline
!=
Deployment Support Capture Pipeline
```

禁止为了“复用 capture”把新的支点占领状态塞进 `CardfrontCaptureInterceptor`。

新的 Support Capture 可以读取 Battlefield Entity Registry 的单位位置，但不能把 projectile territory contact 当作 support capture event。

---

## 1.4 现有 Creature 移动被限制在己方领土

`CardfrontCreatureActionCoordinator.next_owned_step_toward()` 当前明确要求：

```text
battlefield.owners[candidate] == owner_id
```

现有 repair / guard 等单位不会正常走入中立或敌方格。

这对新支点设计影响很大：

> “单位进入支点范围推进 Capture”不能被实现 Agent 偷偷解释成“顺手把所有 Creature 改成自由穿越中立/敌方领土”。

P0 默认冻结：

**不重写全局 Creature movement legality。**

推荐最小迁移语义：

- Support 有一个 authored capture footprint/range；
- 单位只要位于这个范围内即可贡献；
- 贡献单位所在 cell 仍遵守现有 movement/territory legality；
- 因此玩家通常先通过现有领土推进把可站立区域推进到 Support 周围，再由单位完成 Support Claim。

这仍满足：

```text
强战斗力 -> 打开/推进战场
控制单位 -> 把战果转成支点所有权
```

同时避免 P0 顺手把 Creature locomotion 改造成另一套 RTS。

如果实测证明这个限制导致 Support 根本无法形成可玩的争夺，必须单独提 Amendment；不得在 P0-02 中偷偷放开单位跨线移动。

---

## 1.5 当前存在一条绕开 DeploymentRules 的单位出生路径

Draft upgrade resolution 当前可以：

```text
CardfrontRoundDirector
 -> BattlefieldEntityRuntime.apply_pending_upgrade_actions()
 -> spawn_repair_units / spawn_armored_guard / spawn_sapper_unit
 -> CardfrontCreatureActionCoordinator.find_owner_spawn_cell()
```

`find_owner_spawn_cell()` 当前根据：

- route building slot；
- lane index；
- 邻近 owned cell

直接决定出生位置。

它没有经过：

```text
DeploymentRules.evaluate()
```

所以之前只写：

```text
Player commit = Preview = AI
```

还不够。

必须加入第四条：

```text
Auto/Upgrade Entity Spawn
```

否则 UI 看起来已经使用新战线，升级召唤却仍会从旧 route slot 凭空出生。

---

## 1.6 Save Snapshot 仍保存 Legacy Stronghold 字段

`CardfrontRuntimeSnapshot` 当前保存：

- `current_stronghold_bonuses`
- `current_gate_snapshot`
- `entity_snapshot`
- run states / offers 等

因此 Legacy Stronghold Cutover 不能简单理解为“全局删除所有 stronghold 字符串”。

必须区分：

```text
runtime gameplay authority retirement
vs
save-schema backward compatibility
```

旧字段可以暂时作为兼容读字段存在，但不得继续影响新正式 gameplay。

---

# 2. 新增 Anti-Drift Locks

## Lock A — Test Evidence Authority

P0-00 结束前必须确定唯一测试入口。

后续 checkpoint 的 `Automated tests` 必须写：

```text
runner:
command:
test files:
pass count:
fail count:
```

禁止只写：

```text
tests passed
```

---

## Lock B — Support Identity Authority

唯一稳定身份：

```text
support_id
```

以下全部不得被当作 identity：

- runtime `region_id`；
- array index；
- screen position；
- stronghold type（factory/energy/lab）；
- lane index。

这些只能作为属性或映射输入。

---

## Lock C — Capture Vocabulary Separation

代码、checkpoint 和日志必须使用明确术语：

```text
territory_capture
support_capture
```

禁止继续只写模糊的：

```text
capture
```

尤其禁止让一个 signal/function 同时表示二者。

---

## Lock D — Movement Preservation

P0-02 默认不得修改：

```text
CardfrontCreatureActionCoordinator.next_owned_step_toward()
```

的“只走己方领土”核心限制。

如必须修改，当前 step 自动变 `NO-GO / AMENDMENT REQUIRED`。

---

## Lock E — Deployment Authority Must Cover Every Spawn Path

最终 P0-04 parity 不再是三方，而是至少四方：

```text
1. Player Preview
2. Player Commit
3. AI Placement
4. Upgrade/Automatic Entity Spawn
```

任何一方绕过 authoritative deployment rule，P0-04 不得 GO。

---

## Lock F — Derived State Is Not Save Authority

建议冻结：

- `claim_owner`：authoritative runtime state，可保存；
- `operational`：authoritative runtime state，可保存；
- `capture_side/progress`：authoritative transient state；是否保存取决于当前 save contract，但必须明确；
- `network_connected`：**derived/cache**，恢复后从 graph 重算，不作为永久事实；
- `contested`：优先由当前 contributor set 派生，不作为长期 identity。

禁止出现：

```text
save says connected=true
but graph says disconnected
```

然后业务逻辑不知道信谁。

---

# 3. P0-00 继续拆细

## P0-00D — Test Harness Truth

### 只回答
本轮 P0 用什么跑自动测试？

### 必须调查
- 为什么 `tests_legacy_disabled` 被禁用；
- 是否还有隐藏/外部 runner；
- Godot CLI 当前能否跑 headless tests；
- 哪些 legacy tests 仍与 Cardfront 当前主循环有关；
- 是否应该建立一个最小 `tests/cardfront_p0/` runner。

### 推荐方向
如果没有现役 runner：

- 建立**最小 P0 专用 runner**；
- 可以借用旧 `TestRunner/TestAssert` 的结构；
- 不一次性复活整个 legacy suite；
- 第一个版本只放 baseline contract/smoke tests。

### Forbidden
- 改 gameplay 让 test 好过；
- 顺手修所有 legacy tests；
- 引入大型第三方测试框架除非现有环境明确需要。

### Exit
Checkpoint 中存在真实可复制命令，并能：

- 0 test -> fail；
- assertion fail -> non-zero；
- all pass -> zero。

---

## P0-00E — Golden Baseline Contract

P0-00B 记录人工基线后，再产出机器可比较的 minimal golden snapshot。

建议只固定结构性数据，不固定随机视觉像素：

- mode boots；
- duel factions；
- Draft phase opens；
- player/AI offer size 基线；
- Aim/Volley phase transition；
- Command Point/system still present；
- old Stronghold bonus 当前确实能影响正式运行；
- two lane metadata 数量/基本几何；
- current Peek geometry bug reproduction metadata。

### 目的
后面移除旧 Stronghold 时，golden baseline 必须**有意识更新一项**，而不是全量 snapshot 被 Agent 随手重录。

### Forbidden
- 每次 test fail 都直接 regenerate golden；
- 把 FPS/随机 Offer exact IDs 当不可变化 golden。

---

# 4. P0-01 Support Model 继续拆细

## P0-01A1 — Stable Support Identity Schema

最小 static definition：

```text
support_id            # stable authored string
anchor_cell           # authored map anchor
is_core               # bool
authored_neighbors    # support_id list
player_deploy_dir     # authored metadata
ai_deploy_dir         # authored metadata
capture_shape/profile # reference/id, not behavior code
spawn_shape/profile   # reference/id, not behavior code
```

### 明确禁止字段

```text
shot_bonus
attack_bonus
draft_choice_bonus
resource_income
rarity_bonus
```

SupportDefinition 出现这些字段，当前 step 直接 NO-GO。

---

## P0-01A2 — Runtime State Truth Table

必须先用表格覆盖至少：

| Claim | Operational | Connected | Derived gameplay |
|---|---|---|---|
| own | true | true | Online / can contribute deployment zone |
| own | true | false | CapturedOffline / no deployment |
| own | false | any | Disabled / no deployment |
| neutral | true/false | any | not owned / no deployment |
| enemy | true | true for enemy | enemy online, not ours |

### 强制
`Online` 必须是派生表达，不得成为第五份可被独立写入的真相。

---

## P0-01B1 — Region Mapping by Anchor, Not Numeric ID

### Algorithm contract

```text
for support_definition:
    validate anchor inside map
    runtime_region_id = region_map.get_region_id(anchor_cell)
    validate region exists/controllable where required
    bind support_id -> runtime_region_id
```

### 必须测试
- region 定义列表重排后，只要 anchor geometry 不变，support identity 仍映射正确；
- anchor 落到 NORMAL region -> fail fast；
- 两个 non-core support 错误映射同一 runtime region -> validation error；
- unknown neighbor support_id -> validation error。

### 禁止

```text
if region_id == 1: left_support
```

---

## P0-01B2 — Map Metadata Validation Only

在这一小步只验证 topology/support metadata，不启动 capture、deployment 或 visual。

建议扩展 `CardfrontMapDefinition.validate()` 或新增纯 validator seam，但**不要**让 `CardfrontMapBuilder` 开始处理 gameplay state。

### Exit
错误 authored topology 在 map setup 时明确失败，而不是战斗中静默 fallback。

---

# 5. P0-02 Support Capture 继续拆细

## P0-02A1 — Contributor Extraction Contract

Pure capture calculator 的输入不能直接是一整个 scene tree。

先定义 contributor DTO：

```text
entity_id
owner_id
capture_profile
capture_weight
cell
eligible
```

### 来源
Integration adapter 可以从：

```text
CardfrontBattlefieldEntityRuntime.registry
```

读取 alive creature。

### 默认 P0 eligibility
- duel faction creature：可以按 profile 贡献；
- neutral creature：不贡献；
- defense tower/building：不贡献；
- dead/inactive creature：不贡献。

### 禁止隐式推导
Support Capture Runtime 不得自行写：

```text
armored -> weight 0.5
movement > 1 -> weight 2
size_slots == 2 -> cannot capture
```

权重必须来自集中 profile/data mapping。

---

## P0-02A2 — Capture Profile Mapping

当前 creature state 没有 capture_weight 字段。

因此 P0 需要一个**集中映射 seam**，而不是把系数散进 `CreatureActionCoordinator`。

允许：

```text
creature_id -> capture_profile
capture_profile -> weight/tag
```

P0 初始只覆盖现有需要参与验证的代表单位。

### Forbidden
- 顺手重做完整 unit stat schema；
- 用战斗 DPS 自动算 capture；
- 把 Combat/Mobility/Control 压成一个综合数。

---

## P0-02A3 — Diminishing Aggregator

输入：同一方 eligible contributors。

输出至少：

```text
raw_weight
resolved_capture_power
contributor_count
capped_or_diminished
```

### 必须满足
- 第 2 个单位仍有收益；
- 第 3+ 不可保持线性；
- 任意大量廉价单位不能无限提升速度；
- profile weight 0 永远不贡献。

具体系数保持 Yellow tuning，不写死在多个业务类。

---

## P0-02B1 — Support Capture State Machine

只接受：

```text
current support state
player capture power
ai capture power
delta/time step
tuning
```

输出 state transition。

### 它不能读取
- Draft；
- card rarity；
- Stronghold bonus；
- Gate projectile state；
- AI difficulty。

### 必测状态
1. nobody -> no progress change according to configured idle policy；
2. player only -> player progress；
3. AI only -> AI progress；
4. both -> contested pause；
5. capture complete -> claim changes；
6. claim changed but disconnected -> CapturedOffline；
7. support suppressed -> no Online deployment；
8. upstream reconnect -> connectivity resolver later restores Online，不重新 capture。

---

## P0-02C1 — Entity Registry Occupancy Adapter

只负责：

```text
support capture footprint
 -> cells
 -> alive entity registry records
 -> contributor DTOs
```

### 强制隔离
不得调用：

```text
CardfrontCaptureInterceptor.should_block_capture()
CardfrontEntityProjectileBridge.resolve_capture_contact()
```

这两个属于 territory/projectile pipeline。

---

## P0-02C2 — Territory-Gated Occupancy Prototype

这是本批最重要的旧实现适配检查。

### 默认方案
保持现有 creature movement：

```text
only step onto owner territory
```

Support capture footprint 可以跨多个格。

只要己方 creature 位于 footprint 内的合法己方格，就可贡献 Support Capture。

### 必须最小实验
在一个 representative support 上验证：

1. 玩家通过现有 territory/volley 推进到支点附近；
2. control creature 能沿 existing owned cells 进入 capture footprint；
3. 不修改 global movement rule 也能完成 Claim；
4. 对方进入 footprint 后 contested；
5. 强攻单位 alone 若 control=0，不能自动 Claim。

### Stop rule
若步骤 2 在当前地图结构上客观无法成立：

```text
BLOCKED / AMENDMENT REQUIRED
```

不得直接修改 `next_owned_step_toward()` 放开跨线移动。

---

## P0-02D — Support Snapshot Contract

支点运行时稳定后才接保存。

### 推荐持久化
- `support_id`
- `claim_owner`
- `operational`
- 必要时 `capture_side/progress`

### 推荐不持久化为 authority
- `network_connected`：restore 后 graph recompute；
- derived Online；
- visual state。

### Legacy save
如果旧 snapshot 不含 support state：

- 不得临时猜一个迁移规则然后隐藏起来；
- 必须在 checkpoint 明确记录 compatibility policy；
- `current_stronghold_bonuses` 即使继续可读，也不得成为新 support state 的来源，除非另有显式 migration contract。

---

# 6. P0-03 Graph 继续拆细

## P0-03A1 — Topology Data Contract

Topology 只包含：

```text
support nodes
core roots
edges
authored per-side deploy direction/profile refs
```

不包含：

```text
capture progress
current owner
current connected
bonus
projectile gate openness
```

---

## P0-03A2 — Graph Validation

Map setup 时至少验证：

- 每方恰有一个 P0 Core root；
- every edge endpoints exist；
- 不允许 self-edge；
- duplicate edge normalized/rejected deterministically；
- support_id unique；
- authored directions valid；
- branch path 确实形成和 main 不完全相同的 connectivity path。

### 注意
“存在两条 lane metadata”不等于“存在两条 Support Graph path”。

必须显式测试 graph path。

---

## P0-03B1 — Resolver Inputs / Outputs

Input：

```text
topology
side
claim_owner by support
operational by support
```

Output：

```text
connected_support_ids
unconnected_claimed_support_ids
reachable_parent/predecessor optional debug data
revision
```

### 禁止输入
- battlefield pixel ownership percentage；
- Gate openness；
- card rarity；
- route tendency；
- AI archetype。

---

## P0-03B2 — Connectivity Truth Tests

至少固定 8 例：

1. Core only；
2. Core -> Main A online；
3. Core -> Branch A online；
4. Main upstream disabled -> downstream main offline；
5. Branch remains -> branch downstream online；
6. isolated enemy-backline Claim -> offline；
7. reconnect upstream -> same Claim auto online；
8. opponent Claim 不参与己方 traversal。

---

## P0-03C1 — Revisioned Cache

Graph cache 必须有 revision/debug counter。

每次 relevant mutation：

```text
claim_changed
operational_changed
topology_loaded
```

revision +1 / recompute。

以下不得触发：

```text
hover
UI redraw
Draft timer tick
projectile step
FPS frame
```

### Exit
测试可以断言：

```text
100 idle frames -> recompute count unchanged
100 hover events -> recompute count unchanged
one claim change -> exactly one logical invalidation
```

---

# 7. P0-04 Deployment Authority 继续拆细

## P0-04A1 — Extend Existing Query/Result Contract

当前已有：

- `DeploymentQuery`
- `DeploymentResult`
- `DeploymentRuleType`
- `DeploymentRules.evaluate()`

优先扩这些现有 seam。

### Query 可以增加的语义
- owner；
- cell；
- frontline/support rule type；
- support/network context reference or immutable snapshot；
- spawn/deploy profile。

### Result 至少要能表达
- allowed；
- reason；
- resolved support_id（如适用）；
- source kind：Core / Support；
- debug-only explanation。

### 新 reason code 建议

```text
support_not_claimed
support_offline
support_disconnected
outside_deployment_zone
wrong_deploy_direction
no_valid_deployment_source
```

不要让 UI 根据这些字符串再自行决定 allowed。

---

## P0-04A2 — Core Fallback First

在 Support 正式接入前先证明：

```text
所有前线 support offline
=> Core zone 仍有合法部署格
```

这一条优先级高于“前线出生是否漂亮”。

若 Core fallback 不成立，不得继续接 branch。

---

## P0-04A3 — Directional Support Zone

普通 Support：

```text
Online
+ authored direction/profile
=> deterministic deployment cells
```

禁止：

- 360° circle 默认出生；
- 根据敌人位置实时反向；
- UI 自己扩大一圈可放区；
- 支点刚 Claim 但 disconnected 也产区。

---

## P0-04B/C/D — Commit / Preview / AI Cutover

顺序必须保持：

```text
1. Rules pure tests
2. Player commit
3. Preview
4. AI
```

每接一个 consumer，都用同一 fixture 对比前一个 consumer。

禁止四个 consumer 同时改完再统一排错。

---

## P0-04E — Upgrade/Automatic Entity Spawn Cutover

这是上一版路线遗漏的重要 consumer。

### 当前旧 path

```text
RoundDirector
 -> apply_pending_upgrade_actions
 -> CreatureActionCoordinator.find_owner_spawn_cell
 -> route building slot
```

### P0 目标
Automatic entity spawn 也必须从 authoritative deployment source/zone 产生合法 cell。

### 推荐边界
`CreatureActionCoordinator` 不负责重新判断战线图。

它应收到：

```text
resolved legal spawn cell
```

或调用一个最终仍委托 `DeploymentRules` 的 placement query。

### Forbidden
- 保留旧 route slot spawn 作为隐藏 fallback；
- 当新规则找不到位置时直接 `return origin` 并出生；
- 给 AI/upgrade summon 特殊越线权；
- 这一阶段顺便重做 creature AI movement。

### Failure semantics 必须先定
如果没有合法 spawn cell：

- 不得偷偷 spawn；
- 不得 silently move to arbitrary owned cell；
- 必须返回明确 failure/result；
- 资源/upgrade 是否退款按当前上位 resolver contract 处理，不在 coordinator 私自决定。

---

## P0-04F — Four-Consumer Parity Matrix

至少对这些场景比较：

| Scenario | Preview | Commit | AI | Auto Spawn |
|---|---|---|---|---|
| Core legal | legal | legal | legal | legal |
| Online support rear zone | legal | legal | legal | legal |
| support disconnected | illegal | illegal | illegal | illegal |
| support disabled | illegal | illegal | illegal | illegal |
| outside direction | illegal | illegal | illegal | illegal |
| isolated captured support | illegal | illegal | illegal | illegal |

Auto Spawn 若不是 cell-targeted UI，不要求 API 形式相同，但最终合法性必须来自同一 authority。

---

# 8. P0-05 Branch + Stronghold Cutover 继续拆细

## P0-05A1 — Branch Topology Fixture Before Map Behavior Cutover

先在纯 graph fixture 证明：

```text
Core
├─ Main path
└─ Branch path
```

满足冻结语义。

此时不改真实地图视觉、不改 bridge projectile rule。

---

## P0-05A2 — Bind Existing Default Map to Authored Graph

只做：

- support IDs；
- anchors；
- edges；
- main/branch role metadata；
- deploy directions。

### 禁止
- 改 river；
- 新桥；
- route damage/resource bonus；
- 改 command chamber；
- 改 gate projectile openness。

---

## P0-05A3 — Branch Failure Scenarios

真实 runtime 至少手测：

1. Main connected + Branch connected；
2. Main upstream offline + Branch connected；
3. Branch upstream offline + Main connected；
4. both frontline paths offline；
5. Core fallback still works；
6. reconnect does not require recapture of still-owned downstream support。

---

## P0-05B1 — Legacy Stronghold Consumer Cut First

先切 consumer，后清 producer。

第一阶段让正式 gameplay 不再读取旧 bonus：

- Draft choice count 不再由 Lab 变 4；
- volley shot count 不再吃 Factory bonus；
- attack level 不再吃 Energy bonus。

### 为什么 consumer-first
这样可以证明：

> 即使旧 `sample_bonuses()` 仍临时返回数据，它已经不再具有 gameplay authority。

比一边删 producer 一边改 consumer 更容易定位回归。

---

## P0-05B2 — Legacy Stronghold Producer Demotion

consumer 已验证后：

- `CardfrontStrongholdSystem` 不再作为通用 reward authority；
- compatibility shell 如果保留，必须明确标 `legacy/non-authoritative`；
- 不得把旧 effect 换名字继续输出。

---

## P0-05B3 — UI/Text Semantic Cutover

再处理：

- `CardfrontThreeChoicePanel` 的实验室四选一文案；
- `CardfrontRegionInfoPanel` 的 80% 激活/据点能力文案；
- 任何 `Factory/Energy/Lab` 仍暗示 bonus 的 badge/text。

### 注意
这里改的是**语义准确性**，不是全局 UI redesign。

---

## P0-05B4 — Save Compatibility Cleanup

最后检查 `CardfrontRuntimeSnapshot`：

- 新 gameplay 不再读取旧 stronghold bonus；
- legacy field 可按兼容需要继续 decode；
- 新 support state 有独立字段/owner；
- restore 后 connectivity 重算；
- 不允许旧 `current_stronghold_bonuses` 覆盖新 support state。

---

## P0-05B5 — Global Legacy Search Gate

必须全局搜索至少：

```text
FACTORY_SHOT_BONUS
ENERGY_ATTACK_LEVEL_BONUS
LAB_DRAFT_CHOICE_COUNT
current_stronghold_bonuses
apply_to_volley_plan
_draft_choice_count
实验室加成
据点能力
```

每个命中必须分类：

```text
A. active gameplay consumer -> 不允许残留
B. compatibility/read-only -> 允许但要注释
C. tests/docs/history -> 允许
```

禁止只看“代码能跑”就宣布 cutover 完成。

---

# 9. Batch A Checkpoint 额外字段

P0-00～P0-05 的 checkpoint 在原模板基础上再增加：

```text
Test evidence authority:
Stable IDs introduced/used:
Runtime numeric IDs used as identity? YES/NO
Territory capture touched? YES/NO + why
Creature movement legality touched? YES/NO + why
All spawn paths checked:
- preview
- commit
- AI
- automatic/upgrade spawn
Derived states persisted as authority? YES/NO
Legacy stronghold active consumers remaining:
Save compatibility impact:
```

只要出现：

```text
Creature movement legality touched = YES
```

或：

```text
Territory capture touched = YES
```

而当前 micro-step 不是显式 Amendment，默认 NO-GO。

---

# 10. 本批完整执行顺序

禁止跳序：

```text
P0-00A Ownership Map
P0-00B Manual Baseline
P0-00C Delta Ledger
P0-00D Test Harness Truth
P0-00E Golden Baseline

P0-01A1 Stable Support IDs
P0-01A2 Runtime Truth Table
P0-01B1 Anchor -> runtime region mapping
P0-01B2 Metadata validation

P0-02A1 Contributor DTO
P0-02A2 Capture profile mapping
P0-02A3 Diminishing aggregator
P0-02B1 Pure state machine
P0-02C1 Registry occupancy adapter
P0-02C2 One-support territory-gated prototype
P0-02D Snapshot contract

P0-03A1 Topology contract
P0-03A2 Graph validation
P0-03B1 Pure resolver
P0-03B2 Truth fixtures
P0-03C1 Revisioned cache

P0-04A1 Query/result extension
P0-04A2 Core fallback
P0-04A3 Directional support zones
P0-04B Player commit
P0-04C Preview
P0-04D AI
P0-04E Automatic spawn path
P0-04F Four-consumer parity

P0-05A1 Pure branch fixture
P0-05A2 Default map binding
P0-05A3 Runtime branch failure cases
P0-05B1 Legacy consumers cut
P0-05B2 Producer demotion
P0-05B3 UI semantic cutover
P0-05B4 Save compatibility
P0-05B5 Global legacy search gate
```

任何一个 step `NO-GO`：

> **回到当前 owner 修复，不向下执行，不通过增加卡牌/奖励/UI补丁绕过。**

---

# 11. Batch A 最终北极星复核

完成 P0-05 后，必须能同时回答 Yes：

1. Support 的稳定身份不依赖 runtime region_id。
2. Support Capture 没有污染 projectile territory capture pipeline。
3. Creature 全局移动规则没有被暗中改成自由跨线。
4. 单位仍能通过实际战场推进进入支点争夺范围。
5. 所有单位出生路径都受同一个 Deployment authority 约束。
6. Core fallback 始终存在。
7. Branch 是 alternate battle-line path，而不是奖励路线。
8. Legacy Factory/Energy/Lab bonus 不再影响正式 gameplay。
9. Save compatibility 与 gameplay authority 已明确分离。
10. 自动测试证据来自一个固定 runner，而不是每步临时自证。

任一项不能明确 Yes：P0-05 不得宣布完成。
