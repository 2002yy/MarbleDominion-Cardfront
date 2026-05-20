# AI_HANDOFF_CURRENT

Last updated: 2026-05-20
Role / 作用: quick takeover card for Cardfront work / 卡牌前线快速接管卡

## 1. Current Version / 当前版本

- Current line: `v0.2.x` Cardfront formal UI
- Current completed slice: `v0.2.1-target-preview`
- Current slice: `v0.2.2-card-art-binding`
- Foundation baseline: BallWar / Marble Dominion Ricochet War `v2.1.11.1`

## 2. Current Status / 当前状态

- Cardfront is a sidecar mode assembled through `CardfrontMode.gd`; do not move Cardfront rules into `Main.gd`.
- `CardPlaySystem.gd` owns card play: fixed hand, resource payment, target validation, effect dispatch, and rollback on effect failure.
- Active card catalog remains 4 fixed cards (Frontline Fortify, Calibrated Shot, Morale Fluctuation, Pioneer Beacon).
- Formal HUD components:
  - `CardfrontTopResourceBar.gd` — top-left Energy/Parts display, signal-driven.
  - `CardfrontHandPanel.gd` — bottom-center 4-card hand panel.
  - `CardfrontCardView.gd` — card display with `CardArt` TextureRect + placeholder fallback.
  - `CardfrontCardSelectionController.gd` — click → select → preview → battlefield click → play.
  - `CardfrontTargetPreviewLayer.gd` — highlights valid cells on card selection.
- `CardVisualRegistry.gd` maps card IDs 1001-1004 to illustration paths under `assets/cardfront_runtime/卡牌插图_cards/512/`.
  - 3 of 4 images exist (frontline_fortify, calibrated_shot, morale_shift). Pioneer beacon image is pending generation; placeholder fallback works.
- `Main.gd:_unhandled_input()` converts mouse clicks to `selection_controller.on_battlefield_clicked(cell)`.
- `CardfrontFireDirector.gd` has signals: `fire_tick`, `fire_requested`, `fire_issued`, `fire_skipped`.
- Overlay layers (`RegionOverlay`, `FortifyOverlay`) use ImageTexture caching.
- Old BallWar modes should not create or depend on Cardfront card/effect/fire systems.

## 3. Just Completed / 刚完成的内容

- v0.2.1-target-preview: `CardfrontTargetPreviewLayer`, battlefield click wiring in `Main.gd:_unhandled_input()`, `CardfrontBattlefieldClickSelectionTestRunner.gd`.
- Card visual redesign: vertical layout 130×150, type-specific placeholder icons.
- Bug fixes: setup order (@onready safety), deselect-on-reclick, lambda closure, text color restore.
- GDScript warning cleanup: shadowed params, integer division, unused params.
- Doc realignment: README/ROADMAP/AI_HANDOFF synced to v0.2.1.

## 4. Next Steps / 下一步

Ship `v0.2.2-card-art-binding`:

- Sync project.godot version to 0.2.2-dev.
- Verify CardVisualRegistry.gd paths against actual cardfront_runtime files.
- Note: pioneer beacon card illustration is pending generation; fallback works.
- Create `CardfrontCardArtBindingTestRunner.gd` for path/fallback verification.
- Update CHANGELOG.md, CI, and all docs to v0.2.2.

Beyond v0.2.2:

- Generate pioneer beacon card illustration.
- `v0.2.3-debug-panel-toggle`: fold DebugActionPanel behind F3 toggle.
- Deckbuilder, AI Commander, and full Cardfront save/load remain deferred.

## 5. Do Not Do / 不要做什么

- Do not add Deckbuilder, deck draw/discard/shuffle.
- Do not add AI Commander behavior.
- Do not add full Cardfront save/load wiring.
- Do not change FireDirector fire rate or budget rules.
- Do not push effect logic into `Main.gd`.
- Do not change old BallWar mode rules to satisfy Cardfront tests.
- Do not expand the 4-card fixed hand.

## 6. Required Tests / 当前必跑测试

Cardfront formal UI + target preview:

- `CardfrontFormalUITestRunner.gd`
- `CardfrontTargetPreviewTestRunner.gd`
- `CardfrontBattlefieldClickSelectionTestRunner.gd`
- `CardfrontCardArtBindingTestRunner.gd`

Cardfront fire/effects:

- `CardfrontFireDirectorSignalTestRunner.gd`
- `CardfrontFireDirectorTestRunner.gd`
- `CardfrontFireDirectorTurretIntegrationTestRunner.gd`
- `CardfrontControlChamberDecouplingTestRunner.gd`
- `CardEffectResolverTestRunner.gd`
- `CardCoreLiteTestRunner.gd`
- `CardFirstEffectsTestRunner.gd`

Cardfront device/economy:

- `DeviceCoreTestRunner.gd`
- `AbsorberCoreLiteTestRunner.gd`
- `EngineerBotLiteTestRunner.gd`
- `DurablePioneerBeaconTestRunner.gd`
- `FortifyLayerTestRunner.gd`
- `DeploymentRulesTestRunner.gd`
- `EconomyTickTestRunner.gd`
- `CardfrontModeSmokeTestRunner.gd`

Runtime baseline:

- `SmokeTestRunner.gd`
- `IntegrationTestRunner.gd`

## 7. Canonical Docs / 主文档分工

- `README.md` — current project entrypoint
- `docs/ROADMAP.md` — main progress board
- `docs/历史_history/README.md` — historical stage index
- `docs/技术_technical/AI_HANDOFF_CURRENT.md` — this file
- `docs/技术_technical/CARDFRONT_DECOUPLING_PLAN.md` — Cardfront high-coupling split order
