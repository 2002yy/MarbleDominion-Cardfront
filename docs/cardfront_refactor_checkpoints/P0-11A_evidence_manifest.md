# P0-11A Final Evidence Manifest / Test Classification Freeze

Source commit: `0796c32b72f867197dd51d2acc653b18a8707ad9`

P0_RC_COMMIT: `0796c32b72f867197dd51d2acc653b18a8707ad9` (initial RC candidate; P0-11 evidence-only commits must be rebound and rerun before P0-11O)

Godot version: `4.7.1-stable.official.a13da4feb`

Decision: **GO**

Only allowed next step: **P0-11B - Parse / Import / Boot Gate**.

## Active evidence authority

Active workflows:

1. `.github/workflows/headless-tests.yml`
2. `.github/workflows/shared-upgrade-ai-tests.yml`
3. `.github/workflows/b1-simulation-tests.yml`
4. `.github/workflows/battlefield-entity-foundation-tests.yml`

Current source inventory: **158** `scripts/tests/*TestRunner.gd` files. The workflow YAML files, not `tests_legacy_disabled/`, are the current CI authority.

## Class A-F registry

### Class A - frozen non-target/current-product regression

- baseline scene/start/save/integration/layout: `Smoke`, `Integration`, `LayoutSanity`, StartMenu/GameHUD/EventRoulette/SettingsPanel, GameStateCoordinator/SaveFlowController/RestorePlan;
- Cardfront boot and loop: `CardfrontModeSmoke`, `CardfrontMatchPhaseController`, `CardfrontRoundCombat`, `CardfrontThreeChoiceRuntime`;
- Aim/Volley/Command Point: `CardfrontDirectionController`, `CardfrontFireDirector*`, `CardfrontControlChamberDecoupling`, `CardfrontLiveRuntimeBoundary`;
- UI/non-target isolation: formal UI, target preview/validator, click-selection, popup/feedback/hitbox/click-through/top-bar/match-flow runners;
- arena/entity/gate regression: arena/grid/orthographic/battlefield scale, entity runtime/presentation, GateConnectivity/GateRuntime.

### Class B - existing authority extended by P0

- `DeploymentRulesTestRunner` and the P0 deployment contract/core/directional/Player/Preview/AI/Automatic/FourConsumer runners;
- Support map identity/metadata/region mapping;
- Support capture contributor/profile/aggregator/state-machine/occupancy/territory prototype;
- Support topology/validator/connectivity truth/resolver/cache;
- `CardfrontRouteSemanticsTestRunner`;
- Draft geometry/lifecycle/side-RNG/Offer-independence.

### Class C - intentional semantic replacement

- `CardfrontStrongholdSystemTestRunner` - compatibility shell and producer demotion, not active bonus correctness;
- `CardfrontThreeChoiceRuntimeTestRunner` - formal 3-choice replaces legacy Lab 4-choice;
- `CardfrontUpgradeContentTestRunner` and `CardfrontUpgradeResolverTestRunner` - active upgrade semantics after Stronghold retirement;
- `CardfrontRegionInfoPanelVisibilityTestRunner` - Support status language replaces bonus language;
- explicit replacement checkpoints P0-05B1 through P0-05B5 and P0-08C.

### Class D - schema/migration

- `CardfrontRuntimeSnapshotTestRunner`;
- `CardfrontSupportSnapshotContractTestRunner`;
- `CardfrontSelectedLevelSnapshotTestRunner`;
- legacy payload/default fixtures and derived-connectivity rebuilding evidence required again at P0-11H.

### Class E - new frozen P0 contracts

- Support: identity, state, presentation contract/lifecycle, capture set, topology/connectivity/cache;
- deployment: contract, core fallback, directional zone, four-consumer parity;
- Draft: geometry, lifecycle, preview, signal, side RNG and Offer isolation;
- Level: Echo contract, semantic separation, selected snapshot, Offer projection, no-deck-inflation;
- AI: observation boundary, live projection, Commander adapter/metamorphic/sensitivity/no-cheat.

Forty-one new P0 runners and eleven modified pre-existing runners are directly affected and therefore cannot be omitted from final classification/regression evidence.

### Class F - evidence outside ordinary correctness assertions

- deterministic F1-F10 integration scenarios, mapped to focused runners in P0-11F;
- G1-G7 metamorphic/invariance scenarios, mapped in P0-11G;
- structural/per-event performance plus any same-machine runtime baseline in P0-11I;
- parse/import/boot logs and log/signal hygiene in P0-11B/J;
- owner/human North-Star playtest in P0-11K;
- source-bound screenshot pack in P0-11L;
- all four active GitHub workflows on one final RC in P0-11M.

## Performance scenarios frozen

- structural 40x40/50x50 load: `CardfrontPerformanceSmokeTestRunner`;
- graph counter: `SupportConnectivityCache.recompute_count`, including 100 idle queries, 100 hover queries, lazy bounded recompute after claim/operational mutation;
- presentation counter: `CardfrontSupportPresentationLayer3D.presentation_update_count` and lifecycle/orthographic tests;
- real frame-time: same machine, declared resolution/grid/scenario; record measured values without inventing an unfrozen threshold.

No new deploy-evaluation counter or AI-observation build counter is currently present. They are `N/A` unless a final performance symptom requires instrumentation; P0-11 must not add churn merely to satisfy a suggested counter list.

## Manual scenarios frozen

- normal advance;
- main route severed while branch survives;
- both routes severed with Core fallback recovery;
- strong unit cannot complete Support takeover without control contribution;
- repeated Draft Preview use and timeout closure;
- at least one CapturedOffline state;
- unaided tester explanation of main/branch purpose, deploy denial, Support loss, recovery, and combat-vs-control unit roles.

Automated/structured evidence may cover rule truth, but the unaided comprehension judgment in P0-11K cannot be self-certified by the implementation agent.

## Screenshots required

Source-bound evidence must cover or explicitly mark unavailable/N/A with product evidence:

1. default battle view;
2. Active and Neutral/Offline Support;
3. Capturing, Contested, CapturedOffline;
4. legal deployment targeting and Core fallback;
5. main route severed / branch survives;
6. normal three-choice, battlefield preview, preview return geometry;
7. narrow-screen state.

Every image/reference must record commit, viewport/resolution, and scenario/state.

## Known Yellow tuning debt

- capture duration/decay coefficients;
- directional zone dimensions;
- Support flag/glow/occlusion contrast;
- AI decision-window coefficients;
- final performance threshold remains unfrozen until comparable measured baselines exist.

None of these may absorb a structural failure, broken route, inexplicable deploy denial, information leak, save corruption, or legacy Stronghold authority.

## Classification result

No test directly affected by P0-01 through P0-10 remains unclassified. Passing a runner will be recorded only in its later evidence gate; this manifest itself does not claim any P0-11B-O execution result.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-11A evidence/test classification
Audit status: PASS
Evidence bound to source commit: YES - 0796c32b72f867197dd51d2acc653b18a8707ad9
Active workflows classified: 4
Current runner inventory counted: 158
New P0 runners classified: 41
Modified existing runners classified: 11
Manual scenarios frozen: YES
Performance scenarios frozen: YES
Screenshot requirements frozen: YES
Known Yellow debt separated from RED: YES
Later P0-11 gates claimed complete: NO
```
