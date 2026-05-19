# README v1.9.35

## Goal

This pass prioritized stabilization over new features:

1. Fix parser and string-corruption risks first.
2. Keep the event roulette integration from breaking startup.
3. Verify Godot can at least open the project cleanly in editor mode.
4. Defer broader UI polish and feature expansion until runtime stability is confirmed.

## Files repaired or cleaned

- `scripts/GameConfig.gd`
  - Rewritten into a clean, valid UTF-8 script.
  - Restored stable constants and helper APIs used across the project.
  - Tuned pressure thresholds and trail point budgets downward for better large-burst performance.
- `scripts/RuntimeHudController.gd`
  - Rewritten to remove broken string literals and malformed HUD text.
- `scripts/GameHudView.gd`
  - Rewritten to remove corrupted UI strings and broken button text.
  - Preserved event HUD wiring and add-ball button integration.
- `scripts/StartMenuView.gd`
  - Rewritten to remove corrupted menu strings and malformed literals.
- `scripts/EventRouletteController.gd`
  - Fixed `_roll_effect_sequence()` so all code paths return a value.
- `scripts/Main.gd`
  - Added a safe guard for `DisplayServer.get_name() == "headless"` in `_detect_mobile_layout()`.
  - Removed temporary debug probes after isolation work.
  - Kept the existing `selected_palette_name == "默认随机"` branch intact.
  - Kept event roulette creation flow intact.
- `scripts/SaveGameCodec.gd`
  - Added `event_state` validation defaults.
- `scripts/ControlChamber.gd`
  - Restored gate text drawing so the bottom exits are no longer just color blocks.
  - Current stabilization-first labels are `x2/x3`, `FIRE`, and `JAM`.
- `scripts/BulletPool.gd`
  - Added FPS-aware visual degradation so trails simplify earlier when the game is already under load.
  - Reduced visual-pressure update frequency slightly to avoid unnecessary per-frame reconfiguration churn.
- `scripts/Bullet.gd`
  - Reduced trail sampling density under pressure.
- `scripts/BulletTrailLayer.gd`
  - Reduced trail redraw frequency.
  - Draws fewer trail segments/circles for reduced-effect trails and long trails.
- `scripts/Turret.gd`
  - Made low-FPS burst throttling more aggressive so heavy queue states back off sooner.
- `scripts/tests/SmokeTestRunner.gd`
  - Added a reusable smoke-test entry script for save compatibility, event timing, chamber event rules, and turret burst cancellation.

## Script scan results

The `scripts/` directory was scanned for:

- duplicate `class_name`
- missing `load()` / `preload()` targets
- temporary test-script references
- obvious quote-balance issues

Current results:

- no duplicate `class_name`
- no broken script load targets found in `scripts/`
- temporary smoke-test script removed
- `EventRouletteView.gd` exists as a single final file
- no obvious odd-quote / half-string parse damage in the high-risk script set

## Godot checks

### Editor mode

Command used:

```cmd
"E:\Godot\Godot_\Godot_console.exe" --editor --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --quit-after 5 --verbose
```

Result:

- project scripts and main scene can be scanned by Godot editor mode
- no remaining `EventRouletteController.gd` parse error
- editor mode exits normally in this Codex environment

Known environment-side errors still printed during editor mode:

- Godot cannot create some `AppData\Roaming\Godot` / `AppData\Local\Godot` files in the current Codex sandboxed environment
- this affects editor cache/help/preview saving, but not project script parsing

### Run mode / headless mode

Commands tested:

```cmd
"E:\Godot\Godot_\Godot_console.exe" --headless --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --quit
"E:\Godot\Godot_\Godot_console.exe" --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --quit-after 1
"E:\Godot\Godot_\Godot_console.exe" --headless --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --script "res://scripts/tests/SmokeTestRunner.gd"
```

Result in the current Codex environment:

- both still crash with a native access violation before normal gameplay logs begin
- the dedicated smoke-test runner also hits the same native crash in headless mode inside Codex before GDScript-level results can be collected
- a blank temporary smoke scene reproduced the same crash in this environment during isolation
- `Godot.exe --path <project>` also exited with code `1` within a few seconds in this Codex environment

Interpretation:

- the remaining `run mode` crash observed inside Codex is not isolated to the event roulette system or the main gameplay scene alone
- editor-mode parsing is now much cleaner than before
- runtime verification still needs to be confirmed from the normal desktop environment outside the Codex runtime constraints

### Editor open check

Command used:

```cmd
"E:\Godot\Godot_\Godot.exe" --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar"
```

Observed from Codex-side process check:

- process did not remain alive after 8 seconds
- exit code reported as `1`
- this differs from the console editor-mode `--editor --quit-after 5` result, which still loads the project content successfully

## Event roulette status

- Controller/View split remains in place.
- `Main.gd` still creates both `EventRouletteController` and `EventRouletteView`.
- `ControlChamber.gd`, `Turret.gd`, and save-state wiring remain connected.
- This pass did not add new event features.
- `EventRouletteController.gd` parse blocker from `_roll_effect_sequence()` was fixed.

## Test runner

Dedicated smoke-test code now exists at:

- `scripts/tests/SmokeTestRunner.gd`

Coverage focus:

- save compatibility defaults
- event roulette interval logic and weighting helpers
- chamber event handling basics
- turret `cancel_burst()` behavior

Recommended local run command on the desktop machine:

```cmd
"E:\Godot\Godot_\Godot_console.exe" --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --script "res://scripts/tests/SmokeTestRunner.gd"
```

Note:

- in the Codex sandbox this still trips the same headless/runtime native crash
- on the user desktop this should be treated as the next verification path because manual in-editor gameplay already appears healthier than Codex headless mode

## Performance pass

This pass did not change gameplay rules. It only tightens visual/performance fallback behavior:

- trails degrade earlier at medium/high pressure
- low FPS now forces more aggressive bullet visual simplification
- trail redraw cadence is slower under load
- reduced trails skip part of the segment/circle work
- burst firing backs off more aggressively when FPS is already collapsing

User desktop testing has already shown the basic mode appearing functionally normal after the stabilization work, so this performance pass is intentionally conservative.

## Remaining risks

1. Runtime crash still occurs in Codex `run mode`, even when project content is reduced.
2. Chinese UI has only been partially normalized in core scripts. A dedicated text pass is still needed later.
3. Full gameplay acceptance for:
   - chamber lock/jam interaction
   - roulette animation timing
   - save/load continuation with active event state
   still needs desktop runtime verification after the remaining crash source is ruled out.
4. Control chamber bottom labels are restored visually, but final localized wording still needs a later pass after runtime stability is confirmed.
