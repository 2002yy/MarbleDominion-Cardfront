# v0.1.7d-durable-pioneer-beacon

Date: 2026-05-19

This slice adds the durable pioneer beacon device effect — a persistent device that periodically converts nearby neutral cells to the owner.

## Goal

Complete the v0.1.7 device tetralogy. Unlike the one-shot `PioneerBeaconLiteEffect` card, this is a device-layer effect: a placed beacon keeps converting adjacent neutral cells every tick for its entire lifetime.

## Implemented

- `scripts/cardfront/devices/effects/DurablePioneerBeaconEffectSystem.gd` — `Node` that periodically converts nearby neutral cells.
  - `setup(device_layer, battlefield, region_map)`.
  - `tick(delta)` — for each owner with active pioneer beacon devices, scans 8 neighbors for neutral cells and converts up to 1 per tick via `battlefield.apply_owner_change()`.
  - Does NOT convert enemy cells or friendly cells.
  - Does NOT modify fortify stacks.
  - Expired/inactive devices are skipped.

### Wiring

- `CardfrontMode.create_durable_pioneer_beacon_effect_system()` — assembly.
- `Main._create_cardfront_durable_pioneer_beacon_effect()` — game start wiring.
- `GameRuntimeContext.durable_pioneer_beacon_effect_system` — runtime reference.

## Boundaries

- No sprite, VFX, or animation.
- No AI-driven device placement.
- `PioneerBeaconLiteEffect.gd` (one-shot card pulse) remains unchanged.
- Old BallWar modes do not create the beacon system.

## Validation

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DurablePioneerBeaconTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/PioneerBeaconLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EngineerBotLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/AbsorberCoreLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DeviceCoreTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

## Next

Device tetralogy complete. Proceed to v0.1.8 onwards as ROADMAP directs.
