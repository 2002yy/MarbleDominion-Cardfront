# AI_HANDOFF_CURRENT

Last updated: 2026-05-20
Role / 作用: quick takeover card for Cardfront work / 卡牌前线快速接管卡

## 1. Current Version / 当前版本

- Current line: `v0.1.x` Cardfront prototype
- Current completed slice: `v0.1.8e-bottom-hud-status-polish`
- Next slice: `v0.1.9-cardfront-engineering-closeout`
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
- `CardPlaySystem.gd` now dispatches current effects through a small `effect_registry`; keep future effect growth behind that seam instead of expanding `Main.gd`.
- `CardfrontRuntimeSnapshot.gd` owns the current Cardfront save-schema shape; v0.1.9 audits the schema but does not wire full Cardfront save/load.
- `docs/技术_technical/CARDFRONT_DECOUPLING_PLAN.md` is the current high-coupling split plan. Follow it before adding formal HUD, Deckbuilder, AI, or full Cardfront save/load.
- Old BallWar modes should not create or depend on Cardfront card/effect/fire systems.

## 3. Just Completed / 刚完成的内容

- `CardfrontStatusFormatter.gd` — builds status line: 射击ON | 设备 counts | 卡牌 hand | 校准区域 | VFX ON.
- Bottom HUD (`fps_label`) refreshed every 0.25s with live Cardfront status.
- `CardfrontBottomHudStatusTestRunner.gd` (10 checks): verifies device counts, bias info, BallWar isolation.
- `CardfrontPerformanceSmokeTestRunner.gd` (7 checks): 40×40/50×50 perf smoke.
- Dirty-redraw optimizations for RegionOverlay and FortifyOverlay.
- ShotGuideLayer debug text moved out of battlefield layer.
- Bottom HUD fully retained and visible in both Cardfront and BallWar modes.

## 4. Next Steps / 下一步

Ship `v0.1.9-cardfront-engineering-closeout` only:

- version sync
- CI batch gate in `.github/workflows/headless-tests.yml`
- test matrix update
- `CardfrontPerformanceSmokeTestRunner.gd` as the performance budget gate
- `CardfrontRuntimeSnapshotTestRunner.gd` save-schema audit
- `CardPlaySystem.gd` effect registry pre-split
- README / ROADMAP / AI handoff alignment
- high-coupling split plan captured in `docs/技术_technical/CARDFRONT_DECOUPLING_PLAN.md`

Do not turn this into Deckbuilder or AI Commander work.

## 5. Do Not Do / 不要做什么

- Do not add formal card UI in this line unless explicitly requested.
- Do not add deck draw, discard, shuffle, or deckbuilding.
- Do not add AI Commander behavior.
- Do not add new full unit systems outside the planned device slice.
- Do not expand absorber core or engineer bot beyond current lite behavior unless the next slice explicitly owns tuning.
- Do not use AI-generated images for this work.
- Do not change old BallWar mode rules to satisfy Cardfront tests.
- Do not push effect logic into `Main.gd`.
- Do not turn Pioneer Beacon Lite into a durable map entity until the unit-device slice explicitly owns that work.
- Do not re-enable legacy control chambers as the Cardfront primary shooting interface unless a future slice explicitly designs a new Cardfront-specific control surface.

## 6. Required Tests / 当前必跑测试

Cardfront first-effect baseline:

- `DeviceCoreTestRunner.gd`
- `AbsorberCoreLiteTestRunner.gd`
- `CardCoreLiteTestRunner.gd`
- `CardFirstEffectsTestRunner.gd`
- `CardfrontTargetBiasTestRunner.gd`
- `PioneerBeaconLiteTestRunner.gd`
- `CardfrontRuntimeSnapshotTestRunner.gd`
- `CardfrontFireDirectorTestRunner.gd`
- `CardfrontFireDirectorTurretIntegrationTestRunner.gd`
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
- `CardfrontBottomHudStatusTestRunner.gd`
- `CardfrontVfxLayerTestRunner.gd`
- `CardfrontVisibleEffectBridgeTestRunner.gd`

Performance probes are separate from correctness:

- `CardfrontPerformanceSmokeTestRunner.gd`
- `PerfBurstBenchmark.gd`
- `PerfBurstBenchmarkSingleTurret.gd`
- `PerfBurstBenchmarkMultiTurret.gd`

## 7. Canonical Docs / 主文档分工

- `README.md` — current project entrypoint / 项目入口
- `docs/ROADMAP.md` — main progress board and next slice / 进度板与下一切片
- `docs/历史_history/README_v0_1_6_first_card_effects.md` — v0.1.6 detailed stage record
- `docs/历史_history/README_v0_1_6_1_pioneer_beacon_lite.md` — Pioneer Beacon Lite stage record
- `docs/历史_history/README_v0_1_6_1_cardfront_fire_director.md` — Cardfront Fire Director stage record
- `docs/历史_history/README_v0_1_6_2_cardfront_control_chamber_decoupling.md` — Cardfront control-chamber decoupling stage record
- `docs/历史_history/README.md` — historical stage index / 历史阶段索引
- `docs/技术_technical/AI_HANDOFF_CURRENT.md` — quick takeover card for the next AI / Codex session
- `docs/技术_technical/CARDFRONT_DECOUPLING_PLAN.md` — Cardfront high-coupling split order
- `docs/TESTING.md` — test ownership, baseline, and run guidance
