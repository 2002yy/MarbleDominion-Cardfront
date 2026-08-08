# Cardfront P1 Execution Detail — Batch B — 2026-08-08

状态：**MANDATORY P1 DESIGN/EXECUTION ADDENDUM — OFFER PIPELINE / GUARDS / REROLL / PER-CARD UPGRADE TRACKS**

适用：P1-04 ～ P1-06

前置条件：

- `P0-11O_P0_FINAL_GO_NO_GO.md` = GO；
- P1-01 legacy Deck -> `BASE + HERO + ROUTE` cutover = GO；
- P1 Batch A 的 EligiblePool authority 已成立；
- 若 Deep commitment 仍未完成 Decision Gate，则 Deep cards 保持不可正式进入 EligiblePool。

上位文档：

1. `CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`
2. `CARDFRONT_P1_EXECUTION_DETAIL_BATCH_A_2026-08-08.md`
3. `CARDFRONT_P1_BATCH_A_ROUTE_CUTOVER_AMENDMENT_2026-08-08.md`
4. 本文
5. `CARDFRONT_REFACTOR_PLAN_2026-08-07.md`

> 本批不再决定“哪些卡有资格出现”；那是 Batch A / EligiblePoolBuilder 的权威。
>
> 本批回答：**eligible cards 以什么概率进入 Offer、怎样避免假选择、重抽怎样保持公平与随机性、重复选择怎样真正形成有身份的卡牌升级轨。**

---

# 0. 本批北极星

必须同时保护：

1. Offer 是**相对随机**的，不是脚本化发答案；
2. 路线投入会提高相关牌出现可能，但不保证下一轮送卡；
3. 三选一大多数时候存在不同选择理由，而不是一张明显答案 + 两张陪跑；
4. Guard 只修复“没有选择”的极端结果，不变成隐藏导演；
5. Reroll 是玩家/AI的有限否决机制，不提高隐形掉率；
6. 重复选择同一 card ID = `Selected Level +1`，不是牌堆塞第二份；
7. 每张卡自己的升级轨决定数值/数量/机制变化；
8. 禁止统一模板把所有卡升级成 `+攻击/+血量/+数量`；
9. Echo 等 effect replay 不得污染 Selected Level；
10. 不创建一个综合战力分给 Offer/Guard 决策。

本批明确不做：

- 全量路线内容；
- Hard AI；
- 当前战况自动送 counter card；
- 额外 Draft 次数；
- 付费 reroll 经济系统；
- 锁牌/部分 reroll；
- Legendary copy limit；
- 第三条 Deep route；
- PvP 网络同步实现。

---

# 1. 从当前实现出发

当前 `CardfrontUpgradeDraftSystem`：

```text
candidate ids
 -> is_upgrade_eligible
 -> rarity-based weight
 -> weighted sample without replacement
```

当前权重：

```text
COMMON_BASE_WEIGHT
UNCOMMON_BASE_WEIGHT
RARE_BASE_WEIGHT
```

并受 `run_state.rarity_level` 影响。

P1 Batch A cutover 后，candidate IDs 不再来自旧 Deck，而来自 `EligiblePoolSnapshot`。

本批默认保留：

- weighted random 的基础形式；
- 当前 rarity 机制的 gameplay effect，除非后续单独退役；
- sample without duplicate card ID in same Offer；
- per-side RNG isolation。

本批不是“把 DraftSystem 推倒重写”。

---

# 2. Offer Pipeline：唯一正式顺序

正式流程冻结为：

```text
EligiblePoolSnapshot
    ↓
OfferWeightPolicy
    ↓
WeightedCandidateSet
    ↓
Sample 3 without replacement
    ↓
Diversity Guard
    ↓
Dominance Guard
    ↓
Bounded Resample if needed
    ↓
OfferSnapshot
```

如果执行 Reroll：

```text
Current Offer IDs -> temporary exclusion
EligiblePoolSnapshot
    ↓
Same OfferWeightPolicy
    ↓
Same Guards
    ↓
New OfferSnapshot
```

禁止：

```text
先随机三张
-> 看玩家现在缺什么
-> 偷偷替换一张答案牌
```

---

# 3. Eligibility 与 Weight 再次分权

`EligiblePoolBuilder` 只能回答：

