# v0.1.3-deployment-rules

Date: 2026-05-19

This slice adds the bottom-layer Cardfront deployment permission system. It only answers whether a requested deployment is allowed; it does not spawn units, play cards, run AI, or add frontline fortification.

## Goal

Create one shared rule evaluator for later Cardfront cards and devices such as pioneer beacon, temporary rebound board, bullet absorber core, frontline fortification, and collection stations. The rules are based on owner grids and region-control percentages, not on bullet internals.

## Implemented

- Added `scripts/cardfront/deployment/DeploymentRuleType.gd`:
  - `OWNED_CELL`
  - `OWNED_BORDER`
  - `OWNED_REGION_CONTROLLED`
  - `CONTESTED_REGION`
  - `ENEMY_REGION`
- Added `scripts/cardfront/deployment/DeploymentQuery.gd`.
- Added `scripts/cardfront/deployment/DeploymentResult.gd`.
- Added `scripts/cardfront/deployment/DeploymentRules.gd`.
- Added `scripts/tests/DeploymentRulesTestRunner.gd`.

## Rules

- `OWNED_CELL`: the target cell must be inside the map and owned by `query.owner_id`.
- `OWNED_BORDER`: the target cell must be owned by `query.owner_id` and touch at least one non-owned cell in its 8-neighborhood.
- `OWNED_REGION_CONTROLLED`: the region must be valid and `query.owner_id` must meet `min_region_control_percent`.
- `CONTESTED_REGION` and `ENEMY_REGION` are reserved with basic judgment paths for later gameplay wiring.

`DeploymentRules.gd` reuses `RegionControlCalculator.gd` for region-control percentages. It does not duplicate region statistics logic.

## Boundaries

- No card UI.
- No card data or card effects.
- No units or devices.
- No AI Commander behavior.
- No frontline fortification layer.
- No changes to `Battlefield.apply_bullet()`.
- No changes to `Bullet`, `BulletPool`, `Turret`, or `ControlChamber`.
- `evaluate(...)` does not mutate `Battlefield` owners or `RegionMap` snapshots.

## Validation

Run after this slice:

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DeploymentRulesTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMoraleTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EconomyTickTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EconomyDebugPanelSceneTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontVisualPolicyTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMapTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/NeutralOwnerCompatibilityTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

## Next Slice

`v0.1.4-fortify-layer` should build a frontline fortification layer above deployment rules. Cards, units, and AI still wait.
