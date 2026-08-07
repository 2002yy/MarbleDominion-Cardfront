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
4. `docs/CARDFRONT_REFACTOR_PLAN_2026-08-07.md` 作为高层路线索引
5. `P0-11O_P0_FINAL_GO_NO_GO.md`
6. 最近一个 P1 GO checkpoint

如果 Roadmap 的旧概述与更晚的 Batch 文档冲突，以 Engineering Spec + 最新 Mandatory Addendum 为准。

---

# 3. 已知 Roadmap 过时点

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

`CARDFRONT_P1_EXECUTION_DETAIL_BATCH_A_2026-08-08.md`

为准。

尤其：

- 旧 `deck_id -> exclusive upgrade_ids` 必须退出正式 eligibility authority；
- `deck_id` 不得成为第四种 card source；
- BasePool 必须 Player/AI 相同；
- Hero 与 Route 只能在 BasePool 之上增加合法来源。

---

# 4. P1 每一步开始前模板

```text
Step:
Source commit:
P0 final GO reference:
Original intent:
Engineering Spec sections:
P1 Batch section:
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
P1-03A Deep commitment design gate
P1-03B qualification/commitment split
P1-03C slot capacity
P1-03D sticky commitment
P1-03E deep pool eligibility cutover
   ↓
P1-A FINAL GO / NO-GO
```

没有上一 checkpoint GO，不得进入下一步。

---

# 6. P1 Batch A 硬禁令

尤其禁止：

- 在 P0 final GO 前开始 P1；
- 因路线系统方便而重写 SupportGraph / DeploymentRules；
- 把旧 `fortification_corps` / `barrage_control` 直接当新 Route；
- 在旧 exclusive deck 上简单叠 route cards；
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

# 7. Deep Slot 特别说明

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

# 8. 统一复述

P1 开工前：

> **我是在 P0 已冻结的战线系统上增加构筑分化，不是在借路线系统重新打开底层玩法。**

每步交付前：

> **这一 diff 是否只改变“什么卡有资格出现 / 行为怎样形成路线”，而没有偷偷改变 Draft 次数、部署权威、AI 信息边界或地图规则？**
