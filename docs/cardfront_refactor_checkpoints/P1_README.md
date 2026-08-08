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

# 2. P1 必读顺序

1. `docs/CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`
2. `docs/CARDFRONT_P0_EXECUTION_DETAIL_BATCH_C_2026-08-08.md` 中 P0 Final Evidence / P1 Gate
3. `docs/CARDFRONT_P1_EXECUTION_DETAIL_BATCH_A_2026-08-08.md`
4. `docs/CARDFRONT_P1_BATCH_A_ROUTE_CUTOVER_AMENDMENT_2026-08-08.md`
5. `docs/CARDFRONT_P1_BATCH_A_DEEP_COMMITMENT_AMENDMENT_2026-08-08.md`（进入 P1-03 必读）
6. `docs/CARDFRONT_P1_EXECUTION_DETAIL_BATCH_B_2026-08-08.md`（进入 P1-04 以后必读）
7. `docs/CARDFRONT_P1_BATCH_B_REROLL_DECISION_AMENDMENT_2026-08-08.md`（进入 P1-05 必读）
8. `docs/CARDFRONT_P1_EXECUTION_DETAIL_BATCH_C_2026-08-08.md`（进入 P1-07 以后必读）
9. `docs/CARDFRONT_REFACTOR_PLAN_2026-08-07.md` 作为高层路线索引
10. `P0-11O_P0_FINAL_GO_NO_GO.md`
11. 最近一个 P1 GO checkpoint

如果 Roadmap 或 Batch A/B 早期表述与更晚的 Mandatory Amendment 冲突，以 Engineering Spec + 最新 Mandatory Amendment/Addendum 为准。

---

# 3. 已知 Roadmap / Batch 过时点

## 3.1 P0-09 Level

Roadmap 早期写过：

```text
基于 applied_upgrade_counts 提供 Level API
```

该表述已被 P0 Batch B 源码审计修正。

正式语义：

```text
Selected Level authority
!=
applied_upgrade_counts / effect application history
```

Echo 自动重复 effect 不得提升 Selected Level。

---

## 3.2 P1 Eligible Pool

旧：

```text
deck_id
 -> exclusive upgrade_ids
 -> Draft eligibility
```

P1-01 必须正式切换为：

```text
BASE
+ HERO
+ ROUTE
 -> EligiblePoolBuilder
 -> Draft eligibility
```

P1-01 结束不是“双系统并存”，而是 authority 已完成切换。

硬规则：

- `deck_id -> exclusive upgrade_ids` 退出正式 eligibility authority；
- `deck_id` 不得成为第四种 card source；
- Player/AI BasePool 相同；
- Hero/Route 只是在 BasePool 上增加合法来源；
- `core_tactics / fortification_corps / barrage_control` 不得直接改名成新路线；
- Prematch 旧 Deck 选择不得继续改变正式候选池；
- 旧 save 可读 `deck_id`，但不能恢复旧 exclusive pool；
- 禁止 `new pool empty -> fallback legacy deck`；
- 必须有逐卡 old -> new source migration ledger。

---

## 3.3 Deep Commitment — 已冻结

原 P1-03A Decision Gate 已由：

`CARDFRONT_P1_BATCH_A_DEEP_COMMITMENT_AMENDMENT_2026-08-08.md`

正式关闭。

冻结：

```text
actual battlefield behavior
 -> DEEP_QUALIFIED
 -> explicit Commit
 -> consume exactly 1 Deep slot
 -> DEEP_COMMITTED
 -> future EligiblePool may include that route's Deep cards
```

并且：

```text
DEEP_SLOT_LIMIT = 2 per side
```

硬规则：

- `DEEP_QUALIFIED` 不占槽；
- 不自动取最高两条；
- 不按“先到阈值先占槽”；
- 不通过抽到 Deep card 才占槽；
- 玩家/AI 都必须显式调用同一 Commit authority；
- Commit 不可撤销；
- 第三条 Qualified 路线可以保留 Tier1，但 Deep blocked；
- Commit 不发卡；
- Commit 不加 Draft；
- Commit 不赠 reroll；
- 只有 `DEEP_COMMITTED` 的路线 Deep cards 才 eligible；
- Commit 后当前已生成 Offer 不自动变化；
- 若当前 Draft 仍有自己的合法 reroll，reroll 可读取新的 EligiblePool。

