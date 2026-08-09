# P0-00A Repository Ownership & Call-Chain Snapshot

Status: **COMPLETE — STATIC AUDIT**
Decision: **GO**

## Step contract

```text
Step: P0-00A Repository Ownership & Call-Chain Snapshot
Source commit: fc56e21e0cf7ad8c79eaf9659afbda3e1f89e487
Source ref: origin/main
Original intent: Record the current owners and reachable call chains before any P0 gameplay migration.
Engineering Spec sections: §0, §1, §2, §6, §8, §9, §14, §15
Old authority: Existing Cardfront runtime at the source commit described below.
Target authority: No target authority is implemented in P0-00A; this file records migration inputs only.
Allowed mutation surface: docs and necessary read-only audit helpers.
Read-only surface: all gameplay, map, UI, save, AI, runtime, test, and workflow source.
Forbidden changes: gameplay, Support implementation, map edits, refactors, new rules, P0-01 work.
Old behaviors that must survive: Not decided here; P0-00C owns the frozen delta ledger.
Explicitly not solving: Support state, Support capture, Support graph, frontline deployment, Draft preview, Offer isolation, AI observation DTO, legacy Stronghold retirement.
Test evidence authority: scripts/tests/*.gd plus active .github/workflows/*.yml; tests_legacy_disabled is historical only.
Expected checkpoint: docs/cardfront_refactor_checkpoints/P0-00A_ownership_map.md
```

## Source binding and repository sync evidence

- GitHub repository: `2002yy/MarbleDominion-Cardfront`.
- `gh api repos/2002yy/MarbleDominion-Cardfront/commits/main` reported `fc56e21e0cf7ad8c79eaf9659afbda3e1f89e487` (`docs: make P0 audit gates mandatory`).
- `git fetch --prune origin main` then updated `origin/main` from `cd108cc` to `fc56e21`.
- `git merge --ff-only origin/main` fast-forwarded this isolated audit worktree to the same commit.
- `git rev-parse HEAD` and `git rev-parse origin/main` both returned the full Source commit above.
- GitHub compare `cd108cc...fc56e21` contains 28 commits and only documentation paths. Therefore the gameplay source audited at `fc56e21` is the same gameplay source tree as `cd108cc`, while all mandatory P0 documents are present at `fc56e21`.
- The pre-existing primary checkout was not modified or cleaned. It contained 495 tracked changes plus untracked Godot/import outputs, so this audit was performed in the isolated `audit/p0-00a` worktree.

Evidence type: **static**
Evidence bound to source commit: **YES**

## 1. Runtime composition owner

```text
project.godot run/main_scene
 -> scenes/Main.tscn
 -> scripts/Main.gd
 -> CardfrontRuntimeBuilder
 -> GameRuntimeContext / CardfrontRuntimeRefs / CardfrontSystemRegistry
```

- `scripts/Main.gd:_start_game()` selects mode/config, creates the Cardfront runtime core and world layers, then creates Cardfront UI.
- `scripts/cardfront/runtime/CardfrontRuntimeBuilder.gd` is the assembly owner for RegionMap, StrongholdSystem, RoundDirector, entity runtime, territory defense, gate connectivity, and their dependencies.
- `scripts/GameRuntimeContext.gd` holds the live references. `scripts/cardfront/runtime/CardfrontSystemRegistry.gd` names builder result keys; neither is an independent gameplay rules authority.

Audit result: **PASS — composition owner is clear.**

## 2. Legacy Stronghold producer and consumer ledger

### 2.1 Definition and producer

```text
DefaultDuelMap / other map definitions
 -> Energy / Factory / Lab region types
 -> RegionMap runtime region IDs
 -> CardfrontStrongholdSystem.sample_bonuses()
 -> per-side current_stronghold_bonuses
```

- `scripts/cardfront/strongholds/CardfrontStrongholdRules.gd` defines the old tactical contract: activation at 80%, Factory `+3` shots, Energy `+1` temporary attack level, Lab offer size `4`.
- `scripts/cardfront/strongholds/CardfrontStrongholdSystem.gd:sample_bonuses()` iterates controllable runtime regions, calculates territory control, selects the best qualifying region of each type per side, and emits/stores the snapshot.
- `CardfrontRuntimeBuilder.create_stronghold_system()` creates the producer and injects it into `CardfrontRoundDirector`.

