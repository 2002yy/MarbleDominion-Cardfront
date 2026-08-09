# P0-01B1 Anchor to Runtime Region Mapping

Source commit: `c17bb7e4f70e204920ed05e10cd094c9b1627f62`
Original intent: Map authored stable Support identities to transient runtime regions by anchor cell, never by numeric ID or region order.
Engineering Spec sections: 3.2 static/runtime separation; Guardrails P0-01B; Batch A P0-01B1.
Old authority: `RegionMap` allocates transient numeric IDs from region creation order; it has no stable Support identity.
Target authority: `DeploymentSupportRegionMapper.bind()` validates definitions and produces an ephemeral `support_id -> runtime_region_id` lookup from authored anchors.
Allowed mutation surface: Pure mapping adapter, focused test, workflow entry, checkpoint.
Read-only surface: Map definitions, RegionMap allocation, map builder, gameplay, Stronghold, graph, capture, deployment, save, UI.
Forbidden changes: Numeric-ID identity assumptions, map geometry changes, live runtime wiring, gameplay fallback, Support state mutation.
Old behaviors that must survive: Current map construction and all live gameplay.
Explicitly not solving: Authoring Support metadata into maps, production map setup failure, graph connectivity, gameplay state, capture/deployment/save.
Test evidence authority: `CardfrontSupportRegionMapperTestRunner.gd` on Godot 4.7.1.
Expected checkpoint: `P0-01B1_anchor_runtime_region_mapping.md`

## Mapping contract

For each non-core definition the mapper:

1. validates its authored schema;
2. verifies the anchor is inside the current map;
3. calls `RegionMap.get_region_id(anchor_cell)`;
4. rejects NORMAL/non-controllable anchors;
5. rejects two non-core Supports resolving to the same runtime region;
6. returns bindings only when the entire batch validates.

Core nodes are graph roots, not legacy Stronghold regions, and therefore receive no runtime-region binding. Unknown neighbor IDs and duplicate Support IDs fail the batch.

The focused reorder fixture reverses the current `default_duel` region-definition list. Numeric IDs change, while each stable Support ID continues to resolve through its authored anchor. This proves the adapter does not encode `region_id == N` semantics.

## Freeze impact declaration

```text
Pre-Implementation Freeze reference: CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md
Frozen support topology affected? YES — neighbor reference validation only; graph resolution is absent.
Frozen deployment geometry affected? NO
Suppression/capture contract affected? NO
Automatic placement contract affected? NO
Deployment revision contract affected? NO
Amendment required? NO
```

## Mandatory audit fields

```text
Mandatory audit gates touched: P0-01 authored stable identity and runtime region reference boundary
Audit status per gate: PASS
Evidence bound to source commit: YES
Unverified assumptions remaining: Production map metadata and setup validation remain P0-01B2; no live binding is claimed.
Legacy authority still reachable: YES, unchanged.
Second-authority risk: Controlled; runtime region ID is output reference only and cannot select Support identity.
Save/restore risk: No binding is persisted; future restore must rebuild it from anchors.
Cross-system regression evidence: Focused pure mapping runner; production callers unchanged.
Manual evidence required before GO: NO
```

## Gate result

Decision: **GO**

Only allowed next step: **P0-01B2 Map Metadata Validation Only**.
