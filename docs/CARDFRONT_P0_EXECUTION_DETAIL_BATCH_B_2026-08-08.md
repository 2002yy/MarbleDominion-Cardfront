# Cardfront P0 Execution Detail — Batch B — 2026-08-08

状态：**MANDATORY ADDENDUM / ANTI-DRIFT BATCH B**  
适用：P0-06 ～ P0-10  
上位文档：

1. `CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`
2. `CARDFRONT_P0_EXECUTION_GUARDRAILS_2026-08-07.md`
3. `CARDFRONT_P0_EXECUTION_DETAIL_BATCH_A_2026-08-08.md`
4. 本文
5. `CARDFRONT_REFACTOR_PLAN_2026-08-07.md`

> 本文不增加玩法。它只继续压缩 P0 后半段的自由解释空间，防止视觉、Draft、Level、AI 在局部重构中各自长出第二套规则。
>
> **Batch A 解决“战线怎么从旧地图/部署系统迁移”；Batch B 解决“新核心接入 UI/构筑/AI 后，怎样不再次被旧便利接口带偏”。**

---

# 1. 本批新增确认的旧实现事实

这些事实必须在相应 checkpoint 中引用，不能只把本文当背景资料。

## 1.1 `CardfrontThreeChoicePanel` 当前 Peek 不是“隐藏 Draft”，而是“移动 Draft”

当前真实 owner：

- `scripts/cardfront/ui/CardfrontThreeChoicePanel.gd`
- `scenes/ui/cardfront/CardfrontThreeChoicePanel.tscn`

当前逻辑：

```text
PeekButton 是 ChoiceShell child
_toggle_peek()
 -> 保存 ChoiceShell.position
 -> 降低 dimmer alpha
 -> 把 ChoiceShell 移到右下
 -> 返回时恢复 position
```

这与冻结目标不同。

冻结目标是：

```text
DRAFT_VISIBLE
<->
BATTLEFIELD_PREVIEW
```

其中 Draft 内容真正隐藏，按钮保持固定，Draft 仍暂停。

因此 P0-07 不允许继续保留 `_saved_shell_position` / 运行时移动容器这一语义。

---

## 1.2 `DraftRoot`、`ChoiceShell`、`Dimmer` 必须被拆成“生命周期”和“内容可见性”两个概念

当前 `draft_root.visible` 同时承担：

- Draft 生命周期是否存在；
- 遮罩是否存在；
- 卡牌是否可见。

但 Preview 要求：

- Draft 生命周期仍然 active；
- timer 继续；
- battle simulation 仍 paused；
- PeekButton 仍可点击；
- 只有遮罩和选择内容隐藏。

所以冻结：

```text
Draft lifecycle != Choice content visibility
```

P0-07 推荐状态投影：

```text
DRAFT_VISIBLE:
  draft_root.visible = true
  dimmer.visible = true
  choice_shell.visible = true
  peek_chrome.visible = true

BATTLEFIELD_PREVIEW:
  draft_root.visible = true
  dimmer.visible = false
  choice_shell.visible = false
  peek_chrome.visible = true
```

`peek_chrome` 名称可按实现调整，但必须是不会随 `choice_shell` 隐藏/移动的稳定层。

---

## 1.3 Draft 在暂停期间仍会计时，Preview 不能改变 phase/timer owner

`CardfrontRoundDirector` 在 `DRAFT_PAUSED` 时仍调用：

```text
phase_controller.tick(delta)
draft_time_updated.emit(...)
```

`CardfrontThreeChoicePanel` 又设置 `PROCESS_MODE_ALWAYS`。

因此 Preview 只允许改变视图状态。

禁止：

- Preview 自己暂停/恢复 SceneTree；
- Preview 冻结 Draft timer；
- Preview 切换 phase；
- Preview 恢复 battle simulation。

如果玩家在 Preview 中超时，既有 timeout 流程必须正常完成。

---

## 1.4 当前 `CardfrontUpgradeDraftSystem` 的耦合点不仅是 Player/AI，共享 `_rng` 还服务 timeout fallback

当前一个 `_rng` 被用于：

- weighted Offer draw；
- `choose_timeout_fallback()`。

P0-08 冻结目标只解决：

> **Player 的随机消费不能改变 AI 的随机序列，反之亦然。**

本步骤**不擅自解决**同一阵营内部的“Offer RNG 与 timeout RNG 是否还要再分流”。

默认最小迁移：

```text
player_rng = player 的旧随机语义
ai_rng = AI 的旧随机语义
```

同一 side 内 Offer/fallback 可以继续消费同一 side stream，以避免 P0 顺手改变“超时是否影响自己未来随机序列”这一未冻结玩法细节。