---

## 3.4 P1 Batch B — Offer / Reroll / Upgrade

正式细节：

- `CARDFRONT_P1_EXECUTION_DETAIL_BATCH_B_2026-08-08.md`
- `CARDFRONT_P1_BATCH_B_REROLL_DECISION_AMENDMENT_2026-08-08.md`

Offer：

```text
EligiblePool
 -> Weight
 -> Sample
 -> Diversity Guard
 -> Dominance Guard
 -> bounded resample
```

禁止导演式 counter 发牌和综合 PowerScore。

Reroll：

```text
Player: 1 free full reroll / Draft
AI:     1 free full reroll / Draft
```

成功后：

```text
remaining_after = max(remaining_before, REROLL_MIN_REMAINING_SECONDS)
```

不重置完整 Draft timer。

只有成功提交新 Offer 才应用 timer floor。

AI：

```text
see own current Offer
 -> decide KEEP/REROLL
 -> if REROLL, old Offer permanently discarded
 -> only then generate replacement
```

禁止 future peek。

Upgrade：

- per-card authored LevelTrack；
- Selected Level 与 effect application 分权；
- Echo replay resolved effect step，不增加 Selected Level；
- quantity 是卡身份的一部分，不是第二套无限等级。

---

## 3.5 P1 Batch C — Representative Routes / Cadence / Balance / AI / Final Gate

正式细节：

`CARDFRONT_P1_EXECUTION_DETAIL_BATCH_C_2026-08-08.md`

P1 representative validation archetypes：

```text
Mobility / Flank
Breakthrough / Heavy-Firepower
Control / Engineering
```

它们是验证战略职责，不强制最终世界观命名。

P1 必须证明：

- 三轴 Combat/Mobility/Control 真正在战场中不同；
- Deep 强卡能显著兑现路线投入；
- 强卡仍不能独自完成战争；
- 基础/弱卡中后期仍有合理阶段用途；
- Mature Build 有足够真实使用窗口；
- Easy/Normal 信息边界完全相同，只差 Decision Strength；
- P1 没有重写 P0 Battle-line / Deployment authority。

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

如果 `P0 authorities touched` 非 NONE：

1. 说明为什么；
2. 证明不是为了路线/AI实现方便；
3. 列出要重跑的 P0 evidence；
4. 必要时开 Engineering Amendment。

---

# 5. P1 当前合法顺序

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
P1-02 FINAL GO / NO-GO
   ↓
P1-03A confirmed Deep commitment contract checkpoint
P1-03B qualification/commitment state split
P1-03C DeepCommit command/result authority
P1-03D two-slot capacity validator
P1-03E player Draft-window commit UI
P1-03F AI commit adapter using same authority
P1-03G Deep EligiblePool cutover
P1-03H current-offer/reroll interaction regression
P1-03I save/restore migration
P1-03J telemetry/cadence hooks
P1-03K deterministic tests
P1-03 FINAL GO / NO-GO
P1-A FINAL GO / NO-GO
   ↓
P1-04A current weight/read-path audit
P1-04B OfferWeightBreakdown DTO
P1-04C rarity component extraction
P1-04D Hero/Route soft-weight components
P1-04E OfferTrace
P1-04F ChoiceSignature metadata
P1-04G Diversity Guard
P1-04H Dominance Guard
P1-04I bounded resample
P1-04J side-isolation regression
P1-04K statistical smoke
P1-04 FINAL GO / NO-GO
   ↓
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
   ↓
P1-06A current level/effect audit
P1-06B UpgradeTrack schema
P1-06C migration ledger
P1-06D LevelStep resolver
P1-06E atomic Level commit
P1-06F Echo replay migration
P1-06G starting-owned grant
P1-06H max-level eligibility
P1-06I card projection
P1-06J save migration
P1-06K regression tests
P1-06 FINAL GO / NO-GO
   ↓
