# BallWar v2.1.3 - Restore Chain Audit

Date: 2026-05-06
Scope: audit only, no logic changes

## Goal

This document audits the current restore chain after the `v2.1.2`
`SaveFlowController` first cut.

It focuses on the runtime restore path, not the already-split save-side or
continue pre-start preparation.

## Files Audited

- `scripts/Main.gd`
  - `_continue_from_prepared_payload(prepared)`
  - `_apply_saved_state()`
  - `_restore_bullet_states()`
  - `_process_pending_bullet_restore()`
  - `_apply_chamber_state()`
  - `_apply_turret_state()`
- `scripts/SaveStateApplier.gd`
- `scripts/SaveGameCodec.gd`
- `scripts/SaveStateBuilder.gd`
- `scripts/ControlChamber.gd`
- `scripts/Turret.gd`
- `scripts/Battlefield.gd`
- `scripts/EventRouletteController.gd`

## Current Restore Chain Overview

Current effective continue flow is:

```text
_continue_saved_game()
  -> SaveFlowController.prepare_continue_payload(...)
  -> _continue_from_prepared_payload(prepared)
     -> SaveFlowController.prepare_continue_start_plan(...)
     -> SaveFlowController.apply_continue_selection_state(...)
     -> _start_game(...)
     -> _sync_chamber_game_elapsed_time()
     -> _apply_saved_state(clean_data)
        -> SaveStateApplier.apply_owners(...)
        -> SaveStateApplier.apply_factions(...)
           -> _apply_chamber_state(...)
           -> _apply_turret_state(...)
        -> SaveStateApplier.apply_event_state(...)
        -> _restore_bullet_states(...)
        -> SaveStateApplier.apply_game_over_state(...)
        -> if game over: _stop_all_actions_for_game_over()
     -> _show_center_banner(...)
```

Important consequence:

- `SaveFlowController` now owns pre-start orchestration
- the actual restore chain still begins at `Main.gd::_apply_saved_state()`
- `Main.gd` still owns deep runtime sequencing

## 1. Where Does The Restore Chain Start?

Strictly speaking, the restore chain starts at:

- `Main.gd::_continue_from_prepared_payload(prepared)`

That is the point where:

- scene start has already been prepared
- selected config has already been restored
- `clean_data` is ready
- runtime object restore begins next

The deep restore boundary itself begins at:

- `Main.gd::_apply_saved_state(data)`

So there are two useful boundaries:

- restore orchestration start: `_continue_from_prepared_payload(prepared)`
- restore application start: `_apply_saved_state(data)`

## 2. When Is Clean Save Data Generated?

Clean save data is generated before restore begins.

Current path:

1. `SaveFlowController.load_saved_data(...)`
2. `SaveFlowController.prepare_continue_payload(...)`
3. `SaveGameCodec.is_supported_save_version(...)`
4. `SaveGameCodec.validate_save_data(raw_data)`

`SaveGameCodec.validate_save_data(...)` is the only central cleaning step.

It currently normalizes:

- `grid_size`
- `quality_name`
- `game_mode_name`
- `time_limit_minutes`
- `owners`
- `bullets`
- `event_state`
- `factions`
- queued modifiers
- capped control-ball arrays

This means the restore chain should assume its input is already:

- version-checked
- shape-checked
- clamped
- defaulted

## 3. When Are `selected_*` / `GameConfig` Written Back?

This now happens before runtime restore.

Current path:

1. `SaveFlowController.prepare_continue_start_plan(...)`
2. `SaveFlowController.apply_continue_selection_state(selection_state, self)`
3. `_start_game(...)`

`GameConfig` is also updated before restore through:

- `SaveFlowController.apply_continue_game_config(...)`

Important timing:

- by the time `_apply_saved_state(data)` runs, `selected_*` and `GameConfig`
  are already aligned with the save
- restore-chain code does not need to decide palette / quality / mode / timed
  settings itself

## 4. When Are Battlefield Owners Restored?

Battlefield owners are restored first inside `_apply_saved_state(data)`.

Current call:

- `SaveStateApplier.apply_owners(battlefield, data, Callable(self, "_on_scores_changed"))`

What this does:

- reads `owners`
- validates against `battlefield.grid_size`
- replaces `battlefield.owners`
- rebuilds owner counts
- flushes visual update or queues redraw
- emits refreshed score state via callback

Why the order matters:

- battlefield state is foundational
- later restored bullets and restored UI state assume map ownership is already
  correct

## 5. When Is Chamber State Restored?

Chamber state is restored during:

- `SaveStateApplier.apply_factions(...)`

but the heavy mutation still happens in:

- `Main.gd::_apply_chamber_state(chamber, state)`

Current chamber restore includes:

- clearing existing control balls
- clearing stuck states
- clearing `release_ball`
- resetting damage / lock base state
- restoring:
  - `pending_count`
  - `locked_remaining`
  - `jammed_time_left`
  - `queued_round_modifiers`
