# Cardfront P0 Execution Detail — Batch C — 2026-08-08

状态：**MANDATORY ADDENDUM / P0 FINAL ACCEPTANCE & HANDOFF CONTRACT**  
适用：P0-11 + P0 -> P1 Gate  
上位文档：

1. `CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`
2. `CARDFRONT_P0_EXECUTION_GUARDRAILS_2026-08-07.md`
3. `CARDFRONT_P0_EXECUTION_DETAIL_BATCH_A_2026-08-08.md`
4. `CARDFRONT_P0_EXECUTION_DETAIL_BATCH_B_2026-08-08.md`
5. 本文
6. `CARDFRONT_REFACTOR_PLAN_2026-08-07.md`

> 本文不增加玩法。
>
> Batch A/B 解决“怎么迁移不跑偏”；Batch C 解决“怎么证明迁移真的完成，而不是实现 Agent 用自己写的测试证明自己正确”。
>
> **P0-11 不是最后跑一次 tests 的形式步骤，而是独立的证据收敛阶段。**

---

# 0. 先纠正 Batch A 的一处测试入口结论

## 0.1 Batch A §1.1 的“测试入口尚未确定”已被仓库事实更新

Batch A 当时只看到根目录：

```text
tests_legacy_disabled/
```

因此写了“当前仓库没有可直接假定为现役的 `tests/`”。

进一步审计发现，仓库存在真正现役测试体系：

```text
scripts/tests/*.gd
.github/workflows/headless-tests.yml
.github/workflows/b1-simulation-tests.yml
.github/workflows/shared-upgrade-ai-tests.yml
.github/workflows/battlefield-entity-foundation-tests.yml
```

其中 `headless-tests.yml` 在 GitHub Actions 上使用：

```text
Godot 4.6.2-stable
--headless
--audio-driver Dummy
--script res://scripts/tests/<Runner>.gd
```

因此从本文起：

> **P0 的现役测试证据 authority 是 `scripts/tests` + 当前 GitHub Actions workflow，而不是 `tests_legacy_disabled/`。**

`tests_legacy_disabled/` 只可作为历史参考，不可被当作 P0 通过证据。

## 0.2 Batch A 的核心警告仍然有效，但含义修正

仍然禁止：

- Agent 临时写一个孤立脚本，然后称为“完整回归”；
- 只跑自己新增的测试，不跑现有受影响 CI runner；
- 把 `tests_legacy_disabled` 整体复活并顺手重构；
- 因为旧测试与新语义冲突，就把整个 workflow 删除/跳过。

修正后的要求：

```text
Existing active runner
+
New/updated contract runner
+
Cross-system regression
+
Manual north-star evidence
```

共同构成 P0 证据链。

---

# 1. 当前测试基础设施事实：P0-11 必须基于真实仓库

## 1.1 `headless-tests.yml` 已经是大范围结构回归入口

它当前覆盖多个 Cardfront 批次，包括但不限于：

- `DeploymentRulesTestRunner.gd`
- `CardfrontRuntimeSnapshotTestRunner.gd`
- `CardfrontTargetPreviewTestRunner.gd`
- `CardfrontMatchFlowClarityTestRunner.gd`
- `CardfrontPerformanceSmokeTestRunner.gd`
- `CardfrontUpgradeResolverTestRunner.gd`
- `CardfrontLiveRuntimeBoundaryTestRunner.gd`
- `CardfrontThreeChoiceRuntimeTestRunner.gd`
- `CardfrontRoundCombatTestRunner.gd`
- `CardfrontModeSmokeTestRunner.gd`
- `CardfrontStrongholdSystemTestRunner.gd`
- `CardfrontGateConnectivityTestRunner.gd`
- `CardfrontGateRuntimeTestRunner.gd`
- 多个 hero / entity / territory / UI runner。

P0 不应另起一套与之平行的“P0-only test universe”。

## 1.2 现有 workflow 已提供 Parse + Import 两层基础检查

`headless-tests.yml` 在 runner 前会执行：

```text
Headless Parse Check
Import Project
```

P0 最终证据必须保留这两层。

禁止只因为某个目标 runner 能独立 load，就跳过全项目 parse/import。

## 1.3 `shared-upgrade-ai-tests.yml` 已有 AI/价值策略专门证据入口

当前包含：

- `CardfrontUpgradeValuePolicyTestRunner.gd`
- `CardfrontSharedAiParityAuditTestRunner.gd`

后者可跑多 seed parity proxy audit。

P0-10 输入权限迁移后，不允许只跑新 `AIObservation` 测试而完全忽略现有 AI value/parity 回归。

## 1.4 `b1-simulation-tests.yml` 是模拟/平衡审计，不等于 P0 frozen contract

当前包括：

