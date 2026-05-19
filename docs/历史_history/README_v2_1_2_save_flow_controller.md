# BallWar v2.1.2 - SaveFlowController First Cut

Date: 2026-05-06
Scope: low-risk save/load orchestration split only

## Version Boundary

`v2.1.2` is defined as:

- SaveFlowController first-stage split
- save-side responsibilities
- continue-game pre-start preparation
- **does not enter restore-chain application**

In short:

`v2.1.2 = 保存端 + 继续游戏前置准备，不进入恢复链落地。`

## Goal

This phase did not change gameplay and did not yet split the deep restore chain.

It focused on moving low-risk save/load orchestration out of `Main.gd` and into
`SaveFlowController.gd`, while keeping the actual runtime object restore flow
in place.

## What Was Added

- `scripts/SaveFlowController.gd`
- `scripts/tests/SaveFlowControllerTestRunner.gd`
- `TECHNICAL_GUIDE.md`

## What SaveFlowController Owns Now

### Save-side

- save path generation
- slot normalization
- save existence check
- save slot summaries
- slot selection status text
- menu slot button refresh
- save write orchestration

### Read-side, low-risk only

- raw file load
- legacy slot-1 fallback
- JSON parse
- continue payload preparation
  - unsupported version rejection
  - `SaveGameCodec.validate_save_data(...)`
  - required `grid_size` check

### Continue pre-start planning

- runtime normalization
- `GameConfig` apply helper
- start values helper
  - `grid_size`
  - `game_elapsed_time`
- selection-state helper
  - `selected_palette_name`
  - `selected_quality_name`
  - `selected_game_mode_name`
  - `selected_time_limit_minutes`
- banner config helper
- `prepare_continue_start_plan(...)`
- `_continue_from_prepared_payload(prepared)` support boundary

## Main.gd Status After This Phase

`Main.gd` is thinner, but still remains the top-level coordinator.

The effective continue flow now looks like:

```text
_continue_saved_game()
  -> SaveFlowController.prepare_continue_payload(...)
  -> _continue_from_prepared_payload(prepared)

_continue_from_prepared_payload(prepared)
  -> SaveFlowController.prepare_continue_start_plan(...)
  -> SaveFlowController.apply_continue_selection_state(...)
  -> _start_game(...)
  -> _sync_chamber_game_elapsed_time()
  -> _apply_saved_state(...)
  -> _show_center_banner(...)
```

Important note:
- old in-function continue code still exists below new early returns as fallback
  substrate / historical scaffold
- current real execution path is the new helper-driven path above

## What Was Intentionally Not Split

This phase explicitly did **not** move:

- `_apply_saved_state()`
- `_restore_bullet_states()`
- `_process_pending_bullet_restore()`
- `_apply_chamber_state()`
- `_apply_turret_state()`
- `SaveStateApplier` deep runtime restore sequencing
- `SaveGameCodec` compatibility policy

These belong to the restore chain, not to `SaveFlowController` first cut.

These remain next-phase targets because they are order-sensitive and higher risk.

## Why This Boundary Is Good

This phase creates a clearer long-term split:

- `SaveFlowController`
  - save/read orchestration
  - continue pre-start preparation
- `Main.gd`
  - top-level entry
  - scene start
  - handoff into restore application
- `SaveStateApplier`
  - actual runtime object restoration

That means later work can target the restore chain separately without mixing it
with disk IO, slot UI, version checks, or pre-start config recovery.

## Tests Added / Updated

- `scripts/tests/SaveFlowControllerTestRunner.gd`

Current coverage includes:

- `get_save_path()`
- `normalize_slot()`
- `has_save_file()`
- `load_saved_data()`
- `prepare_continue_payload()`
- `build_continue_runtime_state()`
- `apply_continue_selection_state()`
- `apply_continue_game_config()`
- `build_continue_start_values()`
- `prepare_continue_start_plan()`
- `build_save_slot_summaries()`
- `build_slot_selection_status()`
- `refresh_menu_slot_ui()`
- `write_game_progress()`

## Local Baseline

User-verified local Godot runs passed during this phase:

- `SaveFlowControllerTestRunner.gd`
- `SmokeTestRunner.gd`
- `IntegrationTestRunner.gd`
- `StartMenuSceneTestRunner.gd`

Other previously established scene/state/layout baselines also remained green.

## Recommended Next Step

Do not jump straight into deep restore mutation yet.

Best next move:

1. freeze `SaveFlowController` first-cut boundary
2. document that continue pre-start orchestration is now split
3. start the next audit/split around:
   - `_apply_saved_state()`
   - `_restore_bullet_states()`
   - `_process_pending_bullet_restore()`
4. prefer a dedicated restore coordinator or a stronger `SaveStateApplier`
   boundary over pushing more deep restore code into `Main.gd`
