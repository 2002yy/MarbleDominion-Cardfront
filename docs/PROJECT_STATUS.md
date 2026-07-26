# Project Status / 项目状态

Last updated: 2026-07-27

This is the only document that tracks the current version, completed work, active implementation slice, next step, and deferred scope.
本文件是项目当前版本、已完成内容、正在实施内容、下一步和暂缓范围的唯一状态入口。

## 1. Current Direction / 当前方向

Cardfront is being rebuilt as a single-match 1v1 physics strategy roguelite:

> 地图选择 -> 玩家选择英雄 -> 展示 AI 英雄 -> 展示双方基础属性 -> 开始对局 -> 调整炮口方向 -> 倒计时结束 -> 全场暂停 -> 三选一强化 -> 超时随机 -> 双方结算 -> 自动齐射 -> 争夺路线并摧毁敌方控制舱

Confirmed product decisions:

- First mode is player versus AI, with two factions only.
- During the first implementation stage, the player controls firing direction only.
- The world fully pauses during the three-choice draft; draft timeout continues in real time.
- Timeout chooses one of the offered upgrades at random.
- `+5` and `x2` affect the next volley only.
- Attack level, territory-defense cap, and rarity upgrades persist for the current match; base volley does not grow permanently.
- Echo repeats the next selected upgrade once in the following round instead of duplicating it in the same round.
- The primary win condition is destroying the enemy command chamber.
- Territory supplies routes, defense, gate control, stronghold control, and firing advantages; territory percentage is not the primary victory condition.
- The authoritative game state and projectile simulation remain 2D; the orthographic 3D layer is presentation-only.
- New upgrades should primarily change projectile routing, capture behavior, volley distribution, and post-capture fortification instead of adding larger flat numbers.

## 2. Hero Numeric Baseline / 三英雄数值基线

The current public baseline is:

| Hero | Base volley | Chamber health | Ordinary starting defense | Contact-front starting defense | Defense cap | Strategic identity |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Balanced Commander / 均衡指挥官 | 6 | 40 | 1 | 1 | 1 | Broad card compatibility |
| Rapid Gunner / 连射炮手 | 7 | 36 | 1 | 1 | 1 | Multiplier and burst value |
| Fortification Engineer / 筑垒工程师 | 5 | 42 | 1 | 2 | 2 | Pre-built contact front and position management |

Locked Engineer opening rule:

- The contact front means initially owned cells orthogonally adjacent to neutral or enemy territory.
- On the current horizontal spawn layout, this is the full row facing the neutral center.
- Engineer contact-front cells begin at `2/2`.
- Other Engineer starting territory begins at `1/2`.
- Newly captured and recaptured territory begins at `0/2`.
- Raising the cap does not refill current defense.
- The opening contact front is detected and applied once during match initialization.
- Later frontline movement never creates a new free two-layer line.

Hero state layers:

- Identity: hero ID/name, base volley, chamber maximum health, ordinary starting defense, contact-front starting defense, and initial defense cap.
- Persistent run growth: permanent attack level `0..3`, defense cap up to 4, and rarity level `0..3`.
- Next-volley state: additive shot bonus, multiplier capped at `x2`, armor-piercing contacts, and future route/projectile modifiers.
- Delayed state: armed Echo and queued replay upgrade.
- World-authoritative state: chamber current health, per-cell defense, territory ownership, stronghold snapshot, gate snapshot, and aim direction.
- Planned read model: a read-only `CardfrontFactionCombatSnapshot` for UI, AI, and simulation without becoming a second authority.

Completed migration:

- Base volley comes from the selected hero at 5, 6, or 7 shots.
- Chamber health comes from the selected hero at 42, 40, or 36.
- Starting territory defense is seeded once and no longer refills automatically before every volley.
- Territory-defense hard cap is 4; Engineer starts with capacity 2.
- Engineer starts with a visible one-time `2/2` contact front while its interior remains `1/2`.
- Newly captured and recaptured territory begins at zero current defense.
- Permanent attack growth uses levels `0..3`.
- Temporary effects may raise the resolved attack level to 4 for one volley.
- Echo queues and replays the next selected upgrade during the following round.
- Player and AI hero IDs can already be injected through runtime configuration.