```text
eligible / blocked
```

`OfferWeightPolicy` 才回答：

```text
relative weight
```

禁止：

- 为提高概率复制 candidate ID；
- RouteState 自己随机；
- HeroSource 自己随机；
- Guard 修改 EligiblePool；
- AI policy 修改 candidate pool。

---

# 4. OfferWeightPolicy

推荐独立 pure policy：

```text
weight_for(card, side_offer_context) -> WeightBreakdown
```

`WeightBreakdown` 至少可审计：

```text
card_id
rarity_component
source_component
route_component
hero_component
other_authored_component
final_weight
reason_codes
```

具体数值属于 tuning，不在本文冻结。

---

## 4.1 Rarity Component

当前 `rarity_level` 已经是正式旧玩法之一。

P1 初版默认：

> **不要因为加入路线权重顺手删除 rarity 权重。**

应该把当前 rarity 权重逻辑包装成明确 component。

以后如果证明 `rarity_plus_1` 与新路线结构不适配，再开独立 design amendment。

禁止在 Batch B 悄悄把它变成：

```text
rarity = card power tier
```

稀有度 ≠ Deep route tier ≠ Selected Level。

---

## 4.2 Source Component

来源：

```text
BASE
HERO
ROUTE
```

Provenance 可以影响权重，但：

> **同一 card 因多个 source 合法，不自动把 multiplier 连乘。**

例如：

```text
sources = [BASE, HERO]
```

不能因为两个 tag 就天然变成 2 倍概率。

来源权重应由 policy 明确处理，并有上限。

---

## 4.3 Route Component

路线卡在解锁后：

- 可以比一般 Base card 有适度更高概率；
- 主发展路线可以高于弱倾向路线；
- Deep committed route 的 Deep card 可以拥有合理权重；
- 但不得保证下一轮出现。

冻结：

```text
route unlock -> possibility
not guarantee
```

禁止：

```text
Tier1 unlocked -> next offer must contain route card
Deep committed -> every offer one deep card
```

---

## 4.4 Hero Component

Hero card 可以有轻度身份权重，但：

- Hero card 不应每轮霸占一个固定 slot；
- 不应强制一张 Hero + 一张 Route + 一张 Base；
- Hero identity 通过长期概率和少量 starting-owned card 体现，而不是模板槽位。

---

## 4.5 No Counter-Director Component in P1 v1

P1 初版正式禁止：

```text
if enemy has heavy:
    boost anti-heavy card weight dramatically
```

也禁止：

```text
if player is losing:
    inject comeback answer
```

当前战况最多可供 AI 做选择，不参与 Player Offer 的“发答案”逻辑。

如果未来需要动态战场权重，必须单独设计，不得隐藏在 `OfferWeightPolicy`。

---

# 5. OfferTrace：必须可审计

每次 Offer 在 debug/test 模式能够产出：

```text
side_id
draft_id
eligible_pool_revision
candidate IDs
weight breakdown per candidate
sampled IDs
guard result
rejected sample attempts
reroll exclusion IDs if any
final offer IDs
RNG stream/seed reference for test
```

目的：

- 证明不是隐藏导演；
- 证明路线只是加权而非保证；
- 证明 Player/AI RNG 不串；
- 证明 Guard 没有无限重抽直到“看起来漂亮”。

Player UI 不显示这些内部数值。

---

# 6. Diversity Guard

目标：

> 防止明显“没有不同选择理由”的高度同质三张牌。

它不是：

> 强制每轮三种不同职业。

---

## 6.1 Choice Signature

每张卡建议产生只读比较签名：

```text
primary_axis: COMBAT / MOBILITY / CONTROL / MIXED
strategic_role_tags
route_id/tier if any
category/effect_family
permanent_vs_temporary
entity/building/volley/support identity
```

现有 `tags/category` 可以作为输入，但不要让 Guard 自己从 description 文本猜。

如不足，新增明确 authored metadata。

---

## 6.2 Diversity Fail 条件

典型失败：

```text
三张都属于同一 effect family
+ 同一 primary role
+ 战术用途几乎相同
```

例如三张都是：

> 下一轮多发几颗标准弹，只是数字略不同。

可以触发 resample。

但以下**不能仅因同路线就失败**：

