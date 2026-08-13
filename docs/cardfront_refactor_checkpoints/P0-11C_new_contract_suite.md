# P0-11C New Frozen Contract Suite

P0 RC source commit: `34ca4b518ec846b3f50e2988d288a83da74dd498`

Godot version: `4.7.1-stable.official.a13da4feb`

Decision: **GO**

Only allowed next step: **P0-11D - Existing Class A/B Regression Suite**.

## Evidence

Evidence root: `D:\CardfrontEvidence\P0-11BCD-34ca4b5-20260813`

The evidence was produced from a clean detached checkout after a fresh serialized 702-item import and Cardfront boot. All runner logs are separate; no aggregate runner hides domain failures.

New frozen P0 contract domains executed:

- Support identity, map metadata and runtime mapping;
- Support state, capture contributor/profile/aggregation/state machine/occupancy/territory adapter;
- Support topology, validation, connectivity truth/resolver/cache and route semantics;
- Support presentation contract/lifecycle and deployment-zone visualization;
- Deployment contract, Core fallback, directional geometry and Player/Preview/AI/Automatic four-consumer parity;
- Draft geometry/lifecycle, three-choice runtime, Preview, side RNG and Offer independence;
- Echo/Selected Level semantic separation, snapshot, Offer projection and no deck inflation;
- AI observation boundary/projection and Commander consumption.

Every runner in these domains emitted a standard `PASS (<n> checks)` summary, exited 0, and produced zero fail markers, script/engine errors and warnings.

## Inventory correction made during the gate

The audit found `CardfrontCardHoverMotionTestRunner.gd` outside all active workflows. Its two 58-pixel collapse assertions belonged to the retired 70-pixel hand layout, while the active UI contract and production constant both use a compact 30-48 pixel range (38 pixels in production). The stale assertions were aligned to the already-frozen active contract and the runner was added to the Cardfront UI workflow batch.

This changes test authority only. It does not change UI layout or gameplay.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-11C new frozen contract suite
Audit status: PASS
Evidence bound to source commit: YES - 34ca4b518ec846b3f50e2988d288a83da74dd498
Independent domain runners retained: YES
Support contracts: PASS
Deployment four-consumer contracts: PASS
Draft/Preview/Offer contracts: PASS
Level/Echo contracts: PASS
AI observation contracts: PASS
Runner fail markers: 0
Script/engine errors: 0
Warnings: 0
Gameplay changed by audit repair: NO
```
