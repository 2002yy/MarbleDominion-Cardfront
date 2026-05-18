# v0.1.1-a-region-map

Date: 2026-05-18

This slice adds the first Cardfront region layer. It does not add economy ticks, cards, deck data, AI Commander behavior, or save-schema migration.

## Goal

Create a deterministic region map that can sit above Battlefield ownership without changing bullet capture, turret, chamber, or BallWar mode logic.

## Implemented

- Added `scripts/cardfront/regions/RegionType.gd` with `NORMAL`, `ENERGY`, `FACTORY`, and `LAB`.
- Added `scripts/cardfront/regions/RegionMap.gd`:
  - stable 40x40 and 60x60 default layouts
  - central `LAB`
  - contested `ENERGY` and `FACTORY` regions
  - no `LAB` on player/AI spawn edges
  - region snapshots and owned-region counting
- Added `scripts/cardfront/regions/RegionOverlayLayer.gd`:
  - visible only in Cardfront mode
  - translucent markers for `ENERGY`, `FACTORY`, and `LAB`
  - does not alter `Battlefield` cell textures
  - stays below bullet trail and bullet rendering
- Added `scripts/tests/RegionMapTestRunner.gd`.

## Boundaries

- No 1-second economy tick yet.
- No resource inventory yet.
- No card play, deck, or hand system yet.
- No AI Commander behavior yet.
- No changes to `Bullet`, `BulletPool`, `Turret`, or `ControlChamber`.
- No economy logic in `Battlefield.apply_bullet()`.

## Validation

Run after this slice:

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/NeutralOwnerCompatibilityTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMapTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

## Next Slice

`v0.1.1-b-region-instances` should add stable `region_id`, explicit region instances, and per-region control statistics. Keep it data-only: no economy tick, no cards, and no AI in that slice.
