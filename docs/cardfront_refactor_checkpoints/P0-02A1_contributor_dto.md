# P0-02A1 Contributor DTO

Source commit: `9f1f2da7dea005f3e994936aaec9c847064cb5a9`
Original intent: Define the complete, scene-independent input contract for pure Support Capture math.
Engineering Spec sections: 4.1 capture contributors; Batch A P0-02A1.
Old authority: No Support Capture contributor contract existed; entity runtime records remain live entity authority.
Target authority: `SupportCaptureContributor` owns the extracted DTO shape only.
Allowed mutation surface: New pure DTO, focused test/workflow, checkpoint.
Read-only surface: Entity registry/state, territory capture, Support state, maps, movement, combat, UI, save.
Forbidden changes: SceneTree reads, registry integration, implicit armor/movement/size weighting, gameplay side effects.
Old behaviors that must survive: All current entity and territory-capture behavior.
Explicitly not solving: Creature-to-profile mapping, aggregation, state transitions, occupancy extraction, territory gating.
Test evidence authority: `CardfrontSupportCaptureContributorTestRunner.gd` on Godot 4.7.1.
Expected checkpoint: `P0-02A1_contributor_dto.md`

## Contract

The DTO carries exactly `entity_id`, `owner_id`, `capture_profile`, `capture_weight`, `cell`, and `eligible`. It contains no Node, registry, SceneTree, armor, movement, size, damage, DPS, or rarity input. Eligibility and weight are explicit adapter outputs rather than deductions inside capture math.

Neutral/building/dead filtering is deliberately deferred to P0-02C1, where registry records can be read without contaminating the pure calculator.

## Freeze and audit fields

```text
Pre-Implementation Freeze reference: CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md
Frozen support topology affected? NO
Frozen deployment geometry affected? NO
Suppression/capture contract affected? YES — contributor input shape only.
Automatic placement contract affected? NO
Deployment revision contract affected? NO
Amendment required? NO
Mandatory audit gates touched: P0-02 territory_capture != support_capture and contributor extraction boundary
Audit status per gate: PASS
Evidence bound to source commit: YES
Unverified assumptions remaining: Registry eligibility extraction and all live integration remain future steps.
Legacy authority still reachable: YES, unchanged.
Second-authority risk: Controlled; DTO carries explicit data and owns no entity truth.
Save/restore risk: NOT APPLICABLE
Cross-system regression evidence: Focused pure runner only; no production caller.
Manual evidence required before GO: NO
```

Decision: **GO**

Only allowed next step: **P0-02A2 Capture Profile Mapping**.
