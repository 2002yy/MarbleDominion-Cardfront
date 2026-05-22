# AI_HANDOFF_CURRENT

Last updated: 2026-05-22
Role / 作用: quick takeover card for Cardfront work / 卡牌前线快速接管卡

## 1. Current Version / 当前版本

- Current line: `v0.2.x` Cardfront formal UI
- Current completed slice: `v0.2.4a-real-ui-art-scene-pass`
- Current slice: `v0.2.4b-card-thumbnail-pass`
- Foundation baseline: BallWar / Marble Dominion Ricochet War `v2.1.11.1`

## 2. Current Status / 当前状态

- Cardfront is a sidecar mode assembled through `CardfrontMode.gd`; do not move Cardfront rules into `Main.gd`.
- `CardPlaySystem.gd` owns card play: fixed hand, resource payment, target validation, effect dispatch, and rollback on effect failure.
- Active card catalog remains 4 fixed cards (Frontline Fortify, Calibrated Shot, Morale Fluctuation, Pioneer Beacon).
- Formal HUD components:
  - `CardfrontTopResourceBar.gd` — top-left Energy/Parts display, signal-driven.
  - `CardfrontHandPanel.gd` — bottom-center 4-card hand panel.
  - `CardfrontCardView.gd` — card display with `CardArt` TextureRect + placeholder fallback; root receives mouse input, decorative children ignore input.
  - `CardfrontCardSelectionController.gd` — click → select → preview → battlefield click → play.
  - `CardfrontTargetPreviewLayer.gd` — highlights valid cells on card selection.
- Interaction feedback:
  - `CardfrontFeedbackBus.gd` — hover/select/invalid/success/failure signal bridge.
  - `CardfrontCardDetailPopup.gd` + `.tscn` — hover detail with card type, target, costs, summary, and current usable/resource/used state.
  - `CardfrontToastLayer.gd` + `.tscn` — max-3 expiring feedback toasts.
  - `CardfrontEffectVisualBridge.gd` — listens to card success and reuses `CardfrontVfxLayer` for the 4 existing effects.
  - `CardfrontCardAudioFeedback.gd` — light hover/click/success/fail audio hook with silent missing-asset fallback.
- Debug and UI art prep:
  - `CardfrontDebugActionPanel.gd` — hidden by default; parsed F3 input toggles it only in Cardfront non-release builds.
  - `CardfrontTopResourceBar.gd` — includes a tiny non-release `F3 Debug` hint; release builds hide the hint.
  - `CardfrontUiAssetRegistry.gd` — centralized Kenney/Wenrexa/Game-Icons/font path registry with ResourceLoader/fallback helpers.
  - v0.2.4a: TopResourceBar uses TextureRect icons (energy/parts) with registry-backed fallback (emoji text if texture missing).
  - v0.2.4a: CardView uses `card_frame` Panel style (CardBorder changed to Panel) and Bg alpha reduced to 0.40 when `card_bg` texture loads.
  - All Cardfront UI scenes now use registry-backed style/font/icon hooks with ColorRect / StyleBoxFlat fallback.
- `CardVisualRegistry.gd` maps card IDs 1001-1004 to illustration paths under `assets/cardfront_runtime/卡牌插图_cards/512/`.
  - 3 of 4 images exist (frontline_fortify, calibrated_shot, morale_shift). Pioneer beacon image is pending generation; placeholder fallback works.
- `Main.gd:_unhandled_input()` converts mouse clicks to `selection_controller.on_battlefield_clicked(cell)`.
- `CardfrontFireDirector.gd` has signals: `fire_tick`, `fire_requested`, `fire_issued`, `fire_skipped`.
- Overlay layers (`RegionOverlay`, `FortifyOverlay`) use ImageTexture caching.
- Old BallWar modes should not create or depend on Cardfront card/effect/fire systems.

## 3. Just Completed / 刚完成的内容

- v0.2.3-debug-panel-toggle: Cardfront debug action panel is hidden by default, F3 toggles it in non-release Cardfront builds, and BallWar mode remains isolated.
- Added `CardfrontUiAssetRegistry.gd` to centralize UI art paths before broader v0.2.4 skin work.
- Hand panel, card view, resource bar, detail popup, toast layer, and region info panel now consult the registry and fall back to current procedural styling.
- v0.2.3.1-cardview-mouse-hotfix: `CardfrontCardView.tscn` root now uses `MOUSE_FILTER_STOP`, decorative children use `MOUSE_FILTER_IGNORE`, and hover/click dispatch reaches `CardfrontFeedbackBus`.
- v0.2.3.2-debug-input-route-hardening: F3 toggle is covered through `Input.parse_input_event`, the formal UI shows a small non-release `F3 Debug` hint, and release/BallWar paths stay hidden.
- CI matrix now includes `CardfrontDebugPanelToggleTestRunner.gd`, `CardfrontUiAssetRegistryTestRunner.gd`, `CardfrontUiArtSceneTestRunner.gd`, and `CardfrontCardViewInteractionConfigTestRunner.gd`.
- v0.2.3.3-warning-hud-hand-motion-prepass: GDScript warning cleanup (show/name/tier shadowing, integer division); CardfrontHUD as standalone scene with legacy BallWar HUD nodes hidden in Cardfront mode; hand panel collapsed to 80px height (was 160px) with cards sunk at 70px offset; hover Tween expand/collapse animation (y→0, scale→1.05, z_index→30); selected cards stay expanded after mouse exit; F3 Debug hint relocated from top-left (20,136) to bottom-right (1010,660) with reduced visibility.
- v0.2.4a-real-ui-art-scene-pass: TopResourceBar uses TextureRect icons (icon_energy SVG, icon_parts SVG) with registry-backed emoji fallback; CardView CardBorder changed to Panel for card_frame texture, Bg alpha lowered to 0.40 when card_bg exists; all Cardfront UI scenes use registry-backed style/font/icon hooks; no gameplay or card-value changes.

## 4. Next Steps / 下一步

Ship `v0.2.4b-card-thumbnail-pass`:

- Generate/register 128/256 thumbnails for hand cards using `CardVisualRegistry.thumbnail`.
- Keep 512px art reserved for hover detail / full-card views.
- Preserve Game-Icons credits.
- Keep BallWar mode unchanged.
- Do not add cards, Deckbuilder, AI Commander, card-value changes, or full Cardfront save/load in this slice.

Beyond v0.2.4:

- Generate/register hand-card thumbnails for `CardVisualRegistry.thumbnail`.
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
- `CardfrontDebugPanelToggleTestRunner.gd`
- `CardfrontUiAssetRegistryTestRunner.gd`
- `CardfrontUiArtSceneTestRunner.gd`
- `CardfrontCardViewInteractionConfigTestRunner.gd`

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
