# P0-09A4 Echo Contract

Source commit: `df71e45f70e248aa3757ed5a3aede32806a9a340`

Decision: **GO**

Only allowed next step: **P0-09A5-A6 — Eligibility cap and rarity semantic separation**.

## Audit result

The existing three-round Echo behavior is now independently executable and locked:

```text
Round N: select Echo
Round N+1: select +5 volley; queue it for Echo
Round N+2: Echo automatically replays +5 while attack training is selected
```

- selecting Echo gives Echo itself one Selected Level and one effect application;
- selecting +5 gives +5 one Selected Level and one effect application;
- automatic +5 replay raises its effect application count to two but leaves its Selected Level at one;
- the different real selection in Round N+2 receives its own one Selected Level and one effect application;
- the Echo queue is consumed after replay;
- no Echo gameplay timing, effect, numeric value, eligibility, or Draft cadence changed.

`CardfrontEchoLevelContractTestRunner.gd` is included in the Cardfront v0.3 core-loop CI batch. The previous P0-08B, P0-08C, and P0-09A0-A3 checkpoint source SHAs were rebound after the clean rebase onto art baseline `ea934a5`.

## Evidence

- focused Echo Level contract — **PASS (16 checks)**;
- upgrade resolver regression — **PASS (31 checks)**;
- upgrade content regression — **PASS (115 checks)**;
- selectable deck regression — **PASS (1,023 checks)**;
- Draft lifecycle regression — **PASS (170 checks)**;
- formal three-choice runtime — **PASS (59 checks)**.

P0/Draft total: **1,414 passed** under Godot `4.7.1-stable`.

Post-rebase art compatibility was also checked after generating the worktree-local import cache:

- environment asset registry/runtime — **PASS (132 checks)**;
- orthographic arena — **PASS (61 checks)**.

The arena test emits three existing `PowerCore` child-owner consistency warnings from the new interceptor GLB path. They do not affect the Echo gate and are not claimed as resolved here.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-09A4 Echo Contract
Audit status: PASS
Evidence bound to source commit: YES — df71e45f70e248aa3757ed5a3aede32806a9a340
Echo selection increments Echo Level: YES — once
Copied real selection increments copied Level: YES — once
Echo replay increments copied application count: YES
Echo replay increments copied Selected Level: NO
Simultaneous different real selection increments its Level: YES — once
Echo queue consumed after replay: YES
Echo timing/effect changed: NO
Eligibility/rarity/cadence changed: NO
Gameplay expanded: NO
Manual/video evidence required before GO: NO
```
