# Cardfront Strategic Map Design / 策略地图设计

Last updated: 2026-07-27

## 1. Current Verdict / 当前判断

The three registered maps are not identical, but their live strategic identity is still weak.

Current differences:

- `default_duel` uses five separated strongholds.
- `cross_resource` uses an overlapping central cross of Energy, Factory, and Laboratory regions.
- `central_lab` uses one large central Laboratory with smaller side Energy and Factory regions.
- The fast balance simulator also gives the three maps different chamber-hit, travel, defense-contact, territory-pressure, and stronghold-tempo proxy values.

Current shared structure:

- Every live map uses the same center river.
- Every live map uses two bridges.
- Bridge centers are globally fixed at horizontal ratios `0.265` and `0.735`.
- Bridge width and gate-control-zone size are global constants.
- Gate thresholds and off-bridge reflection are identical.
- Map definitions do not currently own route geometry.

Therefore the player mainly experiences one battlefield with different stronghold painting. The map registry contains strategic data, but the route geometry does not yet communicate a clear map-specific decision.

## 2. External Design Lessons / 外部参考结论

Mechanism references:

- `Peglin`: special orbs and relics change how the physics resolution works, so board geometry and build effects interact instead of merely increasing damage.
- `Ballionaire`: highly varied boards require fresh theorycrafting; a Pyramid, wheel, and pinball table do not ask the same placement and trajectory questions.
- `Minion Masters`: holding bridges is an explicit spatial objective that powers progression, making lane control understandable at a glance.
- `Mindustry`: map and terrain data are treated as authored content rather than one globally hard-coded arena.
- `Visual Pinball`: table geometry and table rules are editable data, supporting many strategic layouts on one physics engine.
- `statico/godot-roguelike-example`: map generation has a dedicated preview tool, which is a useful model for validating layout parameters before they enter normal gameplay.

Reference pages:

- https://store.steampowered.com/app/1296610/Peglin/
- https://store.steampowered.com/app/2667120/Ballionaire/
- https://store.steampowered.com/app/489520/Minion_Masters/
- https://github.com/Anuken/Mindustry
- https://github.com/vpinball/vpinball
- https://github.com/statico/godot-roguelike-example

## 3. Map Identity Model / 地图身份模型

A Cardfront map is complete only when it defines all four layers:

1. **Route geometry**: river position, bridge count, bridge centers, lane width, and control-zone size.
2. **Objective relation**: which strongholds sit on a route, between routes, or away from routes.
3. **Physics question**: whether the map rewards concentrated fire, split fire, long flanks, central ricochets, or repeated gate pressure.
4. **Player explanation**: one short identity sentence and one actionable opening hint.

Map identity must not rely mainly on hidden simulation-profile multipliers. Proxy values may remain temporarily for regression, but live geometry must become the source of the difference.

## 4. First Three Strategic Maps / 首批三张策略地图

### 4.1 Five Strongholds / 双桥均衡战线

Role: baseline and beginner map.

Route layout:

- Two medium-width bridges.
- Lane centers: `[0.265, 0.735]`.
- Lane half-width: `0.085`.
- Gate-control half-width: `0.10`.
- Gate-control half-height: `0.10`.
- Five separated strongholds: two Energy, two Factory, one central Laboratory.

Strategic question:

> Do I split the volley to contest both bridges, or concentrate on one bridge and accept losing the opposite flank?

Opening hint:

> 两条路线价值接近。集中齐射更容易封锁一桥，分散齐射更容易保住地图控制。

Why it exists:

- Teaches the complete rules without a special exception.
- Provides the reference point for balance comparisons.
- Keeps both heroes and all core cards broadly viable.

### 4.2 Cross Strongholds / 中央交叉火线

Role: high-conflict, fast-tempo map.

Route layout:

- Two bridges moved inward toward the central cross.
- Lane centers: `[0.38, 0.62]`.
- Lane half-width: `0.095`.
- Gate-control half-width: `0.13`.
- Gate-control half-height: `0.11`.
- Energy and Factory regions form a cross around the central Laboratory.

Strategic question:

> Can I win the central collision zone strongly enough to pressure both bridges, or should I avoid the center and attack one edge angle?

Opening hint:

> 两座桥距离很近，中央占领会同时影响两条路线，但双方弹丸也更容易在中心反复碰撞。

Expected character:

- Faster first meaningful conflict.
- More value from armor piercing and capture-continuation effects.
- Split-lane fire is easier to use, but concentrated center defense can resist both routes.
- Highest snowball risk, so gate and stronghold metrics must be watched carefully.

### 4.3 Central Lab / 中央实验室·外翼绕行

