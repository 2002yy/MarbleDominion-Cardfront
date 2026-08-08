# Cardfront P1 Batch A — Legacy Route/Deck Cutover Amendment — 2026-08-08

状态：**MANDATORY / SUPERSEDES ANY OPTIONAL LEGACY-DECK WORDING IN P1 BATCH A**

适用：P1-00C ～ P1-01I

> 用户已明确：**上一轮 P1 Batch A 不只是规划新 EligiblePool，而是要求正式实现“旧路线/旧 Deck 体系切换到新规划”。**
>
> 因此本修订把“旧 `deck_id` 可暂时继续参与正式候选池”彻底禁止。
>
> P1-01 完成的定义不是“新系统已经存在”，而是：
>
> **正式运行时的 Draft eligibility authority 已从旧 `deck_id -> exclusive upgrade_ids` 切换为 `BASE + HERO + ROUTE -> EligiblePool`，且旧 authority 已失去 gameplay effect。**

---

# 1. 最终 Authority Freeze

## 1.1 P1-01 前

旧正式链路：

```text
run_state.deck_id
 -> CardfrontUpgradeDeckRegistry.get_upgrade_ids(deck_id)
 -> CardfrontUpgradeDraftSystem._deck_upgrade_ids(run_state)
 -> is_upgrade_eligible(...)
 -> weighted draw
```

## 1.2 P1-01 后

正式链路必须变成：

```text
BasePoolRegistry
 + Hero card source
 + RouteProgressionState / RouteDefinition
 + existing per-card effect eligibility
        ↓
EligiblePoolBuilder
        ↓
EligiblePoolSnapshot(side)
        ↓
Offer Generator / Weight Policy
        ↓
Player Offer / AI Offer
```

`CardfrontUpgradeDeckRegistry` 不得出现在正式候选池 authority 链上。

---

# 2. 旧路线/Deck 的正式退役语义

旧定义：

```text
core_tactics
fortification_corps
barrage_control
```

在新规划下不再表示：

- 一方整局完整候选池；
- Hero 的职业卡池；
- Route；
- Faction；
- Deep route；
- Offer 权重来源。

它们不得被“换个名字”后直接复用成新路线。

例如禁止：

```text
fortification_corps -> engineering_route
barrage_control -> firepower_route
```

如果新路线中复用了某些旧卡牌内容，只能逐卡重新声明：

```text
source = ROUTE
route_id = ...
tier = TIER1 / DEEP
```

不能继承旧 Deck membership 作为路线归属证据。

---

# 3. 兼容保留 != gameplay authority

P1-01 后允许继续存在：

```text
CardfrontUpgradeDeckRegistry.gd
run_state.deck_id
legacy save payload deck_id
old deck IDs
```

但仅限：

- 旧存档解析；
- telemetry 对照；
- historical audit；
- migration logging；
- tests fixture。

明确禁止：

```text
if deck_id == "fortification_corps":
    candidate_ids = ...
```

或任何等价逻辑。

### 硬测试

同样的：

```text
hero
route state
selected levels
battle state
RNG seed
```

仅改变：

```text
deck_id = core_tactics
```

与：

```text
deck_id = fortification_corps
```

P1 正式 `EligiblePoolSnapshot.card_ids` 必须完全相同。

如果不同：**RED / NO-GO**。

---

# 4. Prematch 旧 Deck 入口必须退出正式构筑控制

P1-00C 必须审计当前 Prematch / config / hero selection 是否仍存在 deck picker。

P1-01 cutover 后，正常 Cardfront 对局不得再让玩家通过旧 Deck 选择改变候选池。

允许的迁移处理只有两类：

## A. 正式退役/隐藏旧 Deck picker

推荐。

正常新对局不再提供：

```text
基础战术 / 筑垒工兵 / 弹幕压制
```

作为“完整候选池选择”。

## B. 暂留 UI shell，但 gameplay-neutral

若 UI 改动必须延后：

- 旧 picker 可以暂时显示；
- 但选择结果不得改变 EligiblePool；
- 必须标记 migration/deprecated；
- 不得让玩家误以为仍决定本局卡池。

最终正常产品流应移除该误导入口。

禁止第三种：

