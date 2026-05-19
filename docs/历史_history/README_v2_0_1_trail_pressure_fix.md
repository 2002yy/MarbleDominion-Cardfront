# README v2.0.1 Trail Pressure Fix

## Problem summary

Benchmark data showed a counter-intuitive result:

- `512` pending often ran worse than `1024` or `2048`
- `2048` stayed stable mainly because high-pressure protection had already collapsed trail cost

This means the main bottleneck was not queue size alone.
The more important issue was that medium pressure scenes were still allowed to keep expensive trails for too long.

## Root cause

Before this pass, trail degradation reacted strongly to:

- very high queue totals
- very low FPS
- high active bullet counts

But it reacted too late to:

- trail segment growth
- trail redraw frequency
- medium FPS drops around `45 -> 30`

That let `512`-burst scenes sit in an expensive visual band where:

- queue was not high enough to trigger strong fallback
- trail segments were already heavy
- trail redraws were still frequent

## What changed

This pass only adjusts visual degradation and read-only reporting.
It does not change:

- bullet hit logic
- bullet lifetime rules
- capture rules
- turret burst totals
- chamber logic
- event roulette rules

## New trail pressure inputs

Trail pressure now considers:

- `trail_segments_estimate`
- `trail_layer_redraws_per_second`
- `current_fps`
- existing `queue_total`
- existing `active_bullets`

### Added thresholds

- `trail_segments >= 500` -> mid pressure
- `trail_segments >= 800` -> high pressure
- `trail_segments >= 1000` -> extreme pressure
- `fps < 45` -> at least mid pressure
- `fps < 30` -> high pressure
- `fps < 20` -> extreme pressure

Additional redraw thresholds:

- `trail redraws/s >= 30` -> mid pressure
- `trail redraws/s >= 45` -> high pressure
- `trail redraws/s >= 55` -> extreme pressure

## Trail degradation policy

### Mid pressure

- fewer trail points
- redraw interval targets about `30 FPS`
- draw fewer bullet trails per pass

### High pressure

- trail budget collapses further
- redraw interval targets about `15-20 FPS`
- trail drawing is sampled more aggressively

### Extreme pressure

- only minimal trail budget remains
- redraw interval targets about `10 FPS`
- redraw requests are heavily suppressed

## New benchmark fields

`PerfBurstBenchmark.gd` now records:

- `trail_pressure_level`
- `trail_budget_active`
- `trail_degrade_reason`

Typical reasons include:

- `none`
- `fps_low`
- `trail_segments_high`
- `trail_redraw_high`
- `queue_high`
- `active_bullets_high`

## Files touched

- `scripts/GameConfig.gd`
- `scripts/BulletPool.gd`
- `scripts/BulletTrailLayer.gd`
- `scripts/tests/PerfBurstBenchmark.gd`

## Verification status

Editor parse/scan still loads without new project script parse errors.

In the Codex environment, runtime script execution is still blocked by the same Godot native crash class seen previously, so desktop verification is still required for:

- `SmokeTestRunner.gd`
- `PerfBurstBenchmark.gd`

## Desktop commands

Smoke test:

```cmd
"E:\Godot\Godot_\Godot_console.exe" --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --script "res://scripts/tests/SmokeTestRunner.gd"
```

Perf benchmark:

```cmd
"E:\Godot\Godot_\Godot_console.exe" --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --script "res://scripts/tests/PerfBurstBenchmark.gd"
```

## What to compare next

Focus on these cases first:

- `baseline_40_mid_single 512x1`
- `stress_60_mid_single 512x1`
- `stress_60_high_single 512x1`

Expected improvement targets:

- `avg_fps` closer to `50+`
- `min_fps` closer to `30+`
- `p95_frame_ms` reduced
- fewer `stutter_frames_under_30fps`
- trail segment peaks staying lower than before

## Remaining manual check

This pass intentionally sacrifices some medium-pressure trail richness earlier than before.
The next manual validation should confirm that the visual downgrade still feels acceptable during:

- `40x40`
- `60x60`
- medium quality
- high quality
- event roulette active on screen
