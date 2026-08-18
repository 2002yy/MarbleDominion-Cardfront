# Cardfront P1 Execution Detail — Batch C — 2026-08-08

状态：**MANDATORY P1 DESIGN/EXECUTION ADDENDUM — REPRESENTATIVE ROUTES / CADENCE / BALANCE / EASY-NORMAL AI / P1 FINAL GATE**

适用：P1-07 ～ P1-11

前置条件：

- P0 Final GO；
- P1-01 Legacy Deck -> `BASE + HERO + ROUTE` authority cutover GO；
- P1-02 Route Signal / Tier1 unlock GO；
- `CARDFRONT_P1_BATCH_A_DEEP_COMMITMENT_AMENDMENT_2026-08-08.md` 已生效；
- P1-03 Deep Commit GO；
- P1-04 Offer pipeline GO；
- P1-05 Reroll GO；
- P1-06 Per-card Upgrade Track GO。

上位文档：

1. `CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`
2. `CARDFRONT_P1_EXECUTION_DETAIL_BATCH_A_2026-08-08.md`
3. `CARDFRONT_P1_BATCH_A_ROUTE_CUTOVER_AMENDMENT_2026-08-08.md`
4. `CARDFRONT_P1_BATCH_A_DEEP_COMMITMENT_AMENDMENT_2026-08-08.md`
5. `CARDFRONT_P1_EXECUTION_DETAIL_BATCH_B_2026-08-08.md`
6. `CARDFRONT_P1_BATCH_B_REROLL_DECISION_AMENDMENT_2026-08-08.md`
7. 本文

> Batch C 不再创造新的底层系统。
>
> 它的任务是证明：**新构筑路线真的能形成不同军队、强卡真的强、弱卡仍有战争阶段价值、成长节奏来得及使用、AI 难度来自判断而不是作弊，并且这些结论可以通过固定场景和真实 telemetry 复核。**

---

# 0. Batch C 北极星

P1 最终要证明的不是“路线系统已经能显示几个状态”，而是完整闭环：

```text
same BasePool
+ Hero identity
+ actual battlefield behavior
+ independent Offer/Reroll
+ explicit Deep Commit
+ per-card Level tracks
        ↓
mid-match armies diverge
        ↓
Deep strong cards produce real payoff
        ↓
cheap/mobile/control tools still have valid reasons
        ↓
P0 battle-line map remains central
```

Batch C 必须持续保护：

- `Draft -> Aim -> Volley/Execution`；
- Command Point；
- Core fallback；
- SupportGraph / DeploymentRules authority；
- Base/Hero/Route source model；
- two Deep slot limit；
- one reroll per side per Draft；
- Selected Level vs effect application separation；
- Combat / Mobility / Control 分轴；
- AI Information Fairness。

Batch C 明确不做：

- 全路线目录；
- Hard AI；
- P2 Airborne / Infiltration / Forward Engineer 特殊越线规则；
- PvP network；
- Legendary copy limit；
- 付费 reroll；
- comeback bonus Draft；
- 第三条 Deep route；
- 统一综合 PowerScore；
- 为了模拟器方便重新启用旧 Deck。

---

# 1. 从当前实现出发：P1-C 必须继承而不是推倒的东西

## 1.1 当前 AI 已有明确 decision owner

当前链路：

```text
CardfrontAiCommander
 -> CardfrontAiUpgradePolicy
 -> CardfrontTacticalUpgradeValuePolicy
```

并已有：

- hero -> archetype；
- context-aware tactical adjustment；
- ranked evaluations；
- deterministic tie break。

P1-C 不创建：

```text
NewRouteAICommander
```

或第二套 AI decision runtime。

正式方向：

> 在 P0 已冻结的 `AIObservation` 边界内，把 Easy / Normal 的**决策预算与可用推理维度**接入现有 Commander/Policy 演进。

---

## 1.2 当前 AI ValuePolicy 仍依赖旧 Deck 语义

当前 `CardfrontTacticalUpgradeValuePolicy` 中仍可读取：

```text
deck_id
applied_upgrade_counts
```

并对非 `core_tactics` 做不同机会成本调整。

P1-01 cutover 后，这些旧 Deck-dependent AI 逻辑必须进入 migration audit。

Batch C 明确要求：

```text
legacy deck_id must not influence P1 AI decision
```

新的 AI 可以读取：

- Own Hero；
- Own Selected Levels；
- Own public/allowed RouteState；
- Own Deep commitments；
- public battle/support state；
- observed enemy public history；

但不能重新以旧 `deck_id` 作为 archetype/路线捷径。

---

## 1.3 当前 RunTuning 不是完整对局节奏模型

当前有：

```text
FIRST_AIM_SECONDS = 8
AIM_SECONDS = 12
DRAFT_SECONDS = 15
REVEAL_SECONDS = 2
```

这些是 phase timing，不等于“8–12 分钟对局”和“最后 1/3 成型”的完整证据。

