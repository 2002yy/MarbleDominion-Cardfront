# Marble Dominion: Cardfront / 弹珠领土：卡牌前线

**Godot 4.6 + GDScript** prototype built from the BallWar / Marble Dominion Ricochet War foundation.

Cardfront is a controlled prototype branch for turning BallWar's marble territory-control arena into a strategy game:

> 占领格子 -> 产生经济 -> 打出卡牌 -> 改写炮塔、地图和单位规则 -> 继续争夺关键区域。

The current completed slice is **v0.2.5.4-card-press-map-readability-pass**.
Current next slice: **v0.2.5.5-windowed-playtest-acceptance**.
Cardfront now has press-and-rebound card feedback plus a symmetric five-stronghold default map. Content expansion stays paused until a windowed hands-on playtest confirms that selection, target feedback, territory changes, and win pressure are understandable end to end.

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
- Minimal card play pipeline with a fixed 4-card hand, resource cost deduction, target validation, and rollback on effect failure.
- Working first cards:
  - Frontline Fortify adds real `FortifyLayer` stacks.
  - Morale Fluctuation calls `RegionMoraleSystem.apply_morale(...)`.
  - Calibrated Shot registers a testable target-region bias for the player.
  - Pioneer Beacon converts up to 3 neutral neighbors around an owned border cell.
- Formal Cardfront HUD:
  - `CardfrontTopResourceBar` shows compact player Energy / Parts icon + value only.
  - `CardfrontHandPanel` shows 4 fixed-hand cards with cost, target type, and affordability states.
  - `CardfrontCardSelectionController` manages click-to-select and card-play dispatch.
- Cardfront interaction feedback:
  - `CardfrontFeedbackBus` carries hover, select, invalid-target, success, and failure events.
  - `CardfrontCardDetailPopup` explains card type, target, costs, effect summary, and usable/resource/used state.
  - `CardfrontToastLayer` shows invalid target, resource shortage, success, and failure feedback without covering the battlefield core.
  - `CardfrontEffectVisualBridge` maps the 4 existing card successes into existing `CardfrontVfxLayer` effects.
- Cardfront debug panel:
  - `CardfrontDebugActionPanel` is hidden by default and toggled through the real F3 input route in Cardfront non-release builds.
  - `CardfrontTopResourceBar` shows a small non-release `F3 Debug` hint at bottom-right (1010, 660); release builds hide both the hint and debug panel route.
  - Old BallWar modes do not create the Cardfront debug action panel.
- Cardfront UI art registry (v0.2.4a):
  - `CardfrontUiAssetRegistry` centralizes Kenney/Wenrexa/Game-Icons/font paths.
  - TopResourceBar uses TextureRect icons (icon_energy/icon_parts SVG) with registry-backed emoji fallback.
  - CardView CardBorder changed to Panel for `card_frame` texture; Bg alpha lowered to 0.40 when `card_bg` exists.
  - All Cardfront UI scenes use registry-backed style/font/icon hooks with ColorRect / StyleBoxFlat fallback.
- Cardfront card thumbnail pass (v0.2.4b):
  - 256px thumbnails generated for cards 1001-1004 under `assets/cardfront_runtime/卡牌插图_cards/256/`.
  - `CardVisualRegistry.gd` extended with `RUNTIME_BASE_THUMB`, `get_thumbnail_path()`, `has_thumbnail()`, and `thumbnail` fields.
  - `CardfrontCardView.gd` uses thumbnail-first loading with fallback chain: thumbnail → 512 full art → placeholder.
  - `get_texture_path()` preserved for hover detail / full-card views.
  - Game-Icons credits preserved in `ASSET_SOURCES_AND_LICENSES.md`.
- Resource bar minibar cleanup (v0.2.4a.1):
  - TopResourceBar simplified: removed Name labels ("能量"/"零件"), removed YieldLabel ("本秒无产出"/"+x/s").
  - Added fallback Symbol labels (⚡/⚙) toggled with TextureRect icons.
  - Container widths halved (360→220) to match compact layout.
  - DebugHint (1010, 660) unchanged.
  - No gameplay or card-value changes.
- Card click hitbox feedback hotfix (v0.2.4a.2):
  - `CardfrontHandPanel` gives `CardHBox` a real 4-card hitbox and `MOUSE_FILTER_PASS`; decorative panel nodes ignore mouse input.
  - `CardfrontCardView` emits `card_clicked` before availability checks.
  - Resource-disabled cards emit `card_play_failed` with `not_enough_resource`; used cards emit `card_play_failed` with `card_already_used`.
  - Disabled/used cards do not call the selection callback and do not enter selected state.
- Content foundation (v0.2.5):
  - `CardfrontContentManifest.gd` centralizes the existing 4 card definitions, costs, target types, effect IDs, effect params, visual IDs, default hand, and test coverage metadata.
  - `CardCatalog.gd` and `CardVisualRegistry.gd` now read from the manifest.
  - Existing card effects read params from card data while preserving the current values and behavior.
  - `CardTargetValidator.gd` plus `CardTargetRuleRegistry.gd` move current target checks out of `CardPlaySystem.gd`.
  - `CardfrontMapDefinition`, `CardfrontMapRegistry`, and `CardfrontMapBuilder` move default layout data behind map definitions.
  - CI includes content validation, target validator, and map definition runners.
- Content boundary hardening (v0.2.5.1):
  - Current cards may only use implemented target rules: `owned_border`, `owned_region`, and `enemy_region`.
  - Reserved target types stay declared but fail validation if used before a target rule and tests exist.
  - `RegionMap` exposes public map-paint APIs for `CardfrontMapBuilder`.