### 2.2 Gameplay consumers

| Consumer | Reachable behavior |
| --- | --- |
| `CardfrontRoundDirector._open_draft()` | Samples Strongholds once at Draft open before offers are drawn. |
| `CardfrontRoundDirector._draft_choice_count()` | Reads `draft_choice_count`; Lab changes 3 choices to 4 for Player and AI. |
| `CardfrontRoundDirector._begin_resolution()` -> `CardfrontStrongholdSystem.apply_to_volley_plan()` | Applies Factory shot bonus and Energy temporary attack-level bonus to the resolved volley. |
| `CardfrontRoundDirector.get_upgrade_value_context()` | Feeds Stronghold shot, attack and future-offer-size values into current AI upgrade scoring. |
| `Main._check_winner()` -> `WinConditionEvaluator.evaluate_cardfront()` | Re-samples on timeout and counts active Stronghold types as part of timeout score. |
| `CardfrontTargetScorer` | Gives legacy region/controlled-Stronghold target priority; this is legacy Stronghold semantics even though it does not consume the sampled bonus dictionary. |
| `CardfrontBalanceMatchSimulator` and audit wrappers | Simulated stronghold activation affects offer size, volley values, first-activation metrics and score proxies. |

### 2.3 UI and presentation consumers

| Consumer | Current meaning |
| --- | --- |
| `CardfrontThreeChoicePanel` | Subscribes to `strongholds_sampled`, shows bonus labels, titles Lab as four-choice, lays out 3 or 4 cards. |
| `CardfrontRegionInfoPanel` | Reads `get_region_activation()` and renders active/unactivated legacy effect text. |
| `RegionControlBlockLayer` | Uses the 80% threshold and legacy type badges. |
| `CardfrontOrthographicArenaView` | Builds/refreshes Stronghold platforms, rings and labels from regions/control. |
| `Main._connect_stronghold_label_signals()` | Shows Stronghold labels around Draft/resolve events. |
| `CardfrontMapPreview` | Draws Stronghold markers in the prematch map preview. |
| `CardfrontMatchFlowText` | Displays Stronghold contribution in timeout result text. |

### 2.4 Save/restore consumers

```text
Main._save_game_progress()
 -> CardfrontRuntimeSnapshot.capture()
 -> current_stronghold_bonuses
 -> SaveStateBuilder.cardfront_snapshot

continue
 -> Main._apply_saved_state() restores territory owners
 -> CardfrontRuntimeSnapshot.apply_to_runtime()
 -> RoundDirector.current_stronghold_bonuses restored directly
```

- `CardfrontRuntimeSnapshot` schema `2.0` serializes and restores `current_stronghold_bonuses` as live RoundDirector state.
- This is not merely a dormant backward-compatible read: restored bonuses remain reachable by Draft size, AI context and volley application until the next sample.
- Existing tests that deliberately bind the legacy contract include `CardfrontStrongholdSystemTestRunner`, `CardfrontStrongholdTimeoutScoringTestRunner`, `CardfrontThreeChoiceRuntimeTestRunner`, `CardfrontLiveRuntimeBoundaryTestRunner`, and `CardfrontRuntimeSnapshotTestRunner`.

Audit result: **PASS — all current producer/consumer/UI/save surfaces are identified.**
Migration warning: legacy Stronghold authority is still fully reachable and must not coexist with future Support gameplay authority after its frozen retirement cutover.

## 3. Deployment legality, preview, validation and commit

### 3.1 Present rules surface

- `DeploymentQuery`, `DeploymentResult`, `DeploymentRuleType`, and `DeploymentRules` are under `scripts/cardfront/deployment/`.
- `DeploymentRules.evaluate()` owns current rule-type evaluation for owned cell, owned border, controlled region, contested region and enemy region.
- Several live consumers call the same static helper functions directly rather than constructing a `DeploymentQuery`; the present API is therefore one rules module, but not yet one uniform facade call.

### 3.2 Player preview and commit chain