因此 Batch C 不允许通过：

```text
round_number == 10
```

主观宣布“现在就是中期”。

必须同时记录：

- round；
- match elapsed time；
- remaining match fraction if available；
- first Tier1 / Qualified / Commit / Deep card selected / Deep card effective 时间点。

---

## 1.4 当前已有 B1 simulation/audit infrastructure

仓库已有：

- B1 balance audit runner；
- hero/card aggregation；
- map report；
- seed matrix；
- artifact output；
- structural parity gate。

Batch C 默认扩展/迁移这些基础设施，而不是重新建一个与正式玩法逻辑脱节的“P1 专用数学模拟器”。

但旧 B1 中依赖 legacy Deck/旧 card candidate 的指标，必须分类：

```text
PRESERVE
MIGRATE
REPLACE
HISTORICAL_ONLY
```

禁止为了历史曲线好看而让旧 Deck authority 回流。

---

# 2. P1-07：Representative Route Vertical Slices

P1 不先铺完整路线目录。

必须先用少量路线证明三个不同战略轴真的能够构筑出不同军队。

P1 validation route archetypes：

```text
MOBILITY / FLANK
BREAKTHROUGH / HEAVY-FIREPOWER
CONTROL / ENGINEERING
```

这里的名称是**验证角色**，不是强制最终世界观命名。

最终 route_id/name 可以在内容制作时命名，但战略责任不得丢。

---

# 3. 为什么首批验证三条，而不是十条

三条分别重点压测：

### Mobility / Flank

回答：

> 战线、分桥、转线和响应速度是否真的会让“机动力”成为独立价值？

### Breakthrough / Heavy-Firepower

回答：

> Deep 强卡能否真的突破正面上限，而不因为平衡焦虑被削成普通卡？

### Control / Engineering

回答：

> 当突破发生以后，便宜/控制/支援单位是否仍然负责把战果转化成支点和战线？

三者共同验证：

> **Combat / Mobility / Control 不是卡面上的三颗装饰星，而是实际改变战局的三个不同问题。**

---

# 4. Representative Route Definition Contract

每条验证路线必须具备：

```text
route_id
strategic_promise
primary_axis
secondary_axis
explicit_weak_axis
battle_behavior_signals
tier1_unlock_rule
deep_qualification_rule
tier1_card_ids
deep_card_ids
anti_farm_policy
player-facing tendency label
benchmark expectations
```

必须明确：

```text
what this route is best at
what it is merely okay at
what it deliberately does not solve
```

禁止路线描述只有：

```text
+10% damage
+15% speed
```

路线必须改变**战争处理方式**。

---

# 5. Minimum Route Content Slice

为了证明“Deep route 是一套真正的军队，而不是一张 SSR 奖杯”，每条代表路线最低建议验证：

```text
Tier1 cards: >= 2 distinct strategic reasons
Deep cards:  >= 2 distinct strategic reasons
```

即每条路线至少要能回答：

> 我深入这条路线后，为什么未来还会在同路线两张强卡之间犹豫？

禁止：

```text
route has 1 Tier1 filler
route has 1 Deep god card
```

这种结构无法验证 Offer / upgrade / route build 的真实选择空间。

精确最终卡数量属于内容扩展，不在 P1 锁死。

---

# 6. Mobility / Flank Route Validation Contract

该路线的核心不是“所有东西速度 +20%”。

必须至少覆盖两类价值：

```text
response / lane-switch speed
flank or support-network exploitation
```

典型卡牌角色可以包括：

- 快速轻型单位；
- 侧翼增援；
- 快速重新占领；
- 战线断裂后的快速响应。

P1 初版不引入 P2 的非法越线部署。

因此 Mobility Deep 卡仍必须遵守：

```text
DeploymentRules
current legal battle-line
```

禁止为了让“机动路线够强”直接给它普通单位越过战线出生。

这是 P2 特殊空降/渗透卡的设计空间。

### 强项

```text
Mobility = high / very high
Control = medium or situationally high
Combat = low to medium / selected Deep card may be high but not all
```

### 必须存在的弱点

至少一个：

- 正面持久火力不足；
- 重装对抗较弱；
- 单位脆；
- 占领后守不住；
- 高强度突破需要其他路线/基础卡支持。

---

# 7. Breakthrough / Heavy-Firepower Route Validation Contract

该路线是“强卡真的强”的主压力测试。

Deep 卡允许：

```text
Combat = S / S+
```

甚至在：

- 正面突破；
- 支点压制；
- 重装对抗；

其中一个场景明显超出基础卡上限。

禁止为了“所有牌平均”把它削成：

> 贵一点的普通步兵。

但必须保留至少一个硬角色缺口：

```text
Mobility low
or
Control low / zero
```

典型：

### Heavy Breakthrough

```text
combat: very high
mobility: low
control: low
```

### Siege Platform

