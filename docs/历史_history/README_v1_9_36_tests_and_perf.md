# README v1.9.36 Tests And Perf

## Goal

This pass focused on two things only:

1. Build repeatable automated tests and smoke checks.
2. Apply conservative performance protection for heavy burst / trail pressure.

No new gameplay features were added.
No event roulette rules were changed.

## New test files

Added project-root `tests/` directory:

- `tests/TestRunner.gd`
- `tests/TestAssert.gd`
- `tests/TestEventRoulette.gd`
- `tests/TestControlChamber.gd`
- `tests/TestSaveGameCodec.gd`
- `tests/TestBattlefield.gd`
- `tests/PerfBurstBenchmark.gd`
- `README_TEST_MATRIX.md`

Older `scripts/tests/SmokeTestRunner.gd` was left in place as an earlier smoke script, but the new canonical entry point is now `tests/TestRunner.gd`.

## How to run tests

Run the automated test runner:

```cmd
"E:\Godot\Godot_\Godot_console.exe" --headless --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --script res://tests/TestRunner.gd
```

Run the performance benchmark:

```cmd
"E:\Godot\Godot_\Godot_console.exe" --headless --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --script res://tests/PerfBurstBenchmark.gd
```

Benchmark output target:

```text
user://test_reports/perf_burst_benchmark.json
```

## Current test coverage

### `TestControlChamber.gd`

- pending bonus
- x2/x3 multiplier
- base-mode clamp to `2048`
- wild-mode clamp to `2187`
- locked-state queueing behavior
- add-ball event behavior
- jam state enter/exit
- jam floor bounce guard
- damaged priority over jam

### `TestEventRoulette.gd`

- six effect constants exist
- reroll stays on effect layer only
- reroll cap falls back to `bonus_10`
- positive / negative / neutral weighting behavior
- controller applies event logic without depending on a view
- locked chamber queues positive event modifiers

### `TestSaveGameCodec.gd`

- missing `event_state` defaults
- missing countdown / last-event fields defaults
- missing `chamber_jammed_time_left` default
- missing `queued_round_modifiers` default
- event fields survive validation
- queued modifiers do not duplicate across repeated validation

### `TestBattlefield.gd`

- owner count total on init
- same-color hit result
- enemy-color capture result
- score delta after capture
- 40/50/60 initialization
- visual flush / debug metric access

## Files changed for testing support

Minimal support changes were added to existing gameplay scripts:

- `scripts/ControlChamber.gd`
  - added read-only helpers:
    - `is_jammed()`
    - `get_pending_count()`
    - `get_queued_modifier_count()`
- `scripts/Battlefield.gd`
  - added `get_debug_metrics()`

These changes are test-facing only and do not change gameplay rules.

## Conservative performance optimizations

### `scripts/GameConfig.gd`

- lowered pressure thresholds so protection kicks in earlier
- lowered trail point budgets at medium/high pressure

### `scripts/BulletPool.gd`

- tracks spawned bullets per second
- tracks total queue from linked turrets
- exposes debug metrics for:
  - `spawned_bullets_per_second`
  - `trail_segments_estimate`
  - `tracked_queue_total`
- visual degradation now considers queue pressure as well as active bullet count and FPS

### `scripts/Bullet.gd`

- trail sampling interval is slower under pressure
- trail min-distance threshold is larger under pressure

### `scripts/BulletTrailLayer.gd`

- redraw interval is slower than before
- queue pressure and low FPS now force more aggressive redraw throttling
- reduced trails skip some segments / points
- exposes redraw metrics

### `scripts/Turret.gd`

- burst pacing now also considers total queue across turrets
- low FPS and high queue both reduce per-frame shot budget sooner
- total shots are preserved; only burst pacing is stretched

### `scripts/RuntimeHudController.gd`

- cleaned into a stable UTF-8 script
- performance HUD now includes compact logic indicators:
  - `spawn`
  - `cap`
  - `trail`
  - `queue`

### `scripts/Main.gd`

Minimal patch only:

- after turrets are created, `bullet_container.set_tracked_turrets(turrets)` is called if supported

This was required so the new queue-aware pressure logic can work during real gameplay.

## Initial FPS diagnosis

The earlier `FPS 4 / bullets 173 / queue 637` screenshot strongly suggests the main problem is not only active bullet count.

Likely contributors:

1. large queued burst pressure
2. trail-layer redraw cost
3. repeated bullet spawn / recycle churn
4. long-lived bouncing bullets that keep visual state alive
5. battlefield cell updates during strong territorial conversion waves

This pass mainly attacks:

- trail redraw frequency
- trail segment density
- burst pacing under queue pressure
- runtime metric visibility

## Godot checks

### Editor parse / load check

Command used:

```cmd
"E:\Godot\Godot_\Godot_console.exe" --editor --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --quit-after 5 --verbose
```

Result in Codex:

- editor-mode project scan still loads
- no new GDScript parse error surfaced during this pass
- remaining printed errors are still mostly Codex environment filesystem limitations under `AppData`

### Headless test run in Codex

Command used:

```cmd
"E:\Godot\Godot_\Godot_console.exe" --headless --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --script res://tests/TestRunner.gd
```

Result:

- Codex environment still crashes in native headless mode before test output can be trusted

Conclusion:

- `Codex headless crashes, editor can still load`
- user desktop machine should be the authoritative place to run:
  - `tests/TestRunner.gd`
  - `tests/PerfBurstBenchmark.gd`

## Still needs desktop validation

1. Run `tests/TestRunner.gd` on the desktop machine and collect PASS/FAIL output.
2. Run `tests/PerfBurstBenchmark.gd` and inspect the JSON report.
3. Compare 40x40 heavy-burst FPS before/after this pass.
4. Confirm the longer HUD string still fits comfortably in the target layout.

## Smoke test cleanup follow-up

After the first desktop smoke-test pass reported:

- `WARNING: 1 RID of type "CanvasItem" was leaked`
- `WARNING: ObjectDB instances leaked at exit`
- `ERROR: 2 resources still in use at exit`

`scripts/tests/SmokeTestRunner.gd` was tightened so that:

- nodes added to the SceneTree are always `queue_free()`-ed
- detached test nodes are `free()`-ed directly
- cleanup now waits two frames before exit
- event-controller test objects clear strong references before shutdown

The smoke-test coverage itself was kept intact; only cleanup behavior changed.
