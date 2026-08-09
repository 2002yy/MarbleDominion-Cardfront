# P0-00B Baseline Regression Capture

Status: **MANUALLY ACCEPTED WITH FOLLOW-UPS**
Decision: **GO (MANUAL PROGRESS ACCEPTANCE)**

## Step contract

```text
Step: P0-00B Baseline Regression Capture
Source commit: 616cce19b7fd9ac5d1ae07764ebe5302f81169e4
Parent audit commit: ece2ed374544d7a70b443d3ac374d1950d0a3d35
Original upstream source commit: fc56e21e0cf7ad8c79eaf9659afbda3e1f89e487
Target step: P0-00B
Evidence type: automated / rendered runtime / visual inspection
Evidence source: Godot 4.7.1-stable official console and repository test/capture runners
Allowed mutation surface: checkpoint evidence, engine/test authority configuration, non-gameplay tooling metadata
Forbidden changes: gameplay behavior, Support implementation, map changes, refactors, new rules, P0-01
Expected checkpoint: docs/cardfront_refactor_checkpoints/P0-00B_baseline.md
```

The user changed the machine and repository engine authority during this step from the old CI pin to Godot `4.7.1-stable`. Commit `2f2f754` contains that non-gameplay authority update, the official Godot MCP `1.9.0` editor addon, and the Godot 4.7 UID metadata. Commit `8ba5103` contains regression-fixture determinism and teardown fixes found by this audit. Commit `9faf518` makes the packaged runtime bridge Godot 4.7.1-compatible and enables it as debug-only audit tooling. Commit `87024a3` removes the 20 warnings observed during a real `Main.tscn` launch and fixes two test-only sources of nondeterminism/teardown leakage; it does not change gameplay authority. Commit `616cce1` stabilizes the two shared 3D atlas imports. The current evidence is bound to `616cce19b7fd9ac5d1ae07764ebe5302f81169e4`. Evidence collected against the earlier 4.6.2 pin is not used for this decision.

## 2026-08-09 manual acceptance amendment

The product owner accepted this baseline for continued development with the gaps below retained as explicit follow-ups. This is a progress decision, not a claim that every baseline item passed or that the game reached final quality. P0 work must use focused checks during implementation and defer full regression/manual matrices to batch, milestone, release-candidate, or explicitly requested acceptance points.

## Environment and repository evidence

- Engine: `Godot_v4.7.1-stable_win64_console.exe`.
- Engine version output: `4.7.1.stable.official.a13da4feb`.
- Rendering evidence used OpenGL Compatibility on NVIDIA GeForce RTX 5060 Laptop GPU.
- `project.godot` declares feature `4.7`.
- All four active workflows now download `Godot_v4.7.1-stable_win64.exe.zip`.
- Editor plugin: official npm package `@yanhuifair/godot-mcp@1.9.0`, enabled at `res://addons/godot-mcp/plugin.cfg`.
- Stable editor recheck after UID generation: exit `0`, warnings `0`, errors `0`; plugin loaded on `127.0.0.1:9876` and unloaded normally.
- Runtime bridge is registered as `godot_mcp_runtime`, listens only on loopback `127.0.0.1:9877`, and disables itself in non-debug exports.

### Godot MCP live-runtime probe

The first shared `godot_full` probe successfully launched the 4.7.1 editor and a visible `Main.tscn` process at 1280x720. It reached `[StartMenu] Loaded scene StartMenu.tscn`, but live inspection initially failed:

```text
runtime_screenshot -> RUNTIME_NOT_REACHABLE
connect ECONNREFUSED 127.0.0.1:9877
```

Audit remediation in `9faf518` renamed the handler that collided with Node's `_input(InputEvent) -> void`, added explicit `Node` return/local types, enabled the bridge autoload, and prevents its control port from opening in release exports. Godot 4.7.1 `--check-only` and a full editor load both report zero bridge parse errors.

The second real-process probe proves:

```text
[godot-mcp-runtime] Listening on 127.0.0.1:9877
runtime_ping: {"ok": true}
runtime_get_tree: Main, 309 live nodes
runtime_screenshot: success
runtime bridge parse errors: 0
```

The screenshot shows an active Cardfront battle with the two-lane/bridge arena, HUD, Rapid Gunner player at 36/36 and volley 7, Balanced Commander AI at 40/40 and volley 6, 20/20/60 control, and 07:58 remaining. This is live runtime evidence but not proof of the missing player-operated menu and phase chain.

