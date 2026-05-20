# Cardfront Decoupling Plan / Cardfront 高耦合拆分规划

Date / 日期: 2026-05-20  
Role / 作用: engineering boundary plan for the next Cardfront refactors / 后续 Cardfront 重构边界规划

This document is a planning guardrail, not a request to start a large rewrite immediately.  
这份文档用于约束后续拆分顺序，不代表立刻启动大重写。

## 1. Current Risk / 当前风险

The first boundary is already in place: `Main.gd` is mostly orchestration, while Cardfront systems live under `scripts/cardfront/`.

下一层高耦合风险已经出现：

- `CardfrontMode.gd` is becoming a new small `Main.gd`.
- `CardPlaySystem.gd` will become an effect sink when the catalog grows beyond the current 4 cards.
- Cardfront HUD currently borrows old `fps_label` and `event_label`.
- `DeviceLayer.gd` currently owns placement, lifetime ticking, querying, snapshot, and restore.

## 2. Splitting Principles / 拆分原则

Split by responsibility, not by line count.

| File / Module | Owns | Must Not Own |
|---|---|---|
| `CardfrontRuntimeBuilder` | Runtime system creation and dependency wiring | Concrete card effect rules |
| `CardfrontSystemRegistry` | Named runtime refs and lookup safety | System construction policy |
| `CardfrontRuntimeRefs` | Typed reference payload for Cardfront runtime | Gameplay decisions |
| `CardfrontHudBuilder` | Cardfront UI node creation and wiring | Resource settlement |
| `CardEffectResolver` | Effect dispatch and effect context handoff | UI, deck draw, AI choices |
| `CardEffectRegistry` | Effect id to effect object mapping | Rollback and resource payment |
| `CardfrontSaveCodec` | Serialize / deserialize Cardfront snapshot payloads | Gameplay decisions |
| `AICommander` | Strategy selection for AI turns | Simulating real player input |

Keep reusable runtime boundaries intact:

- `Battlefield` owns cell ownership and basic drawing.
- `RegionMap` owns region type, region id, and queries.
- `EconomyTickSystem` owns fixed-tick resource settlement.
- Future `DeckManager` owns draw, discard, shuffle, and deck state only.
- Future Cardfront HUD owns resources, hand display, target preview, and feedback display only.

## 3. Phase Plan / 阶段计划

### Phase 0: v0.1.9 engineering closeout / 工程收口

Goal: finish guardrails without adding new gameplay systems.

Scope:

- Keep `project.godot` versions synchronized.
- Keep Cardfront runners in `.github/workflows/headless-tests.yml`.
- Keep `CardfrontPerformanceSmokeTestRunner.gd` as the performance budget gate.
- Keep `CardfrontRuntimeSnapshotTestRunner.gd` as the current save-schema audit.
- Keep `CardPlaySystem.gd` effect dispatch behind a registry.
- Do not add formal Deckbuilder or AI Commander.

Acceptance:

- New Cardfront test runners are CI-gated, not local-only.
- `CardPlaySystem.gd` has no direct `match card.effect_id` block.
- README / ROADMAP / AI handoff agree on the same next slice name.

### Phase 1: Effect Resolver Split / 卡牌效果拆分

Target folder:

```text
scripts/cardfront/effects/
  CardEffectResolver.gd
  CardEffectRegistry.gd
  effects/
    FortifyBorderEffect.gd
    CalibratedShotEffect.gd
    MoraleFluctuationEffect.gd
    PioneerBeaconLiteEffect.gd
```

Move out of `CardPlaySystem.gd`:

- `_resolve_fortify_border`
- `_resolve_calibrated_shot`
- `_resolve_morale_fluctuation`
- `_resolve_pioneer_beacon_lite`

Keep inside `CardPlaySystem.gd`:

- card lookup
- used-card checks
- resource checks
- target validation
- resource deduction
- resolver call
- failure rollback
- result normalization

Acceptance:

- Adding a new card effect does not modify `CardPlaySystem.gd` main flow.
- Each effect object has focused tests.
- Rollback remains centralized in `CardPlaySystem.gd`.
- Existing runners stay green: `CardCoreLiteTestRunner.gd`, `CardFirstEffectsTestRunner.gd`, relevant effect runners.

### Phase 2: Runtime Builder Split / 运行时装配拆分

Target folder:

```text
scripts/cardfront/runtime/
  CardfrontRuntimeBuilder.gd
  CardfrontSystemRegistry.gd
  CardfrontRuntimeRefs.gd
```

Move out of `CardfrontMode.gd`:

- creation of regions, economy, morale, fortify, target bias
- creation of card system, fire director, shot guide
- creation of device layer, VFX layer, device effect systems
- debug action panel wiring

Keep in `CardfrontMode.gd`:

- mode identity
- active faction policy
- match duration and capture target policy
- old BallWar compatibility switches such as `uses_control_chambers()`
- thin calls into `CardfrontRuntimeBuilder`

Acceptance:

- `CardfrontMode.gd` remains a policy facade, not a runtime factory pile.
- `Main.gd` calls one or two Cardfront assembly entrypoints, not every subsystem constructor.
- Runtime refs are explicit, discoverable, and testable.
- Existing mode smoke and FireDirector runners stay green.

### Phase 3: Formal Cardfront HUD / 正式 Cardfront UI

Target files:

```text
scenes/cardfront/ui/CardfrontHud.tscn
scenes/cardfront/ui/CardfrontHandPanel.tscn
scenes/cardfront/ui/CardfrontResourcePanel.tscn
scenes/cardfront/ui/CardfrontRegionInfoPanel.tscn
scripts/cardfront/ui/CardfrontHudBuilder.gd
scripts/cardfront/ui/CardfrontCardHandView.gd
scripts/cardfront/ui/CardfrontTargetPreviewLayer.gd
scripts/cardfront/ui/CardfrontEffectToastLayer.gd
```

Old HUD keeps:

- FPS / performance debug
- pause
- exit
- base timer

Cardfront HUD owns:

- energy
- parts
- hand cards
- card cost and consumed state
- target region preview
- region yield
- device counts
- current calibrated target
- effect feedback

Acceptance:

- Cardfront no longer depends on `fps_label` or `event_label` for primary state.
- `CardfrontStatusFormatter.gd` can remain as a debug/status formatter, not the main HUD.
- UI tests cover node presence, refresh payloads, and mode isolation.

### Phase 4: Cardfront Save Boundary / Cardfront 存档边界

Target folder:

```text
scripts/cardfront/save/
  CardfrontRuntimeSnapshot.gd
  CardfrontSaveCodec.gd
  CardfrontSaveStateBuilder.gd
  CardfrontSaveStateApplier.gd
```

Responsibilities:

- `CardfrontRuntimeSnapshot.gd`: schema object and stable field list.
- `CardfrontSaveCodec.gd`: serialize, deserialize, version, validate.
- `CardfrontSaveStateBuilder.gd`: collect data from runtime systems.
- `CardfrontSaveStateApplier.gd`: apply validated Cardfront data back into systems.

Acceptance:

- Save codec does not make gameplay decisions.
- Builder and applier know runtime refs, but not UI.
- Existing BallWar `SaveGameCodec` remains the shared outer payload gate.
- Cardfront save/load tests cover partial payloads, old payload tolerance, and neutral owner preservation.

### Phase 5: Device Split / 装置层拆分

Do this after v0.3, when device rules grow enough to justify the extra files.

Target folder:

```text
scripts/cardfront/devices/
  DeviceLayer.gd
  DevicePlacementSystem.gd
  DeviceTickSystem.gd
  DeviceSnapshotCodec.gd
  DeviceQuery.gd
```

Responsibilities:

- `DeviceLayer.gd`: instance container only.
- `DevicePlacementSystem.gd`: placement legality and limits.
- `DeviceTickSystem.gd`: lifetime ticking.
- `DeviceSnapshotCodec.gd`: snapshot / restore.
- `DeviceQuery.gd`: owner/type/cell lookup helpers.

Acceptance:

- `DeviceLayer.gd` does not know concrete device effects.
- Absorber, Engineer Bot, and Durable Pioneer Beacon remain independent effect systems.
- Device snapshot tests stay separate from placement tests.

## 4. Not Now / 暂不处理

- Do not start formal Deckbuilder during `v0.1.9`.
- Do not add AI Commander during `v0.1.9`.
- Do not move Cardfront rules into `Main.gd`.
- Do not make `CardfrontRuntimeBuilder` execute card effects.
- Do not let HUD code pay costs, mutate ownership, or drive economy settlement.
- Do not split `DeviceLayer.gd` before device rules justify the overhead.

## 5. Suggested Order / 建议顺序

1. Finish `v0.1.9-cardfront-engineering-closeout`.
2. Split `CardEffectResolver` and concrete effect files.
3. Split `CardfrontRuntimeBuilder` after effect dispatch is no longer embedded in `CardPlaySystem.gd`.
4. Build formal Cardfront HUD in v0.2.0.
5. Add Cardfront save builder/applier before durable Deckbuilder or AI state.
6. Split device placement/tick/snapshot after v0.3 when device complexity is real.