Remaining hero work:

- Replace fixed upgrade scores with a shared marginal-value AI policy.
- Formal player hero selection and AI hero reveal UI.
- AI repair, armor-piercing, and route-card valuation based on live route pressure.
- Read-only combat snapshot shared by UI, AI, and simulation.

## 3. Attack And Defense Semantics / 攻防语义

### Attack

- Permanent attack level: `0..3`.
- Each level adds 25% chamber damage.
- Temporary attack effects may raise the resolved volley level to 4.
- Resolved damage sequence: `100% / 125% / 150% / 175% / 200%`.
- Level 4 is temporary only and is never written back into permanent run state.
- Live runtime and parity simulation use the level-4 temporary ceiling.

### Defense

- Global territory-defense cap belongs to hero identity and run growth.
- Hard cap is 4.
- Ordinary starting owned cells begin at `1 / hero cap`.
- Engineer contact-front cells are the only opening exception and begin at `2/2`.
- Newly captured or recaptured cells begin at `0 / current cap`.
- Increasing the cap does not refill current defense.
- An effective hostile hit removes one current-defense point; a later hit captures after defense reaches zero.
- Automatic full-map refill is removed.
- Frontline Repair restores at most 6 different owned frontline cells and adds exactly 1 defense point to each.
- One repair card never visits the same cell twice, even when fewer than 6 eligible cells exist.
- Repairing an exhausted former opening-front cell restores one layer; it does not recreate the free `2/2` opening bonus.

## 4. Current Upgrade Catalog / 当前强化池

| Upgrade | Rarity | Function |
| --- | --- | --- |
| Reinforced Volley / 增援齐射 | Common | Next volley `+5` |
| Double Volley / 双倍齐射 | Uncommon | Next volley `x2` |
| Attack Training / 攻击训练 | Uncommon | Permanent attack level `+1`, cap 3 |
| Thicken Position / 加厚阵地 | Common | Permanent defense cap `+1`, cap 4 |
| Frontline Repair / 前线修复 | Common | Repair up to 6 different frontline cells |
| Armor-Piercing Trajectory / 穿甲轨迹 | Uncommon | Ignore the first 6 defended contacts next volley |
| Rarity Premonition / 稀有预感 | Uncommon | Raise future high-rarity probability |
| Delayed Echo / 延迟回响 | Rare | Replay the next selected upgrade once next round |

Catalog limits:

- Normal volleys remain at or below 24 shots.
- Explicit exceptional bonuses may reach 32 shots.
- Same-round multiplier stacking is disallowed.
- Do not prioritize flat additions such as `+8`, `x3`, or permanent `+50%` damage.

Approved future route module:

| Upgrade | Rarity | Approved behavior |
| --- | --- | --- |
| Vanguard Warhead / 先锋弹头 | Common | First 4 projectiles continue after their first capture and may capture one additional cell |
| Gate Breach Round / 破门弹 | Uncommon | First 4 rejected gate crossings become valid bridge passages; off-bridge river crossing remains blocked |
| Bridgehead Fortification / 桥头筑垒 | Uncommon | First 6 newly captured cells inside gate-control zones gain 1 current defense |
| Split-Lane Volley / 双路齐射 | Rare | Total shots unchanged; divide the volley between selected and horizontally mirrored directions |

## 5. Strongholds And Timeout / 据点与超时

- Factory: next volley `+3` shots.
- Energy: next volley gains one temporary attack level and may raise permanent level 3 to resolved level 4.
- Laboratory: draft four upgrades and choose one.
- Destroying the enemy chamber is an immediate win.
- Timeout score: `50% normalized chamber health + 35% territory + 15% strongholds`.

## 6. Completed Slices / 已完成阶段

### v0.3.3a — Authoritative Gate Connectivity

