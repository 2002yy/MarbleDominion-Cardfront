# BallWar v2.1.8 — Decor Layer Event-Driven & ChamberState Extraction

Date: 2026-05-15 (estimated)
Scope: BattlefieldDecorLayer polling→event, ControlChamber state extraction, StartMenu layout polish

## Version Boundary

`v2.1.8` is defined as:

- `BattlefieldDecorLayer` converted from per-frame polling to event/dirty-flag pattern
- `ChamberState.gd` created as pure state container (RefCounted), extracted from `ControlChamber.gd`
- `ControlChamber.gd` delegates state mutations to `chamber_state` with shadow-field bridge
- `StartMenu` layout final polish: PreviewScene clipping, panel centering, compact labels
- Save format and external APIs fully preserved

In short:

`v2.1.8 = DecorLayer 事件化 + ChamberState 状态外提 + StartMenu 布局定型`

## BattlefieldDecorLayer — Polling → Event-Driven

### Files Changed

| File | Change |
|---|---|
| `scripts/BattlefieldDecorLayer.gd` | Added `_decor_dirty`, `_cached_grid_line_alpha`, `_cached_emblem_alpha_mul`, `mark_dirty()`, `apply_visual_settings()`. Removed `update_style()`. |
| `scripts/Battlefield.gd` | Removed `_sync_decor_layer()` from `_process()`. `configure()`/`apply_quality_style()`/`_ready()` now call `decor_layer.configure()` + `decor_layer.apply_visual_settings()` directly. Added `mark_decor_dirty()`. Removed `decor_grid_alpha`/`decor_emblem_alpha_mul` shadow caches. Fixed missing `const` declarations (tab conversion artifact). |

### Before

```
_process() → _sync_decor_layer() every frame → reads GameConfig → checks cache → maybe queue_redraw
```

### After

```
configure(grid_size) → decor_layer.configure() + decor_layer.apply_visual_settings()
apply_quality_style() → decor_layer.apply_visual_settings()
mark_decor_dirty() → decor_layer.mark_dirty()
```

`apply_visual_settings()` internally reads `GameConfig.get_grid_line_alpha()` and
`GameConfig.get_emblem_alpha_mul()`, compares against cached values, and only
triggers `queue_redraw()` when values actually changed or dirty flag is set.

## ChamberState.gd — State Extraction from ControlChamber

### New File

`scripts/ChamberState.gd` — extends `RefCounted`, not `Node`. Manages pure data
and rules with no scene tree, rendering, or signal dependencies.

### State Fields

| Field | Type | Default |
|---|---|---|
| `pending_count` | int | 1 |
| `is_locked` | bool | false |
| `locked_remaining` | int | 0 |
| `jammed_time_left` | float | 0.0 |
| `queued_round_modifiers` | Array | [] |

### Methods

| Method | Purpose |
|---|---|
| `reset(initial_pending)` | Reset to clean state |
| `is_jammed() -> bool` | Jam check |
| `tick(delta) -> bool` | Jam countdown, returns true if changed |
| `apply_pending_bonus(amount, max) -> int` | Returns amount actually added |
| `apply_pending_multiplier(mult, max) -> int` | Returns new pending_count |
| `queue_next_round_modifier(mod)` | Append queued modifier dict |
| `apply_queued_modifiers(max)` | Apply bonus_10/x2/x3 from queue |
| `apply_jam(duration)` | Set jam timer |
| `lock(count)` / `unlock(next_pending)` | Lock/unlock state transitions |
| `export_save_state() -> Dictionary` | Export for serialization |
| `import_save_state(data)` | Import from serialized data |

### ControlChamber.gd Integration

`ControlChamber.gd` adds:
```gdscript
var chamber_state: ChamberState = ChamberState.new()
```

Two sync helpers bridge the old shadow fields:
- `_sync_shadow_fields()` — copies `chamber_state.*` → local `pending_count`, `is_locked`, etc.
- `_sync_state_from_shadow()` — copies local fields → `chamber_state.*` (for external setters)

All state-mutating methods delegate to `chamber_state`:

| ControlChamber method | Now calls |
|---|---|
| `apply_pending_bonus()` | `chamber_state.apply_pending_bonus()` |
| `apply_pending_multiplier()` | `chamber_state.apply_pending_multiplier()` |
| `apply_jammed()` | `chamber_state.apply_jam()` |
| `queue_next_round_modifier()` | `chamber_state.queue_next_round_modifier()` |
| `_apply_queued_round_modifiers()` | `chamber_state.apply_queued_modifiers()` |
| `cancel_current_burst_with_refund()` | `chamber_state.unlock()` |
| `set_locked()` | `chamber_state.unlock()` + `apply_queued_modifiers()` |
| `set_damaged()` | `chamber_state.reset(0)` |
| `restore_from_state()` | Reads/writes through `chamber_state.*` then `_sync_shadow_fields()` |
| `_process()` jam tick | `chamber_state.tick(delta)` |

**Save format is preserved.** `restore_from_state()` reads old keys
(`chamber_pending_count`, `chamber_is_locked`, `chamber_locked_remaining`,
`chamber_jammed_time_left`) and maps them to `chamber_state.*`.
`SaveStateBuilder` continues to read the shadow fields (`pending_count`,
`is_locked`, etc.) unchanged.

## StartMenu Layout Polish (continued from v2.1.7)

- `PreviewContainer` now has `clip_contents = true`; `ChamberPreview` centered with layout-driven position/scale
- `RootPanel` height 650 (desktop) / 640 (mobile), vertically centered
- Child heights compressed: ConfigPanel 126, SavePanel 136, ContinueButton 36
- `MainVBox.separation = 4`
- Slot labels shortened: "基础模式"→"基础", format "槽3｜基础｜20×20｜中"
- `StartButton` text: "新局覆盖槽N" (refreshes on slot selection)
- `Shade` alpha 0.72→0.88

## Tests

| Test Runner | Checks | Status |
|---|---|---|
| SmokeTestRunner | 127 | PASS |
| EndToEndContinueMainTestRunner | 55 | PASS |
| IntegrationTestRunner | 133 | PASS |
| LayoutSanityTestRunner | 376 | PASS |
| GameHUDSceneTestRunner | 40 | PASS |
| StartMenuSceneTestRunner | 52 | PASS |
| SaveFlowControllerTestRunner | 84 | PASS |

**Total: 867 checks across 7 test suites.**
