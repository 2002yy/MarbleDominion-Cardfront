# Cardfront P1 Execution Detail — Batch A — 2026-08-08

状态：**MANDATORY P1 DESIGN/EXECUTION ADDENDUM — ELIGIBLE POOL / ROUTE SIGNALS / DEEP ROUTE SLOTS**  
适用：P1-00 ～ P1-03  
前置条件：**只有 `P0-11O_P0_FINAL_GO_NO_GO.md` 明确 `Final decision: GO` 后，本文才允许作为实现入口。**

上位文档：

1. `CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`
2. `CARDFRONT_P0_EXECUTION_GUARDRAILS_2026-08-07.md`
3. `CARDFRONT_P0_EXECUTION_DETAIL_BATCH_A/B/C_2026-08-08.md`
4. 本文
5. `CARDFRONT_REFACTOR_PLAN_2026-08-07.md`

> P1 不再重构 P0 已冻结的 Support / SupportGraph / DeploymentRules / Draft Preview / Offer side isolation / Selected Level / AIObservation 权威。
>
> **P1 的任务是让“双方怎样逐渐变成不同军队”成立，而不是为了做路线系统重新打开底层规则。**

---

# 0. P1 Batch A 北极星

本批只回答三个问题：

1. **哪些卡现在有资格进入某一方的 3 选 1？**
2. **实际战场行为怎样形成路线倾向与路线解锁？**
3. **“一局最多两条深度路线”怎样成为稳定数据合同，而不是后台分数随意锁死？**

本批明确**不做**：

- reroll；
- Diversity / Dominance Guard 正式实现；
- 每卡 Lv1～Lv5 完整升级轨；
- 全量路线卡内容；
- 精确平衡费用；
- Easy/Normal AI 强度升级；
- Hard AI；
- Airborne / Infiltration 等 P2 越线部署；
- 第四种、第五种卡牌来源。

---

# 1. 从旧实现出发：P1 必须先解决的迁移冲突

## 1.1 当前 Draft 的候选池 authority 是 `deck_id`

当前链路：

```text
CardfrontFactionRunState.deck_id
 -> CardfrontUpgradeDeckRegistry.get_upgrade_ids(deck_id)
 -> CardfrontUpgradeDraftSystem._deck_upgrade_ids(run_state)
 -> eligibility
 -> weighted draw
```

旧 Registry 当前有：

```text
core_tactics
fortification_corps
barrage_control
```

这三套牌池会直接改变某一方能抽到哪些卡。

而冻结后的 P1 设计是：

```text
双方相同 BasePool
+ 各自 Hero source
+ 各自本局解锁 Route source
= 各自 EligiblePool
```

所以：

> **旧 `deck_id -> exclusive card list` 不能继续作为 P1 正式 Draft eligibility authority。**

否则会出现：

```text
Player 从 fortification deck 起步
AI 从 barrage deck 起步
```

这与“双方一开始拥有相同基础卡池”冲突。

---

## 1.2 旧 DeckRegistry 可以暂存，但必须降级

P1 默认迁移目标：

```text
CardfrontUpgradeDeckRegistry
旧职责：决定完整候选池
新状态：legacy/compatibility/audit shell，或只保留历史定义
```

P1 正式候选池不得再通过：

```text
get_upgrade_ids(deck_id)
```

直接决定全部卡。

允许旧 `deck_id` 暂时存在于：

- save compatibility；
- historical audit；
- UI migration bridge；
- telemetry comparison。

禁止它继续：

- 删除 BasePool 中本应双方共有的卡；
- 成为第四种 card source；
- 给某一方隐藏额外路线卡；
- 作为“英雄职业牌”的替代实现。

如果当前 Prematch UI 仍允许选 Deck，P1-01A 必须先审计真实 consumer，再决定：

- retire；或
- 仅转为推荐构筑展示/历史入口。

**不得未经设计 Amendment 把它重新解释成第四类来源。**

---

## 1.3 当前 HeroRegistry 只有数值/炮弹身份，没有 card-source schema

当前 Hero 定义包含：

- base volley；
- projectile mix；
- chamber health；
- defense；
- strategic identity。

P1 需要显式新增“英雄带来的卡牌资格”，不能靠 hero 名字硬编码 `match`。

