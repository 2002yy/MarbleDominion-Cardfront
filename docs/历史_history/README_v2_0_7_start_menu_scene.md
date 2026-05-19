# BallWar v2.0.7 — StartMenu.tscn 可视化迁移

日期: 2026-05-04

## 目标

将开始菜单从纯代码动态生成迁移为 `.tscn` 可视化场景。可在 Godot 编辑器中打开 `scenes/ui/StartMenu.tscn` 直接编辑布局、颜色、字体、节点层级。

## 架构

```
scenes/ui/StartMenu.tscn      ← 节点结构、布局、外观
scripts/StartMenu.gd            ← 逻辑、信号、数据刷新
scripts/StartMenuView.gd        ← 旧版 fallback（保留，不删）
Main.gd                         ← 加载/协调（.tscn 优先）
scripts/tests/StartMenuSceneTestRunner.gd  ← 场景加载验证
```

## 如何在 Godot 编辑器中编辑

1. 打开 `scenes/ui/StartMenu.tscn`
2. Scene 面板显示完整节点树
3. 选中节点 → Inspector 中改 position/size/color/font
4. 拖动节点调整位置
5. Ctrl+S 保存 → 运行游戏即刻生效

## 编辑器编辑规则

- **改布局/颜色/字体**: 在编辑器中直接改，不碰脚本
- **改信号逻辑/数据刷新**: 改 `scripts/StartMenu.gd`
- **改加载/协调**: 改 `Main.gd._create_start_menu()`
- **改旧版 fallback**: 改 `scripts/StartMenuView.gd`

## 生成器警告

`scripts/tools/build_start_menu_scene.gd` 是一次性生成工具。**编辑器内人工调整 StartMenu.tscn 后，禁止再次运行此脚本**，否则会覆盖人工修改。该脚本顶部已有注释警告。

## 信号连接表

| 节点 | 信号 | 目标方法 | 所在脚本 |
|---|---|---|---|
| StartButton | `pressed()` | `_owner._start_game(grid_size)` | `StartMenu.gd` |
| ContinueButton | `pressed()` | `_owner._continue_saved_game()` | `StartMenu.gd` |
| GridSizeOption | `item_selected(index)` | 设置 `_owner.selected_grid_size` | `StartMenu.gd` |
| ModeOption | `item_selected(index)` | 设置 `_owner.selected_game_mode_name` | `StartMenu.gd` |
| QualityOption | `item_selected(index)` | 设置 `_owner.selected_quality_name` | `StartMenu.gd` |
| TimeSpin | `value_changed(value)` | 设置 `_owner.selected_time_limit_minutes` | `StartMenu.gd` |
| PaletteOption | `item_selected(index)` | 设置 `_owner.selected_palette_name` | `StartMenu.gd` |
| SlotButton_1~5 | `pressed()` | `_owner._select_save_slot(slot)` | `StartMenu.gd` |

## 加载策略

```
ResourceLoader.exists("res://scenes/ui/StartMenu.tscn")
  ↓ 存在 → load → instantiate → setup() → get_parts()
           控制台输出: [StartMenu] Loaded scene StartMenu.tscn
  ↓ 不存在 → StartMenuView.create() (legacy)
           控制台输出: [StartMenu] Scene load failed, fallback to legacy StartMenuView.gd
```

## 关键节点路径

| 节点 | 路径 | .tscn 唯一名 |
|---|---|---|
| StartButton | `RootPanel/ConfigPanel/StartButton` | `%StartButton` |
| ContinueButton | `RootPanel/ContinueButton` | `%ContinueButton` |
| GridSizeOption | `RootPanel/ConfigPanel/GridSizeOption` | `%GridSizeOption` |
| ModeOption | `RootPanel/ConfigPanel/ModeOption` | `%ModeOption` |
| TimeSpin | `RootPanel/ConfigPanel/TimeSpin` | `%TimeSpin` |
| PaletteOption | `RootPanel/ConfigPanel/PaletteOption` | `%PaletteOption` |
| SaveSlotContainer | `RootPanel/SavePanel/SaveSlotContainer` | `%SaveSlotContainer` |
| MenuStatusLabel | `RootPanel/MenuStatusLabel` | `%MenuStatusLabel` |
| TitleLabel | `RootPanel/TitleLabel` | `%TitleLabel` |

