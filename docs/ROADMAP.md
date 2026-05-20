# Roadmap / 路线图

Role / 作用: main progress board / 主进度板

This file is the single place for project direction and phase status.  
这份文档只回答项目已经完成什么、正在推进什么、接下来做什么、哪些内容暂缓。

## 1. Current Line / 当前主线

- Current line: `v0.2.x` Cardfront formal UI / 卡牌前线正式 UI 线
- Current completed slice: `v0.2.1-target-preview`
- Next slice: `v0.2.2-card-art-binding`
- Foundation baseline: BallWar / Marble Dominion Ricochet War `v2.1.11.1`
- Current theme:
  - formal Cardfront HUD components (resource bar, hand panel) replacing debug panels
  - FireDirector signal seams for testability and external listener hooks
  - overlay performance via ImageTexture caching instead of per-cell draw_rect
  - next: target preview layer for card selection

## 2. Cardfront Version Plan / 卡牌前线版本规划

| Version | Status | Scope |
|---|---|---|
| `v0.1.1-a-region-map` | Done / 已完成 | Region types, deterministic `RegionMap`, Cardfront-only overlay. No economy tick, cards, or AI. |
| `v0.1.1-b-region-instances` | Done / 已完成 | Add `region_id`, explicit region instances, and region-control statistics. |
| `v0.1.1-c-region-yield` | Done / 已完成 | Region-control yield with 50% / 80% thresholds. |
| `v0.1.2-region-morale` | Done / 已完成 | Morale fluctuation system tied to region state. |
| `v0.1.2.1-cardfront-visibility-polish` | Done / 已完成 | Compact economy debug panel and Cardfront-only low-pressure bullet visual polish. |
| `v0.1.3-deployment-rules` | Done / 已完成 | Deployment permission by owned cell, owned border, and region control degree. |
| `v0.1.3.1-visual-pressure-rebalance` | Done / 已完成 | Rebalance visual pressure: real screen load determines degradation; queue is forecast-only. |
| `v0.1.3.2-cardfront-debug-panel-placement` | Done / 已完成 | Move Cardfront economy debug panel to bottom-right corner. |
| `v0.1.4-fortify-layer` | Done / 已完成 | Frontline fortification layer above deployment rules. |
| `v0.1.5-card-core-lite` | Done / 已完成 | Minimal card play pipeline: 3-card hand, costs, target validation, Fortify effect. |
| `v0.1.6-first-card-effects` | Done / 已完成 | First real effects for Calibrated Shot target bias and Morale Fluctuation morale support. |
| `v0.1.6.1-pioneer-beacon-lite` | Done / 已完成 | Logic-only Pioneer Beacon pulse: owned border cell converts up to 3 nearby neutral cells. |
| `v0.1.6.1-cardfront-fire-director` | Done / 已完成 | Cardfront-only automatic fire director, target scoring, fire intents, and Calibrated Shot bias integration. |
| `v0.1.6.2-cardfront-control-chamber-decoupling` | Done / 已完成 | Cardfront skips legacy control chambers and +ball buttons, adds HUD fire status, and splits FireDirector shot budgets into global + per-owner caps. |
| `v0.1.7a-device-core` | Done / 已完成 | Device core layer: placement, tick, snapshot; 3 types registered, no effects. |
| `v0.1.7b-absorber-core-lite` | Done / 已完成 | Absorber core: absorbs enemy bullets within radius, grants energy. |
| `v0.1.7c-engineer-bot-lite` | Done / 已完成 | Engineer bot: reinforces nearby owned border cells with fortify stacks. |
| `v0.1.7d-durable-pioneer-beacon` | Done / 已完成 | Durable pioneer beacon: periodically converts nearby neutral cells. Device tetralogy complete. |
| `v0.1.8a-device-visual-layer` | Done / 已完成 | Device sprites from runtime PNGs, DeviceOverlayLayer, DeviceVisualRegistry. |
| `v0.1.8b-device-visual-validation` | Done / 已完成 | Full test coverage for device overlay: draw items, fallback, expiry, removal, BallWar isolation. |
| `v0.1.8d-cardfront-bottom-hud-visible-bridge` | Done / 已完成 | Bottom HUD shows device counts and card status; VFX + debug panel wired. |
| `v0.1.8e-bottom-hud-status-polish` | Done / 已完成 | Bottom HUD status formatter, dirty redraw protection, and Cardfront performance smoke coverage. |
| `v0.1.9-cardfront-engineering-closeout` | Done / 已完成 | Version sync, CI batch gate, test matrix update, performance budget gate, save schema audit, `CardPlaySystem` effect registry pre-split, and doc alignment. |
| `v0.2.0a-cardfront-formal-ui-foundation` | Done / 已完成 | Formal `CardfrontTopResourceBar`, `CardfrontHandPanel`, `CardfrontCardView`, `CardfrontCardSelectionController`; FireDirector signals (`fire_tick`/`fire_requested`/`fire_issued`/`fire_skipped`); overlay `ImageTexture` caching. |
| `v0.2.0b-fix-formal-ui-and-signal-ci` | Done / 已完成 | Fix `CardfrontCardView._create_children()` body, fix `CardfrontFireDirectorSignalTestRunner` fixture errors, add new tests to CI batch matrix, doc alignment. |
| `v0.2.1-target-preview` | Done / 已完成 | `CardfrontTargetPreviewLayer.gd`: highlight valid target cells on battlefield; pioneer beacon shows border + adjacent neutral hint cells; `CardfrontBattlefieldClickSelectionTestRunner.gd` verifies select→preview→click→play flow; `Main.gd:_unhandled_input()` wires mouse click to `selection_controller.on_battlefield_clicked()`. |
| `v0.2.2-card-art-binding` | Active / 当前 | Replace `CARD_PLACEHOLDERS` icons with actual card illustrations from `cardfront_runtime/卡牌插图_cards/512/` via `CardVisualRegistry.gd`; `TextureRect` in `CardfrontCardView.tscn` with placeholder fallback. |

