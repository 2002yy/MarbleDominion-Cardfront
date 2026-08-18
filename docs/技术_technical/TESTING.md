# Testing / 测试

Date: 2026-07-23
Role: test matrix and run guidance / 测试矩阵与运行建议

## Correctness Baseline / 正确性基线

Baseline BallWar runtime runners:

| Runner | Expected checks | Category |
|---|---:|---|
| `LayoutSanityTestRunner.gd` | 376 | Layout boundary |
| `SmokeTestRunner.gd` | 215 | Smoke / fast regression |
| `SaveFlowControllerTestRunner.gd` | 190 | Save/load orchestration |
| `IntegrationTestRunner.gd` | 133 | Cross-system correctness |
| `StartMenuSceneTestRunner.gd` | 55 | Scene wiring |
| `GameStateCoordinatorTestRunner.gd` | 50 | Gameplay state flow |
| `GameHUDSceneTestRunner.gd` | 40 | Scene wiring |
| `EventRouletteSceneTestRunner.gd` | 14 | Scene wiring |
| `RestorePlanTestRunner.gd` | 11 | Restore planning |
| `SettingsPanelSceneTestRunner.gd` | 9 | Scene wiring |

Baseline subtotal: **1093 expected checks** across 10 runners.

## Cardfront CI Batches / 卡牌前线 CI 批次

`.github/workflows/headless-tests.yml` runs parse/import warmup plus the following batches on every push and pull request:

| CI batch | Runners |
|---|---|
| Baseline runtime | `SmokeTestRunner`, `IntegrationTestRunner`, `LayoutSanityTestRunner`, scene wiring, state, save, restore |
| Cardfront map economy | `RegionMapTestRunner`, `NeutralOwnerCompatibilityTestRunner`, `DeploymentRulesTestRunner`, `RegionMoraleTestRunner`, `EconomyTickTestRunner`, `EconomyDebugPanelSceneTestRunner`, visual pressure policy tests |
| Cardfront cards effects fire | `FortifyLayerTestRunner`, `CardEffectResolverTestRunner`, `CardCoreLiteTestRunner`, `CardFirstEffectsTestRunner`, `CardfrontTargetBiasTestRunner`, `PioneerBeaconLiteTestRunner`, FireDirector tests, control-chamber decoupling |
| Cardfront devices visuals schema | device core/effect runners, device overlay, bottom HUD status, VFX bridge, `CardfrontRuntimeSnapshotTestRunner` |
| Cardfront performance budget | `CardfrontPerformanceSmokeTestRunner` |
| Cardfront v0.3 core loop | `CardfrontUpgradeContentTestRunner`, `CardfrontMatchPhaseControllerTestRunner`, `CardfrontUpgradeResolverTestRunner` |
| Cardfront v0.3 arena spike | `CardfrontArenaLayoutTestRunner`, `CardfrontDirectionControllerTestRunner`, `CardfrontArenaRuntimeTestRunner`, `CardfrontOrthographicArenaTestRunner`, `CardfrontEighteenCardReadabilityTestRunner` |
| Cardfront v0.3 three-choice slice | `CardfrontThreeChoiceRuntimeTestRunner`, `CardfrontRoundCombatTestRunner`, `CardfrontModeSmokeTestRunner` |
| Cardfront v0.3 tactical strongholds | `CardfrontStrongholdSystemTestRunner`, `CardfrontMapDefinitionTestRunner`, `CardfrontUpgradeContentTestRunner`, `CardfrontThreeChoiceRuntimeTestRunner` |
| Cardfront v0.3 vertical-slice closeout | `CardfrontTerritoryDefenseTestRunner`, `CardfrontVerticalSliceFeedbackTestRunner`, `CardfrontLiveRuntimeBoundaryTestRunner`, `CardfrontPerformanceSmokeTestRunner` |

The v0.1.9 engineering closeout treats local-only Cardfront success as incomplete until the relevant runner is also present in `headless-tests.yml`.

## Performance Probes / 性能探针

Correctness gate:

- `CardfrontPerformanceSmokeTestRunner.gd` — lightweight budget guard for Cardfront overlay redraw, shot-guide debug cleanup, and 40x40 / 50x50 startup pressure.

Manual or release-evidence probes:

- `PerfBurstBenchmark.gd` — full suite.
- `PerfBurstBenchmarkSingleTurret.gd` — single-turret half.
- `PerfBurstBenchmarkMultiTurret.gd` — multi-turret half.

Run the benchmark probes when tuning firing or pressure policies, collecting release evidence, or checking trail/pool behavior. They are not a substitute for the correctness batches above.