若未来要拆 purpose-specific RNG，单独 Amendment / P1 decision。

---

## 1.5 当前 Player/AI Offer 虽分别调用 `draw_offer()`，但 draw order 仍能影响结果

`RoundDirector._open_draft()` 当前顺序是：

```text
player draw
then AI draw
```

因为共享 RNG，交换顺序会改变双方结果。

P0-08A 的真正验收不是“代码里有两个 RNG 字段”，而是：

> **在固定初始 side seeds 下，Player/AI draw 调用顺序交换，不改变各自结果。**

这是 metamorphic test，必须存在。

---

## 1.6 Manifest definition 已经 deep-copy，P0 不需要另造“共享 mutable card definition”框架

`CardfrontUpgradeManifest.get_definition()` 当前返回 `duplicate(true)`。

所以 P0-08 不需要为了“双方 Offer 独立”重构整个 Manifest。

允许：

- immutable/static manifest 作为定义 authority；
- 每次 Offer 获得自己的 definition copy/container。

禁止：

- 创建 PlayerManifest / AiManifest 两套定义；
- 为 Offer independence 复制整份卡牌目录。

---

## 1.7 `applied_upgrade_counts` 是“效果应用历史”，不是严格的“玩家选卡 Level”

当前 `CardfrontUpgradeResolver.resolve()`：

1. 如果有 queued echo，先 `_apply_once(echoed_definition)`；
2. 对 echoed upgrade 调用 `record_upgrade(echoed_upgrade_id)`；
3. 再应用本轮玩家真正选择的 definition；
4. 再 `record_upgrade(upgrade_id)`。

因此：

```text
applied_upgrade_counts
= selected applications + echo applications
```

而冻结设计是：

> **选到已有卡 -> 该卡 Level +1。**

所以不能简单：

```text
get_upgrade_level(id) = applied_upgrade_counts[id]
```

否则 Echo 会让玩家没有选中的卡偷偷升级。

这是对上一批“优先复用 applied_upgrade_counts”的进一步修正。

---

## 1.8 AI 当前拿到的是 `run_state object + free-form context Dictionary`

当前：

```text
RoundDirector
 -> CardfrontAiCommander.choose(
      ai_offer,
      AI run_state object,
      get_upgrade_value_context(AI)
    )
```

`CardfrontTacticalUpgradeValuePolicy` 已能通过 `_read()` 同时读取 Object 或 Dictionary。

这给 P0-10 一个很好的最小迁移路径：

> **把 AI 的 own state 从完整 RunState Object 投影成 whitelist Dictionary，而不是重写所有 ValuePolicy。**

同时，`get_upgrade_value_context()` 当前由 RoundDirector 自由拼 Dictionary，未来不能继续成为“想到什么就塞什么”的逃生口。

---

# 2. Batch B 总体硬锁

## 2.1 UI 只能投影，不得成为规则 authority

从 P0-06 起，所有 UI/visual 代码只能消费：

```text
runtime/public state
 -> presentation snapshot
 -> visual
```

禁止：

```text
visual percent/color/position
 -> 反推 owner / capture / connectivity / deployment legality
```

## 2.2 P0-08 只做 Isolation，不做 Offer Design

P0-08 不得顺手实现：

- route unlock；
- hero profession pool 重构；
- reroll；
- Diversity Guard；
- Dominance Guard；
- 新 rarity 曲线；
- “系统按战况给反制牌”；
- 改 Draft cadence。

这些属于 P1 或后续平衡。

## 2.3 P0-09 只冻结 Level Authority，不完成全部 per-card upgrade track

P0 要完成：

- “选择次数”和“效果应用次数”分离；
- Level authority 明确；
- Duplicate 不形成同 ID 多副本；
- save/restore 语义明确；
- 最小 UI 能表达已有卡再次选择会升级。

P0 不完成：

- 每张卡 Lv1～Lv5 全部正式数值轨；
- 全卡平衡；
- 数量成长内容铺满；
- 路线高阶卡升级树。

## 2.4 P0-10 是“权限收窄”，不是 AI 升级

P0-10 后 AI 应尽量保持当前决策能力。

允许变化：

- 输入来源更严格；
- context field 更明确；
- secret leak 被删除。

禁止变化：

- 增加搜索深度；
- 新 tactical planner；
- Hard AI；
- 机器级反应；
- stat/resource cheat；
- 跨局玩家画像。

---

# 3. P0-06 详细施工卡：Support Presentation

## P0-06A1 — Visual Ownership Snapshot

### 目的