脚本当前使用 `get_node()` 显式路径。`.tscn` 中已预置 `unique_name_in_owner=true` 属性。若在 Godot 编辑器中打开并保存场景，可用 `%NodeName` 替代 `get_node()` 路径。在编辑器保存前，`%` 引用不可用（PackedScene.pack 限制）。

## 样式说明

所有 Button 和 Label 的颜色、字体大小、描边等外观属性已写入 `.tscn` 的 `theme_override_*` 字段，可在 Inspector 中直接修改，无需改代码。`self_modulate` 也在 .tscn 中。

## SaveSlotContainer 说明

SaveSlotContainer 是静态容器（在 .tscn 中），但内部的 SlotButton 由代码根据存档摘要动态创建和刷新。不要误以为所有按钮都必须静态摆在 .tscn 中 — 运行时数据驱动的 UI 元素由脚本负责。

## 编辑器修改指南：哪些属性会被代码覆盖

| 节点 | 属性 | .tscn 可控 | 覆盖来源 |
|---|---|---|---|
| **全节点** | Position, Size | ✓ | — |
| **全节点** | theme_override (颜色/字体) | ✓ | — |
| **StartButton** | text | ✓ | — |
| **ContinueButton** | text | ✗ | `_refresh_slots()` → `"读取槽%d"` |
| **ContinueButton** | disabled | ✗ | `_refresh_slots()` |
| **SlotButton ×5** | text / tooltip / self_modulate | ✗ | `_refresh_slots()` |
| **MenuStatusLabel** | text | ✗ | `_refresh_slots()` → `"当前存档槽：%d"` |
| **OptionButton** | 选项列表 + selected | ✗ | `_init_options()` 填充并选中 |

**结论**：改位置、颜色、字体、StartButton 文字 → 生效。改动态文字/状态（ContinueButton、SlotButton、StatusLabel）→ 被代码覆盖，正常行为。

## 人工验收清单

- [ ] 打开游戏 → 看到开始菜单
- [ ] 控制台输出 `[StartMenu] Loaded scene StartMenu.tscn`
- [ ] 切换地图大小（10~60）选项正常
- [ ] 切换游戏模式（基础/占领/限时/狂野）正常
- [ ] 切换画质（低/中/高）正常
- [ ] 调整限时 SpinBox 正常
- [ ] 选择配色方案正常
- [ ] 点击"开始 / 覆盖存档" → 游戏启动
- [ ] 存档槽 1~5 选中高亮正确
- [ ] 点击"读取槽N" → 继续游戏
- [ ] 游戏中暂停 → 退出 → 返回菜单仍正常

## 修复记录

### Main.gd `:=` 类型推断错误

**现象**: Godot 编辑器报 `Parse Error: Cannot infer the type of "instance" variable`。

**根因**: `load()` 返回 `Resource`，GDScript 的 `:=` 无法推断 `scene.instantiate()` 的具体返回类型。

**修复**: `var scene := load(...)` → `var scene: PackedScene = load(...)`；`var instance := scene.instantiate()` → `var instance: CanvasLayer = scene.instantiate()`。

**教训**: Godot 中 `load()`、`dict.get()`、`array[index]` 返回值用 `:=` 容易推断失败，优先写显式类型。

### visual parity — MenuDecor 未加载

**现象**: StartMenu.tscn 加载后菜单上方大面积空白，缺少旧版中 MenuDecor 生成的装饰性控制仓预览。

**根因**: `StartMenu.gd` 中 `_init_decor()` 定义了但未在 `setup()` 中调用，`ChamberPreview` 节点始终为空。

**修复**: `setup()` 中增加 `_init_decor()` 调用，创建 `MenuDecor` 实例挂到 `ChamberPreview` 节点。同时修复 ChamberPreview .tscn 位置从 (420,260) 改为 (0,0)，避免与代码中 MenuDecor 位置叠加偏移。

### .tscn 完整性确认

`.tscn` 包含 **34 个静态节点**，覆盖旧 StartMenuView.gd 全部 23 个视觉元素。非外壳 — 所有关键控件均可直接在编辑器中选中编辑。

Remote 中 `@ColorRect@2` 来自 `Main.gd:124` `_create_background()` 匿名 ColorRect，不属于 StartMenu 范围。