> UI 看起来仍在选旧 Deck，后台悄悄把它映射到某条新 Route。

这会把“本局行为形成路线”再次变成“开局预选职业路线”。

---

# 5. P1-01 Migration Sequence — 必须按顺序切 Authority

## P1-01A — Legacy Deck Consumer Inventory

只读扫描所有：

```text
deck_id
CardfrontUpgradeDeckRegistry
get_upgrade_ids
recommended_for_hero
DECK_CORE_TACTICS
DECK_FORTIFICATION_CORPS
DECK_BARRAGE_CONTROL
```

对每个 consumer 分类：

```text
LIVE_ELIGIBILITY
PREMATCH_UI
SAVE_COMPAT
AI
SIMULATION
TELEMETRY
TEST
DOC
```

产出 checkpoint：

`P1-01A_legacy_deck_consumer_inventory.md`

未分类 consumer = NO-GO。

---

## P1-01B — New BasePool Authority

建立新的正式 `BasePool` 数据来源。

硬要求：

- Player/AI card ID 集合相同；
- 与 hero 无关；
- 与 route 无关；
- 与 legacy deck_id 无关；
- 每个 ID 唯一。

此时不切 Draft consumer。

先建立 pure tests。

---

## P1-01C — Hero Card Source

在 Hero definition 中显式增加：

```text
hero_offer_card_ids
hero_starting_owned_card_ids
```

或语义等价字段。

禁止：

- 根据 hero_id 直接选择旧 Deck；
- `recommended_for_hero()` 再成为 gameplay eligibility；
- 把整个旧 fortification deck 作为工兵 Hero source。

Hero source 只能增加小规模身份卡，而不是恢复完整职业 deck。

---

## P1-01D — Route Card Source

新 `RouteDefinition` 显式声明：

```text
tier1_card_ids
deep_card_ids
```

Route eligibility 只读取：

```text
RouteProgressionState
```

不读取 legacy deck membership。

---

## P1-01E — Pure EligiblePoolBuilder

输入：

```text
BasePool
HeroSource
RouteState
SelectedLevel/effect eligibility read models
```

输出：

```text
EligiblePoolSnapshot
```

此阶段仍允许 Draft 正式 runtime 继续旧 authority，目的是先 shadow 对比，不一次性全切。

禁止 Builder 调 RNG。

---

## P1-01F — Shadow Evaluation / Differential Audit

正式切换前，同一局状态同时计算：

```text
legacy_candidate_ids
new_eligible_pool_ids
```

只做日志/测试对照，不让两套系统同时影响 Offer。

目的：

- 找出旧 deck 独占卡；
- 明确哪些卡迁到 BASE；
- 哪些迁到 HERO；
- 哪些迁到 ROUTE；
- 哪些被退役。

必须产生一张迁移表：

| card_id | old deck membership | new source | new route/tier if any | action |
|---|---|---|---|---|

`action` 只能是：

```text
KEEP_BASE
MOVE_HERO
MOVE_ROUTE_TIER1
MOVE_ROUTE_DEEP
RETIRE
COMPAT_ONLY
```

禁止 `UNDECIDED` 进入 cutover。

---

## P1-01G — Draft Eligibility Authority Cutover

这是正式切权步骤。

`CardfrontUpgradeDraftSystem` 不再调用：

```text
_deck_upgrade_ids(run_state)
```

作为正式候选来源。

改为消费：

```text
EligiblePoolSnapshot
```

或由明确 side context 内提供等价只读 pool。

### 同一步必须保证

- Player/AI per-side RNG isolation 保持；
- Offer size 规则不变；
- timeout fallback 不被顺手重写；
- rarity/weight 仍沿当前行为，直到 P1 Batch B；
- reroll 仍未实现；
- Route unlock 不直接发卡。

### 禁止

在切 eligibility 的同时顺手重写：

- weight curve；
- rarity system；
- Offer Guard；
- AI score；
- Draft cadence。

切权时只改“候选从哪里来”。

---

## P1-01H — Legacy Gameplay Authority Kill Test

切权后必须主动证明旧 authority 已死，而不是“代码暂时没走到”。

至少测试：

### H1 — deck_id metamorphic invariant

只改变 legacy deck_id：

```text
EligiblePool unchanged
```

