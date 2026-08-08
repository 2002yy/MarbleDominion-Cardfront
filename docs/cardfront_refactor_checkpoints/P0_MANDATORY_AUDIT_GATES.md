# Cardfront P0 Mandatory Audit Gates

状态：**MANDATORY AUDIT CONTRACT / DO NOT SKIP**  
适用范围：P0-00 ～ P0-11，以及 P0 -> P1 放行。

本文不增加任何玩法，也不替代 Engineering Spec / Guardrails / Batch A-C / Pre-Implementation Freeze Addendum。

它只解决一个执行风险：

> **凡是当前不能立即证明的关键事实，要么现在审计并形成证据，要么在对应规划/Checkpoint 中明确标成 `AUDIT REQUIRED`；禁止靠聊天记忆、Agent 推测或“应该没问题”继续推进。**

---

# 1. 总规则

每个涉及下表内容的 micro-step，在 `GO` 前必须满足二选一：

1. **AUDITED**：已有同一 Source commit 的代码/测试/运行证据；
2. **BLOCKED / AUDIT REQUIRED**：尚不能验证，Checkpoint 必须明确阻断下一步。

禁止第三种状态：

```text
NOT CHECKED BUT ASSUMED OK
```

任何审计证据都必须绑定：

```text
Source commit:
Target step:
Evidence type: static / automated / manual / performance / save-restore
Evidence source:
Decision: PASS / FAIL / BLOCKED
```

不同 commit 的测试、截图、人工试玩、性能数据不得拼成一个 GO。

---

# 2. P0-00：实施前审计门

## P0-00A — Repository Ownership & Call-Chain Snapshot

**AUDIT REQUIRED**

必须落盘，而不是只在聊天中口头确认：

- Stronghold sample -> Draft / Volley / UI consumer chain；
- runtime `region_id` allocation mechanism，确认不能作为 stable Support identity；
- Deployment Preview / Validate / Commit chain；
- Draft `RoundDirector -> DraftSystem -> ThreeChoicePanel` chain；
- AI Commander 当前输入路径；
- Map / Region / Route / Gate owner；
- `territory_capture` 与未来 `support_capture` 的 authority 分离；
- Creature movement 的 own-territory constraint；
- Upgrade / Automatic Entity Spawn 绕过 DeploymentRules 的旧路径；
- Save / RuntimeSnapshot 的兼容性表面；
- 当前 active test authority 与人工启动入口。

若任何 owner/call-chain 仍不清楚：

```text
Decision: NO-GO
```

## P0-00B — Baseline Regression Capture

**RUNTIME AUDIT REQUIRED**

静态源码不能替代本项。

至少记录：

- mode boot / enter duel；
- Draft -> Aim -> Volley/Execution；
- Command Point 存在；
- Legacy Stronghold bonus 当前真实运行行为；
- 当前 3/4-choice 行为；
- Creature 至少一次正常行动；
- automatic/upgrade spawn 至少一次基线行为；
- two-lane / bridge 基线；
- Loadout/Draft UI 的关键显示/隐藏行为；
- 当前 warning / error / log noise；
- 当前性能只作为 baseline observation，不得用“能启动”冒充 FPS benchmark。

缺运行证据：`BLOCKED`。

## P0-00C — Frozen Delta Ledger

**DESIGN DELTA AUDIT REQUIRED**

必须把每个待改行为分成：

```text
MUST CHANGE
MUST PRESERVE
MUST RETIRE
OUT OF SCOPE
```

不得把 Legacy Stronghold bonus 同时列为“要退役”和“必须保留 gameplay”。

## P0-00D — Test Harness Truth

**TEST AUTHORITY AUDIT REQUIRED**

必须确认：

- active authority = `scripts/tests/*.gd` + active `.github/workflows/`；
- `tests_legacy_disabled/` 只作历史参考；
- Godot headless command 可复制；
- assertion fail -> non-zero；
- 0 tests 不能伪装成 PASS；
- all pass -> zero；
- 新 P0 test 不能只测自己模块后自证完整回归。

## P0-00E — Golden Baseline Contract

**AUTOMATED BASELINE AUDIT REQUIRED**

Golden 只固定结构性 contract：