**旧菜单节点全数已迁入 .tscn**，无可视化遗漏：
- Shade 背景覆盖层 ✓
- TitleLabel / SubtitleLabel / MobileHint ✓
- ChamberPreview (MenuDecor 容器) ✓
- ConfigPanel (Size/Mode/Quality/Time/Palette + ModeTip) ✓
- StartButton ✓
- SavePanel (5×SlotButton) ✓
- ContinueButton / MenuStatusLabel ✓

## 验证结果

```
StartMenuSceneTest      22 PASS  (+4 node existence checks)
SmokeTestRunner         33 PASS
IntegrationTestRunner  133 PASS
LayoutSanityTestRunner 330 PASS
合计                   518 PASS
```

## 后续 .tscn 迁移模式

每个 UI 组件按此模式迁移：

```
.tscn    → 节点结构、布局、外观
.gd      → 逻辑、信号、数据刷新
Main.gd  → 只创建/切换/协调
测试     → 场景加载 + 关键节点 + 接口不变
README   → 告诉人在哪里改
```

已有完整示例：`scenes/ui/StartMenu.tscn` + `scripts/StartMenu.gd`。

## Visual parity follow-up (v2.0.7.1)

- Fixed `ChamberPreview` double-offset: `.tscn` position (420,260) + code `MenuDecor` position (420,260) = (840,520). Changed ChamberPreview to (0,0).
- Fixed `PanelBg` size: 832×662 → 824×654 (matching legacy `panel.size - 16`).
- Verified StartMenu.tscn contains **34 static nodes**, covering all 23 visual elements from StartMenuView.gd.
- Confirmed Remote tree `@ColorRect@2` comes from `Main.gd:124` unnamed background ColorRect, now named `MainBackground`.
- Added `layout_mode = 0` + `clip_contents = true` to RootPanel; `layout_mode = 0` to SaveSlotContainer.
- All node positions verified against old StartMenuView.gd: 21/25 exact match, 4 minor (1-2px label auto-height, SpinBox auto-width).

## v2.0.7.2 Manual-Edit Safety

- **Source of truth is the local file**: `scenes/ui/StartMenu.tscn`
- **Do not edit Remote runtime nodes** in the Godot Remote tree when your goal is to persist layout changes
- Remote nodes are only live instances created after `Main.gd` runs `load -> instantiate -> setup()`
- Persistent layout edits must be made in the Scene editor on the local `StartMenu.tscn` resource

### Runtime ownership boundaries

- `setup()`
  - initializes selected values on the owner
  - calls `_init_options()`, `_init_decor()`, `_refresh_slots()`, `_connect_signals()`
  - **does not modify** `ConfigPanel`, `ModeTip`, `StartButton`, or `ChamberPreview` transform
- `_init_options()`
  - only fills `OptionButton` items and selected state
  - **does not modify** position / size / scale
- `_init_decor()`
  - only mounts `PreviewScene.tscn` under `ChamberPreview`
  - preview instance is reset to local `Vector2.ZERO` / `Vector2.ONE`
  - **does not modify** the `ChamberPreview` container transform from `.tscn`
- `_refresh_slots()`
  - only updates text / tooltip / disabled / self_modulate
  - **does not modify** position / size / scale

### What `.tscn` controls vs runtime code

| Node / property | Controlled by `.tscn` | Runtime override |
|---|---|---|
| `ConfigPanel` position / size | yes | none |
| `ModeTip` position / size / font size | yes | none |
| `StartButton` position / size / theme | yes | text only remains static, no transform override |
| `ChamberPreview` position / scale | yes | container transform not overridden |
| `ContinueButton` position / size / theme | yes | text + disabled |
| `SlotButton_*` position / size / theme | yes | text + tooltip + self_modulate |
| `MenuStatusLabel` position / size / theme | yes | text |
| `OptionButton` position / size / theme | yes | items + selected |

### Regeneration guard

- `scripts/tools/build_start_menu_scene.gd` is now guarded by `ALLOW_OVERWRITE_START_MENU_TSCN = false`
- Running the script now aborts by default instead of overwriting your manual scene edits
- To regenerate from scratch, you must **intentionally edit the script** and flip that constant to `true`