```text
Preview:
CardfrontCardSelectionController.on_card_clicked()
 -> CardfrontTargetPreviewLayer.show_for_card()
 -> DeploymentRules.is_owned_border() for owned-border cards

Commit:
Main battlefield click
 -> CardfrontCardSelectionController.on_battlefield_clicked()
 -> CardfrontCardSelectionController.on_target_selected()
 -> CardPlaySystem.play()
 -> CardTargetValidator.validate()
 -> OwnedBorderTargetRule.validate()
 -> DeploymentRules.is_owned_border()
 -> resource pay
 -> effect resolve
```

- `CardPlaySystem.validate()` performs availability/resources/target validation; `play()` pays only after validation succeeds.
- `OwnedBorderTargetRule` is the active validator facade adapter for current owned-border deployment-like card targets.
- `CardfrontTargetPreviewLayer` and commit both use `DeploymentRules.is_owned_border()`, so the current owned-border preview/commit predicate is shared.
- `PioneerBeaconLiteEffect` rechecks `DeploymentRules.is_owned_border()` in the effect path; it is a defense-in-depth duplicate call, not a different predicate.
- `DeviceLayer`, `EngineerBotEffectSystem`, `DurablePioneerBeaconEffectSystem`, `FortifyTargetSelector`, and `CardfrontTargetScorer` also consume DeploymentRules helpers for their existing specialized needs.

Audit result: **PASS — current player preview/validate/commit chain is clear.**
Migration warning: future P0 must converge all four consumers on the extended authoritative result; current direct helper use is not proof of future frontline parity.

## 4. Draft and three/four-choice owner

```text
CardfrontMatchPhaseController reaches DRAFT_PAUSED
 -> CardfrontRoundDirector._on_phase_changed()
 -> CardfrontRoundDirector._open_draft()
 -> sample Strongholds and Gates
 -> CardfrontBattlefieldEntityRuntime.prepare_draft()
 -> CardfrontUpgradeDraftSystem.draw_offer() separately for Player and AI
 -> CardfrontAiCommander.choose(AI offer, AI RunState, live value context)
 -> RoundDirector.draft_opened(player_offer, ai_offer, ...)
 -> CardfrontThreeChoicePanel._on_draft_opened()
```

- `CardfrontRoundDirector` is the phase and offer orchestration owner.
- `CardfrontUpgradeDraftSystem` is the eligibility, weighting, RNG, draw and timeout-fallback owner. Default offer size is 3; maximum is 4.
- `CardfrontMode.create_three_choice_panel()` instantiates `scenes/ui/cardfront/CardfrontThreeChoicePanel.tscn`; `Main._create_cardfront_three_choice_panel()` owns creation/lifetime wiring.
- `CardfrontThreeChoicePanel` subscribes to the RoundDirector and owns the visible Draft root, card instances, 3/4-card layout and the current peek behavior.
- Current peek moves `ChoiceShell.position` and restores the saved position. This is the known legacy path targeted later by the frozen Draft-preview work; P0-00A does not change it.
- Player and AI offers are separate arrays, but both draws consume the same `_draft_system` and its single RNG instance. This is a known later Offer-isolation migration fact, not a P0-00A implementation task.

Audit result: **PASS — Draft and UI owners are clear.**

## 5. AI input path

```text
RoundDirector._open_draft()
 -> get_ai_offer()
 -> get_run_state(AI)
 -> get_upgrade_value_context(AI)
 -> CardfrontAiCommander.choose()
 -> CardfrontAiUpgradePolicy.rank_ids()
 -> CardfrontUpgradeValuePolicy.evaluate()
```

- `get_upgrade_value_context()` constructs a Dictionary from current Stronghold bonuses, territory-defense snapshots for both sides, turret health, round number, offer size, and both sides' entity-summary counts.
- `CardfrontAiCommander` applies hero/archetype weights to ranked upgrade evaluations.
- No `AIObservationBuilder`/observation DTO exists yet. The current value-context Dictionary and direct AI `CardfrontFactionRunState` are the present input boundary.
- This chain chooses Draft upgrades. No separate current AI frontline placement consumer exists for the future Support deployment contract; that consumer must be made explicit in its later checkpoint rather than assumed present.