```text
combat/suppression specialty: extreme
mobility: very low
control: 0
```

核心验收：

> 它可以赢战斗，但不能自己完成战争。

强卡摧毁/压制支点以后，仍需要其他单位完成占领、守点、转线或战线延伸。

---

# 8. Control / Engineering Route Validation Contract

这条路线不是旧 Stronghold bonus 的复活。

禁止：

- 占点直接 +3 齐射；
- 支点变成抽卡奖励节点；
- 工兵路线通过 Support 发通用伤害 buff。

该路线价值必须来自：

```text
capture efficiency
hold/recovery efficiency
support establishment / stabilization
battlefield conversion
```

同时继续遵守：

> 所有普通地面单位都能占领；Engineer 不能成为 mandatory capture tax。

因此 Control/Engineering 的身份应是：

```text
best at conversion / establishment
not only unit allowed to capture
```

必须至少存在一个低费/基础控制单位在中后期仍有合理使用理由。

---

# 9. Cross-Route Build Contract

P1 不验证三个封闭职业树。

必须有至少一组测试证明：

```text
Deep Mobility + Tier1 Control
Deep Heavy + Tier1 Mobility
Deep Heavy + Deep Control
```

等混合构筑是合法的。

目的：

> Deep slot 是战略投入限制，不是职业互斥墙。

禁止实现成：

```text
commit Heavy
 -> hide all Mobility cards
```

---

# 10. P1-07 Micro-Steps

```text
P1-07A representative-route content audit
P1-07B route-role contract definitions
P1-07C existing-card migration mapping
P1-07D Mobility vertical slice
P1-07E Heavy/Firepower vertical slice
P1-07F Control/Engineering vertical slice
P1-07G cross-route combination fixtures
P1-07H route UI projection smoke
P1-07I route-specific regression
P1-07 FINAL GO / NO-GO
```

注意：

P1-07C 必须逐卡决定：

```text
reuse as BASE
reuse as HERO
reuse as ROUTE TIER1
reuse as ROUTE DEEP
retire
rewrite effect
```

不得因为旧卡带 `route` tag 就自动算某条新路线。

---

# 11. P1-08：Growth Cadence Contract

已冻结原则：

> 双方成长次数主要由统一、可预测节奏驱动；优势行为不额外增加 Draft。

> 战场行为决定“解锁什么”，不是“多抽几次”。

> 成熟 Build 必须在对局结束前拥有足够长实际使用窗口。

Batch C 要把它变成可测 telemetry。

---

# 12. Growth Opportunity Authority

P1 不允许 RouteSystem 自己调用：

```text
open_extra_draft()
```

或：

```text
on_support_captured -> extra_offer
```

正式成长机会仍由统一 Match/Round cadence 驱动。

双方每个正常成长节点：

```text
Player gets one Draft opportunity
AI gets one Draft opportunity
```

可以因为双方各自 reroll 而实际生成不同数量 Offer，但**基础成长机会数量相同**。

---

# 13. Cadence Milestone Telemetry

每 side 至少记录：

```text
match_start_time
round_number
first_tendency_visible
first_tier1_unlock
first_tier1_card_offer
first_tier1_card_selected
first_deep_qualified
first_deep_commit
second_deep_qualified
second_deep_commit
first_deep_card_offer
first_deep_card_selected
first_deep_card_effective_use
second_route_deep_card_effective_use
match_end_time
```

同时记录：

```text
elapsed_seconds
elapsed_fraction_of_match
round
```

这样才能区分：

> 路线很早解锁但一直抽不到；

和：

> 路线本身解锁太晚。

---

# 14. Mature Build Window

冻结体验目标：

> **成熟 Build 至少应该拥有大约最后 1/3 对局的真实使用窗口。**

P1 不把“1/3”硬编码成游戏逻辑。

它是验收指标：

```text
mature_build_effective_time
/
actual_match_duration
```

目标围绕：

```text
~ 1/3 or more
```

做 tuning。

“mature build”不能简单定义成：

```text
first Deep Commit
```

因为 Commit 后还可能没抽到/没使用 Deep card。

P1 telemetry 至少要区分：

```text
Deep committed
Deep card selected
Deep card actually used/effective
```

推荐把成熟窗口的主要观察点放在：

> 第一条主要构筑路线的 Deep card 已经实际投入战场/产生效果，并且基础+路线升级已经形成明显身份。

精确判定可以在 P1 tuning 时基于不同路线制定，不要做一个全局 `build_mature=true` 黑箱。

---

# 15. Cadence Anti-Snowball Contract

禁止：

```text
kill enemy -> extra Draft
capture support -> extra Draft
destroy support -> extra Draft
lead territory -> faster Draft cadence
```

也不在 P1 初版加入：

```text
lose 2 supports -> comeback bonus Draft
```

优势行为的收益应该首先体现在：

- 战线；
- territory/support；
- route behavior qualification；
- 战术位置；

而不是成长次数。

