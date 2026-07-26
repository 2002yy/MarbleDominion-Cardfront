# Project Status / 项目状态

Last updated: 2026-07-26

This is the only document that tracks the current version, active implementation slice, next step, and deferred scope.
本文件是项目当前版本、正在实施内容、下一步和暂缓范围的唯一状态入口。

## Current Direction / 当前方向

Cardfront is being rebuilt as a single-match 1v1 physics strategy roguelite:

> 调整炮口方向 -> 倒计时结束 -> 全场暂停 -> 三选一强化 -> 超时随机 -> 双方结算 -> 自动齐射 -> 争夺路线并摧毁敌方控制舱

Confirmed product decisions:

- First mode is player versus AI, with two factions only.
- During the first implementation stage, the player controls firing direction only.
- The world fully pauses during the three-choice draft; draft timeout continues in real time.
- Timeout chooses one of the three offered upgrades at random.
- `+5` and `x2` affect the next volley only.
- Attack level, territory defense cap, and rarity upgrades persist for the current match; base volley does not grow permanently.
- Echo repeats the next selected upgrade once in the following round instead of duplicating it in the same round.
- The primary win condition is destroying the enemy command chamber.
- Territory supplies routes, defense, and firing advantages; territory percentage is no longer the primary victory condition.
- Special regions will be tactical strongholds tied to volleys and drafts, not Energy/Parts income.
- The battlefield presentation target is a true orthographic `Camera3D` 2.5D angled board.
- The current `Node2D` battlefield is a transitional simulation/presentation layer, not the final camera solution.

## Approved Hero Numeric Route / 三英雄数值路线

Status: approved product and balance direction. The `v0.3.2b` hero, defense, and first-generation card foundation is live; stronghold, timeout, and simulation changes remain planned.

The first-generation hero baseline is:

| Hero | Base volley | Chamber health | Starting defense | Defense cap | Strategic identity |
| --- | ---: | ---: | ---: | ---: | --- |
| Balanced Commander / 均衡指挥官 | 6 | 40 | 1 | 1 | Broad card compatibility |
| Rapid Gunner / 连射炮手 | 7 | 36 | 1 | 1 | Multiplier and burst value |
| Fortification Engineer / 筑垒工程师 | 5 | 42 | 1 | 2 | Defense capacity and position repair |

This baseline constrains cards, strongholds, AI valuation, timeout scoring, and target match length. Hero identity must remain visible for the whole match, so permanent base-volley growth is excluded from the first generation.

Migration status:

- Completed: base volley now comes from the selected hero at 5, 6, or 7 shots.
- Completed: command-chamber health now comes from the selected hero at 42, 40, or 36.
- Completed: territory defense is seeded once at match start and no longer refills every owned cell before each volley.
- Completed: territory-defense hard cap is now 4, with the engineer starting at capacity 2.
- Completed: newly captured territory remains at zero current defense, and increasing capacity does not refill current defense.
- Completed: attack growth uses levels `0..3`, with chamber damage accumulated at `100% / 125% / 150% / 175%`.
- Completed: Echo queues the next selected upgrade and replays it once during the following round.
- Completed: AI valuation accounts for base volley, current attack level, and match growth instead of one universal static order.
- Remaining: AI repair and armor-piercing valuation does not yet inspect live route pressure or per-cell defense.

Approved defense semantics:

- Global territory-defense cap belongs to hero identity and run growth.
- Hard cap is 4.
- Starting owned territory begins at `1 / hero cap`.
- Newly captured or recaptured cells begin at `0 / current cap`.
- Increasing the cap never refills current defense.
- An effective hostile hit removes one current-defense point; a later hit captures the cell after defense reaches zero.
- Automatic full-map refill is removed.
- Repair must be finite. The first repair card restores at most 6 total defense points inside one strategic area and distributes points instead of filling the whole map.

Approved first-generation upgrade direction:

- Common `+5` affects the next volley.
- Uncommon `x2` affects the next volley.
- Attack growth becomes attack level `0..3`; each level adds 25% chamber damage.
- Defense-cap growth stops being offered at cap 4.
- Rarity growth stops at the first-generation cap and disappears from offers when capped.
- Limited armor penetration counters high-defense routes.
- Mirror is replaced by Echo: the next selected upgrade applies once this round and once again next round.
- Normal volleys should remain at or below 24 shots; exceptional content may reach 32, but same-round multiplier stacking is disallowed.

Approved stronghold and timeout direction:

- Factory: next volley `+3` shots instead of `+4`.
- Energy: next volley gains one temporary attack level instead of integer `+1` projectile damage.
- Laboratory: draft four upgrades and choose one, replacing the late-game rarity guarantee.
- Destroying the enemy chamber remains an immediate win.
- Timeout score becomes `50% chamber health + 35% territory + 15% strongholds`.

Approved pacing targets:

- Hard match limit remains 8 minutes.
- Median match length: 16 to 22 rounds.
- Target play time: 4 to 5.5 minutes.
- P90 match length: no more than 8 minutes.
- Timeout rate target: 10% to 25%.
- First stronghold activation target: rounds 4 to 8.
- Invalid or capped upgrade offers: zero.

The implementation must record average cells crossed per marble, chamber hits per volley, defense absorbed, first stronghold activation, and round count before hero health or base-volley values are tuned away from this baseline.

## Version / 版本

- Stable baseline: `v0.2.5.7-ui-copy-readability-pass`
- Baseline commit: `9eadf9b`
- Core-loop foundation commit: `bef12ce`
- Current completed slice: `v0.3.2b-card-pool-rebalance`
- Next slice: `v0.3.2c-stronghold-and-timeout-scoring`
- Active branch: `main`

## Completed Slice / 已完成阶段

`v0.3.2b-card-pool-rebalance` replaces the six-card placeholder set with the approved eight-upgrade first generation and carries its rules through real volley, bullet, chamber-damage, and territory-defense paths.

Scope:

- The card pool is exactly eight upgrades: `+5`, `x2`, defense cap, frontline repair, attack training, armor-piercing trajectory, rarity growth, and Echo.
- Attack training has three permanent levels. Each level adds 25% chamber damage through quarter-health accumulation without changing legacy BallWar integer damage.
- Frontline repair restores at most six current-defense points on owned territory and distributes one layer per cell per pass.
- Armor piercing is a one-volley shared budget. The first six defended contacts ignore one defense layer; the seventh contact behaves normally.
- Echo no longer duplicates a choice in the same round. It records the next selected upgrade and replays it once during the following resolution.
- Same-round volley multipliers use the highest multiplier instead of multiplying together.
- Card-driven volleys clamp at 24 shots. Explicit exceptional bonuses, including the transitional stronghold layer, clamp at 32.
- Attack, defense-cap, rarity, and armed-Echo upgrades disappear from offers when they cannot produce a valid gain.
- AI upgrade scoring now uses hero base volley, current attack level, and elapsed upgrade growth.
- The formal battle status reports attack percentage rather than obsolete integer projectile power.
- BallWar keeps its legacy bullet damage and firing entry points.

Acceptance:

- All eight upgrade definitions validate and three-choice offers remain unique.
- Four level-one chamber hits remove five health; level three caps at seven health per four hits.
- Frontline repair restores exactly six points when capacity is available and never repairs neutral territory.
- Six shared armor-piercing contacts bypass one layer each; the seventh defended contact blocks normally.
- Echo applies the copied choice once now and once next round, and repeated `x2` cannot create `x4`.
- Normal and exceptional volley ceilings are covered at 24 and 32.
- Headless parse, upgrade/content, real combat, FireDirector, three-choice runtime, territory defense, hero foundation, Smoke, and Integration tests pass.
- `CardfrontCardPoolRebalanceTestRunner.gd` is part of the GitHub Actions matrix.

## Previous Slice / 上一阶段

`v0.3.1c.1-tall-arena-ownership-readability` refines the open dual-gate arena into a taller, finer-grained field while preserving the tested 2D simulation as the sole gameplay authority.

Scope:

- A dedicated `SubViewport` now renders a true `Camera3D` in orthographic projection over an XZ battlefield.
- The 3D presentation uses a separate full-width `arena_view_rect`; the square logical battlefield remains unchanged for input and physics.
- A `MultiMeshInstance3D` mirrors every authoritative 2D territory cell without introducing 3D collision or duplicate game state.
- Fine cell gaps are visually suppressed. A second `MultiMeshInstance3D` draws only the map perimeter and live ownership fronts as bold cartoon boundaries.
- The terrain now uses a coarse olive checker, two narrow earth lanes, a slim river, wood-toned crossings, and simple green perimeter foliage instead of saturated cyan/pink/green slabs.
- The visual field is stretched along its battle axis while the authoritative 40 x 40 coordinates remain unchanged, creating more top-to-bottom breathing room without invalidating rules or saves.
- The terrain checker now resolves every simulation cell instead of grouping cells into enlarged 3 x 3 patches.
- Player and AI ownership remain readable through cool-blue and warm-red terrain tints plus the dynamic dark frontier outline.
- Isolated claims and one-neighbor chain ends receive a raised, unlit faction-color diamond; connected territory relies on tint and frontier outlines so the field stays clean.
- The player and AI turrets, command chambers, barrel direction, health, active marbles, and aim ray are mirrored into reusable 3D visual proxies.
- Both command turrets now sit beyond the top and bottom battlefield borders, with only their arena-facing chamber edge intruding into play space.
- Energy, factory, and lab strongholds are large raised platforms with in-world type and control-percentage labels.
- The center is now a bright river corridor with two bridge gates. Each gate has a visible open/half-open/closed state and defaults to 100% open.
- The region information panel is contextual and collapses outside a stronghold, so it no longer occupies the right side continuously.
- The contextual region panel and the lower-left direction control were reduced and pushed to the screen edges to protect the arena.
- The 3D viewport ignores mouse input, so existing 2D battlefield targeting remains the input authority.
- The formal HUD remains in its existing higher `CanvasLayer` stack.
- BallWar does not create the orthographic arena view.