Audit result: **PASS — current AI decision input is clear.**

## 6. Map, Region, Route, Bridge and Gate ownership

### Map and Region

```text
CardfrontMapRegistry
 -> DefaultDuelMap.make(extent)
 -> CardfrontMapDefinition Dictionary
 -> RegionMap.generate_from_definition()
 -> CardfrontMapBuilder.apply_to_region_map()
 -> RegionMap.paint_region_*()
 -> RegionMap._allocate_region()
```

- `DefaultDuelMap` authors five legacy resource/Stronghold regions, spawn zones, neutral zone, two-lane route metadata, balance/simulation metadata and objective metadata.
- `CardfrontMapDefinition` validates definitions. `CardfrontMapBuilder` applies authored regions. `RegionMap` owns the runtime cell-to-region arrays, region type/cell lookup and runtime ID allocation.

### Runtime `region_id` identity finding

- `RegionMap.next_region_id` resets to `1` and `_allocate_region()` increments it in application order.
- Rect/diamond paint calls allocate IDs as regions are applied. Editing/reordering authored regions can change IDs without changing their conceptual meaning.
- `RegionMap.snapshot()` exposes `next_region_id`, `region_ids`, types and cells, but the main `CardfrontRuntimeSnapshot` does not establish any stable Support identity mapping from those values.
- Conclusion: **runtime `region_id` is an instance-local lookup handle, not a stable Support identity.** Any future Support must use authored `support_id -> anchor_cell -> runtime region_id`, never numeric region IDs as long-lived identity.

### Route and bridge

- `DefaultDuelMap.route_layout` is the authored two-lane metadata owner: centers `0.265/0.735`, widths, control-zone dimensions, traffic weights and off-bridge rate.
- `CardfrontDirectionController` turns the player's lane split/aim into per-lane allocations; `CardfrontRoundDirector` passes those allocations to `CardfrontFireDirector.issue_lane_volley()`.
- `CardfrontArenaLayout` declares the open dual-bridge composition. `CardfrontOrthographicArenaView._build_river_and_bridges()` owns the 3D river, two bridge meshes and gate presentation.

### Gate

- `CardfrontGateRules` owns the 55%/80% state thresholds and projectile pass/filter rules.
- `CardfrontGateConnectivitySystem` samples two gate control zones at Draft open, locks a round snapshot, attaches as `BulletPool.route_filter`, filters river crossings, and drives gate presentation state.
- `CardfrontRoundDirector._sample_gates()` is the sample trigger. `CardfrontRuntimeBuilder.create_gate_connectivity_system()` is the assembly owner.
- The Gate system is a projectile-route filter based on territory control; it is **not** a future Support graph/connectivity authority.

Audit result: **PASS — Map/Region/Route/Bridge/Gate owners and separations are clear.**

## 7. Territory capture authority versus future Support capture

```text
Bullet contact
 -> Bullet._apply_battlefield_contact()
 -> Battlefield.apply_bullet(cell, faction, capture_context)
 -> CardfrontCaptureInterceptor.should_block_capture()
 -> CardfrontBattlefieldEntityRuntime.resolve_capture_contact()
 -> CardfrontEntityProjectileBridge.resolve_capture_contact()
 -> fortify/entity interception
 -> Battlefield.owners[cell] changes if not blocked
 -> CardfrontCaptureInterceptor.on_capture_applied()
```

- `Battlefield.owners` and `Battlefield.apply_bullet()/apply_owner_change()` own territory-cell ownership mutation.
- `CardfrontCaptureInterceptor` decides whether a projectile/card-driven territory ownership change is blocked and applies first-capture fortification side effects.
- Entity contact is delegated through `CardfrontBattlefieldEntityRuntime` to `CardfrontEntityProjectileBridge`; this remains projectile/entity interaction in the territory-capture pipeline.
- No Support claim/progress/contested/operational owner exists at the Source commit.
- Conclusion: **`CardfrontCaptureInterceptor` belongs only to projectile/card-driven territory capture. It is not and must not become Support Capture authority.**

Audit result: **PASS — authority separation is explicit.**