---

# 16. Cadence Tuning 顺序

若成熟 Build 太晚，调参顺序优先：

1. route signal / qualification threshold；
2. route card soft weight；
3. per-card upgrade track pacing；
4. normal Draft cadence；
5. match duration target。

禁止第一反应：

```text
winning player gets more Drafts
```

或：

```text
deep commit immediately grants card
```

因为这会破坏已经冻结的增长公平模型。

---

# 17. P1-08 Micro-Steps

```text
P1-08A cadence event/clock audit
P1-08B milestone telemetry schema
P1-08C deterministic round/time hooks
P1-08D route unlock timing report
P1-08E deep obtain/effective-use timing report
P1-08F mature-window evaluator
P1-08G no-extra-draft invariant tests
P1-08H seed/match distribution audit
P1-08I tuning pass with evidence
P1-08 FINAL GO / NO-GO
```

---

# 18. P1-09：Combat / Mobility / Control Balance Contract

玩家面只显示三轴：

```text
Combat
Mobility
Control
```

内部每一轴继续拆 measurable submetrics。

禁止新增：

```text
Overall Power 82
Combat Score 47 + Mobility 20 + Control 15 = 82
```

也禁止把 cost 当“第四个能力轴”。

Cost/tempo 是约束层。

---

# 19. Combat Internal Profile

至少考虑：

```text
sustained single-target pressure
burst
survivability
range/reach
AoE / anti-swarm
vs light
vs heavy
vs fixed support/building
support suppression speed
```

不是每张卡都需要每项有值；不适用可以 N/A。

---

# 20. Mobility Internal Profile

至少考虑：

```text
time to frontline
lane-switch time
response to remote support
legal deployment flexibility
terrain/path constraints
retreat/re-response
```

注意：

> Mobility 不能通过绕过 DeploymentRules 假造。

---

# 21. Control Internal Profile

至少考虑：

```text
can_capture
solo neutral-support takeover time
stacked capture contribution under cap
hold efficiency
recapture efficiency
support establishment/recovery utility
```

对不能占领的 Deep siege card：

```text
Control = 0 / cannot capture
```

是完全允许的。

---

# 22. Cost / Tempo Constraint Layer

单独记录：

```text
deployment cost
route tier
Deep commitment required?
Selected Level requirement
availability/offer probability band
setup time
```

问题不是：

> 这张卡综合几分？

而是：

> **在它出现的阶段、资格和成本下，它是否值得成为一个真实选择？**

---

# 23. Six Fixed Benchmark Scenarios

所有代表卡至少通过统一固定场景画像：

## S1 Equal-Cost Frontal

同成本正面遭遇。

观察：

- kill/pressure；
- survival；
- time-to-break；
- role fulfillment。

## S2 Versus Many Low-Tier

观察：

- anti-swarm；
- overkill/waste；
- survivability；
- control conversion aftermath。

## S3 Versus Heavy / High-Quality

观察：

- anti-heavy；
- armor/survival；
- breakthrough specialization。

## S4 Rear-to-Remote-Support Response

从后方/另一线响应远端支点。

观察：

- travel/response time；
- lane switch；
- deployment constraints。

## S5 Solo Neutral Support Takeover

观察：

- can capture；
- takeover time；
- control efficiency。

## S6 Suppress Deployment Support

观察：

- disable/suppression pressure；
- time-to-neutralize；
- inability/ability to follow through on capture。

---

# 24. Benchmark Result 不是平均分

结果示例：

```text
Heavy Breakthrough
S1 Frontal: S
S2 Swarm: B
S3 Heavy: A
S4 Response: D
S5 Capture: D
S6 Suppress: S
```

禁止：

```text
average = 3.8 / 5
```

然后用这个平均数判平衡。

真正的 RED 信号是：

> 一张普通/Deep 卡在几乎所有战略场景都明显优于同阶段 alternatives，并且没有真实成本/角色缺口。

---

# 25. Strong Card Acceptance

Deep 强卡必须有“路线投入兑现感”。

禁止因为 Deep card benchmark 某场景 S/S+ 就自动 nerf。

正确检查：

```text
Is this its promised specialty?
Does it still have at least one meaningful weak axis / requirement?
Does it still need another unit/tool to complete territory conversion?
Is its cost/availability reasonable rather than unusably high?
```

符合则：

> **允许它强。**

---

# 26. Weak / Basic Card Acceptance

基础低费卡不要求后期正面等值。

但每个进入正式 BasePool 的卡必须回答：

```text
Why might I take/deploy this now?
```

可能理由：

- cheap capture；
- fast response；
- hold newly opened support；
- fill quantity；
- protect expensive specialist；
- exploit route-specific mechanic。

如果答案只有：

> “因为我还没抽到更好的。”

则 design smell。

---

# 27. Card-Facing Three-Axis Projection

P1 卡面可以显示：

