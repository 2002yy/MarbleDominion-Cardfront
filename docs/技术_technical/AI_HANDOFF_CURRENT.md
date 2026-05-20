# AI_HANDOFF_CURRENT

Last updated: 2026-05-20
Role / 作用: quick takeover card for Cardfront work / 卡牌前线快速接管卡

## 1. Current Version / 当前版本

- Current line: `v0.2.x` Cardfront formal UI
- Current completed slice: `v0.1.9-cardfront-engineering-closeout`
- Current slice: `v0.2.0b-fix-formal-ui-and-signal-ci`
- Foundation baseline: BallWar / Marble Dominion Ricochet War `v2.1.11.1`

## 2. Current Status / 当前状态

- Cardfront is a sidecar mode assembled through `CardfrontMode.gd`; do not move Cardfront rules into `Main.gd`.
- `CardPlaySystem.gd` owns card play: fixed hand, resource payment, target validation, effect dispatch, and rollback on effect failure.
- Active card catalog remains 4 fixed cards (Frontline Fortify, Calibrated Shot, Morale Fluctuation, Pioneer Beacon).
- `CardfrontFireDirector.gd` now has 4 signals: `fire_tick`, `fire_requested`, `fire_issued`, `fire_skipped`. External listeners can hook into fire events without touching director internals.
- Formal HUD components now replace debug panels:
  - `CardfrontTopResourceBar.gd` — top-left Energy/Parts display, signal-driven refresh via `economy_system.resources_changed`.
  - `CardfrontHandPanel.gd` — bottom-center 4-card hand panel with `CardfrontCardView` children, signal-driven refresh via `economy_system.resources_changed`.
  - `CardfrontCardSelectionController.gd` — click→select→target→`CardPlaySystem.play()` flow.
- `RegionOverlayLayer.gd` now caches overlay as `ImageTexture` via `Sprite2D`; region layout is static, `mark_dirty()` is a no-op.
- `FortifyOverlayLayer.gd` caches overlay as `ImageTexture`; rebuilds only on `mark_dirty()` (stack change).
- `CardfrontEconomyDebugPanel.gd` still exists but is no longer the primary resource display.
- Cardfront does not create legacy control chambers or +ball buttons.
- Old BallWar modes should not create or depend on Cardfront card/effect/fire systems.

## 3. Just Completed / 刚完成的内容

- v0.1.9 engineering closeout: version sync, CI batch matrix, snapshot audit, effect resolver split, doc alignment.
- FireDirector signal seams: `fire_tick`/`fire_requested`/`fire_issued`/`fire_skipped` with `CardfrontFireDirectorSignalTestRunner.gd` (8 tests).
- RegionOverlay / FortifyOverlay ImageTexture caching: eliminate per-cell draw_rect iteration.
- Formal HUD: `CardfrontTopResourceBar`, `CardfrontHandPanel`, `CardfrontCardView`, `CardfrontCardSelectionController`.
- `CardfrontFormalUITestRunner.gd` (7 tests): resource bar visibility, hand panel, card click, card play resource consumption, BallWar isolation.
- Event log panel (`EventLogLabel` + `EventLogToggle`) removed from all modes.

## 4. Next Steps / 下一步

Ship `v0.2.0b-fix-formal-ui-and-signal-ci`:

- Fix `CardfrontCardView.gd` missing `_create_children()` body.
- Fix `CardfrontFireDirectorSignalTestRunner.gd` fixture/collector variable errors.
- Add `CardfrontFormalUITestRunner.gd` and `CardfrontFireDirectorSignalTestRunner.gd` to CI batch matrix.
- Update README / ROADMAP / AI_HANDOFF to reflect v0.2.x formal UI line.

Beyond v0.2.0b:

- `v0.2.1-target-preview`: highlight valid target cells when a card is selected.
- `v0.2.2-cardfront-hud-builder`: formal `CardfrontHudBuilder.gd` and `CardfrontSystemRegistry.gd`.
- Deckbuilder, AI Commander, and full Cardfront save/load remain deferred.

## 5. Do Not Do / 不要做什么

- Do not add Deckbuilder, deck draw/discard/shuffle.
- Do not add AI Commander behavior.
- Do not add full Cardfront save/load wiring.
- Do not change FireDirector fire rate or budget rules.
- Do not push effect logic into `Main.gd`.
- Do not change old BallWar mode rules to satisfy Cardfront tests.
- Do not re-enable legacy control chambers as the Cardfront primary shooting interface.

## 6. Required Tests / 当前必跑测试

Cardfront formal UI + signal baseline:

- `CardfrontFireDirectorSignalTestRunner.gd`
- `CardfrontFireDirectorTestRunner.gd`
- `CardfrontFormalUITestRunner.gd`
- `CardfrontModeSmokeTestRunner.gd`
- `CardfrontFireDirectorTurretIntegrationTestRunner.gd`
- `CardfrontControlChamberDecouplingTestRunner.gd`

Cardfront effect + card baseline:

- `CardEffectResolverTestRunner.gd`
- `CardCoreLiteTestRunner.gd`
- `CardFirstEffectsTestRunner.gd`
- `CardfrontTargetBiasTestRunner.gd`
- `PioneerBeaconLiteTestRunner.gd`
- `FortifyLayerTestRunner.gd`

Cardfront device baseline:

- `DeviceCoreTestRunner.gd`
- `AbsorberCoreLiteTestRunner.gd`
- `EngineerBotLiteTestRunner.gd`
- `DurablePioneerBeaconTestRunner.gd`
- `DeviceOverlayLayerTestRunner.gd`

Cardfront map/economy baseline:

- `RegionMapTestRunner.gd`
- `DeploymentRulesTestRunner.gd`
- `RegionMoraleTestRunner.gd`
- `EconomyTickTestRunner.gd`
- `CardfrontRuntimeSnapshotTestRunner.gd`

Runtime smoke baseline:

- `SmokeTestRunner.gd`
- `IntegrationTestRunner.gd`

Performance:

- `CardfrontPerformanceSmokeTestRunner.gd`

## 7. Canonical Docs / 主文档分工

- `README.md` — current project entrypoint / 项目入口
- `docs/ROADMAP.md` — main progress board and next slice / 进度板与下一切片
- `docs/历史_history/README_v0_1_9_cardfront_engineering_closeout.md` — v0.1.9 closeout stage record
- `docs/历史_history/README.md` — historical stage index / 历史阶段索引
- `docs/技术_technical/AI_HANDOFF_CURRENT.md` — this file
- `docs/技术_technical/CARDFRONT_DECOUPLING_PLAN.md` — Cardfront high-coupling split order
- `docs/TESTING.md` — test ownership, baseline, and run guidance