```text
重装突破车
攻城炮组
重型压制平台
```

如果三者的实际使用理由不同，即使都来自 Heavy route，也可以是一个很有趣的“路线爆发 Offer”。

---

## 6.3 禁止模板化 Slot

不得写成：

```text
slot1 = emergency
slot2 = build synergy
slot3 = pivot
```

或：

```text
slot1 = Base
slot2 = Hero
slot3 = Route
```

Guard 只否决极端无选择结果，不直接构造三张牌。

---

# 7. Dominance Guard

目标：

> 防止一个 Offer 中存在明显“点它就对了”的严格支配关系。

禁止用综合分：

```text
PowerScore = combat*0.5 + mobility*0.2 + control*0.3
```

---

## 7.1 Strict Dominance，而不是“谁评分高”

只有在卡 A 与卡 B 战略用途高度可比时，才检查 strict dominance。

概念条件：

```text
same or highly-overlapping role
A has no greater requirement/cost
A >= B on all relevant authored axes
A > B on at least one meaningful axis
B has no unique mechanic / timing / synergy reason
```

才可认为 B 是明显陪跑。

如果：

```text
A 战斗强
B 控制强
```

不能因为当前模拟里 A 平均胜率高就判 B dominated。

---

## 7.2 Dominance metadata

可使用：

```text
Combat/Mobility/Control authored stars
cost/requirement
timing
unique mechanic tags
role tags
benchmark profile
```

禁止读取一个“总战力”字段。

---

## 7.3 Guard 不能保证完美平衡

Guard 不是平衡器。

如果某卡在所有 Offer 都支配同类卡：

> 应修卡牌设计/费用/升级轨。

不能让 Guard 永久隐藏弱卡来掩盖平衡问题。

因此必须 telemetry：

```text
how often a card is rejected by Dominance Guard
```

某卡长期被拒绝 = design smell。

---

# 8. Bounded Resampling

Diversity / Dominance fail 时允许有限重新采样。

精确最大次数属于 tuning。

必须满足：

- 有固定上限；
- 不无限循环；
- 不因为一直失败就提升 rarity；
- 不偷偷扩大 EligiblePool；
- 不改变 route unlock；
- 每次 rejection 可在 OfferTrace 中看到 reason。

达到上限仍无法找到完美 Offer 时：

> 选择当前最少违反 Guard 的合法样本，或使用 deterministic legal fallback。

具体 fallback 排序可以实现时冻结，但不得重新启用旧 Deck。

---

# 9. P1-04 Micro-Steps

```text
P1-04A current weight/read-path audit
P1-04B OfferWeightBreakdown DTO
P1-04C rarity component extraction
P1-04D Hero/Route soft-weight components
P1-04E OfferTrace
P1-04F ChoiceSignature metadata
P1-04G Diversity Guard pure test
P1-04H Dominance Guard pure test
P1-04I bounded resample pipeline
P1-04J Player/AI side isolation regression
P1-04K statistical smoke / probability audit
P1-04 FINAL GO / NO-GO
```

P1-04 不实现 reroll。

---

# 10. P1-04 Statistical Smoke

使用固定大量 seed 做概率审计，而不是验证“某张卡一定第几轮出现”。

至少比较：

```text
Base-only state
Hero-source state
Tier1 route unlocked state
Deep route committed state (only after P1-03 GO)
```

检查：

- 0% eligibility 的卡绝不出现；
- unlocked route card 出现率 > locked；
- 但不是 100% next-offer guarantee；
- Hero card 有身份倾向但不固定占槽；
- 同 card provenance 不因重复 ID 获得隐式倍权；
- Player draw consumption 不扰动 AI；
- Guard rejection rate 有界。

不在这里规定最终胜率目标。

---

# 11. Reroll：已确认方向与未确认细节分离

设计方向已经进入 Roadmap：

> 每次 Draft 提供有限的完整重抽能力，让玩家能够否决一次完全不想要的三选一。

推荐具体合同仍为：

```text
one full reroll per Draft
not banked
replace all 3
old 3 temporarily excluded for this Draft
same eligibility / same weight / same guards
no hidden quality bonus
no paid second reroll in P1
```

但是以下两项**本文不伪装成已最终确认**：