```text
战斗 ★★★★☆
机动 ★★☆☆☆
控制 ★☆☆☆☆
```

或者同等简洁图形。

规则：

- 星级是 authored profile projection；
- 不由实时战况动态跳动；
- 不暴露内部复杂数值；
- 特殊“无法占领”要有明确标签；
- `占领缓慢 / 善于占领 / 无法占领` 可作为 Control 辅助标签。

UI 不显示一个 Overall 星级。

---

# 28. P1-09 Micro-Steps

```text
P1-09A capability-profile schema
P1-09B three-axis authored projection
P1-09C benchmark harness reuse/audit
P1-09D six scenario fixtures
P1-09E representative-card profile pass
P1-09F strong-card specialty acceptance
P1-09G weak/basic late-use acceptance
P1-09H card UI projection
P1-09I telemetry hook migration
P1-09J balance artifact report
P1-09 FINAL GO / NO-GO
```

---

# 29. P1-10：Easy / Normal Decision Strength

AI 难度原则：

```text
Information Fairness = same boundary
Decision Strength = different reasoning quality
```

Easy / Normal 都只能读取 P0 `AIObservationBuilder` 允许的字段。

两者都禁止：

- player hidden Offer；
- player exact hidden route score；
- future RNG；
- future Offer；
- hidden tactical command；
- unrestricted GameState/RunState object escape hatch。

---

# 30. AI Difficulty 不能通过数值作弊实现

标准 Easy/Normal 禁止：

```text
AI damage modifier
AI HP modifier
AI resource income modifier
extra reroll
extra Draft
third Deep slot
higher rarity
faster illegal deployment
```

如果未来做 Handicap/Challenge Modifier，应是独立模式，不能冒充 AI difficulty。

---

# 31. Existing AI Migration Boundary

当前 `CardfrontAiCommander` 已有：

```text
hero archetype
ranked evaluations
context-based archetype shifts
```

P1 正式改造方向：

```text
AIObservation
+ Own Offer
+ Own RerollState
+ Own RouteState allowed projection
+ DecisionStrengthProfile
        ↓
existing Commander / policy family
```

而不是：

```text
if difficulty == normal:
    use NewNormalAI.gd
```

复制整套逻辑。

建议一个 decision owner，多种 budget/profile。

---

# 32. Easy Decision Strength Contract

Easy 目标：

> 合法、能玩、有明显偏好，但不会系统性计算很多未来层。

允许输入与 Normal 相同的信息边界，但主动使用更少维度。

建议行为：

- 当前 Offer 中识别明显合法/有用卡；
- 轻度遵循 Hero identity；
- 轻度遵循已 committed route；
- 只看当前/局部战线问题；
- Deep Qualified 时可以较直接地 commit 最明显已有协同路线；
- Reroll 使用率低，只有 Offer 明显不符合自身已有构筑时才考虑；
- 不做 2 个以上阶段的未来组合规划；
- 不复杂推测玩家路线。

Easy 不能故意选非法目标或作弊送人头来“显得简单”。

---

# 33. Normal Decision Strength Contract

Normal 目标：

> 能理解当前战线 + 自己构筑方向 + 基本成本/机会窗口，并做 1～2 个决策阶段的合理规划。

允许考虑：

- current line/support pressure；
- own Hero；
- own Selected Levels；
- own Tier1/Deep route state；
- own two-slot commitment opportunity；
- current Offer roles；
- public observed enemy history；
- own cost/resource/setup constraints；
- 1～2 stage synergy；
- whether current Offer is weak enough to use reroll。

Normal 可以形成：

> “玩家这局多次公开使用侧翼快速单位，因此提高左侧防守准备”

这样的估计。

但必须来自 `ObservedEnemyHistory`，不是读取隐藏 Mobility score。

---

# 34. Decision Window Contract

Easy/Normal 都不能每 physics frame 重算全局最优。

建议：

```text
strategic decision window
reactive decision window
```

### Strategic

发生于：

- Draft；
- Deep Commit；
- Aim planning；
- 明确阶段切换。

### Reactive

只用于允许的紧急动作。

即使 Reactive：

- 也必须有离散检查窗口；
- 不允许 same-frame perfect reaction；
- 不读取尚未公开的玩家输入。

具体毫秒/秒数属于 tuning。

---

# 35. AI Reroll Decision Strength

权限已冻结双方相同。

### Easy

可以：

- 大多数时候 Keep；
- 当前 Offer 三张均明显偏离已有构筑/角色时才 Reroll。

### Normal

可以比较：

```text
best current legal option
vs
value of consuming one veto opportunity
```

但决定必须发生在 replacement Offer 生成之前。

禁止：

```text
peek replacement
 -> compare old/new
 -> choose better set
```

---

# 36. AI Deep Commitment

AI 使用与玩家同一 `request_deep_commit()` authority。

### Easy

偏向：

- 已有明显路线 Selected Levels；
- 当前最强 Qualified；
- 有 slot 即较保守 Commit。

