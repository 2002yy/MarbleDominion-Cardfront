# Cardfront Projectile Readability Grill Decisions

Date: 2026-08-19

Decision baseline: `e6954de`

Implementation baseline: `dc46d35`

Evidence checkpoint: `faa152d`
Status: **DECISIONS LOCKED / PG1 EVIDENCE COMPLETE / PRODUCT-OWNER PROJECTILE-ONLY GO NOT RECORDED**

This Markdown file is the content authority. The sibling DOCX is a formatted
mirror. The original DOCX contained a damaged `word/document.xml` CRC and was
rebuilt from this source on 2026-08-20.

## 1. Goal And Boundary

D13 HQ Damage States was closed before this interview. The next P0 dynamic
readability question was projectile identity: what type a projectile is, which
faction owns it, and whether that information survives paused frames, bounces,
overlap, low quality, and hidden trails.

The Grill did not authorize new projectile mechanics, balance changes, hero or
AI changes, formal GLBs, or complex impact/VFX production.

## 2. Problem Diagnosis

The runtime already differentiated Standard, Siege, and Suppression through
radius, trail width/length, and primitive shape. Color still carried too much
type meaning:

- blue/red needed to remain the faction identity channel;
- cyan Suppression weakened AI/red ownership recognition;
- orange Siege competed with the D3 warm-orange critical HQ core;
- trails and motion disappear in paused frames and can be hidden by overlap.

## 3. Locked Decisions

### D1 — Dual-Channel Encoding (Option C)

- **Type Body / Silhouette** answers what the projectile is.
- **Faction Rim** stays player blue or AI red and is never replaced by type hue.
- **Faction Trail** stays faction-colored; length and width may reinforce type.
- Type color is secondary and may not overpower faction identity.

Implementation update: `dc46d35` landed D1 using body silhouette/size for type
and shape-matched outer rim plus trail for faction.

### D2 — Special Projectiles Must Read In One Frame (Option A)

At the default 112% camera, hiding trails and pausing on an arbitrary frame
must still distinguish all three types:

- Standard: simplest round baseline.
- Siege: visibly larger, heavy, non-round structure.
- Suppression: flat disc/ring or layered-disc silhouette.
- Motion, trail, and color reinforce identity but cannot be the only channel.

### D3 — Primitive Validation Before Formal GLB (Option A)

Use Godot primitives to lock screen-space ratios before committing formal asset
production. Primitive work proves information structure; GLB work may improve
quality only after the structure survives the camera and density gates.

## 4. Rejected Alternatives

| Alternative | Decision |
| --- | --- |
| Faction-only grammar | Safe ownership but insufficient special-type identity. |
| Type-first full-body recolor | Rejected; causes AI Suppression ownership loss and orange semantic collision. |
| Immediate formal GLB | Deferred until screen-space structure is validated. |
| Standard primitive plus immediate special GLBs | May be reconsidered only after PG1 evidence. |

## 5. PG1 Evidence Contract And Result

Required configurations:

- `1120x720 @ 100%`
- `1120x720 @ 112%`
- `760x540 @ 112%`

Required scenarios per configuration:

1. Trail OFF: one frozen projectile for every faction/type pair.
2. Trail ON: the same six projectiles with faction trails.
3. Volley: eighteen real pooled projectiles, three of each faction/type pair.

Evidence result at `faa152d`:

- Arena: 121 PASS
- Battlefield scale: 57 PASS
- Mode smoke: 38 PASS
- Capture manifests: 3/3 PASS
- Required PNGs: 9/9 generated
- AI full-resolution visual review: PASS for the tested grammar

The product-owner projectile-only screenshot GO was not recorded in the
checkpoint. Implementation and evidence completion must not be rewritten as a
separate human acceptance decision.

## 6. Current Presentation Contract

- `ProjectileRoot / TypeBody`: projectile type.
- `FactionRim`: persistent faction channel.
- `FactionTrail`: faction channel; geometry may reinforce type.
- Standard remains round and visually quiet.
- Siege uses a warm-gray heavy body, not the D3 critical orange semantic.
- Suppression uses a cool-gray flat body, not a full cyan faction-confusing wash.
- Simulation, collision, trajectory, AI, damage, and balance remain unchanged.

## 7. Deferred Follow-Up

Impact feedback remains a separate Grill gate. Before formal projectile GLBs
or complex hit VFX, decide whether impact frames preserve dual encoding or
temporarily prioritize mechanism meaning.
