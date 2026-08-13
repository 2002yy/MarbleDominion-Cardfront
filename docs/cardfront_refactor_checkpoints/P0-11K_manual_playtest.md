# P0-11K Human North-Star Playtest

Source commit: `def95b5dd575aee85a132870ba350e51cf51ba27`

Status: **BLOCKED / AUDIT REQUIRED**

Decision: **NO-GO**

P0-11K is intentionally not self-certified by the implementation agent. Automated integration, rendered evidence, and source inspection cannot replace a first-pass human player who has not been given the route interpretation in advance.

## Required human session

Run Godot `4.7.1-stable.official`, open Cardfront from commit `def95b5dd575aee85a132870ba350e51cf51ba27`, and preserve a short recording or timestamped notes. Do not first explain that one route is the main route and the other is a backup branch.

The session must exercise and record:

1. normal advance;
2. loss of the main route;
3. survival/usefulness of the alternate branch;
4. Core-only counterattack after all frontline Supports are lost;
5. a strong unit plus a low-cost control unit converting pressure into a Support claim;
6. repeated Draft -> Battlefield Preview -> return, with the battle remaining paused and the same three choices preserved;
7. at least one visible CapturedOffline state and an attempted deployment that explains why it is denied.

After the first run, record the tester's unprompted answers:

- What is different about the two routes?
- Why could one Support deploy while another could not?
- What changed after a Support was suppressed/captured?
- What options remained after being pushed back to Core?
- Which units won the fight, and which converted the advantage into a claim?

## Automatic FAIL conditions

- repeated confusion that an owned point should allow deployment while it is offline;
- the alternate bridge reads as decorative or strategically irrelevant;
- Support visuals obstruct combat;
- Core fallback is not practically usable;
- one claim naturally snowballs into an unstoppable automatic-spawn chain;
- the cheap control unit has no meaningful role beside the strong unit.

## Evidence fields for the reviewer

```text
Tester:
Date/time:
Source commit:
Recording or notes path:
Scenarios 1-7 completed:
Unprompted answers:
Observed failures:
Decision: GO / NO-GO
```

Mandatory audit gates touched: Human North-Star; Support/route comprehensibility; Core fallback; control-unit role; Draft Preview lifecycle

Audit status per gate: **BLOCKED pending human evidence**

Evidence bound to source commit: **NO - human evidence not yet supplied**

Unverified assumptions remaining: Whether a new player can infer route usefulness and online/offline deployment without design explanation; whether the live pacing avoids an unstoppable claim/spawn snowball.

Legacy authority still reachable: No known legacy Stronghold gameplay authority in the formal live path; final RC regression and drift audit remain separate gates.

Second-authority risk: No second deployment authority is expected; the human session must still observe actual Commit/automatic behavior rather than a presentation fixture.

Save/restore risk: Covered by automated P0-11H evidence; not substituted for this experience gate.

Cross-system regression evidence: Automated evidence exists, but does not satisfy K.

Manual evidence required before GO: **YES**

Only allowed next formal decision: complete this human checklist on the bound RC and record `Decision: GO` or return the failure to its owning P0 step. P1 remains locked.
