# P0-04E Automatic / Upgrade Spawn Cutover

Audited source commit: `bd30e0cdcf11c10eaf3b5d2e54835a7c0cbd8e91`
Branch: `audit/p0-04e-auto-spawn`
Target step: **P0-04E — Automatic / Upgrade Spawn Cutover**
Decision: **GO**
Evidence bound to audited source commit: **YES**

## Goal

Remove the fourth deployment consumer's legacy bypass so repair / armored-guard / sapper automatic upgrade spawning resolves its final cell through the same deployment legality authority used by player Commit, Preview, and AI.

Frozen authority chain:

```text
pending upgrade action
 -> CardfrontBattlefieldEntityRuntime
 -> CardfrontAutomaticSpawnCoordinator
 -> DeploymentPlacementResolver
 -> DeploymentRules.evaluate(SUPPORT_NETWORK)
 -> deterministic legal cell
 -> occupancy / capacity guard
 -> authoritative creature creation at resolved cell
```

`CardfrontBattlefieldEntityRuntime` and `CardfrontAutomaticSpawnCoordinator` do not directly own deployment legality. `DeploymentPlacementResolver` is a deterministic placement resolver, not a second legality authority.

## What changed

- Added `scripts/cardfront/entities/CardfrontAutomaticSpawnCoordinator.gd`.
- Automatic repair / armored guard / sapper placement now delegates to `DeploymentPlacementResolver`.
- Entity runtime was reduced below its existing 650-line architecture guard and no longer directly imports `DeploymentRules`.
- `CardfrontAuthoritativeCreatureActionCoordinator` exposes `spawn_*_at(...)` creation APIs for already-resolved cells.
- Compatibility `find_owner_spawn_cell()` / `find_adjacent_spawn_cell()` in the authoritative runtime coordinator now fail closed through the current resolver instead of using route-slot / arbitrary-owned-cell fallback.
- Repair behavior regression was decoupled from the retired legacy route-slot spawn origin by using an explicit frontline fixture.

## Preserved boundaries

```text
Territory Capture touched? NO
Support Capture semantics touched? NO
Creature movement legality touched? NO
Tower building-slot semantics touched? NO
Neutral Gate Colossus spawn touched? NO
Map topology changed? NO
Save schema changed? NO
Random automatic placement added? NO
Resolver-side BFS/connectivity inference added? NO
P1/P2 deployment exceptions added? NO
```

The old base `CardfrontCreatureActionCoordinator.gd` still physically contains legacy helper implementations for compatibility/history, but the production runtime instantiates `CardfrontAuthoritativeCreatureActionCoordinator.gd`, whose overrides route those helper entry points through the current placement authority. P0-04F additionally locks the production reference set so this dormant base implementation cannot silently regain authority.

## Deterministic placement contract

Source priority:

1. valid `preferred_support_id`;
2. preferred route-role Online Supports;
3. remaining Online Supports by deeper supplied graph depth;
4. stable lexical Support ID tie-break;
5. explicit Core source;
6. explicit failure.

Support cell ranking remains deterministic. Core fallback uses authored `spawn_zones`. No route building slot, arbitrary owned cell, origin, or random fallback is permitted for migrated automatic creature actions.

Failure contract:

```text
allowed = false
reason = no_valid_deployment_source
spawned = 0
```

The negative fixture deliberately leaves the old route building slot present while making all player deployment cells illegal and proves that no creature appears at the legacy origin.

## Automated evidence — same audited source

All evidence below is from `bd30e0cdcf11c10eaf3b5d2e54835a7c0cbd8e91`.

### Headless Tests — run `31376230274` — SUCCESS

Relevant job:

- `Cardfront P0 deployment pure` — SUCCESS
  - parse/import succeeds;
  - `CardfrontDeploymentAutomaticSpawnTestRunner.gd` succeeds;
  - existing deployment A-D tests remain green;
  - automatic source ranking, Core fallback, Support placement, explicit failure, and no legacy route-origin fallback are covered.

Relevant cross-system jobs in the same Headless run also remain green, including:

- `Cardfront v0.3 core loop`;
- `Cardfront live runtime boundary`;
- `Cardfront v0.3 tactical strongholds`;
- existing Support identity/capture/graph batches.

### Battlefield Entity Foundation Tests — run `31376230222` — SUCCESS

Confirms:

- Entity runtime boundary remains valid;
- live runtime regression passes;
- runtime module split does not break entity behavior.

### Shared Upgrade AI Tests — run `31376230249` — SUCCESS

Confirms automatic spawn migration did not regress the shared upgrade/AI cross-system surface.

### B1 Simulation Tests — run `31376230232` — SUCCESS

Confirms the larger simulation/deck/route-gate regression family remains green on the same source commit.

## Mandatory audit gates

```text
P0-04 four-consumer deployment convergence: PASS
Evidence bound to source commit: YES
Unverified deployment-authority assumptions remaining: NONE known
Legacy route-slot creature spawn authority reachable in production runtime: NO
Second deployment authority risk: PASS / guarded by P0-04F source contract
Save/restore risk introduced by this step: NONE
Cross-system regression evidence: PASS
Manual evidence required before this step GO: NONE beyond existing automated authority contract
```

## Residual risk / explicit non-claim

This checkpoint does **not** claim the historical base coordinator file has been deleted. It claims its old spawn helpers are no longer reachable as production placement authority through the current runtime assembly. Full legacy-code cleanup may happen only when the relevant later retirement step permits it.

## Decision

**GO** for P0-04E on audited source `bd30e0cdcf11c10eaf3b5d2e54835a7c0cbd8e91`.

Only allowed next step from this checkpoint: **P0-04F Four-Consumer Parity Matrix**.
