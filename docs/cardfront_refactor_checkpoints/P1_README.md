# Cardfront P1 Checkpoint Entry

状态：**PREPARED / LOCKED UNTIL P0 FINAL GO**

> 本文件不是现在就允许进入 P1。只有 `P0-11O_P0_FINAL_GO_NO_GO.md` 明确 `Final decision: GO`，并给出 `P1 allowed start commit` 后，P1 才能开始。

---

# 1. P1 唯一起点

必须存在：

```text
docs/cardfront_refactor_checkpoints/P0-11O_P0_FINAL_GO_NO_GO.md
Final decision: GO
P1 allowed start commit: <sha>
```

P1-00A 的 `Source commit` 必须等于该 SHA。

没有：禁止 P1 gameplay code。

---

# 2. P1 Batch A 必读顺序

1. `docs/CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`
2. `docs/CARDFRONT_P0_EXECUTION_DETAIL_BATCH_C_2026-08-08.md` 中 P0 Final Evidence / P1 Gate
3. `docs/CARDFRONT_P1_EXECUTION_DETAIL_BATCH_A_2026-08-08.md`
4. **`docs/CARDFRONT_P1_BATCH_A_ROUTE_CUTOVER_AMENDMENT_2026-08-08.md`**
5. `docs/CARDFRONT_REFACTOR_PLAN_2026-08-07.md` 作为高层路线索引
6. `P0-11O_P0_FINAL_GO_NO_GO.md`
7. 最近一个 P1 GO checkpoint

如果 Roadmap 或 Batch A 早期表述与 `ROUTE_CUTOVER_AMENDMENT` 冲突，以 Engineering Spec + 最新 Mandatory Amendment 为准。

---

# 3. 已知 Roadmap / Batch 过时点

## 3.1 P0-09 Level

Roadmap 早期写过：

```text
基于 applied_upgrade_counts 提供 Level API
```

该表述已被 P0 Batch B 的源码审计修正。

正式语义：

```text
Selected Level authority
!=
applied_upgrade_counts / effect application history
```

Echo 自动重复 effect 不得提升 Selected Level。

## 3.2 P1 Eligible Pool

Roadmap 的“基础 / 英雄 / 路线三类 Eligible Pool”只是纲要。

正式迁移细节以：

- `CARDFRONT_P1_EXECUTION_DETAIL_BATCH_A_2026-08-08.md`
- `CARDFRONT_P1_BATCH_A_ROUTE_CUTOVER_AMENDMENT_2026-08-08.md`

为准。

### 最新强制语义

旧：

```text
deck_id
 -> exclusive upgrade_ids
 -> Draft eligibility
```

必须正式切换为：

```text
BASE
+ HERO
+ ROUTE
 -> EligiblePoolBuilder
 -> Draft eligibility
```

**P1-01 结束时，这不是“双系统共存”，而是 authority 已经完成切换。**

尤其：

- 旧 `deck_id -> exclusive upgrade_ids` 必须退出正式 eligibility authority；
- `deck_id` 不得成为第四种 card source；
- BasePool 必须 Player/AI 相同；
- Hero 与 Route 只能在 BasePool 之上增加合法来源；
- 旧 `core_tactics / fortification_corps / barrage_control` 不得直接重命名成新路线；
- 正常 Prematch 旧 Deck 选择不得继续改变候选池；
- legacy deck_id 可读旧存档，但不得恢复旧候选池；
- 禁止 `new pool empty -> fallback legacy deck`；
- 必须有逐卡 old -> new source migration ledger。

---

# 4. P1 每一步开始前模板

```text
Step:
Source commit:
P0 final GO reference:
Original intent:
Engineering Spec sections:
P1 Batch section:
P1 Amendment sections:
P0 authorities touched (default NONE):
Old authority:
Target authority:
Allowed mutation surface:
Read-only surface:
Forbidden changes:
Existing behavior that must survive:
Explicitly not solving:
Test evidence authority:
Expected checkpoint:
```

如果 `P0 authorities touched` 非 NONE，必须说明为什么，并列出要重跑的 P0 evidence。

---

# 5. P1 Batch A 当前合法顺序

旧 Deck -> 新 EligiblePool 的正式 cutover 被提升为 P1-01 的硬主线：