### Normal

可以考虑：

- 两个 slot 的互补性；
- 当前已拥有卡；
- 战线形态；
- 剩余成熟窗口；
- 第二条路线是否重复同一弱点。

禁止使用未来 Offer 分布的实际 RNG 结果。

可以使用 authored/公开概率模型，但不能读取 future seed。

---

# 37. AI Scalar Utility 与“禁止综合 PowerScore”的边界

当前 AI policy 内部已经使用 `score` 排序候选。

P1 不要求 AI 完全不能使用任何 scalar utility；AI 在一个具体决策中需要比较行动。

但必须区分：

### 禁止

建立一个全局卡牌“真实综合战力”：

```text
CardPower = Combat*0.5 + Mobility*0.2 + Control*0.3
```

并让：

- Balance；
- Dominance Guard；
- Route design；
- AI；

都把它当真理。

### 允许

AI 在**当前 Observation + 当前决策上下文**中计算 situational utility：

```text
this offer choice is useful now because...
```

必须输出 reason breakdown，可审计当前情境因素。

也就是说：

> Designer balance profile 不压成一个总分；AI 可以为“这一刻的行动选择”计算情境效用。

---

# 38. Legacy AI Deck Dependencies Must Die

P1-10 必须全局审计 AI/value policy 中：

```text
deck_id
DeckRegistry
core_tactics
fortification_corps
barrage_control
```

P1 正式 AI 不得继续用旧 Deck ID 解释构筑身份。

替代来源：

```text
Hero
Selected Levels
RouteState
Deep commitments
Observed public battle history
```

旧字段若留作 historical mode，只能在明确 historical fixture 下使用。

正常 runtime 中改变 `deck_id` 不应改变 AI 决策。

---

# 39. AI Explainability Trace

Easy/Normal 每个关键决策至少可记录：

```text
decision_type
difficulty
observation_revision
candidate actions
chosen action
reason_codes
used dimensions
planning_depth
reroll used?
deep commit attempted?
```

禁止日志泄漏：

- player hidden Offer；
- future seed；
- hidden exact route score。

这个 trace 用于证明：

> AI 是因为判断更好，而不是知道更多。

---

# 40. AI Fairness Metamorphic Tests

至少包含：

### A Hidden Offer Mutation

只改变玩家隐藏 Offer。

AI Observation 和当前相同决策输入必须不变。

### B Future RNG Mutation

只改变未来 RNG state。

当前 AI 决策不得读取。

### C Public History Mutation

改变玩家已公开使用的单位/路线历史。

Normal AI 可以合理变化；Easy 可以变化较少。

### D Difficulty Swap

Easy -> Normal：

```text
allowed information fields identical
```

只有 DecisionStrengthProfile / planning behavior 变化。

### E Numerical Buff Probe

切换 Easy/Normal 后：

```text
unit stats
hero HP
base volley
reroll count
deep slot count
```

必须相同。

---

# 41. P1-10 Micro-Steps

```text
P1-10A existing AI read-set + legacy deck dependency audit
P1-10B DecisionStrengthProfile schema
P1-10C Easy budget/profile
P1-10D Normal budget/profile
P1-10E existing Commander adapter
P1-10F route commitment policy
P1-10G reroll keep/reroll policy
P1-10H strategic/reactive decision windows
P1-10I observed-enemy-history integration
P1-10J explainability trace
P1-10K fairness metamorphic tests
P1-10L difficulty numerical-parity test
P1-10M deterministic match smoke
P1-10 FINAL GO / NO-GO
```

---

# 42. P1-11：Final Evidence Gate

P1 Final GO 不是：

> 所有新类都能实例化。

而是必须证明：

1. 旧 Deck authority 已死；
2. 新路线来自实际行为；
3. Deep Commit 是主动且最多两条；
4. Offer 仍随机而非导演；
5. Reroll 公平；
6. Level 是 authored card identity；
7. 至少三个战略轴在实战中可区分；
8. Deep 强卡兑现投入；
9. 基础/弱卡仍有阶段理由；
10. 成熟 Build 有足够使用窗口；
11. Easy/Normal 只差判断，不差权限；
12. P0 战线系统没有被 P1 重写。

---

# 43. P1 Final Evidence Manifest

冻结一个候选 commit：

```text
P1_RC_COMMIT = <sha>
```

所有证据必须来自同一 SHA：

- CI；
- route telemetry；
- Offer statistical audit；
- benchmark artifacts；
- AI traces；
- screenshots；
- manual playtest；
- performance comparison。

修 Bug 后根据影响矩阵重跑相关证据。

---

# 44. P1 Automated Contract Families

至少分开：

```text
A Legacy Deck Authority Kill
B EligiblePool / Route Signals
C Deep Commitment
D Offer / Guard / Reroll
E Upgrade Tracks / Echo
F Representative Route Content
G Cadence / No Extra Draft
H Combat-Mobility-Control Benchmarks
I AI Information Fairness
J Easy/Normal Decision Strength
K P0 Regression
L Save/Restore
M Performance/Log Hygiene
```

