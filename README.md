# Marble Dominion: Cardfront / 弹珠领土：卡牌前线

**Godot 4.6 + GDScript** prototype built from the BallWar / Marble Dominion Ricochet War foundation.

Cardfront is a controlled prototype branch for turning BallWar's marble territory-control arena into a strategy game:

> 占领格子 -> 产生经济 -> 打出卡牌 -> 改写炮塔、地图和单位规则 -> 继续争夺关键区域。

The current milestone is **v0.1.0-cardfront-prototype**. It proves the new mode can live beside the stable BallWar runtime without deleting the original modes.

## Current Slice / 当前阶段

Implemented in this repository:

- New `卡牌前线` game mode in the existing mode selector.
- Player vs AI baseline: BLUE is player, RED is AI, the center starts neutral.
- Cardfront battlefield reset via `Battlefield.reset_cardfront_duel()`.
- Cardfront mode starts with only two turrets and two control chambers.
- Event roulette is disabled in Cardfront mode; active card play will replace it later.
- Cardfront win rules:
  - 70% capture wins immediately.
  - 8-minute timer ends by player/AI territory lead.
  - Equal player/AI territory at timer is a draw.
- New headless runner: `CardfrontModeSmokeTestRunner.gd`.

Not implemented yet:

- Region economy.
- Deck / hand / card effect data.
- AI Commander behavior.
- Cardfront save schema.
- Dedicated Cardfront HUD and card UI.

## Screenshots / 截图

These screenshots still show the inherited BallWar visual baseline while Cardfront systems are being added.

| Start Menu | Initial Field | Mid Game | Event Screen | Result |
|:--:|:--:|:--:|:--:|:--:|
| ![](screenshots/%E5%BC%80%E5%A7%8B%E7%95%8C%E9%9D%A2.png) | ![](screenshots/%E6%B8%B8%E6%88%8F%E5%88%9D%E5%A7%8B.png) | ![](screenshots/%E6%B8%B8%E6%88%8F%E4%B8%AD%E5%9C%BA.png) | ![](screenshots/%E4%BA%8B%E4%BB%B6%E7%94%BB%E9%9D%A2.png) | ![](screenshots/%E4%B8%80%E6%96%B9%E8%83%9C%E5%88%A9%E7%BB%93%E6%9E%9C.png) |

## Architecture / 架构

Cardfront is added as a sidecar mode, not a rewrite of the BallWar runtime.

- `scripts/cardfront/CardfrontRules.gd` — mode constants, duel factions, neutral owner, timer and capture target.
- `scripts/cardfront/CardfrontMode.gd` — thin assembly layer used by `Main.gd`.
- `scripts/Battlefield.gd` — still owns grid ownership and drawing; Cardfront adds a duel reset path.
- `scripts/WinConditionEvaluator.gd` — adds Cardfront win evaluation beside the existing BallWar modes.
- `scripts/Main.gd` — stays orchestration-only and delegates Cardfront rules to `scripts/cardfront/`.

Detailed milestone note: [docs/history/README_v0_1_0_cardfront_prototype.md](docs/history/README_v0_1_0_cardfront_prototype.md)

## Validation / 验证

Run with Godot 4.6:

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

Latest local validation:

- `CardfrontModeSmokeTestRunner.gd`: 29 checks passed.
- `SmokeTestRunner.gd`: 218 checks passed.
- `IntegrationTestRunner.gd`: 136 checks passed.
- `StartMenuSceneTestRunner.gd`: 55 checks passed.
- `GameHUDSceneTestRunner.gd`: 40 checks passed.
- `LayoutSanityTestRunner.gd`: 376 checks passed.
- `SaveFlowControllerTestRunner.gd`: 190 checks passed.
- `EndToEndContinueMainTestRunner.gd`: 56 checks passed.

## Next Milestone / 下一阶段

`v0.1.1-region-economy`:

- Add `RegionMap.gd`.
- Add simple region visualization.
- Add 1-second economy tick for energy and parts.
- Keep economy out of `Battlefield.apply_bullet()` so the grid layer remains reusable.

## License

MIT License. See [LICENSE](LICENSE).