- Two bridge gates are authoritative projectile routes.
- Below 55% control: open to both factions.
- At 55%–79%: owner passes all shots; enemy shots alternate between passage and reflection.
- At 80% or more: owner passes all shots; enemy shots reflect.
- Off-bridge river crossings reflect from the river bank.
- Gate state is sampled and locked at round boundaries.
- 3D gate presentation mirrors the locked 2D authority.

### v0.3.3a1 — Temporary Attack And Strict Repair

Status: completed and merged to `main` at commit `748b826`.

- Added a shared resolved attack ceiling of level 4 while preserving permanent cap 3.
- Energy can produce 200% chamber damage for one volley at permanent level 3.
- Frontline Repair now makes one pass over candidates.
- A six-point repair restores fewer than six points when fewer than six different eligible cells exist.

### v0.3.3a2 — Explicit Historical And Parity Simulation Modes

Status: completed and merged to `main` at commit `a2d004c`.

- `historical_compensated`: preserves hidden hero hit-rate compensation and resolved attack cap 3 so the original audit remains reproducible.
- `parity_uncompensated`: disables hidden hero accuracy and uses temporary resolved attack cap 4.
- Match and report output identifies simulation mode, compensation state, and attack ceiling.
- Historical 54,000-match gate remains merge-blocking.

### v0.3.3a3 — Full B0 Cloud Audit And Map Strategy Specification

Status: completed and merged to `main` at commit `a8b41c4`.

- Added a dedicated full 54,000-match B0 cloud runner and downloadable artifact.
- Recorded exact B0 evidence.
- Defined the first three strategic map identities.
- Split unstable sequential vertical-slice tests into independent CI jobs.

### v0.3.3a4 — Engineer Opening Contact-Front Fortification

Status: completed in PR #6; full repository CI passed before merge.

- Added data-driven `starting_contact_front_defense` to hero definitions and run state.
- Locked Engineer values at 5 volley, 42 health, ordinary defense 1, contact-front defense 2, and cap 2.
- Detects initially owned cells orthogonally adjacent to neutral or enemy territory.
- Applies the opening bonus once and stores the initial-front snapshot.
- Does not dynamically fortify newly exposed inner rows.
- Preserves capture and recapture at zero defense.
- Preserves one-point repair behavior.
- Added initialization, consumption, capture, recapture, repair, no-refill, and overlay-visual tests.
- Historical A and provisional B0 audits remain unchanged because this live per-cell rule is intentionally deferred from the proxy simulator until B1.

## 7. Balance Audit Status / 平衡模拟状态

### Historical A Baseline

Matrix: `3 heroes x 3 enemy heroes x 3 maps x 2 reported sides x 1000 seeds = 54,000`.

- Balanced Commander: `51.46%`.
- Fortification Engineer: `49.09%`.
- Rapid Gunner: `49.45%`.
- Ordered matchup range: `47.62%..53.70%`.
- Mirror position rates: `49%..51%`.
- Median: 22 rounds.
- P90: 34 rounds.
- Timeout: `12.25%`.
- First stronghold: round `6.03`.
- Cells crossed per marble: `19.25`.
- Chamber hits per volley: `1.231`.
- Defense absorbed per volley: `2.271`.
- Invalid offers: zero.

Boundary: this baseline includes hidden Engineer/Gunner hit-rate compensation, does not model authoritative gates, does not model Engineer contact-front fortification, and reports a synthetic second side by flipping the first result instead of rerunning geometry.

### Provisional B0 Cloud Audit

Status: completed in GitHub Actions on 2026-07-27. The audit artifact records all 54,000 matches.

Rules:

- Simulation mode: `parity_uncompensated`.
- Hidden hit compensation: disabled.
- Temporary resolved attack cap: 4.
- Current eight-card catalog.
- Current proxy map profiles.
- No authoritative gate simulation yet.
- No true second-side geometry rerun yet.
- No Engineer opening contact-front fortification yet.

Results:

