# Project Status / 项目状态

Last updated: 2026-08-21

Current `main`: `10ddb48`
Status authority: **this file**

This document contains current truth, the active track, one next gate per
track, locked boundaries, and current content inventory. Long-form completed
slice narratives and old audit reports are historical evidence and live in
`历史_history/PROJECT_STATUS_SNAPSHOT_2026-08-20_PRE_GOVERNANCE.md`.

## 1. Authority And Execution Model / 权威与执行模型

Cardfront keeps two active tracks, but only one track may receive implementation
changes at a time:

1. **Art Production Track / 美术生产轨**
2. **Gameplay Refactor Track / 玩法重构轨**

Authority order:

```text
PROJECT_STATUS.md
  selects the active track and its program-level gate
        ↓
latest valid checkpoint for that track
  may block or select the next step inside that track
        ↓
Grill decision record
  defines goals, rejected alternatives, boundaries, and acceptance
        ↓
ROADMAP.md
  future candidates only; never the current task authority
```

Rules:

- A checkpoint may block its own track, but it cannot switch the active track.
- A track switch requires this file to be updated.
- Current design decisions must have a Markdown authority. DOCX files are
  formatted mirrors and are rebuilt from Markdown when damaged or stale.
- When a missing decision could change gameplay, visual hierarchy,
  interaction, scope, or acceptance, stop implementation and Grill the gap.
- After Grill, update the decision record and this file before resuming code.
- Preserve unrelated dirty work. Commit and push only with explicit authority.

## 2. Current Program Sequence / 当前程序顺序

Locked sequence:

```text
Documentation governance
  → Art Formal Benchmark GO / NO-GO
  → Gameplay P0 current-main drift audit GO / NO-GO
  → choose the next single-track milestone from evidence
```

### Active Track: Art Production

**Current gate:** `P0-FT1 Formal Interceptor Tower Cross-Asset Benchmark`

**Source commit:** `10ddb48`

**Status:** Step 1 validator committed and pushed; Steps 2–8 source, four GLBs,
runtime binding, deterministic captures, save/performance regression, and clean
logs PASS in the current working tree; Step 9 product-owner screenshot decision
is pending, so P0-FT1 remains open

**Checkpoint:**
[`cardfront_refactor_checkpoints/P0-FT1_formal_interceptor_tower_benchmark.md`](cardfront_refactor_checkpoints/P0-FT1_formal_interceptor_tower_benchmark.md)

The first Formal Benchmark is expanded from `default_duel + Balanced HQ +
Castle Theme` to include one complete modular Interceptor Tower vertical slice.
The reusable Formal GLB validator is now executable at
`scripts/cardfront/environment/CardfrontFormalAssetValidator.gd`. It rejects
instead of healing invalid transforms, semantic nodes, material roles,
forbidden authority nodes, and missing required sockets. The currently imported
HQ remains usable as presentation evidence but is not yet D22-admitted because
its legacy root/node/material names fail the frozen contract.

The deterministic Tower source recipe builds a 2.0 m footprint, 2.7553 m high
Formal Interceptor from separate Common, Interceptor, Castle, and mutually
exclusive Damage collections. The four normalized production GLBs now pass
the executable D21/D22 import gate, are registered, and assemble into isolated
player/AI presentation instances. L1–L3, HP4–HP0, power, suppression, quota,
intercept, counter, upgrade, build, and death presentation are bound without
changing gameplay authority.

The deterministic 12-card state board and desktop/narrow live capture matrix
are under `artifacts/formal-tower-state-board/` and
`artifacts/formal-tower-live/`. The state board is the close visual authority;
the 40×50 live images verify battle hierarchy and coexistence with both HQs,
bridges, and both factions' three projectile types. Product-owner screenshot
GO / NO-GO is the only allowed next decision.

The first screenshot review returned NO-GO for an undersized HP0 snapshot and
weak L3 Counter focus. Revision 1 now uses five grounded rubble pieces and a
0.24 m Snap-Recoil with one bounded emissive muzzle flash. Automated and visual
evidence has been refreshed; the revised screenshot decision remains pending.

