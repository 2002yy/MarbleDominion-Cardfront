# Project Status / 项目状态

Last updated: 2026-07-26

This is the only document that tracks the current version, active implementation slice, next step, and deferred scope.
本文件是项目当前版本、正在实施内容、下一步和暂缓范围的唯一状态入口。

## Current Direction / 当前方向

Cardfront is being rebuilt as a single-match 1v1 physics strategy roguelite:

> 地图选择 -> 玩家选择英雄 -> 展示 AI 英雄与双方基础属性 -> 开始对局 -> 调整炮口方向 -> 倒计时结束 -> 全场暂停 -> 三选一强化 -> 超时随机 -> 双方结算 -> 自动齐射 -> 争夺路线并摧毁敌方控制舱

Confirmed product decisions:

- First mode is player versus AI, with two factions only.
- During the first implementation stage, the player controls firing direction only.
- The world fully pauses during the three-choice draft; draft timeout continues in real time.
- Timeout chooses one of the offered upgrades at random.
- `+5` and `x2` affect the next volley only.
- Attack level, territory defense cap, and rarity upgrades persist for the current match; base volley does not grow permanently.
- Echo repeats the next selected upgrade once in the following round instead of duplicating it in the same round.
- The primary win condition is destroying the enemy command chamber.
- Territory supplies routes, defense, gate control, stronghold control, and firing advantages; territory percentage is no longer the primary victory condition.
- Special regions are tactical strongholds tied to volleys and drafts, not Energy/Parts income.
- The battlefield presentation target is a true orthographic `Camera3D` 2.5D angled board.
- The authoritative game state and projectile simulation remain 2D; the orthographic 3D layer is presentation-only.
- New upgrades should primarily change projectile routing, capture behavior, volley distribution, and post-capture fortification instead of adding larger flat numbers.

## Approved Hero Numeric Route / 三英雄数值路线

Status: approved product and balance direction. The `v0.3.2d` hero-balance simulation gate is live and the approved numeric baseline passes its first 54,000-match proxy audit. The baseline remains locked until simulation/live parity work is complete.

The first-generation hero baseline is:

| Hero | Base volley | Chamber health | Starting defense | Defense cap | Strategic identity |
| --- | ---: | ---: | ---: | ---: | --- |
| Balanced Commander / 均衡指挥官 | 6 | 40 | 1 | 1 | Broad card compatibility |
| Rapid Gunner / 连射炮手 | 7 | 36 | 1 | 1 | Multiplier and burst value |
| Fortification Engineer / 筑垒工程师 | 5 | 42 | 1 | 2 | Defense capacity and position repair |

This baseline constrains cards, strongholds, AI valuation, timeout scoring, and target match length. Hero identity must remain visible for the whole match, so permanent base-volley growth is excluded from the first generation.

### Authoritative Hero State Model / 英雄状态模型

Hero-related state is divided into explicit layers:

- Identity state: hero ID and name, base volley, maximum chamber health, starting territory defense, and initial defense cap.
- Persistent run growth: permanent attack level `0..3`, territory-defense cap up to 4, and rarity level `0..3`.
- Next-volley state: additive shot bonus, multiplier capped at `x2`, armor-piercing contacts, and future route/projectile modifiers.
- Delayed state: armed Echo and the queued upgrade to replay.
- World-authoritative state: current chamber health, per-cell current defense, territory ownership, active strongholds, locked gate state, and current aim direction.
- Planned read model: add a read-only `CardfrontFactionCombatSnapshot` that aggregates these systems for UI, AI, and simulation without becoming a second gameplay authority.

Migration status:

- Completed: base volley now comes from the selected hero at 5, 6, or 7 shots.
- Completed: command-chamber health now comes from the selected hero at 42, 40, or 36.
- Completed: territory defense is seeded once at match start and no longer refills every owned cell before each volley.
- Completed: territory-defense hard cap is now 4, with the engineer starting at capacity 2.
- Completed: newly captured territory remains at zero current defense, and increasing capacity does not refill current defense.
- Completed: permanent attack growth uses levels `0..3`, with chamber damage accumulated at `100% / 125% / 150% / 175%`.
- Approved next correction: temporary attack bonuses may raise the resolved attack level to 4 for that volley, producing 200% chamber damage, without changing the permanent level-3 cap.
- Completed: Echo queues the next selected upgrade and replays it once during the following round.
- Completed: AI valuation accounts for base volley, current attack level, and match growth instead of one universal static order.
- Remaining: AI repair and armor-piercing valuation does not yet inspect live route pressure or per-cell defense.
- Remaining: player and AI hero assignments are configuration-driven, but the formal pre-match selection and comparison flow is not implemented.

### Approved Attack Semantics / 攻击等级语义

- Permanent attack level is `0..3`.
- Each permanent level adds 25% chamber damage.
- Temporary attack effects, including an Energy stronghold, may raise the resolved volley level to 4.
- Resolved chamber damage is therefore `100% / 125% / 150% / 175% / 200%`.
- Level 4 is temporary only and must never be written back into permanent run state.
- The live runtime and balance simulator must use the same resolved-level rule.

### Approved Defense Semantics / 防御语义

- Global territory-defense cap belongs to hero identity and run growth.
- Hard cap is 4.
- Starting owned territory begins at `1 / hero cap`.
- Newly captured or recaptured cells begin at `0 / current cap`.
- Increasing the cap never refills current defense.
- An effective hostile hit removes one current-defense point; a later hit captures the cell after defense reaches zero.
- Automatic full-map refill is removed.
- Repair must be finite and strictly distributed.
- Frontline Repair restores at most 6 different owned frontline cells and adds exactly 1 current-defense point to each selected cell.
- A single repair card never visits the same cell twice, even when fewer than 6 eligible cells exist.
- Repair never affects neutral or enemy territory and never exceeds the owner’s current defense cap.

## Approved First-Generation Upgrade Direction / 第一代强化

- Common `+5` affects the next volley.
- Uncommon `x2` affects the next volley.
- Attack growth uses permanent attack level `0..3`; each level adds 25% chamber damage.
- Defense-cap growth stops being offered at cap 4.
- Rarity growth stops at the first-generation cap and disappears from offers when capped.
- Limited armor penetration counters high-defense routes.
- Mirror is replaced by Echo: the next selected upgrade applies once this round and once again next round.
- Normal volleys remain at or below 24 shots.
- Explicit exceptional bonuses may reach 32 shots.
- Same-round multiplier stacking is disallowed.

Current first-generation catalog:

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

## Approved Stronghold And Timeout Direction / 据点与超时

- Factory: next volley `+3` shots instead of `+4`.
- Energy: next volley gains one temporary attack level.
- Energy may raise a permanent level-3 build to resolved level 4 for that volley.
- Laboratory: draft four upgrades and choose one, replacing the late-game rarity guarantee.
- Destroying the enemy chamber remains an immediate win.
- Timeout score is `50% chamber health + 35% territory + 15% strongholds`.
- Chamber health is normalized against each hero’s own maximum.

## Balance Audit Status / 平衡模拟状态

The current historical balance gate records:

- Matrix: `3 heroes x 3 enemy heroes x 3 maps x 2 sides x 1000 seeds = 54,000` matches.
- Balanced Commander: `51.46%`.
- Fortification Engineer: `49.09%`.
- Rapid Gunner: `49.45%`.
- Ordered matchup range: `47.62%..53.70%`.
- Mirrored position rates: inside `49%..51%`.
- Median match length: 22 rounds.
- P90 match length: 34 rounds.
- Timeout rate: `12.25%`.
- Average first stronghold activation: round `6.03`.
- Average cells crossed per marble: `19.25`.
- Chamber hits per volley: `1.231`.
- Defense absorbed per volley: `2.271`.
- Invalid or capped offers: zero.

