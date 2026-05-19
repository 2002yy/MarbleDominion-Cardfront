# v0.1.2-region-morale

Date: 2026-05-19

This slice adds the bottom-layer Cardfront morale system. It only changes ownership inside one target `region_id`; it does not add card UI, units, AI Commander behavior, deployment rules, or frontline fortification.

## Goal

Create a deterministic morale-effect engine that can apply small region-local ownership shifts. This gives later cards and systems a safe foundation without coupling morale to bullets, economy storage, or global map randomness.

## Implemented

- Added `scripts/cardfront/morale/RegionMoraleRules.gd`:
  - `SUPPORT_PLAYER`
  - `UNREST_ENEMY`
  - `DEFAULT_POINTS = 5`
  - `TICK_INTERVAL = 1.0`
- Added `scripts/cardfront/morale/RegionMoraleSystem.gd`:
  - Node-based tick system
  - `setup(region_map, battlefield)`
  - deterministic `RandomNumberGenerator` with `set_seed(seed)`
  - `apply_morale(region_id, source_owner, mode, points)`
  - `tick_once()` and `_process(delta)`
  - `morale_tick(...)` and `morale_finished(...)` signals
- Wired `CardfrontMode.create_morale(...)` and `Main._create_cardfront_morale()`.
- Added `runtime.morale_system`.
- Added `scripts/tests/RegionMoraleTestRunner.gd`.

## Rules

- `SUPPORT_PLAYER`:
  - first picks neutral cells inside the target region and converts one to player ownership
  - if no neutral cell exists, picks an AI cell inside the target region and converts one to neutral
- `UNREST_ENEMY`:
  - picks an AI cell inside the target region and converts one to neutral
- Candidate cells come only from `region_map.get_region_cells(region_id)`.
- Owner mutation goes through `Battlefield.apply_bullet(...)`.
- If no candidate exists, the effect finishes cleanly without errors.

## Boundaries

- No card UI yet.
- No card data or card effects yet.
- No unit or device system yet.
- No AI Commander behavior yet.
- No deployment rules yet.
- No frontline fortification layer yet.
- No changes to `Bullet`, `BulletPool`, `Turret`, or `ControlChamber`.
- No direct changes to `RegionMap` identity or type data.

## Validation

Run after this slice:

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMoraleTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EconomyTickTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMapTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/NeutralOwnerCompatibilityTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

## Next Slice

`v0.1.3-deployment-rules` should define deployment permission by owned region, owned border, and region control degree. Cards, units, AI, and fortification still wait.