## 8. Creature movement legality

```text
CardfrontBattlefieldEntityRuntime.advance_round()
 -> CardfrontCreatureActionCoordinator.run_actions()
 -> behavior-specific target selection
 -> next_owned_step_toward()
 -> BattlefieldEntityRegistry.move_entity()
```

- For normal repair and armored-guard autonomous movement, `next_owned_step_toward()` rejects every candidate whose `battlefield.owners[candidate] != owner_id`.
- Sapper movement delegates to `CardfrontSapperSystem`; its gate navigation is a specialized existing behavior and is not authority to globally relax Creature movement.
- Neutral gate colossus uses `CardfrontNeutralCreatureSystem` and `CardfrontEntityGateNavigator` with its own special traversal contract.
- Projectile push can forcibly move a Creature without the autonomous own-territory check. This is a combat displacement exception, not normal locomotion legality.
- Conclusion: **current normal faction Creature movement is constrained to its own territory; P0 Support Capture must not silently turn this into free movement across neutral/enemy cells.**

Audit result: **PASS — baseline constraint and exceptions are identified.**

## 9. Upgrade and automatic spawn bypasses

### Upgrade action chain

```text
RoundDirector._begin_resolution()
 -> CardfrontUpgradeResolver writes pending entity actions to RunState
 -> CardfrontBattlefieldEntityRuntime.apply_pending_upgrade_actions()
 -> spawn_repair_units / spawn_armored_guard / spawn_sapper_unit
 -> CardfrontCreatureActionCoordinator.find_owner_spawn_cell()
 -> route building slot by lane index
 -> find_adjacent_spawn_cell()
 -> first owned/available nearby cell, otherwise origin
 -> Registry.spawn_creature()
```

- Tower upgrade/build actions use `CardfrontTowerRuntime.first_free_lane()` and fixed route building slots, then `Registry.spawn_defense_tower()`.
- Gate Colossus upgrade actions use `CardfrontNeutralCreatureSystem._spawn_candidates()` around gate cells.

### Automatic summon chain

```text
CardfrontTowerRuntime.process_summons()
 -> runtime._find_adjacent_spawn_cell(tower owner, tower cell)
 -> Registry.spawn_creature()
```

- All these placement paths bypass `DeploymentRules.evaluate()` and its helper predicates as a placement authorization step.
- `find_adjacent_spawn_cell()` returns `origin` when it finds no owned/available candidate, so the old fallback can return a cell that did not pass its preceding owned/availability checks.
- Conclusion: **upgrade and automatic spawn currently bypass DeploymentRules.** P0-04 must include them as the fourth consumer and must remove old arbitrary route/origin fallback semantics only at the frozen cutover, not in P0-00A.

Audit result: **PASS — bypass owners and concrete call chains are identified.**

## 10. Save/snapshot compatibility surface

### Base save owner

- `Main._save_game_progress()` calls `SaveFlowController.write_game_progress_result()`.
- `SaveStateBuilder` saves grid extent, mode, battlefield `owners`, faction/turret state, bullets, event state and optional `cardfront_snapshot`.
- Continue builds a `RestorePlan`; `SaveStateApplier.apply_owners()` restores territory ownership before the Cardfront runtime snapshot is applied.

### Cardfront snapshot owner

- `CardfrontRuntimeSnapshot` schema `2.0` saves faction RunStates, match phase, round state, heroes, current offers, current Stronghold bonuses, current Gate snapshot, entity registry snapshot and territory-defense state.
- Entity snapshot includes `map_id`, registry state and entity serial. The top-level save start plan uses current Main selection/config before applying that entity snapshot; this is a known map-selection compatibility risk to exercise in later save/restore evidence.
- Current Stronghold and Gate snapshots are restored directly into RoundDirector. They are sampled state, not recomputed from restored territory at apply time.
- RegionMap's own `snapshot()` is not the Cardfront save authority in this flow.

Audit result: **PASS — save and restore owners/order are clear.**
Known risk: restored sampled/derived state can disagree with restored territory until a later sample; future Support derived connectivity must not copy this pattern as permanent save truth.

## 11. Active tests and real-run entrypoints

