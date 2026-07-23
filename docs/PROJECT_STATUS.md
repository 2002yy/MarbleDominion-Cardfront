# Project Status / 项目状态

Last updated: 2026-07-23

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
- Projectile power, territory defense cap, and rarity upgrades persist for the current match.
- Mirror applies the next selected upgrade twice.
- The primary win condition is destroying the enemy command chamber.
- Territory supplies routes, defense, and firing advantages; territory percentage is no longer the primary victory condition.
- Special regions will be tactical strongholds tied to volleys and drafts, not Energy/Parts income.
- The battlefield presentation target is a true orthographic `Camera3D` 2.5D angled board.
- The current `Node2D` battlefield is a transitional simulation/presentation layer, not the final camera solution.

## Version / 版本

- Stable baseline: `v0.2.5.7-ui-copy-readability-pass`
- Baseline commit: `9eadf9b`
- Core-loop foundation commit: `bef12ce`
- Current completed slice: `v0.3.0d-vertical-slice-playtest-closeout`
- Next slice: `v0.3.1a-map-identity-foundation`
- Active branch: `main`

## Completed Slice / 已完成阶段

`v0.3.0d-vertical-slice-playtest-closeout` closes the first playable direction, draft, volley, territory-defense, and command-chamber loop.

Scope:

- Four-second opening aim window, then six-second aim windows between volleys.
- Full simulation pause during an eight-second three-choice draft, while the draft timeout continues in real time.
- Three formal text-first upgrade cards with hover and press feedback.
- Timeout fallback that selects from the three visible offers.
- AI upgrade selection, lock-in, and reveal.
- Six manifest upgrades wired through the run-state resolver.
- Next-volley `+5` and `x2`, plus permanent projectile power, defense-cap, rarity, and mirror state.
- Twelve-projectile base volleys, with player manual direction and AI automatic targeting resolved simultaneously.
- Territory defense refills each owned cell to its faction cap when a volley launches; incoming enemy hits remove defense before ownership can flip.
- Owner-colored defense outlines and pips make the current protection visible on the battlefield.
- Both command chambers use a 40-point health pool.
- Command-chamber destruction as the immediate primary victory condition.
- Command-chamber damage flashes, shakes, and shows the damage amount.
- Volley launch shows a short `强化生效` confirmation for the selected upgrade.
- The default Cardfront runtime no longer constructs the legacy fixed hand, resource economy, morale, target-bias, device, debug-action, old target-preview, or old feedback chain.
- Legacy systems remain available only through an explicit compatibility flag used by their focused regression tests.
- Native Godot tests and a dedicated GitHub Actions batch.

Acceptance:

- Exactly three upgrade cards are visible during each draft.
- A real card click and the timeout fallback both lock a valid visible offer.
- AI choice locks before reveal and is shown alongside the player choice.
- The simulation resumes before both directed bursts are issued.
- Projectile-power upgrades propagate to real bullets and multiply turret damage.
- Territory-defense upgrades change the visible per-cell armor cap and block the corresponding number of enemy capture hits.
- Neutral cells receive no territory defense.
- Chamber hit feedback and upgrade-application feedback expire without leaving persistent overlays.
- Territory dominance alone no longer ends a Cardfront match.
- Destroying the enemy command chamber ends the match immediately.
- Legacy BallWar creates none of the new round-director or three-choice UI nodes.
- The live-runtime boundary test proves the retired v0.2 systems are absent by default and available only when compatibility is explicitly enabled.
- Existing card, map, effect, performance, Smoke, and Integration gates remain green.

Implementation result:

- Added `CardfrontTerritoryDefenseSystem` and bound it to `volley_launched`.
- Reused `FortifyLayer` as per-cell territory armor with a six-point maximum and dirty-only overlay redraw.
- Added centralized `CardfrontRunTuning` for aim cadence, draft/reveal duration, volley count, chamber health, defense cap, and feedback duration.
- Added command-chamber hit feedback and post-draft upgrade confirmation.
- Added live-only runtime-builder entrypoints while preserving the previous builder as an explicit compatibility assembly.
- Reworded the region panel around route control, firing lanes, and territory defense instead of retired Energy/Parts income.
- Added `CardfrontTerritoryDefenseTestRunner`, `CardfrontVerticalSliceFeedbackTestRunner`, and `CardfrontLiveRuntimeBoundaryTestRunner`.

Known transition boundaries:

- `ENERGY`, `FACTORY`, and `LAB` region identities still exist in map data and visuals, but the retired resource economy no longer gives them a player-facing effect in the live loop.
- AI target scoring still recognizes those legacy resource identities, so the next slice must replace that hidden weighting with explicit tactical-stronghold rules.
- Current map metadata still contains retired `capture_target_percent`, `resource_multiplier`, and fixed-card-pool fields.
- The arena floor is still drawn by `Node2D`; its trapezoid is only a perspective cue, not an orthographic 2.5D camera.

## Planned Slices / 后续阶段

1. `v0.3.1a-tactical-stronghold-contract`
   - Remove retired economy/card-pool/win-rule metadata from the live map contract.
   - Activate special-region bonuses only at 80% control, sampled before draft resolution.
   - Factory: `+4` shots to the next volley.
   - Energy relay: `+1` projectile power for the next volley.
   - Lab: guarantee at least one uncommon-or-better option in the next three-choice draft.
   - Limit each region type to one active bonus per faction and remove the bonus when control is lost.
2. `v0.3.1b-orthographic-2_5d-arena-spike`
   - Use a real orthographic `Camera3D` over an XZ battlefield.
   - Mirror the existing 2D simulation into 3D tile, marble, turret, chamber, and effect presenters.
   - Validate one map end to end before expanding the catalog; keep the formal HUD in `CanvasLayer`.
3. `v0.3.1c-map-identity-expansion`
   - Add visibly distinct route structures, chamber approaches, and stronghold placements.
   - Keep chamber destruction, the six-upgrade pool, and stronghold bonus rules stable while comparing layouts.
4. `v0.3.2a-summon-rule-foundation`
   - Define allied and neutral summon ownership, movement, collision, targeting, and despawn rules.
   - Add chaos/summon content only after the rule layer is covered by native tests.

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