冻结建议 schema：

```text
hero_offer_card_ids
hero_starting_owned_card_ids   # 可为空，只有确实设计为开局直接拥有时才填
```

语义：

### `hero_offer_card_ids`

从第一轮 Draft 起即可进入该英雄的 EligiblePool。

### `hero_starting_owned_card_ids`

确实属于“开局自动带有/已拥有”的极少数卡。

禁止把二者混为一谈。

> **“英雄附带卡”必须在数据中明确是“可候选”还是“已拥有”，不能让实现者临场猜。**

---

# 2. 三类 Card Source：P1 唯一来源模型

正式来源只有：

```text
BASE
HERO
ROUTE
```

其中所谓“阵营卡 / 路线卡”在本模型中统一归到 `ROUTE` source；暂不再分第四类 Faction source。

## 2.1 BASE

性质：

- 双方相同；
- 对局开始即 eligible；
- 不依赖英雄；
- 不依赖路线；
- 是最低构筑公共语言。

硬不变量：

> 相同版本、相同规则模式下，Player 与 AI 的 BasePool card ID 集合必须相同。

随机 Offer 可以不同，但 BasePool authority 不同是不允许的。

---

## 2.2 HERO

性质：

- 由 hero identity 决定；
- 从开局就形成差异；
- 不依赖本局行为解锁；
- 不占 Route 深度槽；
- 不能成为另一套完整互斥 deck。

英雄卡的目标是回答：

> **“我是谁？”**

而不是：

> “我这一局已经选定整套 18 张牌。”

P1 初版禁止一个 Hero 自带过大的独占卡池，以免重新复活旧 `fortification_corps / barrage_control` 互斥 deck 逻辑。

---

## 2.3 ROUTE

性质：

- 对局开始默认未解锁；
- 主要由实际战场行为形成；
- 卡牌选择只做辅助倾向；
- 解锁后只是加入未来 EligiblePool；
- 不直接发卡；
- 不额外增加 Draft 次数。

路线回答：

> **“这一局我正在变成什么？”**

---

# 3. `EligiblePoolBuilder` 成为唯一资格组合 authority

P1 必须建立一个明确的资格组合层。命名可调整，但职责必须单一。

推荐：

```text
EligiblePoolBuilder
```

输入：

```text
side_id
BasePool definition
Hero identity/source
RouteUnlockState
SelectedLevel/read-model
legacy eligibility state needed by existing card effects
```

输出：

```text
EligiblePoolSnapshot
```

其中每张 card ID 只出现一次。

---

## 3.1 Provenance 与 Identity 分离

同一张卡可能因为多个来源都满足资格，例如：

```text
某卡既属于 Base，也被某 Hero 推荐/引用
```

最终 EligiblePool：

```text
card_id: one identity
sources: [BASE, HERO]
```

禁止：

```text
BASE 中一份
HERO 中再塞一份
=> 同 ID 在 candidate list 出现两次
=> 隐式提高抽到概率
```

是否因为多来源提高 weight 属于 P1 Batch B 的 Soft Weight 设计，不能通过“重复 ID”偷实现。

---

## 3.2 Eligibility 与 Weight 严格分层

Batch A 只决定：

```text
Can this card be considered?
```

不决定：

```text
How likely is this card to be sampled?
```

因此：

```text
EligiblePoolBuilder
 -> card IDs + provenance + eligibility reasons

OfferWeightPolicy (Batch B)
 -> probability weights
```

禁止 `EligiblePoolBuilder` 因“主路线比较重要”复制 card ID 或直接随机。

---

## 3.3 Eligibility result 必须可解释

建议每个 candidate 带只读 debug reason：

```text
card_id
eligible
source_tags
unlock_reason
blocked_reason
```

Player UI 不需要显示内部 reason；用于测试/调试。

典型 blocked reason：

```text
route_not_unlocked
route_deep_not_committed
hero_mismatch
selected_level_cap_if_formally_authored
legacy_effect_state_cap
```

注意：

> P1 不允许把所有旧 effect cap 自动升级成 card max-level cap。

Selected Level 与旧 effect eligibility 继续分权。

---

# 4. P1-00：P0 -> P1 Handoff Gate

