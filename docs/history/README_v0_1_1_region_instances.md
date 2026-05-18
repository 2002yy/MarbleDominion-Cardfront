# v0.1.1-b-region-instances

Date: 2026-05-18

This slice upgrades the Cardfront region layer from a cell-type map into explicit region instances. It does not add economy ticks, morale, cards, units, AI Commander behavior, deployment rules, or fortification systems.

## Goal

Give each controllable Cardfront region a stable `region_id` so later systems can calculate control, yield, morale, deployment permission, and card effects without coupling that logic to `Battlefield.apply_bullet()`.

## Implemented

- Upgraded `scripts/cardfront/regions/RegionMap.gd` with:
  - `region_ids`: cell to `region_id`
  - `region_types`: `region_id` to region type
  - `region_cells`: `region_id` to owned cells
  - stable `next_region_id` allocation
- Preserved the v0.1.1-a compatibility API:
  - `get_region_type(cell)`
  - `set_region_type(cell, region_type)`
  - `count_region_cells(region_type)`
  - `count_owned_region_cells(battlefield, owner_id, region_type)`
  - `snapshot()`
- Added new instance APIs:
  - `get_region_id(cell)`
  - `get_region_type_by_id(region_id)`
  - `get_region_cells(region_id)`
  - `get_region_ids_by_type(region_type)`
  - `get_all_region_ids()`
  - `get_controllable_region_ids()`
- Kept default layout deterministic:
  - `NORMAL` uses `region_id = 0`
  - each `ENERGY` block is an independent region
  - each `FACTORY` block is an independent region
  - the central `LAB` is one independent region
  - 40x40 and 60x60 layouts remain stable
- Added `scripts/cardfront/regions/RegionControlCalculator.gd` for per-region player / AI / neutral ownership statistics and 50% / 80% tier lookup.
- Expanded `scripts/tests/RegionMapTestRunner.gd` to cover region ids, reverse cell lookup, control statistics, yield-tier thresholds, overlay behavior, and Main integration.

## Boundaries

- No `EconomyTickSystem` yet.
- No resource income application yet.
- No morale system yet.
- No card play, deck, hand, or card effect system yet.
- No unit or device system yet.
- No frontline fortification layer yet.
- No changes to `Bullet`, `BulletPool`, `Turret`, or `ControlChamber`.
- No economy logic in `Battlefield.apply_bullet()`.

## Validation

Run after this slice:

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMapTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/NeutralOwnerCompatibilityTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

## Next Slice

`v0.1.1-c-region-yield` should turn the region-control tier data into resource yield rules. Keep that next slice focused on production math and tick integration; cards, morale, units, and fortification still wait.