- mode boot；
- duel sides；
- phase progression；
- Command Point；
- offer-size baseline；
- two-lane metadata；
- Legacy Stronghold bonus 当前确实仍影响旧 gameplay。

禁止把随机 Offer ID、随机视觉像素、瞬时 FPS 录成不可变 golden。

## P0-00F — Pre-Implementation Battle-line Freeze Verification

**FINAL PRE-IMPLEMENTATION AUDIT GATE**

必须完全遵循 `CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md`。

至少验证：

- stable Support IDs / anchors；
- frozen topology exact reproduction；
- `DIRECTIONAL_REAR_RECT_V1` 在 40x40 / 50x50 / 40x50 / 40x60 deterministic；
- suppression evidence source；
- Support Capture owner；
- automatic spawn bypass path；
- deployment revision invalidation sources。

任一项不能证明：

```text
Decision: NO-GO / AMENDMENT REQUIRED
```

没有 `P0-00F = GO`，不得开始 P0-01 gameplay code。

---

# 3. P0-01：Support Model / Save Boundary 审计

**重点：stable identity、单一 runtime truth、save/restore。**

必须审计：

- `support_id` 是否 authored/stable；
- runtime `region_id` 是否仅作映射引用；
- SupportDefinition 是否混入 Factory/Energy/Lab generic bonus；
- `claim_owner` / `operational` 的唯一写 authority；
- `Online` 是否保持 derived expression；
- `network_connected` 是否保持 derived/cache，而不是永久存档真相；
- save/load 后 graph-derived state 是否重算；
- 旧 snapshot stronghold 字段是否仅保留兼容读取，而不继续驱动新 gameplay；
- restore 是否会产生双 authority。

发现以下情况直接 NO-GO：

- `region_id` 被持久化为 Support identity；
- `Online` 作为可独立写字段；
- `network_connected` 与 graph resolver 可产生冲突真相；
- 新 Support 与旧 Stronghold bonus 同时成为正式 gameplay authority。

---

# 4. P0-02：Support Capture 审计

**重点：territory_capture != support_capture。**

必须审计：

- `CardfrontCaptureInterceptor` 仍只属于 projectile/territory capture；
- Support Capture 有独立、明确的 owner；
- contributor extraction 只读取必要 entity data，不读取整个 SceneTree；
- operational enemy Support 在 suppression 前不能直接 takeover；
- contested 双方存在时 progress freeze；
- nobody 时 grace + decay 合同正确；
- claim change 不自动等于 connected/Online；
- Capture 不改变全局 Creature movement legality；
- offline Support 不删除/传送现有单位；
- capture/kill 不产生额外 Draft、资源或被动奖励。

若为了让 Capture 可玩而需要 Creature 跨中立/敌方自由移动：

```text
AMENDMENT REQUIRED
```

不得在 P0-02 偷改。

---

# 5. P0-03：Support Graph / Cache 审计

**重点：唯一 connectivity authority + event-driven recompute。**

必须审计：

- authored edges 与 frozen topology 完全一致；
- GateConnectivity 未成为 SupportGraph authority；
- BFS/DFS 只穿过 claimed + operational nodes；
- Core 是 graph root；
- 两条主线与 Center transfer 行为符合冻结图；
- claim/operational/topology mutation 才触发 recompute；
- idle、hover、cursor frame 不持续 BFS；
- restore 后 connectivity 重算；
- graph result 的唯一 authoritative resolver 明确。

以下任一存在直接 NO-GO：

- 第二套 graph resolver；
- 每帧 BFS；
- runtime 根据距离自动增删 frozen edges；
- save 中的 connected 值覆盖当前 graph 真相。

---

# 6. P0-04：Deployment 四消费者一致性审计

**P0 中最高风险审计之一。**

最终必须同时证明四个消费者收敛到同一 authoritative legality：

```text
1. Player Preview
2. Player Commit
3. AI Placement
4. Upgrade / Automatic Entity Spawn
```

必须审计：

- `DeploymentRules` 是唯一 legality authority；
- Preview 只显示规则结果，不自行生成额外合法格；
- Commit 通过现有 validator facade，并在消费资源前失败；
- Commit 永远使用 current state revalidation；
- stale Preview revision 不能成为 permission token；
- AI 无专属非法 fallback；
- automatic placement 先获得合法集合，再由 deterministic resolver 排序选格；
- preferred support/route 只影响合法集合内排序，不改变 legality；
- 无合法格时明确 `no_valid_deployment_source`，不得 fallback 到旧 route slot/origin/arbitrary owned cell；
- Core fallback 只使用冻结的最低部署来源；
- 普通 Support zone 不是 360° circle；
- deploy direction 不根据最近敌人/路径实时旋转。