## P1-00A — Verify P0 Seal

唯一允许的 source commit：

```text
P0-11O_P0_FINAL_GO_NO_GO.md
 -> P1 allowed start commit
```

如果：

- P0 final = NO-GO；
- 没有 final checkpoint；
- P1 start commit 与 P0 seal 不一致；

则 P1 不得编码。

---

## P1-00B — P0 Authority Read-Only Ledger

P1 开工前列出下列 owner，并默认**只读调用，不重构**：

```text
Support domain/state
SupportGraph/connectivity
DeploymentRules
Draft Preview display state
Per-side RNG isolation
Selected Level authority
AIObservationBuilder
RoundDirector phase orchestration
Command Point
GateConnectivity projectile passage
```

如果 P1 某步骤必须修改其中之一：

1. 写原因；
2. 证明不是为了“路线实现方便”；
3. 重新跑受影响 P0 Evidence Matrix；
4. 需要时开 Engineering Amendment。

禁止直接顺手改。

---

## P1-00C — Legacy Deck Consumer Audit

扫描：

- `CardfrontUpgradeDeckRegistry`；
- `run_state.deck_id`；
- Prematch/hero/deck UI；
- AI deck usage；
- ValuePolicy 中 deck-dependent scoring；
- save schema；
- B1 simulation/audit tests。

产出：

```text
consumer
current meaning
P1 target meaning
preserve / migrate / retire / compatibility
```

没有这份表，不得 P1-01 cutover。

---

# 5. P1-01：三层 Eligible Pool Cutover

## P1-01A — Define BasePool Registry

目标：建立一份双方共用的 BasePool card ID authority。

可以：

- 从旧 core_tactics 中挑选/迁移基础卡；
- 使用新 `CardSourceRegistry` / `BasePoolDefinition`；
- 暂时复用 immutable Manifest card definitions。

禁止：

- Player/AI 两份 BasePool；
- Hero 决定 BasePool 删除项；
- Route 未解锁就把 route card 放 BasePool；
- 复制整份 Manifest。

### Gate

固定 build 下：

```text
PlayerBaseIDs == AIBaseIDs
```

---

## P1-01B — Hero Card Source Schema

在 Hero definition 或专用 HeroCardSource registry 中明确：

```text
hero_offer_card_ids
hero_starting_owned_card_ids
```

要求：

- 所有 ID 必须存在于 Manifest；
- 不允许 duplicate ID；
- 不把路线 Tier 信息塞进 Hero source；
- 不自动创建新卡效果。

### Starting owned 规则

如果某 Hero `starting_owned_card_ids` 非空：

- 初始化时写入 Selected Level authority；
- 必须明确初始 level，一般为 Lv1；
- 不能通过伪造一次 Draft selection 来实现；
- 不触发 `card_selected` telemetry；
- 可触发专门 `starting_card_granted`。

这样避免：

> 开局赠卡被系统误认为“本轮玩家选择”，污染 route signal / pick rate。

---

## P1-01C — Route Card Source Schema

每张 Route card 至少声明：

```text
route_id
route_tier   # TIER1 / DEEP
```

P1 初版不增加多层复杂稀有度树。

禁止：

```text
route_tier = 2.5
subroute_level = 7
prestige_route
```

除非后续设计明确增加。

---

## P1-01D — EligiblePoolBuilder Pure Function

推荐输出：

```text
EligiblePoolSnapshot
- side_id
- base_ids
- hero_ids
- route_ids
- unique_candidate_ids
- provenance_by_id
- blocked_by_id (debug/test)
- revision
```

要求：

- pure/read-only；
- 不消费 RNG；
- 不修改 RouteState；
- 不修改 Level；
- 不触发解锁；
- 不根据当前敌人偷偷放 counter card。

---

## P1-01E — DraftSystem Consumer Cutover

目标链路：

```text
RoundDirector
 -> build side DraftOfferContext
 -> EligiblePoolBuilder
 -> DraftSystem draw from eligible IDs
```

旧：

```text
DraftSystem -> DeckRegistry.get_upgrade_ids(deck_id)
```

正式 gameplay 中退役。

### Cutover gate

在同一 commit 中：

