# P0-11M Full CI / Workflow Gate

P0 RC source commit: `def95b5dd575aee85a132870ba350e51cf51ba27`

Decision: **GO for P0-11M**

## Local release-candidate regression

Evidence: `D:\CardfrontEvidence\P0-11M-local-def95b5-20260813`

- Godot `4.7.1-stable.official` project boot/parse: PASS;
- full import: PASS;
- 155 unique active-workflow runners: 155 PASS, 0 FAIL;
- 314 stdout/stderr logs: 0 `ERROR`, 0 `SCRIPT ERROR`, 0 `WARNING`;
- identical runner/environment combinations were de-duplicated locally; CI still ran every workflow matrix job;
- rendered performance on the same RC: average 4.154 ms, P95 4.766 ms over 600 frames at `1120x720`, `40x40`, 6 entities and 7 Supports. Evidence: `D:\CardfrontEvidence\P0-11I-def95b5-20260813`.

The first full run exposed a false-green existing entity-runtime test: its fixture exceeded the frozen three-creature faction cap, returned null, logged a script error, and then self-reported PASS. Commit `def95b5` moved only the expiring test fixture to neutral ownership, asserted non-null creation, and retained the production cap. The final RC rerun is clean.

## GitHub Actions

Draft PR: [#24](https://github.com/2002yy/MarbleDominion-Cardfront/pull/24)

Head verified: `def95b5dd575aee85a132870ba350e51cf51ba27`

| Workflow | Jobs | Result | Run |
|---|---:|---|---|
| Headless Tests | 28 | 28 success | [31712374878](https://github.com/2002yy/MarbleDominion-Cardfront/actions/runs/31712374878) |
| Shared Upgrade AI Tests | 2 | 2 success | [31712374870](https://github.com/2002yy/MarbleDominion-Cardfront/actions/runs/31712374870) |
| Battlefield Entity Foundation Tests | 4 | 4 success | [31712374872](https://github.com/2002yy/MarbleDominion-Cardfront/actions/runs/31712374872) |
| B1 Simulation Tests | 8 | 8 success | [31712374887](https://github.com/2002yy/MarbleDominion-Cardfront/actions/runs/31712374887) |

Total: **42 success, 0 failure, 0 cancelled, 0 running**.

## Workflow diff audit

- parse/import remain required;
- no workflow was reduced or disabled;
- no `continue-on-error` was added;
- no audit seed was reduced;
- only authorized P0 runners were added to existing matrices.

Yellow tuning evidence remains deliberately distinct from structural failure: parity/balance runners may report provisional threshold failures while their audit-contract checks pass. No balance value was changed during P0-11.

Mandatory audit gates touched: active workflows; parse/import/boot; existing regression; false-green/log hygiene; performance; CI source identity

Audit status per gate: **PASS**

Evidence bound to source commit: **YES**

Unverified assumptions remaining: P0-11K human strategic comprehension/pacing only.

Legacy authority still reachable: no active-CI evidence of retired Stronghold numeric sampling; drift audit is recorded in P0-11N.

Second-authority risk: covered by deployment four-consumer parity and source re-audit.

Save/restore risk: full snapshot/restore runners passed.

Cross-system regression evidence: 155 local unique runners plus all 42 CI jobs.

Manual evidence required before final GO: **YES - P0-11K remains NO-GO**

Only allowed next automated step: P0-11N frozen-spec drift re-audit, followed by a final NO-GO seal unless human K evidence is supplied.
