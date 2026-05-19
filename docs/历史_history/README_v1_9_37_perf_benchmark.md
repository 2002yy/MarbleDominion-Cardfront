# README v1.9.37 Perf Benchmark

## Goal

This pass adds a dedicated burst-performance benchmark without changing gameplay rules.

Scope:

- no new gameplay
- no event-rule changes
- no zip packaging
- no project copy

## New file

- `scripts/tests/PerfBurstBenchmark.gd`

## Run command

```cmd
"E:\Godot\Godot_\Godot_console.exe" --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --script "res://scripts/tests/PerfBurstBenchmark.gd"
```

If headless works on the desktop machine, this also matches the benchmark design:

```cmd
"E:\Godot\Godot_\Godot_console.exe" --headless --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --script "res://scripts/tests/PerfBurstBenchmark.gd"
```

## Benchmark setup

- map size: `40x40`
- quality: `medium`
- mode: `basic`
- run duration: `10 seconds` per case
- tested pending / burst sizes:
  - `512`
  - `1024`
  - `2048`

## Metrics collected

Each run records:

- `avg_fps`
- `min_fps`
- `active_bullets_peak`
- `queue_peak`
- `spawn/s`
- `capture/s`
- `trail_segments_estimate`
- `battlefield_redraws/s`
- `trail_layer_redraws/s`

## Output

JSON output path:

```text
user://test_reports/perf_burst_benchmark.json
```

Console output:

- one compact summary line per pending-count case
- final JSON path confirmation

## Notes

- The script builds a minimal benchmark scene directly and does not depend on menu/UI clicking.
- It reuses existing debug metrics already exposed by:
  - `Battlefield.gd`
  - `BulletPool.gd`
  - `BulletTrailLayer.gd`
- It does not modify `Main.gd`, `ControlChamber.gd`, or event rules for the benchmark itself.

## Expected next step

Run the benchmark on the desktop machine and compare the three cases:

- `512`
- `1024`
- `2048`

That output will tell us whether the main cost is dominated more by:

- queue growth
- trail density
- long bullet lifetime
- or battlefield redraw churn
