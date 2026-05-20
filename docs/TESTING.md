# Testing / 测试

Date: 2026-05-20  
Role: test matrix and run guidance / 测试矩阵与运行建议

## Correctness Baseline / 正确性基线

Baseline BallWar runtime runners:

| Runner | Expected checks | Category |
|---|---:|---|
| `LayoutSanityTestRunner.gd` | 376 | Layout boundary |
| `SmokeTestRunner.gd` | 218 | Smoke / fast regression |
| `SaveFlowControllerTestRunner.gd` | 190 | Save/load orchestration |
| `IntegrationTestRunner.gd` | 133 | Cross-system correctness |
| `StartMenuSceneTestRunner.gd` | 55 | Scene wiring |
| `GameStateCoordinatorTestRunner.gd` | 50 | Gameplay state flow |
| `GameHUDSceneTestRunner.gd` | 40 | Scene wiring |
| `EventRouletteSceneTestRunner.gd` | 14 | Scene wiring |
| `RestorePlanTestRunner.gd` | 11 | Restore planning |
| `SettingsPanelSceneTestRunner.gd` | 9 | Scene wiring |

Baseline subtotal: **1096 expected checks** across 10 runners.

## Cardfront CI Batches / 卡牌前线 CI 批次

`.github/workflows/headless-tests.yml` runs parse/import warmup plus the following batches on every push and pull request:

| CI batch | Runners |
|---|---|
| Baseline runtime | `SmokeTestRunner`, `IntegrationTestRunner`, `LayoutSanityTestRunner`, scene wiring, state, save, restore |
| Cardfront map economy | `RegionMapTestRunner`, `NeutralOwnerCompatibilityTestRunner`, `DeploymentRulesTestRunner`, `RegionMoraleTestRunner`, `EconomyTickTestRunner`, `EconomyDebugPanelSceneTestRunner`, visual pressure policy tests |
| Cardfront cards effects fire | `FortifyLayerTestRunner`, `CardEffectResolverTestRunner`, `CardCoreLiteTestRunner`, `CardFirstEffectsTestRunner`, `CardfrontTargetBiasTestRunner`, `PioneerBeaconLiteTestRunner`, FireDirector tests, control-chamber decoupling |
| Cardfront devices visuals schema | device core/effect runners, device overlay, bottom HUD status, VFX bridge, `CardfrontRuntimeSnapshotTestRunner` |
| Cardfront performance budget | `CardfrontPerformanceSmokeTestRunner` |

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