### H2 — DeckRegistry mutation probe

test fixture 临时让某旧 DeckRegistry 返回一个特殊 dummy ID。

要求：

```text
正式 EligiblePool 不出现该 ID
```

若出现，说明旧 authority 仍泄漏。

### H3 — Hero difference only from HeroSource

改变 hero：

```text
Base IDs 不变
Hero provenance 变化
```

不得通过 legacy deck recommendation 间接改变 BasePool。

### H4 — Route difference only from RouteState

改变 route unlock：

```text
Route provenance / eligible IDs 按定义变化
```

不得修改 Base/Hero source。

---

## P1-01I — Prematch / Save / Test Contract Migration

正式 cutover 后处理 consumer：

### Prematch

旧 Deck 选择不再改变 gameplay eligibility。

### Save

旧 `deck_id` 可继续读取，但 restore 后只做 compatibility data，不影响新 pool。

### Tests

必须迁移任何断言：

```text
hero -> recommended deck -> candidate list
```

为：

```text
BasePool equality
HeroSource difference
RouteSource difference
legacy deck neutrality
```

### Simulation

B1 / parity audit 若仍按旧 Deck 比较，必须分类：

```text
legacy observational
migrated new-pool audit
retired
```

禁止保留一个绿色 CI，但实际仍在测旧 Deck 游戏。

---

# 6. Old → New Card Migration Ledger 是强制产物

P1-01F 必须建立：

`docs/cardfront_refactor_checkpoints/P1-01F_card_source_migration_ledger.md`

至少覆盖当前正式 manifest 中所有卡。

每张卡回答：

1. 当前属于哪些旧 Deck？
2. 新规划属于 BASE / HERO / ROUTE / RETIRE 哪类？
3. 若 ROUTE：属于哪条 route？
4. 若 ROUTE：Tier1 还是 Deep？
5. 是否影响现有 effect eligibility？
6. 是否需要内容重做但暂时用旧 effect？
7. P1 该卡什么时候允许进入正式 Offer？

没有 ledger 的卡不能“暂时沿用旧 deck”。

---

# 7. Cutover Atomicity：禁止长期双 Authority

允许短暂 shadow evaluation：

```text
旧 pool = read-only baseline
新 pool = read-only shadow
```

不允许正式运行时：

```text
legacy candidate pool
+
new route pool
```

一起参与抽牌。

也不允许：

```text
if new_pool.is_empty():
    fallback_to_legacy_deck()
```

因为这会让旧 authority 永远死不干净。

### 新 pool 为空

应该：

```text
hard error / validation failure
```

而不是 fallback 到旧 deck。

---

# 8. Authority Search Gate

P1-01I 结束前全局搜索：

```text
get_upgrade_ids(
deck_id
recommended_for_hero
DECK_FORTIFICATION_CORPS
DECK_BARRAGE_CONTROL
DECK_CORE_TACTICS
```

每个结果必须分类：

```text
COMPATIBILITY
MIGRATION TEST
HISTORICAL DOC
DEAD CODE TO REMOVE
```

任何：

```text
LIVE_DRAFT_ELIGIBILITY
```

结果 = RED。

---

# 9. P1-01 Final GO / NO-GO

只有以下全部满足才 GO：

- 正式 Draft candidate authority = EligiblePoolBuilder；
- BasePool Player/AI 完全相同；
- hero 差异来自 HeroSource；
- route 差异来自 RouteState；
- old Deck membership 不再改变 candidate set；
- Prematch 旧 Deck 不再控制正式构筑；
- save 中 legacy deck_id 不再恢复旧候选池；
- 不存在 fallback-to-legacy；
- old→new card migration ledger 完整；
- active tests 已迁移到新合同；
- P0 authority 没被重开；
- 未偷跑 Batch B 的 weight/reroll/upgrade-track。

任一失败：

```text
P1-01 = NO-GO
```

禁止进入 Route Signals 的正式 gameplay cutover。

---

# 10. 一句话冻结

> **P1 不是在旧职业 Deck 上加路线系统，而是用新 `BASE + HERO + ROUTE` 资格模型正式替换旧 `deck_id -> exclusive list` 构筑路线。旧 Deck 可以被读，但不能再决定玩家这一局能抽什么。**