先确认“谁画 battlefield region/entity/status”，再新增 Support visual。

### 必须记录

- battlefield 主视觉 node/class；
- region hover/info owner；
- entity presentation owner；
- gate visual owner；
- 可复用的 cell -> world 坐标 API；
- 当前 CanvasLayer / z-index 分层。

### Allowed diff

- docs；
- read-only debug helper。

### Forbidden

- 新 Support visual node；
- 调 UI 样式；
- 删除旧 RegionInfoPanel。

### Exit

`P0-06A1_visual_ownership.md`

---

## P0-06A2 — SupportPresentationSnapshot DTO

### 目的

建立“视觉能看到什么”，但视觉不能拿完整 Support runtime。

建议字段：

```text
support_id
anchor_cell
claim_owner
operational
network_connected
capture_side
capture_progress_normalized
contested
derived_view_state
```

### 禁止字段

- mutable runtime reference；
- graph object；
- capture controller object；
- `set_owner()` / `set_connected()` callback；
- deployment rule callback。

### Invariant

Presenter 拿到 DTO 后，即使恶意改 DTO，也不能改变 gameplay truth。

---

## P0-06A3 — View-State Derivation Contract

唯一派生规则必须放在 presenter/view-model 层一个函数中。

示意：

```text
if contested:
  CONTESTED
elif capture_side != NEUTRAL and capture_progress > 0:
  CAPTURING
elif claim_owner != NEUTRAL and operational and network_connected:
  ACTIVE
elif claim_owner != NEUTRAL and not network_connected:
  CAPTURED_OFFLINE
else:
  OFFLINE/NEUTRAL
```

具体优先级以 Engineering Spec invariant 为准。

禁止每个 visual node 自己判断一遍。

---

## P0-06B1 — One Visual Instance Per `support_id`

### 目的

避免 `_process()` 每帧删除/重建 Support visual。

### 生命周期

```text
map/setup
 -> create/bind visual per support_id
state revision
 -> update presentation
map teardown
 -> dispose
```

### Forbidden

- 每帧 instantiate/free；
- 用 runtime `region_id` 做 visual identity；
- 用 scene child index 做 identity。

---

## P0-06B2 — Coordinate Contract

Support visual 位置必须来自：

```text
authored support anchor_cell
 -> battlefield cell/world conversion
 -> visual position
```

禁止：

- 为每个分辨率写硬编码像素坐标；
- 根据旧 RegionInfoPanel 位置猜 battlefield support 位置；
- 根据当前 ownership centroid 漂移支点。

---

## P0-06B3 — Low-Occlusion Visual Only

P0 只允许：

- ground ring；
- small flag；
- low beacon；
- glow base；
- ground marking；
- 简洁 capture progress。

禁止：

- 大型建筑替代支点；
- 永久名称牌遮挡单位；
- 常驻网络线；
- 把 Support 变成可阻挡单位/炮弹的实体，除非 Engineering Spec 另有明确碰撞语义。

### 重要

**视觉实体 ≠ gameplay collision entity。**

地面环/旗帜默认不加入 projectile/entity collision authority。

---

## P0-06B4 — Deployment-Zone Visualization Gate

合法部署区只在“玩家当前正在部署需要 frontline legality 的卡/单位”时显示。

默认战斗状态：

```text
zone visual = hidden
```

进入合法部署 targeting：

```text
DeploymentRules result
 -> visualizer
```

退出 targeting / card cancel / Draft：

```text
zone visual = hidden
```

禁止 Support Presenter 自己重新计算合法部署格。

---

## P0-06C — Legacy Region UI Separation

P0-05B 已退役旧 Stronghold bonus 后：

- `CardfrontRegionInfoPanel` 不得继续展示“80% 激活 -> Factory/Energy/Lab bonus”；
- 若继续显示区域信息，只能描述仍然真实存在的 territory/defense 信息；
- Support 状态由 Support presenter/专用简洁提示读取，不允许 RegionInfoPanel 根据 territory 百分比自己推断 Support owner。

**旧 territory region 与新 Support 是相关空间对象，但不是同一 authority。**

---

# 4. P0-07 详细施工卡：Draft Preview Bug

## P0-07A1 — Geometry Golden Snapshot

在任何修复前记录：

```text
viewport size
draft_root rect/anchors/offsets
choice_shell rect/position
card_box rect
3 张 card IDs + rect
peek button rect/parent path
dimmer rect
signal connections per director signal
```

至少记录：

- 默认桌面尺寸；
- 一个窄尺寸。

P0 不要求在这里完成整个移动端 redesign，只要求修复前后无新增漂移。

---

## P0-07A2 — Lifecycle Event Matrix

