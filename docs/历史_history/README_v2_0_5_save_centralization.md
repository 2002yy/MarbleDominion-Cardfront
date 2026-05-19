# BallWar v2.0.5 — Save System Centralization

日期: 2026-05-04

## 目标

存档版本策略集中管理 + save/load 编排解耦，不加新玩法。

## 新增文件

- `scripts/SaveStateBuilder.gd` — 从游戏对象采集状态 → 生成 save Dictionary
- `scripts/SaveStateApplier.gd` — 将 clean save data 应用回游戏对象

## 修改文件

- `scripts/SaveGameCodec.gd` — 新增 `CURRENT_SAVE_VERSION` 常量、`get_current_save_version()`、`is_supported_save_version()`
- `scripts/Main.gd` — `_save_game_progress()` 调用 `SaveStateBuilder`；`_apply_saved_state()` 调用 `SaveStateApplier`；硬编码 `"1.9.34"` → `SaveGameCodec.get_current_save_version()`；版本检查 → `SaveGameCodec.is_supported_save_version()`；移除重复的 `SAVE_MAJOR_PREFIX` 常量；修复 42 行 tab 污染为 spaces
- `AI_HANDOFF_CURRENT.md`
- `.editorconfig` — 新增，声明 `[*.gd] indent_style = tab` 为标准方向

## 未修改文件

- `scripts/Battlefield.gd`、`BulletPool.gd`、`ControlChamber.gd`、`EventRouletteController.gd`、`EventRouletteView.gd`、`GameConfig.gd`、`Gate.gd`、`Turret.gd`、`WinConditionEvaluator.gd`
- 所有 test 文件
- 其余所有生产脚本

## 重构内容

```
之前:  save_version 分散在 Main.gd (硬编码) + SaveGameCodec (校验)
之后:  save_version 集中在 SaveGameCodec.gd

之前:  Main.gd._save_game_progress() 内联拼字典 (60+ 行)
之后:  _save_game_progress() → SaveStateBuilder.build_save_payload()

之前:  Main.gd._apply_saved_state() 内联恢复逻辑 (50+ 行)
之后:  _apply_saved_state() → SaveStateApplier.apply_owners/apply_factions/apply_event_state/apply_game_over_state
```

### 存档版本现状

- `SAVE_MAJOR_PREFIX = "1.9"`
- `CURRENT_SAVE_VERSION = "1.9.34"`
- 兼容策略：任何 `1.9.x` 版本号均可读取
- **本轮未改主版本号**，未破坏旧存档

## 验证结果

```
SmokeTestRunner       PASS 33 checks
IntegrationTestRunner PASS 133 checks
```

## 注意事项

- 本轮没有修改 save major 为 2.0
- 本轮没有删除 Main.gd 旧 helper
- 本轮没有修改中文编码
- 本轮没有修改 Gate.gd、BulletPool、布局代码

## 修复记录：SaveGameCodec.gd preload 失败

**现象**: 运行 SmokeTestRunner / IntegrationTestRunner 时，Godot 报 `Could not preload resource script "res://scripts/SaveGameCodec.gd"`。

**根因**: `SaveGameCodec.gd` 原文件使用 spaces 缩进，本轮新增函数最初使用 tab 缩进。GDScript 对缩进敏感，同一文件混用 tab 和 spaces 会导致解析失败，但 Godot 不直接提示缩进问题，只报 preload 错误。

**修复**: 新增代码统一为 spaces 缩进，与原文件保持一致。

## GDScript 缩进风格说明（2026-05-04 全项目审计）

审计范围：32 个 `.gd` 文件统计 leading whitespace 的 tab/space 行数。

| 类别 | 文件数 | 文件 |
|---|---|---|
| **TAB** | 14 | BulletPool, BulletTrailLayer, EventRouletteController, EventRouletteView, RuntimeHudController, SaveStateApplier, SaveStateBuilder, WinConditionEvaluator, IntegrationTestRunner, PerfBurstBenchmark, SmokeTestRunner, TestAssert, TestFixtures |
| **SPACE** | 18 | BannerController, Battlefield, Bullet, ControlBall, ControlChamber, EnergyButton, GameConfig, GameHudView, GameSceneBuilder, Gate, HudBadge, LayoutProfiles, Main.gd, MenuDecor, SaveGameCodec, StartMenuView, Turret, UIAnimationController, UIFactory |
| **MIXED** | 0 | 本轮已修复 Main.gd 的 42 行历史 tab 污染 |

项目存在历史分裂：原始游戏逻辑文件多用 spaces；测试基建和新模块统一用 tab。

## GDScript 缩进策略

当前项目存在历史混合风格：

- 部分旧核心文件使用 spaces，例如 `Main.gd`、`Battlefield.gd`、`ControlChamber.gd`、`GameConfig.gd`。
- 部分较新模块和测试文件使用 tabs，例如 `IntegrationTestRunner.gd`、`SmokeTestRunner.gd`、`TestFixtures.gd`、`WinConditionEvaluator.gd`、`SaveStateBuilder.gd`、`SaveStateApplier.gd`。
- 当前安全目标不是全项目统一缩进，而是避免单文件内混用。

后续规则：

1. 新增 `.gd` 文件默认使用 **tab**。
2. 修改已有 `.gd` 文件时，保持该文件既有缩进风格（tab 文件用 tab，space 文件用 space）。
3. 不允许同一 `.gd` 文件内混用 tab 与 spaces 作为代码块缩进。
4. 不在功能版本中做全项目格式化。
5. 若未来需要统一缩进，必须单独开格式化版本，只改行首缩进，不改逻辑。
6. `.editorconfig` 不强制 `.gd` 的 `indent_style`，避免污染历史 space 文件。

## SaveStateApplier 边界

`SaveStateApplier.gd` 只负责 save data 到运行对象的恢复编排：

- 读取 clean save data
- 判断字段是否存在
- 应用 battlefield owners
- 应用 factions 状态
- 应用 event_state
- 应用 game_over 状态
- 调用 Main.gd 传入的 chamber/turret apply 回调

它不应该负责：

- UI/HUD 创建
- 事件表现层
- 复杂节点创建
- 战斗规则
- 子弹物理
- 存档 schema 校验

后续更推荐逐步让对象自己提供：

- `chamber.import_save_state(...)`
- `turret.import_save_state(...)`
- `event_controller.import_save_state(...)`

这样能防止 SaveStateApplier.gd 变成第二个大总管。

## 仍需人工桌面验证

- 新开游戏 → 改变局势 → 保存 → 退出 → 继续游戏
- 验证：战场格子、控制仓 pending/ball、炮塔血量、事件状态、暂停/继续按钮、胜负未误触发
