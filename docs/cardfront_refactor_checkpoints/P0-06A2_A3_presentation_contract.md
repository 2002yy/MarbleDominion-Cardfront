# P0-06A2/A3 Support Presentation Contract

Source commit: `ddb02f10e1e1caab1868679938ba048f68da9f02`
Branch: `audit/p0-04e-auto-spawn`
Target steps: **P0-06A2 — SupportPresentationSnapshot DTO** and **P0-06A3 — View-State Derivation Contract**
Evidence type: automated
Decision: **GO**

## Implemented boundary

`SupportPresentationSnapshot` is a detached presentation DTO containing only:

```text
support_id
anchor_cell
claim_owner
operational
network_connected
capture_side
capture_progress_normalized
contested
derived_view_state
```

`SupportPresentationSnapshotBuilder` is the only builder introduced in this step. It accepts authored definition data plus a public state dictionary, copies only the explicit scalar/value whitelist, clamps capture progress, rejects missing/mismatched stable IDs, and derives the view state. Extra graph, capture-controller, deployment-callback, or setter entries are ignored rather than retained.

Mutating the returned DTO cannot mutate the source Support definition or gameplay state. No mutable runtime reference, graph object, capture controller, deployment rule callback, or setter callback is present in the DTO.

## Single view-state derivation

`SupportPresentationViewState.derive()` is the only A3 derivation function. Priority is:

```text
CONTESTED
CAPTURING
DISABLED_NEUTRAL
ACTIVE
CAPTURED_OFFLINE
```

Detailed rules:

1. occupancy-derived `contested` overrides all other visuals;
2. a non-neutral capture side with positive normalized progress is `CAPTURING`;
3. neutral or non-operational/suppressed Support is `DISABLED_NEUTRAL`;
4. claimed + operational + connected is `ACTIVE`;
5. claimed + operational + disconnected is `CAPTURED_OFFLINE`.

This matches the existing gameplay truth-table priority where non-operational is Disabled before connectivity is considered. Visual nodes must consume `derived_view_state`; they must not recreate this decision tree.

## Automated evidence

Godot 4.7.1 focused run:

- `CardfrontSupportPresentationContractTestRunner.gd`: **PASS (32 checks)**.
- `CardfrontSupportStateTestRunner.gd`: **PASS (22 checks)**.
- `CardfrontSupportSnapshotContractTestRunner.gd`: **PASS (21 checks)**.
- `CardfrontSupportCaptureStateMachineTestRunner.gd`: **PASS (25 checks)**.
- `CardfrontSupportConnectivityTruthTestRunner.gd`: **PASS (14 checks)**.
- Combined focused evidence: **PASS (114 checks)**.
- Project headless parse/start-menu boot: **PASS**, no parser error.

The new presentation runner is included in the active `Cardfront P0 support identity` GitHub Actions batch.

## Mandatory audit fields

```text
Mandatory audit gates touched: P0-06 DTO boundary; presentation-only view-state derivation; stable Support identity
Audit status per gate: PASS
Evidence bound to source commit: YES — ddb02f10e1e1caab1868679938ba048f68da9f02
Highest-priority evidence used: automated
Unverified assumptions remaining: visual instance lifecycle, coordinate binding, and readability belong to P0-06B
Legacy authority still reachable: NO new legacy authority; no territory region input accepted by DTO builder
Second-authority risk: view-state derivation centralized in one function
Save/restore risk: NONE; presentation DTO is not persisted
Cross-system regression evidence: Support state, snapshot, capture, and graph truth runners
Manual evidence required before GO: NO for P0-06A2/A3
Video requested explicitly by product owner: NO
Stable IDs introduced/changed: NO; authored support_id is consumed
Runtime numeric IDs used as identity: NO
Territory capture touched: NO
Creature movement legality touched: NO
Deployment four-consumer authority touched: NO
P1/P2 leakage: NONE
```

## Exit

P0-06A2 and P0-06A3 are complete. No Support visual node has been created yet.

The only allowed next step is **P0-06B1 — One Visual Instance Per support_id**.