禁止只写一个：

```text
P1EverythingTestRunner
```

然后内部一大坨共享 setup 自证正确。

---

# 45. Existing B1 Simulation Migration

现有 B1 audit 是有价值的基础设施。

P1 要求先建立 migration matrix：

```text
metric/test
old meaning
new P1 meaning
preserve/migrate/replace/historical
```

例如旧：

```text
card_by_hero under legacy deck candidate model
```

不能直接作为新 `BASE + HERO + ROUTE` 构筑健康结论。

但：

- seed matrix；
- artifact output；
- map aggregation；
- actual side-call parity；

可以复用。

禁止为了让 P1 报告好看，把 simulation 继续跑在旧 Deck candidate path。

---

# 46. P1 Statistical / Telemetry Reports

至少产出：

## Route report

```text
route tendency formation rate
tier1 unlock timing
deep qualification timing
deep commit timing
route co-occurrence
deep-slot usage
```

## Offer report

```text
card offer rate
card pick rate
reroll rate
reroll replacement distribution
Guard rejection rate
route-source appearance rate
```

## Card report

```text
Selected Level distribution
deployment/effective-use rate
survival if entity
capture contribution if applicable
benchmark profile
```

## Match/build report

```text
match duration
mature-build onset
mature-build usable fraction
route divergence Player vs AI
```

## AI report

```text
reroll usage by difficulty
deep commit timing by difficulty
planning/reason codes
information-field parity
```

这些指标是诊断，不自动成为单一胜率 hard gate。

---

# 47. Player/AI Divergence Acceptance

双方同 BasePool 并不意味着每局必须不同。

偶然相似是合法随机结果。

但在大量 seed / 对局中必须观察到：

```text
hero + behavior + independent Offer
```

能够产生统计上明显的构筑分化。

禁止人为硬约束：

```text
if AI has card X, player cannot get X
```

来伪造“分化”。

真正分化应来自独立历史，而不是互斥作弊。

---

# 48. Manual Playtest Matrix

至少覆盖：

### M1 Mobility-led match

测试者是否自然使用分桥/转线，并理解机动路线价值。

### M2 Heavy-led match

Deep 强卡是否明显爽、明显强，但不能独自完成占领。

### M3 Control-led match

便宜/工兵/控制单位是否在中后期仍有出场理由。

### M4 Mixed build

两个 Deep route + 第三条 Tier1 是否自然共存。

### M5 Poor-offer reroll

玩家是否理解这是“一次否决”，不是品质升级按钮。

### M6 Late reroll

低于 timer floor 时重抽，时间只补到 floor，不重置。

### M7 Deep qualification

玩家是否理解“已可深入”和“已深入”的区别。

### M8 Slots full

第三条已 Qualified 路线显示槽满，但 Tier1 不消失。

### M9 Core comeback

P1 强卡/路线加入以后，P0 Core fallback 仍能支撑反攻。

### M10 Easy vs Normal

测试者能感到 Normal 判断更完整，但没有明显“作弊感”。

---

# 49. P1 Visual Evidence Pack

至少保留同一 RC commit 的：

1. Base-only early Draft；
2. Hero-source identity；
3. Tier1 route unlocked；
4. Deep Qualified；
5. Deep Commit 1/2；
6. Deep Commit 2/2；
7. third Qualified while slots full；
8. Deep card in future Offer；
9. Reroll before/after；
10. late reroll timer floor；
11. reroll -> battlefield preview -> return；
12. per-card Level progression；
13. three-axis card display；
14. Mobility battlefield example；
15. Heavy breakthrough example；
16. Control conversion example；
17. Easy AI trace sample；
18. Normal AI trace sample；
19. narrow/mobile Draft state。

每张记录：

```text
commit
resolution/viewport
scenario
route state
round/time
```

---

# 50. Performance / Complexity Gate

P1 新系统不能通过“每帧算所有路线/所有卡/所有 AI 候选”实现。

必须记录：

```text
RouteSignal processing count
EligiblePool rebuild count
Offer generation count
Guard resample count
AI strategic decision count
AI reactive decision count
benchmark/simulation runtime
```

期望事件驱动：

```text
Battle Event -> route progression revision
Route/Level/Hero change -> pool revision
Draft/Reroll -> offer generation
Decision window -> AI reasoning
```

禁止：

```text
_process() every frame -> rebuild all route scores and candidate pools
```

---

# 51. P1 RED Blockers

任一存在：不得进入 P2。

