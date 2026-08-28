# P0-DA1 Current-main Directed P0 Drift Audit

Date: 2026-08-28

Audit baseline: `144b57fff0eabd54b54c9e5d8b47fd706d5e0816`

Historical comparison RC: `def95b5dd575aee85a132870ba350e51cf51ba27`

Decision: **NO-GO / MATERIAL DRIFT / FULL CURRENT-MAIN P0 RERUN REQUIRED**

## Purpose

P0-FT1 received temporary visual GO, so the locked dual-track program sequence
requires a directed current-main gameplay audit before choosing more production
work. This audit does not treat the old P0 RC as merged truth and does not waive
its independent human gate. It asks whether that source target and evidence
still apply to the actual remote `main`.

## Boundaries

Audited surfaces:

- the historical P0 red blocker and source-bound human protocol;
- formal-live gameplay authority and legacy reachability;
- Support identity, capture, connectivity, and deployment consumers;
- save/restore authority versus derived projections;
- AI information boundaries;
- active tests, remote CI, and current authority documents.

Non-goals:

- no P1 route/deep-commit/reroll/track feature;
- no balance or content expansion;
- no rollback of accepted current-main art assets;
- no wholesale merge or cherry-pick of PR #24 without current-main validation;
- no self-certification of the independent human North-Star gate.

## Verified Repository Facts

1. Remote and local `main` match at `144b57f` with divergence `0/0` at audit
   start.
2. PR #24 remains Draft/Open at head `f0b7a47`; its automated P0 RC is
   `def95b5`, and its final decision remains NO-GO because P0-11K is missing.
3. `main` does not contain the RC's independent
   `CardfrontSupportCaptureRuntime`, `CardfrontAiObservationBuilder`, final
   P0-11 checkpoints, or source-bound evidence tooling.
4. `Main._on_strongholds_sampled()` still calls
   `runtime.stronghold_system.sample_bonuses()` and passes the result into the
   live win-condition path.
5. Current `CardfrontAiCommander` still accepts run-state/context objects rather
   than a detached whitelist observation.
6. Current Support identity/connectivity/deployment foundations and
   Selected-Level persistence exist, but the complete final-RC consumer chain
   and evidence seal do not.
7. Remote Headless Tests fail on `144b57f`; B1 Simulation Tests and Shared
   Upgrade AI Tests pass. The failing job is `Cardfront v0.3 gate connectivity`,
   whose Orthographic Arena batch reports modular HQ module count `2` instead
   of `3`.
8. Source inspection identifies the HQ failure: Rapid/Engineer onboarding
   replaced the original hero/theme instantiation loop and omitted
   `HQThemeCastle`; its test probe also hard-coded `HQHeroBalanced`.
9. `PROJECT_STATUS.md`, this checkpoint hub, and P0-FT1 still described
   `10ddb48` and a pending product-owner decision despite later accepted and
   shipped work.

## Frozen-invariant Drift Matrix

| Invariant | Current-main result | Evidence / consequence |
|---|---|---|
| Support replaces numeric Stronghold bonus authority | **FAIL** | live `sample_bonuses()` consumer remains in `Main.gd` |
| Support Capture is independent from projectile territory capture | **FAIL / ABSENT** | final-RC live Support Capture runtime is not on `main` |
| SupportGraph and GateConnectivity remain separate | PASS in source | separate graph/gate systems and focused tests remain |
| Preview/Commit/AI/automatic placement share deployment legality | PASS foundation / rerun required | `DeploymentRules.evaluate()` and support context remain; full current-main parity evidence must be rerun |
| Selected Level remains distinct from effect count/rarity | PASS foundation / UI evidence incomplete | state and save tests exist; final-RC offer projection is absent |
| AI receives detached allowlisted information | **FAIL / ABSENT** | observation builder and boundary tests are not on `main` |
| Save stores authority, not derived connectivity | PARTIAL / rerun required | Selected Level snapshots exist; live Support Capture state binding is absent |
| UI/presentation is not gameplay authority | PASS foundation / rerun required | presentation adapters remain, but live Support-state projection chain is incomplete |
| Active CI is green | **FAIL** | Headless Tests fail at modular HQ assembly |
| Human North-Star evidence is source-bound and current | **INVALIDATED** | `def95b5` is not current `main`; later runtime/art/UI changes require a new RC and protocol binding |

## Immediate Audit Repair

The local audit repair restores deterministic modular HQ assembly:

- instantiate the selected hero module and `HQThemeCastle` together;
- retain `HQDamageModule` as the third module;
- count any registered `HQHero*` child rather than only Balanced.

Focused local result: `CardfrontOrthographicArenaTestRunner` **166 PASS**.
Remote CI evidence was subsequently authorized and bound: the required rerun
batches 1–4 are complete and converged on `f2e4270` — see
[`P0-DA4_current_main_rc_convergence.md`](P0-DA4_current_main_rc_convergence.md)
for the bound evidence.

## Decision And Required Rerun

Material drift is confirmed. The old conclusion “automation complete, only
human P0-11K missing” is not valid for current `main`. P1 remains locked, and
the old human test must not be run against `def95b5` as if it accepted the
current product.

The current-main P0 rerun will proceed in bounded batches:

1. **P0-DA2 Support / Stronghold Authority Reconciliation**;
2. AI Observation boundary restoration and current-main projection tests;
3. Offer/Selected-Level projection and no-deck-inflation evidence;
4. parse/import, active regression, save, performance, log, visual, and CI
   convergence on one new RC;
5. a newly source-bound independent human North-Star session;
6. a new final GO / NO-GO seal.

## Gate Report

Mandatory audit gates touched: current authority; gameplay authority;
save/restore; AI information boundary; active test/CI authority; human evidence

Audit status per gate: **NO-GO / material drift**

Evidence bound to source commit: audit **YES (`144b57f`)**; local repair **NO
(working tree)**

Unverified assumptions remaining: no current-main full regression; no new
source-bound human comprehension/pacing evidence

Legacy authority still reachable: **YES — Stronghold numeric bonus consumer**

Second-authority risk: **YES — incomplete split between current-main Support
foundations and historical RC live authority**

Save/restore risk: **OPEN — independent live Support Capture binding absent**

Cross-system regression evidence: **INCOMPLETE; remote Headless failure present**

Manual evidence required before final GO: **YES, after a new RC exists**

Only allowed next step: implement P0-DA2 on current `main`, preserve accepted
art assets, and do not start P1 or another Art Production family.