四消费者任何一个绕过规则：

```text
P0-04 = NO-GO
```

---

# 7. P0-05：Legacy Stronghold Retirement 审计

**P0 中另一最高风险审计。**

必须按 consumer -> producer -> UI semantics -> save compatibility -> global search 的顺序确认退役。

全仓重点搜索：

```text
FACTORY
ENERGY
LAB
stronghold bonus
draft_choice_count
volley bonus
attack level bonus
stronghold_active
stronghold_type
```

允许保留：

- 迁移期 geometry metadata；
- backward-compatible save read；
- historical docs/tests。

禁止继续影响正式 gameplay：

- Factory volley count bonus；
- Energy attack-level bonus；
- Lab extra Draft choice；
- 任意“capture support -> generic passive reward”。

若旧 UI、AI、RoundDirector、save restore 中任何一个仍把这些旧 bonus 当新 gameplay truth：

```text
P0-05 = NO-GO
```

---

# 8. P0-06 ～ P0-10：后续专项审计

## P0-06 Visuals

审计 Support visual 是否纯 presenter：

- 不自己计算 claim/connectivity/deployment legality；
- 默认不永久画全图箭头网络；
- 选中部署卡时才显示合法半透明区；
- visual cache 不能成为 gameplay truth。

## P0-07 Draft Preview Bug

审计：

- preview 只切 visibility/state；
- 不移动、保存、恢复 `ChoiceShell.position`；
- Peek 不恢复 battle simulation / Aim / CardSelection 输入；
- 多次开关后布局无漂移。

## P0-08 Offer Independence

审计：

- Player/AI RNG state 独立；
- Offer state 独立；
- 不顺手改 rarity / eligibility / reroll / route unlock；
- 不人为要求双方永不撞牌；
- AI 不能读取 Player 私有 Offer/RNG state。

## P0-09 Duplicate -> Level API

审计：

- Selected duplicate 提升 per-card Level；
- 不创建独立重复永久实例；
- `applied_upgrade_counts` 的历史/运行语义被正确迁移；
- Echo/automatic reapply 不偷偷提升 player-facing Selected Level；
- rarity != Level。

## P0-10 AI Information Boundary

审计：

- AIObservation 字段 whitelist；
- 不传完整 RunState/GameState/Node 作为逃生口；
- Player private Offer/RNG 不可见；
- Easy/Normal 使用同一信息边界；
- 难度差异只来自 decision quality；
- 收窄字段时不顺手调 AI archetype/score 掩盖行为变化。

---

# 9. P0-11：最终独立收敛审计

P0-11 不允许由“刚实现功能的同一个局部 unit test”自我认证。

最终至少需要五类证据汇合：

```text
1. targeted new-contract tests
2. affected existing cross-system regression
3. active CI/headless evidence
4. manual north-star evidence
5. forbidden-diff / legacy-global-search evidence
```

性能相关另列真实证据；当前 performance smoke 的“能加载”不能冒充 FPS benchmark。

修复任何 P0-11 blocker 后，原 target commit 的 evidence 全部视为过期，必须针对新 commit 重跑相关证据。

存在任一 RED blocker：

```text
Final decision: NO-GO
```

唯一 P1 放行文件仍为：

```text
docs/cardfront_refactor_checkpoints/P0-11O_P0_FINAL_GO_NO_GO.md
Final decision: GO
P1 allowed start commit: <sha>
```

---

# 10. Checkpoint 强制审计字段

从本文生效后，每个后续 P0 checkpoint 至少增加：

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

如果 `Unverified assumptions remaining` 中存在会改变 gameplay authority、合法性、存档真相、AI 信息边界或 P0/P1 scope 的事项：

```text
Decision != GO
```

---

# 11. 最终执行口令

> **能现在审计的，现在审计；不能现在审计的，必须在规划/Checkpoint 中醒目标红并阻断 GO。未经验证的关键事实永远不自动升级成“已确认”。**
