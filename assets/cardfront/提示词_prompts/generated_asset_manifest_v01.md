# Generated Asset Manifest v0.2.3 / AI 生成素材清单

This manifest tracks AI-generated Cardfront assets under `assets/cardfront/`
and their processed runtime derivatives under `assets/cardfront_runtime/`.

本清单记录 `assets/cardfront/` 下的 AI 生成源素材，以及
`assets/cardfront_runtime/` 下已经处理后的运行时派生素材。

## 1. Card Illustrations / 卡牌插图

| Card ID | Runtime file | Source file | Current integration |
|---|---|---|---|
| 1001 | `assets/cardfront_runtime/卡牌插图_cards/512/前线加固_frontline_fortify_v01.png` | `assets/cardfront/卡牌插图_cards_illustrations/前线加固_frontline_fortify_v01.png` | Wired through `CardVisualRegistry.gd`; shown by `CardfrontCardView.gd`. |
| 1002 | `assets/cardfront_runtime/卡牌插图_cards/512/校准射击_calibrated_shot_v01.png` | `assets/cardfront/卡牌插图_cards_illustrations/校准射击_calibrated_shot_v01.png` | Wired through `CardVisualRegistry.gd`; shown by `CardfrontCardView.gd`. |
| 1003 | `assets/cardfront_runtime/卡牌插图_cards/512/民心起伏_morale_shift_v01.png` | `assets/cardfront/卡牌插图_cards_illustrations/民心起伏_morale_shift_v01.png` | Wired through `CardVisualRegistry.gd`; shown by `CardfrontCardView.gd`. |
| 1004 | `assets/cardfront_runtime/卡牌插图_cards/512/拓荒信标_pioneer_beacon_v01.png` | source/staged Cardfront asset | Wired through `CardVisualRegistry.gd`; shown by `CardfrontCardView.gd` when present. |

Current limitation: hand cards still use 512 images. `v0.2.4b-card-thumbnail-pass`
should register 128/256 thumbnails in `CardVisualRegistry.thumbnail`.

当前限制：手牌小卡仍直接使用 512 图。`v0.2.4b-card-thumbnail-pass`
应补 128/256 缩略图，并启用 `CardVisualRegistry.thumbnail`。

## 2. Device Sprites / 装置地图精灵

| Device | Runtime file | Current integration |
|---|---|---|
| Absorber Core | `assets/cardfront_runtime/装置精灵_devices/96/吸弹核心_absorber_core_v01.png` | Wired through `DeviceVisualRegistry.gd` and `CardfrontDeviceOverlayLayer.gd`. |
| Engineer Bot | `assets/cardfront_runtime/装置精灵_devices/96/工程机器人_engineer_bot_v01.png` | Wired through `DeviceVisualRegistry.gd` and `CardfrontDeviceOverlayLayer.gd`. |
| Pioneer Beacon | `assets/cardfront_runtime/装置精灵_devices/96/拓荒信标_pioneer_beacon_v01.png` | Wired through `DeviceVisualRegistry.gd` and `CardfrontDeviceOverlayLayer.gd`. |
| Temporary Reflector | `assets/cardfront_runtime/装置精灵_devices/96/临时反弹板_temporary_reflector_v01.png` | Registered as a future/placeholder device sprite path. |

## 3. Device Icons / 装置图标

| Icon | Runtime file | Current integration |
|---|---|---|
| Fortify shield | `assets/cardfront_runtime/装置图标_icons/48/加固层盾牌_fortify_shield_v01.png` | Staged runtime icon; not yet a primary formal HUD icon. |

## 4. VFX Textures / 特效纹理

| VFX | Runtime file | Current integration |
|---|---|---|
| Energy ripple | `assets/cardfront_runtime/视觉特效_vfx/128/能量波纹环_energy_ripple_ring_v01.png` | Used by `CardfrontVfxLayer.play_energy_ripple(...)`. |
| Shield crack / pulse | `assets/cardfront_runtime/视觉特效_vfx/128/护盾裂纹_shield_crack_v01.png` | Used by `CardfrontVfxLayer.play_shield_crack(...)` and `play_shield_pulse(...)`. |
| Region pulse | `assets/cardfront_runtime/视觉特效_vfx/128/区域控制脉冲_region_threshold_pulse_v01.png` | Used by `CardfrontVfxLayer.play_region_pulse(...)`. |