- route/gate/defense/unit simulation；
- model consistency；
- selectable decks and AI；
- 162-match matrix；
- opening strength；
- 5400 directional audit。

这些测试对旧玩法/旧模型可能有历史假设。

因此它们必须被分类：

```text
contract regression
observational audit
intentional semantic replacement
legacy metric
```

禁止：

- 盲目要求所有旧数值阈值一字不变；
- 也禁止因为 P0 改玩法，就把整套模拟测试直接移除。

## 1.5 当前 Performance Smoke 不是实际 FPS benchmark

`CardfrontPerformanceSmokeTestRunner.gd` 当前主要验证：

- overlay dirty redraw 不崩；
- 部分 layer 不做 per-frame processing；
- 40x40 能创建；
- 50x50 能加载。

它**没有测量**：

- 平均 frame time；
- P95/P99 frame time；
- graph recompute 次数；
- signal callback 次数；
- 支点视觉 update 次数；
- 长局内存增长。

因此：

> `CardfrontPerformanceSmokeTestRunner PASS` 只能证明结构性性能烟雾通过，不能单独证明“无性能回归”。

P0-11 需要额外 baseline diff / counters。

---

# 2. 现有测试必须先分类，禁止“旧测试全部原样绿”教条

## 2.1 为什么必须分类

当前现役测试里已经编码了旧玩法事实。

例如 `CardfrontThreeChoiceRuntimeTestRunner` 目前明确断言：

```text
Factory -> +3 shots
Energy -> +1 temporary attack level
Lab -> 4 choices
```

`CardfrontStrongholdSystemTestRunner` 也直接断言旧 tactical stronghold bonus。

但 P0-05B 的冻结目标正是退役这些 generic bonuses。

所以：

```text
“旧测试原样全绿”
```

在这里反而可能意味着：

> **旧玩法没有真正被切掉。**

反过来：

```text
“旧测试失败是 expected”
```

也不够，因为它会永久留下红 CI。

正确方法是：

> **在发生 intentional semantic cutover 的同一步，把相关旧测试迁移成新 contract。**

---

# 3. Test Classification Registry：每个受影响 runner 必须进入一类

P0-00E / P0-11A 必须维护测试分类表。

## Class A — PRESERVE / Regression Contract

语义不应因本轮重构改变。

典型内容：

- 项目可 parse/import；
- Cardfront 模式可启动；
- `Draft -> Aim -> Volley/Execution` 主循环；
- Command Point；
- BallWar / 其他模式隔离；
- Gate projectile connectivity 自身职责；
- 非目标卡牌基础 effect；
- entity registry 基础生命周期；
- 非目标 UI 基础可用性。

这类测试：

> **必须继续绿。**

若失败，不得写成“因为大重构所以正常”。

## Class B — EXTEND / Existing Authority Contract

旧语义保留，但 authority 被扩展。

典型：

- `DeploymentRulesTestRunner.gd`

旧 `OWNED_CELL / OWNED_BORDER / region controlled` 等若仍是其他卡的合法规则，就要继续通过；同时新增 frontline/core/support cases。

要求：

```text
old valid cases remain valid
+
new frozen cases added
```

禁止把旧 runner 删除后用一个更小的新 runner 替代。

## Class C — MIGRATE / Intentional Semantic Replacement

测试本身编码了 P0 明确要退役的旧行为。

典型：

- `CardfrontStrongholdSystemTestRunner.gd`
- `CardfrontThreeChoiceRuntimeTestRunner.gd` 中 stronghold -> 4-choice/+3/+1 部分；
- Region UI 中旧 Factory/Energy/Lab 文案测试。

处理方式：

1. 在对应 cutover step 明确记录旧 assertion；
2. 新增/改写 assertion，证明旧行为消失；
3. 保留与新语义无冲突的同 runner 测试；
4. 同一个 target commit 上 CI 回到 green。

禁止简单 skip/disable 整个 runner。

## Class D — SCHEMA MIGRATION

测试验证 explicit schema，而 P0 确实要扩 schema。

典型：

- `CardfrontRuntimeSnapshotTestRunner.gd`

当前它断言 snapshot key 集合精确等于旧列表。

P0 增加：

- support state；
- selected Level authority；

后该 exact-key assertion 合理地需要更新。

但必须继续保留：

- legacy field compatibility；
- partial payload defaults；
- old payload can load；
- new payload round-trip；
- derived `network_connected` 不与 graph authority 冲突。

## Class E — OBSERVATIONAL / Balance Audit

它们用于发现分布变化、异常趋势，但不一定是 frozen exact output。

例如部分：

- large-seed balance audits；
- opening-strength audit；
- route/deck candidate audit。

P0 必须：

- 跑；
- 保存 artifact；
- 和 baseline 比；
- 解释重大变化。