## 3. Design Boundaries / 设计边界

- `v0.1.1-b` adds region identity and control statistics only; no resource income yet.
- `v0.1.1-c` adds region yield and the first 1-second economy tick.
- `v0.1.2` adds region-local morale ownership shifts only.
- `v0.1.3` adds deployment permission judgment only.
- Economy calculation must stay outside `Battlefield.apply_bullet()`.
- Deployment rules must not mutate `Battlefield` owners or `RegionMap`.
- Card effects must stay behind `CardPlaySystem` and small effect systems; `Main.gd` stays assembly-only.
- Do not modify `Bullet`, `BulletPool`, `Turret`, or `ControlChamber` for region planning slices unless a later slice explicitly requires it.
- Cardfront Fire Director may use a minimal `Turret` directed-fire seam, but old `fire_burst(...)` and old BallWar control-chamber behavior must remain intact.
- Cardfront should not expose old control chambers as a primary play surface while FireDirector owns baseline shooting.

## 4. Foundation Completed / 已完成基础

### Gameplay loop / 玩法闭环

- Four-faction battlefield capture, ricochet turrets, control chambers, win evaluation, event log, and match-end flow are already stable.
- Existing BallWar modes remain the baseline runtime.
- Cardfront is a sidecar mode on top of the reusable BallWar runtime.

### Save/load and orchestration / 保存恢复与编排

- `SaveFlowController` owns save preparation and apply steps.
- `RestorePlan.gd` remains the active recovery chain.
- `ControlChamber.gd`, `Turret.gd`, and `Bullet.gd` expose `restore_from_state(...)`.
- `Main.gd` is kept orchestration-focused and delegates Cardfront systems to `scripts/cardfront/`.

### UI and product surfaces / UI 与用户面

- `StartMenu.tscn`, `GameHUD.tscn`, `SettingsPanel.tscn`, and `ResultPanel.tscn` form the current main UI structure.
- Cardfront currently uses a compact economy debug panel, not a final HUD.
- Formal card UI is intentionally deferred.

### Runtime cleanup / 运行时收口

- `BattlefieldDecorLayer.gd` uses event/dirty-marker style updates.
- `BulletPool.gd` maintains peak active-bullet statistics and visual degradation rules.
- `EventRouletteController.gd` remains part of old BallWar modes; Cardfront disables roulette for now.
- `ChamberState.gd` and chamber helper modules keep chamber state and physics boundaries explicit.

### Documentation cleanup / 文档收口

