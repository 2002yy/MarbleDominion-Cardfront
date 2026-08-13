# P0-11L Visual Evidence Pack

Visual source commit: `def95b5dd575aee85a132870ba350e51cf51ba27`

Engine: Godot `4.7.1-stable.official`

Renderer/device: OpenGL Compatibility / NVIDIA GeForce RTX 5060 Laptop GPU

Evidence directory: `D:\CardfrontEvidence\P0-11L-def95b5-20260813`

Status: **PASS (automation/reviewer visual gate)**

Decision: **GO for P0-11L only**

This does not override the blocked P0-11K human experience gate and is not a P0 final GO.

## Source-bound evidence

| Required state | File | Review result |
|---|---|---|
| Default battle; no persistent network lines | `01-default-battle.png` | PASS |
| Active Support | `02-active-support.png` | PASS; explicit `在线` state label |
| Neutral/Offline Support | `03-neutral-offline-support.png` | PASS; explicit `中立` label |
| Capturing | `04-capturing-support.png` | PASS; side color plus `占领 46%` |
| Contested | `05-contested-support.png` | PASS; orange `争夺中` |
| CapturedOffline | `06-captured-offline.png` | PASS; dark owner color plus `离线`, visually distinct from Active |
| Active Support legal targeting | `07-active-support-zone.png` | PASS; real `DeploymentRules` projection, 355 allowed cells including a visible forward Support footprint |
| Core fallback deployment | `08-core-fallback-zone.png` | PASS; real `DeploymentRules` projection, 320 allowed Core cells and no forward footprint |
| Main route severed / branch survives | `09-route-severed-branch-survives.png` | PASS; left offline, right chain online |
| Draft normal three-choice | `10-draft-three-choice.png` | PASS; exactly three cards |
| Battlefield Preview | `11-battlefield-preview.png` | PASS; Draft hidden, return control visible, battle remains paused |
| Preview return geometry | `12-preview-return.png` | PASS; same three-offer composition returns |
| Narrow state | `13-narrow-draft.png` | PASS at `760x540`; all three cards and their text remain inside the viewport |

Every image includes the full source SHA, viewport, and scenario annotation. The capture script aborts if the Active Support projection does not contain more allowed cells than the Core-only fallback.

## Defects found and repaired during review

The first evidence attempt was rejected because it reset immutable Core states, made Support states too hard to distinguish, omitted a distinct Active-Support deployment extent, and exposed the frozen narrow Draft shell partly outside the viewport. The accepted source:

- preserves both Core claims in the evidence fixture;
- adds detached state labels to the pure Support presenter;
- scales the unchanged desktop Draft shell proportionally inside `760x540`;
- adds geometry/lifecycle assertions that all narrow cards remain visible;
- compares 355 Active-network cells against 320 Core-only cells through the real preview/rules projection.

Mandatory audit gates touched: Support visual non-authority; Active/Neutral/Capturing/Contested/CapturedOffline distinction; deployment-zone visibility; Core fallback; route branch; Draft Preview; narrow layout

Audit status per gate: **PASS**

Evidence bound to source commit: **YES**

Unverified assumptions remaining: North-Star strategic comprehension and live pacing remain P0-11K human evidence, not visual-pack claims.

Legacy authority still reachable: None introduced by the evidence/presenter changes.

Second-authority risk: None. The status label consumes detached snapshots; deployment screenshots consume the existing preview projection of `DeploymentRules`.

Save/restore risk: Not changed by this presentation batch.

Cross-system regression evidence: Focused Support presentation, Draft geometry/lifecycle, live capture, and deployment-zone runners passed before capture; final RC full regression remains P0-11M.

Manual evidence required before final GO: **YES - P0-11K remains NO-GO**

Only allowed next automated step: P0-11M full CI/workflow gate on the same implementation source, while P0-11K remains the only missing human acceptance input.
