# Repository Reorganization v2 — 2026-08-18

## 目标

在不修改任何 Godot 运行时代码、场景、资产、测试与 `res://` 路径的前提下，收敛 `docs/` 根目录的双重分类问题，并把美术生产规范升级到 v0.2。

## 发现的问题

仓库已经存在：
- `设计_design/`
- `技术_technical/`
- `性能_performance/`
- `历史_history/`

但 `docs/` 根目录仍保留大量同职责文件以及一批 P0/P1 dated execution documents，造成“已有分类目录 + 根目录平铺”两套组织方式并存。

本次不再创建新的英文 `design/technical/history` 目录，而是沿用既有中英双语分类。

## 本次迁移

### 设计 → `设计_design/`
- `BATTLEFIELD_ENTITIES_AND_DEFENSE_TOWERS_PLAN.md`
- `CARDFRONT_STRATEGIC_MAP_DESIGN.md`
- `GRILLME_GAME_DESIGN_INTERVIEW.md`

### 技术 → `技术_technical/`
- `ANDROID_EXPORT.md`
- `ARCHITECTURE.md`
- `B1_SIMULATION_MODEL.md`
- `CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`
- `RELEASE_PROCESS.md`
- `SAVE_SYSTEM.md`
- `TESTING.md`

### 性能 → `性能_performance/`
- `PERFORMANCE.md`
- `画质档位参数速查表.md`

### 历史施工 → `历史_history/cardfront_refactor_2026-08/`
- 2026-08 P0/P1 execution batches、guardrails、freeze、amendments；
- `CARDFRONT_REFACTOR_PLAN_2026-08-07.md`

### 整理记录 → `历史_history/repository_cleanup/`
- 上一轮 `REPOSITORY_CLEANUP_2026-08-18.md`
- 本文件。

## 根目录保留

`docs/` 根目录只保留真正需要作为总入口/当前脊柱的文本：
- `README.md`
- `PROJECT_STATUS.md`
- `ROADMAP.md`

以及职责目录：
- `art/`
- `设计_design/`
- `技术_technical/`
- `性能_performance/`
- `历史_history/`
- `cardfront_refactor_checkpoints/`

`CARDFRONT_STRATEGIC_MAP_DESIGN.md` 旧路径仅保留一个迁移指针，因为当前 `PROJECT_STATUS.md` 历史段落仍显式引用该路径；正文 canonical copy 位于 `设计_design/`。

## 美术规范升级

`docs/art/Cardfront_Art_3D_Production_Spec_v0.2_2026-08-18.docx` 新增 D06～D11：
- 玩具化 PBR；
- 选择性阴影；
- 语义低浮雕；
- 三带式 Diorama；
- 分层阵营信号；
- 事件分级 VFX Budget。

v0.1 保留为前序冻结版本，不删除。

## 链接与历史说明

本次迁移使用相同 Git blob 迁移历史正文，避免在“整理”过程中改写历史内容。GitHub/Git 可识别为 rename 或同内容移动。

仓内导航入口已统一更新。历史 commit/PR 或旧历史文档中写死的旧 `docs/<filename>` 路径可能仍指向旧位置；需要追溯时以本迁移表和 Git history 为准。为了真正清理根目录，本次不为全部旧文件保留十余个一行式 redirect stub。

## 安全边界

- 不修改 `scripts/`
- 不修改 `scenes/`
- 不修改 `assets/`
- 不修改 `.github/workflows/`
- 不删除测试
- 不改变 Godot `res://`
- 不改变 gameplay authority
- 不改变任何已迁移历史正文 blob

PR 合并前必须用 `main...branch` compare 验证变更只发生在 `docs/`。
