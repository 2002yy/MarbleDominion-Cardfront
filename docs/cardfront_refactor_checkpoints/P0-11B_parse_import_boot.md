# P0-11B Parse / Import / Boot Gate

Source commit: `708c38aa8d83f92a2c497c46aabd8c6427a82ca9`

Godot version: `4.7.1-stable.official.a13da4feb`

Decision: **GO**

Only allowed next step: **P0-11C - New Frozen Contract Suite**.

## Result

A detached, clean checkout of the source commit was created at `D:\CardfrontWorktrees\P0-11B-708c38a`. Its `.godot` cache did not exist before the run.

Evidence root: `D:\CardfrontEvidence\P0-11B-708c38a-20260813-203114`

| Run | Exit | PASS | FAIL | Errors | Warnings |
|---|---:|---:|---:|---:|---:|
| fresh official `--import` (702 items) | 0 | 0 | 0 | 0 | 0 |
| main scene boot, 10 frames | 0 | 0 | 0 | 0 | 0 |
| `CardfrontModeSmokeTestRunner.gd` | 0 | 38 | 0 | 0 | 0 |
| `StartMenuSceneTestRunner.gd` | 0 | 55 | 0 | 0 | 0 |
| `CardfrontArenaRuntimeTestRunner.gd` | 0 | 24 | 0 | 0 | 0 |

The three runner PASS counts above are taken from their runner summaries; the machine-readable evidence collector counted hard failures/errors and process exits. The detached worktree remained clean after import and execution.

No parser error, missing resource, failed preload, script error, engine error, or warning was found in the formal logs.

## Import failure found and fixed during this gate

The first clean-checkout diagnostic used the generic editor command retained by all four CI workflows:

```text
godot --headless --editor --path <clean checkout> --quit
```

It imported all 702 resources and printed `[Godot MCP] Plugin unloaded`, then exited with Windows access violation `0xC0000005` (`-1073741819`). Windows Application Error event 1000 and WER event 1001 corroborated the native crash. A second run against the already-created cache exited 0.

The same source commit was then imported from another cache-free checkout with Godot's dedicated `--import` mode. It imported 702/702 resources, unloaded the enabled editor plugin, and exited 0. This isolates the failure to the generic fresh-import-plus-immediate-editor-quit path rather than GDScript/resource validity.

Commit `708c38a` therefore changed all four active workflows from `--editor ... --quit` to the dedicated `--import` mode. This is an import/CI reliability correction only; no gameplay source was changed. The formal evidence above was regenerated after that correction, so pre-fix evidence is not used for GO.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-11B parse/import/boot
Audit status: PASS
Evidence bound to source commit: YES - 708c38aa8d83f92a2c497c46aabd8c6427a82ca9
Clean detached checkout: YES
Fresh Godot cache: YES
Godot 4.7.1 dedicated project import: PASS - 702/702, exit 0
Main scene boot: PASS
Cardfront mode boot: PASS
Base scenes instantiated: PASS
Parser/missing resource/preload errors: 0
Formal log warnings/errors: 0/0
Gameplay changed by gate repair: NO
```
