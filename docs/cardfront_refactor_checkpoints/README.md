# Cardfront Checkpoint Hub / 检查点入口

Current status authority:
[`../PROJECT_STATUS.md`](../PROJECT_STATUS.md)

## Authority Rule

- `PROJECT_STATUS.md` selects the active program track.
- The latest valid checkpoint inside that track may block or select its next
  step.
- A checkpoint cannot switch tracks or override a later Grill decision.
- Historical checkpoints remain immutable evidence unless a correction is
  explicitly labeled.
- Missing manual/runtime evidence is never silently promoted to PASS.

## Closed Art Production Checkpoint

Current checkpoint:

[`P0-FT1_formal_interceptor_tower_benchmark.md`](P0-FT1_formal_interceptor_tower_benchmark.md)

Current decision: **TEMPORARY VISUAL GO / CLOSED**

P0-FT1 was accepted by the product owner on 2026-08-21 from source commit
`697dcbe`. Stronger HP2/HP1 silhouette differentiation remains a non-blocking
future enhancement. No Art Production implementation is active.

Decision authority:
[`../设计_design/CARDFRONT_DUAL_TRACK_AND_FORMAL_TOWER_GRILL_DECISIONS_2026-08-20.md`](../设计_design/CARDFRONT_DUAL_TRACK_AND_FORMAL_TOWER_GRILL_DECISIONS_2026-08-20.md)

## Active Gameplay Refactor Gate

Current checkpoint:

[`P0-DA5B_playtest_no_go_remediation.md`](P0-DA5B_playtest_no_go_remediation.md)

Current decision: **NO-GO / RC `9ec52d1` AND CI GREEN / LIVE LONG-SESSION AUDIT
PASSED / INDEPENDENT HUMAN RERUN REQUIRED / P1 LOCKED**

(`P0-DA4_current_main_rc_convergence.md` binds the completed automated rerun to
`f2e4270`. `P0-DA1_current_main_directed_drift_audit.md` recorded the founding
**NO-GO / MATERIAL DRIFT** and remains the audit of record; its required
rerun batches 1–4 are complete and bound to `f2e4270`.)

Only allowed next Gameplay Refactor step:

> Rerun the P0-DA5 human protocol with an independent initially unbriefed
> tester against RC `9ec52d1` / tip `7df8329` (long-session live audit and
> refreshed captures already bound). Host facilitation guide:
> [`P0-DA5_independent_rerun_host_guide.md`](P0-DA5_independent_rerun_host_guide.md).
> P1 stays locked until the final seal.

Do not:

- blindly resume an old P0 micro-step;
- waive the historical `NO-GO / P1 locked` result;
- begin P1 before the new gameplay checkpoint explicitly allows it.

## Evidence Collections

- `P0-00A` through `P0-09B2`: gameplay refactor implementation evidence.
- `P0-PG1_projectile_grammar_prototype.md`: projectile grammar evidence.
- `P1_README.md`: frozen P1 sequence reference; not an authorization to start.
- Historical monolithic checkpoint instructions:
  [`../历史_history/cardfront_refactor_2026-08/CHECKPOINT_README_SNAPSHOT_2026-08-20.md`](../历史_history/cardfront_refactor_2026-08/CHECKPOINT_README_SNAPSHOT_2026-08-20.md)
