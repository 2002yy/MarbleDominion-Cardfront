# README v2.0.2 UI Event Polish

## Scope

This pass is limited to:

- Chinese UI polish for event roulette and chamber gate labels
- event HUD layout cleanup
- extra benchmark observation fields

It does not add new gameplay.
It does not change event rules.
It does not change chamber core logic.
It does not change firing counts.

## Crash observation status

Godot native "memory cannot be read" did not reliably reproduce in this pass.

Current status:

- desktop `SmokeTestRunner` had already passed before this round
- leak warnings were already cleared before this round
- no new evidence in this pass directly ties the older read-crash to `v2.0.1` or `v2.0.2` script logic

So this pass does not attempt speculative crash fixes.

## Chinese UI restored

### Chamber gate text

- `FIRE` -> `发射`
- `JAM` -> `短路`

Gate behavior remains:

- basic / occupation / timed: `x2 + 发射`
- wild: `x3 + 发射`
- jammed: `短路`

### Event roulette text

Event names restored:

- `重转`
- `本次 +10`
- `本次 x2`
- `本次 x3`
- `加 1 球`
- `控制仓短路`

Result format restored:

- `红方：本次 x3！`
- `蓝方：加 1 球！`
- `绿方：控制仓短路 5 秒！`
- `黄方：本次 +10！`

### Event HUD

HUD now uses short Chinese text such as:

- `事件：无 | 下次 00:28`
- `事件：红方 x3 | 下次 00:21`
- `事件：蓝方短路 | 下次 00:40`

The intent is to keep it above the perf HUD line and avoid the right-side button cluster on `40 / 50 / 60`.

## Event roulette presentation

The roulette view remains presentation-only.
Result logic stays in `EventRouletteController.gd`.

Presentation target timing:

- stage drop: `0.5s`
- faction spin: `1.8s`
- faction settle: `0.4s`
- effect spin: `1.8s`
- effect settle: `0.4s`
- result hold: `2.0s`
- stage lift: `0.5s`

## Benchmark fields added

This pass extends benchmark-facing observation fields with:

- `draw_calls`
- `visible_canvas_items_estimate`
- `trail_budget_active`
- `trail_pressure_level`
- `trail_degrade_reason`

### Notes

- `draw_calls` tries to read a Godot performance monitor with safe fallback
- if the monitor is unavailable, it falls back to `-1`
- `visible_canvas_items_estimate` is explicitly a project-side estimate, not an engine-certified monitor

## Files touched

- `scripts/EventRouletteController.gd`
- `scripts/EventRouletteView.gd`
- `scripts/RuntimeHudController.gd`
- `scripts/GameHudView.gd`
- `scripts/ControlChamber.gd`
- `scripts/BulletPool.gd`
- `scripts/tests/PerfBurstBenchmark.gd`

## Verification notes

Codex-side editor parse scan completed without new script parse errors.

Codex-side runtime execution remains unreliable because the environment still shows the previously observed native instability class, so desktop verification is still required for:

- `SmokeTestRunner.gd`
- `PerfBurstBenchmark.gd`

## Manual checks still needed

- chamber gate labels are readable on `40 / 50 / 60`
- event HUD does not overlap perf HUD or add-ball buttons
- roulette panel is readable without covering too much of the battlefield
- benchmark JSON / CSV contain the new fields
