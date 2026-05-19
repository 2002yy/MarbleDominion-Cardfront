# Roadmap / 路线图

Role / 作用: main progress board / 主进度板

This file is the single place for project direction and phase status.  
这份文档只回答项目已经完成什么、正在推进什么、接下来做什么、哪些内容暂缓。

## 1. Current Line / 当前主线

- Current line: `v0.1.x` Cardfront prototype / 卡牌前线原型线
- Current completed slice: `v0.1.5-card-core-lite`
- Next slice: `v0.1.6-first-card-effects`
- Foundation baseline: BallWar / Marble Dominion Ricochet War `v2.1.11.1`
- Current theme:
  - region ownership as the strategic layer above Battlefield cell ownership
  - economy and deployment rules built from region control, not from bullet internals
  - card systems added only after region, yield, morale, and deployment boundaries are testable
  - keep `Battlefield`, bullets, turrets, and chambers reusable for old BallWar modes

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
| `v0.1.6-first-card-effects` | Next / 下一步 | First card effects: calibrated shot, pioneer beacon, morale fluctuation. |
| `v0.1.5-card-core-lite` | Planned / 计划中 | Pseudo-card core: fixed hand and energy costs. |
| `v0.1.6-first-card-effects` | Planned / 计划中 | First effects such as calibrated shot, pioneer beacon, and morale fluctuation. |
| `v0.1.7-unit-devices` | Planned / 计划中 | Device-style systems for bullet absorber core, engineer robot, and pioneer beacon. |

## 3. Design Boundaries / 设计边界

- `v0.1.1-b` adds region identity and control statistics only; no resource income yet.
- `v0.1.1-c` adds region yield and the first 1-second economy tick.
- `v0.1.2` adds region-local morale ownership shifts only.
- `v0.1.3` adds deployment permission judgment only.
- Economy calculation must stay outside `Battlefield.apply_bullet()`.
- Deployment rules must not mutate `Battlefield` owners or `RegionMap`.
- Card effects should wait until region, yield, morale, and deployment rules are already testable.
- Do not modify `Bullet`, `BulletPool`, `Turret`, or `ControlChamber` for region planning slices unless a later slice explicitly requires it.

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
- `docs/history/` keeps detailed historical stage notes.

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
  - Card effects: Fortify calls `FortifyLayer`, others are stubs
  - `CardCoreLiteTestRunner.gd` — 11 test cases

## 6. Next / 下一步

1. **`v0.1.6-first-card-effects`**: calibrated shot, pioneer beacon, morale fluctuation, and similar first effects.
2. **`v0.1.7-unit-devices`**: device-style systems for bullet absorber core, engineer robot, and pioneer beacon.

## 7. Later / 中期候选

- `v0.1.6-first-card-effects`: calibrated shot, pioneer beacon, morale fluctuation, and similar first effects.
- `v0.1.7-unit-devices`: device-style systems for bullet absorber core, engineer robot, and pioneer beacon.
- New-player tutorial.
- Mode explanation page.
- More complete match-end statistics.
- Android signing and store-ready delivery flow.

## 8. Not Now / 暂不处理

- Do not add card UI, units, AI, or fortification outside their planned slices.
- Do not build cards or AI before the region/deployment foundation is stable.
- Do not expand bullet-field scale before the performance baseline is stable.
- Do not push UI logic back into raw code-generated dynamic UI surfaces.
- Do not treat `docs/history/README_v*.md` as the current source of truth.
- Do not add large special events or special marbles before their boundaries are designed.

## 9. Canonical Doc Split / 文档分工

- `README.md`: project entry surface and curated links.
- `CHANGELOG.md`: short milestone spine.
- `docs/ARCHITECTURE.md`: system layering, ownership rules, and architecture principles.
- `docs/TESTING.md`: runner categories and run guidance.
- `docs/PERFORMANCE.md`: performance probe overview and baseline notes.
- `docs/SAVE_SYSTEM.md`: save schema, backup recovery, validation, and input cleanup.
- `docs/ANDROID_EXPORT.md`: Android export checklist.
- `docs/RELEASE_PROCESS.md`: packaging and release workflow.
- `docs/ROADMAP.md`: current direction, completed work, next step, and deferred scope.
- `docs/history/README.md`: historical stage index.
- `docs/technical/AI_HANDOFF_CURRENT.md`: AI / Codex handoff card.
