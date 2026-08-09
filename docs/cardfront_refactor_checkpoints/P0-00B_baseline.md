# P0-00B Baseline Regression Capture

Status: **BLOCKED / AUDIT REQUIRED**
Decision: **NO-GO**

## Step contract

```text
Step: P0-00B Baseline Regression Capture
Source commit: 2f2f754e559a66d3b94fb8adf573128bd2c323d3
Parent audit commit: ece2ed374544d7a70b443d3ac374d1950d0a3d35
Original upstream source commit: fc56e21e0cf7ad8c79eaf9659afbda3e1f89e487
Target step: P0-00B
Evidence type: automated / rendered runtime / visual inspection
Evidence source: Godot 4.7.1-stable official console and repository test/capture runners
Allowed mutation surface: checkpoint evidence, engine/test authority configuration, non-gameplay tooling metadata
Forbidden changes: gameplay behavior, Support implementation, map changes, refactors, new rules, P0-01
Expected checkpoint: docs/cardfront_refactor_checkpoints/P0-00B_baseline.md
```

The user changed the machine and repository engine authority during this step from the old CI pin to Godot `4.7.1-stable`. Commit `2f2f754` contains that non-gameplay authority update, the official Godot MCP `1.9.0` editor addon, and the Godot 4.7 UID metadata required for a warning-free source scan. All evidence below is bound to that commit. Evidence collected against the earlier 4.6.2 pin is not used for this decision.

## Environment and repository evidence

- Engine: `Godot_v4.7.1-stable_win64_console.exe`.
- Engine version output: `4.7.1.stable.official.a13da4feb`.
- Rendering evidence used OpenGL Compatibility on NVIDIA GeForce RTX 5060 Laptop GPU.
- `project.godot` declares feature `4.7`.
- All four active workflows now download `Godot_v4.7.1-stable_win64.exe.zip`.
- Editor plugin: official npm package `@yanhuifair/godot-mcp@1.9.0`, enabled at `res://addons/godot-mcp/plugin.cfg`.
- Stable editor recheck after UID generation: exit `0`, warnings `0`, errors `0`; plugin loaded on `127.0.0.1:9876` and unloaded normally.
- Runtime bridge script is present but is **not** registered as an autoload. P0-00B did not add a live-game node or listener to gameplay runtime.

## Rendered runtime capture

Command:

```text
Godot_v4.7.1-stable_win64_console.exe
  --audio-driver Dummy
  --path .
  --script res://scripts/tools/capture_cardfront_full_game.gd
```

Result:

```text
exit=0
warnings=0
errors=0
StartMenu.tscn loaded
SettingsPanel.tscn loaded
CardfrontHUD.tscn loaded
```

Generated evidence:

- `cardfront-full-battle-40x60.png`: actual rendered arena, both chambers, two bridge/lane presentations, HUD, populated entities and projectile previews.
- `cardfront-full-draft-40x60.png`: actual rendered paused Draft overlay with three player choices and AI selection locked.
- Three presentation-scale captures at 100%, 112% and 120% also completed.

The capture helper calls `Main._start_game()` directly, directly populates several entities, directly fires preview projectiles, and calls `force_open_draft_for_test()`. It therefore proves scene/runtime/render/UI instantiation, but **does not** prove the full player-operated StartMenu -> prematch -> duel -> Draft -> Aim -> Execution chain or automatic spawn behavior.

## Automated evidence

### Targeted baseline runners

Thirteen targeted runners completed with exit `0`, no warning and no error:

| Runner | Result |
| --- | --- |
| `SmokeTestRunner.gd` | PASS, 215 checks |
| `IntegrationTestRunner.gd` | PASS, 133 checks |
| `CardfrontModeSmokeTestRunner.gd` | PASS, 38 checks |
| `CardfrontThreeChoiceRuntimeTestRunner.gd` | PASS, 59 checks |
| `CardfrontRoundCombatTestRunner.gd` | PASS, 19 checks |
| `CardfrontStrongholdSystemTestRunner.gd` | PASS, 17 checks |
| `CardfrontStrongholdTimeoutScoringTestRunner.gd` | PASS, 16 checks |
| `CardfrontGateConnectivityTestRunner.gd` | PASS, 22 checks |
| `CardfrontGateRuntimeTestRunner.gd` | PASS, 12 checks |
| `CardfrontEntityRuntimeBoundaryTestRunner.gd` | PASS, 19 checks |
| `CardfrontArmoredGuardTestRunner.gd` | PASS, 20 checks |
| `CardfrontNeutralCreatureTestRunner.gd` | PASS, 30 checks |
| `CardfrontRuntimeSnapshotTestRunner.gd` | PASS, 37 checks |

These prove the relevant code paths under a real Godot process. They are not a substitute for the required contiguous runtime/manual evidence.

### Active `headless-tests.yml` regression

The CI-order run performed editor import first and retained generated `.import` sidecars while executing all 98 unique runners in the active main workflow. Heavy balance runners were executed individually because a combined local tool batch exceeded 180 seconds.

Result:

```text
97 runners: exit 0
1 runner: exit 1
Headless regression: FAIL
```

Blocking runner:

```text
CardfrontVerticalSliceFeedbackTestRunner.gd
exit=1
player chamber start: expected 40, actual 36
player chamber after damage: expected 37, actual 33
base volley projectile count: expected 6, actual 7
```

The checkpoint does not decide whether the runtime tuning or the test expectations are stale. That authority reconciliation is required before P0-00B can pass; gameplay was not changed to make the test green.

Exit-zero log debt observed in the same workflow:

