# P0-11I Performance & Recompute Evidence

Source commit: `76fdfd31dab4cd69653e9030c08213a324fa766c`

Godot version: `4.7.1-stable.official.a13da4feb`

Decision: **GO WITH RECORDED BASELINE LIMITATION**

Only allowed next step: **P0-11J - Log / Signal Hygiene Audit**.

Evidence root: `D:\CardfrontEvidence\P0-11GHIJ-76fdfd3-20260813`

## I1 structural smoke

`CardfrontPerformanceSmokeTestRunner` passes 10 checks: 40x40 and 50x50 runtimes load; overlays preserve dirty-redraw boundaries; legacy ShotGuide remains absent.

## I2 event counters

| Counter / boundary | Evidence | Result |
|---|---|---|
| Support graph recompute | 100 idle queries + 100 hover queries do not increase `recompute_count`; changed Claim/operational state causes one lazy bounded recompute | PASS |
| Support presentation update | existing instances refresh on each authoritative snapshot; instance identity is retained | PASS |
| Deployment evaluation | editor/test-only counter: 100 idle + 100 visual frames stay 0; one explicit query yields 1 | PASS |
| AI Observation build | editor/test-only counter: 100 idle + 100 visual frames stay 0; one explicit build yields 1 | PASS |
| Preview/resize graph boundary | 40 toggles and two resizes leave graph revision/recompute snapshot unchanged | PASS |

The two new counters are gated by `OS.has_feature("editor")`; they do not add release-build gameplay work.

## I3 rendered same-machine measurement

Measurement tool: `scripts/tools/measure_cardfront_p0_runtime.gd`

```text
machine: Intel Core Ultra 7 255HX / NVIDIA RTX 5060 Laptop GPU / 16 GB
renderer: OpenGL 3.3 gl_compatibility, NVIDIA driver 591.86
viewport: 1120x720
grid: 40x40 default_duel
warmup: 120 rendered frames
sample: 600 rendered frames
active entities: 6
supports: 7
average frame time: 4.164 ms
P95 frame time: 4.242 ms
average FPS equivalent: 240.15
```

This is a rendered `process_frame` wall-time sample and includes display/VSync scheduling. It is not a GPU-only profiler trace.

P0-00B explicitly records that no valid FPS/frame-time sample was taken. Therefore historical baseline diff is **N/A: no comparable pre-P0 measurement exists**. This checkpoint does not claim a percentage improvement or a frozen threshold. The current source-bound measurement becomes the first reproducible anchor for later comparisons, satisfying the rule that structural loading alone cannot masquerade as performance evidence.

```text
Mandatory audit gate touched: P0-11I performance/recompute
Evidence bound to source commit: YES
Structural smoke only presented as performance proof: NO
Real rendered measurement: YES
Historical P0-00B numerical diff: N/A - source baseline absent
Invented threshold: NO
Per-frame graph rebuild: NO
Errors/warnings: 0/0
```