- Balanced Commander: `56.95%`.
- Fortification Engineer: `29.64%`.
- Rapid Gunner: `63.41%`.
- Balanced vs Engineer: `78.22%`.
- Balanced vs Gunner: `42.70%`.
- Engineer vs Balanced: `22.05%`.
- Engineer vs Gunner: `17.63%`.
- Gunner vs Balanced: `57.17%`.
- Gunner vs Engineer: `83.65%`.
- Mirrors remain approximately 50% because the current audit still flips the same result for the second reported side.
- Median: 22 rounds.
- P90: 34 rounds.
- Timeout: `13.53%`.
- First stronghold: round `6.03`.
- Cells crossed per marble: `19.25`.
- Chamber hits per volley: `1.189`.
- Defense absorbed per volley: `2.270`.
- Invalid offers: zero.

Interpretation:

- The hidden compensation materially carried the previous hero balance; it was not a harmless fine adjustment.
- Removing it exposed the Engineer as dramatically weak in the old proxy model and the Gunner as dramatically strong.
- B0 is not the result of the newly fortified Engineer because the proxy simulator does not yet represent per-cell opening defense.
- Do not change Engineer volley count or Gunner values from B0 alone.
- The next valid hero decision point is B1 after the new AI policy, real gates, real route geometry, true side reruns, and per-cell defense are represented.
- If the Engineer remains below 47% in valid B1 evidence, the next candidate is chamber health `42 -> 44`.

B1 risk monitoring for the full Engineer contact line:

- Timeout should remain within `10%..25%`.
- Median should not materially exceed 22 rounds.
- P90 should not exceed 34 rounds without a documented reason.
- First-stronghold timing and Engineer mirror stagnation must be reported.
- If the full line creates excessive delay, narrow the free `2/2` bonus to cells near the two bridge/control zones instead of removing the visible mechanic.

## 8. Current Map Strategy Verdict / 当前地图策略判断

Blunt verdict:

> 当前有“通用双桥闸门策略”和“默认五据点策略”，但几乎没有玩家可直观感受到的地图之间策略差异。

Why:

- Three map definitions exist in the registry: Five Strongholds, Cross Strongholds, and Central Lab.
- Their stronghold shapes and fast-simulation proxy values differ.
- Live runtime currently calls `generate_default_layout()` and therefore always builds the default stronghold layout.
- Cross Strongholds and Central Lab are currently registry/simulation definitions, not fully selectable live battlefields.
- All live gate geometry uses globally fixed two-lane positions, widths, and control-zone sizes.
- The map schema does not yet own river/bridge/gate geometry or a player-facing strategic identity.

Approved strategic map specification:

- `docs/CARDFRONT_STRATEGIC_MAP_DESIGN.md`

First three identities:

1. **Five Strongholds / 双桥均衡战线** — two equal routes; decide whether to split the volley or commit to one bridge.
2. **Cross Strongholds / 中央交叉火线** — bridges move inward; central occupation affects both routes and creates early collision pressure.
3. **Central Lab / 中央实验室·外翼绕行** — bridges move outward; choose between central draft power and stable outer route access.

Design rule:

- A map must change visible route geometry, objective relation, and the physics question.
- Map identity must not rely mainly on hidden `chamber_hit_chance`, `average_cells_crossed`, or other proxy multipliers.

## 9. Formal Pre-Match Flow / 正式开局流程

1. Map selection.
2. Player hero selection.
3. Reveal the AI hero.
4. Show both heroes’ base attributes.
5. Start the match.

Requirements:

- Map cards show route preview, bridge/gate count, stronghold composition, identity, and one opening hint.
- Hero cards show base volley, chamber health, ordinary starting defense, contact-front defense, cap, and strategic identity.
- Mirror matches remain allowed.
- Confirmed map and hero IDs must enter runtime configuration before world construction.
- Desktop and narrow/mobile layouts require dedicated tests.

## 10. Upgrade And AI Architecture / 强化与 AI 架构

Before the catalog grows beyond eight upgrades, replace the expanding `match effect_id` block with modular handlers:

- `VolleyEffect`
- `ProjectileEffect`
- `CaptureEffect`
- `GateEffect`
- `DefenseEffect`
- `DraftEffect`
- `DelayedEffect`