- 新 EligiblePool 正式 authoritative；
- 旧 deck exclusive filtering 不再影响正式 Offer；
- 旧 deck compatibility 仍可读但不能左右 eligibility；
- active tests 已迁移。

禁止长期双 authority。

---

## P1-01F — Pool Identity / Duplication Tests

必须覆盖：

1. 双方 BasePool 相同；
2. 不同 Hero 只增加自己的 Hero source；
3. 未解锁 Route 不进入；
4. Tier1 已解锁才进入 Tier1；
5. Deep 未 committed 不进入 Deep；
6. 同 ID 多来源只出现一次；
7. 修改 Player source state 不影响 AI pool；
8. pool build 不消费 RNG；
9. pool build 不改变 RouteState；
10. legacy deck_id 变化不再删除公共 Base card。

---

# 6. Route Domain：事实事件、路线映射、状态三层分权

P1 路线系统必须拆成三层：

```text
Battlefield Domain Event
        ↓
RouteSignalMapper
        ↓
RouteProgressionState
```

三层不能合并。

---

## 6.1 Battlefield Domain Event = 事实

战斗/支点/部署系统只负责报告发生了什么。

例如：

```text
unit_deployed
support_capture_completed
support_defended
branch_support_connected
fortification_broken
heavy_unit_effective_contact
fire_support_effective
rapid_recapture
```

事件里可以有客观上下文：

```text
event_id
owner_id
event_type
timestamp/round
subject_id
support_id
lane/route spatial tag
objective outcome
magnitude if objectively measurable
```

禁止 gameplay owner 直接写：

```text
mobility_score += 3
control_route_unlock = true
```

因为这会让路线规则散落在 Creature / Support / Card / Projectile 代码中。

---

## 6.2 RouteSignalMapper = 策划解释层

只有这一层把事实解释为路线倾向。

示意：

```text
BRANCH_SUPPORT_CAPTURED
 -> mobility + weight
 -> control + smaller weight
```

```text
HEAVY_BREAKTHROUGH_SUCCESS
 -> heavy + weight
```

```text
SUPPORT_DEFENDED
 -> control + weight
 -> fortification + optional smaller weight
```

具体 weight 属 tuning，不在 Batch A 锁死。

硬要求：

- mapping 集中；
- data-driven 或集中 registry；
- 同一 event -> route contributions 可测试；
- 不能每张卡各写自己的 route score 逻辑。

---

## 6.3 RouteProgressionState = 本局私有状态

建议每方：

```text
RouteProgressionState
- tendency_score_by_route
- tendency_band_by_route
- tier1_unlocked_routes
- deep_qualified_routes
- deep_committed_routes
- deep_slot_limit = 2
- processed_event_ids / dedupe cursor
- revision
```

其中：

### exact score

内部私有。

### tendency band

玩家自己的粗粒度 UI：

```text
未形成
正在形成
接近解锁
已解锁
```

对手不得读取 exact score。

---

# 7. P1-02：Battle Behavior -> Route Progression

## P1-02A — Event Taxonomy Audit

在新增 RouteEventBus 前，先审计现有：

- support telemetry/events；
- deployment accepted；
- entity runtime；
- projectile/volley results；
- territory changes；
- card_selected/card_leveled；
- RoundDirector phase events。

目标：尽量消费已有事实事件，不重复创建第二套事件。

输出：

```text
needed route fact
existing event available?
new event needed?
authority owner
payload
```

---

## P1-02B — Stable Event Identity / Dedupe

Route progression 不能因为：

- signal 重连；
- save/restore；
- replay/debug；
- 同一事件被多个 adapter 转发；

重复加分。

所以每个可累计事实必须拥有：

```text
stable event_id
```

或等价 monotonic cursor。

Route processor 必须保证同一事实最多处理一次。

---

## P1-02C — RouteSignalMapper Pure Mapping

输入：

```text
BattlefieldEvent
```

输出：

```text
[RouteSignalContribution]
```

示例结构：

```text
route_id
source_event_id
weight
reason_code
```

Mapper 不：

- 修改 RunState；
- 解锁卡；
- 生成 Offer；
- 给额外 Draft；
- 改 Support/Deployment；
- 直接更新 UI。

---

## P1-02D — Actual Behavior Must Dominate Card Selection

冻结原则：

