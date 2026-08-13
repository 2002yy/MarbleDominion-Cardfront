# V-01 Arena Visual Hierarchy Acceptance

Source commit: `dabb076e63efbf9ef5714a3a35a605fd23146e90`

Decision: **GO**

Formal P0 authority changed: **NO**

Only allowed next formal P0 step: **P0-09B3 - Offer / View Data Level Projection**.

## Approved scope delivered

- cleared the imported interceptor `IntTip_*` owner inconsistency before runtime regrouping;
- reduced stronghold platform footprint, height, and ring dominance without changing region cells;
- added raised presentation edges to both existing bridges without changing routes, gates, or collisions;
- strengthened GLB value/faction treatment and command-chamber/tower silhouettes;
- added faction-readable command-chamber footprints;
- added quiet map-themed skyline/flank silhouettes outside the playable core;
- reduced the narrow-view bottom margin and retained a readable minimum top-HUD width;
- extended the deterministic capture helper with `CARDFRONT_CAPTURE_MAP_ID` for all registered maps.

Draft geometry, map definitions, route data, collision, projectile simulation, Support authority, and gameplay rules were not changed.

## Real-render acceptance

Godot `4.7.1-stable.official.a13da4feb`, OpenGL Compatibility renderer, NVIDIA RTX 5060 Laptop GPU.

Final captures were produced for all six combinations:

- `default_duel`, `cross_resource`, `central_lab`;
- `1120x720` and `760x540`;
- logical extent `40x50`.

The final six capture runs reported **0 errors and 0 warnings**. Visual inspection confirmed:

- both routes and bridge crossings remain readable;
- strongholds no longer overpower towers, chambers, and active entities;
- map palette/landmark identity remains distinct;
- chamber allegiance remains visible at desktop and narrow widths;
- narrow composition uses the lower screen more effectively;
- peripheral skyline/flank silhouettes remain outside the playable core.

Default-map Draft was separately inspected at both viewports. Three choices, timer, battlefield-review button, status copy, and card text remain readable; Draft geometry was not modified.

Capture artifacts remain local and are intentionally not committed:

```text
D:\CodexTemp\cardfront-v01-acceptance-20260813\artifacts\
```

## Automated evidence

- `CardfrontOrthographicArenaTestRunner` - **PASS (66 checks)**;
- `CardfrontBattlefieldScaleTestRunner` - **PASS (57 checks)**;
- `CardfrontArenaLayoutTestRunner` - **PASS (45 checks)**.

Focused V-01 total: **168 assertions passed**.

## Audit fields

```text
Mandatory audit gates touched: presentation-only visual authority; live error/warning capture
Audit status per gate: PASS
Evidence bound to source commit: YES - dabb076e63efbf9ef5714a3a35a605fd23146e90
Unverified assumptions remaining: human taste remains iterative, but no acceptance blocker is hidden
Legacy authority still reachable: unchanged by V-01
Second-authority risk: NO - added nodes are presentation-only and carry no collision/gameplay state
Save/restore risk: NONE
Cross-system regression evidence: arena, narrow layout, HUD, Draft capture, three-map real render
Manual evidence required before GO: completed by screenshot inspection
Map/gameplay mutation: NO
Draft mutation: NO
```
