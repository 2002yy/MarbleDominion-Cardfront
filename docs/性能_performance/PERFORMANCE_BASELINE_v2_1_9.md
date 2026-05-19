# Performance Baseline v2.1.9

Date: 2026-05-17
Engine: Godot 4.6.2-stable (official)
Hardware: Desktop (Windows)

## Benchmark Configuration

| Parameter | Value |
|---|---|
| warmup_seconds | 2.0 |
| discard_seconds | 0.5 |
| measured_seconds | 10.0 |
| repeats_per_group | 3 |

## Test Cases

### 1. baseline_40_mid_single

- Grid: 40×40, Quality: Medium, Turrets: 1

| pending | order | avg_fps | min_fps | p95(ms) | p99(ms) | stutter<30 | stutter<15 | active(avg/pk) | queue(avg/pk) | trail(avg/pk) | spawn/s |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 512 | forward | 144.8 | 141 | 6.93 | 6.93 | 0.3 | 0.0 | 109 / 177 | 308 / 455 | 197.3 / 948 | 28.2 |
| 512 | reverse | 127.4 | 93 | 8.83 | 12.95 | 2.3 | 1.0 | 110 / 177 | 304 / 444 | 222.4 / 1019 | 28.2 |
| 1024 | forward | 144.9 | 144 | 6.90 | 6.91 | 0.0 | 0.0 | 89 / 136 | 853 / 969 | 104.2 / 363 | 23.2 |
| 1024 | reverse | 137.2 | 106 | 7.87 | 8.27 | 0.7 | 0.3 | 87 / 135 | 855 / 969 | 105.6 / 393 | 23.2 |
| 2048 | forward | 144.6 | 141 | 6.94 | 6.94 | 0.3 | 0.0 | 70 / 106 | 1904 / 2000 | 0.0 / 0 | 19.3 |
| 2048 | reverse | 144.9 | 144 | 6.94 | 6.94 | 0.0 | 0.0 | 67 / 101 | 1904 / 2000 | 0.0 / 0 | 19.3 |

Trail pressure: extreme. Degrade reason: `trail_redraw_high` (512/1024), `queue_high` (2048).

### 2. stress_60_mid_single

- Grid: 60×60, Quality: Medium, Turrets: 1

| pending | order | avg_fps | min_fps | p95(ms) | p99(ms) | stutter<30 | stutter<15 | active(avg/pk) | queue(avg/pk) | trail(avg/pk) | spawn/s |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 512 | forward | 119.2 | 71 | 12.04 | 17.90 | 3.7 | 1.3 | 94 / 127 | 306 / 444 | 171.8 / 662 | 28.3 |
| 512 | reverse | 143.1 | 127 | 7.41 | 7.86 | 0.0 | 0.0 | 93 / 119 | 303 / 443 | 181.0 / 668 | 28.3 |
| 1024 | forward | 130.2 | 116 | 8.73 | 13.84 | 2.7 | 0.3 | 75 / 108 | 854 / 969 | 96.6 / 314 | 23.2 |
| 1024 | reverse | 128.9 | 128 | 8.33 | 8.84 | 0.0 | 0.0 | 74 / 102 | 854 / 969 | 90.6 / 252 | 23.2 |
| 2048 | forward | 128.8 | 67 | 8.28 | 13.51 | 3.0 | 1.0 | 60 / 82 | 1903 / 2002 | 0.0 / 0 | 19.3 |
| 2048 | reverse | 128.2 | 126 | 8.33 | 8.33 | 0.0 | 0.0 | 59 / 81 | 1904 / 2000 | 0.0 / 0 | 19.2 |

Trail pressure: extreme. Degrade reason: `trail_redraw_high` (512), `queue_high` (1024/2048).
Note: forward runs show cold-start penalty — avg_fps ~119 vs ~143 reverse for 512 case.

### 3. stress_60_high_single

- Grid: 60×60, Quality: High, Turrets: 1

| pending | order | avg_fps | min_fps | p95(ms) | p99(ms) | stutter<30 | stutter<15 | active(avg/pk) | queue(avg/pk) | trail(avg/pk) | spawn/s |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 512 | forward | 144.3 | 128 | 6.93 | 8.80 | 0.0 | 0.0 | 96 / 139 | 305 / 444 | 185.1 / 1206 | 28.3 |
| 512 | reverse | 144.7 | 139 | 6.91 | 6.92 | 0.7 | 0.0 | 96 / 136 | 304 / 443 | 193.0 / 1230 | 28.3 |
| 1024 | forward | 144.5 | 134 | 6.93 | 6.93 | 0.7 | 0.0 | 75 / 104 | 853 / 969 | 136.5 / 465 | 23.2 |
| 1024 | reverse | 144.2 | 133 | 6.93 | 7.69 | 0.7 | 0.0 | 75 / 108 | 854 / 969 | 136.7 / 468 | 23.2 |
| 2048 | forward | 145.0 | 144 | 6.90 | 6.90 | 0.3 | 0.0 | 61 / 84 | 1904 / 2000 | 0.0 / 0 | 19.3 |
| 2048 | reverse | 144.9 | 144 | 6.94 | 6.94 | 0.0 | 0.0 | 62 / 85 | 1904 / 2000 | 0.0 / 0 | 19.2 |

