# P0-11B Parse / Import / Boot Gate

P0 RC source commit: `34ca4b518ec846b3f50e2988d288a83da74dd498`

Godot version: `4.7.1-stable.official.a13da4feb`

Decision: **GO**

Only allowed next step: **P0-11C - New Frozen Contract Suite**.

## Result

A detached, clean checkout of the final C/D source commit was created at `D:\CardfrontWorktrees\P0-11BCD-34ca4b5`. Its `.godot` cache did not exist before the run. The serialized-import correction had already been stress-checked in three independent cache-free checkouts on its introducing commit.

Final-RC evidence root: `D:\CardfrontEvidence\P0-11BCD-34ca4b5-20260813`

Serialized-import stress evidence root: `D:\CardfrontEvidence\P0-11B-serialized-import-085ed12-20260813`

| Run | Exit | PASS | FAIL | Errors | Warnings |
|---|---:|---:|---:|---:|---:|
| fresh official `--import` #1 (702 items) | 0 | 0 | 0 | 0 | 0 |
| fresh official `--import` #2 (702 items) | 0 | 0 | 0 | 0 | 0 |
| fresh official `--import` #3 (702 items) | 0 | 0 | 0 | 0 | 0 |
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

Dedicated `--import` removed the premature generic quit but remained nondeterministic under the machine's 16 GB memory limit: some clean runs imported 702/702 and then exited with the same native access violation. Disabling the Godot MCP editor plugin and Godot recovery mode did not eliminate the crash, so the plugin was rejected as the root cause and its diagnostic patch was reverted.

Godot documents `editor/import/use_multiple_threads` as the project setting controlling parallel resource imports. Commit `085ed12` sets it to `false`. Three independent cache-free imports then completed consecutively in 27.24, 27.44 and 27.16 seconds with zero errors/warnings and clean worktrees. This is slower than the unstable parallel run but bounds peak import pressure and only affects editor import. Commit `708c38a` also changed all four active workflows from `--editor ... --quit` to the dedicated `--import` mode. No gameplay source was changed. The formal boot evidence above was regenerated after both corrections, so pre-fix evidence is not used for GO.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-11B parse/import/boot
Audit status: PASS
Evidence bound to source commit: YES - 34ca4b518ec846b3f50e2988d288a83da74dd498
Clean detached checkout: YES - three independent checkouts
Fresh Godot cache: YES - three independent caches
Godot 4.7.1 dedicated serialized project import: PASS - 3/3 at 702/702, exit 0
Main scene boot: PASS
Cardfront mode boot: PASS
Base scenes instantiated: PASS
Parser/missing resource/preload errors: 0
Formal log warnings/errors: 0/0
Gameplay changed by gate repair: NO
```
