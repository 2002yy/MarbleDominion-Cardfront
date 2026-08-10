# P0-05A3 Branch Failure Scenarios

Branch: `audit/p0-04e-auto-spawn`
Target step: **P0-05A3 — Branch Failure Scenarios**
Decision: **PENDING CI**
Evidence bound to candidate source commit: **PENDING**

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

## Candidate implementation

Extend the already-authoritative `CardfrontSupportMapMetadataTestRunner.gd` rather than changing workflow configuration or creating an unexecuted test entrypoint.

The new matrix uses the same `CardfrontSupportDeploymentAuthority` introduced in P0-05A2 and the real `DefaultDuelMap.make(Vector2i(40, 40))` definitions. No alternate topology fixture is created for this checkpoint.

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

## Evidence to run

Primary evidence:

- Headless Tests / `Cardfront P0 support identity`
  - parse;
  - import;
  - extended `CardfrontSupportMapMetadataTestRunner.gd`.

Cross-system regression:

- Headless Tests full matrix;
- Battlefield Entity Foundation Tests;
- Shared Upgrade AI Tests;
- B1 Simulation Tests.

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
Manual/video evidence required? NO
```

## Exit

Do not mark this checkpoint GO until the candidate source commit has same-source green CI evidence.

After GO, only allowed next step: **P0-05B1 — Legacy Stronghold Gameplay Consumer-First Cutover**.
