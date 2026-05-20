# v0.1.9-cardfront-engineering-closeout

Date: 2026-05-20

This slice is a pure engineering closeout — no new gameplay systems. It aligns versions, CI, tests, docs, and code boundaries so the Cardfront prototype line is in a clean, handoff-ready state before v0.2.x formal HUD/Deckbuilder work begins.

## Goal

Finish engineering guardrails without adding gameplay. The repository should be CI-batched, version-synced, test-matrixed, doc-aligned, and have `CardPlaySystem` effect dispatch pre-split through `CardEffectResolver` / `CardEffectRegistry`. All deferred systems (formal card UI, Deckbuilder, AI Commander, full Cardfront save/load) remain explicitly out of scope.

## Implemented

### Version Sync

- `project.godot` version set to `0.1.9-dev`.
- CHANGELOG.md spine updated with v0.1.7a-d, v0.1.8a/b, v0.1.8d, v0.1.8e, v0.1.9 entries.

### CI Batch Matrix

- `.github/workflows/headless-tests.yml` restructured into 5 batches:
  - `Baseline runtime` — SmokeTestRunner, IntegrationTestRunner, LayoutSanityTestRunner, StartMenuSceneTestRunner, GameHUDSceneTestRunner, EventRouletteSceneTestRunner, SettingsPanelSceneTestRunner, GameStateCoordinatorTestRunner, SaveFlowControllerTestRunner, RestorePlanTestRunner.
  - `Cardfront map economy` — RegionMapTestRunner, NeutralOwnerCompatibilityTestRunner, DeploymentRulesTestRunner, RegionMoraleTestRunner, EconomyTickTestRunner, EconomyDebugPanelSceneTestRunner, CardfrontVisualPolicyTestRunner, VisualPressurePolicyTestRunner.
  - `Cardfront cards effects fire` — FortifyLayerTestRunner, CardEffectResolverTestRunner, CardCoreLiteTestRunner, CardFirstEffectsTestRunner, CardfrontTargetBiasTestRunner, PioneerBeaconLiteTestRunner, CardfrontFireDirectorTestRunner, CardfrontFireDirectorTurretIntegrationTestRunner, CardfrontControlChamberDecouplingTestRunner.
  - `Cardfront devices visuals schema` — DeviceCoreTestRunner, AbsorberCoreLiteTestRunner, EngineerBotLiteTestRunner, DurablePioneerBeaconTestRunner, DeviceOverlayLayerTestRunner, CardfrontBottomHudStatusTestRunner, CardfrontVfxLayerTestRunner, CardfrontVisibleEffectBridgeTestRunner, CardfrontRuntimeSnapshotTestRunner.
  - `Cardfront performance budget` — CardfrontPerformanceSmokeTestRunner.

### CardfrontRuntimeSnapshotTestRunner

- `scripts/tests/CardfrontRuntimeSnapshotTestRunner.gd` — 14 checks, headless-only.
- Audits the save-schema shape in `CardfrontRuntimeSnapshot.gd`: resource_states, used_card_ids, fortify_stacks, morale_effects, target_bias_state, devices. Full save/load wiring remains deferred.

### CardEffectResolver / CardEffectRegistry Split

- `scripts/cardfront/effects/CardEffectResolver.gd` — effect dispatch, context handoff, and registry delegation.
- `scripts/cardfront/effects/CardEffectRegistry.gd` — effect-id to effect-object mapping with registration validation and query.
- `CardPlaySystem.gd` now delegates effect resolution to `CardEffectResolver.resolve(req, card)` instead of owning a switch-on-effect_id.
- Four concrete effect wrappers under `scripts/cardfront/effects/effects/`: fortress border, morale shift, calibrated shot, pioneer beacon.
- `scripts/tests/CardEffectResolverTestRunner.gd` — 14 checks: resolver delegation, registry isolation, effect-not-found fallback, effect-id query.

### Documentation Alignment

- `README.md` now shows `Current active slice: v0.1.9-cardfront-engineering-closeout`.
- `CHANGELOG.md` spine updated with all v0.1.7+ entries.
- `assets/ASSET_SOURCES_AND_LICENSES.md` — `assets/cardfront/` re-labelled as source/staging; new `assets/cardfront_runtime/` section documenting wired device sprites.
- `docs/性能_performance/README.md` — new section clarifying that `CardfrontPerformanceSmokeTestRunner.gd` is a smoke gate, not a strict budget gate.
- `docs/技术_technical/CARDFRONT_DECOUPLING_PLAN.md` — captured as the engineering guardrail for future refactors.
- `docs/技术_technical/AI_HANDOFF_CURRENT.md` — aligned to v0.1.9 completion state.
- `docs/ROADMAP.md` — v0.1.9 still listed as Active (this doc is the closeout record).