Interpretation boundaries:

- The audit is a physics-informed proxy, not proof of live projectile balance or human win rate.
- The audit includes a hidden hero hit-rate compensation: low-base-volley heroes receive extra hit probability while high-base-volley heroes receive a reduction.
- That hidden compensation materially narrows expected chamber-hit differences between the 5-shot Engineer and 7-shot Gunner.
- Hidden accuracy compensation is not approved as a permanent player-facing rule.
- The current gate-connectivity rules were added after the 54,000-match baseline and are not represented by that historical audit.
- The simulator currently caps permanent plus temporary attack at level 3 while live Energy can reach level 4; this must be aligned.
- The historical 54,000-match result must be retained as an A baseline.
- A new B audit must remove hidden hero accuracy compensation, include authoritative gate behavior, and use the approved temporary level-4 rule before hero base values are changed.
- Hero base volleys `5/6/7`, chamber health `42/40/36`, and starting defense `1/2, 1/1, 1/1` remain locked during this parity phase.

## Approved Pacing Targets / 节奏目标

- Hard match limit remains 8 minutes.
- Median match length: 16 to 22 rounds.
- Target play time: 4 to 5.5 minutes.
- P90 match length: no more than 8 minutes.
- Timeout rate target: 10% to 25%.
- First stronghold activation target: rounds 4 to 8.
- Invalid or capped upgrade offers: zero.

The implementation must record average cells crossed per marble, chamber hits per volley, defense absorbed, first stronghold activation, round count, gate passage/reflection, card appearance, card selection, and actual effect value before hero health or base-volley values are tuned away from this baseline.

## Approved Pre-Match Flow / 正式开局流程

The first formal match setup flow is:

1. Map selection.
2. Player hero selection.
3. Reveal the AI hero.
4. Show both heroes’ base attributes.
5. Start the match.

Requirements:

- Map cards show route structure, bridge/gate count, stronghold composition, and a short tactical identity.
- Hero cards show name, base volley, maximum chamber health, starting defense, defense cap, and strategic identity.
- The AI hero is revealed before combat so the player can understand likely burst, durability, armor-piercing, and route-control pressures.
- Mirror matches remain allowed and are required for positional-bias testing.
- The confirmation screen shows the selected map and both heroes side by side.
- The confirmed `player_hero_id` and `ai_hero_id` are written into runtime configuration before world construction.
- Default fallback to Balanced Commander remains only for invalid or missing configuration, not as the normal product flow.
- Pre-match UI must have desktop and narrow/mobile layout tests.

## Approved Expansion Principles / 扩卡原则

External references inform mechanism selection, not direct copying:

- `Peglin` and `Flick Shot Rogues`: projectile behavior, collision, aiming, and routing should be part of the build.
- `Ballionaire` and `Rack and Slay`: triggers and physical chains can create build identity, but Cardfront’s 4-to-5.5-minute target cannot support an uncontrolled hundred-item pool.
- `Balatro` and `Luck be a Landlord`: a larger catalog needs clear effect families, tags, and interaction rules instead of one flat random pool.
- `Shattered Pixel Dungeon`: shared content should change value across heroes rather than creating three isolated hero-only catalogs.
- Open-source Godot roguelike patterns: upgrades should be data-defined and resolved through modular effect handlers.

The next card expansion must focus on:

- How projectiles cross routes and gates.
- How projectiles capture cells.
- How one volley is distributed between routes.
- How newly captured territory becomes defensible.

Do not prioritize additional flat upgrades such as `+8`, `x3`, or permanent `+50%` damage.

### Route Module / 路线模块

The second catalog stage adds four behavior-changing upgrades:

| Upgrade | Rarity | Approved behavior |
| --- | --- | --- |
| Vanguard Warhead / 先锋弹头 | Common | The first 4 projectiles continue after their first successful capture and may capture one additional cell |
| Gate Breach Round / 破门弹 | Uncommon | The first 4 gate rejections next volley become valid bridge passages; off-bridge river crossing remains blocked |
| Bridgehead Fortification / 桥头筑垒 | Uncommon | The first 6 newly captured cells inside locked gate-control zones gain 1 current defense, capped by owner capacity |
| Split-Lane Volley / 双路齐射 | Rare | Total shot count is unchanged; the volley is divided between the selected direction and its horizontal mirror |

Catalog policy:

- Global catalog after this stage: 12 upgrades.
- Active match catalog: core 8 plus one approved 4-card route module.
- Route cards do not permanently raise base volley.
- Route cards do not add a new damage multiplier.
- Route cards do not bypass the 24 normal / 32 exceptional volley ceilings.
- Route cards must expose actual-consumption metrics so zero-value choices can be detected.

## Upgrade Implementation Architecture / 强化实现架构

Before the catalog grows beyond 8 upgrades, effect resolution should move away from one expanding `match effect_id` block.

Planned registry:

- `CardfrontUpgradeEffectRegistry`
- `VolleyEffect`
- `ProjectileEffect`
- `CaptureEffect`
- `GateEffect`
- `DefenseEffect`
- `DraftEffect`
- `DelayedEffect`

Each effect handler should support:

- `validate`
- `is_eligible`
- `apply`
- `estimate_value`
- `simulate`
- `describe_result`

Upgrade definitions should expose:

- `tags`
- `duration`
- `stack_rule`
- `target_scope`
- `effect_handler_id`
- `eligibility_id`
- `ai_value_id`
- `simulation_effect_id`
- effect parameters

The live resolver and fast simulator must consume the same definitions and equivalent effect semantics. A new effect is incomplete until live runtime, AI valuation, simulator support, player-facing text, validation, and tests all exist.

## Version / 版本

- Stable baseline: `v0.2.5.7-ui-copy-readability-pass`
- Baseline commit: `9eadf9b`
- Core-loop foundation commit: `bef12ce`
- Current completed slice: `v0.3.3a-gate-connectivity-rules`
- Next slice: `v0.3.3a1-simulation-parity`
- Active branch: `main`

## Completed Slice / 已完成阶段

`v0.3.3a-gate-connectivity-rules` turns the two visible bridge gates into authoritative projectile routes while keeping the 2D simulation as the sole gameplay authority.

Scope:

- Each gate samples a compact territory-control zone around its bridge when the three-choice draft opens.
- Gate state is locked for the following volley, matching the existing round-based stronghold cadence.
- Projectiles copy that locked snapshot when spawned, so an in-flight marble cannot change permission halfway through a crossing.
- Below 55% control, a gate is open to both factions.
- At 55% to 79% control, the owner passes every marble while enemy marbles alternate between pass and reflection.
- At 80% or more control, the owner passes every marble and enemy marbles reflect from the river bank.
- Marbles attempting to cross the center river outside either bridge also reflect from the river bank.
- Before the first draft snapshot, both gates remain open to both factions.
- `CardfrontOrthographicArenaView` receives the locked state only for presentation and labels each gate as open, half-open, or closed with faction color.
- The shared `Bullet` and `BulletPool` expose a nullable route-filter boundary; BallWar leaves it null and retains its old behavior.

Acceptance:

- Native rule tests cover default-open behavior, 55% and 80% thresholds, owner passage, alternating enemy passage, snapshot locking, and off-bridge river rejection.
- Live runtime tests verify the route filter is attached in Cardfront, a draft updates the gate snapshot and 3D display, and a blocked marble reflects.
- Runtime-boundary tests explicitly verify BallWar creates neither the gate system nor a route filter.
- Existing orthographic arena, round combat, runtime builder, Cardfront smoke, BallWar Smoke, and Integration tests remain green.
- The gate test set is a dedicated GitHub Actions batch.

