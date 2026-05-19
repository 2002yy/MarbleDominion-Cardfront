# AI_HANDOFF_CURRENT

Last updated: 2026-05-19
Role / 作用: quick takeover card for Cardfront work / 卡牌前线快速接管卡

## 1. Current Version / 当前版本

- Current line: `v0.1.x` Cardfront prototype
- Current completed slice: `v0.1.7a-device-core`
- Next slice: `v0.1.7b-absorber-core-lite`
- Foundation baseline: BallWar / Marble Dominion Ricochet War `v2.1.11.1`

## 2. Current Status / 当前状态

- Cardfront is a sidecar mode assembled through `CardfrontMode.gd`; do not move Cardfront rules into `Main.gd`.
- `CardPlaySystem.gd` owns card play: fixed hand, resource payment, target validation, effect dispatch, and rollback on effect failure.
- Active card catalog:
  - Frontline Fortify / `fortify_border`: adds stacks through `FortifyLayer`.
  - Calibrated Shot / `calibrated_shot`: registers `CardfrontTargetBiasSystem` region bias.
  - Morale Fluctuation / `morale_fluctuation`: calls `RegionMoraleSystem.apply_morale(..., SUPPORT_PLAYER)`.
  - Pioneer Beacon / `pioneer_beacon_lite`: converts up to 3 nearby neutral cells from an owned border target.
- `CardfrontTargetBiasSystem.gd` is Cardfront-only state and now feeds the Cardfront fire director target selection.
- `CardfrontFireDirector.gd` is Cardfront-only. It ticks independently, builds `CardfrontFireIntent` records, requests directed turret bursts, and uses global + per-owner shot budgets.
- Cardfront does not create legacy control chambers or +ball buttons; HUD event status shows `自动射击中 / 卡牌改写射击`.
- `GameRuntimeContext.gd` has `target_bias_system` and `fire_director`; `Main.gd` only creates and passes them through.
- Old BallWar modes should not create or depend on Cardfront card/effect/fire systems.

## 3. Just Completed / 刚完成的内容

- Decoupled Cardfront from legacy control chambers and +ball buttons.
- Added Cardfront HUD status text for automatic/card-directed fire.
- Split FireDirector per-second shot cap into `max_total_shots_per_second` and `max_owner_shots_per_second`.
- Added `CardfrontControlChamberDecouplingTestRunner.gd`.
- Updated Cardfront smoke and FireDirector coverage for the control-chamber decoupling and fairness budget paths.
- Updated README, roadmap, changelog, history index, and v0.1.6.2 history docs.

## 4. Next Steps / 下一步

1. `v0.1.7-unit-devices`: design the first durable unit-device boundary after the logic-only Pioneer Beacon and fire-director slices are stable.
2. Decide how device-style systems should interact with FireDirector target scoring and per-owner budgets without pushing strategy logic into `Turret`, `Bullet`, or `BulletPool`.
3. Keep formal card UI, draw/discard/shuffle, and AI Commander deferred.
4. If another Cardfront effect is added, preserve the current rollback contract: failed effect resolution must restore resources and hand state.

## 5. Do Not Do / 不要做什么

- Do not add formal card UI in this line unless explicitly requested.
- Do not add deck draw, discard, shuffle, or deckbuilding.
- Do not add AI Commander behavior.
- Do not add bullet absorber core, engineer robot, or full unit systems during a card-effect slice.
- Do not use AI-generated images for this work.
- Do not change old BallWar mode rules to satisfy Cardfront tests.
- Do not push effect logic into `Main.gd`.
- Do not turn Pioneer Beacon Lite into a durable map entity until the unit-device slice explicitly owns that work.
- Do not re-enable legacy control chambers as the Cardfront primary shooting interface unless a future slice explicitly designs a new Cardfront-specific control surface.

## 6. Required Tests / 当前必跑测试

Cardfront first-effect baseline:

- `DeviceCoreTestRunner.gd`
- `CardCoreLiteTestRunner.gd`
- `CardFirstEffectsTestRunner.gd`
- `CardfrontTargetBiasTestRunner.gd`
- `PioneerBeaconLiteTestRunner.gd`
- `CardfrontFireDirectorTestRunner.gd`
- `CardfrontControlChamberDecouplingTestRunner.gd`
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
- `docs/history/README_v0_1_6_1_pioneer_beacon_lite.md` — Pioneer Beacon Lite stage record
- `docs/history/README_v0_1_6_1_cardfront_fire_director.md` — Cardfront Fire Director stage record
- `docs/history/README_v0_1_6_2_cardfront_control_chamber_decoupling.md` — Cardfront control-chamber decoupling stage record
- `docs/history/README.md` — historical stage index / 历史阶段索引
- `docs/technical/AI_HANDOFF_CURRENT.md` — quick takeover card for the next AI / Codex session
- `docs/TESTING.md` — test ownership, baseline, and run guidance
