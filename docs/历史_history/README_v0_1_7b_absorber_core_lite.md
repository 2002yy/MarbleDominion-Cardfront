# v0.1.7b-absorber-core-lite

Date: 2026-05-19

This slice adds the real bullet absorption effect for `ABSORBER_CORE` devices — enemy bullets within range are recycled and grant energy to the device owner.

## Goal

Wire the first real device effect on top of `DeviceLayer` from v0.1.7a. An absorber core placed on a cell absorbs nearby enemy bullets once per tick and rewards the owner with energy.

## Implemented

- `scripts/cardfront/devices/effects/AbsorberCoreEffectSystem.gd` — `Node` that ticks and scans active absorber devices.
  - `setup(device_layer, bullet_pool, resource_states, battlefield)`.
  - `tick(delta)` — for each owner with absorber devices, scans `bullet_pool.get_active_bullets()`.
  - Absorbs only enemy bullets (`bullet.faction_id != owner_id`).
  - Radius check: `ABSORB_RADIUS_CELLS = 3` (in cell-size units).
  - Per-tick cap: 1 bullet per device per tick.
  - Per-second hard cap: `MAX_PER_SECOND = 3` overall.
  - Absorbed bullets: `bullet_pool.recycle_bullet(bullet)` + `owner_state.add_energy(1)`.
  - Expired/inactive devices are skipped.
  - No-ops safely when systems are unavailable.

### Wiring

- `CardfrontMode.create_absorber_core_effect_system()` — assembly.
- `Main._create_cardfront_absorber_core_effect()` — game start wiring.
- `GameRuntimeContext.absorber_core_effect_system` — runtime reference.

## Boundaries

- No sprite, VFX, or animation for absorption.
- No AI-driven device placement.
- No changes to `Bullet.gd`, `BulletPool.gd`, or bullet physics.
- No engineer bot, no durable beacon.
- No card UI, no deck changes.
- Old BallWar modes do not create the absorber system.

## Validation

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/AbsorberCoreLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DeviceCoreTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontFireDirectorTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontControlChamberDecouplingTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardCoreLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardFirstEffectsTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

## Next slice

`v0.1.7c-engineer-bot-lite`