## Previous Slice / 上一阶段

`v0.3.2d-hero-balance-simulation` added the deterministic 54,000-match headless balance proxy and made the complete hero matrix a dedicated GitHub Actions gate.

- Full audit result: Balanced Commander `51.46%`, Fortification Engineer `49.09%`, Rapid Gunner `49.45%`.
- Ordered matchup range: `47.62%..53.70%`; mirrored position rates remain inside `49%..51%`.
- Median match length is 22 rounds, P90 is 34 rounds, and timeout rate is `12.25%`.
- The audit is a physics-informed balance proxy, not proof of live projectile balance or human win rate.
- `CardfrontHeroBalanceSimulationTestRunner.gd` asserts the full match count and all approved thresholds in CI.

## Earlier Visual Slice / 更早视觉阶段

`v0.3.1c.1-tall-arena-ownership-readability` refines the open dual-gate arena into a taller, finer-grained field while preserving the tested 2D simulation as the sole gameplay authority.

Scope:

- A dedicated `SubViewport` now renders a true `Camera3D` in orthographic projection over an XZ battlefield.
- The 3D presentation uses a separate full-width `arena_view_rect`; the square logical battlefield remains unchanged for input and physics.
- A `MultiMeshInstance3D` mirrors every authoritative 2D territory cell without introducing 3D collision or duplicate game state.
- Fine cell gaps are visually suppressed. A second `MultiMeshInstance3D` draws only the map perimeter and live ownership fronts as bold cartoon boundaries.
- The terrain uses an olive checker, two narrow earth lanes, a slim river, wood-toned crossings, and simple green perimeter foliage.
- The visual field is stretched along its battle axis while the authoritative `40 x 40` coordinates remain unchanged.
- Player and AI ownership remain readable through cool-blue and warm-red terrain tints plus a dynamic dark frontier outline.
- The player and AI turrets, command chambers, barrel direction, health, active marbles, and aim ray are mirrored into reusable 3D visual proxies.
- Both command turrets sit beyond the top and bottom battlefield borders, with only their arena-facing chamber edge intruding into play space.
- Energy, Factory, and Laboratory strongholds are large raised platforms with in-world type and control-percentage labels.
- The center is a bright river corridor with two bridge gates.
- The region information panel is contextual and collapses outside a stronghold.
- The 3D viewport ignores mouse input, so existing 2D battlefield targeting remains authoritative.
- BallWar does not create the orthographic arena view.

Acceptance:

- Cardfront creates one active orthographic `Camera3D`, 1,600 mirrored tiles, dynamic ownership-front outlines, five stronghold platforms, two bridges, two gate views, and two combatant proxies.
- At `1120 x 720`, the arena presentation spans at least 95% of viewport width and 78% of viewport height.
- The arena uses a daylight background and bright territory palette.
- Connected starting territory produces no sparse markers; an isolated claim produces one faction marker.
- A bottom-edge player position maps to the positive-Z half of the 3D world.
- Active 2D bullets receive capped, reusable 3D sphere proxies.
- The original `Battlefield`, `BulletPool`, `Bullet`, and `Turret` nodes remain gameplay authorities.
- The presentation layer cannot intercept map clicks.
- Existing arena, direction, Cardfront mode, performance, BallWar Smoke, and Integration tests remain green.

Known transition boundaries:

- The old `Node2D` arena framing remains underneath as a fallback and decorative surround.
- Primitive meshes and lighting remain graybox-quality.
- Gate geometry currently uses shared normalized positions.
- AI target valuation does not yet score gate ownership or route pressure.
- 3D bullet proxies do not yet have a dedicated trail/VFX library.
- Stronghold and gate control are intentionally sampled and locked at round boundaries.
- The three registered map definitions still share one stronghold ruleset.
- The historical balance simulator does not yet model authoritative gate passage and reflection.
- Live and simulated Energy attack-level ceilings are not yet aligned.
- Frontline Repair implementation must be changed from repeated passes to one pass over different cells.

