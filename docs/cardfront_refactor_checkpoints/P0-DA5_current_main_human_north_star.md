# P0-DA5 Current-main Human North-Star Gate

Date: 2026-08-29

Minimum eligible runtime source: `f2e427043aa34a422f50d4f52559bd11eabed623`

Prepared from current `main`: `72871f2aa2d9c1814cc7b6701abb29cad7d580f3`

Decision: **READY FOR INDEPENDENT HUMAN SESSION / NO-GO UNTIL EVIDENCE**

## Purpose

This checkpoint implements batch 5 from
`P0-DA4_current_main_rc_convergence.md`. It preserves the intent of the old
P0-11K gate while rebinding the protocol to the current pushed `main`. It does
not transfer the old `def95b5` session, screenshots, or final seal.

The implementation agent must not act as the tester and must not turn a
deterministic fixture, screenshot pack, or automated assertion into a human
comprehension result.

## Source-binding launcher

The session host runs:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/run_cardfront_p0_da5_session.ps1
```

The launcher refuses to start unless all of the following are true:

- branch is `main`;
- `HEAD` exactly matches both local `origin/main` and the live remote `main`;
- the worktree is clean;
- `f2e4270` is an ancestor of the tested commit;
- the declared Godot 4.7.1 console executable exists.

It creates an ignored `artifacts/p0-da5-human/<timestamp>-<short-sha>/`
directory containing `session_manifest.json` and a blank `session_notes.md`,
then launches the real project. The recording itself remains outside Git unless
the reviewer explicitly chooses a safe evidence location.

## Independence and contamination rules

The tester must be a person other than the implementation agent. Before phase
A is complete, the host must not explain:

- which route is the main route or backup branch;
- why an owned Support can be offline;
- why a deployment is denied;
- the intended split between strong combat units and low-cost control units;
- the expected recovery path after losing the frontline.

The host may explain only basic controls or resolve a technical launch problem.
Any strategic hint before the unprompted answers contaminates the session and
requires a fresh tester or a new first-pass session.

## Phase A — unbriefed first pass

Let the tester enter through the normal product flow and play without route or
Support interpretation. Preserve a recording or timestamped notes. At the end
of the first pass, ask these questions without supplying vocabulary from the
expected answer:

1. What seemed different about the two routes?
2. Why could one position deploy while another could not?
3. What changed when a strategic point was suppressed or captured?
4. What options seemed to remain after being pushed back?
5. Which units won direct fights, and which units helped turn that advantage
   into control?
6. At what moment did the match feel decided, and did a believable recovery
   option still exist before that point?

Record the answers as close to verbatim as practical before discussing the
intended design.

## Phase B — hosted coverage

After phase A answers are frozen, the host may identify the required states and
ask the tester to continue until all seven are observed through the real
runtime:

1. normal advance;
2. loss of the main route while the alternate branch remains useful;
3. Core-only counterattack after all frontline Supports are lost;
4. a strong unit plus a low-cost control unit converting pressure into a
   Support claim;
5. repeated Draft -> Battlefield Preview -> return, with battle pause and the
   same three choices preserved;
6. at least one visible CapturedOffline state;
7. an attempted deployment at an owned-but-offline Support, with the tester
   explaining the denial after observing the feedback.

If ordinary play cannot reach a required state in a reasonable session, record
that as a gate failure. Do not use a presentation-only fixture to claim the
scenario complete.

## Automatic FAIL conditions

- source binding, clean-worktree binding, independence, or phase-A isolation is
  missing;
- the alternate bridge reads as decorative or strategically irrelevant;
- an owned-but-offline Support repeatedly reads as deployment-capable;
- Support visuals obstruct active combat;
- Core fallback is not practically usable;
- the first Support claim appears to create an unstoppable automatic-spawn
  chain with no believable recovery window;
- the low-cost control unit has no understandable role beside the strong unit;
- Draft Preview changes the choices, unpauses the battle, or cannot return
  predictably;
- one or more phase-B scenarios cannot be completed in the real runtime.

## GO requirements

All source-binding and independence fields must be present, all seven scenarios
must be completed, no automatic FAIL condition may occur, and the unprompted
answers must show practical understanding of:

- two-route redundancy;
- ownership versus online deployment reachability;
- Support suppression/capture consequences;
- Core fallback recovery;
- combat strength versus control contribution;
- whether the losing side retains a fair chance before the match is decided.

Ambiguous evidence is **NO-GO**, not partial PASS. A NO-GO returns the observed
failure to its owning P0 contract; it does not authorize balance expansion or
P1.

## Reviewer evidence fields

The launcher pre-fills the source fields in `session_notes.md`. The independent
reviewer must complete the remaining fields and choose exactly one decision.

```text
Tester:
Tester independent from implementation: YES / NO
Date/time:
Source commit:
Branch / local-and-remote origin-main match / clean worktree:
Godot version:
Recording or timestamped notes path:
Phase A unbriefed: YES / NO
Strategic hints before phase A answers: YES / NO
Unprompted answers 1-6:
Scenarios 1-7 completed: YES / NO per item
Observed failures:
Fair-chance finding:
Decision: GO / NO-GO
Reviewer:
Review date/time:
```

## Gate report

Mandatory audit gates touched: Human North-Star; source identity; Support/route
comprehension; Core fallback; combat/control role; Draft Preview lifecycle;
fair-chance pacing

Audit status per gate: **READY / HUMAN EVIDENCE MISSING**

Evidence bound to source commit: **NO — protocol prepared, session not run**

Manual evidence required before GO: **YES**

Only allowed next step: run this protocol with an independent initially
unbriefed tester against a clean pushed `main`, then record the evidence and
decision here. If GO, create batch 6 final current-main seal; if NO-GO, route
only the observed failure back to its owning P0 checkpoint. P1 remains locked.
