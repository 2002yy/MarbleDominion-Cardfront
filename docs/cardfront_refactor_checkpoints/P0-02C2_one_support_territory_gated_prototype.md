# P0-02C2 One-Support Territory-Gated Prototype

Source commit: `e522955`
Original intent: Prove one representative authored Support can be captured through existing territory-gated Creature movement without changing global movement legality.
Engineering Spec sections: 4.2 Support Capture; Batch A P0-02C2; Freeze Addendum sections 3-4.
Old authority: Support definitions had profile IDs but no resolved capture-footprint geometry or composed runtime proof.
Target authority: `SupportCaptureFootprints` resolves the authored profile; existing Battlefield, movement, registry, adapter, aggregator, and state machine remain their separate authorities.
Allowed mutation surface: Minimal footprint profile resolver, real-runtime headless prototype, workflow, checkpoint.
Read-only surface: Default map authored Support metadata and all existing runtime systems.
Forbidden changes: `next_owned_step_toward()`, territory/projectile capture implementation, live gameplay tick integration, suppression owner, deployment, map anchors/regions/routes, UI.
Old behaviors that must survive: Existing movement remains owned-territory-only; existing territory pressure opens approach cells.
Explicitly not solving: Production tick ownership, all-support balance, suppression calculation, graph, deployment, visuals, persistence.
Test evidence authority: `CardfrontSupportCaptureTerritoryPrototypeTestRunner.gd` on Godot 4.7.1.
Expected checkpoint: `P0-02C2_one_support_territory_gated_prototype.md`

## Actual prototype evidence

The runner uses the real 40x40 `default_duel`, stable `support_left_south`, its current authored anchor `(7, 30)`, real duel ownership initialization, real `Battlefield.apply_owner_change()`, real live entity runtime/registry, and the unchanged `next_owned_step_toward()` path.

Observed sequence:

1. A player Scout starts on owned `(7, 32)`, outside the radius-one cross footprint.
2. Movement refuses neutral `(7, 31)` and the Scout contributes nothing.
3. Existing territory authority changes `(7, 31)` to player ownership.
4. The unchanged movement rule selects `(7, 31)`; registry movement enters the footprint.
5. Scout control power advances and completes the suppressed enemy Support Claim.
6. An AI control Creature entering through AI-owned cells produces contested pause.
7. A zero-control Creature inside the footprint resolves zero power and cannot change Claim.

No map anchor, region, route, bridge, or global movement rule was changed. This proves feasibility for one representative Support; it is not whole-map playtest or balance acceptance.

## Freeze and audit fields

```text
Pre-Implementation Freeze reference: CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md
Frozen support topology affected? NO
Frozen deployment geometry affected? NO
Suppression/capture contract affected? YES - representative territory-gated capture composition only.
Automatic placement contract affected? NO
Deployment revision contract affected? NO
Amendment required? NO
Mandatory audit gates touched: P0-02 movement preservation and representative feasibility
Audit status per gate: PASS
Evidence bound to source commit: YES
Unverified assumptions remaining: Whole-map human feel and balance remain manual acceptance; production tick integration is intentionally absent.
Legacy authority still reachable: YES, unchanged.
Second-authority risk: NO; composed owners remain separate.
Save/restore risk: NOT APPLICABLE until P0-02D
Cross-system regression evidence: Real default map + Battlefield + runtime registry + existing movement headless runner.
Manual evidence required before GO: NO for representative technical feasibility; YES later for gameplay feel.
Test evidence authority: scripts/tests/CardfrontSupportCaptureTerritoryPrototypeTestRunner.gd
Stable IDs introduced/used: support_left_south
Runtime numeric IDs used as identity? NO
Territory capture touched? NO production mutation; existing territory authority is invoked as test evidence only.
Creature movement legality touched? NO
All spawn paths checked: unchanged/read-only
Derived states persisted as authority? NO
Legacy stronghold active consumers remaining: unchanged
Save compatibility impact: NONE
```

Decision: **GO**

Only allowed next step: **P0-02D Support Snapshot Contract**.