## Planned Slices / 后续阶段

1. `v0.3.3a1-simulation-parity`
   - Allow permanent attack `0..3` and temporary resolved attack up to 4 in both live runtime and simulation.
   - Make Frontline Repair affect at most 6 different cells, one point per cell.
   - Preserve the historical hidden-compensation audit as baseline A.
   - Run baseline B without hidden hero accuracy compensation.
   - Add authoritative gate passage, half-open filtering, closure, and reflection to the simulator.
   - Record card appearance, selection, consumption, wasted value, gate passage, gate reflection, and hero-specific build distribution.
2. `v0.3.3b0-pre-match-hero-flow`
   - Implement map selection, player hero selection, AI hero reveal, side-by-side base-stat confirmation, and start-match transition.
   - Add the read-only `CardfrontFactionCombatSnapshot`.
   - Verify valid configuration reaches hero registry, chambers, run states, HUD, and simulator.
   - Add desktop and narrow/mobile flow tests.
3. `v0.3.3b1-upgrade-effect-registry`
   - Introduce modular effect families and data-driven effect handlers.
   - Keep live resolver and fast simulator semantics aligned.
   - Migrate the existing 8 upgrades without changing their approved player-facing effects.
4. `v0.3.3b2-route-card-module`
   - Add Vanguard Warhead, Gate Breach Round, Bridgehead Fortification, and Split-Lane Volley.
   - Add live effects, AI valuation, simulation proxies, UI state, content validation, and combination tests.
5. `v0.3.3b3-expanded-balance-gate`
   - Retain the original 54,000-match historical gate.
   - Add a second 54,000-match gate with authoritative gates, no hidden hero accuracy compensation, temporary attack level 4, and the 12-card active catalog.
   - Treat the combined 108,000 matches as A/B evidence, not as a replacement for live playtesting.
   - Require aggregate hero rates `47%..53%`, ordered matchup rates `43%..57%`, mirrored position rates `49%..51%`, median 16–22 rounds, timeout 10%–25%, and zero invalid offers.
   - Require no single card to exceed 30% of all AI selections and track zero-value selections by card and hero.
6. `v0.3.4a-map-identity-expansion`
   - Add distinct route structures, chamber approaches, gate-control zones, and stronghold placements.
   - Replace map-owned proxy differences with tested live geometry where possible.
7. `v0.3.4b-orthographic-visual-polish`
   - Replace primitive chamber silhouettes with authored low-poly presenters.
   - Add readable projectile trails, gate impacts, capture pulses, and defense feedback.
   - Establish shared typography and material rules for in-world labels.

## Reuse And Replacement / 复用与替换

Keep or adapt:

- Bullet pooling and performance pressure controls.
- Directed burst queue and barrel/projectile alignment.
- Chamber quarter-health accumulation semantics.
- Pauseable game layer plus always-processing UI architecture.
- Content validation, map registry, feedback, VFX, and native test patterns.
- Hero registry, upgrade manifest, stronghold snapshot, and gate snapshot as authoritative inputs.

Replace or refactor:

- Fixed four-card hand.
- Energy and parts payment.
- Click-a-map-target card flow.
- Automatic target-scoring fire director.
- Territory-percentage victory.
- Current flat battlefield and dense `40 x 40` presentation.
- Monolithic upgrade `match effect_id` resolution.
- Hidden hero accuracy compensation as an undocumented permanent balance mechanism.

## Deferred / 暂缓

- Online or local human multiplayer.
- Full deckbuilder and meta-progression.
- Complete save/load for the new run state.
- Large uncontrolled card catalog.
- Hero-specific exclusive card pools.
- Complex hero passives before the three base identities are validated in live play.
- Final creature art before summon rules are playable.
- Rewriting projectile simulation as true 3D physics.