修复前先列出：

| Event | Expected UI state |
|---|---|
| `draft_opened` | DRAFT_VISIBLE |
| Peek click / Space | toggle preview |
| timer update | 保持当前 display mode |
| player choice locked | 正常进入 resolution flow |
| timeout while preview | 不得卡死；自动选择仍生效 |
| `choices_revealed` | 强制回到 DRAFT_VISIBLE，显示双方结果 |
| `volley_launched` | Draft hidden / preview reset |
| `director_stopped` | Draft hidden / preview reset |
| next `draft_opened` | 一定从 DRAFT_VISIBLE 开始 |

如果当前产品预期与此矩阵冲突，必须在 P0-07A checkpoint 报告，不得代码里随机决定。

---

## P0-07B1 — Stable Peek Chrome

因为当前 `PeekButton` 是 `ChoiceShell` child，而 Preview 要隐藏 `ChoiceShell`，所以按钮必须迁移到稳定可见父层。

允许的最小结构：

```text
DraftRoot
  Dimmer
  ChoiceShell
  PeekChrome
    PeekButton
```

或者等价 sibling 结构。

这是**一次性 scene hierarchy 修正**，不是 runtime reparent。

### Forbidden

- 每次点击时 `reparent()`；
- 每次点击时改变 root anchors/offsets；
- 把 PeekButton 放到 battle HUD 另一个无关 controller。

---

## P0-07B2 — Single Display-State Authority

删除/退役：

```text
_saved_shell_position
peek 时修改 choice_shell.position
```

只保留一个 display mode：

```text
DRAFT_VISIBLE
BATTLEFIELD_PREVIEW
```

所有显示切换必须经过一个函数，例如：

```text
_set_draft_display_mode(mode)
```

禁止点击、Space、timeout、next draft 各自散落一套 `visible` 写法。

---

## P0-07B3 — Preview Input Contract

`BATTLEFIELD_PREVIEW` 时：

- cards 不可见且不可点击；
- PeekButton / Space 可以返回；
- 不恢复 Aim input；
- 不恢复 CardSelection input；
- 不恢复 battle simulation；
- 不创建新的 battlefield interaction mode。

这里的“回看”是**只看**，不是“趁 Draft 暂停重新操作战场”。

---

## P0-07B4 — Timeout-in-Preview Regression

必须测试：

```text
open draft
 -> enter preview
 -> let timer expire
 -> player fallback locks
 -> resolution reveals
 -> panel returns to visible resolution state
 -> volley launches
 -> next draft opens normally
```

不得出现：

- 永久隐藏 Draft；
- `_peeking=true` 泄漏到下一轮；
- choice shell 下一轮仍 hidden；
- timer 卡住；
- duplicated choice signal。

---

## P0-07B5 — Setup/Signal Lifecycle

当前 `_connect_director()` 对“同一个 director 重复 setup”有 `is_connected()` 防重，但如果 panel 生命周期允许换 director，需要确认旧 director 是否还连着。

P0-07A 必须先记录真实 lifecycle。

- 如果生产路径 panel 只 setup 一次：保持简单，不为了理论情况重写 signal manager。
- 如果真实路径会换 director：最小增加 disconnect-old / connect-new。

禁止无证据地做全 UI signal architecture 重构。

---

# 5. P0-08 详细施工卡：Offer Independence

## P0-08A1 — Freeze Current Draw Semantics

隔离 RNG 前记录：

- 当前 deck IDs；
- eligibility；
- rarity weights；
- offer size；
- timeout fallback；
- fixed master seed 下连续 N 轮 draw trace。

目的不是要求新实现复现**同一张具体牌序列**，而是确认 P0 没有同时改 eligibility/rarity/cadence。

---

## P0-08A2 — Side RNG State Object

目标语义：

```text
DraftSystem
  player_rng
  ai_rng
```

实际容器名可调整。

### Master seed compatibility

现有 `RoundDirector.set_seed_for_tests(seed)` 应继续可用。

建议：

```text
master seed
 -> deterministic PLAYER seed
 -> deterministic AI seed
```

必须使用固定、可复现的 derivation；禁止依赖 Dictionary iteration order、系统时间或不稳定 object identity。

也允许增加显式 test-only：

```text
set_side_seed_for_tests(owner_id, seed)
```

但不能删除现有 master-seed seam 而不迁移测试。

---

## P0-08A3 — Side-Aware RNG Consumer

以下 API 必须知道自己消费哪一方 stream：

- `draw_offer_ids()`；
- weighted selection；
- `choose_timeout_fallback()`。

禁止内部再默认访问一个全局 `_rng`。