- `README.md` is the repository entry surface.
- `CHANGELOG.md` is the short milestone spine.
- `docs/` owns architecture, testing, performance, save system, export, release process, and roadmap docs.
- `docs/历史_history/` keeps detailed historical stage notes.

## 5. Cardfront Completed Slices / 已完成 Cardfront 切片

- `v0.1.1-a-region-map`
  - `RegionType.gd`
  - `RegionMap.gd`
  - `RegionOverlayLayer.gd`
  - `RegionMapTestRunner.gd`
- `v0.1.1-b-region-instances`
  - stable `region_id`
  - explicit region instance data
  - per-region player / AI / neutral control statistics
- `v0.1.1-c-region-yield`
  - resource state, yield rules, yield calculator, economy tick
  - compact Cardfront-only economy debug panel
  - economy logic remains outside `Battlefield.apply_bullet()`
- `v0.1.2-region-morale`
  - region-local morale system
  - deterministic seeded test path
  - no cards, units, AI, or fortification
- `v0.1.2.1-cardfront-visibility-polish`
  - compact debug panel layout
  - Cardfront-only low-pressure marble visual polish
  - old BallWar visual strategy unchanged
- `v0.1.3-deployment-rules`
  - `DeploymentRuleType.gd`
  - `DeploymentQuery.gd`
  - `DeploymentResult.gd`
  - `DeploymentRules.gd`
  - `DeploymentRulesTestRunner.gd`
  - owned cell, owned border, and controlled-region permission checks
  - no cards, units, fortification, or AI
- `v0.1.3.1-visual-pressure-rebalance`
  - split `_resolve_visual_profile` into legacy and Cardfront strategies
  - queue is now a forecast signal, not a current pressure signal
  - Cardfront uses independent thresholds (more generous at low load)
  - new `VisualPressurePolicyTestRunner.gd` for legacy mode tests
  - `CardfrontVisualPolicyTestRunner.gd` rewritten with 8 cardfront-specific tests
- `v0.1.3.2-cardfront-debug-panel-placement`
  - moved economy debug panel from hardcoded top-left to bottom-right
  - `_resolve_panel_position` supports `bottom_right` / `bottom_left`
  - `EconomyDebugPanelSceneTestRunner.gd` adds position boundary checks
- `v0.1.4-fortify-layer`
  - `FortifyRules.gd`, `FortifyLayer.gd` — configurable grid of 0–3 fortify stacks
  - `FortifyTargetSelector.gd` — reuses `DeploymentRules.is_owned_border`
  - `CardfrontCaptureInterceptor.gd` — intercepts capture on fortified cells
  - `Battlefield.gd` — generic `capture_interceptor` hook in `apply_bullet`
  - `FortifyOverlayLayer.gd` — dark fill + colored border per stack level
  - `FortifyLayerTestRunner.gd` — 13 test cases
- `v0.1.5-card-core-lite`
  - `CardType.gd`, `CardTargetType.gd`, `CardData.gd` — card definitions
  - `CardCatalog.gd` — 3-card catalog (Fortify, Calibrated Shot, Morale Fluctuation)
  - `CardHandState.gd` — fixed hand with used/available tracking
  - `CardPlayRequest.gd`, `CardPlayResult.gd` — request/result data objects
  - `CardPlaySystem.gd` — play pipeline: cost check, target validation, effect resolution
  - Card effects at this slice: Fortify calls `FortifyLayer`, others were stubs
  - `CardCoreLiteTestRunner.gd` — 11 test cases
- `v0.1.6-first-card-effects`
  - `CardPlaySystem.gd` — resolves `morale_fluctuation` and `calibrated_shot`
  - `CardfrontTargetBiasSystem.gd` — Cardfront-only region bias state with duration expiry
  - `CardfrontMode.gd`, `GameRuntimeContext.gd`, `Main.gd` — target-bias assembly and injection
  - Morale Fluctuation calls `RegionMoraleSystem.apply_morale(..., SUPPORT_PLAYER)`
  - Calibrated Shot registers a target-region bias; turret aiming integration remains deferred
  - effect failures roll back resource payment and hand used state
  - `CardFirstEffectsTestRunner.gd` and `CardfrontTargetBiasTestRunner.gd`
