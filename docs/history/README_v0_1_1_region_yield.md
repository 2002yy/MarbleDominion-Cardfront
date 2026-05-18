# v0.1.1-c-region-yield

Date: 2026-05-18

This slice turns Cardfront region control tiers into resource yield. It does not add morale, cards, units, AI Commander behavior, deployment rules, or frontline fortification.

## Goal

Create a small economy layer that reads `RegionMap` and `Battlefield` ownership, converts per-region control tiers into resource output, and applies the result to owner resource states on a 1-second tick.

## Implemented

- Added `scripts/cardfront/economy/CardfrontResourceState.gd`:
  - `energy` and `parts`
  - atomic `pay(...)`
  - non-negative resource clamps
  - `snapshot()` and `restore(...)`
- Added `scripts/cardfront/economy/RegionYieldRules.gd`:
  - `ENERGY`: tier 0 / 1 / 2 -> 0 / 1 / 2 energy
  - `FACTORY`: tier 0 / 1 / 2 -> 0 / 1 / 2 parts
  - `LAB`: no ordinary resource yield in this slice
- Added `scripts/cardfront/economy/RegionYieldCalculator.gd`:
  - reads controllable region ids
  - uses `RegionControlCalculator.get_yield_tier(...)`
  - returns total tick yield plus per-region details
- Added `scripts/cardfront/economy/EconomyTickSystem.gd`:
  - Node-based 1-second tick
  - reads only `region_map` and `battlefield`
  - writes only configured `CardfrontResourceState` instances
  - emits `resources_changed` and `yield_tick`
- Wired Cardfront economy creation through `CardfrontMode.create_economy(...)` and `Main._create_cardfront_economy()`.
- Added `scripts/tests/EconomyTickTestRunner.gd`.

## Boundaries

- No morale fluctuation yet.
- No card play, deck, hand, or card effect system yet.
- No unit or device system yet.
- No AI Commander behavior yet.
- No frontline fortification layer yet.
- No changes to `Bullet`, `BulletPool`, `Turret`, or `ControlChamber`.
- No economy logic in `Battlefield.apply_bullet()`.
- No large HUD or UI refactor.

## Validation

Run after this slice:

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EconomyTickTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMapTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/NeutralOwnerCompatibilityTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

## Next Slice

`v0.1.2-region-morale` should add morale fluctuation on top of region state. Cards, units, AI, deployment rules, and fortification still wait.
