# Cardfront P1 Batch A — Deep Commitment Amendment — 2026-08-08

状态：**MANDATORY / RESOLVES P1-03 DEEP COMMITMENT DECISION GATE**

适用：P1-03A ～ P1-03E

上位关系：

1. `CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`
2. `CARDFRONT_P1_EXECUTION_DETAIL_BATCH_A_2026-08-08.md`
3. `CARDFRONT_P1_BATCH_A_ROUTE_CUTOVER_AMENDMENT_2026-08-08.md`
4. 本修订

> 本修订正式关闭 P1-03 中“Deep route 在何时占用深入槽位”的唯一产品 Decision Gate。
>
> 已确认：
>
> **路线先通过真实战场行为达到 `DEEP_QUALIFIED`；资格本身不占槽。玩家/AI必须主动执行一次明确的 Deep Commit，才消耗 1 个槽并进入 `DEEP_COMMITTED`。每局最多 2 个槽；Commit 不可撤销。只有 Committed 路线的 Deep cards 才进入未来 EligiblePool；Commit 本身不发卡、不加 Draft 次数。**

---

# 1. Deep Route 最终状态模型

P1 正式状态至少区分：

```text
UNFORMED
FORMING
TIER1_UNLOCKED
DEEP_QUALIFIED
DEEP_COMMITTED
```

其中：

```text
TIER1_UNLOCKED
```

表示该路线的 Tier1 卡已经可以进入未来 EligiblePool。

```text
DEEP_QUALIFIED
```

表示真实战场行为已经证明该路线具备深入资格，但尚未消耗深入槽位。

```text
DEEP_COMMITTED
```

表示玩家/AI已经明确决定把一个 Deep slot 投入该路线；从此该路线的 Deep tier 可以进入未来 EligiblePool。

硬不变量：

```text
DEEP_QUALIFIED != DEEP_COMMITTED
```

禁止使用一个：

```text
is_deep: bool
```

同时表示“有资格”和“已投入”。

---

# 2. Deep Slot Capacity

冻结：

```text
DEEP_SLOT_LIMIT = 2
```

每个 side 独立维护自己的 commitment：

```text
Player deep slots: 0..2
AI deep slots:     0..2
```

双方互不共享。

每成功 Commit 一条此前未 committed 的路线：

```text
used_slots += 1
```

最大：

```text
used_slots <= 2
```

禁止：

- 第三条路线以任何隐藏字段进入 Deep；
- Hero route 不计槽；
- “主路线”不计槽但仍发 Deep 卡；
- 稀有度达到某级后绕过槽位；
- 某张 Deep 卡自己跳过 RouteState。

---

# 3. Deep Qualification 的唯一来源

Deep qualification 必须来自：

```text
RouteProgressionState
+ battle-behavior evidence
+ route-specific deep_qualification_rule
```

必须继续遵守 Batch A：

> **实际战场行为为主，Card Selection 只能辅助。**

因此：

```text
CARD_SELECTION_AUX only
```

不能直接使路线进入 `DEEP_QUALIFIED`。

Qualification 不得由：

- Offer RNG；
- 某张卡是否刚好出现；
- reroll；
- hero identity 单独决定；
- AI difficulty；
- 当前比分落后补偿；
- 旧 `deck_id`；

直接产生。

---

# 4. Commit 是主动动作，不是自动最高两条

正式禁止：

```text
取 tendency score 最高的两条自动 DEEP_COMMITTED
```

也禁止：

```text
哪条先达到 deep threshold，哪条自动占槽
```

理由：

- 战场行为可以是阶段性的；
- 早期临时打法不应自动永久锁死 Build；
- 玩家必须拥有最后的战略承诺权；
- AI 也应该通过自己的 Decision Strength 做合法 commitment，而不是后台系统替它选。

正式流程：

```text
battle behavior
 -> route progression
 -> DEEP_QUALIFIED
 -> explicit commit decision
 -> validate slot capacity
 -> DEEP_COMMITTED
 -> EligiblePool revision
```

---

# 5. Commit 不通过抽到 Deep 卡触发

禁止：

```text
Offer 中出现 Deep 卡
 -> 玩家选择
 -> 这时才偷偷占槽
```

原因：

1. Deep card 在 Commit 前本来就不应 eligible；
2. 随机 Offer 不应决定玩家是否有机会正式投入路线；
3. 这会把路线承诺权重新交给 RNG。

正确顺序：

```text
Commit first
 -> Deep card becomes eligible for future Draft
```

不是：

```text
Deep card appears first
 -> selection commits route
```

---

# 6. Commit 不发卡、不加抽卡次数

成功 Commit 只允许：

```text
RouteState changes
Deep slot consumed
EligiblePool revision increments
future Draft may include Deep cards
UI route status updates
telemetry event recorded
```

禁止：

```text
immediate grant Deep card
immediate Selected Level +1
immediate free Draft
immediate bonus reroll
next Offer guarantee Deep card
increase rarity
```

继续贯彻：

> **解锁的是可能性，不是奖励发放。**

---

# 7. Commitment 不可撤销

冻结：