The warning-remediation launch against `87024a3` reached the StartMenu with the runtime bridge listening and reported `warning_count=0` and `error_count=0`. The 20 GDScript warnings (unused parameters/signals, intentional integer division, and local/property shadowing) are therefore closed. The two intermittent `get_multiple_md5` file-access errors occurred while Godot auto-detected two shared atlases as 3D textures. Their import settings are now explicitly VRAM Compressed with mipmaps and a clean editor import no longer reproduces either the file-access errors or the two auto-detection notices. The absent continuous played-session log remains a manual follow-up.

## Rendered runtime capture

Command:

```text
Godot_v4.7.1-stable_win64_console.exe
  --audio-driver Dummy
  --path .
  --script res://scripts/tools/capture_cardfront_full_game.gd
```

Result against `2f2f754`:

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

Initial result against `2f2f754`:

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

At that point the checkpoint did not decide whether runtime tuning or test expectations were stale. Authority reconciliation was required before P0-00B could pass; gameplay was not changed to make the test green.

Exit-zero log debt observed in the same workflow:

- `CardfrontActionHintTestRunner.gd`: ObjectDB/resource leak warning/error at exit.
- `CardfrontBattlefieldClickSelectionTestRunner.gd`: ObjectDB/resource leak warning/error at exit.
- `CardfrontVfxLayerTestRunner.gd`: two warnings and one resource-leak error at exit.
- `DeviceOverlayLayerTestRunner.gd`: two warnings and one resource-leak error at exit.

Remediation audit found that `Main._ready()` loaded the developer's persisted Rapid Gunner preference while `CardfrontVerticalSliceFeedbackTestRunner.gd` assumed the frozen default Balanced Commander. The runner now pins both factions to the registry defaults, so its expected 40 health / 6 volley baseline is deterministic and still comes from the existing authority. No hero or gameplay value changed.

The exit-log failures were test teardown defects: standalone overlay/VFX nodes were never freed, and feedback tests freed fixtures while short WAV playbacks were still active. The affected tests now release those objects explicitly. `CardfrontBattlefieldClickSelectionTestRunner.gd` was clean after the CI-order import and required no source change.

Full rerun result on source commit `8ba5103`:

```text
98 runners: exit 0
0 runners: exit nonzero
0 runner logs: warning/error/resource/RID/ObjectDB leak
Headless regression: PASS
```

Targeted verbose confirmation:

| Runner | Result |
| --- | --- |
| `CardfrontVerticalSliceFeedbackTestRunner.gd` | PASS, 17 checks; exit 0 |
| `CardfrontActionHintTestRunner.gd` | PASS, 33 checks; clean exit |
| `CardfrontCardFeedbackTestRunner.gd` | PASS, 24 checks; clean exit |
| `CardfrontBattlefieldClickSelectionTestRunner.gd` | PASS, 16 checks; clean exit |
| `CardfrontVfxLayerTestRunner.gd` | PASS, 18 checks; clean exit |
| `DeviceOverlayLayerTestRunner.gd` | PASS, 29 checks; clean exit |

After the Godot 4.7.1 warning cleanup, all 98 active runners were executed again. All 98 exited `0`; 97 logs were clean. The only remaining log issue was an active short WAV playback retained by `CardfrontBattlefieldClickSelectionTestRunner.gd` during teardown. Commit `87024a3` stops its feedback players before fixture cleanup. A post-fix verbose rerun reports `PASS (16 checks)`, exit `0`, with no warning, error, leak, orphan, or resource-still-in-use output. The 12-runner cross-system subset was also rerun in CI import order and passed with clean logs.

Balance telemetry debt:

- `CardfrontHeroBalanceSimulationTestRunner.gd`: runner PASS after 54,000 historical matches, but its internal balance summary reports `passed=false`.
- `CardfrontParityBalanceAuditTestRunner.gd`: runner PASS after 54,000 parity matches, but `provisional_threshold_passed=false` with multiple aggregate and matchup threshold failures.

An earlier local trial deleted generated `.import` sidecars before running tests and produced false missing-resource failures. Asset existence was then verified in the worktree and Git index, the test was rerun in true CI order, and `CardfrontCardArtBindingTestRunner.gd` passed 37 checks. The invalid trial is excluded from the decision.

## Mandatory runtime audit table

