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
- Current completed slice: `v0.3.0b-2.5d-arena-spike`
- Next slice: `v0.3.0c-three-choice-vertical-slice`
- Active branch: `main`

## Completed Slice / 已完成阶段

`v0.3.0b-2.5d-arena-spike` establishes the new player-bottom versus AI-top battlefield while preserving the existing 2D simulation.

Scope:

- Cardfront-only arena layout with a smaller, readable central battlefield.
- AI spawn and turret at the top; player spawn and turret at the bottom.
- Orthographic 2.5D floor, depth edges, lane rails, and faction accents over the unchanged 2D collision grid.
- Two command-chamber shells that display the real turret health instead of creating a second combat state.
- Player direction controller with a formal slider UI, `A` / `D`, and arrow-key input.
- A visible aim guide that does not cover the battlefield with UI.
- Manual player firing angle wired into `CardfrontFireDirector`; AI targeting remains automatic.
- Cardfront-only runtime references and BallWar isolation.
- Native Godot tests and a dedicated GitHub Actions batch.

Acceptance:

- The battlefield and direction UI remain inside `1120 x 720` without overlapping each other.
- The two active turrets share a center lane and face inward.
- Player aim is clamped to a readable `-60` to `+60` degree arc.
- The visible barrel, directed intent, and projectile angle use the same player-selected direction.
- AI does not inherit the player's manual angle.
- Cardfront creates two command-chamber views; legacy BallWar creates none of the new arena nodes.
- Existing card, map, effect, performance, Smoke, and Integration gates remain green.

Implementation result:

- Added `scripts/cardfront/arena/` for layout, presentation, command-chamber views, direction control, aim guide, and assembly.
- Added `CardfrontAimControl.tscn` as the formal direction UI.
- Added optional Battlefield cell-size override without changing BallWar defaults.
- Rotated the Cardfront ownership contract and default map spawn metadata from left-right to top-bottom.
- Added `CardfrontArenaLayoutTestRunner`, `CardfrontDirectionControllerTestRunner`, and `CardfrontArenaRuntimeTestRunner`.

The legacy fixed hand, resources, click-target cards, continuous firing cadence, and territory-percentage victory remain temporarily active. They are compatibility scaffolding for this spike, not the target product loop.

## Planned Slices / 后续阶段

1. `v0.3.0c-three-choice-vertical-slice`
   - Runtime pause integration.
   - Formal three-choice UI and timeout.
   - AI choice policy and revealed AI selection.
   - Automatic volley launch and command-chamber victory.
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