> **实际战场行为是主要依据，选卡只做辅助条件。**

因此 Route mapper 必须区分 contribution source：

```text
BATTLE_BEHAVIOR
CARD_SELECTION_AUX
```

P1 初版必须存在结构性限制，防止：

```text
连续选 2 张 mobility 卡
但战场完全没打侧翼
=> 自动深度机动路线
```

具体比例/上限未冻结，但至少要求：

- 仅靠 CARD_SELECTION_AUX 不能直接完成 Deep commitment；
- Tier1 是否允许仅靠辅助达到，需要在路线 definition 中显式配置，默认推荐“不允许”；
- Deep qualification 必须包含真实 behavior evidence。

这比写一个全局 `selection_weight = 0.3` 更安全。

---

## P1-02E — Anti-Farm / Repetition Saturation Contract

路线不能鼓励玩家刷隐藏任务。

同类事件重复发生必须支持：

- 时间/回合窗口；
- diminishing contribution；或
- per-window cap；
- objective-quality gate。

例如禁止：

```text
在无战略意义的位置反复部署快速单位 20 次
=> mobility deep route
```

或：

```text
同一支点来回故意放弃/夺回
=> control 无限加分
```

精确曲线不冻结，但 Route Definition 必须可以表达 anti-farm policy。

---

## P1-02F — Route Tendency Bands

内部 exact score 可连续；玩家 UI 只使用 band。

建议逻辑概念：

```text
score < A        -> 未形成
A <= score < B   -> 正在形成
B <= score < C   -> 接近解锁
Tier1 unlocked   -> 已解锁
```

具体 A/B/C 属 tuning。

禁止 UI 显示：

```text
7.43 / 10.00
```

避免玩家把对局变成刷任务表。

---

## P1-02G — Sticky Unlock Contract

一旦某路线 Tier1 在本局正式解锁：

```text
Tier1 unlocked = sticky for this match
```

之后 tendency 数值即使因调优/衰减变化，也不得悄悄把已解锁卡重新锁回去。

Deep committed 同样 sticky。

如果未来要做“失去路线资格”，必须是新设计，而不是 tuning side effect。

---

## P1-02H — Unlock Does Not Grant / Does Not Add Draft

当 Tier1 解锁：

允许：

```text
RouteState changed
 -> EligiblePool revision
 -> future Drafts may include route cards
```

禁止：

```text
立即塞卡到手里
立即 Level+1
立即追加一轮 Draft
立即免费 reroll
```

战场行为决定：

> **解锁什么。**

不是：

> **多抽几次。**

---

# 8. Route Definition Contract

每条 P1 代表路线至少声明：

```text
route_id
name
player-facing tendency label
battle_behavior_signal_rules
tier1_unlock_rule
deep_qualification_rule
tier1_card_ids
deep_card_ids
anti_farm_policy
```

可以另有 tuning weights。

禁止在 Route Definition 中塞：

- Draft cadence；
- Support topology；
- DeploymentRules override；
- AI cheat；
- generic damage multiplier；
- 第三条 Deep slot。

---

# 9. Route Unlock 与 Card Level 严格分离

路线解锁：

```text
card becomes eligible
```

卡牌 Level：

```text
card was actually selected / granted by explicit starting-card rule
```

因此：

```text
unlock route
!= own all route cards
!= Lv1 all route cards
```

禁止 RouteState 修改 `selected_upgrade_levels`。

---

# 10. 多路线并存合同

冻结：

- 一局可同时形成多种倾向；
- 可同时解锁多条 Tier1 路线；
- 真正深入发展的路线最多 2 条；
- 非 Deep 路线的 Tier1 卡并不会因为两个 Deep slot 已满而全部消失。

也就是说：

```text
Route A = Deep
Route B = Deep
Route C = Tier1 unlocked
Route D = tendency forming
```

是合法状态。

禁止：

```text
两个 Deep slot 满
=> 其他路线整个卡池清空
```

除非具体卡自己有互斥设计，而 P1 初版不建议大量做互斥。

---

# 11. P1-03：Deep Route Slot Contract

## 11.1 已冻结部分

已经确认：

```text
DEEP_SLOT_LIMIT = 2
```

含义：

