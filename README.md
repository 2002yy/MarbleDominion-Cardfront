# Marble Dominion: Cardfront / 弹珠领土：卡牌前线

**Godot 4.6 + GDScript** prototype built from the BallWar / Marble Dominion Ricochet War foundation.

Cardfront is a controlled prototype branch for turning BallWar's marble territory-control arena into a strategy game:

> 调整炮口 -> 暂停三选一 -> 自动齐射 -> 争夺路线与防御 -> 摧毁敌方控制舱。

Current version, active implementation slice, next step, and deferred scope are maintained only in [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md).
当前版本与实施进度只在 [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md) 维护。

## Live v0.3 Loop / 当前主玩法

The default Cardfront runtime is the lean 1v1 loop: manual aim, paused three-choice upgrade, simultaneous automatic volleys, visible per-cell territory defense, and 40-health command chambers. The former four-card hand and its UI/feedback chain have been deleted; low-level Energy/Parts economy, morale, card effects, and devices remain behind an explicit compatibility flag for focused simulation tests only.

当前默认 Cardfront 只装配“瞄准 -> 暂停三选一 -> 双方自动齐射 -> 领土护甲 -> 摧毁控制舱”主循环。旧四卡手牌及其点格交互、提示反馈界面已经删除；旧经济、士气、卡牌效果与装置的底层逻辑暂留在显式测试兼容装配中。

The current arena is still a transitional `Node2D` presentation. `ENERGY`, `FACTORY`, and `LAB` shapes remain visible but do not yet provide live bonuses; the committed next steps are an explicit tactical-stronghold contract followed by a real orthographic `Camera3D` 2.5D arena spike.

当前玩法状态仍由 `Node2D` 权威模拟，但 Cardfront 已使用真正的正交 `Camera3D` 镜像呈现 2.5D 战场。能源/工厂/实验室据点已接入路线与强点规则；`default_duel` 已进入明亮玩具沙盘标杆阶段，后续美术替换只改表现层，不改变格子、闸门、弹体和胜负权威。

## Historical v0.2 Compatibility / 历史兼容代码

v0.2 originally provided a four-card hand, Energy/Parts minibar, card target clicks, resource hints, card detail, toast/audio feedback, and a tutorial overlay. **That player-facing UI has been retired together with its dedicated scenes, adapters, input routes, runtime references, tests, and CI jobs.** The v0.3 three-choice UI is the only active Cardfront choice surface.

旧版固定四卡手牌、资源栏、点格出牌、反馈气泡、教程提示等界面与对应测试已整体退役。现役玩家使用 v0.3 的三选一升级界面。历史实现与设计决策可在 Git 历史和 `docs/历史_history/` 中查阅。

The optional `cardfront_legacy_compatibility_enabled` flag still assembles **low-level** legacy economy, morale, fixed-card effects, device effects, and VFX for the remaining focused simulation tests. It no longer restores the v0.2 player-facing UI. This is a transitional test compatibility boundary, not a supported second gameplay mode.

兼容开关仍能创建旧经济、士气、卡牌效果和装置等底层模块供现存测试使用，但不再恢复旧玩家界面。后续是否删除底层功能，需要进一步确认它们与现役玩法的共享依赖。

## Screenshots / 截图

These screenshots still show the inherited BallWar visual baseline while Cardfront systems are being added.

| Start Menu | Initial Field | Mid Game | Event Screen | Result |
|:--:|:--:|:--:|:--:|:--:|
| ![](截图_screenshots/%E5%BC%80%E5%A7%8B%E7%95%8C%E9%9D%A2.png) | ![](截图_screenshots/%E6%B8%B8%E6%88%8F%E5%88%9D%E5%A7%8B.png) | ![](截图_screenshots/%E6%B8%B8%E6%88%8F%E4%B8%AD%E5%9C%BA.png) | ![](截图_screenshots/%E4%BA%8B%E4%BB%B6%E7%94%BB%E9%9D%A2.png) | ![](截图_screenshots/%E4%B8%80%E6%96%B9%E8%83%9C%E5%88%A9%E7%BB%93%E6%9E%9C.png) |

## Architecture / 架构

Cardfront is added as a sidecar mode, not a rewrite of the BallWar runtime.

- `scripts/cardfront/deployment/` - shared deployment permission query/result/rule evaluation.