## Test Infrastructure / 测试基础设施

- `scripts/tests/TestAssert.gd`
- `scripts/tests/TestFixtures.gd`

## What To Run / 改动后跑什么

### Editing the v0.3 draft, run state, or volley contract

1. `CardfrontUpgradeContentTestRunner.gd`.
2. `CardfrontMatchPhaseControllerTestRunner.gd`.
3. `CardfrontUpgradeResolverTestRunner.gd`.
4. `SmokeTestRunner.gd`.
5. `IntegrationTestRunner.gd`.

### Editing the v0.3 arena, turret direction, or aim UI

1. `CardfrontArenaLayoutTestRunner.gd`.
2. `CardfrontDirectionControllerTestRunner.gd`.
3. `CardfrontArenaRuntimeTestRunner.gd`.
4. `CardfrontOrthographicArenaTestRunner.gd`.
5. `CardfrontEighteenCardReadabilityTestRunner.gd` when formal card or combat readability changes.
6. `CardfrontFireDirectorTurretIntegrationTestRunner.gd`.
7. `CardfrontModeSmokeTestRunner.gd`.
8. `LayoutSanityTestRunner.gd`, `SmokeTestRunner.gd`, and `IntegrationTestRunner.gd` when shared runtime surfaces change.

### Editing the live three-choice loop, automatic volley, or command-chamber victory

1. `CardfrontThreeChoiceRuntimeTestRunner.gd`.
2. `CardfrontRoundCombatTestRunner.gd`.
3. `CardfrontUpgradeResolverTestRunner.gd`.
4. `CardfrontModeSmokeTestRunner.gd`.
5. `CardfrontUiClickThroughTestRunner.gd`.
6. `CardfrontMatchFlowClarityTestRunner.gd`.

### Editing territory defense, chamber feedback, tuning, or live runtime assembly

1. `CardfrontTerritoryDefenseTestRunner.gd`.
2. `CardfrontVerticalSliceFeedbackTestRunner.gd`.
3. `CardfrontLiveRuntimeBoundaryTestRunner.gd`.
4. `CardfrontThreeChoiceRuntimeTestRunner.gd`.
5. `CardfrontModeSmokeTestRunner.gd`.
6. `CardfrontPerformanceSmokeTestRunner.gd`.

Tests for retired v0.2 card/economy/device UI must explicitly set `cardfront_legacy_compatibility_enabled = true` before starting Cardfront. New live-path tests must leave it false.
7. `LayoutSanityTestRunner.gd`, `SmokeTestRunner.gd`, and `IntegrationTestRunner.gd` when shared runtime surfaces change.

### Editing `.tscn` or UI wiring

1. Scene wiring tests.
2. `LayoutSanityTestRunner.gd`.
3. `SmokeTestRunner.gd`.

### Editing save/load or continue orchestration

1. `SaveFlowControllerTestRunner.gd`.
2. `RestorePlanTestRunner.gd`.
3. `IntegrationTestRunner.gd`.
4. `SmokeTestRunner.gd`.

### Editing Cardfront map, economy, morale, or deployment rules

1. The matching Cardfront map economy batch runner.
2. `CardfrontModeSmokeTestRunner.gd`.
3. `SmokeTestRunner.gd` if shared runtime surfaces changed.

### Editing cards, effects, or FireDirector

1. `CardCoreLiteTestRunner.gd`.
2. `CardEffectResolverTestRunner.gd`.
3. `CardFirstEffectsTestRunner.gd`.
4. Relevant effect runner such as `PioneerBeaconLiteTestRunner.gd`.
5. Relevant FireDirector runner if shooting or target bias changed.

### Editing device visuals or Cardfront HUD status

1. `DeviceCoreTestRunner.gd`.
2. `DeviceOverlayLayerTestRunner.gd`.
3. `CardfrontBottomHudStatusTestRunner.gd`.
4. `CardfrontVfxLayerTestRunner.gd` or `CardfrontVisibleEffectBridgeTestRunner.gd` when VFX paths change.

### Editing Cardfront save schema

1. `CardfrontRuntimeSnapshotTestRunner.gd`.
2. `NeutralOwnerCompatibilityTestRunner.gd` if owner encoding changes.
3. `SaveFlowControllerTestRunner.gd` once Cardfront save/load wiring becomes active.

## CI / GitHub Actions

Workflow file: `.github/workflows/headless-tests.yml`  
Workflow name: `Headless Tests`

The workflow uses batch matrix jobs so Cardfront additions are automatic gates instead of local-only claims.
