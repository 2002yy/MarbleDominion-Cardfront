# README_v0_1_6_1_cardfront_fire_director

Date: 2026-05-19

Role: detailed stage record for the Cardfront fire-director slice.

## Summary / 摘要

`v0.1.6.1-cardfront-fire-director` adds a Cardfront-only automatic shooting layer. It lets Cardfront turrets keep low-frequency battlefield pressure even when no cards are being played, and it gives Calibrated Shot a real downstream consumer through target-bias-aware fire intents.

This is still a director layer, not a full combat rewrite. Bullet physics, BulletPool spawning, old BallWar control-chamber rules, formal card UI, deck flow, AI Commander, and full unit devices remain deferred.

## Added / 新增

- `scripts/cardfront/fire/CardfrontFireRules.gd`
  - central constants for interval, spread, per-second cap, and target-bias reason strings.
- `scripts/cardfront/fire/CardfrontFireIntent.gd`
  - records `owner_id`, `target_region_id`, `target_cell`, `angle`, `shot_count`, `spread`, and `reason`.
- `scripts/cardfront/fire/CardfrontTargetScorer.gd`
  - selects basic Cardfront targets from region map, battlefield ownership, region control, and resource-region priority.
- `scripts/cardfront/fire/CardfrontFireDirector.gd`
  - ticks in Cardfront mode, reads `CardfrontTargetBiasSystem`, builds fire intents, enforces a hard shot budget, and requests turret fire.
- `scripts/tests/CardfrontFireDirectorTestRunner.gd`
  - covers base intent generation, biased-region targeting, turret fire request, interval limits, shot cap, and old BallWar non-creation.

## Runtime Integration / 运行时装配

- `CardfrontMode.gd` creates and configures the fire director.
- `GameRuntimeContext.gd` stores `fire_director`.
- `Main.gd` only assembles the director for Cardfront mode; shooting policy stays outside Main.
- `Turret.gd` keeps `fire_burst(count)` and adds a minimal directed seam:
  - `request_directed_burst(intent)`
  - `fire_directed(count, angle, spread)`

## Behavior / 行为

- Cardfront mode can generate automatic low-frequency turret shots without card input.
- Target selection prefers target bias when present.
- Without target bias, scoring favors neutral frontier pressure and resource-region relevance.
- FireDirector enforces a per-second hard cap so accidental frame-rate spikes do not create unlimited shots.
- Old BallWar modes do not create `fire_director`.

## Deferred / 暂缓

- No formal card UI.
- No AI Commander.
- No deck, draw, discard, or shuffle.
- No full unit-device system.
- No Bullet or BulletPool core physics rewrite.

## Validation / 验证

Required runner for this slice:

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontFireDirectorTestRunner.gd
```

Related regression lane:

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontTargetBiasTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardFirstEffectsTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardCoreLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```