1. reroll 是否重置 Draft timer；
2. AI 是否与玩家一样拥有每 Draft 一次 reroll opportunity。

因此 P1-05A 必须先过 Decision Gate。

---

# 12. Reroll State Model（不依赖上述两项即可先冻结）

每方每个 Draft 建议维护：

```text
RerollState
- draft_id
- available
- used
- excluded_offer_ids
```

性质：

- draft scoped；
- 新 Draft 自动重建；
- 不累计；
- 不写成永久货币；
- 不改变 RouteState；
- 不改变 Selected Level；
- 不触发额外 Draft。

---

## 12.1 Full Reroll Only

P1 初版禁止：

- 单张锁定后 reroll 另外两张；
- partial reroll；
- 多次连续 reroll；
- 花 Command Point reroll；
- 花新货币 reroll。

完整重抽只有：

```text
[A, B, C]
 -> discard for this draft
 -> [D, E, F]
```

---

## 12.2 Exclusion Contract

第一次 Offer 三个 card ID 本 Draft 内加入临时 exclusion。

Reroll 时：

- 正常不应再次出现 A/B/C；
- exclusion 只持续当前 Draft；
- 下一 Draft A/B/C 恢复正常资格；
- 如果合法 pool 太小无法组成 3 张，不能 crash。

小池 fallback 必须显式记录 reason。

禁止为了凑三张 fallback 到 legacy Deck。

---

## 12.3 No Quality Boost

Reroll 使用：

```text
same EligiblePool
same OfferWeightPolicy
same rarity rules
same Guards
```

唯一额外条件是本 Draft exclusion。

禁止：

- reroll 提高 rare；
- reroll 强制路线卡；
- reroll 强制至少一张未拥有卡；
- reroll 根据第一次 Offer 质量偷偷补偿。

---

## 12.4 Preview Interaction

P0 已冻结：

```text
DRAFT_VISIBLE <-> BATTLEFIELD_PREVIEW
```

Reroll 不得重开这套 UI architecture。

推荐状态：

- Preview 中 choice content 隐藏；
- 返回 Draft 后 reroll 状态原样保留；
- reroll 后进入 Preview 再返回，新 Offer 仍保持；
- Preview toggle 不消耗 reroll；
- reroll 不移动 ChoiceShell。

必须新增：

```text
reroll -> preview -> return
```

回归。

---

# 13. P1-05 Micro-Steps

```text
P1-05A REROLL DECISION GATE
P1-05B per-draft RerollState
P1-05C exclusion-aware Offer request
P1-05D player UI button / state
P1-05E RoundDirector orchestration
P1-05F timeout + reroll interaction
P1-05G preview/reroll regression
P1-05H save/restore policy audit
P1-05I AI reroll path (only if Decision Gate confirms)
P1-05 FINAL GO / NO-GO
```

---

# 14. Reroll 与 Save

先审计当前产品是否正式支持 mid-draft save/restore。

如果支持：

必须保存：

```text
current offer IDs
reroll used/available
excluded IDs
draft_id/timer state as existing contract requires
```

如果不支持：

> 不得为了 Reroll 顺手新增 mid-draft save feature。

记录 `N/A + evidence`。

---

# 15. Per-Card Upgrade Track：核心语义

P0 已冻结：

```text
Selected Level
!=
Effect Application Count
```

P1 现在把每个 card ID 的 Selected Level 真正接到 authored progression。

默认：

```text
first real selection -> Lv1
second real selection -> Lv2
...
```

不创建第二份 card instance。

---

# 16. Upgrade Track Schema

每张正式可升级卡建议显式声明：

```text
max_selected_level
level_steps:
  1: ...
  2: ...
  3: ...
  [4/5 if authored]
```

每个 LevelStep 至少包含：

```text
level
resolution/effect spec
player-facing delta text
optional quantity identity
optional mechanic unlock
optional presentation update
```

具体 schema 命名可调整。

核心：

> **每一步是 authored，不从一个全局成长公式自动推导。**

---

# 17. Quantity 是卡牌身份，不是第二个通用等级

允许：

### 征召兵

```text
Lv1: 2人
Lv2: 3人
Lv3: 占领效率能力
Lv4: 4人
```

### 重装突破单位

```text
Lv1: 1台
Lv2: 装甲提升
Lv3: 对支点压制增强
Lv4: 解锁突破机制
```

