# Cardfront Documentation Hub

本目录是 `MarbleDominion-Cardfront` 的文档导航入口。为避免多个阶段性文档互相争夺“当前真相”，文档按**权威级别**而不是按文件日期阅读。

## 1. 先看这里

| 入口 | 用途 | 权威级别 |
|---|---|---|
| [`PROJECT_STATUS.md`](PROJECT_STATUS.md) | 当前版本、已完成项、当前实施切片、下一步与暂缓范围 | **当前状态唯一入口** |
| [`art/README.md`](art/README.md) | 当前美术与 3D 生产规范入口 | **美术生产入口** |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | 代码/系统架构说明 | 架构参考 |
| [`CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`](CARDFRONT_ENGINEERING_SPEC_2026-08-07.md) | 当前大规模工程整改的冻结基线 | 工程约束参考 |
| [`cardfront_refactor_checkpoints/`](cardfront_refactor_checkpoints/) | P0/P1 执行检查点、证据和验收记录 | 实施证据 |
| [`ANDROID_EXPORT.md`](ANDROID_EXPORT.md) | Android 导出说明 | 平台说明 |

## 2. 文档阅读规则

1. **当前状态只以 `PROJECT_STATUS.md` 为准。** 日期更早的 roadmap、batch、amendment、plan 或 checkpoint 不自动覆盖当前状态。
2. **检查点是证据，不是新的第二权威。** `cardfront_refactor_checkpoints/` 用于证明某一步做过什么、如何验收。
3. **美术生产从 `art/` 入口进入。** 视觉参考素材仍保留在仓库根目录 `美术参考_art_reference/`，避免在整理时破坏现有引用和资产来源关系。
4. **阶段性 P0/P1 文档暂不物理搬迁。** 当前整理先解决导航和权威边界；批量移动必须先做全仓引用审计，再单独 PR 处理。
5. **运行时代码与资产路径不因文档整理改变。** `scripts/`、`scenes/`、`assets/` 的现有 `res://` 路径保持不动。

## 3. 当前主题索引

### 玩法 / 模拟 / 实体

- [`B1_SIMULATION_MODEL.md`](B1_SIMULATION_MODEL.md) — B1 模拟模型。
- [`BATTLEFIELD_ENTITIES_AND_DEFENSE_TOWERS_PLAN.md`](BATTLEFIELD_ENTITIES_AND_DEFENSE_TOWERS_PLAN.md) — 战场实体和防御塔方案。

### 工程整改 / 验收

- [`CARDFRONT_P0_EXECUTION_GUARDRAILS_2026-08-07.md`](CARDFRONT_P0_EXECUTION_GUARDRAILS_2026-08-07.md) — P0 执行护栏。
- `CARDFRONT_P0_EXECUTION_DETAIL_BATCH_*_2026-08-08.md` — 分批实施细纲。
- `CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md` — 实施前冻结补丁。
- [`cardfront_refactor_checkpoints/`](cardfront_refactor_checkpoints/) — 每个检查点的事实证据。

### 美术 / 3D

- [`art/README.md`](art/README.md) — 美术与 3D 入口。
- [`art/Cardfront_Art_3D_Production_Spec_v0.1_2026-08-18.docx`](art/Cardfront_Art_3D_Production_Spec_v0.1_2026-08-18.docx) — 已确认 A → A3 → C → B → B2 的正式冻结稿。
- [`../美术参考_art_reference/cardfront_visual_hierarchy_v01/`](../美术参考_art_reference/cardfront_visual_hierarchy_v01/) — V-01 视觉层级参考与规范。

## 4. 整理原则

本次整理采用“**先建立入口和边界，再移动旧文件**”的方式。原因是仓库已存在大量历史验收链接、Godot `res://` 资产路径和阶段性 checkpoint；在没有全仓引用扫描前直接批量改目录，整理收益小于断链风险。

后续如果要进一步瘦身 `docs/` 根目录，建议单独执行一次 link-safe 文档迁移：`docs/design/`、`docs/technical/`、`docs/history/`，并同时更新所有仓内链接、CI/脚本引用与 README。
