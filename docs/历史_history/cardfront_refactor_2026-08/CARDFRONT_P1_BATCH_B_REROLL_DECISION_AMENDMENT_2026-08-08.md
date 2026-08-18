# Cardfront P1 Batch B — Reroll Decision Amendment — 2026-08-08

状态：**MANDATORY / RESOLVES P1-05 REROLL DECISION GATE**

适用：P1-05A ～ P1-05I

上位关系：

1. `CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`
2. `CARDFRONT_P1_EXECUTION_DETAIL_BATCH_A_2026-08-08.md`
3. `CARDFRONT_P1_BATCH_A_ROUTE_CUTOVER_AMENDMENT_2026-08-08.md`
4. `CARDFRONT_P1_EXECUTION_DETAIL_BATCH_B_2026-08-08.md`
5. 本修订

> 本修订正式解决 Batch B 中仅剩的两个 Reroll 产品 Decision Gate。
>
> 已确认：
>
> 1. **Reroll 不重置完整 Draft 倒计时；但存在最小剩余时间保护。若当前剩余时间低于该最小值，成功 Reroll 后提升到最小值。**
> 2. **AI 与玩家拥有完全相同的“每个 Draft 一次免费完整 Reroll”权限；是否使用由 Decision Strength 决定，而不是由额外信息权限决定。**

---

# 1. 最终 Reroll 权限合同

每个 side、每个 Draft 都拥有独立：

```text
RerollState
- draft_id
- available = true
- used = false
- excluded_offer_ids = []
```

正式规则：

```text
one full reroll per side per Draft
free
not banked
not transferable
not partially reusable
not purchasable in P1
```

Player 与 AI 权限对称：

```text
Player: 1
AI:     1
```

区别只能来自：

```text
Decision Strength
```

而不是：

```text
AI gets more rerolls
AI sees future reroll result
AI sees player hidden offer
AI gets higher rarity after reroll
```

---

# 2. Timer Contract — 不重置，但有最小剩余时间保护

新增明确 tuning constant：

```text
REROLL_MIN_REMAINING_SECONDS
```

具体秒数**尚不冻结为设计常量**，属于后续基于 Draft 总时长与实测确定的 tuning 值。

约束：

```text
0 < REROLL_MIN_REMAINING_SECONDS <= DRAFT_TIMEOUT
```

成功 Reroll 前：

```text
remaining_before
```

成功 Reroll 后：

```text
remaining_after = max(
    remaining_before,
    REROLL_MIN_REMAINING_SECONDS
)
```

且永远不得超过当前 Draft 的正常总时长上限：

```text
remaining_after <= DRAFT_TIMEOUT
```

因此：

### 情况 A：剩余时间已经足够

```text
remaining_before = 8s
min = 3s
```

结果：

```text
remaining_after = 8s
```

**完全不重置。**

### 情况 B：剩余时间太短

```text
remaining_before = 1.2s
min = 3s
```

结果：

```text
remaining_after = 3s
```

目的：

> 玩家在最后一刻合法使用唯一一次 Reroll 时，至少还有一个最小可读/可选择窗口；但不能通过 Reroll 把整个 Draft 倒计时重新拉满。

---

# 3. Timer Floor 只能在成功事务后生效

Reroll 必须作为一个原子事务：

```text
validate request
 -> build legal replacement offer
 -> commit exclusion
 -> commit new offer
 -> mark reroll used
 -> apply timer floor
 -> emit UI/state update
```

如果发生：

```text
request denied
already used
choice already locked
wrong draft_id
phase invalid
cannot produce legal replacement under explicit fallback contract
internal generation failure
```

则：

```text
old Offer stays
reroll.used stays false
excluded IDs unchanged
timer unchanged
```

禁止：

> 点击失败的 Reroll 也把时间抬回最小值。

否则会形成免费拖时间 exploit。

---

# 4. Timer Floor 不是可重复续时机制

因为每 side 每 Draft 只能成功 Reroll 一次，所以正常情况下每 side 最多触发一次 timer floor。

禁止通过：

- Preview toggle；
- 重复点击 disabled Reroll；
- failed generation retry；
- UI reopen；
- save/restore；
- AI evaluate loop；

重复刷新倒计时。

如果 Reroll 已成功：

```text
available = false
used = true
```

之后所有再次调用必须：

```text
DENY_REROLL_ALREADY_USED
```

并且 timer 不变。

---

# 5. Shared Draft Clock 与双方 Reroll

当前 Draft 使用共享 phase/timer。

因此任何一方的**成功** Reroll 请求，如果发生时：

```text
remaining < REROLL_MIN_REMAINING_SECONDS
```

共享 Draft remaining time 提升到该最小值。

这不是额外奖励，而是 Reroll 交互最低可操作窗口。

