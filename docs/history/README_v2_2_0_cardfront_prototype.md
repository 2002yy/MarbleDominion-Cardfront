# v2.2.0-cardfront-prototype

Date: 2026-05-18

This branch starts the controlled Cardfront prototype beside the stable BallWar line.

## Goal

Create the first safe entry point for **Marble Dominion: Cardfront / 弹珠领土：卡牌前线** without deleting the existing BallWar modes.

The v2.2.0 slice intentionally stops before card data, economy, AI strategy, save migration, and new UI art. Its job is to prove that Cardfront can live as a separate mode and reuse the BallWar runtime foundation.

## Implemented

- Added `scripts/cardfront/CardfrontRules.gd` for Cardfront constants, duel factions, neutral owner rules, match timer, and target percentage.
- Added `scripts/cardfront/CardfrontMode.gd` as the thin mode assembly layer used by `Main.gd`.
- Added `GameConfig.GAME_MODE_CARDFRONT` and exposed it through the existing mode selector.
- Added `Battlefield.reset_cardfront_duel()`:
  - BLUE = player side.
  - RED = AI side.
  - `-1` = neutral center territory.
- Cardfront mode now starts with only BLUE and RED turrets/chambers.
- Event roulette is skipped in Cardfront mode because active card play will later replace it as the core intervention system.
- Added `WinConditionEvaluator.evaluate_cardfront()`:
  - 70% capture ends the match early.
  - 8-minute timer ends by player/AI territory lead.
  - Equal player/AI territory at timer becomes a draw.
- Added `scripts/tests/CardfrontModeSmokeTestRunner.gd`.

## Boundaries

- No card deck yet.
- No economy tick yet.
- No AI Commander yet.
- No Cardfront save schema yet.
- No large UI redesign yet.
- Existing BallWar modes and save system remain in place.

## Validation

Run after this slice:

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

## Next Slice

`v2.2.1-region-economy` should add `RegionMap.gd`, a lightweight region overlay, and a 1-second economy tick. Keep it separate from `Battlefield.apply_bullet()` so territory ownership remains the base layer.
