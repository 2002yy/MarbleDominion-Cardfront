# Cardfront Dual-Track Governance And Formal Tower Grill Decisions

Date: 2026-08-20

Source baseline: `3f3c8a6`
Status: **DECISIONS LOCKED / DOCUMENTATION GOVERNANCE COMPLETE / IMPLEMENTATION NOT STARTED**

## 1. Why This Grill Was Required

The repository contained two competing current-next-step stories:

- gameplay P0/P1 checkpoint documents still described a frozen gameplay path;
- newer art production documents directed work toward the Formal Benchmark.

`PROJECT_STATUS.md` had grown beyond 1500 lines and retained historical next
steps beside newer decisions. The projectile Grill DOCX was also structurally
damaged. The user selected a dual-track program with explicit sequencing and
required further Grill whenever a missing decision could change implementation.

## 2. Dual-Track Governance

Locked decisions:

- Art Production and Gameplay Refactor are both active program tracks.
- Only one track receives implementation changes at a time.
- Small milestones alternate; work does not alternate per commit or calendar.
- `PROJECT_STATUS.md` selects the active track.
- A checkpoint may block and select the next step inside its track, but it may
  not switch the project to another track.
- Markdown is the content authority; DOCX is a formatted mirror.
- The current sequence is documentation governance → Art Formal Benchmark →
  current-main gameplay P0 drift audit → evidence-based next milestone.

## 3. Gameplay P0 Audit Decision

The historical P0 `NO-GO / P1 locked` result is neither discarded nor blindly
replayed on an obsolete commit.

After the art gate:

1. audit current `main` against the old blockers;
2. verify gameplay authority, save/restore, AI information boundaries, and
   current test authority;
3. retain the independent playtest if its target still applies;
4. update the acceptance protocol first if the old target is invalidated;
5. expand to a complete P0 rerun only if directed evidence finds material drift.

## 4. Formal Benchmark Expansion

The Formal Benchmark must cross from HQ into one complete functional Tower
vertical slice before GO. The selected asset is the Interceptor Tower.

Modules:

```text
tower_common.glb
tower_interceptor.glb
tower_theme_castle.glb
tower_damage_common.glb
```

All modules share one ground-contact origin and semantic sockets. Common body,
functional identity, map theme, faction material, level configuration, and
damage state remain separate responsibilities.

## 5. Scale And Level Grammar

- Tower remains the `1.0` tactical-height reference.
- Level 1–3 keep essentially the same footprint and total-height class.
- Levels change the weapon head, interception arms/shield plates, armor, and
  core intensity instead of scaling the complete asset.
- Level 1 exposes two large interception elements.
- Levels 2 and 3 expose three.
- Level 3 adds a readable counterfire weapon/muzzle distinction without
  approaching HQ height or changing gameplay footprint.

## 6. Damage And Destruction Grammar

The existing 4-HP authority maps to persistent visual states:

| HP | Visual state |
| ---: | --- |
| 4 | Complete |
| 3 | Light damage |
| 2 | Heavy damage |
| 1 | Critical / near destruction |
| 0 | Authored disassembly and short-lived rubble |

At 0 HP, the authoritative entity leaves the runtime Registry immediately.
The presentation layer may keep a read-only death snapshot for about one
second, with no collision, save data, targeting, occupancy, or gameplay
authority, then fade it out.

## 7. Operational State Grammar

The persistent world model answers two macro questions:

1. Can this Tower currently work?
2. Is its interception quota ready or exhausted?

Exact reason and count remain contextual information.

- Active: core lit, functional upper assembly ready.
- Unpowered: core extinguishes and the assembly settles/folds.
- Suppressed/temporarily disabled: bounded cool interference change cue; the
  contextual detail surface states the exact reason.
- Quota consumed: large interception arms/plates settle or extinguish as each
  charge is spent; do not depend on tiny persistent `×N` text.
- Level-3 counterfire: a real muzzle event and restrained recoil.

Required functional nodes:

- `PIV_Turret`
- `SOCKET_Muzzle`
- `VFX_Intercept`

## 8. Motion And VFX Boundaries

Build feedback starts from the existing authoritative spawn/build result:

```text
base set → module unfold → core light
```

Target duration: approximately `0.6–0.9 s`. Gameplay availability does not
wait for the presentation animation.

Upgrade feedback keeps the base still, swaps/settles the upper assembly, and
uses a short core pulse. It does not replay the full construction sequence.
Implementation requires an explicit presentation notification for level change;
the view must not infer upgrades from arbitrary polling history.

This slice includes only bounded construction dust/ring, upgrade pulse, damage
smoke/sparks, intercept response, counterfire recoil, and destruction pieces.
Formal audio and the broader D26 timing contract remain deferred.

## 9. Validator Prerequisite

D22 requires machine-verifiable admission, but the repository currently has no
reusable Formal GLB contract validator. P0-FT1 must implement the validator
before admitting the Tower assets. `Godot can import the GLB` is not Contract
PASS.

The validator must reject rather than heal invalid transforms, roots, semantic
node prefixes, required sockets, exported collision/Camera/Light, and unknown
material roles.

## 10. Acceptance Matrix

Deterministic state board:

- blue and red faction instances;
- Level 1–3;
- HP 4/3/2/1/0;
- Active, Unpowered, Suppressed, Quota Empty, and Level-3 Counter states.

Live fixed-camera captures:

- desktop `1120x720` and landscape-narrow `760x540`;
- both HQs, at least one Formal Tower, bridges/frontline, and blue/red
  projectiles in the same scene;
- complete and damaged Tower states;
- no critical HUD or battlefield overlap.

Automated evidence must cover contract validation, module isolation, faction
instance isolation, level/HP/operational mapping, explicit upgrade notification,
animation not changing authority, death snapshot non-authority, required
sockets, and affected runtime regression.

Final GO still requires product-owner screenshot acceptance.

## 11. Explicit Non-Goals

- No tower HP, interception count, counterfire, upgrade cost, build legality,
  fixed-slot, AI, save, projectile, or balance changes.
- No Fire-Control Beacon Formal asset.
- No Gate, Bridge, Stronghold, Rapid, Engineer, Industrial, or Lab expansion.
- No full Tower family, formal audio, or broad D26 implementation.
- No whole-model faction tint or runtime non-uniform scaling used as final form.

## 12. Rejected Alternatives

- A neutral screenshot-only scale tower: rejected because it has no gameplay identity.
- Whole-model growth per level: rejected because it breaks the tactical scale and occlusion budget.
- One complete GLB per faction/level/damage combination: rejected due combination explosion.
- Text-only operational state: rejected because world state must remain readable without tiny labels.
- Permanent rubble: rejected because it would imply occupancy or collision after authority removal.
- Expanding directly to Tower/Gate/Stronghold together: rejected until the cross-asset contract passes.