- 真正 Deep tier 最多两条；
- Deep route 承载真正强牌；
- 强牌不是一次性观光奖励；
- Deep 强牌仍受角色分工限制，不能 Combat/Mobility/Control 全顶。

---

## 11.2 唯一尚未完全冻结的细节：什么时候“占用”Deep slot

历史 GrillMe 已确认“最多两条”，但没有最终确认：

```text
自动取 tendency 最高的两条
```

还是：

```text
行为达标后由玩家确认深入
```

**本文不把未确认事项伪装成已确认。**

P1-03A 必须是独立 Design Decision Gate。

---

## P1-03A — Deep Commitment Decision Gate

默认推荐：

```text
behavior qualifies route
 -> route becomes DEEP_QUALIFIED
 -> 玩家在明确时机确认“深入该路线”
 -> consume one deep slot
 -> route becomes DEEP_COMMITTED
```

理由：

- 行为决定“你有资格成为什么”；
- 玩家决定“我是否真的把这一局押在这里”；
- 避免后台 tendency 误判把玩家锁进路线；
- 保留构筑主动性；
- 选卡本身仍不能凭空制造资格。

主要代价：

- 需要一个很轻的确认 UI/交互；
- AI 需要自己的合法 commitment policy。

替代 A：自动取最高两条。

风险：

- 玩家可能在不知情时消耗 slot；
- 行为噪音导致永久锁定；
- 容易产生“系统替我构筑”的感觉。

替代 B：选到任意路线卡就占 slot。

风险：

- 违反“实际行为主要、选卡只辅助”；
- 一张偶然 Offer 就可能锁死整局。

### Gate

在该选择被产品设计明确确认前：

- 可以实现 `DEEP_QUALIFIED` 数据状态；
- 不允许正式消费 Deep slot；
- 不允许 Deep cards 进入正式 EligiblePool。

---

## P1-03B — Deep Qualification Is Not Commitment

数据必须分开：

```text
deep_qualified_routes
deep_committed_routes
```

禁止一个 bool：

```text
route.deep = true
```

同时表示“有资格”和“已占槽”。

---

## P1-03C — Slot Capacity Contract

如果：

```text
deep_committed_routes.size() == 2
```

那么第三条路线：

- 仍可形成 tendency；
- 仍可 Tier1 unlocked；
- 仍可达到 DEEP_QUALIFIED（可选：保留 qualification 作为反馈）；
- 但不得进入 DEEP_COMMITTED；
- 其 deep_card_ids 不进入 EligiblePool。

UI 应表达：

> 已达深入资格，但深度槽已满

而不是静默失败。

---

## P1-03D — Commitment Is Sticky

P1 初版一旦 committed：

```text
本局不可免费撤销/换槽
```

原因：

- 否则玩家可频繁切换 Deep pool，规避“最多两条”的战略代价；
- route identity 失去意义；
- Offer pool 可被反复操纵。

未来如需 respec，必须是显式稀缺机制/新设计。

P1 初版不做。

---

## P1-03E — Commitment Does Not Grant a Card

Deep commit 后只发生：

```text
EligiblePool revision
 -> deep cards now may appear
```

不发生：

```text
直接获得 Deep card
额外 Draft
自动 reroll
免费 Level
```

---

# 12. AI 与 Deep Route：P1 Batch A 只冻结权限，不提高智力

AI 的 RouteProgressionState 是自己的私有状态。

AI 可以读取：

- 自己 exact tendency；
- 自己 Tier1 unlock；
- 自己 deep qualification/commitment；
- 公开战场事实。

AI 不可读取：

- Player exact tendency；
- Player hidden qualification；
- Player future commitment；
- Player private Offer。

若采用显式 Deep commitment：

AI 通过一个独立 `RouteCommitmentPolicy` 做选择。

P1 Batch A 只建立接口，不做 Easy/Normal 高级策略。

默认 policy 可以：

- 只在已有合法 qualification 中选择；
- deterministic / testable；
- 不偷看玩家路线秘密。

---

# 13. Route UI 边界

P1 Batch A 只允许粗粒度反馈。

推荐位置：

- Draft；
- 卡组/构筑查看；
- 小型路线图标区域。

默认战场不常驻大路线面板。

