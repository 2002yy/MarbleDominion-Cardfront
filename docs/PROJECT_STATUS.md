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
- The final presentation may replace the current flat 2D battlefield, fixed hand, HUD, card art, and camera.

## Version / 版本

- Stable baseline: `v0.2.5.7-ui-copy-readability-pass`
- Baseline commit: `9eadf9b`
- Core-loop foundation commit: `bef12ce`
- Current completed slice: `v0.3.0c-three-choice-vertical-slice`
- Next slice: `v0.3.0d-vertical-slice-playtest-closeout`
- Active branch: `main`

## Completed Slice / 已完成阶段

`v0.3.0c-three-choice-vertical-slice` establishes the first playable version of the new direction, draft, and automatic-volley loop.

Scope:

- Four-second opening countdown followed by an eight-second upgrade interval.
- Full simulation pause during an eight-second three-choice draft, while the draft timeout continues in real time.
- Three formal text-first upgrade cards with hover and press feedback.
- Timeout fallback that selects from the three visible offers.
- AI upgrade selection, lock-in, and reveal.
- Six manifest upgrades wired through the run-state resolver.
- Next-volley `+5` and `x2`, plus permanent projectile power, defense-cap, rarity, and mirror state.
- Player manual direction and AI automatic targeting resolved into simultaneous automatic volleys.
- Command-chamber destruction as the immediate primary victory condition.
- Legacy fixed-hand and resource-minibar UI hidden in the live Cardfront loop.
- Native Godot tests and a dedicated GitHub Actions batch.

Acceptance:

- Exactly three upgrade cards are visible during each draft.
- A real card click and the timeout fallback both lock a valid visible offer.
- AI choice locks before reveal and is shown alongside the player choice.
- The simulation resumes before both directed bursts are issued.
- Projectile-power upgrades propagate to real bullets and multiply turret damage.
- Territory dominance alone no longer ends a Cardfront match.
- Destroying the enemy command chamber ends the match immediately.
- Legacy BallWar creates none of the new round-director or three-choice UI nodes.
- Existing card, map, effect, performance, Smoke, and Integration gates remain green.

Implementation result:

- Added `CardfrontRoundDirector` and `CardfrontAiUpgradePolicy` for countdown, pause, draft, reveal, and volley orchestration.
- Added `CardfrontThreeChoicePanel.tscn` and `CardfrontUpgradeChoiceCard.tscn` as formal runtime UI.
- Added one-shot volley issuing to `CardfrontFireDirector` without restoring the legacy continuous Cardfront cadence.
- Propagated projectile power through fire intent, turret burst state, bullets, and save snapshots.
- Updated Cardfront victory evaluation and player-facing copy around command-chamber destruction.
- Added `CardfrontThreeChoiceRuntimeTestRunner` and `CardfrontRoundCombatTestRunner`.

Legacy fixed-card systems are still instantiated for compatibility coverage, but their hand UI, resource UI, click-target flow, and continuous firing cadence are disabled in the live Cardfront path. The permanent defense-cap value is stored correctly but is not yet bound to a visible battlefield defense rule.

## Planned Slices / 后续阶段

1. `v0.3.0d-vertical-slice-playtest-closeout`
   - Bind territory defense cap to a visible battlefield defense rule.
   - Tune countdown, volley cadence, command-chamber health, and projectile pressure from playtests.
   - Improve command-chamber hit and upgrade-application feedback.
   - Remove remaining legacy fixed-card runtime construction from the default Cardfront path.
2. `v0.3.1-map-and-summon`
   - Distinct map mechanics.
   - Chaos effects.
   - Allied and neutral summoned creatures.

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
