# BallWar v2.1.9 — Settings System & Result Panel

Date: 2026-05-16 (estimated)
Scope: player settings store, settings panel rebuild, result/结算 panel, statistics tracking, decor layer refactor

## Version Boundary

`v2.1.9` is defined as:

- `PlayerSettingsStore.gd` — persistent settings file (performance/log/low-effect)
- `SettingsPanel` rebuilt with 3 working CheckButtons + close button
- `ResultPanel` — end-of-match summary screen with replay/return buttons
- `Main.gd` receives settings changes and applies toggles live
- Statistics: `peak_active_count` on BulletPool, `event_count` on EventRouletteController
- Save format adds `match_finished` flag to exclude finished games from continue
- `BattlefieldDecorLayer` converted from per-frame polling to event/dirty-flag pattern
- `ChamberState.gd` extracted from ControlChamber as pure state container

In short:

`v2.1.9 = 设置系统 + 结算页 + 统计 + DecorLayer事件化 + ChamberState提取`

## Player Settings System

### PlayerSettingsStore.gd (new)

Path: `scripts/PlayerSettingsStore.gd`

Persistence: `user://player_settings.json`

```gdscript
static func default_settings() -> Dictionary:
    return {
        "show_performance_info": OS.is_debug_build(),
        "low_effect_mode": false,
        "show_event_log": true,
    }
```

- `load_settings()` — merges saved values over defaults
- `save_settings(settings)` — writes only known keys
- `OS.is_debug_build()` — dev: perf bar shown, release: hidden by default

### SettingsPanel Rebuild

| File | Change |
|---|---|
| `scenes/ui/SettingsPanel.tscn` | Control root → MarginContainer → VBoxContainer → TitleLabel + 3 CheckButtons (PerformanceCheck / LowEffectCheck / EventLogCheck) + HintLabel + CloseButton |
| `scripts/SettingsPanel.gd` | `settings_changed` signal; reads `PlayerSettingsStore.load_settings()` on `show_panel()`; writes on every `toggled`; `_on_setting_toggled` saves + emits |

### Main.gd Wiring

```gdscript
var player_settings: Dictionary = {}
# Loaded in _ready()

func _on_player_settings_changed(settings) -> void:
    player_settings = settings.duplicate()
    _apply_performance_setting()
    _apply_event_log_setting()
    _apply_low_effect_setting()
```

| Method | Action |
|---|---|
| `_apply_performance_setting()` | `RuntimeHudController.set_performance_visible()` + HUD node visibility |
| `_apply_event_log_setting()` | `event_log_label.visible` + `event_controller.set_event_log_visible()` |
| `_apply_low_effect_setting()` | `GameConfig.set_low_effect_mode()` + `battlefield.apply_quality_style()` |

### RuntimeHudController Performance Toggle

```gdscript
static var performance_visible: bool = true

static func set_performance_visible(value: bool) -> void:
    performance_visible = value

static func get_perf_debug_text(...) -> String:
    if not performance_visible:
        return ""   # skip string building entirely
```

### EventRouletteController Event Log Toggle

```gdscript
var event_log_visible: bool = true

func set_event_log_visible(value: bool) -> void:
    event_log_visible = value
    # Event history continues recording regardless
```

## Result Panel / 结算页

### Files

| File | Status |
|---|---|
| `scenes/ui/ResultPanel.tscn` | New |
| `scripts/ResultPanel.gd` | New |

### Layout

```
ResultPanel (CanvasLayer)
 ├─ Shade (ColorRect, α=0.88)
 └─ Panel (840×560)
     └─ VBoxContainer
         ├─ TitleLabel ("海方胜利！")
         ├─ ReasonLabel ("击败全部对手")
         ├─ DurationLabel ("游戏时长：03:42")
         ├─ OccupationLabel ("最终占领率：海方 48% | 霞方 22%...")
         ├─ StatsLabel ("最高活跃子弹：126 | 触发事件：8 次")
         └─ ButtonRow
             ├─ ReplayButton ("再来一局")
             └─ ReturnMenuButton ("返回菜单")
```

### Wiring

```gdscript
signal replay_requested
signal return_menu_requested

func show_result(result: Dictionary) -> void:
    # Sets all labels from structured data
```

In `Main.gd`:
- `_check_winner()` captures `last_winner_id` + `last_win_reason`, calls `_show_match_result()`
- `_build_match_result()` assembles data from battle stats
- "再来一局": `is_game_over = false` → `_start_game(selected_grid_size)`
- "返回菜单": no save (finished game), `_cleanup_game_layer()` → `_create_start_menu()`

### Save Protection — match_finished

`SaveStateBuilder.build_save_payload()` adds `"match_finished": true` when game is over.
`SaveFlowController.build_save_slot_summaries()` reads it → `state = "finished"`, `is_playable = false`.
`StartMenu.build_slot_label()` shows `"槽3｜已结束"`.

## Statistics Tracking

| Component | New Field | Method |
|---|---|---|
| `BulletPool.gd` | `peak_active_count` | Updated every spawn; `get_peak_active_count()` / `reset_stats()` |
| `EventRouletteController.gd` | `event_count` | Incremented in `_finish_event_round()`; `get_event_count()`; reset in `reset_for_new_game()` |
| `Main.gd` | — | `_start_game()` calls `bullet_pool.reset_stats()` after subsystem creation |

## BattlefieldDecorLayer Event-Driven Refactor

| File | Change |
|---|---|
| `BattlefieldDecorLayer.gd` | Added `_decor_dirty`, caches, `mark_dirty()`, `apply_visual_settings()` (reads GameConfig directly). Removed `update_style()`. |
| `Battlefield.gd` | Removed `_sync_decor_layer()` from `_process()`. `configure()`/`apply_quality_style()`/`mark_decor_dirty()` call decor layer directly. Removed `decor_grid_alpha`/`decor_emblem_alpha_mul` caches. |

## ChamberState.gd — State Extraction

`scripts/ChamberState.gd` (new) — extends `RefCounted`, manages:
- `pending_count`, `is_locked`, `locked_remaining`, `jammed_time_left`, `queued_round_modifiers`
- Methods: `tick()`, `apply_pending_bonus()`, `apply_pending_multiplier()`, `apply_queued_modifiers()`, `apply_jam()`, `lock()/unlock()`, `export/import_save_state()`

`ControlChamber.gd` delegates all state mutations via `chamber_state` with `_sync_shadow_fields()`/`_sync_state_from_shadow()` bridge. Save format unchanged.

## GameConfig

Added `_low_effect_mode` static var + `set_low_effect_mode()` / `is_low_effect_mode()`.

## Tests

| Test Runner | Checks | Status |
|---|---|---|
| SettingsAndResultTestRunner (NEW) | 19 | PASS |
| SmokeTestRunner | 127 | PASS |
| EndToEndContinueMainTestRunner | 55 | PASS |
| IntegrationTestRunner | 133 | PASS |
| SaveFlowControllerTestRunner | 84 | PASS |
| LayoutSanityTestRunner | 376 | PASS |
| GameHUDSceneTestRunner | 40 | PASS |
| StartMenuSceneTestRunner | 52 | PASS |

**Total: 886 checks across 8 test suites.**