玩家最多优先显示当前最明显的 2 个 tendency。

允许：

```text
机动：正在形成
控制：接近解锁
重装：已解锁
```

禁止：

```text
机动 8.73 / 10
本回合再占 1.27 个点即可解锁
```

Deep qualified/committed 必须有明确但简洁状态。

---

# 14. Save / Restore Contract

P1 新状态至少需要保存：

```text
tier1_unlocked_routes
deep_qualified_routes
deep_committed_routes
route progression raw state required for exact continuation
processed event cursor/dedupe state if necessary
```

如果 tendency score 属于 authoritative progression，则保存。

如果某些 display band 是 derived，则 restore 后重算。

禁止：

- save restore 后重新处理历史事件再加一遍分；
- route unlock 丢失；
- committed slot 丢失；
- 旧 save 缺 route 字段直接 crash。

旧 save 默认：

```text
no route progression
no unlock
no commitment
```

除非另有迁移依据。

---

# 15. Telemetry Contract

P1 Batch A 新增/完善：

```text
route_signal_event
route_tendency_band_changed
route_tier1_unlocked
route_deep_qualified
route_deep_committed
eligible_pool_rebuilt
```

每个事件至少含：

```text
owner_id
route_id if relevant
round/timestamp
event/reason code
```

禁止每次 score 浮点变化都打 telemetry。

记录状态跃迁，而不是数值噪音。

---

# 16. P1 Batch A 测试矩阵

## 16.1 Pool tests

- Player/AI BasePool IDs identical；
- Hero source 按 hero 不同；
- Route source 初始为空；
- Tier1 unlock 后未来 pool 增加对应 cards；
- Deep qualified 未 committed 时 deep cards 仍 blocked；
- Deep committed 后 deep cards eligible；
- 多来源同 ID 不重复；
- pool build 不消费 RNG；
- pool build 不改变 progression；
- old deck_id 不再成为 exclusive eligibility authority。

## 16.2 Route mapper tests

- factual event -> deterministic contributions；
- same event_id 不重复处理；
- unrelated event 不加 route；
- card-selection contribution 标为 AUX；
- 只靠 AUX 不得直接形成 Deep commitment；
- anti-farm policy 对重复行为有界。

## 16.3 Progression tests

- tendency 多路线可并存；
- Tier1 unlock sticky；
- unlock 不直接发卡；
- unlock 不增加 Draft 次数；
- exact score 与 player-facing band 分离；
- opponent exact score 不进入 AI observation/public UI。

## 16.4 Deep slot tests

在 P1-03A 决策确认后：

- qualification != commitment；
- commit 消耗一个 slot；
- 最多 2；
- 第三条可 Tier1 但不可 Deep；
- committed sticky；
- commit 不自动 grant card；
- AI commit 只读合法信息。

## 16.5 Save tests

- route state round-trip；
- dedupe cursor round-trip；
- old save 缺字段安全默认；
- restore 不重复加分。

---

# 17. P1 Batch A Integration Scenarios

## A1 — Same base, different hero

Player 与 AI：

- BasePool 相同；
- Hero 不同；
- 首轮 Offer 过程独立；
- Hero source 形成有限差异。

验证不是“两个完全不同旧 deck”。

---

## A2 — Behavior unlocks possibility

玩家多次完成有效侧翼/快速支援行为：

```text
mobility tendency rises
 -> Tier1 mobility unlock
 -> future pool adds mobility cards
```

当轮：

- 不直接发卡；
- 不额外 Draft；
- 不强制下一 Offer 出 mobility。

---

## A3 — Selection without behavior cannot fake deep route

玩家反复选择带 mobility 标签的通用/英雄卡，但没有真实侧翼/快速行为。

要求：

- 可以有辅助 tendency；
- 不得仅凭选卡完成 Deep qualification/commitment。

---

## A4 — Multi-route shallow state

同一局形成：

```text
mobility Tier1 unlocked
control Tier1 unlocked
heavy forming
```

要求系统正常，不强制立刻选唯一职业树。

---

## A5 — Two deep routes + third shallow

最终：

```text
mobility Deep committed
control Deep committed
heavy Tier1 unlocked
```

Heavy Tier1 卡仍可以出现；Heavy Deep 卡不可出现。

