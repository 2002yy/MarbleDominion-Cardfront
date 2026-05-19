# BallWar v2.1.7 — UI Polish & Critical Fixes

Date: 2026-05-15 (estimated)
Scope: start menu container layout, leader label tie fix, chamber blur fix, event status refactor, lifecycle cleanup, asset audit

## Version Boundary

`v2.1.7` is defined as:

- start menu redesigned with container-based layout (VBox / HBox / GridContainer)
- leader label correctly shows "并列：25%" instead of fake "领先：某方"
- control chamber gate text blur reduced (scale→modulate, adaptive font, rounded positions)
- event status text unified via `_build_event_status_text()`
- save slot summaries now run full validation (empty / valid / damaged / incompatible)
- menu panel height reduced to fit content
- reset button shows state ("已是默认" vs "恢复默认")
- BOM stripped, `randomize()` deduplicated, bullet lifecycle cleaned, asset audit documented

## What Was Changed

### Start Menu Containerized Layout

| File | Change |
|---|---|
| `scenes/ui/StartMenu.tscn` | Rebuilt with VBox/HBox/GridContainer. MainVBox uses anchors (not fixed pixels). ChamberPreview wrapped in PreviewContainer (Control) for container compatibility. ResetDefaultsButton added to ConfigRow2. |
| `scripts/StartMenu.gd` | `@onready` paths updated to new TSCN tree. Added `_update_mode_tip()`, `_update_reset_button_state()`, `_is_default_config()`. Slot buttons show 3 states. |
| `scripts/StartMenuView.gd` | Fallback code generates same container structure via `_make_option_row()`. `mode_tip_label` pre-declared for closure use. |
| `scripts/LayoutCoordinator.gd` | `root_panel_size.y` 670→582. Chamber Y positions prefer profile values (`minf`/`maxf` blend). Horizontal boundary constraints prevent chamber overlap. |
| `scripts/tests/StartMenuSceneTestRunner.gd` | Updated to new node paths. 46 checks: GridContainer columns=3, 5 slot buttons all visible with reasonable width, reset button state. |

### Leader Label Tie Detection

`RuntimeHudController.update_meta` now:
- Finds all factions at max score (not just the first)
- `leaders.size() == 1` → "领先：海方 25%"
- `leaders.size() > 1` → "并列：25%"

### Control Chamber Gate Text Blur Fix

`ControlChamber.gd`:
- `count_label.scale` pulse animation replaced with `modulate` pulse
- `gate_font_size` now `17.0 / scale.x` (compensates for chamber scale 0.74–0.80)
- All `draw_string` positions truncated via `round()`

### Event Status Text Unification

`EventRouletteController.gd`:
- `_build_event_status_text()` — single entry point for all event label text
- `_build_last_event_status_text()` — "获得 x2" / "触发 短路" / "触发 重转"
- Output format: "事件：海方获得 x2｜下次事件 00:18"

### Save Slot Summary Validation

`SaveFlowController.build_save_slot_summaries` now runs:
1. `SaveGameCodec.validate_save_data()` on raw JSON
2. `is_supported_save_version()` check
3. `grid_size` presence check

Three states returned:
- `empty` — no data (dark gray button)
- `valid` — playable save (green tint, blue if selected)
- `incompatible` / `damaged` — warn (red tint, "版本不兼容" / "存档损坏")

"读取槽N" button only enabled when current slot is `is_playable`.

### Menu Preferences & Reset Button

- `_select_save_slot()` now calls `_save_menu_preferences()`
- Reset button shows "已是默认" (disabled, dim) when config matches factory defaults
- Reset button shows "恢复默认" (enabled, brighter) when config differs

### Lifecycle & State Safety

| File | Fix |
|---|---|
| `Bullet.gd` | `_ready()` no longer calls `activate()`; activation owned by `BulletPool` |
| `BulletPool.gd` | Added `prune_invalid_bullets()` to clean stale references |
| `Turret.gd` | Removed `randomize()` from `_ready()` |
| `ControlChamber.gd` | Removed `randomize()` from `_ready()`; BOM stripped |
| `SaveStateBuilder.gd` | Added `is_instance_valid()` checks for chamber/turret objects |
| `SaveGameCodec.gd` | `event_history` preserved in `validate_save_data` |
| `SaveStateApplier.gd` | Added `locked_remaining > 0` guard before auto-unlocking chambers |
| `GameConfig.gd` | Added `reset_runtime_defaults()` for test isolation |

### UI Text Polish