## Not Done (Intentionally Deferred)

- Formal card UI / HUD, Deckbuilder, and AI Commander remain deferred.
- Full Cardfront save/load integration remains deferred; only the schema shape is audited.
- Strict performance budget test (`CardfrontPerformanceBudgetTestRunner.gd`) is not in this slice — only smoke-level checks exist.
- Device effect tuning, animation polish, and balance adjustments.
- Cardfront-specific start menu or deck selection UI.

## Validation

All runners in the CI batch matrix pass locally.

Key v0.1.9-adjacent runner results:

```
CardfrontRuntimeSnapshotTestRunner.gd         14 checks passed
CardEffectResolverTestRunner.gd               14 checks passed
CardfrontPerformanceSmokeTestRunner.gd         7 checks passed
CardfrontBottomHudStatusTestRunner.gd         10 checks passed
CardfrontVfxLayerTestRunner.gd                14 checks passed
CardfrontVisibleEffectBridgeTestRunner.gd      8 checks passed
DeviceOverlayLayerTestRunner.gd               21 checks passed
DeviceCoreTestRunner.gd                       31 checks passed
AbsorberCoreLiteTestRunner.gd                 11 checks passed
EngineerBotLiteTestRunner.gd                  10 checks passed
DurablePioneerBeaconTestRunner.gd              9 checks passed
CardfrontControlChamberDecouplingTestRunner.gd 7 checks passed
CardfrontFireDirectorTestRunner.gd            21 checks passed
CardfrontFireDirectorTurretIntegrationTestRunner.gd 12 checks passed
PioneerBeaconLiteTestRunner.gd                37 checks passed
CardCoreLiteTestRunner.gd                     40 checks passed
CardFirstEffectsTestRunner.gd                 40 checks passed
FortifyLayerTestRunner.gd                     469 checks passed
DeploymentRulesTestRunner.gd                  26 checks passed
EconomyTickTestRunner.gd                      50 checks passed
CardfrontModeSmokeTestRunner.gd               38 checks passed
SmokeTestRunner.gd                            218 checks passed
IntegrationTestRunner.gd                      133 checks passed
```

## Known Issues

- `CardfrontPerformanceSmokeTestRunner.gd` is smoke-level only (overlay dirty-redraw, shot-guide debug text, 40×40/50×50 load). It does not enforce frame budgets, object caps, or sustained-run stability. A strict `CardfrontPerformanceBudgetTestRunner.gd` is planned for a later slice.
- `CardfrontRuntimeSnapshot.gd` schema is audited but not wired into actual game save/load. The snapshot is currently test-only.
- `assets/cardfront_runtime/` VFX textures and device icons are staged but not yet wired into runtime rendering.
- Card illustrations remain entirely deferred to formal card UI.
- No v0.1.8a/b/d/e individual stage docs exist in `docs/历史_history/`; the CHANGELOG spine entries serve as their condensed record.

## Next: v0.2.0 Cardfront HUD Boundary

v0.1.x engineering closeout is complete. The next slice boundary is `v0.2.0-cardfront-formal-hud`:

### In scope
- Formal Cardfront HUD scene (`CardfrontHUD.tscn`) with resource bars, active card hand, device status, and target preview.
- `CardfrontHudBuilder.gd` — HUD node creation, data wiring, and `CardfrontRuntimeRefs`-driven refresh.
- Cardfront hand UI: show current fixed-hand cards, highlight playable cards, indicate used state.
- `CardfrontRuntimeRefs.gd` — typed reference payload so HUD, VFX, and overlay access is name-indexed, not `Main.gd`-coupled.
- `CardfrontSystemRegistry.gd` — named runtime refs with safe lookup (null checks, runtime-only assertions).

### Out of scope for v0.2.0
- Deck builder, deck draw/discard/shuffle, or card collection management.
- AI Commander behavior.
- Full Cardfront save/load wiring.
- New gameplay systems, card types, or device effects.
- Performance budget beyond smoke level.

### Design boundary
- The new HUD scene must not mutate resource state, card state, or device state. It is a read-and-display surface only.
- Card play input flows through `CardPlaySystem.gd` as before; the HUD only transmits play-intent signals.
- Old BallWar HUD (`GameHUD.tscn`) must continue to work unchanged when not in Cardfront mode.
- Follow the split order in `docs/技术_technical/CARDFRONT_DECOUPLING_PLAN.md` for all new wiring.