禁止统一：

```text
every level:
  damage + X%
  hp + X%
  quantity + 1
```

也禁止：

```text
card_level
+
quantity_level
+
stat_level
```

三套独立无上限成长轴。

---

# 18. Resolver Contract

选择 card 时必须按顺序：

```text
current Selected Level
 -> next Selected Level
 -> lookup authored LevelStep(next)
 -> validate
 -> apply effect step
 -> commit Selected Level increase
```

若 effect apply 失败：

> 不得先永久增加 Level 再返回失败。

需要原子性：

```text
selection resolution succeeds
=> Level advances

resolution fails
=> Level unchanged
```

---

# 19. Echo 与 Upgrade Track：必须升级旧 ID-only replay

当前旧实现：

```text
queued_echo_upgrade_id
```

随后 Echo 再按 card ID 重新 apply。

加入 per-card LevelStep 后，这不够安全。

问题：

```text
选择某卡 Lv2
-> queue echo(card_id)
-> 后续该卡可能已到 Lv3
-> echo 时只凭 card_id
```

会产生：

> Echo 到底重放 Lv2 还是按当前 Level 解析？

冻结：

> **Echo 重放“当时被选中并已成功结算的 effect step”，而不是再推进 Level，也不是动态解析成下一 Level。**

因此建议 queue：

```text
ResolvedEffectReplay
- card_id
- selected_level_at_source
- effect_id / resolved params snapshot or stable step id
```

Echo replay：

- effect application count 可增加；
- Selected Level 不增加；
- Route card-selection auxiliary signal 不重复记一次真实选择；
- telemetry 标记 `source = ECHO_REPLAY`。

---

# 20. Starting-Owned Hero Cards

若某 Hero 有：

```text
hero_starting_owned_card_ids
```

必须明确初始化到哪个 Selected Level。

P1 默认建议：

```text
starting owned -> Selected Level 1
```

但通过显式 `starting grant` API 实现。

禁止伪造：

```text
player selected card event
```

否则会：

- 污染 route selection signal；
- 污染 pick telemetry；
- 触发 Echo/selection side effects。

---

# 21. Max Level Eligibility

默认合同：

```text
Selected Level >= max_selected_level
=> card no longer eligible for normal Offer
```

理由：

- 避免给玩家无效选择；
- 保持“重复选择就是升级”的清晰语义。

如果未来某卡需要：

```text
repeatable_at_max
```

必须是显式特殊设计，P1 初版默认 false。

禁止因为 effect 本身还能执行就自动继续出现。

---

# 22. Old Effect Caps != Card Max Level

当前存在：

```text
attack_level max
rarity_level max
building_volley_level max
tower level max
```

这些是旧 effect/runtime cap。

它们不自动等于：

```text
card.max_selected_level
```

迁移每张旧卡时必须明确：

- 继续作为多 Level card；
- 改成不同 LevelStep；
- max level；
- 还是退役/重做。

禁止 `min(old_runtime_cap, 3)` 自动生成所有卡轨。

---

# 23. Upgrade Track Migration Ledger

P1-06 必须建立：

```text
docs/cardfront_refactor_checkpoints/P1-06_upgrade_track_migration_ledger.md
```

对每张进入 P1 正式代表池的 card 记录：

```text
card_id
new source
route/tier if any
max_selected_level
Lv1 effect
Lv2 effect
Lv3 effect
Lv4/Lv5 if any
quantity changes
mechanic unlocks
runtime caps touched
Echo replay semantics
max-level eligibility
Combat/Mobility/Control identity
```

没有 ledger，不允许 Agent“先按 +20% 做起来”。

---

# 24. Upgrade Track 与 Offer Weight 分权

OfferWeightPolicy 可以读取：

```text
current selected level
is maxed
```

用于 eligibility/合理小幅 authored weighting。

但禁止：

```text
低 Level -> 系统强制继续喂同一张牌
```

否则 Build 会被系统自动完成。

是否继续升级必须仍然来自随机 Offer + 玩家选择。

---

# 25. Card UI Projection

Choice card 至少最终能表达：

```text
当前 Level
选择后将到 LvN
本次具体提升
Combat / Mobility / Control
route/tier/source identity（适量）
```