Trail pressure: extreme. Degrade reason: `trail_redraw_high` (512/1024), `queue_high` (2048).
High quality single-turret stays near 144 FPS across all pending levels.

### 4. stress_60_mid_four_turrets

- Grid: 60×60, Quality: Medium, Turrets: 4

| pending | order | avg_fps | min_fps | p95(ms) | p99(ms) | stutter<30 | stutter<15 | active(avg/pk) | queue(avg/pk) | trail(avg/pk) | spawn/s |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 512 | forward | 144.8 | 143 | 6.93 | 7.08 | 0.0 | 0.0 | 244 / 286 | 1365 / 1820 | 7.5 / 701 | 91.6 |
| 512 | reverse | 144.8 | 141 | 6.93 | 6.93 | 0.3 | 0.0 | 244 / 280 | 1365 / 1820 | 7.9 / 707 | 91.6 |
| 1024 | forward | 144.6 | 133 | 6.93 | 6.93 | 0.7 | 0.0 | 222 / 256 | 3472 / 3888 | 0.0 / 0 | 83.6 |
| 1024 | reverse | 144.9 | 144 | 6.94 | 6.94 | 0.0 | 0.0 | 222 / 253 | 3472 / 3888 | 0.0 / 0 | 83.5 |

Trail budget: active for 512, inactive for 1024. All `queue_high` degrade.
Queue pressure is the primary bottleneck at 4 turrets.

### 5. stress_60_high_four_turrets

- Grid: 60×60, Quality: High, Turrets: 4

| pending | order | avg_fps | min_fps | p95(ms) | p99(ms) | stutter<30 | stutter<15 | active(avg/pk) | queue(avg/pk) | trail(avg/pk) | spawn/s |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 512 | forward | 144.8 | 141 | 6.93 | 6.93 | 0.3 | 0.0 | 243 / 270 | 1365 / 1820 | 76.2 / 727 | 91.6 |
| 512 | reverse | 120.6 | 10 | 16.71 | 39.48 | 17.7 | 4.7 | 241 / 283 | 1418 / 1860 | 70.3 / 872 | 89.5 |
| 1024 | forward | 144.8 | 141 | 6.93 | 6.93 | 0.3 | 0.0 | 220 / 258 | 3471 / 3888 | 0.0 / 0 | 83.5 |
| 1024 | reverse | 141.9 | 115 | 7.41 | 9.69 | 2.0 | 0.7 | 222 / 249 | 3468 / 3888 | 0.0 / 0 | 83.2 |

Trail budget: active for 512, inactive for 1024.
Note: reverse 512 shows high variance — worst repeat dropped to 10 FPS (extreme trail + queue pressure at high quality).

### 6. dominant_faction_60_mid

- Grid: 60×60, Quality: Medium, Turrets: 1 (dominant faction, ~82% pre-painted)

| pending | order | avg_fps | min_fps | p95(ms) | p99(ms) | stutter<30 | stutter<15 | active(avg/pk) | queue(avg/pk) | trail(avg/pk) | spawn/s |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1024 | forward | 143.0 | 103 | 7.01 | 10.34 | 2.3 | 0.0 | 64 / 126 | 852 / 969 | 75.3 / 337 | 23.2 |
| 1024 | reverse | 144.8 | 137 | 6.93 | 7.21 | 0.3 | 0.0 | 61 / 122 | 853 / 969 | 70.0 / 316 | 23.2 |
| 2048 | forward | 144.7 | 139 | 6.93 | 6.93 | 0.0 | 0.0 | 50 / 96 | 1904 / 2000 | 0.0 / 0 | 19.3 |
| 2048 | reverse | 143.8 | 124 | 7.01 | 7.63 | 1.0 | 0.0 | 44 / 94 | 1904 / 2000 | 0.0 / 0 | 19.3 |

Trail pressure: extreme. Degrade reason: `trail_redraw_high` (1024), `queue_high` (2048).

## Key Observations

1. **Single-turret at medium quality (40×60 grid)**: Generally ~144 FPS. Forward 512 reverse shows anomalous cold-start penalty (avg 119 vs 143).
2. **Single-turret at high quality (60×60)**: Maintains ~144 FPS across all pending levels. Trail segments peak at 1200+ but does not cause stutter.
3. **Four turrets at medium quality**: ~144 FPS stable. Queue builds to ~3888 at 1024×4 pending. Trail budget cuts off at 1024×4, eliminating trail rendering entirely.
4. **Four turrets at high quality, reverse 512**: Worst observed performance — avg 120.6 FPS, min 10 FPS, 17.7 stutter frames <30 FPS. High-quality trail rendering + queue pressure creates the heaviest load.
5. **Dominant faction**: Comparable to stress_60_mid_single. Pre-painted cells add no measurable overhead.
6. **Bottleneck hierarchy**: Queue pressure > trail density > active bullet count. When queue exceeds ~1800, trail budget deactivates, eliminating trail redraw cost at the expense of visual quality.

## Output Files

- `user://test_reports/perf_burst_benchmark.json` — Full raw runs + summaries
- `user://test_reports/perf_burst_benchmark.csv` — Raw data in tabular format
