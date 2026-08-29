# P0-DA4 Current-main RC Convergence

Date: 2026-08-28

RC source commit: `f2e427043aa34a422f50d4f52559bd11eabed623` (`f2e4270`)

Decision: **CONVERGENCE COMPLETE / AWAITING INDEPENDENT HUMAN NORTH-STAR**
(P0-DA1 required-rerun batches 1–4 done; batch 5 human session and batch 6
seal remain)

## Scope

This checkpoint records the current-main P0 rerun convergence demanded by
`P0-DA1_current_main_directed_drift_audit.md`. It binds automated evidence to
one pushed `main` commit and leaves the human gate explicitly open.

## Automated Evidence Bound To `f2e4270`

1. **Full active regression matrix via CI.** All 161 local
   `*TestRunner.gd` suites are enumerated across three workflows
   (`headless-tests.yml`, `b1-simulation-tests.yml`,
   `shared-upgrade-ai-tests.yml`); all three concluded **success** on
   `f2e4270`. Previously 10 suites existed only as local dark runners; they
   are now enumerated in CI.
2. **Parse and import checks: 0 errors.**
3. **Performance budget** batch (`CardfrontPerformanceSmokeTestRunner`) green
   inside the Headless matrix.
4. **Log cleanliness:** no gameplay SCRIPT ERRORs in the convergent suites.
   The headless dummy-renderer `material is null` teardown noise found during
   DA1 was eliminated by the deterministic ArenaView teardown in `7aa8bf6`;
   the live GateRuntime teardown rerun on `72871f2` is 12 PASS with no ERROR.

## Rerun Batches Completed

1. **P0-DA2 batch 1 (`7aa8bf6`)** — Support Capture authority wired into live
   runtime with save/restore binding; legacy Stronghold `sample_bonuses()`
   numeric consumer retired (`sample_status()` telemetry only); HQ
   hero+theme assembly regression fixed (remote CI red since `94a762b`).
2. **P0-DA2 batch 2 (`31bd718`)** — AI Observation boundary restored from the
   RC schema: detached three-tier allowlist projection, forbidden-field
   deny-list, pure-value atomic rejection; live Draft AI consumes
   `choose_from_observation()`; decision strength frozen vs legacy path.
3. **P0-DA2 batch 3 (`33c3a1f`)** — Offer/View Level projection restored
   (`current_level`/`next_level` from Selected Level authority only) and
   no-deck-inflation evidence frozen (62 checks).
4. **P0-DA2 batch 4a (`f2e4270`)** — dark-corner runner repairs
   (hover-motion stale constants; two legacy-surface fixtures moved to the
   Main.tscn + legacy-compat-flag pattern; settings runner re-targeted to the
   mode-driven performance authority) and CI coverage closed at 161/161.

## DA1 Drift Matrix Re-check

| Invariant | f2e4270 result |
|---|---|
| Support replaces numeric Stronghold bonus authority | PASS (live consumer retired) |
| Support Capture independent from projectile territory capture | PASS (live runtime + save binding) |
| Preview/Commit/AI/automatic placement share deployment legality | PASS (deployment suites green in CI) |
| Selected Level distinct from effect count/rarity | PASS (projection + inflation evidence) |
| AI receives detached allowlisted information | PASS (boundary/projection/commander suites) |
| Save stores authority, not derived connectivity | PASS (Support states snapshotted; connectivity remains derived) |
| UI/presentation is not gameplay authority | PASS (presentation provider pattern) |
| Active CI is green | PASS (3/3 workflows on `f2e4270`) |
| Human North-Star evidence is source-bound and current | **OPEN — batch 5** |

## Remaining Gates

- **Batch 5:** a newly bound independent human North-Star session played
  against an RC at or after `f2e4270` (comprehension, pacing, fair-chance
  evidence per the old P0-11K intent; the old `def95b5` session does not
  transfer). The current protocol and source-binding launcher are frozen in
  [`P0-DA5_current_main_human_north_star.md`](P0-DA5_current_main_human_north_star.md).
- **Batch 6:** final current-main GO / NO-GO seal recorded from batch 5
  evidence. P1 remains locked until that seal.

## Gate Report

Evidence bound to source commit: **YES (`f2e4270`, pushed; CI green)**
Manual evidence required before final GO: **YES**
Unverified assumptions remaining: human comprehension/pacing/fair-chance
session only.