- `CardfrontActionHintTestRunner.gd`: ObjectDB/resource leak warning/error at exit.
- `CardfrontBattlefieldClickSelectionTestRunner.gd`: ObjectDB/resource leak warning/error at exit.
- `CardfrontVfxLayerTestRunner.gd`: two warnings and one resource-leak error at exit.
- `DeviceOverlayLayerTestRunner.gd`: two warnings and one resource-leak error at exit.

Balance telemetry debt:

- `CardfrontHeroBalanceSimulationTestRunner.gd`: runner PASS after 54,000 historical matches, but its internal balance summary reports `passed=false`.
- `CardfrontParityBalanceAuditTestRunner.gd`: runner PASS after 54,000 parity matches, but `provisional_threshold_passed=false` with multiple aggregate and matchup threshold failures.

An earlier local trial deleted generated `.import` sidecars before running tests and produced false missing-resource failures. Asset existence was then verified in the worktree and Git index, the test was rerun in true CI order, and `CardfrontCardArtBindingTestRunner.gd` passed 37 checks. The invalid trial is excluded from the decision.

## Mandatory runtime audit table

| Required baseline | Evidence obtained | Status |
| --- | --- | --- |
| Game boot and enter duel | Main/Cardfront runtime rendered after direct `_start_game()`; menu-to-prematch player path not operated | **BLOCKED** |
| Draft -> Aim -> Volley/Execution | Draft and battle states rendered separately; phase/round tests pass; no contiguous player-operated cycle | **BLOCKED** |
| Command Point | Automated runtime tests cover the current system; no live visible gain/spend observation captured | **BLOCKED** |
| Legacy Stronghold bonus | Stronghold rules and timeout runners pass; no live Factory/Energy/Lab trigger was observed in a played duel | **BLOCKED** |
| 3/4-choice behavior | Three-choice rendered; automated 3/4-choice checks pass; no live Lab-driven four-choice capture | **BLOCKED** |
| Peek bug | Source path known from P0-00A; no real pointer/peek reproduction recording | **BLOCKED** |
| Creature normal action | Creature runners pass and entities rendered; capture helper directly spawned entities and did not prove a normal round action | **BLOCKED** |
| Automatic/upgrade spawn | Entity runners pass; capture helper uses direct spawn APIs, not an earned automatic/upgrade spawn | **BLOCKED** |
| Two-lane / bridge baseline | Actual rendered battle capture visibly contains both bridge/lane presentations | **PASS** |
| Loadout/Draft key show/hide | Draft visible and battle view visible in separate captures; Loadout and interactive hide/restore sequence absent | **BLOCKED** |
| Warning/error/log baseline | Runtime capture is clean; editor is clean after UID import; main headless workflow has one nonzero regression and exit-zero leak logs | **FAIL** |
| Performance observation | Rendering device recorded; no valid FPS/frame-time sampling was taken | **BLOCKED** |

## Mandatory audit fields

```text
Mandatory audit gates touched: P0-00B Baseline Regression Capture
Audit status per gate: FAIL / BLOCKED
Evidence bound to source commit: YES
Unverified assumptions remaining: none are treated as passed; missing runtime observations are listed below
Legacy authority still reachable: YES — expected baseline; live triggers still require capture
Second-authority risk: NOT APPLICABLE to this evidence-only step
Save/restore risk: P0-00A static risk remains; no new save/restore runtime evidence was captured
Cross-system regression evidence: FAIL — CardfrontVerticalSliceFeedbackTestRunner exit 1
Manual evidence required before GO: YES
```

## Manual evidence required before GO

Using Godot 4.7.1 and this exact source commit (or a later explicit P0-00B remediation commit), record one continuous duel session with console output or video/screenshots that shows:

1. StartMenu -> Cardfront -> prematch Loadout/map/hero -> confirmed duel entry.
2. A complete Draft -> Aim -> Volley/Execution cycle, including the related UI show/hide transitions.
3. Command Point visible before and after a real gain/spend event.
4. A real old Factory or Energy Stronghold bonus affecting a volley, and a Lab activation producing four choices; also capture the normal three-choice case.
5. The current peek behavior/bug reproduction and restoration.
6. At least one normal Creature action caused by round progression rather than a direct debug spawn call.
7. At least one automatic or upgrade-earned spawn, including its selected cell and fallback behavior if applicable.
8. Both bridge/lane behaviors during real volley execution.
9. Loadout and Draft UI visibility transitions with no stuck overlay.
10. FPS/frame-time observation and the complete warning/error/log output for the session.

Before those observations can support GO, the nonzero `CardfrontVerticalSliceFeedbackTestRunner` result must also be reconciled against the current frozen authority and rerun successfully. The exit-zero resource leak logs must be either fixed or explicitly accepted by the applicable test/log gate; they are not silently waived here.

## Findings

1. Godot 4.7.1 can parse, import, render Cardfront, load the MCP 1.9.0 editor plugin, and run the active test suite.
2. Rendered evidence confirms the two-lane/bridge presentation and the current three-choice Draft surface.
3. Automated coverage is substantial but cannot replace the mandatory player-operated runtime observations.
4. The active main headless workflow currently contains a real nonzero regression in vertical-slice expectations.
5. Existing balance audits intentionally pass their runner contract while reporting material threshold debt; those values are baseline observations, not P0-00B acceptance.

## Decision

```text
AUDIT REQUIRED
BLOCKED
Decision: NO-GO
```

P0-00C and P0-01 are forbidden from this state.

The **only allowed next step** is P0-00B remediation and completion on one source commit: reconcile the failing headless authority without changing gameplay merely to satisfy the test, rerun the affected regression, and collect every missing manual runtime observation above.
