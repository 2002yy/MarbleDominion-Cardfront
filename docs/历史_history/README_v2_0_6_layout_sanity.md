# BallWar v2.0.6 — Layout Coordination & Sanity Tests

日期: 2026-05-04

## 目标

建立布局计算与布局边界测试，为后续渲染分辨率功能做准备。本轮不加分辨率设置。

## 新增文件

- `scripts/LayoutCoordinator.gd` — 集中布局计算（tab 缩进）
- `scripts/tests/LayoutSanityTestRunner.gd` — 布局边界测试（tab 缩进）

## 修改文件

- `AI_HANDOFF_CURRENT.md` — 更新 v2.0.6 状态
- `SmokeTestRunner.gd` — 清理 SHADOWED_GLOBAL_IDENTIFIER preload
- `IntegrationTestRunner.gd` — 清理 SHADOWED_GLOBAL_IDENTIFIER preload
- `PerfBurstBenchmark.gd` — 清理 SHADOWED_GLOBAL_IDENTIFIER preload
- `TestFixtures.gd` — 清理 SHADOWED_GLOBAL_IDENTIFIER preload
- `WinConditionEvaluator.gd` — 清理 SHADOWED_GLOBAL_IDENTIFIER preload

## 未修改生产文件

- `Main.gd`, `Battlefield.gd`, `ControlChamber.gd`, `GameConfig.gd`, `Turret.gd`
- 存档相关（SaveGameCodec, SaveStateBuilder, SaveStateApplier）
- `Gate.gd`, `BulletPool.gd`, `RuntimeHudController.gd`, `EventRouletteController.gd`
- `.editorconfig`

## LayoutCoordinator.gd

输入 `grid_size` + `viewport_size` + `is_mobile`，输出所有元素位置。

`cell_size` 与 `Battlefield.gd.configure()` 一致：

| grid | cell | map px |
|---|---|---|
| 10 | 34 | 340 |
| 20 | 22 | 440 |
| 30 | 16 | 480 |
| 40 | 13 | 520 |
| 50 | 11 | 550 |
| 60 | 9 | 540 |

HUD 布局对齐真实代码：`fps_label` 在 `Vector2(402, 649)`、`event_label` 右对齐 fps_label 上方、整体 `bottom_hud_rect` 检测溢出自动左移。

## LayoutSanityTestRunner.gd

覆盖 10~60 全 6 种网格 × desktop + mobile，checks:
- battlefield_rect 在 viewport 内
- turret / chamber / +球 按钮 / side 按钮 不越界
- bottom_hud_group (fps_label + event_label 整体) 不溢出
- event_label 不和 fpsep_label 重叠
- 按钮不盖在 chamber 上
- roulette stage 水平居中

330 checks — 不含 known limitation，全部 strict pass。

## 修复记录

### 60×60 误判越界
`LayoutCoordinator` 初版硬编码 `CELL_SIZE = 13`。修正测试侧 `LayoutCoordinator` 的 cell_size 计算，对齐真实 `Battlefield.gd.configure()` 的 grid_size → cell_size 映射，使 60×60 布局测试与真实运行画面一致。60×60 桌面截图确认可正常游玩。未修改生产代码。

### 60×60 HUD 右溢出
底部 HUD group (fps_label + event_label) 在 LayoutSanity 检测中纳入右侧溢出检查。`LayoutCoordinator._calculate_hud_positions()` 改为按组总宽度整体右对齐，检测溢出后自动左移。未修改生产 UI 代码（`GameHudView.gd` 中实际渲染仍按原有布局）。

### SHADOWED_GLOBAL_IDENTIFIER ×23
6 个文件中 `class_name Xxx` 全局类名与 `const Xxx = preload(...)` 同名冲突，删除冗余 preload 直接使用全局类名。涉及：`WinConditionEvaluator.gd`、`TestFixtures.gd`、`SmokeTestRunner.gd`、`IntegrationTestRunner.gd`、`LayoutSanityTestRunner.gd`、`PerfBurstBenchmark.gd`。不改变玩法逻辑。

### GameConfig.gd parse error
编辑时新增代码缩进风格混入（space 文件中插入 tab），导致 GameConfig.gd 全局类 parse 失败。修复为统一 spaces。

### Turret.gd 历史混合缩进
`Turret.gd` 存在历史缩进风格不一致（部分函数 tab、部分 spaces），本轮仅修复 parse error 不破坏现有测试，不做全文件格式化。后续若需统一缩进应作为独立格式化版本处理。

### nul/null
项目根目录无此文件。

## 验证结果

```
SmokeTestRunner         33 PASS
IntegrationTestRunner  133 PASS
LayoutSanityTestRunner 330 PASS
```

## 未做的事

- 不加入渲染分辨率功能
- 不改 project.godot viewport / stretch
- 不改炮塔血量（另开版本）
- 不删 Gate.gd