P1-07A representative-route content audit
P1-07B route-role contracts
P1-07C existing-card migration mapping
P1-07D Mobility vertical slice
P1-07E Heavy/Firepower vertical slice
P1-07F Control/Engineering vertical slice
P1-07G cross-route fixtures
P1-07H route UI projection smoke
P1-07I route regression
P1-07 FINAL GO / NO-GO
   ↓
P1-08A cadence event/clock audit
P1-08B milestone telemetry schema
P1-08C deterministic round/time hooks
P1-08D route unlock timing report
P1-08E deep obtain/effective-use timing report
P1-08F mature-window evaluator
P1-08G no-extra-draft invariant tests
P1-08H seed/match distribution audit
P1-08I evidence-based tuning pass
P1-08 FINAL GO / NO-GO
   ↓
P1-09A capability-profile schema
P1-09B three-axis authored projection
P1-09C benchmark harness audit/reuse
P1-09D six fixed scenario fixtures
P1-09E representative-card profile pass
P1-09F strong-card specialty acceptance
P1-09G weak/basic late-use acceptance
P1-09H card UI projection
P1-09I telemetry hook migration
P1-09J balance artifact report
P1-09 FINAL GO / NO-GO
   ↓
P1-10A AI read-set + legacy deck dependency audit
P1-10B DecisionStrengthProfile schema
P1-10C Easy profile
P1-10D Normal profile
P1-10E existing Commander adapter
P1-10F route commitment policy
P1-10G reroll policy
P1-10H strategic/reactive decision windows
P1-10I observed-enemy-history integration
P1-10J explainability trace
P1-10K fairness metamorphic tests
P1-10L difficulty numerical-parity test
P1-10M deterministic match smoke
P1-10 FINAL GO / NO-GO
   ↓
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

没有上一 checkpoint GO，不得进入下一步。

---

# 6. P1 Batch A 硬禁令

尤其禁止：

- 在 P0 final GO 前开始 P1；
- 因路线系统方便而重写 SupportGraph / DeploymentRules；
- 把旧 `fortification_corps` / `barrage_control` 直接当新 Route；
- 在旧 exclusive deck 上简单叠 route cards；
- P1-01 后仍让 `deck_id` 改变 EligiblePool；
- 保留 Prematch 旧 Deck picker 并暗中映射到新 Route；
- new pool empty 时 fallback 旧 Deck；
- 未做 card-source migration ledger 就默认旧卡归属；
- Player/AI BasePool 不同；
- Hero 变成另一套完整互斥 deck；
- 同 ID 因多来源重复进入 candidate；
- Gameplay system 直接 `route_score += ...`；
- Card script 自己解锁路线；
- 只靠选卡完成 Deep qualification；
- route unlock 直接发卡或增加 Draft；
- opponent AI 读取 route exact score；
- qualification/commitment 用同一个 bool；
- Deep Qualified 自动占槽；
- 自动取 tendency 最高两条占槽；
- 第三条 route 绕过 `DEEP_SLOT_LIMIT=2`；
- Deep Commit 可撤销换线；
- Deep Commit 直接发卡/加 Draft/赠 reroll。

---

# 7. P1 Batch B 硬禁令

P1-04～P1-06 尤其禁止：

- 为提高路线概率复制 card ID；
- 固定 Base/Hero/Route 三个 Offer slot；
- 固定“应急/路线/转型”三个 slot；
- 当前敌军配置触发隐藏 counter 发牌；
- 综合 PowerScore 驱动 Dominance Guard；
- Guard 无限重抽；
- Guard 隐藏长期弱卡；
- reroll 提高 rarity/强制路线卡；
- reroll 触发额外 Draft；
- reroll fallback legacy Deck；
- reroll 重置完整 DRAFT_TIMEOUT；
- reroll 失败也刷新最低时间；
- 重复调用无限续时；
- Player/AI reroll 权限数量不同；
- AI 先看 replacement 再决定 reroll；
- AI 在 old/new Offer 中择优；
- cross-side RNG 相互扰动；
- per-card Level 与 rarity/effect cap 混淆；
- Echo replay 提升 Selected Level；
- starting-owned 伪造成 selection；
- 全卡统一 `+攻击/+血量/+数量`；
- maxed card 默认继续产生无效 Offer；
- UpgradeTrack 重开 P0 Deployment/Support authority。

