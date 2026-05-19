# AI生成素材清单 / Generated Asset Manifest v0.1

本清单记录 `assets/cardfront/` 下所有 AI 生成素材的原始对应关系、用途和集成状态。

## 一、卡牌插图 / cards/illustrations

| 当前文件名 | 原始中文文件名 | 资源类型 | 生成用途 | 交付模式 | 人工修改 | 可进运行时 | 预计接入 |
|---|---|---|---|---|---|---|---|
| 前线加固_frontline_fortify_v01.png | 前线加固.png | 卡牌主图 | 前线加固卡牌展示 | 完整背景 | 否 | 否（待裁切/透明） | v0.2.x card UI |
| 民心起伏_morale_shift_v01.png | 民心起伏.png | 卡牌主图 | 民心起伏卡牌展示 | 完整背景 | 否 | 否（待裁切/透明） | v0.2.x card UI |
| 校准射击_calibrated_shot_v01.png | 校准射击.png | 卡牌主图 | 校准射击卡牌展示 | 完整背景 | 否 | 否（待裁切/透明） | v0.2.x card UI |

## 二、装置地图精灵 / devices/map_sprites

| 当前文件名 | 原始中文文件名 | 资源类型 | 生成用途 | 交付模式 | 人工修改 | 可进运行时 | 预计接入 |
|---|---|---|---|---|---|---|---|
| 吸弹核心_absorber_core_v01.png | 吸弹核心.png | 地图装置精灵 | 吸弹核心装置地图显示 | 完整背景 | 否 | 否（待透明/缩放） | v0.2.x device visuals |
| 工程机器人_engineer_bot_v01.png | 工程机器人.png | 地图装置精灵 | 工程机器人装置地图显示 | 完整背景 | 否 | 否（待透明/缩放） | v0.2.x device visuals |
| 拓荒信标_pioneer_beacon_v01.png | 拓荒信标.png | 地图装置精灵 | 持久拓荒信标装置地图显示 | 完整背景 | 否 | 否（待透明/缩放） | v0.2.x device visuals |
| 临时反弹板_temporary_reflector_v01.png | 临时反弹板.png | 地图装置精灵 | 未来反弹板机关地图显示 | 完整背景 | 否 | 否（待透明/缩放） | 未来 device slice |

## 三、装置图标 / devices/icons

| 当前文件名 | 原始中文文件名 | 资源类型 | 生成用途 | 交付模式 | 人工修改 | 可进运行时 | 预计接入 |
|---|---|---|---|---|---|---|---|
| 加固层盾牌_fortify_shield_v01.png | 加固层盾牌状态.png | 状态图标 | 加固层状态 HUD 盾牌图标 | 完整背景 | 否 | 否（待切透明/缩小） | v0.2.x HUD |

## 四、特效纹理 / vfx/textures

| 当前文件名 | 原始中文文件名 | 资源类型 | 生成用途 | 交付模式 | 人工修改 | 可进运行时 | 预计接入 |
|---|---|---|---|---|---|---|---|
| 能量波纹环_energy_ripple_ring_v01.png | 能量波纹环.png | VFX 纹理 | 吸弹/转换等波纹特效 | 透明背景 | 否 | 可试用 | v0.2.x VFX |
| 护盾裂纹_shield_crack_v01.png | 护盾裂纹.png | VFX 纹理 | 加固层被击中裂纹特效 | 透明背景 | 否 | 可试用 | v0.2.x VFX |
| 区域控制脉冲_region_threshold_pulse_v01.png | 区域控制脉冲.png | VFX 纹理 | 区域控制阈值脉冲特效 | 透明背景 | 否 | 可试用 | v0.2.x VFX |

## 五、状态说明

- **v0.1 阶段不用这批素材**：当前 Cardfront lite 效果全为逻辑，无 sprite/VFX。
- **v0.2.x card UI / device visuals** 阶段再接入卡牌图、装置精灵、图标。
- **VFX 纹理**可先试跑，但当前没有粒子/AudioStreamPlayer 管线。
- **所有素材为 AI 生成**，仅限本项目使用，不对外做第三方 pack 分发。
- **所有素材均未人工修改**，接入前可能需要裁切、去背景、缩放、调色。

## 六、Runtime 派生图 / cardfront_runtime

v0.1.7c.1 已从 1024 源图批量导出 runtime 尺寸：

| 源目录 | 导出目录 | 尺寸 | 处理 |
|---|---|---|---|
| 卡牌插图_cards_illustrations/ | cardfront_runtime/卡牌插图_cards/512/ | 512×512 | Lanczos 缩放 |
| 装置地图精灵_devices_map_sprites/ | cardfront_runtime/装置精灵_devices/96/ | 96×96 | 自动背景透明 + Lanczos 缩放 |
| 装置图标_devices_icons/ | cardfront_runtime/装置图标_icons/48/ | 48×48 | 自动背景透明 + Lanczos 缩放 |
| 特效纹理_vfx_textures/ | cardfront_runtime/视觉特效_vfx/128/ | 128×128 | 保留透明度 + Lanczos 缩放 |

处理脚本: `tools/process_cardfront_assets.py`

- `CardfrontDeviceOverlayLayer.gd` 已接入 runtime device sprites (96×96)。
- 装置图自动抠背景为采样角落色+阈值 60，结果需人工检查修图。
- VFX 和卡牌图暂未接入渲染层。

