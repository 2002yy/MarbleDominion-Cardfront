# Cardfront P0 Checkpoint Entry

状态：**MANDATORY START HERE FOR P0 IMPLEMENTATION**

## Current Progress / 当前进度

- Current status authority: [`../PROJECT_STATUS.md`](../PROJECT_STATUS.md)
- Latest accepted checkpoint: [`P0-11J_log_signal.md`](P0-11J_log_signal.md)
- Latest decision: **GO**
- Only allowed formal next step: **P0-11K - Human North-Star Playtest**
- P1 status: **LOCKED** until `P0-11O_P0_FINAL_GO_NO_GO.md` records Final decision `GO` and a P1 allowed start commit.

The historical bootstrap instructions below remain the audit chain for a fresh repository review. They are not permission to restart or skip the latest checkpoint.

任何 Coding Agent 开始或继续 2026-08-07 Cardfront 战线/构筑重构前，必须按顺序阅读：

1. `docs/CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`
2. `docs/CARDFRONT_P0_EXECUTION_GUARDRAILS_2026-08-07.md`
3. `docs/CARDFRONT_P0_EXECUTION_DETAIL_BATCH_A_2026-08-08.md`
4. `docs/CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md`
5. `docs/cardfront_refactor_checkpoints/P0_MANDATORY_AUDIT_GATES.md`
6. `docs/CARDFRONT_P0_EXECUTION_DETAIL_BATCH_B_2026-08-08.md`
7. `docs/CARDFRONT_P0_EXECUTION_DETAIL_BATCH_C_2026-08-08.md`
8. `docs/CARDFRONT_REFACTOR_PLAN_2026-08-07.md`
9. 本目录中**最近一个已经 GO 的 checkpoint**

历史设计讨论 `docs/GRILLME_GAME_DESIGN_INTERVIEW.md` 只用于追溯理由，不得覆盖 Engineering Spec。

> **P0 Pre-Implementation Freeze 修正：** `CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md` 不重新设计 Cardfront；它冻结 Engineering Spec / Batch A 尚未下降到唯一实现语义的六项内容：`default_duel` Support topology、directional deployment geometry、suppression contract、capture idle policy、automatic placement resolver、deployment revision/stale-state contract。发现代码事实与该 Addendum 冲突时必须停在 `P0-00F NO-GO / AMENDMENT REQUIRED`，不得由实现 Agent自行选择另一套规则。

> **测试入口修正：** Batch A 早期关于“测试入口尚未确定”的判断已由 Batch C §0 更新。当前 P0 现役测试 authority 是 `scripts/tests/*.gd` 及 `.github/workflows/` 中的 active Godot headless workflows；`tests_legacy_disabled/` 只作为历史参考。

> **审计记录规则：** 所有会影响 gameplay authority、部署合法性、Support/Graph 真相、save/restore、AI 信息边界、Legacy Stronghold 退役或 P0 -> P1 放行的关键事项，必须形成证据或在对应 checkpoint 中明确记录为 follow-up / `AUDIT REQUIRED`。禁止把“尚未检查”默认解释成“已确认”；是否阻断日常施工由下述人工验收规则决定。完整审计门见 `P0_MANDATORY_AUDIT_GATES.md`。

> **2026-08-09 人工验收与检查节奏修正：** P0 日常推进改为人工产品验收主导。未完成、体验仍需调整或非关键日志问题可以明确记入 follow-up，并由人工决定是否允许进入下一施工 step；不得把它们伪写成 `PASS`，但也不再要求每个 micro-step 都重复完整回归或连续录像。实施期间只运行与本次 diff 直接相关的 focused checks；完整 headless regression、连续试玩、性能和全量日志检查集中在 batch / milestone / release candidate 边界。只有启动/解析失败、数据损坏、当前改动涉及的 authority 无法确定、相关 focused check 失败，或人工明确拒绝验收时，才阻断继续开发。人工推进验收不等于最终质量验收。

---

## Bootstrap Gate / 首次实施起点

如果本目录还没有 P0 checkpoint：

```text
NEXT = P0-00A Repository Ownership & Call-Chain Snapshot
```

不得直接开始 P0-01 Support gameplay code。

