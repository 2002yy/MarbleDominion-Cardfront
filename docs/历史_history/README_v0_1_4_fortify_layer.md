# v0.1.4-fortify-layer

Date: 2026-05-19

This slice adds the Cardfront frontline fortification layer. Fortified cells appear darker with a shield border overlay and require multiple enemy hits to be captured.

## Goal

Provide a persistent fortification system above deployment permission checks. Fortified cells consume one fortify stack per enemy hit instead of flipping ownership. This is a bottom-layer system — cards and AI will trigger fortification later.

## Implemented

### Core

- `scripts/cardfront/fortify/FortifyRules.gd` — constants `MAX_FORTIFY_STACKS = 3`, `DEFAULT_FORTIFY_STACKS = 3`.
- `scripts/cardfront/fortify/FortifyLayer.gd` — grid-based stack layer with `configure`, `get_fortify_stack`, `set_fortify_stack`, `add_fortify_stack`, `clear_fortify_stack`, `fortify_cells`, `consume_hit`, `is_fortified`, `snapshot`, `restore`.
- `scripts/cardfront/fortify/FortifyTargetSelector.gd` — `select_owned_border_cells` reuses `DeploymentRules.is_owned_border`.
- `scripts/cardfront/fortify/CardfrontCaptureInterceptor.gd` — wraps FortifyLayer; `should_block_capture(cell, incoming, current)` returns true when fortify stacks exist and consume one.

### Battlefield hook

- `scripts/Battlefield.gd` — added `capture_interceptor` field. `apply_bullet()` calls interceptor before flipping owner; returns `"BLOCKED_BY_FORTIFY"` when intercepted. Old BallWar modes have no interceptor — behavior unchanged.

### Visual overlay

- `scripts/cardfront/fortify/FortifyOverlayLayer.gd` — draws darker cell fill and colored border per stack level. Only visible in Cardfront mode. Position tracks battlefield.

### Wiring

- `scripts/cardfront/CardfrontMode.gd` — `create_fortify(game_layer, battlefield, region_map)` creates FortifyLayer, overlay, and interceptor.
- `scripts/Main.gd` — `_create_cardfront_fortify()` called during game start.
- `scripts/GameRuntimeContext.gd` — added `fortify_layer` and `fortify_overlay` fields.

## Boundaries

- No card UI, no card data, no card effects.
- No AI Commander behavior.
- No units or devices.
- No changes to `Bullet`, `BulletPool`, `Turret`, or `ControlChamber`.
- No changes to economy, morale, or deployment rules.
- Old BallWar modes behave identically (no interceptor set).

## Validation

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/FortifyLayerTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/NeutralOwnerCompatibilityTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DeploymentRulesTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMoraleTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EconomyTickTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMapTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

## Next slice

`v0.1.5-card-core-lite`