| Required baseline | Evidence obtained | Status |
| --- | --- | --- |
| Game boot and enter duel | Main/Cardfront runtime rendered after direct `_start_game()`; menu-to-prematch player path not operated | **FOLLOW-UP** |
| Draft -> Aim -> Volley/Execution | Draft and battle states rendered separately; phase/round tests pass; no contiguous player-operated cycle | **FOLLOW-UP** |
| Command Point | Automated runtime tests cover the current system; no live visible gain/spend observation captured | **FOLLOW-UP** |
| Legacy Stronghold bonus | Stronghold rules and timeout runners pass; no live Factory/Energy/Lab trigger was observed in a played duel | **FOLLOW-UP** |
| 3/4-choice behavior | Three-choice rendered; automated 3/4-choice checks pass; no live Lab-driven four-choice capture | **FOLLOW-UP** |
| Peek bug | Source path known from P0-00A; no real pointer/peek reproduction recording | **FOLLOW-UP** |
| Creature normal action | Creature runners pass and entities rendered; capture helper directly spawned entities and did not prove a normal round action | **FOLLOW-UP** |
| Automatic/upgrade spawn | Entity runners pass; capture helper uses direct spawn APIs, not an earned automatic/upgrade spawn | **FOLLOW-UP** |
| Two-lane / bridge baseline | Actual rendered battle capture visibly contains both bridge/lane presentations | **PASS** |
| Loadout/Draft key show/hide | Draft visible and battle view visible in separate captures; Loadout and interactive hide/restore sequence absent | **FOLLOW-UP** |
| Warning/error/log baseline | Real Main boot now has 0 GDScript warnings and 0 errors; 98/98 active runners exit 0 and the remediated outlier has a clean verbose rerun. Explicit 3D atlas import settings eliminate the reproduced `get_multiple_md5`/auto-detection startup messages; the continuous played-session log remains incomplete | **FOLLOW-UP** |
| Performance observation | Rendering device recorded; no valid FPS/frame-time sampling was taken | **FOLLOW-UP** |

## Mandatory audit fields

```text
Mandatory audit gates touched: P0-00B Baseline Regression Capture
Audit status per gate: MANUALLY ACCEPTED WITH FOLLOW-UPS
Evidence bound to source commit: YES
Unverified assumptions remaining: none are treated as passed; missing runtime observations are non-blocking follow-ups listed below
Legacy authority still reachable: YES — expected baseline; live triggers still require capture
Second-authority risk: NOT APPLICABLE to this evidence-only step
Save/restore risk: P0-00A static risk remains; no new save/restore runtime evidence was captured
Cross-system regression evidence: PASS — 98/98 active headless runners exit 0; the sole teardown-log outlier was remediated and independently rerun clean
Manual evidence required before final quality acceptance: YES; not required before P0-00C progress
```

## Deferred manual acceptance follow-ups

Using Godot 4.7.1 and source commit `616cce19b7fd9ac5d1ae07764ebe5302f81169e4` (or a later explicit P0-00B remediation commit), record one continuous duel session with console output or video/screenshots that shows:

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

The previously nonzero `CardfrontVerticalSliceFeedbackTestRunner`, the 20 real-start GDScript warnings, all observed runner exit-log leaks, and the two atlas-related editor startup errors are reconciled. The ten played-session observations above remain follow-ups for later milestone/manual acceptance and do not block P0-00C.

## Findings

1. Godot 4.7.1 can parse, import, render Cardfront, load the MCP 1.9.0 editor plugin, and run the active test suite.
2. Rendered evidence confirms the two-lane/bridge presentation and the current three-choice Draft surface.
3. Automated coverage is substantial but cannot replace the mandatory player-operated runtime observations.
4. The active main headless workflow is 98/98 exit-zero; its sole post-warning-cleanup teardown-log outlier has a clean targeted verbose rerun after remediation.
5. Existing balance audits intentionally pass their runner contract while reporting material threshold debt; those values are baseline observations, not P0-00B acceptance.
6. The shared Godot MCP now launches and inspects the live game successfully on Godot 4.7.1; ping, a 309-node scene tree, and runtime screenshot are verified, with the control listener disabled for release exports.
7. A real `Main.tscn` launch now reaches StartMenu with zero GDScript warnings and zero runtime errors. The two shared 3D atlases now have stable VRAM/mipmap import settings, and a clean import does not reproduce the earlier `get_multiple_md5` errors or texture auto-detection notices.

## Decision

```text
MANUALLY ACCEPTED WITH FOLLOW-UPS
Decision: GO (MANUAL PROGRESS ACCEPTANCE)
```

This decision allows P0-00C to start. It does not mark unobserved items as passed and does not waive final batch/milestone acceptance.

The **only allowed next step** is P0-00C Frozen Delta Ledger. During implementation, run focused checks proportional to the current diff; defer the full regression/manual matrix to the next batch or milestone acceptance point unless the product owner explicitly requests it sooner. P0-01 remains gated by the rest of the P0-00 pre-implementation sequence.