Role: route-versus-objective tradeoff map.

Route layout:

- Two narrow bridges moved toward the outside edges.
- Lane centers: `[0.17, 0.83]`.
- Lane half-width: `0.065`.
- Gate-control half-width: `0.075`.
- Gate-control half-height: `0.09`.
- A large central Laboratory is separated from the two bridge approaches.
- Energy and Factory strongholds sit between the Laboratory and the outer routes.

Strategic question:

> Do I fight for the central four-choice draft, or spend trajectory and territory pressure securing an outer route to the enemy chamber?

Opening hint:

> 中央实验室不直接控制桥梁。争夺实验室能改善构筑，争夺外翼才能稳定穿越河道。

Expected character:

- Longest average route.
- Higher value from defense, repair, and gate-breach effects.
- A player can lead in drafting power while still losing route access.
- Creates the clearest distinction between build advantage and battlefield advantage.

## 5. Data Schema / 数据结构

Each map definition should add:

```gdscript
"route_layout": {
    "river_y_ratio": 0.5,
    "lane_center_ratios": [0.265, 0.735],
    "lane_half_width_ratio": 0.085,
    "control_zone_half_width_ratio": 0.10,
    "control_zone_half_height_ratio": 0.10,
    "lane_names": ["left_bridge", "right_bridge"],
},
"strategy_profile": {
    "identity": "balanced_split_or_commit",
    "summary": "Two equal bridges and five separated strongholds.",
    "opening_hint": "Concentrate to close one route or split to preserve map control.",
    "tags": ["baseline", "two_lane", "balanced"],
},
```

Validation requirements:

- Exactly two lane centers during the first implementation stage.
- Lane centers are sorted and remain inside `0.10..0.90`.
- Bridge ranges do not overlap.
- Control zones remain inside the battlefield.
- Route layout is rotationally symmetric for the first three competitive maps.
- Strategy summary and opening hint are non-empty.

## 6. Shared Authority / 共享权威

The same `route_layout` must drive:

- `CardfrontGateConnectivitySystem` crossing checks.
- Gate control-zone sampling.
- Orthographic bridge and gate presentation.
- Pre-match map cards and route preview.
- Fast balance simulation.
- Map tests and screenshot/debug previews.

Global gate constants remain only as fallback defaults for missing or invalid configuration. They must not remain the normal source of live map geometry.

## 7. Implementation Order / 实施顺序

### M0 — Schema and Preview

- Add `route_layout` and `strategy_profile` to all three definitions.
- Extend map validation.
- Add a debug route-layout snapshot and tests.
- No gameplay behavior changes yet.

### M1 — Live Gate Geometry

- Configure `CardfrontGateConnectivitySystem` from the selected map.
- Use per-map lane centers, widths, and control zones.
- Preserve current thresholds during the first comparison.

### M2 — Presentation Parity

- Move 3D bridges, gates, labels, and control overlays from the same route layout.
- Ensure the 2D authority and 3D presentation remain aligned.
- Add desktop and narrow/mobile screenshots or geometry assertions.

### M3 — Simulation Parity

- Add gate passage, reflection, and map route layout to the simulator.
- Actually rerun both side variants instead of flipping one result.
- Replace map-owned hidden proxy differences with geometry-derived values where possible.

### M4 — Product Flow

- Show map route preview before hero selection.
- Display bridge count, lane spacing, stronghold composition, identity, and opening hint.

## 8. Acceptance Metrics / 验收指标

Functional:

- Each map produces visibly different bridge positions in the live arena.
- Projectile crossing and gate control use the selected map definition.
- Presentation and authority agree on lane index for sampled test crossings.
- Invalid route layouts fail content validation.

Strategic:

- Players can describe each map after one match without seeing its name.
- The two bridges do not receive an identical share of traffic on every map.
- Central Lab produces a measurable tradeoff between Laboratory control and gate control.
- Cross Strongholds creates earlier central conflict without pushing timeout below the approved range.
- No map gives one hero an aggregate win rate outside the eventual approved range after full parity simulation.

Readability:

- Map selection explains one decision, not every rule.
- Bridge locations, control zones, and strongholds are readable before the first volley.
- Narrow/mobile layout keeps the route preview above the fold and does not shrink labels below the established UI baseline.

## 9. Deferred Map Features / 暂缓

- Single-bridge maps, because they may create excessive hard-choke snowballing.
- Asymmetric competitive maps, until true side reruns exist.
- Moving bridges during combat.
- Random bridge positions.
- Large obstacle catalogs or pinball-table bumpers before the three route identities are validated.
- Map-exclusive card pools.