重要：

- AI 不得故意延迟到最后一刻只为给自己制造额外决策时间；
- AI decision policy 不应把“延迟触发 timer floor”作为策略动作；
- AI 正常应在自己的离散 Draft decision window 内完成 keep/reroll/lock；
- timer floor 是交互安全机制，不是可优化资源。

如果未来改为 per-side timer，需单独 Engineering Amendment；P1 不在此重构 phase timer architecture。

---

# 6. AI Reroll 权限对称，不等于行为完全相同

正式原则：

```text
Information Fairness = same
Reroll Permission = same
Decision Strength = can differ
```

### Easy AI

可以：

- 很少使用 Reroll；
- 只在当前 Offer 明显缺乏可用选择时考虑；
- 使用简单启发式决定 KEEP / REROLL。

### Normal AI

可以：

- 综合自己的当前构筑、费用、路线、公开战线状态；
- 判断当前三张是否都低价值；
- 合理保留或使用唯一 Reroll。

### Hard AI

不属于 P1 Batch B。

无论难度：

> **Reroll 权限都是 1 次，不增加。**

---

# 7. AI 必须“先决定重抽，再看到新 Offer”

这是 AI 公平的硬规则。

正确顺序：

```text
AI sees Own Offer A/B/C
+ legal AIObservation
+ own RerollState
        ↓
AI decision: KEEP or REROLL
```

若 KEEP：

```text
select from A/B/C
```

若 REROLL：

```text
commit discard A/B/C
        ↓
generate D/E/F
        ↓
A/B/C no longer selectable
        ↓
AI selects from D/E/F
```

禁止：

```text
generate D/E/F secretly
compare [A/B/C] vs [D/E/F]
choose whichever set contains better card
```

这等价于 AI 拥有“预览未来随机结果”的作弊权限。

Player 也同样：

> 一旦确认 Reroll，旧三张立即失去选择资格。

---

# 8. AI Reroll 不得读取 Player 私有 Draft 信息

AI 的 reroll decision 输入只允许：

```text
Own current Offer
Own RerollState
OwnPrivateState
PublicBattleState
ObservedEnemyHistory
```

禁止：

```text
Player current Offer
Player reroll future result
Player hidden exact route values
future RNG
future Offer queue
Player uncommitted hidden choice
```

即使 RoundDirector 内部持有这些数据，也不得进入 AI reroll policy。

---

# 9. AI Reroll 必须使用同一 Offer Pipeline

AI 不存在特殊抽牌接口。

Player 与 AI 都必须走：

```text
EligiblePoolSnapshot(side)
 -> OfferWeightPolicy(side)
 -> sample
 -> Diversity Guard
 -> Dominance Guard
 -> bounded resample
 -> OfferSnapshot
```

Reroll 仅追加：

```text
excluded_offer_ids = previous offer IDs
```

禁止 AI reroll：

- rarity boost；
- route guarantee；
- counter card guarantee；
-额外 resample 上限；
-旧 Deck fallback；
-比 Player 更宽松的 exclusion。

---

# 10. Per-Side RNG Isolation 必须继续成立

P0 已冻结 Player/AI RNG isolation。

因此：

```text
Player uses reroll
```

不得改变：

```text
AI current offer
AI future RNG sequence
AI reroll result
```

反之亦然。

必须新增 metamorphic tests：

### Test A

```text
same seeds
run 1: Player rerolls, AI keeps
run 2: Player keeps, AI keeps
```

要求：

```text
AI offer/random trace identical
```

### Test B

```text
run 1: AI rerolls
run 2: AI keeps
```

要求：

```text
Player current/future random trace identical
```

---

# 11. Reroll 与 Choice Lock

每 side 状态必须明确：

```text
UNDECIDED
REROLLED_UNDECIDED
LOCKED
```

Reroll 只允许在：

```text
UNDECIDED
```

成功后进入：

```text
REROLLED_UNDECIDED
```

选牌后：

```text
LOCKED
```

禁止：

```text
LOCKED -> reroll
```

也禁止：

```text
REROLLED_UNDECIDED -> second reroll
```

AI 同样遵守。

---

# 12. Reroll 与 Battlefield Preview

P0 Preview architecture 不变。

推荐/冻结交互：

- `DRAFT_VISIBLE` 时显示 Reroll button；
- 进入 `BATTLEFIELD_PREVIEW` 时选择内容与 Reroll button 随内容层隐藏；
- Peek/Return button 保持可用；
- 返回 `DRAFT_VISIBLE` 后 RerollState 完整恢复；
- timer 持续流逝；
- Preview 不触发 timer floor；
- 只有**成功 Reroll**才可能触发 timer floor；
- reroll 后再 Preview，再 Return，新 Offer 不变。

