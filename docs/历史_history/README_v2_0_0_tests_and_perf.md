# README v2.0.0 Tests And Perf

## Scope

This `2.0.0` pass is limited to:

- automated smoke testing
- burst/performance benchmarking
- read-only debug/perf counters

It does not add new gameplay.
It does not change event roulette rules.
It does not change core combat rules.

## Included test scripts

- `scripts/tests/SmokeTestRunner.gd`
- `scripts/tests/PerfBurstBenchmark.gd`

## Smoke test

Run:

```cmd
"E:\Godot\Godot_\Godot_console.exe" --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --script "res://scripts/tests/SmokeTestRunner.gd"
```

Current desktop result:

```text
[SmokeTest] PASS (33 checks)
```

Also confirmed:

- no `RID leaked`
- no `ObjectDB instances leaked`
- no `resources still in use`

## Perf benchmark

Run:

```cmd
"E:\Godot\Godot_\Godot_console.exe" --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --script "res://scripts/tests/PerfBurstBenchmark.gd"
```

## Why `512` needed re-checking

Earlier benchmark output showed:

- `512  -> avg_fps 36.59, min_fps 1`
- `1024 -> avg_fps 60.00, min_fps 60`
- `2048 -> avg_fps 60.00, min_fps 60`

That shape strongly suggested the first measured group was polluted by cold-start work rather than real gameplay pressure.

The `2.0.0` benchmark therefore adds:

- per-case warm-up
- first-slice discard after warm-up
- repeated runs
- forward and reverse pending order
- larger stress cases closer to real gameplay

## Benchmark timing model

- `warmup_seconds = 2.0`
- `discard_seconds = 0.5`
- `measured_seconds = 10.0`
- `repeats_per_group = 3`

## Benchmark case matrix

- `baseline_40_mid_single`
- `stress_60_mid_single`
- `stress_60_high_single`
- `stress_60_mid_four_turrets`
- `stress_60_high_four_turrets`
- `dominant_faction_60_mid`

The original `40x40 / medium / 512 / 1024 / 2048` baseline is still preserved.

## Exported outputs

JSON:

```text
user://test_reports/perf_burst_benchmark.json
```

CSV:

```text
user://test_reports/perf_burst_benchmark.csv
```

## Key metrics

Per raw run:

- `avg_fps`
- `min_fps`
- `p95_frame_ms`
- `p99_frame_ms`
- `stutter_frames_under_30fps`
- `stutter_frames_under_15fps`
- `active_bullets_peak`
- `active_bullets_avg`
- `queue_peak`
- `queue_avg`
- `spawn_per_second`
- `capture_per_second`
- `trail_segments_peak`
- `trail_segments_avg`
- `battlefield_redraws_per_second`
- `trail_layer_redraws_per_second`
- `bullets_recycled_per_second`
- `bullets_expired_per_second`

Per summary group:

- `avg_fps_mean`
- `avg_fps_min`
- `min_fps_min`
- averaged pressure counters
- peak bullet / queue / trail counters

## Read-only instrumentation only

This pass adds lightweight reporting only.

Examples:

- `BulletPool.gd` perf counters
- `Bullet.gd` expiry reporting
- `Battlefield.gd` redraw/capture reporting
- `BulletTrailLayer.gd` redraw reporting

These are benchmark/support metrics and do not change combat behavior.

## Next step

Use the new benchmark outputs to decide whether future optimization should focus on:

- cold-start contamination
- queue pressure
- trail redraw churn
- battlefield redraw churn
- long-lived bullet pressure in dominant-faction scenes
