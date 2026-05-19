# v0.1.7a-device-core

Date: 2026-05-19

This slice adds the Cardfront device core layer — placement, removal, lifetime ticking, and snapshot — without any concrete device effects.

## Goal

Build a shared `DeviceLayer` foundation that later slices (`v0.1.7b-absorber-core-lite`, `v0.1.7c-engineer-bot-lite`, `v0.1.7d-durable-pioneer-beacon`) can hang real device behaviors on. No bullet absorption, no auto-repair, no durable beacon expansion happen in this slice.

## Implemented

### Device core

- `scripts/cardfront/devices/DeviceType.gd` — absorber_core / engineer_bot / pioneer_beacon enum.
- `scripts/cardfront/devices/DeviceData.gd` — device definition: type, max_per_owner, default_lifetime, display_name.
- `scripts/cardfront/devices/DeviceInstance.gd` — runtime instance: id, type, owner_id, cell, remaining_lifetime, active.
- `scripts/cardfront/devices/DevicePlacementRequest.gd` — placement request: type, owner_id, target_cell.
- `scripts/cardfront/devices/DevicePlacementResult.gd` — result: success, reason, instance.
- `scripts/cardfront/devices/DeviceRegistry.gd` — singleton catalog with 3 device definitions and default limits.
- `scripts/cardfront/devices/DeviceLayer.gd` — Node with `place`, `remove_at`, `get_device_at`, `query`, `tick`, `snapshot`, `restore`.

### Placement rules

Uses `DeploymentRules.is_owned_cell`:
- Owned cell → placed.
- Enemy cell → rejected.
- Outside grid → rejected.
- Same cell duplicate → rejected.
- Max per owner/type enforced (absorber=3, engineer=2, beacon=2).

### Lifetime ticking

- `DeviceLayer.tick(delta)` reduces `remaining_lifetime` for each active device.
- Expired devices are auto-removed.
- Auto-disables `_process` when no devices remain.
- Tick does NOT change battlefield owners.

### Wiring

- `CardfrontMode.create_device_layer()` — assembly.
- `Main._create_cardfront_device_layer()` — game start wiring.
- `GameRuntimeContext.device_layer` — runtime reference.

### Save schema

- `scripts/cardfront/save/CardfrontRuntimeSnapshot.gd` — shape definition with fields for resource_states, used_card_ids, fortify_stacks, morale_effects, target_bias_state, devices. Full save/load wiring deferred to future.

## Boundaries

- No absorber core bullet absorption effect.
- No engineer bot auto-repair effect.
- No durable pioneer beacon expansion effect.
- No card UI, no deck management.
- No AI Commander, no card-driven device placement.
- No changes to Bullet, BulletPool, Turret, ControlChamber.

## Validation

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DeviceCoreTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontControlChamberDecouplingTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontFireDirectorTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/PioneerBeaconLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardCoreLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardFirstEffectsTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

## Next slice

`v0.1.7b-absorber-core-lite`
