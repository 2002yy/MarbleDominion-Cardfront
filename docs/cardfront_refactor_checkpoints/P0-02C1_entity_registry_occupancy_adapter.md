# P0-02C1 Entity Registry Occupancy Adapter

Source commit: `9e0ec11c205b0beaf06016c636c40693d7d7f75b`
Original intent: Convert alive entity-registry records inside a Support footprint into explicit contributor DTOs.
Engineering Spec sections: 4.2 Support Capture; Batch A P0-02C1.
Old authority: No registry-to-Support-capture adapter existed.
Target authority: `SupportCaptureOccupancyAdapter.extract()` owns the narrow registry extraction seam.
Allowed mutation surface: New adapter, focused test/workflow, checkpoint.
Read-only surface: Existing entity registry/state and centralized capture profile mapping.
Forbidden changes: Territory/projectile capture calls, movement, state-machine integration, suppression, map geometry, deployment, UI.
Old behaviors that must survive: Existing registry, Creature, tower, projectile, movement, spawn, and save behavior.
Explicitly not solving: Footprint geometry, territory-gated runtime prototype, tick ownership, persistence.
Test evidence authority: `CardfrontSupportCaptureOccupancyAdapterTestRunner.gd` on Godot 4.7.1.
Expected checkpoint: `P0-02C1_entity_registry_occupancy_adapter.md`

## Extraction result

The adapter reads only `footprint cells -> registry.get_entities_at(cell)`. It produces deterministic DTOs for living duel-faction Creatures. Neutral entities, defense towers/buildings, dead/inactive entities, and records outside the footprint do not contribute. Unknown Creature IDs remain visible as fail-closed `non_control` DTOs with zero weight and `eligible=false`.

The adapter does not reference `CardfrontCaptureInterceptor`, `resolve_capture_contact()`, projectile contacts, combat stats, movement, or SceneTree discovery.

## Freeze and audit fields

```text
Pre-Implementation Freeze reference: CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md
Frozen support topology affected? NO
Frozen deployment geometry affected? NO
Suppression/capture contract affected? YES - occupancy extraction only.
Automatic placement contract affected? NO
Deployment revision contract affected? NO
Amendment required? NO
Mandatory audit gates touched: P0-02 registry extraction boundary
Audit status per gate: PASS
Evidence bound to source commit: YES
Unverified assumptions remaining: Real default-map footprint reachability remains P0-02C2.
Legacy authority still reachable: YES, unchanged.
Second-authority risk: NO; profile mapping remains centralized.
Save/restore risk: NOT APPLICABLE
Cross-system regression evidence: Focused real registry runner.
Manual evidence required before GO: NO for adapter contract.
Test evidence authority: scripts/tests/CardfrontSupportCaptureOccupancyAdapterTestRunner.gd
Stable IDs introduced/used: NONE
Runtime numeric IDs used as identity? NO
Territory capture touched? NO
Creature movement legality touched? NO
All spawn paths checked: unchanged/read-only
Derived states persisted as authority? NO
Legacy stronghold active consumers remaining: unchanged
Save compatibility impact: NONE
```

Decision: **GO**

Only allowed next step: **P0-02C2 One-Support Territory-Gated Prototype**.
