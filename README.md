# Marble Dominion: Cardfront / 弹珠领土：卡牌前线

**Godot 4.6 + GDScript** prototype built from the BallWar / Marble Dominion Ricochet War foundation.

Cardfront is a controlled prototype branch for turning BallWar's marble territory-control arena into a strategy game:

> 占领格子 -> 产生经济 -> 打出卡牌 -> 改写炮塔、地图和单位规则 -> 继续争夺关键区域。

The current completed slice is **v0.1.5-card-core-lite**. It adds a minimal card play pipeline with a fixed 3-card hand, resource cost deduction, and a working Fortify card.

## Current Slice / 当前阶段

Implemented in this repository:

- New `卡牌前线` game mode in the existing mode selector.
- Player vs AI baseline: BLUE is player, RED is AI, the center starts neutral.
- Cardfront battlefield layout via `scripts/cardfront/CardfrontBattlefieldInitializer.gd`.
- Deterministic Cardfront region layer with `NORMAL`, `ENERGY`, `FACTORY`, and `LAB` cells.
- Stable `region_id` instances for contested `ENERGY`, `FACTORY`, and central `LAB` regions.
- Per-region player / AI / neutral control statistics via `RegionControlCalculator.gd`.
- Cardfront resource state, region yield rules, and 1-second economy tick.
- Compact Cardfront-only economy debug panel for resource and region-yield verification.
- Cardfront-only low-pressure bullet visual policy that keeps richer marble effects while old BallWar modes keep their original degradation rules.
- Region-local morale system for support and unrest ownership shifts.
- Deployment permission rules for owned cells, owned borders, and controlled regions.
- Cardfront-only translucent region overlay.
- Cardfront mode starts with only two turrets and two control chambers.
- Event roulette is disabled in Cardfront mode; active card play will replace it later.
- Cardfront win rules:
  - 70% capture wins immediately.
  - 8-minute timer ends by player/AI territory lead.
  - Equal player/AI territory at timer is a draw.
- New headless runner: `CardfrontModeSmokeTestRunner.gd`.
- New headless runner: `RegionMapTestRunner.gd`.
- New headless runner: `DeploymentRulesTestRunner.gd`.

Not implemented yet:

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

- `scripts/cardfront/deployment/` - shared deployment permission query/result/rule evaluation.

- `scripts/cardfront/CardfrontRules.gd` — mode constants, duel factions, neutral owner, timer and capture target.
- `scripts/cardfront/CardfrontBattlefieldInitializer.gd` — player/AI/neutral initial owner-grid generation.
- `scripts/cardfront/regions/RegionMap.gd` — deterministic region instance map used by Cardfront systems.
- `scripts/cardfront/regions/RegionControlCalculator.gd` — per-region player / AI / neutral control statistics.
- `scripts/cardfront/economy/` — resource state, region yield rules, yield calculator, economy tick system, and debug panel.
- `scripts/cardfront/morale/` — region-local morale rules and deterministic morale tick system.
- `scripts/cardfront/regions/RegionOverlayLayer.gd` — lightweight Cardfront-only region visualization.
- `scripts/cardfront/CardfrontMode.gd` — thin assembly layer used by `Main.gd`.
- `scripts/Battlefield.gd` — owns generic owner grids, owner counts, painting, and draw color overrides.
- `scripts/WinConditionEvaluator.gd` — adds Cardfront win evaluation beside the existing BallWar modes.
- `scripts/Main.gd` — stays orchestration-only and delegates Cardfront rules to `scripts/cardfront/`.

Detailed milestone notes:

- [docs/history/README_v0_1_5_card_core_lite.md](docs/history/README_v0_1_5_card_core_lite.md)
- [docs/history/README_v0_1_4_fortify_layer.md](docs/history/README_v0_1_4_fortify_layer.md)
- [docs/history/README_v0_1_3_2_cardfront_debug_panel_placement.md](docs/history/README_v0_1_3_2_cardfront_debug_panel_placement.md)
- [docs/history/README_v0_1_3_1_visual_pressure_rebalance.md](docs/history/README_v0_1_3_1_visual_pressure_rebalance.md)
- [docs/history/README_v0_1_3_deployment_rules.md](docs/history/README_v0_1_3_deployment_rules.md)
- [docs/history/README_v0_1_2_region_morale.md](docs/history/README_v0_1_2_region_morale.md)
- [docs/history/README_v0_1_2_1_cardfront_visibility_polish.md](docs/history/README_v0_1_2_1_cardfront_visibility_polish.md)
- [docs/history/README_v0_1_1_region_instances.md](docs/history/README_v0_1_1_region_instances.md)
- [docs/history/README_v0_1_1_region_yield.md](docs/history/README_v0_1_1_region_yield.md)
- [docs/history/README_v0_1_1_region_map.md](docs/history/README_v0_1_1_region_map.md)
- [docs/history/README_v0_1_0_cardfront_prototype.md](docs/history/README_v0_1_0_cardfront_prototype.md)

## Validation / 验证

Run with Godot 4.6:

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/FortifyLayerTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/NeutralOwnerCompatibilityTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DeploymentRulesTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMoraleTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EconomyTickTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EconomyDebugPanelSceneTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontVisualPolicyTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/VisualPressurePolicyTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMapTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

Latest local validation:

- `FortifyLayerTestRunner.gd`: 469 checks passed.
- `CardfrontModeSmokeTestRunner.gd`: 32 checks passed.
- `NeutralOwnerCompatibilityTestRunner.gd`: 24 checks passed.
- `DeploymentRulesTestRunner.gd`: 26 checks passed.
- `RegionMoraleTestRunner.gd`: 24 checks passed.
- `EconomyTickTestRunner.gd`: 50 checks passed.
- `EconomyDebugPanelSceneTestRunner.gd`: 12 checks passed.
- `CardfrontVisualPolicyTestRunner.gd`: 27 checks passed.
- `VisualPressurePolicyTestRunner.gd`: 25 checks passed.
- `RegionMapTestRunner.gd`: 3737 checks passed.
- `SmokeTestRunner.gd`: 218 checks passed.
- `IntegrationTestRunner.gd`: 133 checks passed.
- `StartMenuSceneTestRunner.gd`: 55 checks passed.
- `GameHUDSceneTestRunner.gd`: 40 checks passed.
- `LayoutSanityTestRunner.gd`: 376 checks passed.
- `SaveFlowControllerTestRunner.gd`: 190 checks passed.
- `EndToEndContinueMainTestRunner.gd`: 56 checks passed.

## Next Milestone / 下一阶段

`v0.1.6-first-card-effects`:

- Pseudo-card core with fixed hand and energy costs.
- Still defer card UI, unit devices, and AI Commander behavior.
- Full route is tracked in [docs/ROADMAP.md](docs/ROADMAP.md).

## License

MIT License. See [LICENSE](LICENSE).