```text
P1-00A verify P0 seal
P1-00B P0 authority read-only ledger
P1-00C legacy deck consumer audit
   ↓
P1-01A legacy deck consumer inventory
P1-01B BasePool authority
P1-01C Hero source schema
P1-01D Route source schema
P1-01E pure EligiblePoolBuilder
P1-01F shadow evaluation + card source migration ledger
P1-01G Draft eligibility authority cutover
P1-01H legacy gameplay authority kill tests
P1-01I Prematch / save / test contract migration
P1-01 FINAL GO / NO-GO
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
P1-03A Deep commitment design gate
P1-03B qualification/commitment split
P1-03C slot capacity
P1-03D sticky commitment
P1-03E deep pool eligibility cutover
   ↓
P1-A FINAL GO / NO-GO
```

没有上一 checkpoint GO，不得进入下一步。

### 特别 Gate

`P1-01 FINAL GO` 前不得进入正式 Route Signal gameplay cutover。

因为如果旧 Deck authority 还活着，后面的 Route Signal 只是在旧构筑系统上叠第二层路线，会再次偏离北极星。

---

# 6. P1 Batch A 硬禁令

尤其禁止：

- 在 P0 final GO 前开始 P1；
- 因路线系统方便而重写 SupportGraph / DeploymentRules；
- 把旧 `fortification_corps` / `barrage_control` 直接当新 Route；
- 在旧 exclusive deck 上简单叠 route cards；
- 在 P1-01 完成后让 `deck_id` 继续改变 EligiblePool；
- 保留 Prematch 旧 Deck picker 并让它暗中映射到新 Route；
- 新 EligiblePool 为空时 fallback 到旧 Deck；
- 未建立 card-source migration ledger 就默认“旧卡先沿用”；
- 让 Player/AI 拥有不同 BasePool；
- 把 hero 做成另一套完整互斥 deck；
- 同 card ID 因多个来源重复进入 candidate list；
- 通过 duplicate ID 暗中提高概率；
- Gameplay systems 直接 `route_score += ...`；
- Card script 自己直接解锁路线；
- 只靠选卡完成 Deep route；
- route unlock 直接发卡；
- route unlock 增加 Draft 次数；
- route exact score 对 opponent AI 可见；
- Deep qualification 与 commitment 用同一个 bool；
- 第三条路线绕过 `DEEP_SLOT_LIMIT = 2`；
- 在 Deep commitment 方式未确认前，让正式 Deep card 进入 pool；
- 偷跑 reroll / full upgrade tracks / Hard AI。

---

# 7. P1-01 Legacy Authority Kill Checklist

P1-01 结束必须同时证明：

```text
DraftSystem candidate source = EligiblePoolSnapshot
```

并证明以下 metamorphic invariants：

### 7.1 deck_id neutrality

只改变：

```text
core_tactics
fortification_corps
barrage_control
```

正式 EligiblePool 不变。

### 7.2 DeckRegistry mutation probe

测试中改变某旧 DeckRegistry 列表，不得影响正式 EligiblePool。

### 7.3 Hero provenance

改变 Hero：

```text
BasePool 不变
Hero source 合法变化
```

### 7.4 Route provenance

改变 RouteState：

```text
Base/Hero 不变
Route source 合法变化
```

### 7.5 Save compatibility neutrality

旧存档带 `deck_id`：

- 可读取；
- 不 crash；
- 不恢复旧 exclusive pool。

任一失败：`P1-01 = NO-GO`。

---

# 8. Deep Slot 特别说明

当前已冻结：

```text
最多 2 条 Deep route
```

当前仍需独立确认：

```text
什么时候真正 consume slot
```

推荐默认：

```text
behavior -> DEEP_QUALIFIED
player explicit confirm -> DEEP_COMMITTED
```

在该 Decision Gate 完成前：

- 可以实现 qualification 数据；
- 不允许消费 slot；
- 不允许正式 Deep cards 进入 EligiblePool。

实现 Agent 不得自行选择“自动最高两条”或“拿路线卡即占槽”。

---

# 9. 统一复述

P1 开工前：

> **我是在 P0 已冻结的战线系统上，用新的 BASE + HERO + ROUTE 构筑模型正式替换旧 exclusive Deck eligibility；不是在旧 Deck 上继续叠路线。**

每步交付前：

> **这一 diff 是否让旧 `deck_id` 更接近纯兼容数据、让新 EligiblePool 更接近唯一正式 authority，而没有偷偷改变 Draft 次数、部署权威、AI 信息边界或地图规则？**
