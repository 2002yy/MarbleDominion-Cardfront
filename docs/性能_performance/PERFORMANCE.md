# Performance / 性能

Date: 2026-05-17
Role: performance probe overview and baseline summary / 性能探针概览与基线摘要

## Probes / 探针脚本

- `PerfBurstBenchmark.gd` — full benchmark suite
- `PerfBurstBenchmarkSingleTurret.gd` — single-turret half
- `PerfBurstBenchmarkMultiTurret.gd` — multi-turret half

Output: `user://test_reports/perf_burst_benchmark.json` + `.csv`

## Baseline Summary (v2.1.9) / 基线摘要

Recorded on Godot 4.6.2, desktop (Windows).

| Scenario | Avg FPS | Bottleneck |
|---|---|---|
| 40×40 medium, 1 turret, 512 pending | ~144 | Trail redraw |
| 60×60 medium, 1 turret, 2048 pending | ~144 | Queue pressure |
| 60×60 high, 1 turret, 1024 pending | ~144 | Trail redraw |
| 60×60 medium, 4 turrets, 512 pending | ~144 | Queue pressure |
| 60×60 high, 4 turrets, 512 pending (worst) | ~120 (min 10) | Trail + queue |

### Key Findings / 主要结论

1. **Single-turret at medium quality**: Generally ~144 FPS. Forward runs show cold-start penalty in some cases.
2. **Single-turret at high quality**: Maintains ~144 FPS across all pending levels. Trail segments peak at 1200+.
3. **Four turrets at medium**: ~144 FPS stable. Queue builds to ~3888. Trail budget cuts off at 1024×4.
4. **Worst observed**: Four turrets at high quality, reverse 512 — avg 120.6, min 10 FPS, 17.7 stutter frames.
5. **Bottleneck hierarchy**: Queue pressure > trail density > active bullet count.
6. When queue exceeds ~1800, trail budget deactivates, eliminating trail redraw cost.

## Current Coverage Gaps / 当前覆盖缺口

- High-pressure barrage (all four factions firing simultaneously at full config)
- Larger grid scenarios (beyond 60×60)
- Mobile device performance data

Full baseline data: [performance/PERFORMANCE_BASELINE_v2_1_9.md](performance/PERFORMANCE_BASELINE_v2_1_9.md)
