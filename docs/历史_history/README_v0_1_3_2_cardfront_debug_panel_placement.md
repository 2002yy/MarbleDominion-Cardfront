# v0.1.3.2-cardfront-debug-panel-placement

Date: 2026-05-19

Polish slice: moves the Cardfront economy debug panel from the hardcoded top-left corner to the bottom-right corner, keeping it out of the battlefield and control chambers.

## Problem

The debug panel was positioned at `Vector2(8, 118)`, which overlapped the battlefield and control chamber area. This made it hard to see the game state during development.

## Fix

- Added `PANEL_SIZE`, `PANEL_MARGIN`, and `PANEL_PLACEMENT` constants.
- Added `_resolve_panel_position(view_size)` supporting `"bottom_right"` and `"bottom_left"`.
- `_ensure_ui()` now reads viewport size and calls `_resolve_panel_position` instead of hardcoding position.
- Panel size changed from `260×150` to `280×150`.
- Label sizing is calculated from `PANEL_SIZE` minus padding.

## Files changed

- `scripts/cardfront/economy/CardfrontEconomyDebugPanel.gd` — placement constants, `_resolve_panel_position`
- `scripts/tests/EconomyDebugPanelSceneTestRunner.gd` — added position and boundary assertions

## Boundaries

- No change to economy system, morale, deployment, BulletPool, or Battlefield.
- No change to non-Cardfront modes.
- No gameplay logic changes.

## Validation

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EconomyDebugPanelSceneTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontVisualPolicyTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DeploymentRulesTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMoraleTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EconomyTickTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

## Next slice

`v0.1.4-fortify-layer`
