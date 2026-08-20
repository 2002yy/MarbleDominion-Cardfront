# P0-PG1 Projectile Grammar Prototype

Date: 2026-08-20
Source baseline: `cdd128b`
Evidence revision: `faa152d`
Decision: **AUTOMATED PASS / AI VISUAL PASS / PRODUCT-OWNER SCREENSHOT GO PENDING**

## Scope

This checkpoint implements and validates the locked GrillMe contract:

- Type = body silhouette and structure.
- Faction = shape-matched outer rim plus trail hue.
- Standard, Siege, and Suppression remain presentation-only variants of the
  existing authoritative projectiles.
- No simulation, collision, trajectory, AI, damage, balance, card, or GLB
  behavior changes are permitted.

## Implementation

- `Standard`: round baseline.
- `Siege`: larger warm-gray body with a heavy non-round ground footprint.
- `Suppression`: cool-gray disc with a prototype ground-footprint aspect of at
  least `2.15:1` after runtime scaling.
- `FactionRim`: reuses the body mesh, expands it by `1.18`, and renders a
  depth-tested, front-face-culled, unshaded emissive back shell. The type body
  occludes the shell center, leaving a red/blue contour rather than a full-body
  faction wash.
- `FactionTrail`: remains faction-colored. Trail geometry compensates for the
  non-uniform body scale so a flat Suppression body does not shorten its trail.

## Deterministic evidence contract

Run:

```powershell
& .\scripts\tools\run_cardfront_projectile_grammar_capture.ps1
```

The tool produces three scenarios for each required camera configuration:

1. `trail-off`: six frozen projectiles, exactly one of every faction/type pair.
2. `trail-on`: the same six-projectile layout with faction trails restored.
3. `volley`: eighteen real `BulletPool` projectiles, three of every
   faction/type pair, frozen at the evidence frame so contact/recycle timing
   cannot silently change the matrix.

Camera configurations:

- `1120x720 @ 100%`
- `1120x720 @ 112%`
- `760x540 @ 112%`

Each run writes three PNGs plus a JSON manifest under
`artifacts/projectile-grammar-pg1/`. Before saving, it validates exact active
counts, exact faction/type counts, visible proxy counts, screen bounds, trail
mode, shape-matched rims, and the Suppression footprint gate. The manifest also
records the HEAD SHA plus worktree dirty state and paths, so uncommitted visual
evidence cannot be mistaken for a clean-commit capture.

## Automated evidence

- `CardfrontOrthographicArenaTestRunner.gd`: **PASS (121 checks)**
- `CardfrontBattlefieldScaleTestRunner.gd`: **PASS (57 checks)**
- `CardfrontModeSmokeTestRunner.gd`: **PASS (38 checks)**
- PG1 capture manifests: **3/3 PASS**, covering **9/9 required PNGs**

The Arena runner now inspects the actual runtime proxy and material state. It
does not accept a configuration-dictionary-only green result. It verifies rim
mesh parity, alpha transparency, unshaded mode, front-face culling, depth
occlusion, faction separation, type footprint ratios, and Trail OFF/ON state.

## Visual review

AI inspection of all nine full-resolution captures found:

- Trail OFF: Standard, Siege, and Suppression remain distinguishable in a
  single frame.
- Trail ON: player blue and AI red remain visible on both the contour and the
  trail without recoloring the Siege or Suppression body.
- `760x540 @ 112%`: the three silhouettes do not collapse into one shape.
- The eighteen-projectile pressure fixture preserves the grammar under the
  tested overlap, but does not waive future higher-density review.

Product-owner review remains the final projectile-only screenshot gate. It does
not block the independently scoped Art Formal Benchmark recorded in
`P0-FT1_formal_interceptor_tower_benchmark.md`. Complex projectile particles
and projectile hit-feedback grammar remain blocked until that review is
explicitly GO.
