# v2.1.1 / v2.1.2 GameStateCoordinator

Date: 2026-05-06

## Scope

This phase did not change gameplay rules.

This phase did not touch:
- `_start_game()`
- `_save_and_exit_to_menu()`
- `_continue_saved_game()`
- `_apply_saved_state()`
- `_process_pending_bullet_restore()`

This phase only extracted low-risk state-flow helpers from `Main.gd` into:
- `scripts/GameStateCoordinator.gd`

`Main.gd` still keeps the public entry functions.

## Current Stage Complete

GameStateCoordinator current stage complete:
- pause / game_over / menu_visible predicates
- pause_overlay / winner_label state helpers
- game over shutdown helper
- `_process()` lightweight predicate delegation
- `_cleanup_game_layer()` lightweight state cleanup delegation

## What Was Added

New file:
- `scripts/GameStateCoordinator.gd`

New focused test:
- `scripts/tests/GameStateCoordinatorTestRunner.gd`

Supporting docs:
- `TECHNICAL_GUIDE.md`
- `README_TEST_MATRIX.md`

## Main.gd Integration Pattern

The integration pattern is intentionally conservative:

1. Keep `Main.gd` function names and top-level entry points.
2. Delegate low-risk state decisions to `GameStateCoordinator`.
3. Leave high-risk save/load flow in place for later `SaveFlowController`.

This keeps:
- signal connections stable
- rollback easy
- tests small and local

## Delegated Helpers

Current helpers in `GameStateCoordinator.gd` cover:
- `should_ignore_pause()`
- `is_menu_visible()`
- `should_process_restore_queue()`
- `should_advance_gameplay()`
- `apply_pause_toggle()`
- `finish_with_winner()`
- `finish_as_draw()`
- `stop_actions_for_game_over()`
- `reset_pause_and_winner_state()`
- `apply_winner_label_state()`

## Main.gd Call Sites Updated

Current `Main.gd` now delegates at these points:
- `_toggle_pause()`
- `_finish_with_winner()`
- `_finish_as_draw()`
- `_stop_all_actions_for_game_over()`
- `_process()` lightweight active-state checks
- `_cleanup_game_layer()` lightweight UI/state reset

## Explicit Non-Goals

Not changed in this phase:
- event rules
- save versioning
- `.tscn` structures
- `ControlChamber` internal behavior
- `Turret` internal behavior
- `BulletPool`
- full-file formatting
- scene generator scripts

## Test Status

User-verified on local Godot runtime:
- `GameStateCoordinatorTestRunner.gd` PASS
- `SmokeTestRunner.gd` PASS
- `IntegrationTestRunner.gd` PASS
- `LayoutSanityTestRunner.gd` PASS
- `StartMenuSceneTestRunner.gd` PASS
- `GameHUDSceneTestRunner.gd` PASS
- `EventRouletteSceneTestRunner.gd` PASS
- `SettingsPanelSceneTestRunner.gd` PASS

## Next Safe Step

Continue `GameStateCoordinator` in small steps, but still avoid save flow.

Good next targets:
- return-to-menu pre-cleanup helpers
- more menu/gameover/paused state predicates
- more pause/winner/event visibility helpers

Still avoid for now:
- `_start_game()`
- `_save_and_exit_to_menu()`
- `_continue_saved_game()`
- `_apply_saved_state()`
- `_process_pending_bullet_restore()`
