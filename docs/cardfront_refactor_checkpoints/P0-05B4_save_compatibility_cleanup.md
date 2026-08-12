# P0-05B4 Save Compatibility Cleanup

Audited source commit: `7fc4a3b82ad57b6cec340c2ef36da54121942363`
Branch: `audit/p0-04e-auto-spawn`
Target step: **P0-05B4 — Save Compatibility Cleanup (corrected audit)**
Decision: **GO**

## Correction

The earlier checkpoint incorrectly stated that Cardfront had no implemented runtime snapshot. Source inspection and CI proved that `CardfrontRuntimeSnapshot.gd` is active. That false repository-reality statement is superseded by this checkpoint.

The active snapshot previously serialized, deserialized, captured, and restored the retired Stronghold reward dictionary. The live `CardfrontRoundDirector` had already moved to status-only Stronghold observation, so the stale snapshot path both violated the retirement boundary and referenced a removed runtime property.

## Corrected compatibility boundary

`CardfrontRuntimeSnapshot` now:

- does not write the retired Stronghold reward field;
- ignores that unknown field when reading an older dictionary;
- does not re-emit it during roundtrip;
- does not restore it into `CardfrontRoundDirector`;
- never maps it into Support state, connectivity, deployment, Draft size, attack level, or volley count.

The schema version remains `2.0`: older dictionaries remain readable because unknown keys are ignored, while newly emitted dictionaries contain only current authority. This is a compatibility cleanup, not a migration of legacy reward data.

## Evidence

- `CardfrontRuntimeSnapshotTestRunner.gd`: **PASS (39 checks)**.
- `CardfrontSupportSnapshotContractTestRunner.gd`: **PASS (21 checks)**.
- An old payload containing the retired field is accepted, omitted from the new payload, and produces no Support state.
- Production source search finds no retired Stronghold reward snapshot token.

## Mandatory audit fields

```text
Mandatory audit gates touched: P0-05 save compatibility; derived-state persistence; legacy authority retirement
Audit status per gate: PASS
Evidence bound to source commit: YES — 7fc4a3b82ad57b6cec340c2ef36da54121942363
Highest-priority evidence used: automated
Unverified assumptions remaining: none affecting save/gameplay authority
Legacy authority still reachable: NO through CardfrontRuntimeSnapshot
Second-authority risk: NONE introduced
Save/restore risk: older retired reward data is intentionally ignored
Cross-system regression evidence: runtime snapshot + Support snapshot focused runners
Manual evidence required before GO: NO
Video requested explicitly by product owner: NO
Stable IDs introduced/changed: NO
Runtime numeric IDs used as persistent identity: NO
Territory capture touched: NO
Creature movement legality touched: NO
Deployment four-consumer authority touched: NO
P1/P2 leakage: NONE
```

Only allowed next step: **P0-05B5 — Global Legacy Search Gate**.
