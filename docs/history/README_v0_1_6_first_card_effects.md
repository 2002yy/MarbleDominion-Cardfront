# v0.1.6-first-card-effects

Date: 2026-05-19

This slice turns the two v0.1.5 stub cards into real, testable first effects while keeping Cardfront as a sidecar mode over the existing BallWar runtime.

## Goal

Deliver first card effects without adding formal card UI, draw/discard/shuffle, AI Commander behavior, generated images, or full unit-device systems.

## Implemented

### Morale Fluctuation / 民心起伏

- `CardPlaySystem.gd` now resolves `morale_fluctuation` through `_resolve_morale_fluctuation(req, card)`.
- The effect calls `RegionMoraleSystem.apply_morale(target_region_id, owner_id, SUPPORT_PLAYER)`.
- Missing morale system, invalid region id, or `apply_morale(...) == false` returns failure.
- Effect failure rolls back both resource payment and hand used state.
- `RegionMoraleSystem` core rules were not changed.

### Calibrated Shot / 校准射击

- Added `scripts/cardfront/effects/CardfrontTargetBiasSystem.gd`.
- Supports:
  - `apply_region_bias(owner_id, region_id, duration)`
  - `tick(delta)`
  - `clear(owner_id)`
  - `get_biased_region(owner_id)`
  - `get_biased_target_cell(owner_id)`
- `calibrated_shot` registers a target-region bias for the owning faction.
- v0.1.6 intentionally does not alter `Turret`, `Bullet`, `BulletPool`, or `ControlChamber`; turret aiming integration remains a later slice.

### Wiring / 装配

- `CardfrontMode.gd` creates `CardfrontTargetBiasSystem` only for Cardfront mode.
- `GameRuntimeContext.gd` owns `target_bias_system`.
- `Main.gd` remains assembly-only and passes `target_bias_system` into `CardPlaySystem`.
- Old BallWar modes do not create or depend on `CardfrontTargetBiasSystem`.

### Tests / 测试

- Added `CardFirstEffectsTestRunner.gd`.
- Added `CardfrontTargetBiasTestRunner.gd`.
- Updated `CardCoreLiteTestRunner.gd` from stub assertions to first-effect assertions.
- Updated `CardfrontModeSmokeTestRunner.gd` to assert target-bias assembly and injection.

## Boundaries

- No formal card UI.
- No deck draw, discard, shuffle, or deckbuilding.
- No AI Commander.
- No bullet absorber core, engineer robot, or full unit system.
- No AI-generated images.
- No old BallWar mode rule changes.

## Validation

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardCoreLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardFirstEffectsTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontTargetBiasTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMoraleTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/FortifyLayerTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DeploymentRulesTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EconomyTickTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

Latest local validation:

- `CardCoreLiteTestRunner.gd`: 35 checks passed.
- `CardFirstEffectsTestRunner.gd`: 35 checks passed.
- `CardfrontTargetBiasTestRunner.gd`: 13 checks passed.
- `RegionMoraleTestRunner.gd`: 24 checks passed.
- `FortifyLayerTestRunner.gd`: 469 checks passed.
- `DeploymentRulesTestRunner.gd`: 26 checks passed.
- `EconomyTickTestRunner.gd`: 50 checks passed.
- `CardfrontModeSmokeTestRunner.gd`: 35 checks passed.
- `SmokeTestRunner.gd`: 218 checks passed.
- `IntegrationTestRunner.gd`: 133 checks passed.

## Next slice

`v0.1.6.1-pioneer-beacon-lite`