但如果旧阈值本身依赖已退役 Stronghold bonus，不允许为了让旧阈值继续绿而恢复旧玩法。

需要调整阈值时必须在 checkpoint 说明：

```text
old metric assumption
new frozen semantic causing change
new expected interpretation
```

## Class F — NEW FROZEN CONTRACT

P0 新增、必须能直接证明新核心不变量的测试。

包括：

- Support identity/state；
- capture influence/state machine；
- graph connectivity；
- deployment four-consumer parity；
- Legacy Stronghold retirement；
- Preview geometry state machine；
- Offer RNG cross-side independence；
- Selected Level vs Echo application count；
- AIObservation secret isolation。

---

# 4. Anti-Self-Certification Constitution

## 4.1 新代码自己写的新测试不能成为唯一证据

任何 P0 feature 至少需要两种不同性质的证据：

```text
new targeted contract
+
existing cross-system regression
```

涉及体验/UI/战略的还必须有：

```text
manual north-star check
```

例如 Support Graph：

```text
new graph unit test
+
existing map/gate/runtime smoke
+
manual main-route/branch scenario
```

## 4.2 测试必须能证明“错误实现会失败”

新增 frozen contract 不只要验证 happy path。

至少包含一个 opposite/negative case。

例如：

```text
CapturedOffline -> deploy denied
Connected Active -> deploy allowed
```

而不是只测“Active 可以部署”。

## 4.3 关键合同优先使用 metamorphic / invariance test

避免测试把内部实现写死。

例如：

### Offer

```text
swap Player/AI draw order
-> each side offer unchanged
```

### AIObservation

```text
change hidden Player Offer only
-> observation unchanged
```

### Graph

```text
change unrelated visual state
-> connectivity unchanged
```

### Preview

```text
20 toggles
-> geometry identity unchanged
```

### Deployment

```text
same query through Preview/Commit/AI/AutoSpawn
-> same legality
```

## 4.4 不允许通过削弱测试让 CI 变绿

Red flags：

- 删除 assertion；
- 把 exact invariant 改成永远 true；
- catch error 后忽略；
- 统一 `quit(0)`；
- 给失败 case 增加 `expected=true` 而没有设计依据；
- 从 workflow matrix 删除受影响 runner；
- 大量 increase tolerance 掩盖行为错误。

任何 workflow/test weakening 必须在 checkpoint 单独列：

```text
Test weakening review:
- old assertion
- why invalid under Frozen Spec
- replacement assertion
- evidence replacement is stronger/equivalent
```

## 4.5 新合同优先 test-first / red-green；不能时要说明

对于 pure model / graph / DTO：

推荐：

```text
write failing contract test
-> implement
-> green
```

对于复杂 scene integration，如果无法安全 test-first：

checkpoint 必须写：

```text
Why red-before-green was impractical:
What negative control proves the test is not vacuous:
```

---

# 5. Evidence Freshness：所有证据必须属于同一个目标 commit

## 5.1 Final Evidence Commit

P0-11 开始时冻结：

```text
P0_RC_COMMIT = <sha>
```

以下证据都必须标注该 SHA：

- CI run；
- headless logs；
- audit artifacts；
- manual test notes；
- screenshots；
- performance counters；
- final checklist。

禁止把：

```text
commit A 的 automated tests
+
commit B 的 screenshots
+
commit C 的 manual result
```

拼成一个 P0 GO。

## 5.2 P0-11 中发生修复后，旧证据自动失效

如果 P0-11 测试发现问题并产生新 commit：

```text
P0_RC_COMMIT = new sha
```

至少必须重跑：

1. 与修复直接相关的 targeted tests；
2. 受依赖关系影响的 regression cluster；
3. 最终 mandatory full suite。

人工证据若画面/行为受影响，也必须重新采集。

---

# 6. P0-11 进一步拆成 15 个 micro-step

不得一次写“跑完全量测试 -> GO”。

---

# P0-11A — Final Evidence Manifest / Test Classification Freeze

## 目的

在跑测试前，先冻结“哪些测试证明什么”。

## 输入

- P0-00E golden baseline；
- 所有 P0-01～P0-10 GO checkpoints；
- 当前 workflow；
- 当前 `scripts/tests`。

## 必须产出

`P0-11A_evidence_manifest.md`

包含：

```text
P0_RC_COMMIT
Godot version
active workflows
Class A-F test registry
new P0 runners
modified old runners
manual scenarios
performance scenarios
screenshots required
known Yellow tuning debt
```

## Exit

没有未分类的“受本轮直接影响测试”。

---

# P0-11B — Parse / Import / Boot Gate

## 必须通过

1. Godot 4.6.2-stable headless parse；
2. project import；
3. Cardfront mode boot；
4. 基础 scene instantiate；
5. 无新 parser error；
6. 无新 missing resource / preload error。

## 这是第一硬门

