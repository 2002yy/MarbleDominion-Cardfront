# P0-05B5 Global Legacy Search Gate

Audited source commit: `7fc4a3b82ad57b6cec340c2ef36da54121942363`
Branch: `audit/p0-04e-auto-spawn`
Target step: **P0-05B5 — Global Legacy Search Gate**
Decision: **PENDING CI / NOT GO YET**

## Goal

Close P0-05 by proving that retired Factory / Energy / Lab numeric reward authority is absent from Cardfront production code, save/restore, and simulation consumers while retaining historical evidence only in tests and checkpoints.

## CI failure corrected

The previous audited source was not eligible for GO:

- all four CI workflows bound to `b751924` were cancelled by later pushes;
- the latest branch CI then found four real production residues;
- `CardfrontRuntimeSnapshot` still carried the retired Stronghold reward dictionary;
- `CardfrontBalanceMatchSimulator` still referenced the deleted Lab, Factory, and Energy reward constants;
- those references broke compilation for Hero, Parity, Shared AI, and B1 simulation runners.

Commit `7fc4a3b` removes the snapshot authority and makes the simulator use the formal three-choice Draft plus normal volley/attack state with no Stronghold numeric reward injection.

## Production gate

`CardfrontStrongholdSystemTestRunner.gd` recursively scans `res://scripts/cardfront/**/*.gd` and rejects the retired authority vocabulary. The current source scan is clean. Historical tests and checkpoint text may still name old fields as migration evidence; they are not production authority.

Stronghold runtime observation remains status-only:

```text
sample_status()
get_owner_status()
get_region_activation()

status schema:
active_types
active_regions
control_percent
```

Stronghold activation may remain observable for map/status and timeout telemetry, but it does not change Draft size, volley count, or attack level.

## Local focused evidence

Godot 4.7.1:

- Stronghold source/status gate: **PASS (2,311 checks)**.
- Runtime snapshot: **PASS (39 checks)**.
- Support snapshot boundary: **PASS (21 checks)**.
- Hero simulation reduced-seed contract: **PASS (31 checks)**.
- Parity reduced-seed contract: **PASS (8 checks)**.
- Shared AI reduced-seed contract: **PASS (8 checks)**.
- B1 deck candidate reduced probe: **PASS (21 checks)**.
- B1 162-match matrix configuration: **PASS (40 checks)**.
- B1 opening reduced probe: **PASS (30 checks)**.

The reduced simulations prove compilation, deterministic completion, offer validity, and contract shape. They do not replace the configured GitHub Actions seed counts or final numeric evidence.

## Mandatory audit fields

```text
Mandatory audit gates touched: P0-05 global legacy search; save compatibility; cross-system simulation
Audit status per gate: production search PASS; focused regression PASS; active CI PENDING
Evidence bound to source commit: YES — 7fc4a3b82ad57b6cec340c2ef36da54121942363
Highest-priority evidence used: automated
Unverified assumptions remaining: configured CI seed counts and full workflow matrix
Legacy authority still reachable: NONE found in production source
Second-authority risk: NONE introduced
Save/restore risk: corrected in P0-05B4
Cross-system regression evidence: focused Stronghold/snapshot/Hero/Parity/Shared AI/B1 runners
Manual evidence required before GO: NO for this source gate
Video requested explicitly by product owner: NO
Stable IDs introduced/changed: NO
Runtime numeric IDs used as identity: NO new use
Territory capture touched: NO
Creature movement legality touched: NO
Deployment four-consumer authority touched: NO
P1/P2 leakage: NONE
```

## Exit gate

Do not mark GO until active CI for the branch tip containing audited source `7fc4a3b82ad57b6cec340c2ef36da54121942363` confirms the source gate and cross-system regressions.

If green, P0-05 closes and the only allowed next step is **P0-06 — Support Presentation**.
