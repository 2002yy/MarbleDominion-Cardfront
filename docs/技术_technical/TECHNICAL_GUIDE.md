# Technical Guide / 技术指南

Date / 日期: 2026-05-16
Role / 作用: live engineering guide / 当前工程协作与技术边界

This file replaces scattered historical audit and handoff notes.  
这份文档用于替代零散的历史审计、迁移说明和交接附页。

Keep it current, short, and operational.  
请把它维护成“当前有效”的短文档，而不是继续堆历史过程稿。

## 1. Canonical Docs / 主文档分工

- `README.md`
  - concise 9-section entry point, links to `docs/` / 精简 9 区块入口，链接到 `docs/`
- `docs/ROADMAP.md`
  - current progress, what is done, what is next, what is deferred / 进度板、已完成、下一步、暂缓项
- `docs/ARCHITECTURE.md`
  - system layering, ownership rules, architecture guidelines / 系统分层、归属规则、架构原则
- `docs/TESTING.md`
  - correctness baseline, performance probes, and when to run which tests / 正确性基线、性能探针、运行建议
- `docs/SAVE_SYSTEM.md`
  - save slots, backup recovery, version checks, input sanitization / 存档槽、备份恢复、版本校验、输入清洗
- `docs/PERFORMANCE.md`
  - performance probe overview and baseline summary / 性能探针概览与基线摘要
- `docs/ANDROID_EXPORT.md`
  - Android export troubleshooting checklist / Android 导出排错清单
- `docs/RELEASE_PROCESS.md`
  - packaging and release workflow / 打包与发布流程
- `docs/技术_technical/AI_HANDOFF_CURRENT.md`
  - fast session takeover card for the next AI / Codex run / 下一次 AI/Codex 接管卡
- `docs/技术_technical/CARDFRONT_DECOUPLING_PLAN.md`
  - Cardfront high-coupling split order and acceptance criteria / Cardfront 高耦合拆分顺序与验收标准
- `CHANGELOG.md`
  - condensed version spine / 精简版本脊柱
- `.github/workflows/headless-tests.yml`
  - GitHub Actions headless CI: parse/import warmup + batched baseline and Cardfront runners / GitHub Actions headless CI：解析/导入预热 + 基础与 Cardfront 分批测试
- `docs/历史_history/README.md`
  - history index for stage documents / 历史阶段索引
- `docs/历史_history/README_v*.md`
  - detailed historical stage notes, intentionally preserved / 详细历史阶段记录，有保留地保存
- `assets/ASSET_SOURCES_AND_LICENSES.md`
  - asset provenance and redistribution notes / 素材来源与分发许可

## 2. Repo Scope And Entry Scenes / 仓库范围与入口场景

- Git mainline scope:
  - `BallWar/`
- root runtime entry scene:
  - `scenes/Main.tscn`
- current human-editable UI scenes:
  - `scenes/ui/StartMenu.tscn`
  - `scenes/ui/GameHUD.tscn`
  - `scenes/ui/EventRouletteView.tscn`
  - `scenes/ui/SettingsPanel.tscn`
  - `scenes/ui/ResultPanel.tscn`
  - `scenes/ui/PreviewScene.tscn`

Use the editor for layout, fonts, spacing, colors, and scene wiring where a `.tscn` already exists.  
凡是已经存在 `.tscn` 的可见 UI，优先在编辑器里改布局、字体、配色和节点连接。

Do not recreate those surfaces in code unless there is a clear runtime-only reason.  
除非有明确的运行时理由，否则不要把这些界面重新改回纯代码生成。

## 3. Current Architecture Boundaries / 当前架构边界

- `Main.gd`
  - top-level lifecycle and orchestration / 顶层生命周期编排
  - should keep shrinking away from deep restore-field mutation / 应持续收缩，不承担深层恢复逻辑
