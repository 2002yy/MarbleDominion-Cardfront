# Technical Docs / 技术文档

这里存放当前仍有执行价值的 Cardfront 工程规范、架构、模拟、测试、存档、平台与发布资料。当前状态仍以 [`../PROJECT_STATUS.md`](../PROJECT_STATUS.md) 为唯一入口。

## 当前工程入口

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — 代码与系统架构。
- [`B1_SIMULATION_MODEL.md`](B1_SIMULATION_MODEL.md) — B1 模拟模型与权威边界。
- [`CARDFRONT_ENGINEERING_SPEC_2026-08-07.md`](CARDFRONT_ENGINEERING_SPEC_2026-08-07.md) — 大规模工程整改冻结基线。
- [`TESTING.md`](TESTING.md) — 测试策略、runner 与验收规则。
- [`SAVE_SYSTEM.md`](SAVE_SYSTEM.md) — 存档系统。
- [`ANDROID_EXPORT.md`](ANDROID_EXPORT.md) — Android 导出。
- [`RELEASE_PROCESS.md`](RELEASE_PROCESS.md) — 发布流程。
- [`TECHNICAL_GUIDE.md`](TECHNICAL_GUIDE.md) — 工程边界、编辑器协作与验证规则。
- [`AI_HANDOFF_CURRENT.md`](AI_HANDOFF_CURRENT.md) — AI/Codex 快速接管卡。
- [`CARDFRONT_DECOUPLING_PLAN.md`](CARDFRONT_DECOUPLING_PLAN.md) — 耦合治理参考。
- [`PROJECT_PRINCIPLES.md`](PROJECT_PRINCIPLES.md) — 项目级维护原则。
- `Godot素材导入与格式速查手册.docx` — Godot 素材导入参考。

## 兼容/旧入口

- `README_TEST_MATRIX.md` — 旧测试矩阵资料，当前以 `TESTING.md` 为准。
- `README_ANDROID_EXPORT.md` — 旧 Android 导出说明，当前以 `ANDROID_EXPORT.md` 为准。

## 规则

- 工程文档不得成为第二份 `PROJECT_STATUS`。
- 一次性 P0/P1 execution batch、freeze、amendment 已归档到 `../历史_history/cardfront_refactor_2026-08/`。
- 运行时代码路径、Godot `res://` 与资产 registry 不因文档重组改变。
