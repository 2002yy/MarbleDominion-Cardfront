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

## Active Art Production Checkpoint

Current checkpoint:

[`P0-FT1_formal_interceptor_tower_benchmark.md`](P0-FT1_formal_interceptor_tower_benchmark.md)

Current decision: **NOT STARTED**

Only allowed next Art Production step:

> Implement the reusable D22 Formal GLB validator with negative fixtures and
> focused tests. Do not start Tower modeling before validator admission is
> executable.

Decision authority:
[`../设计_design/CARDFRONT_DUAL_TRACK_AND_FORMAL_TOWER_GRILL_DECISIONS_2026-08-20.md`](../设计_design/CARDFRONT_DUAL_TRACK_AND_FORMAL_TOWER_GRILL_DECISIONS_2026-08-20.md)

## Queued Gameplay Refactor Gate

Gameplay implementation is not active. After P0-FT1 GO/NO-GO, the first
gameplay action is a directed current-`main` P0 drift audit against the old
blockers, authority boundaries, save/restore, AI information boundaries, and
current tests.

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