- `SaveFlowController.gd`
  - owns the continue/load flow split between `prepare_*` and `apply_*` / 负责继续/加载流程的 prepare/apply 拆分
- `RestorePlan.gd`
  - active restore planning data passed through the continue path / 沿继续路径传递的主动恢复计划数据
- `SaveGameCodec.gd`
  - validates and normalizes save data only / 仅验证和规范化存档数据
  - should not directly mutate runtime objects / 不应直接修改运行时对象
- `SaveStateApplier.gd`
  - applies cleaned data to runtime objects and systems / 将清洗后的数据应用到运行时对象与系统
- `ControlChamber.gd`, `Turret.gd`, `Bullet.gd`
  - own `restore_from_state(...)` for their internal restore mutation / 各自拥有内部恢复方法
- bullet restore path
  - still needs deferred handling / 因对象池、弹道和压力行为较重，仍需延迟处理

## 4. UI And Scene Policy / UI 与场景规则

- new visible UI should be `.tscn`-first / 新的可见 UI 优先使用 `.tscn` 场景
- scripts should prefer logic, signals, and lightweight coordination / 脚本应侧重逻辑、信号和轻量协调
- avoid rebuilding large node trees in `_ready()` when a reusable scene is the better fit / 已有可复用场景时不要用代码重建节点树
- if a scene has been manually tuned in the editor, do not overwrite it with generator-style scripts / 已手动调整的场景不要用生成式脚本覆盖
- runtime-heavy systems can stay code-driven when editor scenes add little value / 运行时较重的系统可以保留代码驱动：
  - `Battlefield.gd`
  - `BulletPool.gd`
  - pooled bullet/trail internals / 子弹池/弹道内部逻辑
  - control-chamber internal ball runtime state / 控制仓内部弹球运行时状态

## 5. Validation Policy / 验证规则

Priority / 优先级:

1. desktop local smoke/perf evidence / 桌面端本地冒烟/性能证据
2. editor parse/load health / 编辑器解析/加载健康度
3. static script scanning and targeted headless checks / 静态脚本扫描 + 定向 headless 检查
4. Codex runtime observations / Codex 运行时观察

Working rules / 工作规则:

- correctness baseline lives in `docs/技术_technical/README_TEST_MATRIX.md` / 正确性基线见测试矩阵文档
- performance probes are not correctness proof / 性能探针不能替代正确性验证
- if Codex runtime crashes but there is no clear parse/script failure and desktop local does not reproduce it, record it as an environment limitation instead of rewriting code speculatively / 无法重现的环境限制不做推测性重写
- when feature work is UI-heavy, still leave controller/logic tests, a benchmark hook, or a manual verification checklist / UI 重的工作也尽量保留逻辑测试或人工验证清单

## 6. Asset Boundary / 资源边界

- `assets/`
  - curated, import-ready, redistribution-aware files only / 仅存放整理好、可导入、可分发的文件
- `美术参考_art_reference/free_ui_assets/`
  - research material, raw downloads, and source capture artifacts / 调研素材、原始下载和源文件

Before shipping or mirroring third-party material, check `assets/ASSET_SOURCES_AND_LICENSES.md`.  
任何第三方资源在正式提交或分发前，都先看 `assets/ASSET_SOURCES_AND_LICENSES.md`。

## 7. Maintenance Rule / 维护规则

- if a doc is about the current truth, fold it into one of the live docs above
- if a doc is only a temporary process log, do not let it become permanent root clutter
- detailed stage history belongs under `docs/历史_history/`
- when a new version gets its own stage note, keep the live docs aligned instead of copying status text into many places

## 8. Android Export Boundary / Android 导出边界

- public-facing export notes should stay summarized in `README.md`
- operational export checklist and helper scripts can live in `docs/技术_technical/README_ANDROID_EXPORT.md` and `tools/`
- `project.godot` must keep:
  - `[rendering]`
  - `textures/vram_compression/import_etc2_astc=true`
