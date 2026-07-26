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

The first-generation baseline remains locked during simulation and map-parity work:

| Hero | Base volley | Chamber health | Starting defense | Defense cap | Strategic identity |
| --- | ---: | ---: | ---: | ---: | --- |
| Balanced Commander / 均衡指挥官 | 6 | 40 | 1 | 1 | Broad card compatibility |
| Rapid Gunner / 连射炮手 | 7 | 36 | 1 | 1 | Multiplier and burst value |
| Fortification Engineer / 筑垒工程师 | 5 | 42 | 1 | 2 | Defense capacity and position repair |

Hero state layers:

- Identity: hero ID/name, base volley, chamber maximum health, starting territory defense, and initial defense cap.
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
- Newly captured territory begins at zero current defense.
- Permanent attack growth uses levels `0..3`.
- Temporary effects may raise the resolved attack level to 4 for one volley.
- Echo queues and replays the next selected upgrade during the following round.
- Player and AI hero IDs can already be injected through runtime configuration.

Remaining hero work:

- Formal player hero selection and AI hero reveal UI.
- AI repair, armor-piercing, and route-card valuation based on live route pressure.
- Read-only combat snapshot shared by UI and decision systems.

## 3. Attack And Defense Semantics / 攻防语义

### Attack

- Permanent attack level: `0..3`.
- Each level adds 25% chamber damage.
- Temporary attack effects may raise the resolved volley level to 4.
- Resolved damage sequence: `100% / 125% / 150% / 175% / 200%`.
- Level 4 is temporary only and is never written back into permanent run state.
- Live runtime and parity simulation now use the level-4 temporary ceiling.

### Defense

- Global territory-defense cap belongs to hero identity and run growth.
- Hard cap is 4.
- Starting owned cells begin at `1 / hero cap`.
- Newly captured or recaptured cells begin at `0 / current cap`.
- Increasing the cap does not refill current defense.
- An effective hostile hit removes one current-defense point; a later hit captures after defense reaches zero.
- Automatic full-map refill is removed.
- Frontline Repair restores at most 6 different owned frontline cells and adds exactly 1 defense point to each.
- One repair card never visits the same cell twice, even when fewer than 6 eligible cells exist.

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
- Stronghold, repair, vertical-slice, performance, and repository-wide headless tests passed.

### v0.3.3a2 — Explicit Historical And Parity Simulation Modes

Status: completed and merged to `main` at commit `a2d004c`.

- `historical_compensated`: preserves hidden hero hit-rate compensation and resolved attack cap 3 so the original audit remains reproducible.
- `parity_uncompensated`: disables hidden hero accuracy and uses temporary resolved attack cap 4.
- Match and report output now identifies simulation mode, compensation state, and attack ceiling.
- Historical 54,000-match gate remains merge-blocking.
- A small full-matrix parity probe validates the new mode contract.

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

Boundary: this baseline includes hidden Engineer/Gunner hit-rate compensation, does not model authoritative gates, and reports a synthetic second side by flipping the first result instead of rerunning geometry.

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
- Removing it exposes the Engineer as dramatically weak in the current proxy model and the Gunner as dramatically strong.
- Do not immediately rebalance hero health or base volleys from B0 alone.
- B0 still lacks real gate control, map-specific route geometry, true side reruns, per-card value metrics, and human aiming behavior.
- Hero baseline remains locked until B1/B2 parity evidence exists.

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
- Existing readability tests mainly prove the default five-stronghold layout is large, separate, and symmetric; they do not prove three live maps feel different.

Therefore the user’s lack of an intuitive map difference is expected and accurate.

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
- Hero cards show base volley, chamber health, starting defense, cap, and strategic identity.
- Mirror matches remain allowed.
- Confirmed map and hero IDs must enter runtime configuration before world construction.
- Desktop and narrow/mobile layouts require dedicated tests.

## 10. Upgrade Architecture / 强化实现架构

Before the catalog grows beyond eight upgrades, replace the expanding `match effect_id` block with modular handlers:

- `VolleyEffect`
- `ProjectileEffect`
- `CaptureEffect`
- `GateEffect`
- `DefenseEffect`
- `DraftEffect`
- `DelayedEffect`

Each handler should support validation, eligibility, application, AI value estimation, simulation, and result description. A new effect is incomplete until live runtime, AI valuation, simulation support, player-facing text, validation, and tests all exist.

## 11. Active And Planned Slices / 当前与后续阶段

### Active: v0.3.3a3 — B0 Audit And Strategic Map Specification

- Persist full B0 audit as a GitHub Actions artifact.
- Record exact B0 evidence in this status document.
- Define the first three visible strategic map identities.

### Next: v0.3.3a4 — Strategic Map Schema And Preview

- Add `route_layout` and `strategy_profile` to all three map definitions.
- Validate sorted, non-overlapping bridge lanes and bounded control zones.
- Add player-facing identity and opening-hint data.
- Add route-layout snapshots/tests without changing live behavior yet.

### Next: v0.3.3a5 — Live Map And Gate Geometry

- Stop forcing `generate_default_layout()` in live runtime.
- Build the selected map definition from configuration.
- Configure gate crossing and control sampling from the map’s `route_layout`.
- Move 3D bridges and gates from the same authoritative route data.
- Add visual and physics alignment tests.

### Next: v0.3.3a6 — Simulation Parity B1

- Model open, half-open, and closed gate passage/reflection.
- Actually rerun both side variants.
- Record gate passes, gate reflections, lane traffic, and map-specific route pressure.
- Record card appearance, selection, consumption, wasted value, and hero-specific build distribution.
- Run a new full B1 audit before changing hero base values.

### Later

- `v0.3.3b0`: formal map/hero pre-match flow and combat snapshot.
- `v0.3.3b1`: upgrade-effect registry.
- `v0.3.3b2`: four-card route module.
- `v0.3.3b3`: final expanded 108,000-match A/B evidence gate.
- `v0.3.4`: map geometry expansion and visual polish.

## 12. Acceptance Requirements / 验收要求

Every map-related slice must include:

- Content validation.
- Headless regression tests.
- 2D authority versus 3D presentation alignment checks.
- Performance smoke tests.
- Desktop and narrow/mobile readability checks where UI is involved.
- Human acceptance: bridge positions, route tradeoffs, and stronghold relation should be understandable before the first volley.

No map is considered strategically complete until a player can describe its main decision after one match without reading the map name.

## 13. Deferred / 暂缓

- Online or local human multiplayer.
- Full deckbuilder and meta-progression.
- Large uncontrolled card catalog.
- Hero-exclusive card pools.
- Complex hero passives before the three base identities are validated.
- Single-bridge and asymmetric competitive maps before true side reruns exist.
- Moving or random bridges during combat.
- Large bumper/obstacle catalogs before the first three route identities work.
- Rewriting projectile simulation as true 3D physics.
