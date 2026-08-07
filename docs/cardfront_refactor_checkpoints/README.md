# Cardfront P0 Checkpoint Entry

状态：**MANDATORY START HERE FOR P0 IMPLEMENTATION**

任何 Coding Agent 开始或继续 2026-08-07 Cardfront 战线/构筑重构前，必须按顺序阅读：

1. `docs/CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`
2. `docs/CARDFRONT_P0_EXECUTION_GUARDRAILS_2026-08-07.md`
3. `docs/CARDFRONT_P0_EXECUTION_DETAIL_BATCH_A_2026-08-08.md`
4. `docs/CARDFRONT_P0_EXECUTION_DETAIL_BATCH_B_2026-08-08.md`
5. `docs/CARDFRONT_P0_EXECUTION_DETAIL_BATCH_C_2026-08-08.md`
6. `docs/CARDFRONT_REFACTOR_PLAN_2026-08-07.md`
7. 本目录中**最近一个已经 GO 的 checkpoint**

历史设计讨论 `docs/GRILLME_GAME_DESIGN_INTERVIEW.md` 只用于追溯理由，不得覆盖 Engineering Spec。

> **测试入口修正：** Batch A 早期关于“测试入口尚未确定”的判断已由 Batch C §0 更新。当前 P0 现役测试 authority 是 `scripts/tests/*.gd` 及 `.github/workflows/` 中的 active Godot headless workflows；`tests_legacy_disabled/` 只作为历史参考。

---

## 当前合法起点

如果本目录还没有 P0 checkpoint：

```text
NEXT = P0-00A Repository Ownership & Call-Chain Snapshot
```

不得直接开始 P0-01 Support gameplay code。

---

## 每一步开始前

必须声明：

```text
Step:
Source commit:
Original intent:
Engineering Spec sections:
Old authority:
Target authority:
Allowed mutation surface:
Read-only surface:
Forbidden changes:
Old behaviors that must survive:
Explicitly not solving:
Test evidence authority:
Expected checkpoint:
```

如果 `Old authority` 或 `Target authority` 无法回答：不得编码。

---

## 每一步结束后

必须创建对应：

```text
P0-XX_name.md
```

并明确：

```text
GO / NO-GO
```

`NO-GO` 时不得进入下一 micro-step。

---

## Batch A 额外硬检查

P0-00～P0-05 期间尤其禁止：

- 把 runtime `region_id` 当 Support identity；
- 把 `CardfrontCaptureInterceptor` 当 Support Capture owner；
- 顺手放开 Creature 跨中立/敌方领土移动；
- 只接 Preview/Commit/AI，却漏掉 automatic/upgrade entity spawn；
- 让旧 Factory/Energy/Lab bonus 与新 Support 同时继续影响正式 gameplay；
- 把 `network_connected` 等 derived state 当保存档永久真相；
- 每一步临时写自己的测试脚本自证通过。

---

## Batch B 额外硬检查

P0-06～P0-10 期间尤其禁止：

- Support visual 自己计算 ownership/connectivity/deployment legality；
- 为了“回看战场”继续移动、保存、恢复 `ChoiceShell.position`；
- Preview 恢复 battle simulation / Aim / CardSelection 输入；
- 为了 Offer independence 顺手改 rarity、eligibility、reroll、route unlock 或强制双方不撞牌；
- 把 `applied_upgrade_counts` 直接改名成 Level 而忽略 Echo 自动重复；
- Echo effect application 偷偷提升 player-facing Selected Level；
- 把 rarity/run rarity 当 per-card Level；
- 给 AIObservation 传完整 RunState/GameState/Node 作为“以后方便”的逃生口；
- AI 输入收窄后顺手调 archetype/score 权重掩盖字段差异；
- P0-06～P0-10 偷跑 P1 route/reroll/deep-card 内容。

---

## Batch C 额外硬检查

P0-11 / P0 -> P1 放行期间尤其禁止：

- 把 `tests_legacy_disabled/` 当现役 P0 通过证据；
- 只跑新 P0 runner，不跑受影响的现有 `scripts/tests` / active CI；
- 要求所有旧测试“原样不改全绿”，从而被迫保留已冻结退役的 Stronghold bonus；
- 反过来把旧失败长期标成 expected，而不迁移对应 test contract；
- 删除 workflow batch、加 `continue-on-error`、减少关键 audit 只为让 CI 变绿；
- 用 `CardfrontPerformanceSmokeTestRunner` 的“能加载”冒充真实无性能回归；
- 混用不同 commit 的 CI、截图、人工试玩、性能证据；
- 修复 P0-11 问题后继续沿用旧 target commit 的 evidence；
- 只有同一模块自己写的 unit test，没有 existing cross-system regression；
- 把 Yellow 调优债务当作容纳结构性 bug 的垃圾桶；
- 有任一 RED blocker 时宣布 conditional GO；
- 没有 `P0-11O_P0_FINAL_GO_NO_GO.md` 就进入 P1。

P0 最终唯一合法 P1 入口必须来自：

```text
docs/cardfront_refactor_checkpoints/P0-11O_P0_FINAL_GO_NO_GO.md
Final decision: GO
P1 allowed start commit: <sha>
```

P1 未来施工入口已经预先准备在：

```text
docs/cardfront_refactor_checkpoints/P1_README.md
```

但在上述 P0 Final GO 出现之前，`P1_README.md` 只是一份**锁定的未来入口**，不是开工许可。

---

## 统一复述

开工前：

> **我是在把当前 Cardfront 定向迁移到冻结设计，不是在借这次重构重新设计 Cardfront。**

交付前：

> **如果只看这一批 diff，它是否让游戏更接近冻结目标，而不是仅仅让局部代码看起来更完整？**