The art track may not expand to Fire-Control Beacon, Gate, Stronghold, Rapid,
Engineer, Industrial, Lab, formal audio, or D26 until P0-FT1 records GO.

### Queued Track: Gameplay Refactor

**Next gate after P0-FT1:** current-`main` directed P0 drift audit

**Status:** queued; implementation blocked while Art Production is active

The old P0 seal and its `NO-GO / P1 locked` result remain historical evidence.
The next gameplay action is not a blind restart at an old micro-step and not an
automatic waiver. Audit current `main` against the old blockers, gameplay
authority, save/restore, AI information boundaries, and current test authority.

- If the old independent-playtest target still applies, retain the human gate.
- If later code invalidated the old target, update the acceptance protocol
  before judging it; do not silently mark it PASS.
- Expand to a full P0 rerun only when the directed audit finds material drift.
- P1 remains locked until the resulting gameplay checkpoint explicitly allows it.

## 3. Current Product Direction / 当前产品方向

Approved match flow:

> 地图选择 → 玩家选择英雄 → AI 英雄展示与双方基础属性 → 开始对局 →
> 调整炮口方向 → 倒计时结束 → 全场暂停 → 三选一强化 → 超时随机 →
> 双方结算 → 自动齐射 → 争夺路线并摧毁敌方控制舱

Core boundaries:

- First mode is player versus AI with two factions.
- The player controls firing direction; projectiles and battlefield resolution
  remain authoritative 2D simulation.
- The orthographic 3D arena is presentation-only.
- Draft pauses the world while its real-time timeout continues.
- Command-chamber destruction is the primary win condition.
- Territory controls routes, defense, gates, Supports, and deployment; territory
  percentage is not the primary win condition.
- Upgrades should favor routing, capture, volley composition, entities, and
  fortification over unrestricted flat-number escalation.

Approved art direction:

> **明亮玩具沙盘 + 清晰竞技路线 + 粗轮廓占领块**

Visual priority:

```text
HQ → active combat → towers → Supports → bridges → environment dressing
```

## 4. Current Player-Facing Reality / 当前玩家可见状态

- Normal menu entry runs map selection, hero selection, AI reveal, matchup
  confirmation, battle, paused Draft, and automatic volley resolution.
- Three registered maps drive the live `RegionMap` and gate geometry.
- The supported runtime extent matrix includes `40x40`, `50x50`, `40x50`, and
  `40x60`; `40x50` is the formal non-square visual benchmark.
- The default battle presentation scale is `112%`; desktop `1120x720` and
  landscape-narrow `760x540` are required visual evidence surfaces.
- The arena has modular formal HQ assets, D21 semantic material channels, D13
  HQ damage states, typed projectile silhouettes, faction rims/trails, compact
  HUD, contextual aim controls, and map-edge environment dressing.
- Strategic Supports remain low-profile weak physical landmarks. Combat shows
  compact `能/工/研 + 百分比`; hover/click/touch exposes the full screen-space
  detail card; Draft battlefield review expands full names.
- Projectile grammar uses body silhouette for type and faction rim/trail for
  ownership. Standard, Siege, and Suppression remain presentation variants of
  the existing authoritative projectile types.
- The first formal creatures and defense towers are active three-choice content.
- Legacy targeted-card UI and legacy economy surfaces are compatibility content,
  not part of the normal three-choice match loop.

## 5. Active Hero Baseline / 正式英雄基线

| Hero | Base projectile group | Chamber HP | Start defense | Contact front | First neutral frontline capture | Repair bonus | Defense cap |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Balanced Commander / 均衡指挥官 | 6 standard | 40 | 1 | 1 | 0 | 0 | 1 |
| Rapid Gunner / 连射炮手 | 6 standard + 1 suppression | 36 | 1 | 1 | 0 | 0 | 1 |
| Fortification Engineer / 筑垒工程师 | 4 standard + 1 siege | 42 | 1 | 2 | 1 once per neutral cell | +2 Frontline Repair | 2 |