- 正式 Draft 仍受 legacy `deck_id` 控制；
- Player/AI BasePool 不同；
- Route unlock 直接发卡；
- 战场优势增加额外 Draft；
- 只靠选卡能进入 Deep；
- Deep Qualified 自动占槽；
- 第三条 Deep route 生效；
- Commit 可免费撤销换线；
- Deep Commit 直接送强卡；
- Offer 固定槽/导演 counter；
- Reroll 提高品质；
- AI 偷看 replacement Offer 后决定是否 reroll；
- Echo 增加 Selected Level；
- 全卡统一升级模板；
- Deep 强卡 Combat/Mobility/Control 全顶；
- 低费基础卡没有任何中后期合理场景；
- 成熟 Build 基本只在比赛结束前才出现；
- Easy/Normal 信息字段不同；
- Normal 通过伤害/HP/资源作弊；
- AI 直接拿完整 GameState/RunState；
- P1 为路线卡创建第二套 Deployment authority；
- P0 Core fallback 被破坏；
- Graph/Route/Offer/AI 每帧无界重算。

---

# 52. P1 YELLOW Tuning Items

可以进入有限调优，但不能掩盖结构 bug：

- route tendency threshold；
- anti-farm curve；
- route soft weights；
- Guard bounded retry count；
- `REROLL_MIN_REMAINING_SECONDS`；
- individual card LevelStep numbers；
- unit capture weight；
- exact card cost；
- AI decision-window timing；
- mature build onset target细调；
- benchmark grade boundaries；
- UI contrast/wording。

如果问题描述是：

> “有时不知道为什么路线没解锁。”

这不是 Yellow；这是 explainability/logic RED。

---

# 53. P1-11 Micro-Steps

```text
P1-11A final evidence manifest + RC commit
P1-11B parse/import/boot
P1-11C P1 frozen-contract suite
P1-11D legacy Deck authority kill suite
P1-11E representative-route integration matrix
P1-11F cadence report
P1-11G six-scenario benchmark report
P1-11H Offer/Guard/Reroll statistical report
P1-11I UpgradeTrack/Echo audit
P1-11J AI fairness + difficulty report
P1-11K existing B1 migration audit
P1-11L P0 full regression
P1-11M save/restore
P1-11N performance/log audit
P1-11O manual playtest matrix
P1-11P visual evidence pack
P1-11Q frozen-spec drift re-audit
P1-11R P1 FINAL GO / NO-GO
```

---

# 54. P1 Final GO Seal

唯一合法文件：

```text
docs/cardfront_refactor_checkpoints/P1-11R_P1_FINAL_GO_NO_GO.md
```

至少包含：

```text
P1 RC commit:
P0 final GO reference:
P1 Batch A checkpoints:
Deep Commitment Amendment confirmed:
P1 Batch B checkpoints:
Reroll Amendment confirmed:
P1 Batch C checkpoints:
Automated test summary:
Route/cadence report:
Balance benchmark report:
AI fairness report:
Manual playtest result:
Performance result:
RED blockers:
YELLOW tuning debt:
Final decision: GO / NO-GO
P2 allowed start commit: <sha or NONE>
```

没有：

```text
Final decision: GO
P2 allowed start commit: <sha>
```

禁止进入 P2 gameplay implementation。

---

# 55. P1 Final North-Star Questions

P1-11R 前必须逐项回答：

1. 双方是否真的从同一个 BasePool 开始？
2. Hero 是否只是身份差异，而不是旧 Deck 复活？
3. 实际战场行为是否真的影响路线？
4. 选卡是否仍只是辅助而不是路线刷分主渠道？
5. Deep commitment 是否由玩家/AI明确决定？
6. 两个 Deep slot 是否真的限制深入而不锁死 Tier1 多路线？
7. Deep 强卡是否有明显兑现感？
8. Deep 强卡是否仍不能独自完成战争？
9. 便宜/弱卡是否仍有控制、机动或阶段价值？
10. 分桥/Support/战线是否比 P0 前更重要，而不是被构筑 UI 抢走？
11. Offer 是否仍然有随机惊喜，而不是系统发答案？
12. Reroll 是否是有限 veto，而不是品质提升器？
13. 重复选卡是否真的形成不同身份升级轨？
14. Mature build 是否有足够实际使用时间？
15. Easy/Normal 是否只差判断质量？
16. AI 是否从未获得玩家没有的信息权限？
17. 是否有任何旧 `deck_id`/Stronghold generic bonus/第二套部署逻辑重新回流？

任何一项只能用：

> “代码理论上应该是。”

回答，而没有证据：不得 GO。

---

# 56. Anti-Drift Restatement

Batch C 每个 micro-step 开工前必须复述：

> **我是在验证并完善已经冻结的 Cardfront 构筑闭环，不是在看到路线/AI/平衡系统后重新发明一套职业树、导演式发牌或作弊 AI。**

每步结束前必须问：

> **这一 diff 是否让玩家更清楚地感受到“地图战线 + 本局行为 + 构筑选择”的闭环，还是只是让某个子系统单独变得更复杂？**

如果答案偏向后者：停止并回到当前 checkpoint 的 original intent。
