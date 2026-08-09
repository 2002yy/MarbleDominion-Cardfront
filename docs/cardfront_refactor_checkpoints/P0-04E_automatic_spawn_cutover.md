# P0-04E Automatic / Upgrade Spawn Cutover

Source commit: `c36bbabad44d089262c130a03c16c248581d247e`
Original intent: Remove the automatic/upgrade creature spawn bypass so the fourth deployment consumer obtains its final cell from the same `DeploymentRules` authority as Player Commit, Preview, and AI.
Engineering Spec sections: 4.4 Deployment; Guardrails P0-04; Execution Detail Batch A P0-04E; Pre-Implementation Freeze Addendum section 5.
Old authority: `RoundDirector -> BattlefieldEntityRuntime.apply_pending_upgrade_actions() -> CreatureActionCoordinator.find_owner_spawn_cell() -> route building slot / nearest owned cell / origin fallback`.
Target authority: `DeploymentPlacementResolver` selects deterministically only among cells for which `DeploymentRules.evaluate()` returns allowed; `CardfrontBattlefieldEntityRuntime` resolves cells before entity creation and passes resolved cells to an authoritative creature coordinator.
Allowed mutation surface: Automatic/upgrade repair, armored-guard, and sapper placement; additive deployment context placement metadata; focused resolver/runtime test; CI registration; checkpoint.
Read-only surface: Territory capture, Support Capture, creature movement legality, tower building-slot placement, neutral Gate Colossus spawn, maps, save schema, Draft transaction semantics.
Forbidden changes: Route-slot/origin/arbitrary-owned-cell fallback for automatic creatures, AI/upgrade crossing exception, resolver-side BFS/connectivity inference, random placement, creature movement rewrite, tower placement migration, neutral-creature migration.
Test evidence authority: `CardfrontDeploymentAutomaticSpawnTestRunner.gd` plus existing P0 deployment batch on Godot 4.7.1.

## Cutover contract

Automatic player/AI creature actions now use this sequence:

```text
pending upgrade action
 -> current deployment context provider
    -> if no live provider is configured: explicit Core-only context from authored spawn_zones
 -> DeploymentPlacementResolver
 -> DeploymentRules.evaluate() for every candidate considered legal
 -> deterministic source/cell ranking
 -> entity occupancy/capacity guard
 -> resolved cells
 -> creature creation
```

`DeploymentPlacementResolver` does not traverse the Support graph or infer Online state. It consumes `support_sources`, `route_role`, `graph_depth`, and `deployment_revision` supplied by the current deployment context. Missing configured provider data fails closed; only the absence of a provider uses the explicit authoritative Core context.

Source ranking is frozen as preferred Support, preferred route role, deeper supplied authored graph depth, lexical stable Support ID, then Core. Support-cell ranking is rear distance, lateral distance, squared anchor distance, y, x. Core candidates are deterministic y then x because the Freeze Addendum does not impose an additional Core-local ranking rule.

Entity occupancy is a separate physical placement guard after deployment legality: faction creature cap and per-cell creature slots are preserved. Multi-unit repair placement pre-resolves all requested cells with temporary slot reservations before any creature is created.

## Structured spawn evidence

Each migrated pending creature action returns:

```text
action
allowed
reason
spawned
placements[]:
  cell
  resolved_support_id
  source_kind
  deployment_revision
  legal_candidate_count
  reason
```

Required negative fixture paints the entire battlefield as enemy-owned while the legacy player route building slot still exists. Expected result:

```text
allowed = false
reason = no_valid_deployment_source
spawned = 0
no entity at legacy route origin
```

## Audit fields

```text
Stable IDs introduced/used: existing support_id / Core IDs only
Runtime numeric IDs used as identity? NO
Territory capture touched? NO
Support Capture touched? NO
Creature movement legality touched? NO
Tower route building-slot semantics touched? NO
Neutral creature spawn semantics touched? NO
Automatic creature route-slot fallback remaining in production call chain? NO (subject to CI/static diff verification)
Deployment legality authority duplicated? NO
Resolver performs BFS/connectivity inference? NO
Random automatic placement added? NO
Derived connectivity persisted as authority? NO
Save compatibility impact: NONE
Amendment required? NO
```

## Evidence status

Implementation branch: `audit/p0-04e-auto-spawn`

Automated evidence required before GO:

```text
runner: scripts/tests/CardfrontDeploymentAutomaticSpawnTestRunner.gd
command: GitHub Actions Headless Tests / Cardfront P0 deployment pure
expected focused coverage:
- preferred Support ranking
- preferred route ranking
- deeper graph-depth ranking
- lexical tie
- deterministic Support cell ranking
- Core fallback
- live upgrade spawn uses Support authority
- no-provider runtime uses explicit Core authority
- no legal source fails with no_valid_deployment_source
- legacy route origin is not used as hidden fallback
```

Cross-system evidence required before GO:

- Headless Parse Check passes.
- Existing P0 deployment A-D runners remain green.
- Cardfront v0.3 core loop remains green, especially entity-card/armored-guard/sapper behavior.
- Cardfront live runtime boundary remains green.
- No diff to `next_owned_step_toward()` or global creature movement legality.

Decision: **PENDING CI / NOT GO YET**

Only after the required evidence passes may this checkpoint be amended to **GO** and P0-04F Four-Consumer Parity begin.
