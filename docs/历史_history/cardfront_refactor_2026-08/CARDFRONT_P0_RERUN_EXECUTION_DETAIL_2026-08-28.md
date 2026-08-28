# CARDFRONT P0 Current-main Rerun Execution Detail — 2026-08-28

Role / 作用: 施工商历史（construction history）。当前状态只读
`../../PROJECT_STATUS.md`；逐检查点验收证据读
`../../cardfront_refactor_checkpoints/`。

本文件记录 2026-08-28 会话内完成的 P0 当前主干重跑（P0-DA1 → P0-DA4）全部
批次施工细节与提交链。

## 背景链

- `P0-FT1`（正式拦截塔基准）于 2026-08-21 获产品所有者**临时视觉 GO**，接受
  源提交 `697dcbe`；HP2/HP1 剪影强化记为非阻塞美术债。
- 随后 Bridge/Gate、Beacon、工事 L1–L4、Stronghold、VFX、D21 调试视图、
  Rapid/Engineer 英雄模块等扩展提交（GO 批 2–8）推进了代码，但权威文档仍停
  在 `10ddb48`，形成治理漂移。
- 对此执行定向漂移审计 `P0-DA1_current_main_directed_drift_audit.md`
  （基线 `144b57f`）：判定 **NO-GO / MATERIAL DRIFT**，锁定了六批重跑序列。

## 批次施工记录（提交链）

### 批 0：仓库整理（`144b57f`）

- 提交删除 24 个被 formal_benchmark GO 包取代的旧 `artifacts/` 证据图。
- `截图_screenshots/.gdignore`（沿用 archive/ 先例）：证据截图不再被 Godot
  当纹理导入，清除全部 `.import` 边车。
- 补齐 4 个脚本 `.uid` 边车。

### 批 1：P0-DA2 Support/Stronghold 权威对齐（`7aa8bf6`）

- **CI Headless 回归修复**（`94a762b` 起红灯）：英雄模块接入时把
  hero+theme 循环改成单一实例化，漏掉 `HQThemeCastle`；恢复
  hero+theme+damage 三模块装配，模块计数探针改为接受任意 `HQHero*` 子节点。
- **Support Capture 独立权威**：新增
  `CardfrontSupportCaptureRuntime`（占领/抑制/Online-Offline），经
  RuntimeBuilder fail-closed 装配，battlefield meta 绑定，
  registry/context 接线。
- **呈现投影而非夺权**：`SupportDeploymentAuthority` 增加可插拔
  `presentation_state_provider`。
- **存档绑定**：`CardfrontRuntimeSnapshot` 捕获/恢复 `support_states`。
- **遗留数值消费退役**：Main 实时限时路径 `sample_bonuses()` →
  `sample_status()`（遥测）；StrongholdSystemTestRunner 遗留 needle 门禁
  扩展到 Main.gd + GameRuntimeContext.gd。
- **拆除卫生**：ArenaView `prepare_for_teardown()` 确定性逐分支释放
  SubViewport 世界，消除 Dummy renderer 拆除期 "material is null"。

### 批 2：AI Observation 边界（`31bd718`）

- 新增 `CardfrontAiObservationBuilder`（RC `def95b5` schema 移植）：
  三tier 白名单（public_battle_state / own_private_state /
  observed_enemy_history）+ 嵌套记录 schema（supports/entities/gates/
  bridges/revealed）+ `FORBIDDEN_FIELD_NAMES` 二层拒止 + 纯值拷贝原子拒收
  Object/Node/Callable。
- RoundDirector `get_ai_observation()` 单一生产者；
  `get_upgrade_value_context` 降级为观察派生 facade；实机 Draft AI 改走
  `choose_from_observation()` —— **raw run_state 对象不再触达 commander**。
- 兼容性论证：policy `_state_model` 仅读 4 个白名单字段，value context 仅
  读 valuation 字段——投影零行为偏差。
- 移植 RC 三个测试跑器：Boundary 30 / Projection 12 / Commander
  Observation 15（含决策强度冻结与秘密注入变形契约）。

### 批 3：Offer/Selected-Level 投影 + no-deck-inflation（`33c3a1f`）

- 新增 `CardfrontUpgradeOfferView.project()`：`current_level`/`next_level`
  仅从本方 `get_selected_upgrade_level` 派生，永不读
  `applied_upgrade_counts`；缺失 run state 安全投影 0→1。
- `draw_offer_for_context` 在 ID 抽取后包装投影定义——资格/稀有度权重/RNG/
  三选一/双侧隔离行为零变化。
- 移植 RC `NoDeckInflationTestRunner`（62 检查冻结）与
  `OfferLevelProjectionTestRunner`（适配回 09B3 范围：RC-09B4 玩家可见
  文本探针按契约本身移出）。

### 批 4：RC 收敛（`f2e4270` 施工 + `49fc2e3` 文档绑定）

- 全量盘点：161 个本地跑器 vs CI 清单 → 10 个暗角跑器修复并接入 CI。
  - `CardfrontCardHoverMotionTestRunner`：真 FAIL×2，硬编码旧 collapsed
    offset 58 vs 产品权威 `COLLAPSED_OFFSET=38` → 断言改引视图常量。
  - HandPanelGuidance + TargetPreviewGuidance：0 检查假绿（早于
    Main.tscn-only 装配与 `cardfront_legacy_compatibility_enabled` 旗标）
    → 改 tscn fixture + await + 旗标（对齐 CI 同族跑器）。
  - SettingsAndResult：性能条段驱动已退役的
    `player_settings._apply_performance_setting`（错误中断→空转假绿）→
    改测现权威 `RuntimeHudController.set_performance_visible`。
- CI 覆盖闭环 161/161；`artifacts/` 入 gitignore。
- parse/import 检查 0 错误；三 workflow 全绿。
- 文档绑定：`P0-DA4_current_main_rc_convergence.md`（RC 源提交
  `f2e427043aa34a422f50d4f52559bd11eabed623`）+ checkpoint hub 路由 +
  PROJECT_STATUS 时间线。

## 证据汇总

- 新增/移植测试：SupportCaptureLive 19、ObservationBoundary 30、
  ObservationProjection 12、CommanderObservation 15、NoDeckInflation 62、
  OfferLevelProjection 35。
- 回归全绿（本地+CI）：Environment 209、Stronghold 2443、Save 190、
  Restore 11、Orthographic 166、Gate 12、Scale 57、Smoke 38、
  UpgradeDeck 1023、ValuePolicy 43、RoundCombat 19、Content 115、
  黄金基线 39、Draft 族 84/170/22/20、ThreeChoice 59、暗角修复四件套
  18/12/14/14、B1 英雄审计 24/15 等。
- CI：`7aa8bf6`、`31bd718`、`33c3a1f`、`f2e4270` 四个提交上三 workflow
  全绿。

## 遗留门禁（不可自动化代劳）

- **批 5**：独立人类 North-Star 会话（对 ≥ `f2e4270` 的 RC 实机：理解度/
  节奏/公平感证据；`def95b5` 旧会话不可转移）。
- **批 6**：依批 5 证据记录最终 current-main GO/NO-GO 封印；P1 保持锁定
  至封印。
