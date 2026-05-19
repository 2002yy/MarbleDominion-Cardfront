# README_v0_1_6_2_cardfront_control_chamber_decoupling

Date: 2026-05-19

Role: detailed stage record for Cardfront control-chamber decoupling and FireDirector budget fairness.

## Summary / 摘要

`v0.1.6.2-cardfront-control-chamber-decoupling` makes the Cardfront play surface match the FireDirector direction. Cardfront no longer creates the old control-chamber UI or +ball buttons, while old BallWar modes keep their original control-chamber flow.

This slice also changes FireDirector from one global shot budget to a two-layer budget:

- total per-second cap
- per-owner per-second cap

That prevents early-iterated owners from consuming the whole window when later cards or devices increase shot counts.

## Added / 新增

- `CardfrontMode.FIRE_STATUS_TEXT`
  - HUD text: `自动射击中 / 卡牌改写射击`
- `CardfrontMode.uses_control_chambers()`
  - returns `false` for the current Cardfront line.
- `CardfrontMode.configure_runtime_hud(...)`
  - puts the Cardfront fire status into the event-status slot.
- `CardfrontControlChamberDecouplingTestRunner.gd`
  - verifies Cardfront skips chambers/buttons and old BallWar keeps them.

## Changed / 修改

- `Main.gd`
  - does not create control chambers in Cardfront mode.
  - does not create +ball buttons in Cardfront mode.
  - leaves `runtime.chambers` and `add_ball_buttons` as empty dictionaries for Cardfront.
  - still creates normal control chambers and buttons for old BallWar modes.
- `CardfrontFireRules.gd`
  - adds `MAX_TOTAL_SHOTS_PER_SECOND`.
  - adds `MAX_OWNER_SHOTS_PER_SECOND`.
- `CardfrontFireDirector.gd`
  - tracks total shots per one-second window.
  - tracks owner shots per one-second window.
  - clamps intents against the active owner budget and remaining global budget.
- `CardfrontFireDirectorTestRunner.gd`
  - adds coverage that a first owner cannot starve the second owner in the same shot window.
- `CardfrontModeSmokeTestRunner.gd`
  - now expects no Cardfront control chambers/buttons and checks HUD status text.

## Behavior / 行为

- Cardfront:
  - two turrets are still created.
  - `fire_director` is created.
  - legacy `runtime.chambers` stays empty.
  - `add_ball_buttons` stays empty.
  - HUD status says automatic/card-directed fire is active.
- Old BallWar:
  - control chambers are still created.
  - +ball buttons are still created.
  - `fire_director` remains null.

## Deferred / 暂缓

- No formal card UI.
- No deck/draw/discard/shuffle.
- No AI Commander.
- No full unit-device system.
- No Cardfront-specific replacement control surface yet.

## Validation / 验证

Required runner for this slice:

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontControlChamberDecouplingTestRunner.gd
```

Related regression lane:

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontFireDirectorTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```
