# P0-DA5B Playtest NO-GO Remediation

Date: 2026-08-29

Playtest source commit: `4b240fb026b0a4dea1dfa10f4031935fff2719dc`

Decision: **NO-GO / REMEDIATION IMPLEMENTED LOCALLY / NEW RC AUDIT REQUIRED / P1 LOCKED**

Product-owner Grill lock: **`1A 2A 3A 4A 5A`**

## Evidence

The source-bound DA5 launcher passed branch, clean-worktree, local/remote-main,
minimum-RC, and Godot 4.7.1 checks. All three GitHub workflows on `4b240fb`
concluded success. The live playtest nevertheless exposed a long-session path
not represented by the green CI matrix:

```text
Can't add child 'CombatImpact' to 'ArenaWorld', already has a parent 'ArenaWorld'.
```

The error repeats from `CardfrontOrthographicArenaView._add_combat_effect()`
after a pooled impact node is reused without first leaving its existing parent.
Guidance and entity-contact events both reach the failing path.

The product-owner playtest also reported:

1. the top bar remains 50/50 and does not explain its calculation;
2. summoned units appear useless and stationary;
3. no selected-upgrade review surface exists;
4. building effects are too subtle to perceive;
5. rarity is not perceptible and late-match cards are not sufficiently strong.

This session is a valid product-owner NO-GO and defect discovery pass. It does
not replace the still-required independent initially unbriefed DA5 tester after
remediation.

## Verified causes

1. **Misleading top bar.** Cardfront passes current command-chamber HP into the
   generic proportional score bar. Each side displays
   `current HP / (both sides' current HP)`, so equal HP reads 50/50 regardless
   of absolute damage and can remain 50/50 after equal damage.
2. **Opaque creature action.** Creature actions run once at the Draft boundary.
   Repair units move only when a damaged owned frontline cell exists; guards
   stop at the nearest owned guard post; owned-only navigation can leave an
   entity with no visible movement. No intent or hold reason is presented.
3. **Missing review UI.** `selected_upgrade_levels` is authoritative and saved,
   but the player receives only a short upgrade toast. There is no persistent
   or reopenable consumer.
4. **Weak/broken building causality.** Guidance, interception, counterfire, and
   building-volley signals exist, but feedback is brief and the live impact-pool
   error corrupts repeated combat effects.
5. **Rarity has presence without perception or late progression.** Cards use a
   small rarity label and colored border. Base weights are Common 100,
   Uncommon 42, Rare 12; rarity level changes weights, but elapsed rounds do not
   impose a quality floor.

## Locked remediation (`1A 2A 3A 4A 5A`)

### 1A — Command-chamber truth

- Replace the relative 50/50 bar with two fixed-width, independently normalized
  command-chamber HP bars.
- Show absolute values such as `38/40`; each fill uses its own current/max HP.
- Keep territory as clearly labeled secondary text with Player / Neutral / AI
  percentages. Territory must not impersonate the primary win condition.

### 2A — Role-based automatic action plus intent

- Preserve distinct creature roles; do not turn every creature into a generic
  attacker.
- Every creature action boundary must produce an observable result: movement,
  repair/attack, Support-control assistance, or an explicit hold reason.
- A repair unit with no damaged target advances toward the nearest contested
  owned frontline; once holding that boundary it remains a Standard-Control
  Support contributor.
- Guards show their guard target/hold state; sappers show their assault target.

### 3A — Reopenable selected-upgrade drawer

- Add one collapsed secondary control named `本局强化`.
- The drawer is available during battle and Draft without occupying the center
  playfield by default.
- It lists selected upgrade name, Selected Level, and a readable state such as
  `本局生效`, `下轮待结算`, `已结算`, `建筑 Lx`, or entity/once-only state.
- It consumes `selected_upgrade_levels`; it never derives Selected Level from
  Echo application counts.

### 4A — Building causality before numeric churn

- Repair the live impact-pool error first.
- Strengthen tower-local muzzle/recoil/pulse, trajectory or contact emphasis,
  and short causal text for `引导`, `拦截`, `反击`, and `建筑齐射`.
- Keep the central playfield clear and coalesce repeated events.
- Do not increase ordinary tower numbers until the feedback-fixed build is
  replayed. Rare Building Volley may still be recalibrated under 5A.

### 5A — Perceptible rarity and late quality floor

- Use explicit tier glyphs/text plus whole-card material treatment and a
  bounded reveal emphasis; a small border-color difference is insufficient.
- Replace opaque `稀0` copy with readable rarity tendency language.
- Keep exactly three choices and the existing 18-card formal pool.
- After three prior player selections, each offer guarantees at least one
  Uncommon-or-Rare eligible card.
- After six prior player selections, each offer guarantees at least one Rare
  eligible card.
- Rarity Level advances the Rare guarantee by one prior selection per level,
  with a floor of three prior selections.
