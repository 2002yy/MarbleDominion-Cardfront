# P0-05A2 Bind Existing Default Map to Authored Graph

Branch: `audit/p0-04e-auto-spawn`
Target step: **P0-05A2 — Bind Existing Default Map to Authored Graph**
Decision: **PENDING CI**
Evidence bound to candidate source commit: **PENDING**

## Goal

Move the already-authored `default_duel` Support topology from pure fixtures into a narrow production runtime authority without changing the battlefield layout or combat rules.

This step binds only authored Support identity/topology/deployment metadata:

- stable `support_id` values;
- existing anchor cells;
- existing authored edges;
- existing physical route roles (`LEFT`, `RIGHT`, `CENTER_TRANSFER`, `CORE`);
- existing player/AI deploy directions and deployment profile IDs.

The two physical routes remain equal authored branches. This step does not introduce a hidden `MAIN > BRANCH` weighting that is absent from the frozen P0-05A1 route semantics.

## Candidate implementation

- Add `CardfrontSupportDeploymentAuthority` as a runtime composition layer over the existing:
  - `SupportTopologyContract`;
  - `SupportTopologyValidator`;
  - `SupportConnectivityCache`;
  - `DeploymentSupportContext`.
- Initialize both Core roots as owned/operational permanent deployment roots.
- Initialize non-Core Supports offline until authoritative Claim/Operational state is supplied.
- Build deployment contexts directly from the selected map's `deployment_supports` metadata.
- Bind the live battlefield entity runtime to this authority through the existing deployment-context provider seam.
- Publish the authority on the battlefield as runtime metadata so later consumers can share the same object instead of rebuilding topology truth.

## Explicitly unchanged

```text
river geometry: UNCHANGED
bridges: UNCHANGED
gate projectile openness: UNCHANGED
command chambers: UNCHANGED
territory capture semantics: UNCHANGED
creature movement legality: UNCHANGED
Factory/Energy/Lab gameplay bonuses: UNCHANGED
```

No Support capture signal is wired in this step. State mutation methods exist only as the narrow input seam for the later live-state cutover and deterministic runtime tests.

## Automated evidence to run

Existing CI runner `CardfrontSupportMapMetadataTestRunner.gd` is extended so the already-authoritative Headless Tests workflow verifies:

1. runtime topology is projected from the real `DefaultDuelMap.make()` definitions;
2. Core-only fallback remains available before any non-Core Support is online;
3. an online Support source inherits the exact authored anchor, route role, deploy direction, and profile;
4. an upstream operational cut removes disconnected downstream Support from deployment authority;
5. reconnect restores a still-owned downstream Support without recapture.

Cross-system regression gates remain the existing PR workflows:

- Headless Tests;
- Battlefield Entity Foundation Tests;
- Shared Upgrade AI Tests;
- B1 Simulation Tests.

## Mandatory audit gates

```text
Test evidence authority: CardfrontSupportMapMetadataTestRunner.gd + existing PR workflows
Stable IDs introduced/used: existing default_duel support_id values
Runtime numeric IDs used as identity? NO
Territory capture touched? NO
Creature movement legality touched? NO
All spawn paths checked: P0-04 authority unchanged; live automatic spawn now consumes real-map runtime context provider
Derived states persisted as authority? NO
Legacy stronghold active consumers remaining: YES, intentionally unchanged until P0-05B1
Save compatibility impact: NONE
Map geometry changed? NO
Bridge/gate behavior changed? NO
```

## Exit

Do not mark this checkpoint GO until the candidate commit has same-source green CI evidence.

After GO, only allowed next step: **P0-05A3 — Branch Failure Scenarios**.
