# Project Status / 项目状态

Last updated: 2026-07-28

This is the only document that tracks the current version, completed work, active implementation slice, next step, and deferred scope.
本文件是项目当前版本、已完成内容、正在实施内容、下一步和暂缓范围的唯一状态入口。

## 1. Current Direction / 当前方向

Cardfront is being rebuilt toward the following single-match 1v1 physics strategy roguelite flow. This is the approved target flow, not the current complete player-facing runtime:

> 地图选择 -> 玩家选择英雄 -> 展示 AI 英雄 -> 展示双方基础属性 -> 开始对局 -> 调整炮口方向 -> 倒计时结束 -> 全场暂停 -> 三选一强化 -> 超时随机 -> 双方结算 -> 自动齐射 -> 争夺路线并摧毁敌方控制舱

Confirmed product decisions:

- First mode is player versus AI, with two factions only.
- During the first implementation stage, the player controls firing direction only.
- The world fully pauses during the three-choice draft; draft timeout continues in real time.
- Timeout chooses one of the offered upgrades at random.
- `+5` and `x2` affect the next volley only.
- Attack level, territory-defense cap, and rarity upgrades persist for the current match; base volley does not grow permanently.
- Echo repeats the next selected upgrade once in the following round instead of duplicating it in the same round.
- The primary win condition is destroying the enemy command chamber.
- Territory supplies routes, defense, gate control, stronghold control, and firing advantages; territory percentage is not the primary victory condition.
- The authoritative game state and projectile simulation remain 2D; the orthographic 3D layer is presentation-only.
- New upgrades should primarily change projectile routing, capture behavior, volley distribution, and post-capture fortification instead of adding larger flat numbers.

### Current Player-Facing Reality / 当前玩家可见状态

- The current implementation branch includes the B1 route, projectile,
  simulation-parity, typed-projectile, and first formal entity/building-card
  slices.
- Starting Cardfront from the normal menu opens a formal three-step deployment flow: map selection, player hero selection, then AI reveal and matchup confirmation.
- All three registered maps are selectable and the chosen `map_id` now drives the live `RegionMap`, not only simulation.
- The reveal screen presents both heroes' base volley, chamber health, defense capacity, and strategic trait before battle.
- Each hero has a compact cartoon silhouette, accent color, selection card, press/reveal animation, and an in-match identity plate.
- The orthographic arena has a first-generation environment-art pass: map-specific palettes plus green-field banners, industrial stacks, or laboratory pylons. It is no longer a single-palette graybox, though bespoke meshes, textures, and polish remain future art work.
- Existing legacy card illustrations and compatibility UI do not count as art completion for the new three-choice hero/run loop.

### Approved Art Direction / 已批准美术方向

The approved visual target is:

> **明亮玩具沙盘 + 清晰竞技路线 + 粗轮廓占领块**

The arena should feel bright, open, readable, and tactile. It must not return to
the compressed dark-gray prototype look, and it must not become a noisy
cyberpunk HUD or a realistic military battlefield.

Reference responsibilities:

- [Clash Royale](https://supercell.com/en/games/clashroyale/): learn from its
  vertical arena composition, immediately visible opposing cores, and natural
  separation created by the river and bridges.
- [Minion Masters](https://store.steampowered.com/app/489520/Minion_Masters/):
  learn from its oblique depth, opposing bases, and readable pressure around
  the central routes.
- [Into the Breach](https://store.steampowered.com/app/590380/Into_the_Breach/):
  learn from the absolute clarity of tile ownership, attack routes, danger,
  and state changes.
- [Bad North](https://store.steampowered.com/app/688420/Bad_North/): learn from
  its low-poly terrain, soft bright lighting, simplified architecture, and
  strong silhouettes.

These games are references for composition and readability, not templates to
copy. Cardfront must retain its own visual identity:

- bright marble trajectories;
- thick, clearly separated ownership blocks;
- two authoritative bridge gates;
- a visible player-versus-AI command-chamber confrontation;
- territory state that remains readable while projectiles are moving.

### Approved Asset Stack / 已批准资源组合

**Primary environment skeleton: KayKit Medieval Hexagon**

- Use its 200+ stylized buildings, terrain pieces, and props as the fastest
  route to a coherent readable battlefield.
- Prefer the included blue/red faction variations and shared gradient atlas.
- License: CC0.
- Sources:
  [KayKit official page](https://www.kaylousberg.com/game-assets/medieval-hexagon),
  [Godot package](https://godotengine.org/asset-library/asset/2900).

**Walls, bridges, gates, and command chambers: Kenney Castle Kit + Mini Arena**

- Use selected pieces for turret bases, walls, bridge structures, gate
  machinery, flags, and map-edge construction.
- Do not import either pack wholesale into every scene.
- License: CC0.
- Sources:
  [Castle Kit](https://kenney.nl/assets/castle-kit),
  [Mini Arena](https://kenney.nl/assets/mini-arena),
  [Kenney license guidance](https://kenney.nl/support).

**Peripheral nature: Quaternius Stylized Nature MegaKit**

- Use trees, rocks, bushes, and ground accents only around the outer frame of
  the battlefield.
- Keep the playable grid, bridge approaches, projectile lanes, and command
  chambers visually clear.
- The pack provides glTF assets and a Godot implementation.
- License: CC0.
- Source:
  [Quaternius official pack page](https://quaternius.com/packs/stylizednaturemegakit.html).

**Chinese typography: Noto Sans SC**

- Use Black or Bold for titles, hero names, major percentages, countdowns, and
  large combat numbers.
- Use Medium for descriptions, secondary stats, hints, and normal HUD text.
- License: SIL Open Font License; the font may be bundled with the game under
  its license terms.
- Source:
  [Noto official usage and license guidance](https://notofonts.github.io/noto-docs/website/use/).

### Art Integration Rules / 美术接入规则

- Do not mix the raw appearance of three asset packs in the same scene. Route
  imported meshes through one Cardfront material palette, one lighting setup,
  and one outline/bevel language.
- Prefer glTF/GLB for imported 3D assets. Imported art remains presentation
  only and must not become authoritative projectile, gate, capture, or
  collision state.
- Keep environment paths in a dedicated registry with explicit fallbacks. Do
  not scatter asset paths through `Main.gd`, gameplay systems, or individual
  effect handlers.
- Preserve the current 2D authoritative simulation. The orthographic 3D arena
  mirrors ownership, defense, gates, projectiles, chambers, and effects.
- Use strong faction identity without flooding entire tiles with saturated
  color: blue/red inset borders, raised rims, corner markers, and restrained
  surface tint should work together.
- Neutral cells require their own warm or natural value range and must not be
  confused with an unlit faction tile.
- Territory borders must remain visible for isolated and scattered captured
  cells, not only for large connected regions.
- River water, bridge decks, gate machinery, command chambers, projectiles,
  and ownership borders must occupy distinct value and hue ranges.
- Decorative foliage and structures belong mainly outside the playable core.
  They must not hide bridge entrances, projectile contacts, target previews,
  or the thick ownership outlines.
- Every imported pack, modified asset, font, and license must be recorded in
  the existing asset-source and license documentation before release.

### First Art Benchmark / 首个正式美术标杆

Do not attempt to finish all three maps at once. The first art-production slice
must complete `default_duel` as the benchmark scene before the industrial and
laboratory maps inherit the same material language.

The `default_duel` benchmark includes:

- bright grass and readable terrain variation;
- modeled river banks instead of a flat color strip;
- two visually substantial bridge gates aligned with authoritative routes;
- distinct blue and red command chambers outside the central play space;
- thick, cartoon-like ownership blocks with clear faction and neutral states;
- unified sunlight, ambient fill, shadows, and color grading;
- restrained rocks, trees, flags, walls, and arena-edge dressing;
- high-contrast marble trajectories and hit/capture feedback;
- compact HUD and hero plates that do not cover the arena.

Benchmark acceptance:

- At first glance, a player can identify both command chambers, the river, both
  legal crossings, and the current front line.
- Blue, red, and neutral scattered cells remain distinguishable without
  reading labels.
- Ownership borders remain clear during volleys and do not flicker or disappear
  at oblique camera angles.
- The arena reads as bright and expanded rather than dark, compressed, or
  surrounded by heavy UI.
- Desktop `1120x720` and a narrow/mobile viewport both preserve the core routes
  and do not overlap critical HUD with the battlefield.
- Before/after screenshots are captured from deterministic camera states and
  reviewed side by side.
- The benchmark remains inside the existing arena performance budget.
- Only after this benchmark is accepted should the same art system expand to
  Cross Strongholds and Central Lab.

## 2. Hero Numeric Baseline / 三英雄数值基线

The current public baseline is:

| Hero | Base volley | Chamber health | Ordinary starting defense | Contact-front starting defense | Defense cap | Strategic identity |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Balanced Commander / 均衡指挥官 | 6 | 40 | 1 | 1 | 1 | Broad card compatibility |
| Rapid Gunner / 连射炮手 | 7 | 36 | 1 | 1 | 1 | Multiplier and burst value |
| Fortification Engineer / 筑垒工程师 | 5 | 42 | 1 | 2 | 2 | Pre-built contact front and position management |

Locked Engineer opening rule:

- The contact front means initially owned cells orthogonally adjacent to neutral or enemy territory.
- On the current horizontal spawn layout, this is the full row facing the neutral center.
- Engineer contact-front cells begin at `2/2`.
- Other Engineer starting territory begins at `1/2`.
- Balanced Commander and Rapid Gunner captures begin at zero defense.
- Fortification Engineer's first capture of a neutral frontline cell begins at
  `1/2` once per cell; later recaptures of that cell begin at `0/2`.
- Raising the cap does not refill current defense.
- The opening contact front is detected and applied once during match initialization.
- Later frontline movement never creates a new free two-layer line.

Hero state layers:

- Identity: hero ID/name, base volley, chamber maximum health, ordinary starting defense, contact-front starting defense, and initial defense cap.
- Persistent run growth: permanent attack level `0..3`, defense cap up to 4, and rarity level `0..3`.
- Next-volley state: additive shot bonus, multiplier capped at `x2`, armor-piercing contacts, and future route/projectile modifiers.
- Delayed state: armed Echo and queued replay upgrade.
- World-authoritative state: chamber current health, per-cell defense, territory ownership, stronghold snapshot, gate snapshot, and aim direction.
- Planned read model: a read-only `CardfrontFactionCombatSnapshot` for UI, AI, and simulation without becoming a second authority.

Completed migration:

- Base volley comes from the selected hero at 5, 6, or 7 shots.
- Chamber health comes from the selected hero at 42, 40, or 36.
- Starting territory defense is seeded once and no longer refills automatically before every volley.
- Territory-defense hard cap is 4; Engineer starts with capacity 2.
- Engineer starts with a visible one-time `2/2` contact front while its interior remains `1/2`.
- Balanced Commander and Rapid Gunner captures begin at zero current defense.
- Fortification Engineer gains one defense layer on the first neutral
  frontline capture of each cell; enemy captures and Engineer recaptures begin
  at zero.
- Permanent attack growth uses levels `0..3`.
- Temporary effects may raise the resolved attack level to 4 for one volley.
- Echo queues and replays the next selected upgrade during the following round.
- Player and AI hero IDs can already be injected through runtime configuration.

Remaining hero work:

- Route-card valuation based on authoritative route and gate pressure.
- Read-only combat snapshot shared by UI, AI, and simulation.
- Replace first-generation vector silhouettes only if later art direction approves bespoke hero portraits; the current icons remain the readable fallback.

## 3. Attack And Defense Semantics / 攻防语义

### Attack

- Permanent attack level: `0..3`.
- Each level adds 25% chamber damage.
- Temporary attack effects may raise the resolved volley level to 4.
- Resolved damage sequence: `100% / 125% / 150% / 175% / 200%`.
- Level 4 is temporary only and is never written back into permanent run state.
- Live runtime and parity simulation use the level-4 temporary ceiling.

### Defense

- Global territory-defense cap belongs to hero identity and run growth.
- Hard cap is 4.
- Ordinary starting owned cells begin at `1 / hero cap`.
- Engineer contact-front cells are the only opening exception and begin at `2/2`.
- Balanced Commander and Rapid Gunner captures begin at `0 / current cap`.
- Fortification Engineer's first neutral frontline capture of a cell begins at
  `1 / current cap`; recaptures begin at zero.
- Increasing the cap does not refill current defense.
- An effective hostile hit removes one current-defense point; a later hit captures after defense reaches zero.
- Automatic full-map refill is removed.
- Frontline Repair restores at most 6 different owned frontline cells and adds exactly 1 defense point to each.
- One repair card never visits the same cell twice, even when fewer than 6 eligible cells exist.
- Repairing an exhausted former opening-front cell restores one layer; it does not recreate the free `2/2` opening bonus.

## 4. Current Upgrade Catalog / 当前强化池

| Upgrade | Rarity | Function |
| --- | --- | --- |
| Reinforced Volley / 增援齐射 | Common | Next volley `+5` |
| Double Volley / 双倍齐射 | Uncommon | Next volley `x2` |
| Attack Training / 攻击训练 | Uncommon | Permanent attack level `+1`, cap 3 |
| Thicken Position / 加厚阵地 | Common | Permanent defense cap `+1`, cap 4 |
| Frontline Repair / 前线修复 | Common | Repair up to 6 different frontline cells |
| Armor-Piercing Trajectory / 穿甲轨迹 | Uncommon | Ignore the first 6 defended contacts next volley |
| Rarity Premonition / 稀有预感 | Uncommon | Raise future high-rarity probability |
| Delayed Echo / 延迟回响 | Rare | Replay the next selected upgrade once next round |
| Siege Formation / 攻城编组 | Uncommon | Convert up to 2 standard projectiles next volley into siege projectiles |
| Suppression Formation / 压制编队 | Uncommon | Convert up to 2 standard projectiles next volley into suppression projectiles |

Catalog limits:

- Normal volleys remain at or below 24 shots.
- Explicit exceptional bonuses may reach 32 shots.
- Same-round multiplier stacking is disallowed.
- Do not prioritize flat additions such as `+8`, `x3`, or permanent `+50%` damage.

### Authoritative Content Inventory / 当前内容唯一确认清单

This section is the authoritative answer to "what content exists now." A
roadmap name, simulator candidate, legacy script, or tested prototype does not
count as formal player-facing content unless this section says it is active.

#### Active Formal Upgrade Pool / 正式启用强化池

The normal player-facing run uses `core_tactics`, containing exactly eighteen
upgrades:

| Upgrade | Rarity | Exact current behavior |
| --- | --- | --- |
| Reinforced Volley / 增援齐射 | Common | Next volley adds 5 standard projectiles. These bonus shots are appended after the hero base group and are not copied by Double Volley. |
| Double Volley / 双倍齐射 | Uncommon | Next volley copies the hero's complete typed base projectile group once. It does not stack above `x2`. |
| Attack Training / 攻击训练 | Uncommon | Permanent attack level `+1`, capped at level 3. Each level adds 25% chamber damage; temporary effects may resolve at level 4 for 200%. |
| Thicken Position / 加厚阵地 | Common | Permanent territory-defense cap `+1`, hard-capped at 4. Existing cells are not refilled. |
| Frontline Repair / 前线修复 | Common | Repairs up to 6 distinct owned frontline cells by 1 layer each. Engineer receives 2 additional repair points, for up to 8 distinct repairs when targets exist. |
| Armor-Piercing Trajectory / 穿甲轨迹 | Uncommon | The first 6 defended contacts in the next volley ignore one defense layer. |
| Rarity Premonition / 稀有预感 | Uncommon | Permanent rarity level `+1`, capped at level 3, increasing later high-rarity offer probability. |
| Delayed Echo / 延迟回响 | Rare | Arms the next selected upgrade; that upgrade resolves normally, then replays once in the following round. |
| Siege Formation / 攻城编组 | Uncommon | Converts up to 2 standard projectiles in the next volley into siege projectiles; special projectiles fire before standards. |
| Suppression Formation / 压制编队 | Uncommon | Converts up to 2 standard projectiles in the next volley into suppression projectiles; these increase route pressure but cannot damage the command chamber. |
| Repair Units / 维修单位 | Common | Summons 2 friendly Repair Units. Each has 1 HP, movement 1, lasts 3 owner rounds, seeks damaged friendly frontline cells, and restores 1 defense layer when adjacent. One cell can receive at most one creature repair per round. |
| Fire-Control Beacon / 火控信标 | Uncommon | Builds or upgrades one fixed-slot beacon, maximum level 3. It has 5 HP and guides 6/8/10 standard projectiles per volley. Levels 2/3 maintain one 1-HP scout with a 3/2-round respawn; the scout lightly corrects up to 3 nearby standard projectiles per volley. |
| Interceptor Tower / 拦截塔 | Uncommon | Builds or upgrades one fixed-slot 4-HP tower, maximum level 3. It intercepts the first 2/3/3 enemy standard projectiles each volley; level 3 fires one standard counter-projectile after exhausting its quota. Siege and suppression projectiles are not intercepted. |
| Building Volley / 建筑齐射 | Rare | Permanent level 1-3. Every powered friendly defense tower independently fires 2/3/4 standard projectiles from its route slot. These shots are not copied by `+5` or `x2`; combined command-chamber and building shots cap at 32. Requires at least one friendly tower before it can be offered. |
| Heavy Charge / 重型装药 | Rare | Arms the next volley. Its first non-intercepted enemy defense-tower contact resolves normal projectile damage, then adds 1 center structure damage, deals 1 damage to other enemy entities within Manhattan radius 2, and removes 1 defense layer from enemy cells within radius 1. It never directly damages the command chamber. |
| Armored Guard / 装甲护卫 | Uncommon | Summons 1 permanent friendly armored creature with 4 HP and movement 1. It advances toward the nearest owned gate entrance or contested frontline and physically blocks hostile projectiles. Standard hits deal 1 damage and bounce; siege hits deal 2 damage and are consumed. It grants no territory damage reduction. |
| Sapper Unit / 掘城单位 | Uncommon | Summons 1 permanent friendly armored creature with 3 HP and movement 1. It crosses the river only through a gate that is not closed against its faction, prioritizes enemy defense towers, then the highest-defense enemy cell, then the command chamber. Contact deals 3 tower damage, removes up to 2 cell-defense layers, or deals exactly 1 chamber damage, then the Sapper self-destructs. |
| Awaken Gate Colossus / 唤醒闸门巨像 | Rare | Once per faction per run, summons one neutral 6-HP armored creature occupying 2 creature slots. It moves 1 cell per round, crosses only non-closed gates, and attacks the current territory leader. It prioritizes towers, then defended cells, then the chamber; each action deals 2 tower damage, removes 1 defense layer, or deals 1 chamber damage. It does not self-destruct, and projectiles from both factions damage it. |

Runtime boundary:

- The normal live run state defaults to `core_tactics`.
- The pre-match screen does not currently expose deck selection.
- Normal volleys cap at 24 projectiles; explicitly exceptional paths may cap at
  32.
- Special projectiles fire before the standard segment so their route effect is
  visible.

Candidate deck definitions:

- `core_tactics`: the active default eighteen-card pool.
- `fortification_corps`: an implemented Engineer-oriented candidate containing
  Siege Formation, the six entity cards, Building Volley, and Heavy Charge.
- `barrage_control`: an implemented Gunner-oriented candidate containing
  Suppression Formation.
- Candidate decks remain audit/configuration content. They are not selectable
  from the formal pre-match screen and are not promoted merely because their
  tests pass.

#### Legacy Targeted Cards / 旧目标式卡牌

The earlier click-a-card-then-click-a-target system still contains four cards
for compatibility and regression coverage. The new live three-choice run does
not construct the legacy `CardPlaySystem`, so these are not part of the current
formal match loop:

| ID | Card | Cost | Target and effect |
| ---: | --- | --- | --- |
| 1001 | Frontline Fortify / 前线加固 | 10 energy, 3 parts | Owned border cell; adds 3 fortification stacks. |
| 1002 | Calibrated Shot / 校准射击 | 8 energy, 5 parts | Enemy region; prioritizes that region for 6 seconds. |
| 1003 | Morale Fluctuation / 民心起伏 | 5 energy, 2 parts | Owned region; applies the player-support morale mode. |
| 1004 | Pioneer Beacon / 拓荒信标 | 8 energy, 4 parts | Owned border cell; converts up to 3 adjacent neutral cells. |

These four cards must not be counted when describing the active three-choice
upgrade catalog, and their old energy/parts economy must not be reintroduced
into the new loop by accident.

#### Active Hero Baseline / 正式英雄与精确数值

| Hero | Base projectile group | Chamber HP | Starting defense | Contact-front defense | First neutral frontline capture | Repair bonus | Defense cap |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Balanced Commander / 均衡指挥官 | 6 standard | 40 | 1 | 1 | 0 | 0 | 1 |
| Rapid Gunner / 连射炮手 | 6 standard + 1 suppression | 36 | 1 | 1 | 0 | 0 | 1 |
| Fortification Engineer / 筑垒工程师 | 4 standard + 1 siege | 42 | 1 | 2 | 1, once per neutral cell | +2 Frontline Repair points | 2 |

Projectile semantics:

- Standard: 1 chamber damage unit; deals 1 damage to creatures or towers and
  normally bounces from them.
- Siege: 2 chamber damage units, pierces 1 territory-defense layer, deals 1 to
  normal creatures, 2 to armored creatures, and 3 to defense towers; consumed
  on entity contact.
- Suppression: cannot damage the command chamber or creatures; contributes
  stronger territory/route pressure, stuns and pushes creatures for one round,
  and disables defense towers for one round.
- Double Volley copies the hero's typed base group. For example, Engineer
  receives two siege projectiles and Gunner receives two suppression
  projectiles before caps and conversions.

#### Battlefield Entities / 战场生物与建筑实体

The shared entity runtime is active and the first formal creature/tower cards
are now part of the live three-choice pool.

Implemented foundation rules:

- Maximum 3 creatures per faction.
- Maximum 2 defense towers per faction.
- Maximum 2 creature slots per cell.
- Creatures support normal or armored defense, HP, movement, behavior, timed
  duration, stun, push, projectile collision, and round actions.
- Defense towers support HP, power from tile ownership, interception, summoning,
  trajectory guidance, disable state, and fixed map building slots.

Implemented formal entities:

| Entity | Current values | Status |
| --- | --- | --- |
| Repair Unit / 修复单位 | 1 HP, normal armor, movement 1, `repair_frontline`, lasts 3 rounds, restores 1 defense layer to a nearby eligible frontline cell per action. | Formal Common card; summoned in pairs. |
| Armored Guard / 装甲护卫 | 4 HP, armored, movement 1, `guard_frontline`, permanent until destroyed; advances toward the nearest owned gate entrance or contested frontline and blocks projectiles without granting territory reduction. | Formal Uncommon card; summoned singly. |
| Sapper Unit / 掘城单位 | 3 HP, armored, movement 1, `sapper_assault`, permanent until destroyed or detonated; respects gate closure, then deals 3 tower damage, removes up to 2 defense, or deals 1 chamber damage before self-destructing. | Formal Uncommon card; summoned singly. |
| Gate Colossus / 闸门巨像 | Neutral owner, 6 HP, armored, movement 1, size 2, `neutral_gate_colossus`; attacks the current territory leader and remains until destroyed. Both factions' projectiles collide with it. | Formal Rare card; each faction may awaken one per run. |
| Fire-Control Beacon / 火控信标 | 5 HP, guides 6/8/10 standard projectiles by level; level 2/3 maintains one scout with 3/2-round respawn. | Formal Uncommon building card. |
| Scout / 侦察单位 | 1 HP; maintained by level 2/3 beacon; lightly corrects up to 3 nearby standard projectiles each volley. | Generated by the beacon, not independently draftable. |
| Interceptor Tower / 拦截塔 | 4 HP; intercepts 2/3/3 standard projectiles by level; level 3 counterfires after exhausting quota. | Formal Uncommon building card. |

Creature and defense-tower card-pool decision:

- **Neutral creature:** Gate Colossus is the first formal third-party battlefield
  presence. It uses neutral allegiance, attacks the current territory leader,
  and can be damaged by both factions. Its generated 256px runtime animation set
  provides `idle`, `move`, `attack`, `hit`, and `death` states. The presentation
  actor uses Tween movement and a strict
  `death > hit > attack > move > idle` priority without applying gameplay
  damage from animation callbacks. `CardfrontEntityVisualRegistry` owns every
  frame path, while the static sprite and procedural silhouette remain
  missing-resource fallbacks.
- **Friendly creature:** approved direction is a medium-strength faction-owned
  unit with construction synergy. Repair Units and the Armored Guard now provide
  formal player-facing summon upgrades with distinct support and blocking roles.
- Creature summons and defense-tower construction/upgrades are confirmed as
  **future three-choice card-pool content**, not a separate out-of-pool system.
- Repair Units, Armored Guard, Sapper Unit, Gate Colossus, Fire-Control Beacon,
  and Interceptor Tower are offered by the current formal pool.

Confirmed future card-pool inventory:

| Card or card family | Current proposed values and behavior | Lock status |
| --- | --- | --- |
| Repair Unit Card / 维修单位卡 | Summon 2 friendly normal units; 1 HP each; movement 1; last 3 owner rounds; seek the nearest damaged friendly frontline cell and restore 1 defense when adjacent; each cell can receive at most one creature repair per round. | Implemented; Common. |
| Armored Guard Card / 装甲护卫卡 | Summon 1 permanent friendly armored unit; 4 HP; movement 1; move toward the nearest owned gate entrance or contested frontline and physically block projectiles; grants no extra territory damage reduction. | Implemented; Uncommon. |
| Sapper Unit Card / 掘城单位卡 | Summon 1 permanent armored unit; 3 HP; movement 1; respect gate closure and prioritize enemy towers, then the highest-defense enemy cell, then the command chamber; deal 3 structure damage to a tower and self-destruct, remove up to 2 defense from a cell and self-destruct, or deal only 1 chamber damage and self-destruct. | Implemented; Uncommon. |
| Awaken Gate Colossus / 唤醒闸门巨像 | Rare; once per faction. Summon one neutral 6-HP armored size-2 creature with movement 1. It crosses only non-closed gates and attacks the current territory leader, prioritizing towers, defended cells, then the chamber. It deals 2 tower damage, removes 1 defense, or deals 1 chamber damage per action and remains until destroyed. Both factions can shoot it. | Implemented with generated five-state runtime animation, static-sprite fallback, and procedural fallback. |
| Fire-Control Beacon Card / 火控信标卡 | Builds in a fixed tower slot. Level 1: 5 HP and guides the first 6 standard projectiles each volley. Level 2: guides 8, maintains 1 scout creature, respawns it after 3 owner rounds, and the scout gives a second light correction to up to 3 nearby standard projectiles. Level 3: guides 10 and reduces scout respawn to 2 rounds. Duplicate cards upgrade the existing tower instead of creating unlimited copies. | Implemented; Uncommon. |
| Interceptor Tower Card / 拦截塔卡 | Builds in a fixed tower slot; 4 HP. Level 1 intercepts the first 2 enemy standard projectiles per volley; level 2 intercepts 3; level 3 still intercepts 3 and fires 1 standard counter-projectile after using the full quota. Does not intercept siege or suppression projectiles. | Implemented; Uncommon. |
| One-shot Chamber Facility / 一次性控制舱设施 | On the first chamber-HP threshold crossing, resolves current damage, grants brief invulnerability, consumes subsequent enemy projectiles, emits a radial standard-projectile counterattack, then disappears after the enemy volley or a time limit. | Card-family concept confirmed; threshold, duration, counter-shot count, name, and rarity TBD. |
| Generic Summoner Tower / 通用召唤塔 | Fixed-slot tower that summons a configured creature on a round interval. | Engine capability and future card family confirmed; no formal card definition or values yet. |

All creature and tower cards obey the shared foundation unless a later card
explicitly overrides it: maximum 3 creatures and 2 defense towers per faction,
maximum 2 creature slots per cell, friendly projectiles pass through friendly
entities, and an entity on enemy-held ground cannot remain normally powered.

#### Explicitly Paused Content / 明确暂缓内容

The following are approved concepts but are **not current implementation
targets**:

| Upgrade | Rarity | Approved behavior |
| --- | --- | --- |
| Vanguard Warhead / 先锋弹头 | Common | First 4 projectiles continue after their first capture and may capture one additional cell |
| Gate Breach Round / 破门弹 | Uncommon | First 4 rejected gate crossings become valid bridge passages; off-bridge river crossing remains blocked |
Bridgehead Construction and Bridgehead Fortification are removed. Their
defensive role overlaps Frontline Repair and they are not reserved for a later
pool.

#### Confirmed Entity Card Slice / 已确认实体牌切片

Implementation order:

Completed in the current slice:

1. Repair Units.
2. Fire-Control Beacon.
3. Interceptor Tower.
4. Building Volley.
5. Heavy Charge.
6. Armored Guard.
7. Sapper Unit.
8. Gate Colossus.

The first neutral-creature slice is complete. Further card expansion pauses
until the coupling closeout below and a live playtest of the eighteen-card pool.

#### Coupling Audit / 耦合审计（2026-07-28）

Current measured hotspots:

| Priority | Module | Current size | Judgment and required boundary |
| --- | --- | --- | --- |
| P0 | `CardfrontBattlefieldEntityRuntime.gd` | 1066 lines / 57 functions | Still the largest new coordinator. Sapper targeting, neutral AI, and shared gate navigation are now extracted, but projectile contact, heavy-charge splash, tower volleys/guidance, repairs, tower summons, and lifecycle cleanup remain combined. Before adding another entity family, split `CardfrontEntityProjectileBridge`, `CardfrontTowerRuntime`, and `CardfrontCreatureActionCoordinator`; target the coordinator below 650 lines. |
| P1 | `CardfrontBalanceMatchSimulator.gd` | 702 lines / 26 functions | Upgrade application and eligibility switches duplicate the B1 deck simulator. Introduce a shared simulation upgrade adapter before another card batch so live and audit models cannot drift independently. |
| P1 | Manifest/deck/draft/value chain | 330-line Manifest plus multiple registries | Adding one card still requires synchronized edits across Manifest, deck registry, draft eligibility, live resolver, two value policies, and two simulators. The next content-foundation pass should centralize eligibility and simulation metadata instead of growing parallel `match` lists. |
| P2 | `CardfrontRoundDirector.gd` | 461 lines / 33 functions | Acceptable as a phase coordinator. Do not move entity targeting, collision, visuals, or card-specific effects into it. |
| P2 | `CardfrontMode.gd` | 345 lines / 38 functions | Current builder delegation keeps it manageable. Continue moving construction details into builders rather than adding another UI/runtime family directly. |

Completed coupling reduction in this slice:

- `CardfrontSapperSystem.gd` owns Sapper targeting and demolition.
- `CardfrontNeutralCreatureSystem.gd` owns neutral allegiance, target selection,
  movement, and attacks.
- `CardfrontEntityGateNavigator.gd` is the single creature gate-crossing policy
  used by both systems.
- `CardfrontEntityVisualActor.gd` owns presentation-only animation and smooth
  cell-to-cell movement. `CardfrontEntityDebugLayer.gd` routes runtime signals
  to actors without moving damage or lifecycle authority out of the entity
  runtime.

Heavy Charge / 重型装药 is locked as a Rare next-volley combo card:

- It arms the first projectile in the next volley that physically contacts an
  enemy defense tower; if no tower is hit, the charge expires with the volley.
- Resolve the projectile's normal hit first, then explode at that tower cell.
- The center tower receives 1 additional structure damage.
- Other enemy creatures or defense towers within Manhattan radius 2 receive 1
  damage.
- Enemy territory cells within Manhattan radius 1 lose 1 current-defense layer,
  never below zero.
- The explosion cannot damage either command chamber.
- A standard projectile plus Heavy Charge deals 2 total damage to its center
  tower. A siege projectile plus Heavy Charge deals 4, so the card cannot
  unconditionally destroy a healthy 4-HP tower but can do so through the
  explicit Siege Formation combination; a 5-HP Fire-Control Beacon survives
  that clean two-card combo at 1 HP.

- `v0.3.3b2 Four-card Route Module` is paused until the user explicitly
  reactivates it.
- `v0.3.3b3` and its expanded 108,000-match A/B audit are paused.
- Candidate-deck promotion, hero-number changes, and hard balance gates must not
  wait on or silently trigger either paused slice.

## 5. Strongholds And Timeout / 据点与超时

- Factory: next volley `+3` shots.
- Energy: next volley gains one temporary attack level and may raise permanent level 3 to resolved level 4.
- Laboratory: draft four upgrades and choose one.
- Destroying the enemy chamber is an immediate win.
- Timeout score: `50% normalized chamber health + 35% territory + 15% strongholds`.

## 6. Completed Slices / 已完成阶段

### v0.3.3a — Authoritative Gate Connectivity

- Two bridge gates are authoritative projectile routes.
- Below 55% control: open to both factions.
- At 55%–79%: owner passes all shots; enemy shots alternate between passage and reflection.
- At 80% or more: owner passes all shots; enemy shots reflect.
- Off-bridge river crossings reflect from the river bank.
- Gate state is sampled and locked at round boundaries.
- 3D gate presentation mirrors the locked 2D authority.

### v0.3.3a1 — Temporary Attack And Strict Repair

Status: completed and merged to `main` at commit `748b826`.

- Added a shared resolved attack ceiling of level 4 while preserving permanent cap 3.
- Energy can produce 200% chamber damage for one volley at permanent level 3.
- Frontline Repair now makes one pass over candidates.
- A six-point repair restores fewer than six points when fewer than six different eligible cells exist.

### v0.3.3a2 — Explicit Historical And Parity Simulation Modes

Status: completed and merged to `main` at commit `a2d004c`.

- `historical_compensated`: preserves hidden hero hit-rate compensation and resolved attack cap 3 so the original audit remains reproducible.
- `parity_uncompensated`: disables hidden hero accuracy and uses temporary resolved attack cap 4.
- Match and report output identifies simulation mode, compensation state, and attack ceiling.
- Historical 54,000-match gate remains merge-blocking.

### v0.3.3a3 — Full B0 Cloud Audit And Map Strategy Specification

Status: completed and merged to `main` at commit `a8b41c4`.

- Added a dedicated full 54,000-match B0 cloud runner and downloadable artifact.
- Recorded exact B0 evidence.
- Defined the first three strategic map identities.
- Split unstable sequential vertical-slice tests into independent CI jobs.

### v0.3.3a4 — Engineer Opening Contact-Front Fortification

Status: completed in PR #6; full repository CI passed before merge.

- Added data-driven `starting_contact_front_defense` to hero definitions and run state.
- Locked Engineer values at 5 volley, 42 health, ordinary defense 1, contact-front defense 2, and cap 2.
- Detects initially owned cells orthogonally adjacent to neutral or enemy territory.
- Applies the opening bonus once and stores the initial-front snapshot.
- Does not dynamically fortify newly exposed inner rows.
- Preserves capture and recapture at zero defense.
- Preserves one-point repair behavior.
- Added initialization, consumption, capture, recapture, repair, no-refill, and overlay-visual tests.
- Historical A and provisional B0 audits remain unchanged because this live per-cell rule is intentionally deferred from the proxy simulator until B1.

### v0.3.3a5 — Shared Marginal Upgrade Value Policy

Status: completed in PR #7; the 5,400-match shared-AI proxy audit and full repository Headless suite passed before merge.

- Replaced the live AI fixed score table with `CardfrontUpgradeValuePolicy`.
- Live runtime values real added shots, cap waste, expected chamber hits, real repairable cells, defended contacts, fillable defense capacity, remaining drafts, and delayed Echo replay.
- Fast simulation accepts equivalent dictionary state and calls the same value policy.
- Historical audit replay remains available through the explicit `historical_fixed` mode; its old constants are not used by current live AI.
- Per-offer reports expose score, immediate value, persistent value, delayed value, actual consumption, and waste.
- Dedicated tests cover hero-specific volley margins, repeated multiplier waste, near-cap waste, repairable-cell count, armor-piercing demand, rarity timing, Echo, live/simulator state equivalence, and live draft integration.

## 7. Balance Audit Status / 平衡模拟状态

### Historical A Baseline

Matrix: `3 heroes x 3 enemy heroes x 3 maps x 2 reported sides x 1000 seeds = 54,000`.

- Balanced Commander: `51.46%`.
- Fortification Engineer: `49.09%`.
- Rapid Gunner: `49.45%`.
- Ordered matchup range: `47.62%..53.70%`.
- Mirror position rates: `49%..51%`.
- Median: 22 rounds.
- P90: 34 rounds.
- Timeout: `12.25%`.
- First stronghold: round `6.03`.
- Cells crossed per marble: `19.25`.
- Chamber hits per volley: `1.231`.
- Defense absorbed per volley: `2.271`.
- Invalid offers: zero.

Boundary: this baseline includes hidden Engineer/Gunner hit-rate compensation, does not model authoritative gates, does not model Engineer contact-front fortification, and reports a synthetic second side by flipping the first result instead of rerunning geometry.

### Provisional B0 Cloud Audit

Status: completed in GitHub Actions on 2026-07-27. The audit artifact records all 54,000 matches.

Rules:

- Simulation mode: `parity_uncompensated`.
- Hidden hit compensation: disabled.
- Temporary resolved attack cap: 4.
- Historical eight-card catalog used by that completed audit; the live catalog
  has since promoted Siege Formation and Suppression Formation.
- Current proxy map profiles.
- No authoritative gate simulation yet.
- No true second-side geometry rerun yet.
- No Engineer opening contact-front fortification yet.

Results:

- Balanced Commander: `56.95%`.
- Fortification Engineer: `29.64%`.
- Rapid Gunner: `63.41%`.
- Balanced vs Engineer: `78.22%`.
- Balanced vs Gunner: `42.70%`.
- Engineer vs Balanced: `22.05%`.
- Engineer vs Gunner: `17.63%`.
- Gunner vs Balanced: `57.17%`.
- Gunner vs Engineer: `83.65%`.
- Mirrors remain approximately 50% because the current audit still flips the same result for the second reported side.
- Median: 22 rounds.
- P90: 34 rounds.
- Timeout: `13.53%`.
- First stronghold: round `6.03`.
- Cells crossed per marble: `19.25`.
- Chamber hits per volley: `1.189`.
- Defense absorbed per volley: `2.270`.
- Invalid offers: zero.

Interpretation:

- The hidden compensation materially carried the previous hero balance; it was not a harmless fine adjustment.
- Removing it exposed the Engineer as dramatically weak in the old proxy model and the Gunner as dramatically strong.
- B0 is not the result of the newly fortified Engineer because the proxy simulator does not yet represent per-cell opening defense.
- Do not change Engineer volley count or Gunner values from B0 alone.
- The next valid hero decision point is B1 after the new AI policy, real gates, real route geometry, true side reruns, and per-cell defense are represented.
- If the Engineer remains below 47% in valid B1 evidence, the next candidate is chamber health `42 -> 44`.

### Shared Marginal-AI Proxy Audit

Status: completed in GitHub Actions on 2026-07-27. Artifact run: `30236044493`.

Matrix: `3 heroes x 3 enemy heroes x 3 maps x 2 reported sides x 100 seeds = 5,400`.

Rules:

- Simulation mode: `parity_uncompensated`.
- Upgrade valuation mode: `marginal`.
- Hidden hit compensation: disabled.
- Temporary resolved attack cap: 4.
- Shared value policy was invoked for `178,632` simulated upgrade choices.
- Invalid offers: zero.

Results:

- Balanced Commander: `51.31%`.
- Fortification Engineer: `41.44%`.
- Rapid Gunner: `57.25%`.
- Balanced vs Balanced: `46.83%`.
- Balanced vs Engineer: `58.83%`.
- Balanced vs Gunner: `42.00%`.
- Engineer vs Balanced: `39.17%`.
- Engineer vs Engineer: `49.50%`.
- Engineer vs Gunner: `34.00%`.
- Gunner vs Balanced: `53.83%`.
- Gunner vs Engineer: `65.67%`.
- Gunner vs Gunner: `46.50%`.
- Reported mirror blue-side rates: exactly `50.00%` for all three heroes because the proxy still flips one result instead of rerunning geometry.
- Median: 16 rounds.
- P90: 22 rounds.
- Timeout: `0.15%`.
- First stronghold: round `5.99`.
- Cells crossed per marble: `19.20`.
- Chamber hits per volley: `1.514`.
- Defense absorbed per volley: `1.141`.

Interpretation and boundary:

- Sharing marginal valuation materially improves the old uncompensated proxy result for Engineer (`29.64% -> 41.44%`) and reduces Gunner from `63.41% -> 57.25%`, but Engineer remains below the future valid-B1 decision threshold.
- This is directional evidence about the AI-policy change only and must not be treated as B1.
- It still lacks authoritative per-map route geometry, gate passage/reflection, true second-side reruns, and per-cell defense including the Engineer opening contact front.
- Do not change hero base values from this 5,400-match proxy result.
- The next complete 54,000-match balance audit remains reserved for B1 after those systems are represented.

B1 risk monitoring for the full Engineer contact line:

- Timeout should remain within `10%..25%`.
- Median should not materially exceed 22 rounds.
- P90 should not exceed 34 rounds without a documented reason.
- First-stronghold timing and Engineer mirror stagnation must be reported.
- If the full line creates excessive delay, narrow the free `2/2` bonus to cells near the two bridge/control zones instead of removing the visible mechanic.

### B1 Opening And Archetype Calibration Framework

Status: implemented on the B1 branch; balance thresholds are diagnostic and do
not yet fail CI.

The new five-round opening audit:

- Runs both real side variants across all heroes and registered maps.
- Disables upgrades and stronghold bonuses to isolate hero base strength.
- Reports hero point rate and mirror blue-side rate.
- Reports early chamber damage, territory pressure, defense absorption, route
  passage/rejection, captures, and ending territory by hero.
- Records the intended `48%..52%` hero and `49%..51%` mirror ranges without
  enforcing them yet.

The 100-seed opening baseline (`5,400` matches) reports:

- Balanced Commander: `48.13%`.
- Fortification Engineer: `57.78%`.
- Rapid Gunner: `44.10%`.
- Mirror blue-side rates: Balanced `49.83%`, Engineer `50.83%`, Gunner `50.67%`.

Interpretation:

- The opening imbalance is primarily hero strength, not a large universal side
  advantage.
- Engineer defense absorption is already clearly differentiated.
- Gunner shot volume and route traffic lead, but that identity does not yet
  convert into acceptable opening points.
- This baseline is sufficient to identify the opening-strength direction, but
  thresholds remain diagnostic until the model contract and tuning procedure
  are accepted.

The full-match archetype evaluator now reports, without gating:

- Gunner shot volume and route pressure.
- Engineer defense absorption, bridgehead hold/recapture, and repair choice
  share.
- Balanced rarity choice share, Echo choice share, and build diversity.
- Intended archetype indicator lead of `20%..35%` with final hero rates inside
  `47%..53%`.

Required tuning order:

1. Keep live/simulation contracts green for gates, core upgrade effects, volley
   sequences, per-cell defense semantics, and shared AI valuation.
2. Stabilize the opening audit, then tune only health, base volley, or starting
   defense if needed.
3. Tune deck offer weights, exclusive effect strength, and AI marginal values
   for late-game archetype growth.
4. Promote diagnostic ranges to hard gates only after approved sample sizes are
   stable.

CI enforcement during this framework phase:

- The `5,400` directional audit gates complete map coverage, route telemetry,
  and target-diagnostic schema; current pacing ranges remain reported rather
  than merge-blocking.
- Selectable deck candidate CI gates complete scenarios, valid offers, card
  usage, and artifact output; a candidate is not promoted merely because the
  audit ran, and its balance must be tuned before becoming a live default.

## 8. Current Map Strategy Verdict / 当前地图策略判断

Blunt verdict:

> 三张地图已经可选并进入实时区域、桥梁和闸门装配，但当前仍主要依赖路线位置、据点布局和第一代程序配色表达差异；正式环境几何与玩家可直观复述的地图个性仍未完成。

Why:

- Three map definitions exist in the registry: Five Strongholds, Cross Strongholds, and Central Lab.
- Their stronghold shapes, route layouts, strategy profiles, and simulation values differ.
- The selected `map_id` now drives live `RegionMap` generation.
- Live gate crossing, control sampling, and orthographic bridge presentation use
  each map's authoritative `route_layout`.
- The formal pre-match screen exposes all three maps with route previews,
  identities, and opening hints.
- The current environmental distinction is still a first-generation palette
  and landmark pass rather than finished modeled terrain.
- Human playtest evidence has not yet established that a new player can explain
  each map's main route decision after one match.

Approved strategic map specification:

- `docs/CARDFRONT_STRATEGIC_MAP_DESIGN.md`

First three identities:

1. **Five Strongholds / 双桥均衡战线** — two equal routes; decide whether to split the volley or commit to one bridge.
2. **Cross Strongholds / 中央交叉火线** — bridges move inward; central occupation affects both routes and creates early collision pressure.
3. **Central Lab / 中央实验室·外翼绕行** — bridges move outward; choose between central draft power and stable outer route access.

Design rule:

- A map must change visible route geometry, objective relation, and the physics question.
- Map identity must not rely mainly on hidden `chamber_hit_chance`, `average_cells_crossed`, or other proxy multipliers.

## 9. Formal Pre-Match Flow / 正式开局流程

1. Map selection.
2. Player hero selection.
3. Reveal the AI hero.
4. Show both heroes’ base attributes.
5. Start the match.

Requirements:

- Map cards show route preview, bridge/gate count, stronghold composition, identity, and one opening hint.
- Hero cards show base volley, chamber health, ordinary starting defense, contact-front defense, cap, and strategic identity.
- Each first-generation hero card includes a simple authored emblem or cartoon silhouette, a distinct accent color, and clear selected/hover/locked states.
- The initial art pass may use vector shapes, icons, and existing licensed UI assets; it must not wait for generated character portraits.
- AI reveal reuses the same hero-card language so the matchup is readable before the battlefield is constructed.
- The battle HUD keeps a compact version of both hero identities visible without covering the arena.
- Mirror matches remain allowed.
- Confirmed map and hero IDs must enter runtime configuration before world construction.
- Desktop and narrow/mobile layouts require dedicated tests.

## 10. Upgrade And AI Architecture / 强化与 AI 架构

The live catalog has grown beyond the historical eight upgrades. Before adding
the approved entity/building card families, replace the expanding
`match effect_id` block with modular handlers:

- `VolleyEffect`
- `ProjectileEffect`
- `CaptureEffect`
- `GateEffect`
- `DefenseEffect`
- `DraftEffect`
- `DelayedEffect`

Live AI and the current fast-simulation adapter now use the shared `CardfrontUpgradeValuePolicy`. Fixed values such as `x2 = 92` remain only inside the explicitly labeled `historical_fixed` replay mode.

Implemented value components:

- Actual additional shots after caps for `+5` and `x2`.
- Actual number and route value of distinct repairable cells.
- Fillable value of a higher defense cap instead of empty capacity.
- Expected defended contacts for armor piercing.
- Expected chamber hits and remaining health for attack growth.
- Delay discount for Echo.
- Remaining draft count and probability improvement for rarity.
- Score explanation containing immediate value, persistent value, delayed value, actual consumption, and expected waste.
- A repeated `x2` has zero immediate marginal value when the next-volley multiplier is already `x2`, because same-round stacking and refresh are disallowed. Echo may still add delayed value when the replay lands in the following round.

A new effect or AI score is incomplete until live runtime, simulation, player-facing explanation, validation, and tests all exist.

## 11. Active And Planned Slices / 当前与后续阶段

### Completed: v0.3.3b0 — Formal Pre-Match And Environment Identity

- Three-step Cardfront deployment screen: map, player hero, AI reveal.
- Three selectable live maps and three selectable player heroes.
- Side-by-side base-stat comparison before battle.
- Lightweight cartoon silhouettes, hero selection cards, and selection/reveal motion.
- Compact in-match player/AI hero identity plates outside the arena core.
- Map-specific environment palettes and landmarks for green-field, industrial,
  and laboratory identities.
- Headless coverage for selection flow, runtime map propagation, hero plates,
  and environment-theme separation.

### Completed Current Slice: First Entity And Building Cards

- Removed the redundant Bridgehead Construction/Bridgehead Fortification path.
- Promoted Repair Units, Fire-Control Beacon, Interceptor Tower, Building
  Volley, and Heavy Charge into the formal `core_tactics` pool.
- Connected entity creation/upgrades to round resolution and synchronized live
  entity summaries before offer eligibility is evaluated.
- Kept building shots independent from command-chamber `+5`/`x2`.
- Added shared one-use Heavy Charge contact state across all sources in a
  volley.
- Added native runtime, content, deck, AI-value, and simulation-contract
  coverage.

### Completed: v0.3.3a6 — Strategic Map Schema And Preview

- Add `route_layout` and `strategy_profile` to all three map definitions.
- Validate sorted, non-overlapping bridge lanes and bounded control zones.
- Add player-facing identity and opening-hint data.
- Add route-layout snapshots/tests without changing live behavior yet.

### Completed: v0.3.3a7 — Live Map And Gate Geometry

- Stop forcing `generate_default_layout()` in live runtime.
- Build the selected map definition from configuration.
- Configure gate crossing and control sampling from the map’s `route_layout`.
- Move 3D bridges and gates from the same authoritative route data.
- Add visual and physics alignment tests.

### Completed: v0.3.3a8 — Simulation Parity B1

- Share gate thresholds and projectile admission between live runtime and B1.
- Contract-test core upgrade and volley resolution against live run state.
- Add a five-round no-upgrade opening-strength audit.
- Add per-hero gameplay and archetype-growth diagnostics.
- Model Engineer opening contact-front cells and per-cell repair/defense.
- Model open, half-open, and closed gate passage/reflection.
- Actually rerun both side variants.
- Record gate passes, gate reflections, lane traffic, and map-specific route pressure.
- Record card appearance, selection, consumption, wasted value, and hero-specific build distribution.
- Run full candidate search before changing hero base values.

Candidate order after B1:

1. Current Engineer: 5 volley / 42 health / contact front `2/2`.
2. If Engineer aggregate remains below 47%: test health `42 -> 44`.
3. Only if still severely weak: consider another visible mechanism; do not immediately change base volley from 5.
4. Keep Gunner at 7 volley / 36 health until the Engineer and AI corrections are represented.

### Later

- Next gameplay engineering target: entity-runtime coupling closeout and an
  eighteen-card live playtest; do not add another card batch first.
- `v0.3.4`: complete the `default_duel` formal-art benchmark, then expand the
  approved environment language to Cross Strongholds and Central Lab.
- `v0.3.3b2` and `v0.3.3b3` remain paused and are not implied by completing
  `v0.3.3b1`.

## 12. Acceptance Requirements / 验收要求

Every gameplay slice must include:

- Content validation.
- Headless regression tests.
- Performance smoke tests.
- Explicit edge cases and no-refill/no-duplication checks.
- Visual/readability checks where player-visible state changes.

Every map-related slice must additionally include:

- 2D authority versus 3D presentation alignment checks.
- Desktop and narrow/mobile readability checks where UI is involved.
- Human acceptance: bridge positions, route tradeoffs, and stronghold relation should be understandable before the first volley.

No map is considered strategically complete until a player can describe its main decision after one match without reading the map name.

## 13. Deferred / 暂缓

- Online or local human multiplayer.
- Full deckbuilder and meta-progression.
- Large uncontrolled card catalog.
- Hero-exclusive card pools.
- Hidden hero hit-rate compensation as a permanent balance rule.
- Changing Engineer base volley before valid B1 evidence.
- Single-bridge and asymmetric competitive maps before true side reruns exist.
- Moving or random bridges during combat.
- Large bumper/obstacle catalogs before the first three route identities work.
- The four-card route module until explicitly reactivated.
- The 108,000-match A/B audit, candidate-deck promotion, and hard balance gates
  while the core framework and art benchmark remain in progress.
- Implementing formal neutral/friendly creature and tower cards until the `TBD`
  fields in the authoritative inventory are explicitly approved; their place
  in the future three-choice card pool is already confirmed.
- Rewriting projectile simulation as true 3D physics.