The next AI slice must replace fixed scores such as `x2 = 92` with a shared marginal-value policy used by both live AI and simulation.

Required value components:

- Actual additional shots after caps for `+5` and `x2`.
- Actual number and route value of distinct repairable cells.
- Fillable value of a higher defense cap instead of empty capacity.
- Expected defended contacts for armor piercing.
- Expected chamber hits and remaining health for attack growth.
- Delay discount for Echo.
- Remaining draft count and probability improvement for rarity.
- Score explanation containing immediate value, long-term value, route value, and expected waste.

A new effect or AI score is incomplete until live runtime, simulation, player-facing explanation, validation, and tests all exist.

## 11. Active And Planned Slices / 当前与后续阶段

### Active Next: v0.3.3a5 — Shared Marginal Upgrade Value Policy

- Create a shared `CardfrontUpgradeValuePolicy`.
- Replace fixed `+5`, `x2`, attack, repair, defense-cap, armor-piercing, Echo, and rarity scores.
- Use actual added shots and actual consumable effects.
- Make live AI and the fast simulator call the same policy.
- Emit per-offer score breakdowns for later B1 auditing.

### v0.3.3a6 — Strategic Map Schema And Preview

- Add `route_layout` and `strategy_profile` to all three map definitions.
- Validate sorted, non-overlapping bridge lanes and bounded control zones.
- Add player-facing identity and opening-hint data.
- Add route-layout snapshots/tests without changing live behavior yet.

### v0.3.3a7 — Live Map And Gate Geometry

- Stop forcing `generate_default_layout()` in live runtime.
- Build the selected map definition from configuration.
- Configure gate crossing and control sampling from the map’s `route_layout`.
- Move 3D bridges and gates from the same authoritative route data.
- Add visual and physics alignment tests.

### v0.3.3a8 — Simulation Parity B1

- Model Engineer opening contact-front cells and per-cell repair/defense.
- Model open, half-open, and closed gate passage/reflection.
- Actually rerun both side variants.
- Record gate passes, gate reflections, lane traffic, and map-specific route pressure.
- Record card appearance, selection, consumption, wasted value, and hero-specific build distribution.
- Run full candidate search before changing hero base values.

Candidate order after B1:

1. Current Engineer: 5 volley / 42 health / contact front `2/2`.
2. If Engineer aggregate remains below 47%: test health `42 -> 44`.
3. Only if still severely weak: consider another visible mechanism; do not immediately change base volley from 5.
4. Keep Gunner at 7 volley / 36 health until the Engineer and AI corrections are represented.

### Later

- `v0.3.3b0`: formal map/hero pre-match flow and combat snapshot.
- `v0.3.3b1`: upgrade-effect registry.
- `v0.3.3b2`: four-card route module.
- `v0.3.3b3`: final expanded 108,000-match A/B evidence gate.
- `v0.3.4`: map geometry expansion and visual polish.

## 12. Acceptance Requirements / 验收要求

Every gameplay slice must include:

- Content validation.
- Headless regression tests.
- Performance smoke tests.
- Explicit edge cases and no-refill/no-duplication checks.
- Visual/readability checks where player-visible state changes.

Every map-related slice must additionally include:

- 2D authority versus 3D presentation alignment checks.
- Desktop and narrow/mobile readability checks where UI is involved.
- Human acceptance: bridge positions, route tradeoffs, and stronghold relation should be understandable before the first volley.

No map is considered strategically complete until a player can describe its main decision after one match without reading the map name.

## 13. Deferred / 暂缓

- Online or local human multiplayer.
- Full deckbuilder and meta-progression.
- Large uncontrolled card catalog.
- Hero-exclusive card pools.
- Hidden hero hit-rate compensation as a permanent balance rule.
- Changing Engineer base volley before valid B1 evidence.
- Single-bridge and asymmetric competitive maps before true side reruns exist.
- Moving or random bridges during combat.
- Large bumper/obstacle catalogs before the first three route identities work.
- Rewriting projectile simulation as true 3D physics.
