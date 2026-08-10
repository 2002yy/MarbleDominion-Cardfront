# P0-05A3 Branch Failure Scenarios

Audited source commit: `84dfcddd13cd67db2c0c03e270e27487706b22e0`
Branch: `audit/p0-04e-auto-spawn`
Target step: **P0-05A3 — Branch Failure Scenarios**
Decision: **GO**
Evidence bound to audited source commit: **YES**

## Goal

Prove that the real `default_duel` authored graph behaves correctly when either physical branch loses upstream operational continuity, when both branches are cut, and when continuity is restored.

P0-05A1 froze the map as two equal physical branches (`LEFT` / `RIGHT`) plus an optional `CENTER_TRANSFER`; this checkpoint therefore interprets the execution-detail "main / branch" scenarios as the two frozen parallel routes. It does not introduce an unapproved route-priority hierarchy.

## Scenario matrix

The matrix runs from both faction roots so player south-to-north and AI north-to-south traversal are both covered.

1. **Both routes connected**
   - upstream and downstream Supports on LEFT are Online;
   - upstream and downstream Supports on RIGHT are Online.
2. **LEFT upstream offline, RIGHT connected**
   - LEFT upstream/downstream are removed from deployment authority;
   - RIGHT remains Online.
3. **RIGHT upstream offline, LEFT connected**
   - RIGHT upstream/downstream are removed from deployment authority;
   - LEFT remains Online.
4. **Both frontline routes offline**
   - no non-Core Support remains a deployment source.
5. **Core fallback survives**
   - the correct side-specific Core source remains present while all non-Core Supports are offline;
   - final Core placement legality remains covered by the existing P0-04 Core fallback regression.
6. **Reconnect without recapture**
   - downstream Claim ownership remains intact while disconnected;
   - restoring upstream Operational state restores downstream deployment authority without applying Claim again.

## Same-source automated evidence

All evidence below is from audited source `84dfcddd13cd67db2c0c03e270e27487706b22e0`.

- Headless Tests — run `31398873977` — **SUCCESS**.
  - `Cardfront P0 support identity` — **SUCCESS**.
  - Headless Parse Check — **SUCCESS**.
  - Import Project — **SUCCESS**.
  - `CardfrontSupportMapMetadataTestRunner.gd` exercises the complete six-scenario matrix from both faction roots.
- Battlefield Entity Foundation Tests — run `31398874050` — **SUCCESS**.
- Shared Upgrade AI Tests — run `31398873685` — **SUCCESS**.
- B1 Simulation Tests — run `31398873626` — **SUCCESS**.

## Explicitly unchanged

```text
Support capture runtime wiring: UNCHANGED
river/bridge geometry: UNCHANGED
gate projectile behavior: UNCHANGED
command chambers: UNCHANGED
creature movement legality: UNCHANGED
Stronghold rewards: UNCHANGED
save schema: UNCHANGED
```

## Mandatory audit gates

```text
Real default map used? YES
Both faction roots exercised? YES
Both equal routes exercised independently? YES
Both-routes-offline case covered? YES
Core fallback presence covered? YES
Reconnect without downstream recapture covered? YES
Territory capture semantics changed? NO
P0-04 deployment authority changed? NO
Stronghold gameplay changed? NO
Cross-system regression evidence: PASS
Manual/video evidence required: NO
```

## Decision

**GO** for P0-05A3 on audited source `84dfcddd13cd67db2c0c03e270e27487706b22e0`.

Only allowed next step: **P0-05B1 — Legacy Stronghold Gameplay Consumer-First Cutover**.
