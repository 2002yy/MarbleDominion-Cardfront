# BallWar v2.1.5 - Event Log & Menu Preferences

Date: 2026-05-15 (estimated)
Scope: event explanation layer + start menu remembers last selection

## Version Boundary

`v2.1.5` is defined as:

- event log / explanation layer added to HUD (no gameplay change)
- mode + effect descriptions accessible in-event
- start menu persists last user selections across sessions
- "恢复默认" button to reset to factory defaults
- layout coordinator extended with `event_log_rect`

In short:

`v2.1.5 = 事件转盘解释层 + 菜单记忆上次选择`

## Goal

Two separate UX improvements that share zero runtime gameplay risk:

1. Players cannot understand why events fired → add an
   explanation layer (event log, mode/effect descriptions).
2. Returning to menu resets all selections to hardcoded
   defaults → persist last choices to `user://menu_preferences.json`.

## What Was Added

- Event history in `EventRouletteController.gd`
- `event_log_label` (RichTextLabel) in `GameHUD.gd` + `GameHudView.gd`
- `event_log_rect` in `LayoutCoordinator.gd`
- `_load_menu_preferences()` / `_save_menu_preferences()` in `Main.gd`
- `_sync_options_from_owner()` in `StartMenu.gd` + `StartMenuView.gd`
- "恢复默认" button in both menu implementations

## Event Log / 事件解释层

### EventRouletteController

New static helpers (`EventRouletteController.gd:21`):

- `effect_description(effect_name)` — explains each of 6 effects in plain Chinese:
  - `bonus_10`: "待发射球数 +10"
  - `x2`: "待发射球数 ×2（翻倍）"
  - `x3`: "待发射球数 ×3（三倍）"
  - `add_ball`: "控制仓增加 1 个控制球"
  - `jam`: "控制仓短路 5 秒，无法发射"
  - `reroll`: "重新抽取事件效果"

- `mode_description(mode_name)` — explains each of 4 game modes:
  - basic: "基础模式：消灭所有对手炮台即获胜"
  - occupation: "占领模式：控制 75% 以上领土即获胜"
  - timed: "限时模式：倒计时结束后领地最多方获胜"
  - wild: "狂野模式：全局 ×3 倍率，事件更频繁"

- `generate_log_text(payload, game_time)` — produces timestamped log line:
  `[02:31] 蓝方  待发射球数 ×2（翻倍）`

### event_history Array

- `event_history: Array[Dictionary]` — capped at `MAX_EVENT_HISTORY` (24 entries)
- mode description pushed as italic header entry on `reset_for_new_game()`
- each `_finish_event_round()` pushes a timestamped entry
- `get_event_log_text(max_entries)` — returns BBCode-formatted log for HUD display
- `export_save_state()` / `import_save_state()` — history survives save/load

### HUD Integration

- `GameHUD.gd:256` — `_try_attach_event_log()` creates `event_log_label` (RichTextLabel)
  if the scene does not already provide one; `update_event_log(text)` refreshes its content
- `GameHudView.gd:291` — same label created programmatically in code-generated HUD fallback
- Position: right side, between top panel bottom (~106px) and side buttons, 290px wide × 230px tall
- Font: 13px desktop / 11px mobile, warm white with dark shadow

### Signal Wiring

- `Main.gd:296` — `event_round_finished` signal connected to `_on_event_round_finished`
- `_on_event_round_finished` reads `get_event_log_text(8)` from controller and pushes to HUD label

### LayoutCoordinator

- `event_log_rect` added to `hud_positions` output (`LayoutCoordinator.gd:198`)
- Constants: `EVENT_LOG_WIDTH = 290.0`, `EVENT_LOG_MAX_HEIGHT = 230.0`

## Menu Preferences / 菜单记忆上次选择

### Persistence

- File: `user://menu_preferences.json`
- Stored fields: `grid_size`, `palette_name`, `quality_name`, `game_mode_name`,
  `time_limit_minutes`, `save_slot`
- Writes every time any menu option changes (grid/mode/quality/time/palette/slot)
- Validates all values against known lists on load (`_sanitize_pref_*` helpers)

### StartMenu / StartMenuView Changes

- `setup()` / `create()`: no longer hard-reset `selected_*` to defaults
- Only normalizes `selected_save_slot` with `clampi` and `selected_grid_size` with `LayoutProfiles.sanitize_grid_size`
- `_sync_options_from_owner()`: selects the correct OptionButton index for each
  widget based on the owner's current `selected_*` values
- `_try_add_reset_button()`: adds "恢复默认" button to config panel (only once)
- `_on_reset_pressed()`: resets all `selected_*` to factory defaults and calls
  `_save_menu_preferences()`

### Selection Callbacks

All callbacks (`_on_size_option_selected`, `_on_mode_option_selected`,
`_on_quality_option_selected`, `_on_time_spin_changed`, `_on_palette_option_selected`)
now call `owner._save_menu_preferences()` immediately after setting the value.

### Start Button

Both `_on_start_pressed()` (StartMenu.gd) and the start button callback
(StartMenuView.gd) call `_save_menu_preferences()` before `_start_game()`.

## Files Changed

| File | Change |
|---|---|
| `scripts/EventRouletteController.gd` | Added `event_history`, `effect_description`, `mode_description`, `generate_log_text`, `get_event_log_text`; updated `export_save_state`/`import_save_state` |
| `scripts/GameHUD.gd` | Added `event_log_label`, `_try_attach_event_log()`, `update_event_log()` |
| `scripts/GameHudView.gd` | Added `event_log_label` in `create_runtime_ui()`, included in return dict |
| `scripts/LayoutCoordinator.gd` | Added `EVENT_LOG_*` constants, `event_log_rect` in `hud_positions` |
| `scripts/StartMenu.gd` | Removed hardcoded defaults from `setup()`, added `_sync_options_from_owner()`, `_try_add_reset_button()`, `_on_reset_pressed()`; selection callbacks now save prefs |
| `scripts/StartMenuView.gd` | Same as StartMenu.gd for code-generated path |
| `scripts/Main.gd` | Added `MENU_PREF_PATH`, `_load_menu_preferences()`, `_save_menu_preferences()`, `reset_menu_preferences()`, `_sanitize_pref_*()`, `_on_event_round_finished()`; wired `event_round_finished` signal |

## Tests

All existing tests remain green:

| Test Runner | Checks |
|---|---|
| SmokeTestRunner | PASS 60 |
| SaveFlowControllerTestRunner | PASS 84 |
| IntegrationTestRunner | PASS 133 |
| LayoutSanityTestRunner | PASS 376 |
| GameHUDSceneTestRunner | PASS 28 |
| StartMenuSceneTestRunner | PASS 37 |