失败：

```text
NO-GO
```

禁止继续跑一堆 unit tests 后说“核心逻辑是对的”。

---

# P0-11C — New Frozen Contract Suite

必须覆盖 P0 新核心。

推荐 runner 按职责拆，不要求一个巨型文件：

```text
CardfrontSupportStateTestRunner.gd
CardfrontSupportCaptureTestRunner.gd
CardfrontSupportGraphTestRunner.gd
CardfrontFrontlineDeploymentTestRunner.gd
CardfrontDeploymentConsumerParityTestRunner.gd
CardfrontDraftPreviewStateTestRunner.gd
CardfrontOfferIsolationTestRunner.gd
CardfrontSelectedLevelTestRunner.gd
CardfrontAiObservationTestRunner.gd
```

实际命名可调整。

### 禁止

创建一个：

```text
P0EverythingPassTestRunner.gd
```

内部只调用几个高层 bool。

每个领域应保留独立失败定位能力。

---

# P0-11D — Existing Class A/B Regression Suite

## 目标

证明“新核心接入后，没有把旧非目标系统弄坏”。

至少覆盖：

- existing DeploymentRules old cases；
- core Cardfront mode smoke；
- Round/Draft/Aim/Volley flow；
- Command Point；
- Gate connectivity/runtime；
- entity live runtime boundary；
- target preview/validator；
- non-target UI interaction；
- other-mode isolation。

## Rule

Class A/B failure 必须修。

不能因为：

> “这次重构很大。”

而降级为 warning。

---

# P0-11E — Intentional Semantic Replacement Audit

专门检查 Class C/D。

## Stronghold retirement

必须证明正式 gameplay 不再存在：

```text
Factory -> +3 volley
Energy -> +1 temporary attack
Lab -> 4-choice
```

同时要求：

- 旧 Stronghold consumer 不再 authoritative；
- UI 不再宣传旧 bonus；
- compatibility 字段若存在，不影响 gameplay。

### 反向测试

如果旧 bonus consumer 被重新接回，测试应失败。

## Snapshot migration

必须证明：

- 新字段 round-trip；
- 老字段仍能读取；
- old save 缺新字段时行为明确；
- `network_connected` 由 graph/revision 重新推导；
- Selected Level 与 effect-history 语义不混淆。

---

# P0-11F — Full Integration Scenario Matrix

不使用完全随机长局来替代 deterministic integration。

至少固定以下场景：

## F1 — Main route normal advance

```text
Core -> rear support -> front support
```

验证：

- capture；
- connect；
- directional deploy；
-已有单位不被状态切换删除。

## F2 — CapturedOffline

```text
绕到孤立支点
-> claim 完成
-> 没有 Core path
```

要求：

- owner/claim 可变化；
- deployment = denied；
- UI 显示 Offline；
- 后续接通后自动 Online。

## F3 — Main route severed, branch survives

要求：

- branch path 仍让相应前沿在线；
- main path 不错误保持；
- projectile Gate 逻辑不被 support graph 串改。

## F4 — Both routes severed

要求：

- 前沿 supports 离线；
- 已有单位仍在；
- Core fallback 仍可部署；
- 玩家可以重建战线。

## F5 — Strong unit cannot finish war alone

使用 `SiegePlatform_Test`：

- 能快速压制/打掉支点；
- control = 0；
- 无控制单位时不能完成接管；
- 低费控制单位可完成转化。

## F6 — Draft Preview timeout path

```text
open draft
-> preview
-> timeout
-> fallback lock
-> reveal
-> volley
-> next draft
```

必须完整闭环。

## F7 — Offer independence

固定 seeds + 改 draw order/一方额外消费：

另一方 trace 不变。

## F8 — Echo vs Selected Level

Echo 可重复 effect；Selected Level 不因自动重复增加。

## F9 — AI secret isolation

hidden Player state 变化但 public state 不变：

AI Observation 不变。

## F10 — Save/restore mid-state

至少覆盖：

- Capturing；
- CapturedOffline；
- selected Levels；
- active Draft/Offer（若当前 schema 支持）；

restore 后 derived connectivity 从 authority 重建。

---

# P0-11G — Metamorphic / Invariance Suite

这是防“测试刚好覆盖实现路径”的第二层证据。

必须包含：

## G1 Draw-order invariance

Player/AI draw order 交换，各自结果保持。

## G2 Hidden-data invariance

改变 Player hidden Offer/future RNG，不改变 AI Observation。

## G3 Public-data sensitivity

改变公开 Support/单位状态，Observation 按 schema 改变。

## G4 Deployment consumer parity

同一 query：

```text
Preview
Commit
AI
Automatic/Upgrade Spawn
```

结论一致。

## G5 Visual non-authority

改变 support visual presentation 参数：

