# Changelog / 版本脊柱

Date / 日期: 2026-05-17  
Role / 作用: condensed milestone spine / 精简版本脊柱

Detailed stage notes now live under [docs/history/](docs/history/README.md).  
详细阶段记录现已统一收敛到 [docs/history/](docs/history/README.md)。

## Release Reading Rule / Release 分层

- Cardfront Prototype: `v0.1.0`
  - new repository baseline, with Cardfront mode entry, player-vs-AI duel baseline, and headless smoke coverage
- Latest Stable: `v2.1.11.1`
  - recommended public download, with Windows zip and Android debug APK assets
- Milestone Releases: `v2.1.10`, `v2.1.9`, `v2.1.8`, `v2.1.4`, `v2.0.3`
  - important checkpoints, not the default download signal
- Historical Releases: `v1.9.x`, `v0.1.0-mvp`
  - reconstructed history, not the recommended download path

## `v2.1.11.1` — UI Hotfix / 控制仓文字热修复

- Fixed control-chamber bottom gate label clipping / 修复控制仓底部门文字裁切
- x2/x3 no longer gets clipped into x in narrow gate layouts / 倍率标签在窄门布局下不再被裁为单字符
- Reduced gate text outline thickness so 发射 appears less heavy / 减少门文字描边厚度，让"发射"显示不再过粗
- Rendering-only change; no chamber physics, multiplier, event, bullet, or collision rule changes / 纯绘制变更，不涉及物理、倍率、事件、子弹或碰撞逻辑
- Verified with SmokeTestRunner, IntegrationTestRunner, LayoutSanityTestRunner, and StartMenuSceneTestRunner / 以 SmokeTestRunner、IntegrationTestRunner、LayoutSanityTestRunner、StartMenuSceneTestRunner 验证通过

## `v2.1.11` — Public Repository Hardening / 公开仓库收口

- Restored corrupted Chinese UTF-8 text in key GDScript files / 恢复关键脚本中被破坏的中文编码
- Fixed Android ETC2/ASTC export configuration and added export-check helpers / 修复 Android ETC2/ASTC 导出配置，增加检查与修复脚本
- Published Windows zip and Android debug APK assets on GitHub Releases / 发布 Windows zip 和 Android debug APK 到 Releases
- Continued structure cleanup through `ChamberBallPhysics`, `BulletPool` swap-remove, and `EventRouletteController` signal decoupling / 继续控制仓物理外提、子弹池交换删除、事件控制器信号解耦

**Public repository hardening / 公开仓库产品化收口:**
- Restructured README top section for player/recruiter audience / README 顶部重构：面向玩家与招聘官
- Added GitHub Actions CI workflow / 接入 GitHub Actions CI：项目加载验证 + 10 测试并行矩阵
- Fixed Android export scripts: removed hardcoded absolute paths / Android 导出脚本去本机绝对路径
- Aligned `export_presets.cfg` settings / 对齐 export_presets.cfg 预设配置
- Historical docs remain in `docs/history/` — root directory clean / 历史文档全部归档到 docs/history/

- Current Latest Stable / 推荐公开下载版本

## `v2.1.10` / 安全加固与性能优化

- Added save file size limits, path traversal filtering, and nested save-data validation / 增加存档文件大小限制、路径穿越过滤、嵌套数据校验
- Reduced turret queue, bullet map-size lookup, dictionary iteration, and bullet recycling hot-path costs / 优化炮台队列、子弹地图尺寸查询、字典遍历、回收热路径
- Improved StartMenu button prominence, text contrast, and slot readability / 改进开始菜单按钮视觉、文字对比度和槽位可读性
- Repacked Windows releases as `.exe + .pck` zip bundles / Windows 发布包改为 `.exe + .pck` 压缩包

## `v2.1.9` / 设置系统与结算面板

- Added `PlayerSettingsStore.gd` / 新增玩家设置存储
- Added interactive `SettingsPanel` / 新增交互式设置面板
- Added `ResultPanel` with victory reason, game duration, final territory ratio, and statistics / 新增结算面板：胜利原因、游戏时长、占领率、统计
- Added peak active bullet and event trigger statistics / 新增峰值活跃子弹和事件触发统计
- Connected low-FX, performance HUD, and event-log settings to runtime behavior / 低特效、性能 HUD、事件日志设置接入运行时

## `v2.1.8` / 装饰层事件化与状态外提

- Changed `BattlefieldDecorLayer` from polling to event/dirty-marker behavior / 战场装饰层从轮询改为事件/脏标记模式
- Extracted `ChamberState` from `ControlChamber` / 从 ControlChamber 外提 ChamberState
- Improved StartMenu layout, preview, and slot readability / 改进开始菜单布局、预览和槽位可读性
- Strengthened save recovery and continue flow coverage / 增强存档恢复与继续游戏链路

## `v2.1.5` - `v2.1.7` / UI 打磨与修复

- Continued event explanation, menu preferences, and UI detail work / 事件说明、菜单偏好、UI 细节持续打磨
- Fixed save/restore bugs and improved continue stability / 修复存档/恢复错误，提升继续游戏稳定性
- Containerized StartMenu behavior and cleaned lifecycle/event state / 开始菜单行为容器化、生命周期与事件状态清理
- Continued asset audit and resource-boundary cleanup / 持续素材审计与资源边界清理

## `v2.1.0` - `v2.1.4` / 场景化与结构基线

- Migrated `StartMenu.tscn` into an editable UI scene / 开始菜单迁移为可编辑 UI 场景
- Split continue flow into `prepare_*` and `apply_*` / 继续流程拆分为 prepare/apply 两阶段
- Moved `restore_from_state(...)` ownership out of `Main.gd` into runtime objects / 将恢复逻辑从 Main.gd 移至运行时对象
- Clarified `Main.gd` as top-level orchestration / 明确 Main.gd 为顶层编排角色
- Established the stable structural baseline / 确立了当前仍被引用的稳定结构基线

## `v2.0.x` / 系统化测试与编排层

- Systematized save/restore, win conditions, and layout sanity coverage / 系统化存档/恢复、胜负判断、布局回归覆盖
- Formed coordination layers such as `SaveFlowController` and `GameStateCoordinator` / 形成 SaveFlowController、GameStateCoordinator 等编排层
- Introduced a more maintainable test matrix and version-note workflow / 引入可维护的测试矩阵和版本文档工作流
- Laid the groundwork for later v2.1.x UI scene migration / 为后续 UI 场景迁移打下基础

## `v1.9.x` / 多模式规则与性能

- Developed multi-mode rules and event systems / 开发多模式规则与事件系统
- Focused on bullet-pool, trail, and battlefield rendering performance / 聚焦子弹池、弹道和战场渲染性能
- Introduced `SmokeTestRunner`, `IntegrationTestRunner`, and `PerfBurstBenchmark` / 引入冒烟测试、集成测试和性能基准
- Moved the project from "playable" toward "maintainable" / 从"可玩"走向"可维护"

## `v1.7.x` - `v1.8.x` / 早期稳定化

- Stabilized early battlefield, control-chamber, and turret rules / 稳定早期战场、控制仓和炮台规则
- Polished early UI and battlefield feedback / 打磨早期 UI 和战场反馈
- Started accumulating versioned stage documentation / 开始积累版本化阶段文档

## `v0.1.0-mvp` / 创始原型

- Established the minimum four-faction territory-control loop / 建立最小四阵营领土争夺玩法闭环
- Implemented the earliest battlefield, turret, control-chamber, and launch logic / 实现最早期的战场、炮台、控制仓和发射逻辑
- Preserved as the historical founding prototype / 作为创始原型保留
