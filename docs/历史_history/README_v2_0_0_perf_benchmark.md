# README v2.0.0 Perf Benchmark

## Goal

This pass upgrades the burst benchmark so it can:

- reduce cold-start pollution
- compare forward and reverse pending-order runs
- repeat each group multiple times
- approximate more realistic high-pressure gameplay scenes
- export both JSON and CSV

No gameplay rules were changed.
No event rules were changed.
No new features were added.

## Benchmark script

- `scripts/tests/PerfBurstBenchmark.gd`

Run command:

```cmd
"E:\Godot\Godot_\Godot_console.exe" --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --script "res://scripts/tests/PerfBurstBenchmark.gd"
```

## Why the old `512` result was suspicious

Earlier results showed:

- `512  -> avg_fps 36.59, min_fps 1`
- `1024 -> avg_fps 60.00, min_fps 60`
- `2048 -> avg_fps 60.00, min_fps 60`

That pattern strongly suggests the first run was polluted by startup work such as:

- cold shader/resource initialization
- first benchmark scene creation hitch
- first-sample timing contamination

This benchmark now addresses that by:

- warming up each run before measurement
- discarding the first `0.5s` after warm-up
- running both forward and reverse pending order
- repeating each group `3` times

## Timing model

- `warmup_seconds = 2.0`
- `discard_seconds = 0.5`
- `measured_seconds = 10.0`
- `repeats_per_group = 3`

## Order testing

Each case now runs both:

- `forward`
- `reverse`

Meaning pending values are tested in both normal and reversed order, which helps confirm whether a low result only happens when the first group starts cold.

## Benchmark cases

### `baseline_40_mid_single`

- `40x40`
- medium quality
- single firing turret
- pending values: `512 / 1024 / 2048`

### `stress_60_mid_single`

- `60x60`
- medium quality
- single firing turret
- pending values: `512 / 1024 / 2048`

### `stress_60_high_single`

- `60x60`
- high quality
- single firing turret
- pending values: `512 / 1024 / 2048`

### `stress_60_mid_four_turrets`

- `60x60`
- medium quality
- four turrets firing
- pending per turret: `512 / 1024`

### `stress_60_high_four_turrets`

- `60x60`
- high quality
- four turrets firing
- pending per turret: `512 / 1024`

### `dominant_faction_60_mid`

- `60x60`
- medium quality
- one dominant faction pre-painted to about `82%`
- dominant turret fires large pending bursts
- pending per turret: `1024 / 2048`

## Metrics exported

Per raw run:

- `case_name`
- `grid_size`
- `quality`
- `turret_count`
- `pending_per_turret`
- `total_pending_start`
- `order_name`
- `repeat_index`
- `warmup_seconds`
- `measured_seconds`
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
- `p95_frame_ms`
- `p99_frame_ms`
- all major average/peak pressure metrics

## Output paths

JSON:

```text
user://test_reports/perf_burst_benchmark.json
```

CSV:

```text
user://test_reports/perf_burst_benchmark.csv
```

## Console summary

Each summary group prints a compact line like:

```text
[Perf] stress_60_high_four_turrets | order=forward | pending=1024x4 | avg=42.1 | min=18 | p95=38.0ms | active=900 | queue=3800 | trail=2400 | spawn/s=80.0
```

## Supporting read-only metrics

To support benchmark reporting, lightweight read-only counters were added:

- `BulletPool.gd`
  - `recycled_bullets_per_second`
  - `expired_bullets_per_second`
- `Bullet.gd`
  - notifies the pool when a bullet expires by lifetime

These changes are instrumentation only and do not alter gameplay rules.

## Next step

Run the benchmark on the desktop machine and compare:

- forward vs reverse order
- 40x40 vs 60x60
- medium vs high quality
- single turret vs four turrets
- normal ownership vs dominant-faction ownership

That data should tell us whether the real remaining bottleneck is closer to:

- cold-start hitches
- queue pressure
- trail density
- long-lived bullets
- or battlefield redraw churn
