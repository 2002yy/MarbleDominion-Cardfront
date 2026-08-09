# P0-00F Pre-Implementation Battle-line Freeze Verification

```text
Source commit: e9ebe70fa7168ec872f2b4edb1be233f6b3eaa20
DefaultDuel support mapping verified: YES
Support IDs and anchor sources: Seven authored stable IDs; five non-core anchors come from the existing DefaultDuelMap left/right/top/bottom/center geometry calculations, while core_player and core_ai are authored battle-line roots rather than legacy regions.
Frozen topology reproduced exactly: YES
Directional geometry reproduced for 40x40: YES
Directional geometry reproduced for 50x50: YES
Directional geometry reproduced for 40x50: YES
Directional geometry reproduced for 40x60: YES
Suppression event source identified: Current territory ownership share over an authored suppression footprint supplies evidence; the future Support runtime owns operational state transitions.
Support capture owner identified: A dedicated future Support Capture runtime/state owner; eligible control creatures may progress takeover only after an enemy Support is non-operational.
Automatic spawn old bypass path identified: YES; upgrade creature/tower/Gate-Colossus and automatic tower-summon paths bypass DeploymentRules today.
Deployment revision invalidation sources identified: YES; claim, operational, connectivity, legitimate topology, profile/geometry revision, initialization, and restore rebuild.
Contradictions found: None. Current runtime does not yet implement the frozen Support model; this checkpoint verifies implementability and exact migration inputs, not completion.
Decision: GO
```

## 1. Stable identity and `default_duel` mapping

The stable authored identities are exactly:

```text
core_player
support_left_south
support_right_south
support_center
support_left_north
support_right_north
core_ai
```

Runtime `region_id`, region-array position, legacy region type, screen/world position, and lane index are explicitly rejected as identity sources. This agrees with the current `RegionMap` allocation audit: numeric region IDs are runtime references, not stable Support IDs.

The current `DefaultDuelMap.make()` region geometry reproduces the frozen migration mapping:

| Stable ID | Existing anchor | Legacy region type | Route role |
|---|---:|---|---|
| `support_left_north` | `(left_x, top_y)` | ENERGY | LEFT |
| `support_right_north` | `(right_x, top_y)` | FACTORY | RIGHT |
| `support_center` | `(center_x, center_y)` | LAB | CENTER_TRANSFER |
| `support_left_south` | `(left_x, bottom_y)` | FACTORY | LEFT |
| `support_right_south` | `(right_x, bottom_y)` | ENERGY | RIGHT |

`core_player` and `core_ai` are graph roots and do not impersonate old Stronghold regions. During P0-01, the map definition must author `support_id`, `anchor_cell`, neighbors, route role, side directions, deployment profile, capture profile, and suppression footprint/profile. The Support runtime must consume those authored values and must not duplicate the map sizing formula.

## 2. Exact frozen topology

The verified undirected edge set contains exactly ten edges:

```text
core_player <-> support_left_south
core_player <-> support_right_south
support_left_south <-> support_left_north
support_right_south <-> support_right_north
support_left_south <-> support_center
support_right_south <-> support_center
support_center <-> support_left_north
support_center <-> support_right_north
support_left_north <-> core_ai
support_right_north <-> core_ai
```

This preserves two independent direct north/south routes, with the center as a cross-route transfer rather than a mandatory articulation point. Current Gate connectivity remains projectile-routing infrastructure and is not reused as SupportGraph authority. Runtime distance, region adjacency, lane centers, or unit positions may not add or remove these edges.

## 3. Directional geometry reproduction

The only ordinary P0 Support profile is `DIRECTIONAL_REAR_RECT_V1`.

```text
player forward = (0, -1)
AI forward     = (0, +1)
lateral_half_width_cells = max(2, round(min_axis * 0.075))
rear_depth_cells         = max(2, round(min_axis * 0.10))
```

Using the actual `DefaultDuelMap.make()` anchor formula and the frozen geometry formula gives:

| Extent | left/right | top/bottom | center | half width | rear depth | Result |
|---|---|---|---|---:|---:|---|
| 40x40 | 7 / 32 | 9 / 30 | (20,20) | 3 | 4 | reproduced |
| 50x50 | 9 / 40 | 11 / 38 | (25,25) | 4 | 5 | reproduced |
| 40x50 | 7 / 32 | 11 / 38 | (20,25) | 3 | 4 | reproduced |
| 40x60 | 7 / 32 | 13 / 46 | (20,30) | 3 | 4 | reproduced |

