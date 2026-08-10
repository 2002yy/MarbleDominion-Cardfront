# P0-05A2 Bind Existing Default Map to Authored Graph

Audited source commit: `5a623c3fef46de4111a3a10d6a2e1bda40c87925`
Branch: `audit/p0-04e-auto-spawn`
Target step: **P0-05A2 — Bind Existing Default Map to Authored Graph**
Decision: **GO**
Evidence bound to audited source commit: **YES**

## Goal

Move the already-authored `default_duel` Support topology from pure fixtures into a narrow production runtime authority without changing the battlefield layout or combat rules.

This step binds only authored Support identity/topology/deployment metadata:

- stable `support_id` values;
- existing anchor cells;
- existing authored edges;
- existing physical route roles (`LEFT`, `RIGHT`, `CENTER_TRANSFER`, `CORE`);
- existing player/AI deploy directions and deployment profile IDs.

The two physical routes remain equal authored branches. This step does not introduce a hidden `MAIN > BRANCH` weighting that is absent from the frozen P0-05A1 route semantics.

## Implemented authority

- Added `CardfrontSupportDeploymentAuthority` as a runtime composition layer over the existing:
  - `SupportTopologyContract`;
  - `SupportTopologyValidator`;
  - `SupportConnectivityCache`;
  - `DeploymentSupportContext`.
- Both Core roots initialize as owned/operational permanent deployment roots.
- Non-Core Supports initialize offline until authoritative Claim/Operational state is supplied.
- Deployment contexts are built directly from the selected map's `deployment_supports` metadata.
- The live battlefield entity runtime receives this authority through the existing deployment-context provider seam.
- The authority is published on the battlefield as runtime metadata so later consumers can share the same object instead of rebuilding topology truth.

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

No Support capture signal is wired in this step. State mutation methods remain only the narrow input seam for later live-state cutover and deterministic runtime tests.

## Same-source automated evidence

All evidence below is from audited source `5a623c3fef46de4111a3a10d6a2e1bda40c87925`.

- Headless Tests — run `31397970735` — **SUCCESS**.
  - `Cardfront P0 support identity` — **SUCCESS**.
  - Headless Parse Check — **SUCCESS**.
  - Import Project — **SUCCESS**.
  - `CardfrontSupportMapMetadataTestRunner.gd` verifies the real `DefaultDuelMap.make()` projection, Core fallback, authored anchor/direction/profile/route role, upstream disconnect, and reconnect without recapture.
- Battlefield Entity Foundation Tests — run `31397969267` — **SUCCESS**.
- Shared Upgrade AI Tests — run `31397969380` — **SUCCESS**.
- B1 Simulation Tests — run `31397969404` — **SUCCESS**.

## Mandatory audit gates

```text
Test evidence authority: CardfrontSupportMapMetadataTestRunner.gd + same-source PR workflows
Stable IDs introduced/used: existing default_duel support_id values
Runtime numeric IDs used as identity? NO
Territory capture touched? NO
Creature movement legality touched? NO
All spawn paths checked: P0-04 authority unchanged; live automatic spawn consumes real-map runtime context provider
Derived states persisted as authority? NO
Legacy stronghold active consumers remaining: YES, intentionally unchanged until P0-05B1
Save compatibility impact: NONE
Map geometry changed? NO
Bridge/gate behavior changed? NO
Cross-system regression evidence: PASS
Manual/video evidence required: NO
```

## Decision

**GO** for P0-05A2 on audited source `5a623c3fef46de4111a3a10d6a2e1bda40c87925`.

Only allowed next step: **P0-05A3 — Branch Failure Scenarios**.
