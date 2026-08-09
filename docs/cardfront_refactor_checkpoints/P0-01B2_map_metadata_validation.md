# P0-01B2 Map Metadata Validation Only

Source commit: `b553857f4c4bf1b1b5ec100266462cfd8181122f`
Original intent: Author and fail-fast validate `default_duel` Support topology metadata without starting Support gameplay.
Engineering Spec sections: 3.2 static definition; Guardrails P0-01B; Freeze Addendum section 1; Batch A P0-01B2.
Old authority: `DefaultDuelMap` authored five legacy regions and route metadata but no stable Support nodes or edges.
Target authority: `DefaultDuelMap.deployment_supports` is the authored topology source; `DeploymentSupportMapMetadata` owns structural validation; `CardfrontMapBuilder` refuses invalid Support metadata before painting regions.
Allowed mutation surface: Default map metadata only, pure validator, validation seam, focused tests/workflow, checkpoint.
Read-only surface: Region geometry formulas, bridges/routes/spawn zones, Stronghold gameplay, graph/capture/deployment/runtime state, save, UI, AI.
Forbidden changes: Geometry changes, runtime Support activation, graph resolution, capture/deployment behavior, old bonus retirement, visuals/cards/resources.
Old behaviors that must survive: Existing five regions, route metadata, spawn zones, Stronghold effects, and all current match behavior.
Explicitly not solving: Support runtime construction, graph connectivity, capture/suppression, deployment zones, automatic spawn migration, save integration.
Test evidence authority: `CardfrontSupportMapMetadataTestRunner.gd` plus existing map-definition focused test where relevant.
Expected checkpoint: `P0-01B2_map_metadata_validation.md`

## Authored result

`default_duel` now carries seven pure metadata definitions with:

- exact frozen stable IDs;
- five non-core anchors derived from the existing `left_x/right_x/top_y/bottom_y/center` calculations;
- Core anchors aligned with current command-chamber cells, without pretending they are legacy regions;
- exact ten undirected frozen edges;
- LEFT, RIGHT, CENTER_TRANSFER, and CORE route roles;
- frozen side directions and profile references.

No region geometry, bridge, route, spawn zone, or gameplay consumer changed. The metadata is not yet instantiated as live Support runtime.

## Validation result

The pure validator rejects malformed definitions, duplicate IDs, duplicate non-core anchors, unknown neighbors, asymmetric edges, and incorrect core classification. For `default_duel`, it additionally requires the exact seven IDs, ten frozen edges, and per-node route roles, so a structurally valid but design-drifted graph also fails. `CardfrontMapDefinition.validate()` exposes these errors. `CardfrontMapBuilder` checks only the Support metadata seam before applying a definition, preserving older map construction behavior when the metadata key is absent while ensuring an authored invalid topology cannot silently enter battle.

The focused fixture verifies the exact ten-edge set, all seven IDs, five anchor mappings, and deterministic anchors for 40x40, 50x50, 40x50, and 40x60. It also proves metadata contains no runtime truth or legacy bonus fields.

## Freeze impact declaration

```text
Pre-Implementation Freeze reference: CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md
Frozen support topology affected? YES — reproduced exactly as authored metadata.
Frozen deployment geometry affected? NO — only profile/direction references are authored.
Suppression/capture contract affected? NO — only profile references are authored.
Automatic placement contract affected? NO
Deployment revision contract affected? NO
Amendment required? NO
```

## Mandatory audit fields

```text
Mandatory audit gates touched: P0-01 stable identity, map metadata, second-authority prevention
Audit status per gate: PASS
Evidence bound to source commit: YES
Unverified assumptions remaining: Live Support runtime, graph, capture, deployment, and save integration remain future steps and are not claimed.
Legacy authority still reachable: YES, unchanged and intentionally still live.
Second-authority risk: Controlled; authored metadata is the topology source, runtime region mapping remains ephemeral, and GateConnectivity is untouched.
Save/restore risk: No live state or new snapshot integration.
Cross-system regression evidence: Focused metadata and existing map-definition runners; no complete suite claimed.
Manual evidence required before GO: NO; no visual or live gameplay behavior changed.
```

## Gate result

Decision: **GO**

Only allowed next step: **P0-02A1 Contributor DTO**. This batch stops before P0-02.