- `v0.1.6.1-pioneer-beacon-lite`
  - `CardCatalog.gd` adds card `1004` / Pioneer Beacon to the fixed hand
  - `PioneerBeaconLiteEffect.gd` keeps neutral-neighbor search and conversion outside `CardPlaySystem.gd`
  - Pioneer Beacon validates an owned border target and converts up to 3 adjacent neutral cells
  - failure paths preserve the card rollback contract
  - no durable map entity, no duration, no full unit/device system
  - `PioneerBeaconLiteTestRunner.gd`
- `v0.1.6.1-cardfront-fire-director`
  - `CardfrontFireRules.gd`, `CardfrontFireIntent.gd`, `CardfrontTargetScorer.gd`, `CardfrontFireDirector.gd`
  - Cardfront turrets keep low-frequency automatic pressure without using control chambers as the shooting driver
  - `CardfrontFireDirector` reads `CardfrontTargetBiasSystem`; Calibrated Shot can steer the next generated intent toward its biased region
  - `Turret.gd` keeps old `fire_burst(...)` and adds a minimal directed-fire seam
  - old BallWar modes do not create `fire_director`
  - `CardfrontFireDirectorTestRunner.gd`
- `v0.1.6.2-cardfront-control-chamber-decoupling`
  - Cardfront runtime no longer creates visible legacy control chambers
  - Cardfront runtime no longer creates +ball buttons
  - HUD event-status slot now shows `自动射击中 / 卡牌改写射击`
  - FireDirector now has both global and per-owner per-second shot budgets
  - old BallWar modes still create control chambers and +ball buttons
  - `CardfrontControlChamberDecouplingTestRunner.gd`

## 6. Next / 下一步

1. `v0.2.2-card-art-binding`: replace `CARD_PLACEHOLDERS` with actual card illustrations via `CardVisualRegistry`, add `TextureRect` to `CardfrontCardView.tscn` with placeholder fallback.
2. Keep Deckbuilder, deck draw/discard/shuffle, and AI Commander deferred.
3. Follow the high-coupling split order in `docs/技术_technical/CARDFRONT_DECOUPLING_PLAN.md` for all new wiring.

### Cardfront Save Schema

`CardfrontRuntimeSnapshot.gd` was added in v0.1.7a with fields for:
- resource state (energy, parts per player/AI)
- used card IDs
- fortify stacks grid
- active morale effects
- target bias state (owner → region → remaining duration)
- future device list placeholder

v0.1.9 owns the schema audit and explicit test coverage. Full save/load wiring may wait, but schema shape should be kept stable before devices introduce durable world entities.

## 7. Later / 中期候选

- New-player tutorial.
- Mode explanation page.
- More complete match-end statistics.
- Android signing and store-ready delivery flow.

## 8. Not Now / 暂不处理

- Do not add formal card UI, Deckbuilder, AI Commander, units, or fortification outside their planned slices.
- Do not build cards or AI before the region/deployment foundation is stable.
- Do not expand bullet-field scale before the performance baseline is stable.
- Do not push UI logic back into raw code-generated dynamic UI surfaces.
- Do not treat `docs/历史_history/README_v*.md` as the current source of truth.
- Do not add large special events or special marbles before their boundaries are designed.

## 9. Canonical Doc Split / 文档分工

- `README.md`: project entry surface and curated links.
- `CHANGELOG.md`: short milestone spine.
- `docs/ARCHITECTURE.md`: system layering, ownership rules, and architecture principles.
- `docs/TESTING.md`: runner categories and run guidance.
- `docs/PERFORMANCE.md`: performance probe overview and baseline notes.
- `docs/SAVE_SYSTEM.md`: save schema, backup recovery, validation, and input cleanup.
- `docs/技术_technical/CARDFRONT_DECOUPLING_PLAN.md`: Cardfront high-coupling split order and acceptance criteria.
- `docs/ANDROID_EXPORT.md`: Android export checklist.
- `docs/RELEASE_PROCESS.md`: packaging and release workflow.
- `docs/ROADMAP.md`: current direction, completed work, next step, and deferred scope.
- `docs/历史_history/README.md`: historical stage index.
- `docs/技术_technical/AI_HANDOFF_CURRENT.md`: AI / Codex handoff card.