- color；
- alpha；
- animation；

不得改变：

- claim；
- connectivity；
- deploy legality。

## G6 Graph non-visual invariance

hover/resize/preview UI 操作不得触发 connectivity semantic 变化。

## G7 Preview geometry invariance

20 toggle + resize 后：

- root anchors；
- offsets；
- candidate IDs；
- signal count；

保持合同要求。

---

# P0-11H — Save / Restore Migration Gate

## H1 新 schema round-trip

新 Support / Level state 必须 round-trip。

## H2 Legacy payload acceptance

至少用一个 P0 前 payload fixture：

- 能 load；
- 缺失新字段有安全默认；
- 不 crash；
- 不把旧 stronghold bonus 恢复成 gameplay authority。

## H3 Derived-state rehydration

restore 后：

```text
claim/operational/static topology
-> graph resolver
-> connected
```

禁止优先相信旧 cache bool。

## H4 Mid-draft safety

如果当前产品正式支持 mid-draft snapshot：

- Offer identity；
- selected progress；
- phase/timer；

按旧产品合同恢复。

如果正式产品不支持，不得在 P0 为验收顺手增加这个功能；只记录 N/A + 依据。

---

# P0-11I — Performance & Recompute Evidence

## 先区分三层

### I1 Structural smoke

继续跑现有：

`CardfrontPerformanceSmokeTestRunner.gd`

证明：

- 40x40/50x50 可加载；
- 关键 dirty-redraw boundary 没被破坏。

### I2 Event-counter performance contract

必须新增/暴露 test-only counters 或可审计日志，至少记录：

```text
support_graph_recompute_count
support_presentation_update_count
deploy_evaluation_count（只在测试场景统计）
AI observation build count
```

关键断言：

- idle N frames -> graph recompute 不持续增长；
- mouse hover N cells -> graph recompute 不增长；
- resize -> 不改变 graph revision；
- claim/operational change -> 正常触发一次/有界重算；
- visual animation -> 不触发 gameplay graph recompute。

### I3 Real frame-time baseline diff

P0-00B 在同一机器/同一 grid/同一场景记录真实 baseline 后，P0-11 用同条件复测。

至少记录：

```text
scenario
build/commit
resolution
duration
average frame time or FPS
P95 frame time if tooling可得
active entity count
support count
notes
```

### 禁止

在没有 baseline 的情况下发明：

```text
必须 60 FPS
不得下降 5%
```

具体允许回归阈值属于 Engineering Spec 的 Unfrozen Constant，需要基于 P0-00B 决定。

---

# P0-11J — Log / Signal Hygiene Audit

必须比较 baseline：

- startup warnings/errors；
- repeated signals；
- repeated graph logs；
- hover log spam；
- AI every-frame score spam；
- Preview toggle duplicate callbacks。

## Hard fail

出现：

- parser error；
- runtime exception；
- repeated signal side effect；
- runaway log；
- 每帧 graph rebuild；

均不得 GO。

---

# P0-11K — Human North-Star Playtest

自动测试不能代替这一层。

## K1 测试者不得先读机制解释

至少第一轮人工试玩时，不先告诉测试者：

> “左边这个分桥是备用战线。”

结束后问：

1. 你觉得主路和分路有什么不同？
2. 为什么某个支点可以部署、另一个不能？
3. 支点被打掉以后发生了什么？
4. 被压回基地后你觉得还能做什么？
5. 哪些单位适合打赢，哪些适合把优势转成占领？

目的是验证：

> **规则是否从画面和操作自然可理解，而不是只有设计者自己知道。**

## K2 必测体验场景

- 正常推进；
- 主路失守；
- 分路维持；
- 全前线失守后 Core 反攻；
- Strong unit + cheap control unit 配合；
- Draft Preview 连续使用；
- 一局中至少观察一次 CapturedOffline。

## K3 人工 FAIL 标准

以下不能用“以后教程解释”掩盖：

- 大量出现“明明点是我的为什么不能部署”；
- 分桥仍像无意义装饰；
- 支点视觉遮挡战斗；
- Core 反攻路径实际不可玩；
- 一次夺点后自然滚成不可阻挡连锁刷兵；
- 低费控制单位在强卡存在时完全没有使用理由。

---

# P0-11L — Visual Evidence Pack

P0 最终 checkpoint 至少保存/引用以下状态截图或录屏证据：

1. 默认战斗画面：没有常驻满屏网络线；
2. Active Support；
3. Neutral/Offline Support；
4. Capturing；
5. Contested；
6. CapturedOffline；
7. 合法部署 targeting：只在此时显示 zone；
8. Core fallback deployment；
9. Main route severed / Branch survives；
10. Draft normal 3-choice；
11. Battlefield Preview；
12. Preview return 后 geometry；
13. 一个窄屏状态。

