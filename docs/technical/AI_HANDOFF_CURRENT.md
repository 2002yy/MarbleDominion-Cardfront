# AI_HANDOFF_CURRENT

Last updated: 2026-05-19
Role / 作用: quick takeover card for Cardfront work / 卡牌前线快速接管卡

## 1. Current Version / 当前版本

- Current line: `v0.1.x` Cardfront prototype
- Current completed slice: `v0.1.6-first-card-effects`
- Next slice: `v0.1.6.1-pioneer-beacon-lite`
- Foundation baseline: BallWar / Marble Dominion Ricochet War `v2.1.11.1`

## 2. Current Status / 当前状态

- Cardfront is a sidecar mode assembled through `CardfrontMode.gd`; do not move Cardfront rules into `Main.gd`.
- `CardPlaySystem.gd` owns card play: fixed hand, resource payment, target validation, effect dispatch, and rollback on effect failure.
- Active card catalog:
  - Frontline Fortify / `fortify_border`: adds stacks through `FortifyLayer`.
  - Calibrated Shot / `calibrated_shot`: registers `CardfrontTargetBiasSystem` region bias.
  - Morale Fluctuation / `morale_fluctuation`: calls `RegionMoraleSystem.apply_morale(..., SUPPORT_PLAYER)`.
- `CardfrontTargetBiasSystem.gd` is Cardfront-only state. It is testable now, but it does not yet steer turret aim.
- `GameRuntimeContext.gd` has `target_bias_system`; `Main.gd` only creates and passes it through.
- Old BallWar modes should not create or depend on Cardfront card/effect systems.

## 3. Just Completed / 刚完成的内容

- Implemented real Morale Fluctuation effect with failure handling for missing morale system, invalid region id, and `apply_morale(...) == false`.
- Implemented Calibrated Shot first effect by adding a duration-based target-bias system.
- Added rollback coverage for effect failures after resource payment and hand-used marking.
- Added `CardFirstEffectsTestRunner.gd` and `CardfrontTargetBiasTestRunner.gd`.
- Updated `CardCoreLiteTestRunner.gd` and `CardfrontModeSmokeTestRunner.gd` for v0.1.6 behavior.
- Updated `README.md`, `docs/ROADMAP.md`, and `docs/history/README_v0_1_6_first_card_effects.md`.

## 4. Next Steps / 下一步

1. `v0.1.6.1-pioneer-beacon-lite`: define the smallest Pioneer Beacon effect with explicit state and tests.
2. Decide whether Calibrated Shot should later influence turret target selection or a separate aiming adapter; keep that integration outside `Bullet`, `BulletPool`, `Turret`, and `ControlChamber` until the seam is clear.
3. Keep formal card UI, draw/discard/shuffle, AI Commander, and full unit devices deferred.
4. If another Cardfront effect is added, preserve the current rollback contract: failed effect resolution must restore resources and hand state.

## 5. Do Not Do / 不要做什么

- Do not add formal card UI in this line unless explicitly requested.
- Do not add deck draw, discard, shuffle, or deckbuilding.
- Do not add AI Commander behavior.
- Do not add bullet absorber core, engineer robot, or full unit systems during a card-effect slice.
- Do not use AI-generated images for this work.
- Do not change old BallWar mode rules to satisfy Cardfront tests.
- Do not push effect logic into `Main.gd`.

## 6. Required Tests / 当前必跑测试

Cardfront first-effect baseline:

- `CardCoreLiteTestRunner.gd`
- `CardFirstEffectsTestRunner.gd`
- `CardfrontTargetBiasTestRunner.gd`
- `RegionMoraleTestRunner.gd`
- `FortifyLayerTestRunner.gd`
- `DeploymentRulesTestRunner.gd`
- `EconomyTickTestRunner.gd`
- `CardfrontModeSmokeTestRunner.gd`

Runtime smoke baseline:

- `SmokeTestRunner.gd`
- `IntegrationTestRunner.gd`

Helpful wider Cardfront checks when touching region or mode assembly:

- `RegionMapTestRunner.gd`
- `NeutralOwnerCompatibilityTestRunner.gd`
- `EconomyDebugPanelSceneTestRunner.gd`
- `CardfrontVisualPolicyTestRunner.gd`

Performance probes are separate from correctness:

- `PerfBurstBenchmark.gd`
- `PerfBurstBenchmarkSingleTurret.gd`
- `PerfBurstBenchmarkMultiTurret.gd`

## 7. Canonical Docs / 主文档分工

- `README.md` — current project entrypoint / 项目入口
- `docs/ROADMAP.md` — main progress board and next slice / 进度板与下一切片
- `docs/history/README_v0_1_6_first_card_effects.md` — v0.1.6 detailed stage record
- `docs/history/README.md` — historical stage index / 历史阶段索引
- `docs/technical/AI_HANDOFF_CURRENT.md` — quick takeover card for the next AI / Codex session
- `docs/TESTING.md` — test ownership, baseline, and run guidance