- `scripts/cardfront/CardfrontRules.gd` — mode constants, duel factions, neutral owner, timer and capture target.
- `scripts/cardfront/CardfrontBattlefieldInitializer.gd` — player/AI/neutral initial owner-grid generation.
- `scripts/cardfront/regions/RegionMap.gd` — deterministic region instance map used by Cardfront systems.
- `scripts/cardfront/regions/RegionControlCalculator.gd` — per-region player / AI / neutral control statistics.
- `scripts/cardfront/economy/` — resource state, region yield rules, yield calculator, economy tick system, and debug panel.
- `scripts/cardfront/morale/` — region-local morale rules and deterministic morale tick system.
- `scripts/cardfront/cards/` — fixed-hand card catalog, play request/result, cost checks, target validation, effect dispatch, and rollback.
- `scripts/cardfront/effects/CardfrontTargetBiasSystem.gd` — Cardfront-only target-region bias state used by Calibrated Shot.
- `scripts/cardfront/effects/PioneerBeaconLiteEffect.gd` — one-shot Pioneer Beacon neutral-cell pulse logic.
- `scripts/cardfront/fire/` — Cardfront-only fire rules, target scoring, fire intent data, and fire director.
- `scripts/cardfront/runtime/` — Cardfront runtime assembly builder, named refs, and result-to-runtime registry.
- `scripts/cardfront/ui/` — Cardfront formal HUD, hand cards, selection controller, feedback bus, detail popup, toasts, UI asset registry, and light audio/visual feedback bridges.
- `scripts/cardfront/vfx/CardfrontVfxLayer.gd` — reusable Cardfront visible-effect layer for card/device feedback.
- `scripts/cardfront/regions/RegionOverlayLayer.gd` — lightweight Cardfront-only region visualization.
- `scripts/cardfront/CardfrontMode.gd` — mode policy/facade for Cardfront identity and compatibility calls.
- `scripts/Battlefield.gd` — owns generic owner grids, owner counts, painting, and draw color overrides.
- `scripts/WinConditionEvaluator.gd` — adds Cardfront win evaluation beside the existing BallWar modes.
- `scripts/Main.gd` — stays orchestration-only and delegates Cardfront rules to `scripts/cardfront/`.

Detailed milestone notes:

- [docs/历史_history/README_v0_1_6_2_cardfront_control_chamber_decoupling.md](docs/历史_history/README_v0_1_6_2_cardfront_control_chamber_decoupling.md)
- [docs/历史_history/README_v0_1_6_1_cardfront_fire_director.md](docs/历史_history/README_v0_1_6_1_cardfront_fire_director.md)
- [docs/历史_history/README_v0_1_6_1_pioneer_beacon_lite.md](docs/历史_history/README_v0_1_6_1_pioneer_beacon_lite.md)
- [docs/历史_history/README_v0_1_6_first_card_effects.md](docs/历史_history/README_v0_1_6_first_card_effects.md)
- [docs/历史_history/README_v0_1_5_card_core_lite.md](docs/历史_history/README_v0_1_5_card_core_lite.md)
- [docs/历史_history/README_v0_1_4_fortify_layer.md](docs/历史_history/README_v0_1_4_fortify_layer.md)
- [docs/历史_history/README_v0_1_3_2_cardfront_debug_panel_placement.md](docs/历史_history/README_v0_1_3_2_cardfront_debug_panel_placement.md)
- [docs/历史_history/README_v0_1_3_1_visual_pressure_rebalance.md](docs/历史_history/README_v0_1_3_1_visual_pressure_rebalance.md)
- [docs/历史_history/README_v0_1_3_deployment_rules.md](docs/历史_history/README_v0_1_3_deployment_rules.md)
- [docs/历史_history/README_v0_1_2_region_morale.md](docs/历史_history/README_v0_1_2_region_morale.md)
- [docs/历史_history/README_v0_1_2_1_cardfront_visibility_polish.md](docs/历史_history/README_v0_1_2_1_cardfront_visibility_polish.md)
- [docs/历史_history/README_v0_1_1_region_instances.md](docs/历史_history/README_v0_1_1_region_instances.md)
- [docs/历史_history/README_v0_1_1_region_yield.md](docs/历史_history/README_v0_1_1_region_yield.md)
- [docs/历史_history/README_v0_1_1_region_map.md](docs/历史_history/README_v0_1_1_region_map.md)
- [docs/历史_history/README_v0_1_0_cardfront_prototype.md](docs/历史_history/README_v0_1_0_cardfront_prototype.md)

## Validation / 验证

Run with Godot 4.6:

CI gate: [`.github/workflows/headless-tests.yml`](.github/workflows/headless-tests.yml) runs these as batch jobs on push and pull request.

```powershell
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontPerformanceSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontBottomHudStatusTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontVfxLayerTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontVisibleEffectBridgeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontRuntimeSnapshotTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontRuntimeBuilderTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DeviceOverlayLayerTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DeviceCoreTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/AbsorberCoreLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EngineerBotLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DurablePioneerBeaconTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/FortifyLayerTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardEffectResolverTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardCoreLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardFirstEffectsTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontFireDirectorTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontFireDirectorTurretIntegrationTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontControlChamberDecouplingTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/PioneerBeaconLiteTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontTargetBiasTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/NeutralOwnerCompatibilityTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/DeploymentRulesTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMoraleTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EconomyTickTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontVisualPolicyTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/VisualPressurePolicyTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMapTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontFormalUITestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontTargetPreviewTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontUiAssetRegistryTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

Current checks run in `.github/workflows/headless-tests.yml`, `b1-simulation-tests.yml`, and `shared-upgrade-ai-tests.yml`. The old v0.2.5.2 local assertion-count snapshot is historical and no longer a valid current test inventory.

## Project Status / 项目状态

See [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md). No other document maintains the current milestone or next step.

MIT License. See [LICENSE](LICENSE).