## Screenshot rule

截图必须标注：

```text
commit SHA
viewport/resolution
scenario/state
```

禁止用旧 commit 的漂亮截图替代当前验收。

---

# P0-11M — Full CI / Workflow Gate

## M1 当前 active workflows 必须审计

至少：

- `headless-tests.yml`
- `shared-upgrade-ai-tests.yml`
- `b1-simulation-tests.yml`
- `battlefield-entity-foundation-tests.yml`（若本轮改动影响其领域）

## M2 不允许“目标测试绿但 workflow 红”直接 GO

如果红是 Intentional Semantic Replacement：

必须在同一 P0 分支/commit 中迁移对应 test contract，使 active CI 恢复有意义的绿。

## M3 workflow diff 必须特别审查

P0 原则上只允许：

- 把新 P0 runner 加进 matrix；
- 必要的 artifact 输出。

禁止：

- 删除失败 batch；
- `continue-on-error: true` 掩盖失败；
- 取消 parse/import；
- 大范围减少 audit seeds 只为变快；
- 把测试 workflow 改成只在手动触发时跑。

---

# P0-11N — Drift Re-Audit Against Frozen Spec

最后重新逐条执行 North-Star Drift Check，但这次必须附证据引用。

不能只写：

```text
1. Yes
2. Yes
...
```

必须写：

```text
Invariant 1:
Status: PASS
Evidence:
- test runner
- scenario
- screenshot/log
```

重点复核：

1. 据点是否真的从 bonus node 迁成 deployment support；
2. SupportGraph 是否与 GateConnectivity 分权；
3. Capture 是否与 projectile territory capture 分权；
4. deployment 是否只有一个 authority；
5. auto/upgrade spawn 是否没有旧 route-slot 绕路；
6. Player/AI Offer 是否只隔离、不偷跑 P1；
7. Selected Level 是否没有被 Echo 污染；
8. AI 是否没有 Object escape hatch；
9. UI 是否仍只是 projection；
10. Draft/Aim/Volley/Command Point 是否保留。

---

# P0-11O — GO / NO-GO Decision & P0 Seal

这是唯一允许声明：

```text
P0 COMPLETE
```

的步骤。

必须创建：

```text
docs/cardfront_refactor_checkpoints/P0-11O_P0_FINAL_GO_NO_GO.md
```

并包含：

```text
P0_RC_COMMIT:
Final decision: GO / NO-GO
All prior checkpoint SHAs:
CI run refs:
Automated contract summary:
Regression summary:
Intentional semantic migration summary:
Performance/log summary:
Manual playtest summary:
Visual evidence refs:
Yellow tuning debts:
Red blockers:
Frozen invariant evidence matrix:
P1 allowed start commit:
```

---

# 7. GO / NO-GO Severity Model

不要所有问题都叫“known issue”。

## RED — P0 Blocker

任一 RED：**NO-GO**。

包括：

- parser/runtime crash；
- Core fallback 失效；
- CapturedOffline 可部署；
- 普通 support 360°越线部署；
- 两套 deployment authority 并存；
- Player/AI RNG 串流；
- old Factory/Energy/Lab bonus 仍影响正式 gameplay；
- Echo 污染 Selected Level；
- AIObservation 泄露 opponent Offer/future RNG/hidden route exact；
- AI 仍能拿完整 GameState/RunState escape；
- Preview 重生成 Offer/移动容器/恢复战斗；
- Draft/Aim/Volley/Command Point 核心回归；
- save/load 导致状态损坏；
- active CI 因未迁移 contract 长期红；
- graph 每帧重算；
- 明显不可阻挡支点雪球。

## YELLOW — 只允许 Intentionally Unfrozen / 非结构调优

可以带入 P1，但必须记录 owner / metric / follow-up。

例如：

- capture 秒数需要微调；
- zone 尺寸需要微调；
- flag/glow 对比度小修；
- AI decision window 数值；
- bounded resample 次数（尚未进入 P1 实现）；
- performance threshold 尚待 baseline 定量。

### YELLOW 不得包括

- “偶尔不能部署但原因不明”；
- “分桥仍没人用”；
- “AI 偶尔偷看”；
- “旧 bonus 先留着”；
- “测试先 skip”；
- “save 以后再修”。

这些都是 RED。

## GREEN

冻结语义、回归、体验证据完整。

---

# 8. Final P0 Evidence Matrix

P0-11O 必须逐条填。