### 重要：不拆 purpose stream

P0 默认同一 side 的 draw + fallback 仍消费同一 side RNG。

这是为了最小改变旧语义。

---

## P0-08A4 — Draw-Order Invariance Test

固定 Player seed / AI seed：

Case A：

```text
player draw -> AI draw
```

Case B：

```text
AI draw -> player draw
```

要求：

```text
Player offer A == Player offer B
AI offer A == AI offer B
```

---

## P0-08A5 — Cross-Side Consumption Isolation

固定 seeds 后：

- Player 多 draw 一次，不改变 AI 后续 trace；
- Player timeout fallback 消费一次，不改变 AI 后续 trace；
- AI 多消费随机，不改变 Player 后续 trace。

---

## P0-08B1 — Side Context Envelope

P0 只建立 container seam，例如：

```text
DraftOfferContext
  owner_id
  run_state/read-model
  deck_id
```

P0 不填 route/profession/behavior fields，最多保留未来扩展字段/DTO seam。

禁止为了“以后路线要用”提前实现 P1 route unlock。

---

## P0-08B2 — Offer Container Independence

要求：

- Player Offer Array 与 AI Offer Array 是不同对象；
- definition Dictionary 是自己的 deep copy；
- 修改 Player offer view-data 不影响 AI；
- getters 继续返回 copy，不暴露 authoritative mutable array。

Manifest 继续是一份定义 authority。

---

## P0-08B3 — Preserve Coincidental Overlap

Offer independence **不等于 card exclusivity**。

允许：

```text
Player 本轮抽到普通步兵
AI 本轮也抽到普通步兵
```

禁止为了“双方看起来不同”添加：

- 跨阵营互斥抽牌；
- Player 抽到后从 AI pool 删除；
- 强制不同 rarity/category。

双方差异来自独立过程，而不是硬编码“不许撞牌”。

---

## P0-08C — Stronghold Cutover Interaction

P0-05B 后正式 Draft 应回到固定基础 Offer size 语义。

旧：

```text
Lab -> 4-choice
```

已经退役。

但 `MAX_OFFER_SIZE = 4` 可暂时作为 compatibility/test 常量存在；不能因为常量还在就把 4-choice 当成正式玩法恢复。

---

# 6. P0-09 详细施工卡：Duplicate -> Level Authority

## P0-09A0 — Correct the Old Assumption

上一版曾建议直接把 `applied_upgrade_counts` 包成 Level API。

根据当前 Resolver 证据，这不够准确。

冻结修正：

> **`applied_upgrade_counts` 可以继续作为 effect application/history compatibility 数据，但不能直接成为 user-facing Level authority。**

因为 Echo 会增加它。

---

## P0-09A1 — Define Two Semantics Explicitly

必须区分：

### Selected Level

```text
这张卡被该阵营在 Draft 中真正选择并成功结算的次数
```

这是玩家看到的 `Level`。

### Effect Application Count

```text
该 effect/upgrade 实际执行次数，包括 echo/repeat 等自动重复
```

这是内部历史/兼容数据，不等于 Level。

---

## P0-09A2 — Level Storage Authority Migration

因为旧字段语义不纯，允许新增一个**明确的新 authoritative store**，例如：

```text
selected_upgrade_levels
```

命名可调整。

迁移规则：

- 新 store 是 Level authority；
- `applied_upgrade_counts` 继续作为旧 application/history compatibility，直到所有 consumer 分类完成；
- 禁止两个字段都被不同模块解释为“Level”。

这属于有证据的 authority transfer，不违反“禁止无理由平行 progression store”。

---

## P0-09A3 — Increment Point Must Be Singular

Level 只能在：

```text
本轮某 side 真实选择的 upgrade
且 resolve 成功
```

之后增加一次。

禁止在以下位置额外增加：

- `draw_offer()`；
- card click 但 resolve 失败；
- Echo replay；
- visual setup；
- save restore；
- AI score evaluation。

---

## P0-09A4 — Echo Contract

例如：

```text
Round N: 选择 延迟回响
Round N+1: 选择 攻击训练
Round N+2: Echo 自动重复 攻击训练 + 玩家选择别的卡
```

要求：

- 攻击训练的实际 effect 可执行两次（按旧 Echo 语义）；
- 攻击训练 Selected Level 只因 Round N+1 的真实选择 +1；
- Round N+2 的 Echo 不再偷偷 +1 Level。

如果以后设计希望 Echo 也提升 Level，必须另开设计决策，P0 不允许自行改变。

---

## P0-09A5 — Eligibility Is Not Level Cap

当前一些旧升级有 state cap，例如：