---

# 8. P1 Batch C 硬禁令

P1-07～P1-11 尤其禁止：

- 一开始铺全路线目录；
- 把验证路线做成封闭职业树；
- Mobility 为了“够强”直接绕过 DeploymentRules；
- Heavy/Firepower 因 S/S+ specialty 自动被削平；
- Deep 卡 Combat/Mobility/Control 全部顶级；
- Control/Engineering 复活旧 Stronghold generic bonus；
- Engineer 成为唯一能占点的 mandatory tax；
- 两个 Deep slot 满后删除所有其他 Tier1 路线；
- kill/capture/support destruction 额外送 Draft；
- 落后方获得 bonus Draft 作为 P1 默认 comeback；
- 用 first Deep Commit 直接等价 Mature Build；
- 用固定 round 数主观替代真实 elapsed-time telemetry；
- 把三轴平均成 Overall Power；
- Benchmark 只输出一个平均分；
- 弱卡唯一价值是“还没抽到强卡”；
- Easy/Normal 使用不同信息字段；
- Normal 获得额外 HP/伤害/资源/reroll/Deep slot；
- 新建第二套 RouteAICommander 复制现有 AI；
- AI difficulty 每 physics frame 重算全局最优；
- legacy `deck_id` 继续影响 P1 AI；
- B1 simulation 为保留历史结果继续走旧 Deck candidate path；
- P1 为路线/AI重新创建 Deployment authority；
- 任一 RED blocker 下 conditional GO。

---

# 9. P1-01 Legacy Authority Kill Checklist

P1-01 结束必须证明：

```text
DraftSystem candidate source = EligiblePoolSnapshot
```

并通过：

- deck_id neutrality；
- DeckRegistry mutation probe；
- Hero provenance；
- Route provenance；
- old-save compatibility neutrality。

任一失败：`P1-01 = NO-GO`。

---

# 10. Deep Commitment 已冻结合同

每 side：

```text
DEEP_SLOT_LIMIT = 2
```

状态：

```text
TIER1_UNLOCKED
 -> DEEP_QUALIFIED
 -> explicit Commit
 -> DEEP_COMMITTED
```

只有最后一步占 1 slot。

Commit sticky，不可撤销。

Deep cards 只有 committed route 才进入未来 EligiblePool。

当前 Offer 不因 Commit 自动变化。

Player / AI 使用同一 Commit authority。

---

# 11. Reroll 已冻结合同

每 side 每 Draft：

```text
1 次免费完整 Reroll
```

成功后：

```text
remaining_after = max(
    remaining_before,
    REROLL_MIN_REMAINING_SECONDS
)
```

不重置完整 timer。

AI 必须先 KEEP/REROLL 决策，之后才能生成 replacement。

Easy/Normal 只改变使用策略，不改变权限。

---

# 12. P1 Final P2 Gate

P1 完成唯一合法文件：

```text
docs/cardfront_refactor_checkpoints/P1-11R_P1_FINAL_GO_NO_GO.md
```

必须包含：

```text
P1 RC commit: <sha>
Final decision: GO
P2 allowed start commit: <sha>
```

没有这三项：禁止进入 P2 gameplay implementation。

Final Evidence 必须来自同一 RC commit。

---

# 13. 统一复述

P1 开工前：

> **我是在 P0 已冻结的战线系统上，用 BASE + HERO + ROUTE 正式替换旧 exclusive Deck eligibility；路线资格由真实行为形成，Deep 由明确 Commit 决定。**

P1-04～P1-06：

> **Offer 是随机选择空间，不是导演系统；Reroll 是一次 veto，不是品质提升器；升级是卡牌自己的身份成长。**

P1-07～P1-11：

> **我是在证明构筑分化、强弱角色、成长窗口和 AI 公平真的成立，不是在借路线/平衡/AI 再发明第二套游戏。**

每步交付前：

> **这一 diff 是否让“地图战线 + 本局行为 + 构筑选择”闭环更清楚，并且没有让单个子系统为了自洽而越权？**
