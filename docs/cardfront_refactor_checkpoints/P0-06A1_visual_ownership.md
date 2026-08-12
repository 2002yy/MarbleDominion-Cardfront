# P0-06A1 Visual Ownership Snapshot

Source commit: `91da1badbeeb7bd283fea56eacdc3f2f3699dafe`
Branch: `audit/p0-04e-auto-spawn`
Target step: **P0-06A1 — Visual Ownership Snapshot**
Evidence type: static
Decision: **GO**

## Active battlefield presentation

The active Cardfront battlefield is owned by `CardfrontOrthographicArenaView`, a `CanvasLayer` at layer `4`. `CardfrontArenaBuilder.create_orthographic_view()` creates it and `CardfrontPresentationModeController.activate_orthographic()` hides the legacy 2D battlefield, region, fortify, aim, target-preview, device, and VFX canvas items once the orthographic view is available.

`CardfrontOrthographicArenaView` owns the active `SubViewportContainer -> SubViewport -> ArenaWorld` tree and currently draws:

- terrain, territory boundaries, sparse claim markers, bridges, and region platforms;
- region labels and control rings;
- command chambers, projectiles, entities, HP/status presentation, aim guide, and combat effects;
- bridge gate geometry and gate labels.

This makes the orthographic view the integration owner for future Support battlefield visuals. The legacy Node2D layers are not an alternative Support presentation authority.

## Region hover and information ownership

- `CardfrontRegionInfoPanel` owns region hover information in UI `CanvasLayer.layer = 17`.
- `CardfrontMode.create_region_info_panel()` creates and binds it to `RegionMap`, `Battlefield`, territory defense, and the legacy status-only Stronghold observer.
- It derives territory region information from runtime `region_id`; it must not infer Support identity, Claim, connectivity, capture state, or deployment legality.
- `RegionOverlayLayer` (`z_index = 2`) and `RegionControlBlockLayer` (`z_index = 3`) are legacy 2D region renderers. They are hidden in active orthographic presentation and must not become Support presenters.

## Entity presentation ownership

- Active orthographic entities are owned by `CardfrontOrthographicArenaView`, keyed by stable `entity_id` in `_entity_proxies`, `_entity_sprites`, `_entity_hp_fills`, and `_entity_status_labels`.
- `CardfrontEntityPresentationLayer` is the legacy Node2D entity presenter (`z_index = 22`). Its actor caches are also keyed by `entity_id`, but it is not the active orthographic Support integration point.
- Neither entity presenter grants gameplay collision or movement authority to presentation nodes.

## Gate presentation ownership

- `CardfrontOrthographicArenaView._build_gate_visual()` owns active gate meshes, bars, and labels.
- `CardfrontGateConnectivitySystem` owns the sampled gate gameplay snapshot and pushes presentation-only state through `set_gate_state()` / `set_gate_openness()`.
- Gate presentation is therefore a consumer of gate state, not a Support graph authority.

## Cell-to-world coordinate contract

Two coordinate spaces currently exist:

- legacy 2D: `(Vector2(cell) + Vector2(0.5, 0.5)) * battlefield.cell_size`, with `Battlefield.world_to_cell()` for inverse lookup;
- active orthographic 3D: `CardfrontOrthographicArenaView._cell_to_world(cell, height)`, using `ARENA_X_SCALE` and the grid-dependent `_z_scale`.

The active 3D conversion is private. `simulation_to_world_for_test()` is public only for simulation-position tests and is not the production Support anchor API. P0-06B2 must expose or internally reuse one orthographic conversion seam rather than copy its formula into a Support visual node.

## Current layer map

| Surface | Owner | Layer / z-index | Active orthographic status |
|---|---|---:|---|
| Orthographic battlefield | `CardfrontOrthographicArenaView` | CanvasLayer `4` | active |
| Region info panel | `CardfrontRegionInfoPanel` | CanvasLayer `17` | active UI |
| Legacy region overlay | `RegionOverlayLayer` | z `2` | hidden |
| Legacy region control blocks | `RegionControlBlockLayer` | z `3` | hidden |
| Legacy entity presentation | `CardfrontEntityPresentationLayer` | z `22` | legacy/fallback |
| Target preview | `CardfrontTargetPreviewLayer` | z `5` | hidden by orthographic controller |
| Device overlay | `CardfrontDeviceOverlayLayer` | z `5` | hidden by orthographic controller |
| VFX layer | `CardfrontVfxLayer` | z `6` | hidden by orthographic controller |

Support visuals should be children of the active orthographic `ArenaWorld`, with low-height geometry and no collision nodes. Support status hints that require screen-space UI must remain a separate projection of the same presentation snapshot.

## Findings and constraints for the next steps

1. `runtime region_id` is not a legal Support visual key; one instance must be keyed by authored `support_id`.
2. `CardfrontRegionInfoPanel` remains territory UI and cannot infer Support state from territory control percentage.
3. `CardfrontOrthographicArenaView` already centralizes the active map, gate, and entity visuals; a second Support overlay authority would be drift.
4. The active 3D cell conversion needs a production seam before P0-06B2; formula duplication is forbidden.
5. No visual node may receive mutable Support runtime, graph, capture-controller, or deployment callbacks.

## Mandatory audit fields

```text
Mandatory audit gates touched: P0-06 visual ownership; UI non-authority; stable Support identity
Audit status per gate: PASS
Evidence bound to source commit: YES — 91da1badbeeb7bd283fea56eacdc3f2f3699dafe
Highest-priority evidence used: static
Unverified assumptions remaining: final Support visual occlusion and readability require later screenshot/manual evidence
Legacy authority still reachable: legacy 2D layers exist but are hidden by active orthographic mode
Second-authority risk: identified and constrained; no Support presenter exists yet
Save/restore risk: NOT APPLICABLE
Cross-system regression evidence: NOT APPLICABLE for docs-only ownership audit
Manual evidence required before GO: NO for P0-06A1
Video requested explicitly by product owner: NO
Stable IDs introduced/changed: NO
Runtime numeric IDs used as identity: NO
Territory capture touched: NO
Creature movement legality touched: NO
Deployment four-consumer authority touched: NO
P1/P2 leakage: NONE
```

## Exit

Visual owners, coordinate seams, and layering are identified. P0-06A1 is complete.

The only allowed next step is **P0-06A2 — SupportPresentationSnapshot DTO**.