- attack level max；
- rarity max；
- tower level max。

P0 不得把这些旧 effect cap 自动等同为：

```text
card max level
```

这是两个概念。

P0 只保留现有 eligibility 行为；正式每卡 Lv track 上限属于 P1。

---

## P0-09A6 — Rarity Is Not Card Level

当前存在：

```text
run_state.rarity_level
card definition.rarity
```

它们都不是 `Selected Level`。

禁止：

- 把 rarity 改名 Level；
- Level up 自动提升 rarity；
- 用 run `rarity_level` 代替 per-card Level。

---

## P0-09B1 — Resolver Cutover

`CardfrontUpgradeResolver` 必须明确：

```text
apply echo effect
 -> application history only

apply selected effect
 -> if success: application history + selected Level +1
```

具体记录顺序必须保证 resolve 失败不会 Level up。

---

## P0-09B2 — Save / Restore Contract

新 Level authority 必须进入 `CardfrontFactionRunState.snapshot()/restore()`。

兼容原则：

- 新 save 有 selected Level；
- 旧 save 没有新字段时，不得凭 `applied_upgrade_counts` 盲目重建精确 Level，因为 Echo 历史无法区分；
- 对旧 save 的 fallback 必须显式标记 compatibility approximation 或采用安全默认，不可悄悄声称精确。

P0-00B 若确认正式存档兼容是硬需求，再决定旧档迁移策略；否则至少保证新 schema round-trip。

---

## P0-09B3 — Offer/View Data Level Projection

Manifest definition 仍然是静态定义，不把当前 Level 写回 Manifest。

UI 所需 Level 必须来自：

```text
static definition
+
side run-state Level read model
```

推荐 Offer/View 层附加：

```text
current_level
next_level
```

不得 mutate `CardfrontUpgradeManifest.DEFINITIONS`。

---

## P0-09B4 — Minimal Player-Facing Level Feedback

P0 只需让玩家能辨认：

```text
首次选择：获得 / Lv.1
已有卡再次出现：Lv.N -> Lv.N+1
```

不要求此时把完整 Lv2/Lv3 数值轨全部设计出来。

如果某旧升级仍只是 legacy effect，描述应避免虚构尚未实现的 Level 特效。

---

## P0-09B5 — No Deck Inflation Test

连续选择同一 upgrade ID N 次：

- eligible/deck ID 集合中该 ID 仍只有一个 identity；
- selected Level 递增；
- 不创建 N 个 card instance；
- Manifest 定义数量不增长。

---

# 7. P0-10 详细施工卡：AI Observation Boundary

## P0-10A1 — Current AI Read-Set Audit

先扫描：

- `CardfrontAiCommander`；
- `CardfrontAiUpgradePolicy`；
- `CardfrontTacticalUpgradeValuePolicy`；
- `CardfrontDeckUpgradeValuePolicy`；
- `RoundDirector.get_upgrade_value_context()`。

输出真实字段清单：

```text
AI currently reads
AI currently could read because full object is passed
AI does not need
```

没有 read-set audit，不得直接设计一个“大而全 Observation”。

---

## P0-10A2 — Observation Is an Allowlist, Not a Redaction List

禁止设计：

```text
full GameState
 -> remove a few secret keys
 -> AI
```

必须设计：

```text
empty DTO
 -> explicitly copy allowed fields
 -> AI
```

原则：未来 GameState 新增字段时，AI 默认**看不到**，除非显式加入 allowlist。

---

## P0-10A3 — Three Information Buckets

### `PublicBattleState`

只包含正常对手可观察/确定的信息，例如：

- round/phase；
- 双方公开 command chamber health/ratio；
- 公开 territory summary；
- 公开 Support view state/owner/connectivity（如果玩家 UI 也公开）；
- 公开 battlefield entities/towers；
- 公开 gate/bridge state；
- 已经公开使用过的卡/历史事件。

### `OwnPrivateState`

只属于 AI 自己：

- AI hero/deck identity；
- AI 自己 selected Levels / run progression；
- AI 自己 resources / command points；
- AI 自己合法可用状态。

AI 当前 Offer 可以继续作为 `choose(offer, ...)` 的显式参数，不需要藏进巨大 Observation。

### `ObservedEnemyHistory`

只来自当前对局已发生、可观察事件：

- 对方过去公开使用的牌；
- 过去公开部署/侧翼行为；
- 已公开的 support capture；
- 可由公开行为形成的粗粒度倾向估计。

P0 只建立容器/权限边界，不实现复杂长期推断器。

---

## P0-10A4 — Explicit Forbidden Fields

