# AI_HANDOFF_CURRENT

Last updated: 2026-05-22
Role / 作用: quick takeover card for Cardfront work / 卡牌前线快速接管卡

## 1. Current Version / 当前版本

- Current line: `v0.2.x` Cardfront formal UI
- Current completed slice: `v0.2.2e-card-interaction-feedback-pass`
- Current slice: `v0.2.3-debug-panel-toggle`
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
- Interaction feedback:
  - `CardfrontFeedbackBus.gd` — hover/select/invalid/success/failure signal bridge.
  - `CardfrontCardDetailPopup.gd` + `.tscn` — hover detail with card type, target, costs, summary, and current usable/resource/used state.
  - `CardfrontToastLayer.gd` + `.tscn` — max-3 expiring feedback toasts.
  - `CardfrontEffectVisualBridge.gd` — listens to card success and reuses `CardfrontVfxLayer` for the 4 existing effects.
  - `CardfrontCardAudioFeedback.gd` — light hover/click/success/fail audio hook with silent missing-asset fallback.
- `CardVisualRegistry.gd` maps card IDs 1001-1004 to illustration paths under `assets/cardfront_runtime/卡牌插图_cards/512/`.
  - 3 of 4 images exist (frontline_fortify, calibrated_shot, morale_shift). Pioneer beacon image is pending generation; placeholder fallback works.
- `Main.gd:_unhandled_input()` converts mouse clicks to `selection_controller.on_battlefield_clicked(cell)`.
- `CardfrontFireDirector.gd` has signals: `fire_tick`, `fire_requested`, `fire_issued`, `fire_skipped`.
- Overlay layers (`RegionOverlay`, `FortifyOverlay`) use ImageTexture caching.
- Old BallWar modes should not create or depend on Cardfront card/effect/fire systems.

## 3. Just Completed / 刚完成的内容

- v0.2.2e-card-interaction-feedback-pass: card hover detail popup, toast feedback, feedback bus, VFX bridge, and optional audio feedback.
- `CardfrontCardView.gd`: hover emits feedback and applies light scale/uplift-style emphasis without breaking `clicked_callback`.
- `CardfrontCardSelectionController.gd`: emits selected/deselected/invalid/success/failure through the feedback bus.
- `CardfrontVfxLayer.gd`: keeps existing VFX surface and adds process wake-up for new card-triggered effects.
- CI matrix now includes the new Cardfront interaction feedback runner batch.

## 4. Next Steps / 下一步

Ship `v0.2.3-debug-panel-toggle`:

- Keep the Cardfront debug action panel available for development.
- Add a clear toggle path so the panel no longer visually competes with the formal hand/resource/feedback UI.
- Keep BallWar mode unchanged.
- Do not add cards, Deckbuilder, AI Commander, or full Cardfront save/load in this slice.

Beyond v0.2.2:

- Generate or replace any pending card illustration assets only in an art-binding slice.
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
- `CardfrontCardDetailPopupTestRunner.gd`
- `CardfrontCardFeedbackTestRunner.gd`
- `CardfrontToastLayerTestRunner.gd`
- `CardfrontEffectVisualBridgeTestRunner.gd`

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