Projectile truth:

- Standard: 1 chamber-damage unit; 1 entity damage; normally bounces.
- Siege: 2 chamber-damage units; pierces 1 territory-defense layer; deals 3
  tower damage and is consumed on entity contact.
- Suppression: no chamber or creature damage; stronger route pressure; disables
  towers and stuns/pushes creatures for one round.
- Double Volley copies the typed hero base group.

## 6. Active Formal Upgrade Pool / 正式强化池

The normal run uses `core_tactics`, exactly eighteen upgrades:

| Upgrade | Rarity | Current behavior |
| --- | --- | --- |
| Reinforced Volley / 增援齐射 | Common | Next volley adds 5 standard shots; not copied by Double Volley. |
| Double Volley / 双倍齐射 | Uncommon | Copies the complete typed hero base group once; no stacking above `x2`. |
| Attack Training / 攻击训练 | Uncommon | Permanent attack level +1, capped at 3. |
| Thicken Position / 加厚阵地 | Common | Defense cap +1, hard-capped at 4; no refill. |
| Frontline Repair / 前线修复 | Common | Repairs up to 6 frontline cells; Engineer budget is 8. |
| Armor-Piercing Trajectory / 穿甲轨迹 | Uncommon | First 6 defended contacts next volley ignore one layer. |
| Rarity Premonition / 稀有预感 | Uncommon | Rarity level +1, capped at 3. |
| Delayed Echo / 延迟回响 | Rare | Replays the next selected upgrade once in the following round. |
| Siege Formation / 攻城编组 | Uncommon | Converts up to 2 next-volley standards into siege shots. |
| Suppression Formation / 压制编队 | Uncommon | Converts up to 2 next-volley standards into suppression shots. |
| Repair Units / 维修单位 | Common | Summons two 1-HP, movement-1, three-round repair units. |
| Fire-Control Beacon / 火控信标 | Uncommon | Fixed-slot 5-HP L1–L3 tower; guides 6/8/10 shots and later maintains a scout. |
| Interceptor Tower / 拦截塔 | Uncommon | Fixed-slot 4-HP L1–L3 tower; intercepts 2/3/3 standards; L3 counterfires. |
| Building Volley / 建筑齐射 | Rare | Powered towers fire 2/3/4 standards; combined shot cap 32. |
| Heavy Charge / 重型装药 | Rare | First qualifying tower contact adds structure/area pressure; no direct chamber damage. |
| Armored Guard / 装甲护卫 | Uncommon | Summons one permanent 4-HP armored projectile blocker. |
| Sapper Unit / 掘城单位 | Uncommon | Summons one permanent 3-HP armored demolition unit; self-destructs on attack. |
| Awaken Gate Colossus / 唤醒闸门巨像 | Rare | Once per side, summons a neutral 6-HP size-2 leader-targeting creature. |

Limits:

- Normal volleys cap at 24; explicit exceptional paths may cap at 32.
- Same-round multiplier stacking is prohibited.
- Candidate deck definitions are not player-selectable formal content.

## 7. Active Battlefield Entities / 正式战场实体

Foundation:

- Maximum 3 creatures and 2 defense towers per faction.
- Maximum 2 creature slots per cell.
- Towers occupy fixed map slots and receive power from tile ownership.
- Towers support HP, L1–L3, power loss, temporary disable, interception,
  guidance/summoning, counterfire, and presentation feedback.

| Entity | Current authority |
| --- | --- |
| Repair Unit | 1 HP, normal armor, movement 1, lasts 3 rounds, repairs one eligible layer per action. |
| Armored Guard | 4 HP, armored, movement 1, permanent, blocks hostile projectiles. |
| Sapper Unit | 3 HP, armored, movement 1, respects gates, attacks then self-destructs. |
| Gate Colossus | Neutral, 6 HP, armored, movement 1, size 2, attacks the current leader. |
| Scout | 1 HP helper maintained by L2/L3 Fire-Control Beacon. |
| Fire-Control Beacon | 5 HP; L1–L3 guidance 6/8/10; L2/L3 scout maintenance. |
| Interceptor Tower | 4 HP; L1–L3 capacity 2/3/3; L3 counterfire after quota exhaustion. |