```text
DEEP_COMMITTED = match-sticky
```

一旦成功 Commit：

```text
route remains DEEP_COMMITTED until match ends
slot remains consumed until match ends
```

禁止：

- refund slot；
- route respec；
- Commit A 拿强卡后退出，再 Commit C；
- 因 tendency 下降自动取消；
- 因 Support 丢失自动取消；
- 因卡牌满级自动取消。

未来若要加入 respec，属于新的产品设计，不是 P1 tuning。

---

# 8. 两个槽满后的语义

合法例子：

```text
Mobility = DEEP_COMMITTED
Control  = DEEP_COMMITTED
Heavy    = DEEP_QUALIFIED
Fire     = TIER1_UNLOCKED
```

此时：

- Mobility Deep cards：eligible；
- Control Deep cards：eligible；
- Heavy Tier1 cards：仍 eligible；
- Heavy Deep cards：blocked by `deep_slot_capacity_full`；
- Fire Tier1 cards：仍 eligible。

禁止：

```text
2 slots full
 -> all non-committed route cards disappear
```

最多两条 Deep，不等于只能存在两条路线。

---

# 9. Commit API Contract

推荐建立明确 command/result，而不是 UI 直接改 RouteState：

```text
request_deep_commit(side_id, route_id) -> DeepCommitResult
```

Result 至少包含：

```text
success
side_id
route_id
previous_state
new_state
used_slots_before
used_slots_after
reason_code
eligible_pool_revision_before
eligible_pool_revision_after
```

推荐 reason codes：

```text
OK
NOT_QUALIFIED
ALREADY_COMMITTED
SLOT_LIMIT_REACHED
UNKNOWN_ROUTE
WRONG_SIDE
PHASE_NOT_ALLOWED
MATCH_NOT_ACTIVE
```

UI、AI 都调用同一个 authority。

禁止：

```text
player UI: route_state.deep_committed = true
```

或 AI 直接写数组。

---

# 10. Commit 的合法时机

为了避免战场中突然弹窗/输入冲突，P1 初版默认只允许在**构筑决策窗口**完成玩家 Commit。

推荐合法窗口：

```text
DRAFT_PAUSED
```

可在当前 Draft 的 route/tendency 小区域中操作。

不要求 Commit 必须占用三选一的一张卡。

禁止 P1 初版：

- 战斗执行中弹全屏 modal；
- Aim 瞄准过程中抢输入；
- Volley 飞行中暂停战斗确认路线；
- 自动在阈值达成瞬间弹窗。

如果路线在战斗中刚达到 `DEEP_QUALIFIED`：

```text
record qualification
 -> next legal Draft window shows “已可深入”
```

---

# 11. Player UI Contract

默认战场不常驻路线树。

在 Draft 阶段显示粗粒度路线状态：

```text
机动    已可深入   [深入]
控制    正在形成
重装    已解锁
```

成功 Commit 后：

```text
机动    已深入
深入路线 1/2
```

第二条后：

```text
深入路线 2/2
```

其他已 Qualified 路线显示：

```text
已具备深入条件 · 深入槽已满
```

UI 不显示内部 exact tendency score。

禁止：

- UI 自己判定 Qualified；
- UI 自己减 slot；
- UI 点击后先显示成功再异步让 runtime 失败；
- 把 Deep Commit 做成新的货币消费。

---

# 12. AI Commitment Contract

AI 与玩家拥有相同：

```text
DEEP_SLOT_LIMIT = 2
qualification rules
commit API
Deep card eligibility rule
```

AI 不允许：

- 自动获得第 3 个 slot；
- 提前知道未来 Offer；
- 看玩家隐藏路线 exact score；
- 看 future RNG；
- 在未 Qualified 时 Commit。

AI 的区别只来自 Decision Strength。

### Easy

可以采用较简单 commitment policy：

- route 已 Qualified；
- 与当前已有公开/自身构筑有明显一致性；
- 有 slot；
- 以较高阈值才 Commit；
- 不做复杂跨路线未来价值模拟。

### Normal

可以考虑：

- 已有 Selected Levels；
- 已解锁 Tier1 构筑；
- 当前战线实际使用方式；
- 两个 slot 之间的协同/重复程度；
- 剩余成长窗口。

但仍不得搜索未来随机牌。

Hard 属 P2。

---

# 13. EligiblePool Integration

Deep cards 的硬 Eligibility：

```text
route_state == DEEP_COMMITTED
```

不是：

```text
route_state >= DEEP_QUALIFIED
```

blocked reason：

```text
route_deep_not_committed
```

若 Qualified 但 2 slots 已满：

```text
deep_slot_capacity_full
```

Commit 成功后：

```text
EligiblePool revision += 1
```

但当前已经打开的 Offer 不自动替换。

推荐：

> Commit 影响“未来生成的 Offer”，不在同一个已经生成完的 Offer 中热插入新 Deep 卡。

这样避免：

```text
看到当前三张不好
 -> Commit route
 -> 当前 Offer 突然变牌
```