---

## A6 — Save/restore before/after qualification

在：

- tendency forming；
- Tier1 unlocked；
- Deep qualified；
- Deep committed；

几个阶段分别 snapshot/restore。

要求状态一致且不重复计分。

---

# 18. P1 Batch A Drift Checks

每个 micro-step 后必须回答：

1. 是否仍是相同 BasePool 起步？
2. Hero 是否只是 identity source，而不是整套互斥 deck？
3. Route 是否由实际行为主导？
4. 选卡是否仍只是辅助，而非隐藏解锁捷径？
5. Route unlock 是否仍只是“可能性”？
6. 是否没有额外增加 Draft 次数？
7. 是否没有把 route score 写进 gameplay owner？
8. 是否没有把 exact route score 暴露给对手 AI？
9. 是否保留最多 2 条 Deep？
10. 是否没有因为 P1 路线方便而绕过 P0 DeploymentRules？
11. 是否没有让旧 `deck_id` 成为第四种来源？
12. 是否没有偷跑 reroll / full upgrade tracks / Hard AI？

任一失败：NO-GO。

---

# 19. P1 Batch A Micro-step 顺序

```text
P1-00A verify P0 seal
P1-00B P0 authority read-only ledger
P1-00C legacy deck consumer audit
   ↓
P1-01A BasePool authority
P1-01B Hero source schema
P1-01C Route source schema
P1-01D pure EligiblePoolBuilder
P1-01E Draft consumer cutover
P1-01F pool tests
   ↓
P1-02A event taxonomy audit
P1-02B stable event identity/dedupe
P1-02C RouteSignalMapper
P1-02D behavior-vs-selection source separation
P1-02E anti-farm contract
P1-02F tendency bands
P1-02G sticky Tier1 unlock
P1-02H pool revision only
   ↓
P1-03A deep-slot commitment design gate
P1-03B qualification/commitment split
P1-03C slot capacity
P1-03D sticky commitment
P1-03E deep pool eligibility cutover
   ↓
P1-A final regression/checkpoint
```

同一依赖链不得跳步。

---

# 20. P1 Batch A 最终 GO 条件

只有以下全部满足才进入 Batch B：

1. P1 起点来自 P0 final GO commit；
2. P0 authorities 无未经许可重写；
3. BasePool 双方完全一致；
4. 旧 exclusive deck filtering 已退出正式 eligibility authority；
5. Hero source 可审计且没有变成完整互斥 deck；
6. Route source 只有实际解锁后才进入；
7. Battlefield event 与 RouteSignalMapper 分权；
8. 实际行为贡献是主路径，选卡仅辅助；
9. anti-farm 有结构性保护；
10. Tier1 unlock sticky，且只改变未来资格；
11. 多种路线可并存；
12. Deep qualification 与 commitment 数据分离；
13. 最多两个 Deep slot；
14. Deep commit 不发卡、不增加 Draft；
15. exact route score 不泄露给对方 AI；
16. save/restore 不重复计分；
17. reroll / Offer Guards / full card upgrade track 尚未偷跑。

---

# 21. 未冻结常数 / 必须留到实测

Batch A 故意不锁死：

- route signal weight；
- tendency band threshold；
- anti-farm diminishing curve/window；
- Tier1 threshold；
- Deep qualification threshold；
- 各 Hero 到底带几张 offer cards；
- 代表路线正式卡数量。

这些必须集中在 data/tuning，并通过 P1 representative-route tests 校准。

禁止散落 magic numbers。

---

# 22. 结论

P1 Batch A 的核心不是“做一棵技能树”。

真正结构是：

```text
公开战场事实
 -> 集中的 RouteSignalMapper
 -> 私有本局 RouteProgressionState
 -> 解锁资格
 -> EligiblePoolBuilder
 -> 后续 Draft 可能抽到
```

同时：

```text
Base = 双方公共起点
Hero = 开局身份差异
Route = 本局行为形成差异
Deep = 最多两条真正投入方向
```

任何实现如果变成：

```text
预选 deck 决定全部卡
选牌直接涨路线
达标立即发强卡
占点奖励额外抽牌
第三条第四条路线也能无限深入
```

都属于偏离冻结方向，而不是“合理扩展”。
