# P0-02B1 Support Capture State Machine

Source commit: `344744c`
Original intent: Define Support claim progress and completion as a pure, deterministic state transition.
Engineering Spec sections: 4.2 Support Capture; Batch A P0-02B1; Freeze Addendum sections 3-4.
Old authority: No Support capture transition owner existed.
Target authority: `SupportCaptureStateMachine.step()` accepts only current state, two resolved powers, delta, and tuning.
Allowed mutation surface: New pure transition, centralized timing tuning, focused test/workflow, checkpoint.
Read-only surface: Existing runtime support DTO/status derivation.
Forbidden changes: SceneTree/registry reads, suppression evidence calculation, connectivity resolution, persistence, territory capture, movement, deployment, UI.
Old behaviors that must survive: Existing territory/projectile capture, Creature behavior, spawn, Stronghold, and save paths.
Explicitly not solving: Runtime occupancy, local territory-share suppression, graph connectivity, snapshot policy, visuals.
Test evidence authority: `CardfrontSupportCaptureStateMachineTestRunner.gd` on Godot 4.7.1.
Expected checkpoint: `P0-02B1_support_capture_state_machine.md`

## Transition contract

- One side advances using its already-resolved capture power.
- Both sides set `contested` and freeze progress without idle decay.
- Nobody holds progress for 2.0 seconds, then decays at 0.25 of the standard base rate; zero clears `capture_side`.
- An operational enemy-owned Support blocks takeover until the separate suppression owner makes it non-operational.
- Completion changes Claim but leaves the Support non-operational and disconnected. Operational recovery and graph connectivity remain separate later authorities.
- Runtime-only `capture_idle_seconds`, derived `contested`, and cached `network_connected` are transition data here, not persistent snapshot authority.

The pure result also returns one-step audit flags `claim_changed`, `capture_completed`, and `previous_claim_owner`; no live runtime consumer is connected in this micro-step.

## Freeze and audit fields

```text
Pre-Implementation Freeze reference: CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md
Frozen support topology affected? NO
Frozen deployment geometry affected? NO
Suppression/capture contract affected? YES - frozen prerequisite, contest, idle, and completion semantics implemented purely.
Automatic placement contract affected? NO
Deployment revision contract affected? NO
Amendment required? NO
Mandatory audit gates touched: P0-02 pure transition contract
Audit status per gate: PASS
Evidence bound to source commit: YES
Unverified assumptions remaining: Runtime suppression/occupancy/connectivity adapters remain future checkpoints.
Legacy authority still reachable: YES, unchanged.
Second-authority risk: NO; runtime is not integrated yet.
Save/restore risk: Deferred explicitly to P0-02D; idle and derived fields are not added to persistence.
Cross-system regression evidence: Focused pure runner plus existing state truth derivation.
Manual evidence required before GO: NO for pure transitions; runtime integration requires later evidence.
Test evidence authority: scripts/tests/CardfrontSupportCaptureStateMachineTestRunner.gd
Stable IDs introduced/used: Existing support_id only
Runtime numeric IDs used as identity? NO
Territory capture touched? NO
Creature movement legality touched? NO
All spawn paths checked: unchanged/read-only
Derived states persisted as authority? NO
Legacy stronghold active consumers remaining: unchanged
Save compatibility impact: NONE
```

Decision: **GO**

Only allowed next step: **P0-02C1 Entity Registry Occupancy Adapter**.