Observation schema/test 必须明确拒绝：

- Player current Offer；
- Player未揭示选择；
- future Offer；
- RNG state / seed；
- exact hidden route tendency score；
- hidden tactical instruction；
- SceneTree/Node/runtime Object reference；
- `RoundDirector` reference；
- full Player RunState reference；
- callbacks that can query arbitrary state。

---

## P0-10A5 — No Object Escape Hatch

Observation DTO 最好只允许：

- primitive；
- Array of allowed DTO/primitive；
- Dictionary with whitelisted keys；
- Vector2/Vector2i 等纯值类型（若需要）。

测试递归遍历 Observation：

> 不得出现能继续 `get()` 任意游戏状态的 Node/RefCounted runtime object。

否则“字段白名单”只是表面，AI 仍能通过 object reference 逃逸。

---

## P0-10A6 — Own-State Projection, Do Not Pass Full RunState

当前 ValuePolicy 已支持 Dictionary `_read()`，因此 P0 推荐先构造：

```text
AiOwnStateView Dictionary
```

只包含现有 policy 确实需要的字段。

例如当前已确认至少涉及：

- deck_id；
- rarity_level；
- territory_defense_cap；
- selected/effect history（按迁移后的明确字段）；
- policy 真正读取的其他 own-state 字段。

每个字段必须来自 read-set audit，而不是“可能以后有用”。

---

## P0-10A7 — Context Projection Replaces Free-Form Escape Hatch

当前 `get_upgrade_value_context()` 可以自由添加 key。

P0 后目标：

```text
AIObservationBuilder
 -> approved valuation context projection
 -> ValuePolicy
```

RoundDirector 不应继续成为“随手把敌方内部字段塞给 AI”的长期入口。

P0 可以保留兼容 facade，但其输出必须从 Observation 派生。

---

## P0-10B1 — Commander Adapter First, No Policy Rewrite

先让：

```text
CardfrontAiCommander
```

在不改变评分算法的前提下消费 projected own state + approved context。

目标：

> 输入边界改变，策略尽量不改变。

如果因为字段缺失导致评分明显变化，先补“确属合法且旧 policy 已经依赖”的字段，不要顺手重调 archetype weights。

---

## P0-10B2 — Decision Strength Freeze Test

固定 AI Offer + 固定合法 Observation：

- 迁移前/迁移后排名应尽量一致；
- 如果变化，checkpoint 必须逐项解释是因为删除了哪一个不应读取的信息；
- 不允许为了让 snapshot 测试通过而偷偷调权重。

---

## P0-10B3 — Secret Injection Metamorphic Test

构造两个 runtime：

```text
公开战场完全相同
AI own private 完全相同
Player hidden Offer / future RNG / hidden route value 不同
```

要求生成的 AI Observation 完全相同。

这比“检查字段名里没有 secret”更强。

---

## P0-10B4 — Public Change Sensitivity Test

反过来：

```text
公开敌方单位/支点状态发生变化
```

Observation 应按 schema 正常变化。

避免把“信息公平”误实现成“AI 什么都看不到”。

---

## P0-10B5 — No Difficulty Cheats

P0 Observation/Commander adapter 不得引入：

```text
AI damage multiplier
AI HP multiplier
AI resource multiplier
AI cost discount
AI hidden extra draw
AI same-frame reaction
```

未来若存在 handicap，必须是另一个明确命名的系统，不属于 Decision Strength。

---

# 8. P0-06～P0-10 Authority Matrix

| Domain | Current authority | P0 target authority | Explicitly NOT authority |
|---|---|---|---|
| Support truth | Support runtime（前置 P0 完成后） | 同一 runtime | visual node / RegionInfoPanel |
| Support view state | 尚未正式存在 | Support presenter/view-model | gameplay controller |
| Draft lifecycle | RoundDirector + PhaseController | 保持 | ThreeChoicePanel display mode |
| Draft display mode | ThreeChoicePanel `_peeking`/position | 单一 `DRAFT_VISIBLE/BATTLEFIELD_PREVIEW` state | RoundDirector phase |
| Offer generation | UpgradeDraftSystem single RNG | 同一 DraftSystem + per-side RNG/context | 两个 DraftDirector |
| Static upgrade definition | UpgradeManifest | 保持 | Player/AI duplicate manifests |
| Effect application history | `applied_upgrade_counts` | compatibility/history | player-facing Level |
| Player-facing per-card Level | 当前无严格 authority | selected Level store in RunState | echo count / rarity |
| AI decision | CardfrontAiCommander | 保持 | ObservationBuilder |
| AI information boundary | free-form run_state/context | AIObservationBuilder allowlist | full GameState/RunState escape hatch |