必须覆盖：

```text
Draft
 -> Preview
 -> Return
 -> Reroll at low time
 -> timer floor
 -> Preview
 -> Return
 -> choose
```

---

# 13. AI Orchestration Sequence

当前旧实现中 AI 会在 Draft 打开时立即从自己的 Offer 锁牌。

P1-05 迁移后，必须调整为：

```text
generate Player Offer
generate AI Offer
        ↓
AI receives own Offer + legal Observation
        ↓
AI decides KEEP / REROLL
        ↓
if REROLL:
    discard own Offer
    generate own replacement using own RNG
        ↓
AI chooses final card
        ↓
AI locks
```

仍然禁止 AI 等待/读取 Player 的隐藏选择后再决定是否 Reroll。

AI 可以在玩家操作期间已经完成自己的合法 decision，但这属于决策时序，不改变信息权限。

---

# 14. P1-05 Micro-Steps — Decision Gate 已解决

原：

```text
P1-05A REROLL DECISION GATE
```

现在改为：

```text
P1-05A confirmed reroll contract checkpoint
P1-05B per-side RerollState
P1-05C transactional reroll request/result
P1-05D exclusion-aware Offer request
P1-05E timer-floor integration
P1-05F player UI
P1-05G RoundDirector orchestration
P1-05H AI keep/reroll decision adapter
P1-05I timeout + reroll edge cases
P1-05J preview/reroll regression
P1-05K save/restore policy audit
P1-05L cross-side RNG metamorphic tests
P1-05M AI no-future-peek tests
P1-05 FINAL GO / NO-GO
```

每一步独立 checkpoint。

---

# 15. P1-05 Hard Tests

## T1 — Timer above floor

```text
remaining = 8
min = 3
reroll succeeds
=> remaining = 8
```

## T2 — Timer below floor

```text
remaining = 1.2
min = 3
reroll succeeds
=> remaining = 3
```

## T3 — No full reset

无论何时 Reroll：

```text
remaining_after != DRAFT_TIMEOUT
```

除非 `remaining_before` 本来就等于 `DRAFT_TIMEOUT`。

## T4 — Failed reroll gives no time

Reroll 请求失败：

```text
remaining unchanged
used unchanged
Offer unchanged
```

## T5 — Second reroll denied

第一次成功后第二次请求：

```text
denied
remaining unchanged
Offer unchanged
```

## T6 — Player exclusion

第一次：

```text
[A,B,C]
```

成功 Reroll 后正常结果不得包含 A/B/C，除非触发明确记录的小池 fallback contract。

## T7 — AI same permission

每 Draft：

```text
AI reroll_available == Player reroll_available == true initially
```

均只能成功一次。

## T8 — AI cannot preview replacement

AI reroll policy 在执行决定时：

```text
replacement_offer == not generated / inaccessible
```

## T9 — AI discard is final

AI 决定 Reroll 后：

```text
old Offer cannot be selected
```

即使新 Offer 更差。

## T10 — Cross-side RNG isolation

一方是否使用 Reroll，不改变另一方随机轨迹。

## T11 — Preview interaction

```text
reroll -> preview -> return
```

Offer IDs、used flag、exclusion、timer 均符合合同。

## T12 — Timeout after low-time reroll

低时间成功 Reroll：

```text
time raised to minimum
 -> countdown continues
 -> if no choice, normal timeout fallback
 -> reveal
 -> volley
```

不得创建第二种 timeout path。

---

# 16. P1-05 GO / NO-GO

任一以下情况为 RED：

- Reroll 重置完整 Draft timer；
- Reroll 失败也刷新时间；
- 可通过重复调用无限续时；
- Player/AI Reroll 权限数量不同；
- AI 先看 replacement 再决定是否 Reroll；
- AI 可从旧 Offer 与新 Offer 二选一；
- AI Reroll 使用更高 rarity/更多 Guard retries；
- 一方 Reroll 扰动另一方 RNG；
- Reroll 允许旧 Deck fallback；
- Reroll 后 Preview/Return 丢失 Offer/state；
- Reroll 改变 Route unlock / Selected Level；
- 选择已锁定后仍可 Reroll。

全部通过后：

```text
P1-05 = GO
```

---

# 17. 最终复述

> **Reroll 是一次性的重新抽样权，不是额外时间资源。正常情况下时间完全不重置；只在剩余时间低于最小可操作窗口时，成功 Reroll 才把剩余时间抬到该最小值。**
>
> **AI 和玩家拥有相同的一次免费 Reroll 权限。AI 是否使用它由 Decision Strength 决定，但 AI 必须先决定是否放弃当前 Offer，之后才能看到 replacement；不能通过未来随机结果作弊。**
