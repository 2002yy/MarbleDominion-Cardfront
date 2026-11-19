# Marble Dominion: Cardfront / 弹珠领土：卡牌前线

**Godot 4.6 + GDScript** prototype built from the BallWar / Marble Dominion Ricochet War foundation.

Cardfront is a controlled prototype branch for turning BallWar's marble territory-control arena into a strategy game:

> 调整炮口 -> 暂停三选一 -> 自动齐射 -> 争夺路线与防御 -> 摧毁敌方控制舱。

Current version, active implementation slice, next step, and deferred scope are maintained only in [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md).
当前版本与实施进度只在 [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md) 维护。

## Live v0.3 Loop / 当前主玩法

The default Cardfront runtime is the lean 1v1 loop: manual aim, paused three-choice upgrade, simultaneous automatic volleys, visible per-cell territory defense, and 40-health command chambers. The former fixed four-card hand, Energy/Parts economy, morale, card/device effects, and dedicated compatibility runtime have been retired.

当前默认 Cardfront 只装配“瞄准 -> 暂停三选一 -> 双方自动齐射 -> 领土护甲 -> 摧毁控制舱”主循环。旧四卡手牌、经济、士气、装置特效及其测试兼容装配均已退役。

The current arena is still a transitional `Node2D` presentation. `ENERGY`, `FACTORY`, and `LAB` shapes remain visible but do not yet provide live bonuses; the committed next steps are an explicit tactical-stronghold contract followed by a real orthographic `Camera3D` 2.5D arena spike.

当前玩法状态仍由 `Node2D` 权威模拟，但 Cardfront 已使用真正的正交 `Camera3D` 镜像呈现 2.5D 战场。能源/工厂/实验室据点已接入路线与强点规则；`default_duel` 已进入明亮玩具沙盘标杆阶段，后续美术替换只改表现层，不改变格子、闸门、弹体和胜负权威。

## Historical v0.2 Compatibility / 历史兼容代码

v0.2 originally provided a four-card hand, Energy/Parts minibar, card target clicks, resource hints, card detail, toast/audio feedback, and a tutorial overlay. **That player-facing UI has been retired together with its dedicated scenes, adapters, input routes, runtime references, tests, and CI jobs.** The v0.3 three-choice UI is the only active Cardfront choice surface.

旧版固定四卡手牌、资源栏、点格出牌、反馈气泡、教程提示等界面与对应测试已整体退役。现役玩家使用 v0.3 的三选一升级界面。历史实现与设计决策可在 Git 历史和 `docs/历史_history/` 中查阅。

The v0.2 compatibility flag and low-level legacy assembly are also removed. The former targeted-card preview and unconnected 3D deployment-zone display seam are retired as well: the live v0.3 loop has no player-facing targeted deployment selection. The current three-choice round director, fortification, territory defense, Core/Support deployment resolver, and fire director remain in use and continue to be tested.

兼容开关、旧底层模块及从未接入正式三选一的定向部署预览已移除；仍承担现役玩法职责的据点、领土护甲、三选一升级、射击和 Core/Support 部署判定保持不变。

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
- `scripts/cardfront/deployment/` — current Core/Support deployment rules, AI legality evaluation, and automatic placement resolver.
- `scripts/cardfront/strongholds/` and `scripts/cardfront/defense/` — live tactical strongholds and territory defense.
- `scripts/cardfront/run/` and `scripts/cardfront/draft/` — the three-choice draft, battle-phase coordination, and upgrades.
- `scripts/cardfront/fire/` — Cardfront-only fire rules, target scoring, fire intent data, and fire director.
- `scripts/cardfront/runtime/` — Cardfront runtime assembly builder, named refs, and result-to-runtime registry.
- `scripts/cardfront/ui/` — current formal HUD, three-choice panel, and UI assets.
- `scripts/cardfront/regions/RegionOverlayLayer.gd` — lightweight Cardfront-only region visualization.
- `scripts/cardfront/CardfrontMode.gd` — mode policy/facade for the active Cardfront loop.
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
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontModeSmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontLiveRuntimeBoundaryTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontFireDirectorTurretIntegrationTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontDeploymentAuthorityRefreshTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontDeploymentAiParityTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontRuntimeSnapshotTestRunner.gd
```

Current checks run in `.github/workflows/headless-tests.yml`, `b1-simulation-tests.yml`, and `shared-upgrade-ai-tests.yml`. The old v0.2.5.2 local assertion-count snapshot is historical and no longer a valid current test inventory.

## Project Status / 项目状态

See [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md). No other document maintains the current milestone or next step.

MIT License. See [LICENSE](LICENSE).
