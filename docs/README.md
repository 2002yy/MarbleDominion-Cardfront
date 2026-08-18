# Cardfront Documentation Hub

本目录是 `MarbleDominion-Cardfront` 的文档导航入口。文档按**权威级别 + 职责目录**阅读，避免历史施工稿、阶段性计划与当前状态互相覆盖。

## 1. 当前权威入口

| 入口 | 用途 | 权威级别 |
|---|---|---|
| [`PROJECT_STATUS.md`](PROJECT_STATUS.md) | 当前版本、已完成项、当前实施切片、下一步与暂缓范围 | **当前状态唯一入口** |
| [`art/README.md`](art/README.md) | 当前美术 / 3D / VFX 生产规范 | **美术生产入口** |
| [`ROADMAP.md`](ROADMAP.md) | 中长期路线与未完成方向 | 路线参考 |
| [`设计_design/README.md`](设计_design/README.md) | 玩法、地图、实体、素材与 UI 设计 | 设计参考 |
| [`技术_technical/README.md`](技术_technical/README.md) | 架构、模拟、测试、导出、存档、工程规范 | 工程参考 |
| [`性能_performance/README.md`](性能_performance/README.md) | 性能基线、画质档位与性能附录 | 性能参考 |
| [`cardfront_refactor_checkpoints/`](cardfront_refactor_checkpoints/) | P0/P1 检查点、事实证据与验收记录 | 实施证据 |
| [`历史_history/README.md`](历史_history/README.md) | 已完成阶段、旧施工批次与迁移记录 | 历史证据 |

## 2. 阅读规则

1. **当前状态只以 `PROJECT_STATUS.md` 为准。** roadmap、batch、amendment、plan、checkpoint 与历史 README 不会因为日期较新就自动获得更高权威。
2. **专题规范只约束自己的专题。** 例如 `art/` 是美术生产冻结规范，不替代项目状态文档。
3. **检查点是实施证据，不是第二状态库。** `cardfront_refactor_checkpoints/` 用于说明某一步做了什么、如何验收。
4. **历史施工稿已经归档。** 2026-08 的 P0/P1 batch、guardrail、freeze、amendment 与旧 refactor plan 位于 `历史_history/cardfront_refactor_2026-08/`。
5. **运行时路径不跟文档目录一起整理。** `scripts/`、`scenes/`、`assets/`、Godot `res://`、GLB 路径不因本次文档重组改变。

## 3. 当前目录职责

### `art/`
正式美术与 3D 生产规范、版本化 DOCX。当前冻结稿为 **v0.2**。

### `设计_design/`
玩法设计、地图策略、战场实体/防御塔方案、素材缺口、UI/音效设计资料。

### `技术_technical/`
当前仍有执行价值的架构与工程文档，包括 architecture、B1 simulation model、engineering spec、testing、save、Android export、release process。

### `性能_performance/`
性能基线、性能说明、画质档位与历史性能附录。

### `cardfront_refactor_checkpoints/`
按检查点保存可追溯的实施证据。原则上不再把这里的文件重新改写成“当前状态”。

### `历史_history/`
阶段历史、旧版本说明、已完成 P0/P1 施工包、文档迁移与仓库整理记录。

## 4. 文档新增规则

新增文档时先判断职责：
- 当前状态 → 更新 `PROJECT_STATUS.md`，不要再造第二份状态文档；
- 美术生产冻结 → `art/`；
- 设计方案 → `设计_design/`；
- 工程规范 → `技术_technical/`；
- 性能 → `性能_performance/`；
- 一次性施工/审计结束后 → 移入 `历史_history/` 或对应 checkpoint。

禁止再次把一批 dated batch 直接堆回 `docs/` 根目录。
