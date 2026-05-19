# README_v0_1_6_1_pioneer_beacon_lite

Date: 2026-05-19

Role: detailed stage record for the logic-only Pioneer Beacon card-effect slice.

## Summary / 摘要

`v0.1.6.1-pioneer-beacon-lite` adds the fourth Cardfront card:

- ID: `1004`
- Name: Pioneer Beacon / 拓荒信标
- Cost: `8 energy + 4 parts`
- Target: `OWNED_BORDER`
- Effect: convert up to 3 nearby neutral cells to the player owner

This is intentionally a light, one-shot logic effect. It does not create a map entity, does not have duration, and does not enter the full unit-device system yet.

## Added / 新增

- `scripts/cardfront/effects/PioneerBeaconLiteEffect.gd`
  - owns the neutral-neighbor search and conversion rule.
  - validates the selected cell through `DeploymentRules.is_owned_border(...)`.
  - converts neutral neighbors through the existing battlefield capture entrypoint.
- `scripts/tests/PioneerBeaconLiteTestRunner.gd`
  - covers catalog registration, successful conversion, no-neutral failure rollback, non-border rejection, missing-system failure, and direct effect result data.

## Updated / 更新

- `CardType.gd`
  - adds `PIONEER_BEACON`.
- `CardCatalog.gd`
  - adds card `1004` and includes it in the fixed Cardfront hand.
- `CardPlaySystem.gd`
  - dispatches `pioneer_beacon_lite` to `PioneerBeaconLiteEffect`.
  - keeps payment, target validation, hand-used state, and rollback in the card-play pipeline.
- `CardCoreLiteTestRunner.gd`
  - updates fixed-hand coverage from 3 cards to 4 cards.

## Behavior / 行为

- Success path:
  - target must be an owned border cell.
  - up to 3 adjacent neutral cells are converted to the playing owner.
  - resource payment and hand-used state are committed.
- Failure path:
  - missing systems fail.
  - invalid or non-border targets fail.
  - owned-border targets with no neutral neighbor fail.
  - effect failure rolls back resources and hand-used state.

## Deferred / 暂缓

- No durable beacon entity.
- No pulse duration or cooldown.
- No unit-device simulation.
- No formal card UI.
- No deck, draw, discard, or shuffle.
- No AI Commander.

## Validation / 验证

Required runner for this slice:

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/PioneerBeaconLiteTestRunner.gd
```

Related regression lane:

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardCoreLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardFirstEffectsTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/FortifyLayerTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DeploymentRulesTestRunner.gd
```
