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
- Current completed slice: `v0.3.0a-core-loop-contract`
- Next slice: `v0.3.0b-2.5d-arena-spike`
- Active branch: `main`

## Completed Slice / 已完成阶段

`v0.3.0a-core-loop-contract` builds the new rules as isolated, testable logic without changing the currently playable Cardfront scene.

Scope:

- Match phase contract: battle countdown, paused draft, resolve, launch.
- Per-faction run state.
- Six initial text-and-symbol upgrades.
- Deterministic three-choice generation with rarity weighting.
- Random timeout fallback.
- Upgrade resolution, including mirror.
- Volley plan resolution and one-shot modifier consumption.
- Native Godot tests and GitHub Actions coverage.

Acceptance:

- A draft always returns three unique valid upgrades.
- The same seed and state produce the same offer.
- Timeout can resolve a valid offered upgrade.
- Permanent upgrades remain after a volley.
- `+5` and `x2` are consumed by one volley.
- Mirror doubles the next selected upgrade once.
- Match phases cannot skip required choices.
- Existing Cardfront and BallWar runtime behavior remains unchanged.

Implementation result:

- Added isolated `run/`, `draft/`, and `volley/` logic.
- Added six text-and-symbol upgrade definitions with no generated card-art dependency.
- Added dead-choice filtering for capped rarity and an already-armed mirror.
- Added three native runners to the dedicated `Cardfront v0.3 core loop` CI batch.
- Local Godot 4.6.2 parse, new foundation tests, Cardfront regressions, Smoke, and Integration pass.

The initial `10`-shot volley, `12`-second battle interval, `8`-second draft timeout, rarity weights, and `512`-shot safety cap are provisional contract defaults, not final balance.

## Planned Slices / 后续阶段

1. `v0.3.0b-2.5d-arena-spike`
   - Player at the bottom, AI at the top.
   - Orthographic 2.5D presentation over a 2D simulation contract.
   - Two command chambers, one readable large-block map, and direction control.
2. `v0.3.0c-three-choice-vertical-slice`
   - Runtime pause integration.
   - Formal three-choice UI and timeout.
   - AI choice policy and revealed AI selection.
   - Automatic volley launch and command-chamber victory.
3. `v0.3.1-map-and-summon`
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
