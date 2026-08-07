# Cardfront P0 Checkpoint Entry

状态：**MANDATORY START HERE FOR P0 IMPLEMENTATION**

任何 Coding Agent 开始或继续 2026-08-07 Cardfront 战线/构筑重构前，必须按顺序阅读：

1. `docs/CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`
2. `docs/CARDFRONT_P0_EXECUTION_GUARDRAILS_2026-08-07.md`
3. `docs/CARDFRONT_P0_EXECUTION_DETAIL_BATCH_A_2026-08-08.md`
4. `docs/CARDFRONT_REFACTOR_PLAN_2026-08-07.md`
5. 本目录中**最近一个已经 GO 的 checkpoint**

历史设计讨论 `docs/GRILLME_GAME_DESIGN_INTERVIEW.md` 只用于追溯理由，不得覆盖 Engineering Spec。

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

## 统一复述

开工前：

> **我是在把当前 Cardfront 定向迁移到冻结设计，不是在借这次重构重新设计 Cardfront。**

交付前：

> **如果只看这一批 diff，它是否让游戏更接近冻结目标，而不是仅仅让局部代码看起来更完整？**