### Automated authority

- Active local runners: `scripts/tests/*.gd` (122 `.gd` files at the Source commit).
- Active CI workflows: `.github/workflows/headless-tests.yml`, `battlefield-entity-foundation-tests.yml`, `shared-upgrade-ai-tests.yml`, and `b1-simulation-tests.yml`.
- CI uses Godot `4.6.2-stable`, performs headless parse/import, then runs scripts with:

```text
Godot --headless --audio-driver Dummy --path <repo> --script res://scripts/tests/<Runner>.gd
```

- `headless-tests.yml` is the broad regression authority and includes baseline runtime plus Cardfront map/economy, cards/effects/fire, schema/UI, v0.3 core, entity, Stronghold, gate and live-boundary batches.
- Focused workflows add entity runtime, shared AI parity/value policy, and B1 simulation evidence.
- `tests_legacy_disabled/` and disabled historical TestRunner files are not current evidence authority.
- A zero-test or load-only result is not a pass. `CardfrontPerformanceSmokeTestRunner` is structural smoke, not real performance proof.

### Manual/runtime entry

```text
Godot project -> scenes/Main.tscn
 -> StartMenu selects Cardfront
 -> Main._open_cardfront_prematch()
 -> CardfrontPrematchScreen map/hero flow
 -> battle_confirmed
 -> Main._start_game(selected_grid_extent)
```

- `scripts/tools/capture_cardfront_full_game.gd` is a rendering-display screenshot helper, not a replacement for interactive P0-00B evidence.
- P0-00A performed no runtime pass/fail claim. Actual boot, play flow, UI visibility, warnings/logs and headless outcomes belong to P0-00B.

Audit result: **PASS — active automated and manual entrypoints are identified.**

## 12. Mandatory audit gate summary

```text
Mandatory audit gates touched: P0-00A Repository Ownership & Call-Chain Snapshot
Audit status per gate: PASS
Evidence bound to source commit: YES
Unverified assumptions remaining: None for repository ownership/call-chain scope. Runtime behavior remains deliberately unverified until P0-00B.
Legacy authority still reachable: YES — Factory/Energy/Lab bonuses affect Draft, volley, AI scoring, timeout scoring, UI, simulation and restore.
Second-authority risk: YES for future migration if Support/Deployment is added without retiring legacy Stronghold and the spawn bypass paths.
Save/restore risk: Restored Stronghold/Gate sampled state can be stale relative to restored territory; map selection is not proven by P0-00A runtime evidence.
Cross-system regression evidence: Static only in P0-00A; active runners/workflows are identified but not claimed as executed here.
Manual evidence required before GO: Not required for P0-00A static ownership GO. It is mandatory for P0-00B.
```

## Findings that constrain the next stages

1. Runtime numeric `region_id` cannot identify a stable Support.
2. `CardfrontCaptureInterceptor` is territory/projectile capture only.
3. Upgrade creature spawn, tower placement, Gate Colossus placement and automatic tower summons bypass DeploymentRules.
4. Normal faction Creature movement stays on owned territory; special neutral navigation and projectile displacement do not authorize a global rule change.
5. Legacy Stronghold remains live in Draft, volley, AI, timeout score, UI, simulation and save/restore.
6. Current Preview and Commit share owned-border helpers, but not every existing placement-like consumer is routed through `DeploymentRules.evaluate()`.
7. Current Player/AI Draft draws use the same DraftSystem RNG; later Offer-isolation work must not assume independent streams already exist.
8. Gate connectivity is projectile routing, not the future Support graph.
9. Cardfront restore directly reinstates sampled Stronghold/Gate dictionaries; future graph-derived state must be recomputed under its frozen save contract.

## Decision

All mandatory P0-00A owners and reachable call chains are identified at the bound Source commit. No gameplay, map, Support, refactor or test authority was changed.

**Decision: GO**

## Only allowed next step

**P0-00B Baseline Regression Capture** using real runtime/manual and headless evidence bound to one target commit. If any required real-run evidence cannot be obtained, P0-00B must be recorded as `BLOCKED / AUDIT REQUIRED / Decision: NO-GO`; P0-01 remains forbidden.