| Frozen Goal | Automated | Integration | Manual/Visual | Result |
|---|---|---|---|---|
| Support state dimensions separated | unit | F1/F2 | state screenshots | |
| CapturedOffline cannot deploy | unit/parity | F2 | screenshot | |
| Core fallback always available | deployment test | F4 | manual | |
| Branch is alternate path | graph test | F3 | player explanation | |
| Existing units survive support loss | integration | F1/F4 | manual | |
| Strong card cannot complete war alone | fixture | F5 | manual | |
| Old stronghold bonus retired | replacement test | F5/normal draft | UI evidence | |
| Preview visibility-only | geometry/metamorphic | F6 | screenshot | |
| Offers cross-side independent | RNG metamorphic | F7 | N/A | |
| Duplicate -> Selected Level | unit | F8 | UI | |
| Echo != Selected Level | unit | F8 | optional | |
| AI information fair | schema/metamorphic | F9 | debug snapshot | |
| One deploy authority / 4 consumers | parity | F1/F4 | targeting | |
| Save/restore coherent | snapshot test | F10 | N/A | |
| No per-frame graph recompute | counter | perf scenario | profiler/log | |
| Draft/Aim/Volley preserved | existing regression | normal match | manual | |
| Command Point preserved | existing regression | normal match | manual | |

没有某一列适用时写 `N/A + 理由`，不得留空。

---

# 9. Test Runner Migration Guidance：对现有关键测试的具体处理

## 9.1 `DeploymentRulesTestRunner.gd`

分类：**Class B / EXTEND**

保留现有：

- owned cell；
- owned border；
- region threshold（只要仍有旧卡使用）；
- invalid inputs；
- evaluate read-only。

新增：

- Core fallback；
- Online Support directional zone；
- Offline denied；
- front-of-line denied；
- reason codes；
- graph/context read-only。

禁止删掉旧 cases 来缩短 runner。

## 9.2 `CardfrontThreeChoiceRuntimeTestRunner.gd`

分类：**A + C 混合 runner**

保留：

- Draft pause；
- exactly 3 default choices；
- AI locks own choice；
- player choice -> reveal -> volley；
- timeout fallback；
- BallWar isolation。

迁移/删除旧 assertion：

- Factory +3；
- Energy +1；
- Lab four-choice；
- “实验室加成：四选一”文案。

替换为：

- formal Draft 默认保持 3-choice；
- Support 状态不额外增加 Draft 次数/choice count；
- Preview state machine regression。

## 9.3 `CardfrontStrongholdSystemTestRunner.gd`

分类：**Class C / MIGRATE or retire old gameplay assertions**

不能继续作为“正式 tactical bonus 正确性”测试。

可选择：

A. 将其迁移成 compatibility shell/no-authority test；或
B. 保留 legacy unit helper test，但从 active gameplay batch 移出，同时新增明确 `LegacyStrongholdRetirement` runner。

无论选 A/B，都必须证明：

> production RoundDirector 不再消费旧 generic bonus。

不能只是让旧 system class 还能算出 +3，然后说“反正没人用”。必须有 consumer-retirement test。

## 9.4 `CardfrontRuntimeSnapshotTestRunner.gd`

分类：**Class D / SCHEMA MIGRATION**

当前 exact key list 会因新字段合理变化。

迁移要求：

- 新 schema keys 明确；
- legacy keys 兼容；
- new Support/Level roundtrip；
- old payload defaults；
- derived connectivity 不持久化为第二 authority。

## 9.5 `CardfrontPerformanceSmokeTestRunner.gd`

分类：**Class A structural smoke + I2/I3 supplemental**

保留现有 40x40/50x50 load。

新增/另建：

- graph recompute counter tests；
- presentation dirty update counter；
- actual baseline report。

不要把 smoke runner 的名字当成真正 benchmark。

## 9.6 AI tests

现有：

- ValuePolicy；
- Shared AI parity audit。

P0-10 后：

- 保留其合法输入下的策略回归；
- 新增 Observation allowlist/leak test；
- 如果旧 parity 因删除非法信息变化，必须说明具体字段；
- 不通过调权重偷偷恢复旧结果。

---

# 10. Failure Recovery / Rollback Contract

## 10.1 每个 GO checkpoint 都是恢复点

记录：

```text
LAST_GO_COMMIT
CURRENT_STEP_SOURCE_COMMIT
CURRENT_STEP_TARGET_COMMIT
```

## 10.2 当前 step NO-GO 时只有三种合法动作

### Fix-in-step

问题确实属于当前 semantic cluster：

修复 -> rerun -> checkpoint。

### Revert-to-LAST_GO

实现方向错误/污染面过大：

回退当前 step，再重新实现。

### Amendment Required

冻结 Spec 与真实代码事实冲突：

停止实现，提交：

```text
BLOCKED / AMENDMENT REQUIRED
```

禁止第四种：

> “先带着 known broken invariant 继续下一步，最后一起修。”

## 10.3 P0-11 发现早期步骤错误时

例如最终人工测试发现 branch topology 本身不成立。

不得在 P0-11 临时打 UI/balance patch。

必须回到 ownership 所属步骤：

