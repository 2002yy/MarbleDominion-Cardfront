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
- Current completed slice: `v0.3.1a-tactical-stronghold-contract`
- Next slice: `v0.3.1b-orthographic-2_5d-arena-spike`
- Active branch: `main`

## Completed Slice / 已完成阶段

`v0.3.1a-tactical-stronghold-contract` turns the three special region identities into explicit, readable tactical objectives for the current draft-and-volley loop.

Scope:

- Special regions activate only when one duel faction controls at least 80% of the region at draft-open sampling time.
- Factory grants `+4` shots to the following volley.
- Energy relay grants `+1` projectile power to the following volley.
- Lab guarantees at least one uncommon-or-better option in that three-choice offer.
- A faction can receive each stronghold type only once, even when it controls two regions of the same type.
- Losing control removes the bonus at the next draft sample.
- Map metadata now declares command-chamber destruction and the tactical stronghold ruleset instead of retired resource/card-pool/capture-victory fields.
- AI target scoring now names and evaluates tactical strongholds explicitly; enemy stronghold priority starts at the same 80% activation threshold.
- Region badges, the right-side region panel, the battle status panel, and the draft explanation expose active bonuses directly.
- The stronghold runtime exists only in live Cardfront; BallWar and the explicit legacy-compatibility assembly remain isolated.

Acceptance:

- 79% control grants no stronghold bonus; 80% control does.
- Two factories still grant only one `+4` shot bonus.
- Lab visibly changes the current offer and never reduces it below three unique choices.
- Factory and Energy contributions are recorded separately in the real `CardfrontVolleyPlan`.
- Stronghold shot bonuses respect the 512-shot safety limit.
- Losing a region before the next draft removes its sampled bonus.
- The player can see both the 80% requirement and the concrete effect without consulting documentation.
- Existing three-choice, fire, region, live-runtime, BallWar, Smoke, and Integration behavior remains covered.

Implementation result:

- Added `CardfrontStrongholdRules` and `CardfrontStrongholdSystem`.
- Extended draft selection with an optional uncommon-or-better guarantee.
- Extended volley plans with explicit stronghold shot and projectile-power contributions.
- Added stronghold sampling to `CardfrontRoundDirector` without moving region logic into the director.
- Updated map definitions, target-scoring reasons, region badges, region details, and battle/draft feedback.
- Added `CardfrontStrongholdSystemTestRunner` and a dedicated GitHub Actions batch.

Known transition boundaries:

- The arena floor is still drawn by `Node2D`; its trapezoid is only a perspective cue, not an orthographic 2.5D camera.
- Stronghold sampling is intentionally round-based, so control changes during a volley take effect when the next draft opens.
- The three registered map definitions share one stronghold ruleset; their route geometry and visual identity remain a later slice.

## Planned Slices / 后续阶段

1. `v0.3.1b-orthographic-2_5d-arena-spike`
   - Use a real orthographic `Camera3D` over an XZ battlefield.
   - Mirror the existing 2D simulation into 3D tile, marble, turret, chamber, and effect presenters.
   - Validate one map end to end before expanding the catalog; keep the formal HUD in `CanvasLayer`.
2. `v0.3.1c-map-identity-expansion`
   - Add visibly distinct route structures, chamber approaches, and stronghold placements.
   - Keep chamber destruction, the six-upgrade pool, and stronghold bonus rules stable while comparing layouts.
3. `v0.3.2a-summon-rule-foundation`
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