| File | Change |
|---|---|
| `GameHUD.gd` | `"Palette: 薄荷"` → `"配色：薄荷"` |
| `RuntimeHudController.gd` | Debug bar: `spawn→生成`, `cap→占领`, `trail→轨迹`, `draw→绘制`, `canvas→画布` |
| `SaveGameCodec.gd` | Garbled string `存档版本不兼容` restored |
| `EventRouletteController.gd` | Faction names use `GameConfig.faction_name()` for all palettes |

### EventLabel Refresh Throttle

`EventRouletteController.gd` added `EVENT_LABEL_UPDATE_INTERVAL = 0.20` and
`_update_event_label_on_interval(delta)`. The event label now refreshes at most
5 times per second instead of every frame, reducing string allocation.

### BulletTrailLayer Extreme Pressure Early Return

`BulletTrailLayer.gd` already has `get_trail_redraw_interval_extreme()` and
early return paths at extreme pressure levels, preventing trail rendering from
spiking frame time under heavy bullet loads.

### BulletPool Regular Prune

`BulletPool.prune_invalid_bullets()` removes null/invalid/inactive bullet
references from the `active_bullets` array. Not called every frame — intended
for periodic cleanup.

### Planned / Not Yet Landed

| Item | Status |
|---|---|
| BattlefieldDecorLayer event-driven sync | Not landed |
| ControlChamber split (state / physics / render) | Not landed |

### Main.gd Critical Fix

`Main.gd:214` — `game_layer.process_mode = Node.PROCESS_MODE_PAUSABLE` was merged into a garbled comment line and never executed. Restored to standalone line. This caused pause to not actually pause bullets/turrets/chambers.

### Event Log Persistence & Refresh

- `SaveGameCodec.validate_save_data()` now preserves `event_history` (capped at 24 entries)
- `_refresh_event_log()` called on game start, continue restore, and event finish
- History overflow now preserves mode header (removes oldest non-header entry)

### Asset Audit

`assets/ASSET_SOURCES_AND_LICENSES.md` section 8 documents:
- All 214 source files in `assets/` exist with licenses but are unused by code
- What's missing: audio, background music, custom theme resources
- Recommended integration order in 3 rounds

### PreviewScene Overflow Fix

- `StartMenu.tscn`: `PreviewContainer` now has `clip_contents = true`. `ChamberPreview` position set to `(402, 78)`, scale `(0.40, 0.40)`.
- `StartMenu.gd._apply_layout()`: reads `preview_local_position` and `preview_scale` from layout dict to set `chamber_preview.position` and `chamber_preview.scale`.
- `LayoutCoordinator._calculate_start_menu_layout()`: adds `preview_local_position` (desktop: `(root_panel_w/2, 78)`, mobile: `(root_panel_w/2, 74)`) and `preview_scale` (desktop: `(0.40, 0.40)`, mobile: `(0.36, 0.36)`).

### RootPanel Height & Centering

- `LayoutCoordinator`: `root_panel_size` → desktop `(840, 650)`, mobile `(792, 640)`. Panel vertically centered via `(viewport.y - panel.y) * 0.5` instead of fixed `y=22`.
- `StartMenu.tscn`: `MainVBox.separation = 4`.

### Child Area Height Compression

| Node | `custom_minimum_size.y` |
|---|---|
| ConfigPanel | 126 |
| SavePanel | 136 |
| ContinueButton | 36 |
| MenuStatusLabel | 22 |

### Short Slot Labels

`StartMenu.gd._compact_slot_title()`: "基础模式/占领模式/限时模式/狂野模式" → "基础/占领/限时/狂野". Button text format: `"槽3｜基础｜20×20｜中"`. Empty slots: `"槽4｜空"`.

### StartButton Shows "新局覆盖槽N"

`StartButton` text updates to `"新局覆盖槽%s" % slot` after slot selection. "读取槽N" button retains its original text.

### Shade Opacity

`Shade` color alpha raised from `0.72` to `0.88` to better block background distraction.

## Tests

| Test Runner | Checks | Status |
|---|---|---|
| SmokeTestRunner | 63 | PASS |
| EndToEndContinueMainTestRunner | 55 | PASS |
| SaveFlowControllerTestRunner | 84 | PASS |
| IntegrationTestRunner | 133 | PASS |
| LayoutSanityTestRunner | 376 | PASS |
| GameHUDSceneTestRunner | 40 | PASS |
| StartMenuSceneTestRunner | 52 | PASS |

**Total: 803 checks across 7 test suites.**