```text
P0-03/P0-05
```

修复对应 authority，再重新走受影响 checkpoint 链。

---

# 11. Evidence Invalidation Matrix

P0-11 中任何修复后，用这个表决定重跑范围。

| Changed area | Minimum evidence invalidated |
|---|---|
| Support state/capture | Support unit + graph + deployment + integration + manual support |
| Graph/topology | Graph + deployment + branch scenarios + performance recompute + manual map |
| DeploymentRules | unit + all 4 consumers + card target regression + manual deployment |
| Stronghold cutover | ThreeChoice + RoundCombat + Stronghold retirement + UI text + save |
| Support visual | visual pack + UI/performance dirty update; gameplay tests still sampled |
| Preview UI | ThreeChoice/preview + timeout + geometry + narrow screen |
| Draft RNG | Offer isolation + timeout fallback + ThreeChoice + AI draft |
| Level state/resolver | UpgradeResolver + save + Echo + UI |
| AIObservation | AI leak + existing value/parity + public sensitivity |
| save schema | snapshot + restore integration + affected runtime |

这比“修一行只重跑一个 test”更安全。

---

# 12. P0 -> P1 Handoff Seal

P1 不能因为“P0 基本差不多”提前启动。

## 12.1 唯一合法 P1 起点

必须存在：

```text
P0-11O_P0_FINAL_GO_NO_GO.md
Final decision: GO
P1 allowed start commit: <sha>
```

P1 Agent 必须以该 SHA/其直接后继为基线。

## 12.2 P1 开工前不得重新解释 P0 core

P1 可以实现：

- route unlock；
- reroll；
- per-card tracks；
- Combat/Mobility/Control UI；
- stronger card content；
- Easy/Normal AI strength。

P1 不得重新打开：

- Support 是否是 deployment support；
- CapturedOffline 是否能部署；
- Core fallback；
- one deployment authority；
- Information Fairness；
- Preview visibility-only；
- Selected Level 语义；
- old generic stronghold bonus。

如果 P1 发现必须改这些：

> **Engineering Spec Amendment，不是“顺手调整”。**

---

# 13. Final Acceptance 文件结构建议

最终目录：

```text
docs/cardfront_refactor_checkpoints/
  README.md
  P0-00A_...
  ...
  P0-10E_...
  P0-11A_evidence_manifest.md
  P0-11B_parse_import_boot.md
  P0-11C_new_contract_suite.md
  P0-11D_existing_regression.md
  P0-11E_semantic_replacement.md
  P0-11F_integration_matrix.md
  P0-11G_metamorphic_suite.md
  P0-11H_save_restore.md
  P0-11I_performance.md
  P0-11J_log_signal.md
  P0-11K_manual_playtest.md
  P0-11L_visual_evidence.md
  P0-11M_ci_gate.md
  P0-11N_drift_reaudit.md
  P0-11O_P0_FINAL_GO_NO_GO.md
```

不强制每份都很长，但每份必须有明确 evidence。

---

# 14. P0-11 Final Stop Rules

出现以下情况，验收 Agent 必须停，不得宣布 GO：

1. 有受影响 active test 尚未分类；
2. 新行为只由同一模块自己的 unit test 证明；
3. old Stronghold assertions 被直接删除但没有 replacement；
4. active workflow 被弱化；
5. CI 证据来自不同 commit；
6. manual screenshot 来自旧 commit；
7. performance 只用“50x50 能打开”冒充无回归；
8. branch usefulness 只由设计者解释，没有实际试玩理解证据；
9. AI leak 只检查 key 名，没有 hidden-data invariance test；
10. deployment parity 漏掉 auto/upgrade spawn；
11. save test 没覆盖 new state；
12. Yellow 列表里混入 structural bug；
13. 存在 RED 仍写“conditional GO”；
14. P0-11 直接补新玩法来修体验问题；
15. 任何 Frozen Invariant 证据无法指向具体 test/scenario/log。

正确结论只能是：

```text
GO
```

或：

```text
NO-GO
Return to owner step: P0-XX
```

---

# 15. Batch C 结论

P0 最终验收不再是：

```text
功能看起来都能跑
+ tests green
= P0 complete
```

而是：

```text
同一 commit
  -> parse/import
  -> 新 Frozen Contracts
  -> 旧非目标回归
  -> intentional semantic replacement
  -> deterministic integration
  -> metamorphic/invariance
  -> save/restore
  -> performance/log
  -> human north-star
  -> visual evidence
  -> active CI
  -> drift re-audit
  -> GO/NO-GO seal
```

只有最后 seal 为 GO，才允许进入 P1。

> **最终目标不是让测试数量变多，而是让任何未来 Agent 都很难通过“自创规则 + 自己写测试 + 自己宣布通过”把 Cardfront 再次逐步带离冻结设计。**