Acceptance:

- Cardfront creates one active orthographic `Camera3D`, 1,600 mirrored tiles, dynamic ownership-front outlines, five stronghold platforms, two bridges, two gate views, and two combatant proxies.
- At 1120 x 720, the arena presentation spans at least 95% of the viewport width and 78% of its height.
- The arena uses a daylight background and bright territory palette rather than the previous dark navy board.
- Player, AI, and neutral territory colors have tested minimum RGB separation while sharing one coherent grass material language.
- Connected starting territory produces no sparse markers; introducing one isolated claim produces exactly one faction marker.
- A bottom-edge player position maps to the positive-Z half of the 3D world.
- Active 2D bullets receive capped, reusable 3D sphere proxies.
- The original `Battlefield`, `BulletPool`, `Bullet`, and `Turret` nodes remain 2D gameplay authorities.
- The presentation layer cannot intercept map clicks.
- Existing arena, direction, Cardfront mode, performance, BallWar Smoke, and Integration tests remain green.

Implementation result:

- Added `CardfrontOrthographicArenaView` as a presentation-only runtime boundary.
- Registered the view through `CardfrontArenaBuilder`, `CardfrontRuntimeBuilder`, `CardfrontSystemRegistry`, and `GameRuntimeContext`.
- Added `CardfrontOrthographicArenaTestRunner` to the arena CI batch.
- Verified a real 1120 x 720 OpenGL window render on the local NVIDIA compatibility renderer; the arena is nonblank, bright, full-width, and the empty region panel no longer covers its right side.

Known transition boundaries:

- The old `Node2D` arena framing remains underneath as a fallback and decorative surround; the playable board itself is now rendered by the orthographic 3D viewport.
- Primitive meshes and lighting remain graybox-quality, not final environment art.
- Gate openness is currently a presentation-state API only. Both gates default open and do not yet block, filter, or redirect authoritative 2D bullets.
- 3D bullet proxies currently show the marble body and aim ray, but not a dedicated 3D trail/VFX library.
- Stronghold sampling is intentionally round-based, so control changes during a volley take effect when the next draft opens.
- The three registered map definitions share one stronghold ruleset; their route geometry and visual identity remain a later slice.

## Planned Slices / 后续阶段

1. `v0.3.2c-stronghold-and-timeout-scoring`
   - Change Factory to `+3`, Energy to a temporary attack level, and Laboratory to four-choice drafting.
   - Resolve timeout through chamber-health, territory, and stronghold scoring.
   - Add player-facing scoring and stronghold-value feedback.
2. `v0.3.2d-hero-balance-simulation`
   - Run `3 heroes x 3 enemy heroes x 3 maps x 2 sides x 1000 seeds = 54,000` automated matches.
   - Target 47% to 53% aggregate hero win rates, 43% to 57% matchup win rates, and 49% to 51% mirrored-match win rates.
   - Tune route effectiveness and immediate upgrade value before changing the approved 5/6/7 volley or 36/40/42 health baseline.
3. `v0.3.3a-gate-connectivity-rules`
   - Define who controls each gate, when its state is sampled, and how closed/half-open/open states filter authoritative volleys.
   - Keep both gates open until the rule layer and native tests are complete.
4. `v0.3.3b-map-identity-expansion`
   - Add distinct route structures, chamber approaches, and stronghold placements while retaining the dual-gate language.
5. `v0.3.3c-orthographic-visual-polish`
   - Replace primitive chamber silhouettes with authored low-poly presenters and add readable projectile trails and hit pulses.
   - Establish a shared typography and material policy for in-world labels.

## Reuse And Replacement / 复用与替换

Keep or adapt:

- Bullet pooling and performance pressure controls.
- Directed burst queue and barrel/projectile alignment.
- Chamber pending-count modifier semantics.
- Pauseable game layer plus always-processing UI architecture.
- Content validation, map registry, feedback, VFX, and native test patterns.

Replace in the new main loop:

- Fixed four-card hand.
- Energy and parts payment.
- Click-a-map-target card flow.
- Automatic target-scoring fire director.
- Territory-percentage victory.
- Current flat battlefield and dense `40 x 40` presentation.

## Deferred / 暂缓

- Online or local human multiplayer.
- Full deckbuilder and meta-progression.
- Complete save/load for the new run state.
- Large card catalog.
- Final creature art before summon rules are playable.
- Rewriting projectile simulation as true 3D physics.
