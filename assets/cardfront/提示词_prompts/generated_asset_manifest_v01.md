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

## 5. Runtime Derivation / 运行时派生

Processed runtime sizes:

| Source category | Runtime directory | Size | Processing |
|---|---|---|---|
| `卡牌插图_cards_illustrations/` | `cardfront_runtime/卡牌插图_cards/512/` | 512x512 | Lanczos resize |
| `装置地图精灵_devices_map_sprites/` | `cardfront_runtime/装置精灵_devices/96/` | 96x96 | background transparency + Lanczos resize |
| `装置图标_devices_icons/` | `cardfront_runtime/装置图标_icons/48/` | 48x48 | background transparency + Lanczos resize |
| `特效纹理_vfx_textures/` | `cardfront_runtime/视觉特效_vfx/128/` | 128x128 | alpha preserved + Lanczos resize |

Processing script: `tools/process_cardfront_assets.py`

## 6. Boundaries / 边界

- These assets are project-specific AI-generated assets, not a reusable third-party pack.
- Do not use raw 1024 source images directly as small sprites.
- Use registries (`CardVisualRegistry`, `DeviceVisualRegistry`, `CardfrontUiAssetRegistry`) for runtime paths.
- Keep `ResourceLoader.exists` fallback behavior in tests and UI code.