- Runtime builder split (v0.2.5.2):
  - `scripts/cardfront/runtime/` adds `CardfrontRuntimeBuilder`, `CardfrontSystemRegistry`, and `CardfrontRuntimeRefs`.
  - `Main.gd` now creates Cardfront core systems and battlefield layers through grouped runtime-builder entrypoints.
  - `CardfrontMode.gd` remains a compatibility/policy facade for older tests and call sites.
- Playability and region readability pass (v0.2.5.3):
  - Fixed the full-screen `MainBackground` consuming battlefield clicks; decorative Cardfront HUD, toast, and resource controls now pass mouse input through.
  - Battlefield click routing uses the active event position transformed into canvas/world coordinates, which works reliably in embedded and stretched windows.
  - `RegionControlBlockLayer` renders each contested resource region as a unified cartoon block with a dark outer stroke, faction-color inner stroke, and a large `玩家/AI/中立 XX%` badge.
  - Region blocks rebuild only from score-change dirty signals; they do not redraw every frame.
  - Real-input CI covers card click -> selection -> valid battlefield click -> card play.
- Card press and map readability pass (v0.2.5.4):
  - Card presses compress to `0.94` scale and move down briefly, then rebound to the correct hover/selected/rest pose on release.
  - The default map is now five separate strongholds: mirrored Energy/Factory blocks around one large central Lab.
  - Strongholds do not overlap or touch, remain rotationally symmetric, and scale cleanly across supported grid sizes.
  - Region badges now include strategic type plus control state, for example `能源 · 玩家 64%`.
- Cardfront card interaction hotfix:
  - `CardfrontCardView.tscn` root uses `MOUSE_FILTER_STOP`; decorative children use `MOUSE_FILTER_IGNORE`.
  - `CardfrontCardViewInteractionConfigTestRunner.gd` verifies hover/click signal routing to `CardfrontFeedbackBus`.
- Cardfront fire director:
  - Generates low-frequency `CardfrontFireIntent` records.
  - Prioritizes target bias from Calibrated Shot when present.
  - Falls back to neutral-boundary and resource-region scoring.
  - Enforces both global and per-owner hard per-second shot budgets.
- Cardfront-only translucent region overlay.
- Cardfront mode starts with only two turrets; legacy control chambers and +ball buttons are skipped in this mode.
- Cardfront HUD shows `自动射击中 / 卡牌改写射击` in the former event-status slot.
- Event roulette is disabled in Cardfront mode; active card play will replace it later.
- Cardfront win rules:
  - 70% capture wins immediately.
  - 8-minute timer ends by player/AI territory lead.
  - Equal player/AI territory at timer is a draw.
- New headless runner: `CardfrontModeSmokeTestRunner.gd`.
- New headless runner: `RegionMapTestRunner.gd`.
- New headless runner: `DeploymentRulesTestRunner.gd`.
- New headless runner: `CardfrontFireDirectorTestRunner.gd`.
- New headless runner: `CardfrontControlChamberDecouplingTestRunner.gd`.
- New headless runner: `PioneerBeaconLiteTestRunner.gd`.
- New headless runners include `CardfrontRegionControlBlockTestRunner.gd` and `CardfrontUiClickThroughTestRunner.gd`, alongside the existing formal UI, feedback, hitbox, and asset runners.

Not implemented yet:

- Deckbuilder and AI Commander remain deferred.
- Cardfront save/load integration remains deferred; schema shape is audited in `CardfrontRuntimeSnapshot.gd` but not wired.
- Final device tuning, animation polish.

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
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/EconomyDebugPanelSceneTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontVisualPolicyTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/VisualPressurePolicyTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/RegionMapTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontFormalUITestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontTargetPreviewTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontBattlefieldClickSelectionTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontCardDetailPopupTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontCardFeedbackTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontDisabledCardFeedbackTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontToastLayerTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontEffectVisualBridgeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontDebugPanelToggleTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontUiAssetRegistryTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontUiArtSceneTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontCardViewInteractionConfigTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontHandRealHitboxTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/CardfrontTopResourceBarMinimalTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
E:\Godot\Godot_\Godot_console.exe --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
```

Latest local validation for v0.2.5.2-runtime-builder-split:

- Headless parse check: passed.
- `CardfrontRuntimeBuilderTestRunner.gd`: 22 checks passed.
- `CardfrontModeSmokeTestRunner.gd`: 38 checks passed.
- `CardfrontContentValidationTestRunner.gd`: 108 checks passed.
- `CardfrontMapDefinitionTestRunner.gd`: 28 checks passed.
- `RegionMapTestRunner.gd`: 3737 checks passed.
- `CardCoreLiteTestRunner.gd`: 40 checks passed.
- `CardfrontTargetValidatorTestRunner.gd`: 9 checks passed.
- `CardfrontTargetPreviewTestRunner.gd`: 13 checks passed.
- `CardfrontBattlefieldClickSelectionTestRunner.gd`: 16 checks passed.
- `CardfrontFormalUITestRunner.gd`: 48 checks passed.
- `CardfrontRuntimeSnapshotTestRunner.gd`: 14 checks passed.
- `CardfrontFireDirectorTestRunner.gd`: 21 checks passed.
- `CardfrontFireDirectorTurretIntegrationTestRunner.gd`: 16 checks passed.
- `CardfrontFireDirectorSignalTestRunner.gd`: 22 checks passed.
- `SmokeTestRunner.gd`: 215 checks passed.
- `IntegrationTestRunner.gd`: 133 checks passed.

## Next Milestone / 下一阶段

`v0.2.5a-8-card-catalog-on-manifest`: expand toward 8 cards only through `CardfrontContentManifest`, implemented target rules, and focused tests. Keep Deckbuilder, AI Commander, card-value churn, and full Cardfront save/load deferred.

MIT License. See [LICENSE](LICENSE).