Commit 后若本 Draft 仍有未使用 Reroll，则 Reroll 生成的新 Offer可以读取**已经更新后的 EligiblePool**；这是正常的，因为 Reroll 本来就是新的 Offer generation transaction。

但不得因此额外赠送 Reroll。

---

# 14. Qualification / Commit 与 Reroll 的边界

允许：

```text
current Draft opened
route already DEEP_QUALIFIED
player commits
EligiblePool revision changes
player uses own still-available reroll
replacement Offer uses new pool
```

不允许：

```text
commit
 -> auto reroll
```

Reroll 权限与路线 commitment 完全分离。

AI 同理。

---

# 15. Save / Restore

若正式保存支持 mid-match：

必须保存：

```text
route tendency/progression state as contract requires
tier1 unlocked routes
deep qualified routes
deep committed routes
used deep slots
```

恢复时：

- committed sticky 保持；
- slot usage 从 committed routes 验证/重建；
- 不允许 snapshot 中 `used_slots=1` 但 committed routes=2；
- EligiblePool 从恢复后的正式 RouteState 重建。

推荐 authority：

```text
committed route IDs = persisted truth
used_slots = derived/validated count
```

避免两个独立字段漂移。

---

# 16. Telemetry / Audit

至少记录：

```text
route_qualified
route_commit_requested
route_commit_succeeded
route_commit_denied
route_id
side_id
round_number
match_time
used_slots_before/after
reason_code
```

P1 cadence 分析还需要：

```text
first_tier1_unlock_round
first_deep_qualified_round
first_deep_commit_round
second_deep_commit_round
first_deep_card_offer_round
first_deep_card_selected_round
first_deep_card_deployed_or_effective_round
```

注意：

> `Deep committed` 与 `真正拿到/使用 Deep card` 是两个不同时间点。

---

# 17. Required Tests

## 17.1 Qualification Does Not Consume Slot

```text
route -> DEEP_QUALIFIED
```

断言：

```text
used_slots unchanged
Deep cards blocked
```

## 17.2 Explicit Commit Consumes Exactly One

第一次成功 Commit：

```text
0 -> 1
```

重复 Commit 同一路线：

```text
still 1
DENY/NO-OP
```

## 17.3 Two Slot Limit

A Commit：成功。

B Commit：成功。

C Commit：失败 `SLOT_LIMIT_REACHED`。

A/B Deep cards eligible；C Deep cards blocked；C Tier1 仍可 eligible。

## 17.4 Not Qualified Cannot Commit

`TIER1_UNLOCKED` 但未 Deep Qualified：Commit 必须失败。

## 17.5 Commit Sticky

后续 tendency 下降、支点丢失、战线改变：Committed 不取消。

## 17.6 No Immediate Grant

Commit 后：

- Selected Level 不变；
- current Offer 不变；
- Draft count 不变；
- Reroll availability 不变；
- next future Offer eligible set 才变化。

## 17.7 Player / AI Same Authority

相同 RouteState、slot capacity 条件下，同一个 Commit validator 得到相同合法性。

## 17.8 Save Roundtrip

Committed A/B restore 后仍为 A/B，slot count=2，C Deep 仍 blocked。

---

# 18. P1-03 Revised Micro-Steps

原：

```text
P1-03A Deep commitment design gate
```

现已关闭。

正式顺序：

```text
P1-03A confirmed commitment contract checkpoint
P1-03B RouteState qualification/commitment split
P1-03C DeepCommit command/result authority
P1-03D two-slot capacity validator
P1-03E player Draft-window commit UI
P1-03F AI commit adapter using same authority
P1-03G EligiblePool Deep cutover
P1-03H reroll/current-offer interaction regression
P1-03I save/restore migration
P1-03J telemetry/cadence hooks
P1-03K deterministic tests
P1-03 FINAL GO / NO-GO
```

---

# 19. P1-03 GO / NO-GO

必须全部满足：

1. Deep qualification 不自动占槽；
2. Commit 是明确动作；
3. 每条成功 Commit 只占 1 slot；
4. 每 side 上限 2；
5. Commit 不可撤销；
6. 第三条 Deep route 被拒绝但 Tier1 仍保留；
7. Commit 不直接发卡；
8. Commit 不增加 Draft；
9. Commit 不赠 Reroll；
10. Deep cards 只有 committed route 才 eligible；
11. current Offer 不因 Commit 自动变更；
12. Player / AI 调同一个 commit authority；
13. AI 无未来信息；
14. Save/restore 不漂移；
15. telemetry 能区分 Qualified / Committed / Deep card actually obtained。

任一失败：`P1-03 = NO-GO`。

---

# 20. Anti-Drift Restatement

实现 Agent 在 P1-03 开工前必须复述：

> **战场行为决定我“有资格深入什么”，明确 Commit 决定我“真正押注什么”；随机 Offer 只能决定我之后可能拿到哪张牌，不能替我占 Deep slot。**

交付前必须回答：

> **如果把 RNG seed 换掉，只要路线行为与 Commit 决策相同，Deep slot 使用结果是否仍然相同？**

如果答案不是“是”：说明 RNG 已经越权影响路线承诺，必须停止并修正。
