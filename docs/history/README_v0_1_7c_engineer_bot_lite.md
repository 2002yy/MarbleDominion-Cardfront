# v0.1.7c-engineer-bot-lite

Date: 2026-05-19

This slice adds the engineer bot device effect — active engineer bots periodically add fortify stacks to nearby owned border cells.

## Goal

Wire the second device effect on the device core layer. An engineer bot placed on a cell scans its radius for the owner's border cells and adds one fortify stack per tick (up to MAX_FORTIFY_STACKS).

## Implemented

- `scripts/cardfront/devices/effects/EngineerBotEffectSystem.gd` — `Node` that ticks and repairs nearby border cells.
  - `setup(device_layer, fortify_layer, battlefield, region_map)`.
  - `tick(delta)` — for each owner with active engineer bots, scans cells within `REPAIR_RADIUS_CELLS=3`.
  - Reinforces only owned border cells (`DeploymentRules.is_owned_border`).
  - Skips cells already at `MAX_FORTIFY_STACKS` (3).
  - Per-tick cap: 1 cell repaired per tick across all devices.
  - Does NOT change battlefield owners.
  - Expired/inactive devices are skipped.

### Wiring

- `CardfrontMode.create_engineer_bot_effect_system()` — assembly.
- `Main._create_cardfront_engineer_bot_effect()` — game start wiring.
- `GameRuntimeContext.engineer_bot_effect_system` — runtime reference.

## Boundaries

- No sprite, VFX, or animation.
- No AI-driven device placement.
- No changes to Bullet, BulletPool, Turret, or ControlChamber.
- Old BallWar modes do not create the engineer system.

## Validation

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EngineerBotLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/AbsorberCoreLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DeviceCoreTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/FortifyLayerTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

## Next slice

`v0.1.7d-durable-pioneer-beacon`