- recreating `ControlBall` nodes from saved per-ball state
- fallback ball-count restore when detailed ball state is absent
- restoring release-ball index
- restoring final locked state

Important dependency:

- this function is tightly coupled to `ControlChamber` internals:
  - `balls`
  - `release_ball`
  - `_reset_stuck_state`
  - `set_ball_stay_time`
  - `set_locked`
  - `set_damaged`
  - jam/queue semantics

This is why it is not a good first split target.

## 6. When Are Turret Health / Destroyed State Restored?

Turret state is restored in the same faction phase:

- `SaveStateApplier.apply_factions(...)`
  -> `Main.gd::_apply_turret_state(turret, state)`

Current turret restore includes:

- `health`
- `is_destroyed`
- destroy animation reset
- `sweep_phase`
- `rotation`
- `burst_remaining`
- `burst_total`
- `burst_index`
- `burst_timer`
- `burst_locked`

Important dependency:

- `Turret.gd` runtime behavior is heavily intertwined:
  - burst lifecycle
  - destruction lifecycle
  - emitted lock/progress/destroy signals
  - visible rotation/sweep state

That makes `_apply_turret_state()` another high-risk node-adjacent function.

## 7. When Is `event_controller` State Restored?

Event state is restored after owners/factions and before bullets.

Current call:

- `SaveStateApplier.apply_event_state(event_roulette_controller, data)`

This delegates to:

- `EventRouletteController.import_save_state(data["event_state"])`

Current imported fields include:

- `event_roulette_enabled`
- `next_event_time_left`
- `current_event_interval`
- `last_event_faction`
- `last_event_effect`
- `reroll_count`

Important timing:

- `event_roulette_controller` must already exist
- that means `_start_game(...)` must already have completed scene creation

## 8. Why Is There A Pending Bullet Restore Queue?

Bullets are intentionally restored in two phases:

1. `_restore_bullet_states(...)`
   - clears active bullets
   - clears old pending queue
   - caps total restore count
   - pushes bullet payloads into `pending_restore_bullets`
2. `_process_pending_bullet_restore()`
   - restores a limited batch each frame

This queue exists to avoid:

- a one-frame object allocation spike
- a large one-frame trail restore spike
- resume hitching on dense saves
- pool/fallback spawn thrash

So the queue is a performance-safety design, not accidental complexity.

## 9. What Does `_process_pending_bullet_restore()` Depend On?

It depends on runtime scene state already being valid.

Practical dependencies:

- battlefield already exists
- bullet container / pool already exists
- scene has already started
- factions/turrets/chambers are already restored enough that bullets can exist
- per-frame restore budget is available

It also depends on object-creation policy:

- use pool spawn if available
- fallback to `Bullet.new()` otherwise

And on visual/runtime state:

- position
- direction
- age
- `last_cell`
- trail points

This is why `_process_pending_bullet_restore()` should not be moved casually.

## 10. What Can Be Split, And What Should Stay Frozen For Now?

### Good split targets

These are safer next-step targets:

- a structured restore-plan object
  - `owners_data`
  - `faction_states`
  - `event_state`
  - `bullet_states`
  - `game_over_state`
- a restore-plan builder helper
- a restore-sequencing coordinator that still calls existing runtime mutators

### Not good first split targets

These should stay frozen for the first restore-chain refactor:

- `_apply_chamber_state()`
- `_apply_turret_state()`
- `_process_pending_bullet_restore()`
- `_restore_bullet_states()` worker semantics

Reason:

- they are closest to live node internals and scene timing

## Recommended First Cut For The Next Phase

The safest first restore-chain split is:

- `RestorePlan.gd`
  or
- `RestorePayload.gd`

Its job should be:

- accept already-clean save data
- split it into clearly named restore sections
- avoid changing actual restore order

Suggested structure:

```text
RestorePlan
  - owners_data
  - faction_states
  - event_state
  - bullet_states
  - game_over_state
```

Then `Main.gd` can move from:

```text
_apply_saved_state(data)
```

to:

```text
_apply_saved_state(restore_plan)
```

without immediately rewriting:

- chamber mutation
- turret mutation
- bullet queue worker

That gives a much safer seam than trying to rip node-level restore code out of
`Main.gd` all at once.

## Recommended Boundary After This Audit

### SaveFlowController

- save-side orchestration
- read/load orchestration
- continue pre-start planning

### Main.gd

- continue orchestration
- scene start
- restore sequencing

### SaveStateApplier

- current partial restore applier
- future candidate to absorb more sequencing after a restore-plan layer exists

### SaveGameCodec

- compatibility
- normalization
- defaulting/clamping

## Final Conclusion

The current architecture is now in a good intermediate state:

- pre-start orchestration has been split
- deep restore sequencing has not

That means the next step should not be "move more code into SaveFlowController".

The next step should be:

1. freeze `v2.1.2` boundary
2. use this audit as the restore-chain map
3. introduce a restore-plan layer first
4. only then start shrinking `_apply_saved_state()`