避免显示内部：

- exact route score；
- weight；
- Guard score；
- composite PowerScore。

卡面必须回答：

> “我为什么现在想再拿一次这张卡？”

而不仅是：

> “它现在是Lv3。”

---

# 26. P1-06 Micro-Steps

```text
P1-06A current level/effect audit
P1-06B authored UpgradeTrack schema
P1-06C representative card migration ledger
P1-06D LevelStep resolver
P1-06E atomic Selected Level commit
P1-06F Echo replay snapshot migration
P1-06G starting-owned grant path
P1-06H max-level eligibility
P1-06I ChoiceCard projection
P1-06J save/restore migration
P1-06K regression / metamorphic tests
P1-06 FINAL GO / NO-GO
```

---

# 27. Upgrade Track Tests

必须至少：

### T1 Normal selection

```text
Lv0 -> select -> effect Lv1 -> Level1
```

### T2 Repeat selection

```text
Level1 -> select -> authored Lv2 effect -> Level2
```

### T3 Failed resolution

```text
apply fails -> Level unchanged
```

### T4 Echo

```text
source selection Level2
-> Echo replays Level2 effect snapshot
-> card stays Level2
```

### T5 Max

```text
Level = max
-> normal EligiblePool excludes card
```

### T6 Starting-owned

```text
explicit grant -> Level1
no fake selection telemetry
```

### T7 Save/restore

```text
Selected Levels + queued replay semantics roundtrip
```

### T8 Route signals

Echo replay 不产生新的 CARD_SELECTION_AUX signal。

---

# 28. Batch B Anti-Drift Red Flags

任一出现应停止：

- Guard 固定构造三种槽位；
- WeightPolicy 根据当前敌人偷偷发 counter；
- Route unlock 保证下一 Offer 路线卡；
- multi-source duplicate ID 偷加权；
- Guard 无限 resample；
- Guard 通过综合 PowerScore 判断所有卡；
- Reroll 提高 rarity；
- Reroll 重新启用旧 Deck fallback；
- Reroll 生成额外成长次数；
- per-card Level 与 rarity_level 混为一谈；
- Echo Level+1；
- starting-owned 伪造 player selection；
- 全卡统一 `+攻击/+血量/+数量`；
- maxed card 继续以无效选项出现；
- 为升级轨重新打开 P0 Deployment authority；
- Batch B 偷跑全部路线内容或 Hard AI。

---

# 29. Batch B Final Evidence

最终至少要能证明：

```text
Eligibility authority = Batch A
Weight authority = OfferWeightPolicy
Guard = bounded validity filter, not director
Reroll = same random rules + exclusion only
Selected Level = authored progression
Echo = replay effect, not selection
```

以及：

- 统计上路线卡概率提高但不保证；
- 同一 Offer 大多数存在不同理由；
- 明显严格支配组合被有限 Guard 过滤；
- Guard rejection rate 可审计；
- Player/AI RNG isolation 不回归；
- 旧 Deck 不复活；
- 升级轨具有不同身份；
- 没有综合战力分。

---

# 30. 当前需要产品确认的 Decision Gate

本文发现两项会实质改变体验，不能由实现 Agent 自定：

## D1 — Reroll 是否重置 Draft 倒计时

推荐：**不重置，只保留当前剩余时间。**

理由：

- reroll 是改候选，不是额外思考回合；
- 避免反复利用 UI 延长 Draft；
- 每轮只有一次，玩家仍有明确时间预算。

替代：reroll 后恢复/增加时间，需要明确增加多少。

## D2 — AI 是否拥有同等一次 Reroll 权

推荐：**是。双方每 Draft 都有同样一次 reroll opportunity，是否使用由 Decision Strength 决定。**

理由：

- 构筑机会规则对称；
- AI 难度来自判断，不来自少一个系统按钮；
- AI reroll 仍只能看自己的 Offer 和合法 Observation。

Easy 可以较少/不主动使用，Normal 可在明显低价值 Offer 时使用；但机会本身相同。

在 D1/D2 未确认前：

- 可实现 OfferWeightPolicy / Guards / UpgradeTrack；
- 可实现 RerollState pure model；
- **不得把 timer reset 语义和 AI reroll policy 写死进正式 runtime。**
