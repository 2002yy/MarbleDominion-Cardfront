# v0.1.5-card-core-lite

Date: 2026-05-19

This slice adds a minimal, testable Cardfront card core with a fixed 3-card hand, resource cost deduction, target validation, and a working "前线加固" (Frontline Fortify) card that calls the existing FortifyLayer.

## Goal

Provide the bottom-layer card play pipeline — card data, catalog, hand state, play request/result, and effect resolution — without a full deckbuilder, card UI, or AI Commander.

## Implemented

### Card core

- `scripts/cardfront/cards/CardType.gd` — fortify / calibrated_shot / morale_fluctuation types.
- `scripts/cardfront/cards/CardTargetType.gd` — owned_border / enemy_region / owned_region targets.
- `scripts/cardfront/cards/CardData.gd` — card data: id, name, type, cost, target_type, effect_id.
- `scripts/cardfront/cards/CardCatalog.gd` — singleton catalog with 3 predefined cards.
- `scripts/cardfront/cards/CardHandState.gd` — fixed 3-card hand, used/available tracking.
- `scripts/cardfront/cards/CardPlayRequest.gd` — play request: card_id, owner_id, target_cell, target_region_id.
- `scripts/cardfront/cards/CardPlayResult.gd` — result: success, reason, consumed costs.
- `scripts/cardfront/cards/CardPlaySystem.gd` — play pipeline: catalog lookup, resource check, target validation, effect resolution, rollback on failure.

### Cards

| ID | Name | Type | Energy | Parts | Target |
|---|---|---|---|---|---|
| 1001 | 前线加固 | fortify | 10 | 3 | owned_border |
| 1002 | 校准射击 | calibrated_shot | 8 | 5 | enemy_region |
| 1003 | 民心起伏 | morale_fluctuation | 5 | 2 | owned_region |

- "前线加固" calls `FortifyLayer.add_fortify_stack` on the target border cell.
- "校准射击" and "民心起伏" are stubs returning success; effects deferred to v0.1.6.

### Wiring

- `scripts/cardfront/CardfrontMode.gd` — `create_card_system()` assembly.
- `scripts/Main.gd` — `_create_cardfront_card_system()` called during game start.
- `scripts/GameRuntimeContext.gd` — added `card_system` field.
- `scripts/tests/CardCoreLiteTestRunner.gd` — 11 test cases.

## Boundaries

- No deckbuilding, card draw, discard, or shuffle.
- No card UI or card HUD.
- No AI Commander behavior.
- No unit devices or device effects.
- No changes to Bullet, BulletPool, Turret, or ControlChamber.
- Old BallWar modes unchanged.

## Validation

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardCoreLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/FortifyLayerTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DeploymentRulesTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EconomyTickTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

## Next slice

`v0.1.6-first-card-effects`