`P0-00A` ～ `P0-00E` 完成后，还必须执行：

```text
P0-00F Pre-Implementation Battle-line Freeze Verification
```

唯一合法 checkpoint：

```text
docs/cardfront_refactor_checkpoints/P0-00F_PRE_IMPLEMENTATION_BATTLELINE_FREEZE.md
```

必须存在：

```text
Decision: GO
```

之后才允许开始 `P0-01A1 Stable Support IDs`。

`P0-00F` 必须验证而不是重新决定：

1. `default_duel` stable Support IDs / anchors / frozen edges 可由当前地图事实无歧义 author；
2. `DIRECTIONAL_REAR_RECT_V1` 在 `40x40 / 50x50 / 40x50 / 40x60` 都 deterministic；
3. Support suppression 由 local territory-control evidence 驱动，但不污染 projectile territory-capture authority；
4. takeover capture 只在敌方 Support non-operational 后推进，无人时 2 秒 grace 后回退；
5. automatic / upgrade spawn 只能从当前 `DeploymentRules` 合法集合中 deterministic 选格；
6. Preview revision 不能作为 Commit permission token，Commit 必须使用当前 state 重新验证。

任一项无法证明：

```text
Decision: NO-GO / AMENDMENT REQUIRED
```

不得进入 P0-01。

---

## 强制审计落盘规则

所有后续 checkpoint 必须检查 `P0_MANDATORY_AUDIT_GATES.md` 中与当前 step 有关的项目，并至少记录：

```text
Mandatory audit gates touched:
Audit status per gate: PASS / FAIL / BLOCKED / NOT APPLICABLE
Evidence bound to source commit: YES/NO
Unverified assumptions remaining:
Legacy authority still reachable:
Second-authority risk:
Save/restore risk:
Cross-system regression evidence:
Manual evidence required before GO:
```

以下类型的未验证事项不得带入 `GO`：

- gameplay authority 不明确；
- Preview / Commit / AI / Auto Spawn 任一路径可能绕过统一部署规则；
- Support claim / operational / connectivity 存在双真相；
- save/restore 可能恢复过期 derived state；
- AI 可能读取 Player 私有 Offer/RNG 或未白名单 live state；
- Legacy Factory/Energy/Lab bonus 仍可能影响正式 gameplay；
- P1/P2 内容可能偷跑；
- 测试或人工证据来自不同 target commit。

这些情况必须明确写成：

```text
AUDIT REQUIRED
BLOCKED
Decision: NO-GO
```

而不是留 TODO 后继续下一步。

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

P0-01 ～ P0-05 额外必须声明：

```text
Pre-Implementation Freeze reference:
Frozen support topology affected? YES/NO
Frozen deployment geometry affected? YES/NO
Suppression/capture contract affected? YES/NO
Automatic placement contract affected? YES/NO
Deployment revision contract affected? YES/NO
Amendment required? YES/NO
```

只要 `Amendment required = YES`，当前 gameplay step 不得继续。

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
- 每一步临时写自己的测试脚本自证通过；
- 把普通 Support 做成 360° spawn circle；
- 根据最近敌人、graph predecessor 或当前连接路径动态旋转 `default_duel` Support deploy direction；
- 让 Online enemy Support 在未被 suppression 打到 `operational=false` 前直接推进 takeover capture；
- 把无人 capture progress 永久保存不回退；
- 让 automatic spawn 在没有合法格时退回旧 route slot / origin / arbitrary owned cell；
- 把 placement resolver 写成第二套 graph/deployment legality authority；
- 使用 stale Preview 结果绕过 Commit 时的 current-state validation。

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

P0-01 开工前额外复述：

> **`default_duel` 是两条可持续纵向战线加一个中央转线节点；普通 Support 只向己方侧/侧后方提供 deterministic rectangular deployment zone；Combat/territory pressure 先把敌方 Support 打到 non-operational，Control units 再完成 Claim；无人接管会在 grace 后回退；自动出生只能从 DeploymentRules 的当前合法格里 deterministic 选择；Preview 永远不能替代 Commit 时的当前规则复核。**

交付前：

> **如果只看这一批 diff，它是否让游戏更接近冻结目标，而不是仅仅让局部代码看起来更完整？**
