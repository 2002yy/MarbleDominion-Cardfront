# P0-02D Support Snapshot Contract

Source commit: `e5db034`
Original intent: Persist stable Support authority without persisting graph/occupancy/UI-derived truth or guessing a Stronghold migration.
Engineering Spec sections: 4.1-4.2 save authority; Batch A P0-02D; Freeze Addendum derived-state rules.
Old authority: `DeploymentSupportState.snapshot()` existed in isolation; the runtime snapshot schema had no Support container.
Target authority: `support_states` plus `SupportStateSnapshotCodec` define the additive persistence boundary.
Allowed mutation surface: Snapshot schema/codec, focused tests/workflow, checkpoint.
Read-only surface: Existing Support state DTO and legacy Stronghold compatibility field.
Forbidden changes: Live runtime wiring, graph computation, occupancy rebuild, implicit Stronghold migration, gameplay consumers, movement, deployment, UI.
Old behaviors that must survive: Existing schema fields roundtrip; `current_stronghold_bonuses` remains compatibility-readable.
Explicitly not solving: Production Support-state owner/capture hook, restore-time graph and occupancy execution, Stronghold cutover.
Test evidence authority: `CardfrontSupportSnapshotContractTestRunner.gd` and `CardfrontRuntimeSnapshotTestRunner.gd` on Godot 4.7.1.
Expected checkpoint: `P0-02D_support_snapshot_contract.md`

## Persistence policy

Persisted per stable `support_id`:

- `support_id`
- `claim_owner`
- `operational`
- `capture_side`
- `capture_progress`

Explicitly discarded/rebuilt:

- `network_connected` from the future Support graph
- derived `Online`
- `contested` from current occupancy
- visual state
- runtime-only idle timer

`support_states` is an additive optional field under the existing compatible schema. Missing legacy data defaults to empty. `current_stronghold_bonuses` remains readable but is never used to infer or overwrite Support Claim/operational state. Live capture/apply wiring is intentionally deferred because no production Support runtime owner exists yet.

## Freeze and audit fields

```text
Pre-Implementation Freeze reference: CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md
Frozen support topology affected? NO
Frozen deployment geometry affected? NO
Suppression/capture contract affected? NO
Automatic placement contract affected? NO
Deployment revision contract affected? NO
Amendment required? NO
Mandatory audit gates touched: Support save authority and legacy compatibility
Audit status per gate: PASS
Evidence bound to source commit: YES
Unverified assumptions remaining: Restore-time graph/occupancy recomputation requires their future runtime owners.
Legacy authority still reachable: YES - current_stronghold_bonuses remains compatibility-readable only; active consumers are unchanged pending P0-05.
Second-authority risk: NO; derived states are stripped.
Save/restore risk: Controlled by additive default-empty field and explicit codec.
Cross-system regression evidence: Existing runtime snapshot runner plus focused Support snapshot runner.
Manual evidence required before GO: NO for schema contract; future live runtime restore requires integration evidence.
Test evidence authority: scripts/tests/CardfrontSupportSnapshotContractTestRunner.gd; scripts/tests/CardfrontRuntimeSnapshotTestRunner.gd
Stable IDs introduced/used: support_id keys and payload fields
Runtime numeric IDs used as identity? NO
Territory capture touched? NO
Creature movement legality touched? NO
All spawn paths checked: unchanged/read-only
Derived states persisted as authority? NO
Legacy stronghold active consumers remaining: YES, unchanged pending P0-05
Save compatibility impact: Additive optional support_states; old payloads default empty; legacy Stronghold field preserved without implicit migration
```

Decision: **GO**

Only allowed next step: **P0-03A1 Topology Data Contract**.