- Rare effects must create a visible next-volley or board-state power spike;
  calibrate exact values with deterministic B1 evidence instead of adding new
  cards or starting the P1 deep upgrade track.

## Non-goals

- no new cards, deckbuilder, reroll, deep-commit route, or P1 upgrade track;
- no new game mode or map family;
- no generic all-unit attack rewrite;
- no art-family expansion;
- no final DA5 GO from automated evidence or this product-owner session.

## Acceptance gates

1. Repeated pooled combat effects produce zero ERROR and no duplicate-parent
   attempt in focused and live long-session evidence.
2. Full/equal/damaged command chambers show truthful independent HP fills and
   absolute values; territory remains secondary.
3. The selected-upgrade drawer is closed by default, reopenable, accurate after
   repeated picks/Echo, and usable at desktop `1120x720` and narrow `760x540`.
4. Repair, guard, and sapper scenarios prove movement/action/hold intent, with
   repair units contributing their existing Standard-Control profile.
5. Each building event family has visible source and outcome feedback without
   spam or playfield obstruction.
6. Rarity tiers are distinguishable without reading border hue alone; mid/late
   guarantees are deterministic and preserve side RNG isolation.
7. Focused tests, 161-suite active CI coverage, B1 balance evidence, performance,
   screenshots, and a new error-free live session converge on one pushed RC.
8. DA5 is rerun with an independent initially unbriefed human after remediation;
   P1 stays locked until the resulting final seal.

## Only allowed next step

Review and deliver the bounded DA5B implementation as one new RC after explicit
commit/push authorization. Bind clean CI, an error-free live long session, the
new visual evidence, and the independent initially unbriefed DA5 rerun to that
same RC. Do not start P1 or another Art Production family.

## Local implementation evidence — 2026-08-30

The locked `1A 2A 3A 4A 5A` remediation is implemented in the local worktree:

- pooled combat impacts detach before pooling, reattach exactly once, and are
  explicitly freed during arena teardown;
- the top bar uses two fixed command-chamber lanes with independent `current /
  max` fill and absolute text; territory is an explicit secondary readout;
- `本局强化` is a closed-by-default drawer available in battle and Draft. It
  reads `selected_upgrade_levels`, lists Level and live state, and fits both
  `1120x720` and `760x540` captures;
- repair units move toward contested friendly frontline when no repair target
  exists; repair, guard, and sapper units expose their action or hold reason;
- tower-local feedback identifies `引导`, `拦截`, `反击`, `升级`, power state,
  and `建筑齐射 ×N`, with repeated-family coalescing;
- rarity uses tier glyphs, full-card material, stronger border/shadow, and a
  bounded Rare reveal. Offers guarantee Uncommon-or-better after three prior
  selections and Rare after six; each Rarity Level advances the Rare threshold
  by one with a floor of three;
- deterministic B1 calibration moved Building Volley from `2/3/4` to `4/6/8`
  shots per powered tower and Heavy Charge center/splash/defense impact from
  `1` to `2`. Echo remains unchanged.

Local evidence:

- GitHub Headless workflow list: `148` unique runners; `147` were clean in the
  full pass and the sole log-only failure was a pre-existing Lane Allocation
  fixture leak. After explicit node cleanup, that runner is `43 PASS`, exit 0,
  and zero ERROR lines, yielding `148/148` clean locally;
- focused suites include Orthographic Arena `174 PASS`, Upgrade Content `175
  PASS`, 18-card readability `220 PASS`, B1 Model Consistency `229 PASS`,
  Entity Card Runtime `27 PASS`, Draft geometry/state `96 PASS`, and creature
  runtime `29 PASS`;
- the final post-capture strict rerun covered Orthographic Arena, Performance
  Smoke, Draft geometry/state, Upgrade Content, 18-card readability, Lane
  Allocation, and Neutral Owner compatibility: `7/7` runners, `748` checks,
  exit 0, zero `SCRIPT ERROR` / `ERROR:` lines. A fresh project parse/load was
  also exit 0 with zero error lines;
- B1 162-match baseline diagnosed Building Volley `0.76%` and Heavy Charge
  `0.29%` selection rates. Final calibration records `13.13%` and `58.71%`,
  hero rates `49.07% / 50.93% / 50.00%`, zero invalid offers, and `40 PASS`;
- deterministic OpenGL RTX 5060 captures completed with exit 0 and zero ERROR
  lines at both desktop and narrow viewports:
  - `artifacts/cardfront-full-battle-40x60-viewport-1120x720.png`
  - `artifacts/cardfront-upgrade-history-40x60-viewport-1120x720.png`
  - `artifacts/cardfront-full-draft-40x60-viewport-1120x720.png`
  - `artifacts/cardfront-upgrade-history-40x50-viewport-760x540.png`
  - `artifacts/cardfront-full-draft-40x50-viewport-760x540.png`

This is not DA5 GO. A pushed source-bound RC, remote CI, a longer live replay,
and the independent human rerun remain mandatory.
