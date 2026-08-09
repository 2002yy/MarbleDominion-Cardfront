# P0-02A2 Capture Profile Mapping

Source commit: `9a7d0bc61cbfb6164cc65969ed3a2aa53a937b3d`
Original intent: Centralize representative Creature-to-capture-profile and profile-to-weight/tag mappings.
Engineering Spec sections: 4.2 capture weights; Batch A P0-02A2.
Old authority: Creature state exposes no capture weight; combat/mobility fields must not become implicit capture rules.
Target authority: `SupportCaptureProfiles` is the sole pure profile/weight lookup seam.
Allowed mutation surface: New mapping data/API, focused test/workflow, checkpoint.
Read-only surface: Creature state/runtime, combat stats, movement, registry, capture state machine, UI.
Forbidden changes: Full unit-stat redesign, DPS-derived capture, armor/movement inference, new classes or gameplay effects.
Old behaviors that must survive: Existing Creature combat, movement, lifetime, and spawn behavior.
Explicitly not solving: Registry extraction, aggregation curve, capture transitions, user-facing labels.
Test evidence authority: `CardfrontSupportCaptureProfileTestRunner.gd` on Godot 4.7.1.
Expected checkpoint: `P0-02A2_capture_profile_mapping.md`

## Mapping

The initial verification representatives are explicitly mapped: Scout 2.0, Repair Unit 1.0, Sapper 1.0, Armored Guard 0.5, and neutral Gate Colossus 0.0. Unknown creature/profile IDs fail closed to `non_control` and zero weight.

These are centralized Yellow tuning values. They are not inferred from armor, movement, size, damage, DPS, rarity, or AI difficulty, and no production entity class was modified.

## Freeze and audit fields

```text
Pre-Implementation Freeze reference: CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md
Frozen support topology affected? NO
Frozen deployment geometry affected? NO
Suppression/capture contract affected? YES — centralized profile data only.
Automatic placement contract affected? NO
Deployment revision contract affected? NO
Amendment required? NO
Mandatory audit gates touched: P0-02 contributor weight authority
Audit status per gate: PASS
Evidence bound to source commit: YES
Unverified assumptions remaining: Live registry extraction and balance acceptance remain future evidence.
Legacy authority still reachable: YES, unchanged.
Second-authority risk: Controlled; one profile registry owns weights.
Save/restore risk: NOT APPLICABLE
Cross-system regression evidence: Focused pure runner; no production caller.
Manual evidence required before GO: NO
```

Decision: **GO**

Only allowed next step: **P0-02A3 Diminishing Aggregator**.