## 8. Locked Visual And Production Contracts / 冻结视觉生产合同

- D18: layered perceived footprint, G0 authority through G3 ephemeral effects.
- D19: tactical occlusion priority; critical truth and dynamics outrank dressing.
- D20: Ground/Object/Target/Trajectory/Area layered interaction grammar.
- D21: semantic material roles use `CF_<SURFACE>__<CHANNEL>`; no whole-model
  faction tint for Formal assets.
- D22: normalized export, semantic nodes/sockets, presentation-only GLB,
  `Validate, Don't Heal`, and machine-verifiable admission.
- `Asset Done = Contract PASS + Fixed-Camera Benchmark PASS`.
- Screen-space labels follow contextual hybrid information layering: world
  identifies state and change; contextual HUD carries exact values and history.

Formal production authority:

- [`art/README.md`](art/README.md)
- [`art/CARDFRONT_P0_PRODUCTION_CONTRACT_V0.4_2026-08-18.md`](art/CARDFRONT_P0_PRODUCTION_CONTRACT_V0.4_2026-08-18.md)
- [`设计_design/CARDFRONT_DUAL_TRACK_AND_FORMAL_TOWER_GRILL_DECISIONS_2026-08-20.md`](设计_design/CARDFRONT_DUAL_TRACK_AND_FORMAL_TOWER_GRILL_DECISIONS_2026-08-20.md)

## 9. Recent Evidence And Decisions / 近期证据

| Date | Result | Evidence |
| --- | --- | --- |
| 2026-08-18 | Formal modular HQ imported; Formal Benchmark still open | `320de9e` through `e6954de` |
| 2026-08-20 | Projectile PG1 implementation/evidence formalized | `dc46d35`, `cdd128b`, `faa152d` |
| 2026-08-20 | Layered strategic-region information accepted and pushed | `3f3c8a6`; 339 focused checks; desktop/narrow captures |
| 2026-08-20 | Dual-track governance and Formal Interceptor Tower scope locked | current Grill decision record; implementation pending |
| 2026-08-20 | P0-FT1 Step 1 validator committed; Step 2 Tower reference layout passes local admission | `10ddb48`; `artifacts/formal-tower-reference/validation.json`; P0-FT1 remains open |
| 2026-08-21 | P0-FT1 Steps 3–8 production modules, runtime state binding, capture matrix, and regression PASS locally | source still `10ddb48`; evidence is dirty-working-tree and awaits product-owner screenshot decision |

Generated captures under `artifacts/` are local review evidence unless a
checkpoint explicitly admits them. They are not automatically release assets.

## 10. Explicitly Deferred / 明确暂缓

- Fire-Control Beacon formal asset and the rest of the Tower family.
- Formal Gate/Bridge, Stronghold, Rapid, Engineer, Industrial, and Lab modules.
- D23 screen-space budget, D24 quality-tier contract, D25 Draft/card visual
  language, and D26 formal damage/VFX/audio timing hooks beyond the bounded
  Tower benchmark needs.
- P1 route/deep-commit/reroll/upgrade-track implementation before a valid P0
  gameplay gate allows it.
- True 3D authoritative projectile physics.
- GraphRAG-like broad design expansion, new game modes, network scope, and
  unrelated map expansion.

## 11. Acceptance And Reporting / 验收与报告

Every milestone reports:

- source commit and changed files;
- focused automated evidence and any missing manual/runtime evidence;
- screenshot matrix when the change is visual;
- audit problems and remaining assumptions;
- GO / NO-GO;
- the only allowed next step for that track.

Unavailable manual evidence is not PASS. A visual implementation may be
automated PASS while the checkpoint remains product-owner GO pending.