The rectangle is candidate geometry only. A front cell is outside the ordinary Support zone; final legality still requires map bounds, current source Online state, existing block/reservation constraints, and authoritative `DeploymentRules` approval. Overlapping valid source zones form a union, with the frozen distance then lexical-ID tie-break used only to explain the resolved source.

## 4. Suppression and Capture authority

The current territory system supplies `claim_owner_local_share` evidence over an authored footprint. The future Support runtime alone transitions `operational` using the frozen 40% suppress / 60% recover hysteresis. Territory/projectile capture continues to belong to `CardfrontCaptureInterceptor`; it must not change Support Claim directly.

The future Support Capture runtime/state owner consumes eligible control-creature contributors. Enemy takeover cannot progress while that Support remains operational. Contested contributors freeze progress; no contributors hold for 2.0 seconds and then decay toward zero at the frozen 0.25 multiplier. Claim change does not imply immediate Online state; operational recovery and graph connectivity are re-evaluated separately. Current normal Creature movement remains restricted to owned territory and is not broadened by this contract.

## 5. Existing placement bypasses and frozen resolver boundary

The old bypasses are concrete:

- `CardfrontUpgradeResolver` queues entity actions, then `CardfrontBattlefieldEntityRuntime.apply_pending_upgrade_actions()` dispatches repair units, Armored Guard, Sapper, tower, and Gate-Colossus actions.
- Creature actions call `CardfrontCreatureActionCoordinator.find_owner_spawn_cell()` and adjacent-cell selection before `CardfrontBattlefieldEntityRegistry.spawn_creature()`.
- Tower actions select fixed route-building slots before `spawn_defense_tower()`.
- Gate Colossus uses `CardfrontNeutralCreatureSystem._spawn_candidates()` around gate cells.
- `CardfrontTowerRuntime.process_summons()` uses the adjacent-cell helper and calls the registry directly.

None of these paths currently asks `DeploymentRules` for placement authorization. The adjacent helper can also return its origin after failing to find an owned/available candidate. These are migration facts for P0-04, not defects repaired in P0-00F.

The future placement resolver may rank only candidates already proven legal by `DeploymentRules`. It cannot become a second legality authority and cannot fall back to the old origin, route slot, arbitrary owned cell, or an AI-only exception. No legal Support source leads to Core fallback; no legal Core cell leads to explicit `no_valid_deployment_source`.

## 6. Deployment revision boundary

The monotonic `deployment_revision` advances for:

- Support `claim_owner` change;
- Support `operational` change;
- connectivity result/revision change;
- explicit legitimate authored/runtime topology change;
- deployment profile or geometry revision change;
- map/Support runtime initialization or post-restore rebuild.

It does not advance for hover, UI redraw, Draft timer ticks, sub-threshold capture progress, projectile frame steps, or camera motion. Cache identity includes side, deployment profile, and revision. Preview may remember a revision for staleness display, but Commit always revalidates against current state and current rules.

## Contradiction audit

- The existing five-region geometry can author all five non-core Support anchors exactly.
- The existing two-lane strategy metadata is compatible with two direct routes plus a center transfer.
- Current territory capture, Creature movement, Gate routing, and old automatic spawn ownership are separable from the frozen new authorities.
- The current old Stronghold effects are still live, but P0-00C and P0-00E explicitly require retirement at the later P0-05 cutover; they are not silently preserved as Support bonuses.
- No source fact requires a different topology, dynamic direction, 360-degree zone, Support HP system, global free movement, or a second graph/rules authority.

No amendment is required before implementation.

## Mandatory audit fields

```text
Mandatory audit gates touched: P0-00F Pre-Implementation Battle-line Freeze Verification
Audit status per gate: PASS
Evidence bound to source commit: YES
Unverified assumptions remaining: None that changes the frozen implementation contract. Runtime implementation and its required tests remain future P0-01 through P0-05 work.
Legacy authority still reachable: YES at this pre-implementation commit; retirement is mandatory at P0-05 and cannot be reinterpreted as Support behavior.
Second-authority risk: Identified and bounded; Region ID, GateConnectivity, placement resolver, territory capture, and Preview cannot become alternate Support/graph/deployment authorities.
Save/restore risk: Future graph-derived state must rebuild after restore; old Stronghold snapshot fields may remain compatibility-read only after retirement.
Cross-system regression evidence: P0-00E focused golden runner plus prior P0-00B baseline. No full-suite rerun is claimed for this docs-only gate.
Manual evidence required before GO: NO under the approved manual-acceptance cadence.
```

## Gate result

Decision: **GO**

Only allowed next step: **P0-01A1 Stable Support IDs**. This checkpoint does not begin it.