`CardfrontEffectVisualBridge.gd` now maps the 4 existing card-success events to
these VFX methods. Missing textures fall back to procedural draw circles.

## 5. Neutral Creatures / 中立生物

| Creature | Runtime file | Source file | Current integration |
|---|---|---|---|
| Gate Colossus / 闸门巨像 | `assets/cardfront_runtime/中立生物_neutral_creatures/256/gate_colossus/{idle,move,attack,hit,death}/frame_*.png` | `assets/cardfront/中立生物_neutral_creatures/source/闸门巨像_gate_colossus_v01.png` plus source strips under `animations/` | Five-state `AnimatedSprite2D` actor wired through `CardfrontEntityVisualRegistry.gd` and `CardfrontEntityPresentationLayer.gd`; static 256px sprite and procedural drawing remain fallbacks. |

The source was generated specifically for Cardfront with the built-in image
generation workflow. Animation strips were chroma-keyed, normalized to a shared
bottom-center anchor on 256x256 transparent canvases, and validated as
`idle:4`, `move:6`, `attack:6`, `hit:4`, and `death:6`.

## 5b. Friendly Battlefield Entities / 友方战场实体

| Entity | Runtime animation set | Action states | Production |
|---|---|---|---|
| Repair Unit | `assets/cardfront_runtime/战场实体_battlefield_entities/256/repair_unit/` | `idle`, `move`, `repair`, `hit`, `death` | Deterministic toy-robot frame generator |
| Armored Guard | `assets/cardfront_runtime/战场实体_battlefield_entities/256/armored_guard/` | `idle`, `move`, `block`, `hit`, `death` | Deterministic toy-robot frame generator |
| Sapper Unit | `assets/cardfront_runtime/战场实体_battlefield_entities/256/sapper_unit/` | `idle`, `move`, `attack`, `detonate`, `hit`, `death` | Deterministic toy-robot frame generator |
| Scout Unit | `assets/cardfront_runtime/战场实体_battlefield_entities/256/scout_unit/` | `idle`, `move`, `guide`, `hit`, `death` | Deterministic toy-drone frame generator |

All friendly frames are 256x256 RGBA, bottom-center anchored, use stable bold
outlines, and can be horizontally mirrored for left/right movement. Contact
sheets live under `assets/cardfront/战场实体_battlefield_entities/previews/`.
Fire-Control Beacon and Interceptor Tower use procedural presentation actors
rather than frame strips.

## 6. Runtime Derivation / 运行时派生

Processed runtime sizes:

| Source category | Runtime directory | Size | Processing |
|---|---|---|---|
| `卡牌插图_cards_illustrations/` | `cardfront_runtime/卡牌插图_cards/512/` | 512x512 | Lanczos resize |
| `装置地图精灵_devices_map_sprites/` | `cardfront_runtime/装置精灵_devices/96/` | 96x96 | background transparency + Lanczos resize |
| `装置图标_devices_icons/` | `cardfront_runtime/装置图标_icons/48/` | 48x48 | background transparency + Lanczos resize |
| `特效纹理_vfx_textures/` | `cardfront_runtime/视觉特效_vfx/128/` | 128x128 | alpha preserved + Lanczos resize |
| `中立生物_neutral_creatures/source/` and `animations/` | `cardfront_runtime/中立生物_neutral_creatures/256/gate_colossus/` | 256x256 per frame | chroma-key alpha + shared-scale bottom-center normalization |
| `scripts/tools/generate_cardfront_entity_animations.py` | `cardfront_runtime/战场实体_battlefield_entities/256/` | 256x256 per frame | deterministic RGBA frames + bottom-center anchor + contact sheets |

Processing script: `tools/process_cardfront_assets.py`
Friendly entity animation generator:
`scripts/tools/generate_cardfront_entity_animations.py`

## 7. Boundaries / 边界

- These assets are project-specific AI-generated assets, not a reusable third-party pack.
- Do not use raw 1024 source images directly as small sprites.
- Use registries (`CardVisualRegistry`, `DeviceVisualRegistry`, `CardfrontUiAssetRegistry`, `CardfrontEntityVisualRegistry`) for runtime paths.
- Keep `ResourceLoader.exists` fallback behavior in tests and UI code.
