# v0.1.3.1-visual-pressure-rebalance

Date: 2026-05-19

This slice rebalances visual pressure judgment so that the real screen load determines degradation, not the future queue forecast alone. Both legacy BallWar and Cardfront modes are updated.

## Problem

The old `_resolve_visual_profile` mixed `active_count`, `tracked_queue_total`, `trail_segments`, `fps`, and `trail_redraws` into a single severity pipeline. Even with fewer than 10 active bullets, a high `tracked_queue_total` could push the profile to mid or high, causing bullets to lose shadows, highlights, and trails prematurely.

## Fix

Split visual pressure resolution into two mode-specific strategies:

- `_resolve_legacy_visual_profile` — for BallWar, Basic, Occupation, Timed, Wild modes
- `_resolve_cardfront_visual_profile` — for Cardfront mode

`_resolve_visual_profile(active_count)` now dispatches to the appropriate strategy based on `GameConfig.get_game_mode_name()`.

## Legacy / BallWar strategy changes

Old queue logic:

```
queue_total >= 500  → mid
queue_total >= 1000 → high
queue_total >= 1500 → extreme
```

New queue logic:

| active_count condition | queue_total threshold | max severity |
|---|---|---|
| `< 80` | queue does not participate | 0 |
| `>= 80` | `>= 1000` | 1 (mid) |
| `>= 250` | `>= 1500` | 2 (high) |
| `>= 600` | `>= 2200` | 3 (extreme) |

- Queue is now a forecast, not a current pressure signal.
- `active_count`, `trail_segments`, `fps`, and `trail_redraws` thresholds remain unchanged from GameConfig.

## Cardfront strategy

Independent thresholds (no longer use legacy BallWar thresholds):

### active_count

| active_count | min severity |
|---|---|
| `< 180` | 0 |
| `>= 220` | 1 |
| `>= 650` | 2 |
| `>= 1400` | 3 |

### trail_segments

| trail_segments | min severity |
|---|---|
| `>= 900` | 1 |
| `>= 1600` | 2 |
| `>= 2200` | 3 |

### FPS

| fps | min severity |
|---|---|
| `< 25` | 3 |
| `< 35` | 2 |
| `< 45 and active_count >= 120` | 1 |

### Queue

Queue cannot degrade alone. Only participates when `active_count >= 220`:

| active_count condition | queue_total threshold | max severity |
|---|---|---|
| `>= 220` | `>= 1500` | 1 |
| `>= 650` | `>= 2500` | 2 |

### Cardfront output mapping

| severity | simple_draw | reduce_effects | trail_points |
|---|---|---|---|
| 0 | false | false | 12 |
| 1 | false | false | 8 |
| 2 | false | true | 4 |
| 3 | true | true | 0 |

## Reason field

- Queue-triggered degrade now reports `queue_forecast` instead of `queue_high`.
- All other reason strings remain: `none`, `active_bullets_high`, `trail_segments_high`, `trail_redraw_high`, `fps_low`.

## Files changed

- `scripts/BulletPool.gd` — dispatch, legacy function, cardfront function, test helper
- `scripts/tests/CardfrontVisualPolicyTestRunner.gd` — rewritten with new cardfront tests
- `scripts/tests/VisualPressurePolicyTestRunner.gd` — new, legacy mode tests

## Boundaries

- No change to `Bullet.gd` movement or collision.
- No change to `Battlefield.apply_bullet`.
- No change to economy, morale, deployment rules, cards, or AI.
- No change to `GameConfig` global thresholds.
- `spawn_bullet()`, `recycle_bullet()`, and `_process` are untouched.

## Validation

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontVisualPolicyTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/VisualPressurePolicyTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DeploymentRulesTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMoraleTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EconomyTickTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

## Next slice

`v0.1.4-fortify-layer`