---

# 9. Required Checkpoint Split

本批禁止用一个“大提交”完成 P0-06～P0-10。

最低 checkpoint 粒度：

```text
P0-06A1 visual ownership
P0-06A2 presentation DTO/view-state
P0-06B support visuals
P0-06C legacy region UI separation

P0-07A geometry/lifecycle baseline
P0-07B stable peek chrome + display state
P0-07C timeout/resize/signal regression

P0-08A RNG baseline
P0-08B side RNG isolation
P0-08C side context/container

P0-09A count semantics audit
P0-09B selected Level authority
P0-09C resolver/save migration
P0-09D minimal UI + no-inflation regression

P0-10A AI read-set audit
P0-10B observation schema/allowlist
P0-10C own-state/context projection
P0-10D commander adapter
P0-10E secret/public metamorphic tests
```

每一个 checkpoint 仍执行 Guardrails 的 12 项 North-Star Drift Check。

---

# 10. Mutation Budgets — Batch B

## P0-06

Allowed by default:

```text
support presentation files
battlefield visual integration owner
relevant support visual scene/assets
tests/checkpoint docs
```

Read-only unless proven necessary:

```text
run/draft/ai
support capture/graph/deployment rules
```

## P0-07

Allowed:

```text
CardfrontThreeChoicePanel.gd
CardfrontThreeChoicePanel.tscn
relevant UI tests/checkpoint
```

Read-only:

```text
RoundDirector
PhaseController
DraftSystem
```

只有真实 lifecycle bug 证明必须修改 director/phase 时才越界。

## P0-08

Allowed:

```text
CardfrontUpgradeDraftSystem.gd
minimal RoundDirector seed/call-site adaptation
Draft isolation tests
```

Read-only:

```text
UpgradeManifest definitions
UpgradeResolver effects
AI scoring weights
route systems
```

## P0-09

Allowed:

```text
CardfrontFactionRunState.gd
CardfrontUpgradeResolver.gd
minimal offer/view projection
CardfrontUpgradeChoiceCard.gd if Level display required
save snapshot/schema integration
tests
```

Read-only unless migration evidence:

```text
card balance values
AI archetype weights
route content
```

## P0-10

Allowed:

```text
new AI observation DTO/builder
CardfrontAiCommander adapter
minimal RoundDirector valuation-context facade adaptation
AI info-boundary tests
```

Read-only unless read-set migration requires narrow change:

```text
AI scoring formulas/archetype weights
Draft generation
card balance
```

---

# 11. Batch B Stop Rules

除 Guardrails 通用 Stop Rules 外，本批出现以下情况必须停：

1. Support visual 需要自己查询 graph 才能决定 Online；
2. Peek 修复要求恢复 battle input 才“好用”；
3. 为了固定按钮需要重写整个 Draft layout；
4. RNG 隔离需要改变 rarity/eligibility 才能测试通过；
5. Agent 想让 Player/AI 永不抽到同卡来体现“独立”；
6. `applied_upgrade_counts` 被直接改名 Level，未处理 Echo；
7. Echo 自动重复导致 player-facing Level 增长；
8. 为了 AI 兼容继续传完整 RunState/GameState；
9. Observation 中出现 Node/Runtime object escape hatch；
10. AI 输入收窄后表现变化，于是顺手改权重“补回来”；
11. P0 开始实现 reroll/route/deep cards；
12. 任一后半段步骤开始重新设计 Command Point / Aim / Volley。

正确输出：

```text
BLOCKED / AMENDMENT REQUIRED
- exact old-code fact
- frozen invariant affected
- smallest missing decision
- why current step cannot safely infer it
```

---

# 12. Batch B Completion Definition

Batch B 被正确执行后，应得到：

```text
Support runtime
 -> read-only low-occlusion visuals

Draft lifecycle
 -> fixed visibility-only battlefield preview

One DraftSystem
 -> independent Player/AI random state + containers

One static Manifest
 -> per-side selected Level authority in RunState
 -> effect application history kept distinct

Game runtime
 -> explicit AIObservation allowlist
 -> existing AI Commander / ValuePolicy
```

而**不应该**得到：

```text
第二套 Support rule
第二套 Draft director
第二份 Player/AI card manifest
rarity = level
Echo = hidden level-up
full GameState with a few fields hidden
Hard AI
P1 route/reroll 偷跑
```

最后检查：

> **后半段的每一个“便利接口”是否都被收窄成单向数据流，而不是让 UI、Draft、AI重新获得绕过冻结核心的能力？**

若不能明确回答 Yes，P0-11 不得开始。
