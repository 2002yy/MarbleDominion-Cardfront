# P0-00D Test Harness Truth

Source commit: `0b9aa92b7366591b51cd30fc76e6dd74d49f4546`
Target step: P0-00D Test Harness Truth
Evidence type: static + existing automated baseline
Evidence source: active test tree, active GitHub workflows, and P0-00B headless evidence
Decision: PASS

## Active authority

- Active local authority is `scripts/tests/*.gd`. At the source commit there are 117 `*TestRunner.gd` files and all 117 extend `SceneTree`.
- Active workflow authority is:
  - `.github/workflows/headless-tests.yml`
  - `.github/workflows/b1-simulation-tests.yml`
  - `.github/workflows/battlefield-entity-foundation-tests.yml`
  - `.github/workflows/shared-upgrade-ai-tests.yml`
- `tests_legacy_disabled/` is historical reference only. Its runnable-looking scripts use the `.gd.disabled` suffix and are not an active test source.
- No external or hidden runner was identified as required to interpret repository test results.

## Reproducible command and exit truth

The active Godot command shape is:

```powershell
D:\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe --headless --audio-driver Dummy --path . --script res://scripts/tests/<TestRunner.gd>
```

Each active runner owns a `TestAssert` instance, reports accumulated failures, and exits with status 1 when failures are present and status 0 when they are absent. The workflows additionally propagate the Godot process exit code.

P0-00B recorded a real 98-runner active matrix at its bound commit: 98/98 exited zero. That evidence remains historical baseline evidence; it is not relabelled as a fresh full regression for this source commit.

## Zero-test result

Audit found one harness hole: the main matrix loop could complete successfully if a matrix entry resolved to no script names. The workflow now throws before creating artifacts or entering the loop when `$scripts.Count -eq 0`. This is test-tooling only and changes no gameplay.

The individual runner count is also explicit in this checkpoint. A future full-suite claim must record a non-zero discovered or enumerated count; an empty batch cannot be reported as PASS.

## P0 evidence boundary

A new P0 runner may prove its own focused contract, but cannot by itself certify cross-system or final P0 regression. Full regression remains a batch, milestone, release-candidate, or explicitly requested audit activity under the current manual-acceptance cadence.

## Mandatory audit fields

```text
Mandatory audit gates touched: P0-00D Test Harness Truth
Audit status per gate: PASS
Evidence bound to source commit: YES
Unverified assumptions remaining: None for test authority, command shape, and exit semantics. No fresh full-suite execution is claimed.
Legacy authority still reachable: tests_legacy_disabled remains readable historical material only.
Second-authority risk: Controlled; active scripts and four workflows are enumerated.
Save/restore risk: NOT APPLICABLE
Cross-system regression evidence: P0-00B historical 98/98 baseline; not rerun for this docs/tooling change.
Manual evidence required before GO: NO
```

## Gate result

Decision: **GO**

Only allowed next step: **P0-00E Golden Baseline Contract**.
