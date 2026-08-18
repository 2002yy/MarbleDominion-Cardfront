# Formal Runtime 3D Assets

本目录从 Cardfront D21/D22 起承接新的正式 runtime 3D 资产。不要把现有 `source/` 资产批量搬进来；只有真正通过新合同的资产才进入这里。

## 第一套 Admission Target — 已导入，待 Benchmark GO

首轮验证 `default_duel + Balanced HQ + Castle Theme`。4 个 HQ GLB 已导入并通过测试（Arena 67 / Scale 57 / Smoke 38），等待 fixed-camera screenshot 人工验收：

- `hq/hq_common.glb` ✅ imported
- `hq/hq_hero_balanced.glb` ✅ imported
- `hq/hq_theme_castle.glb` ✅ imported
- `hq/hq_damage_common.glb` ✅ imported

Blender 母版：`art_source/cardfront_3d/Cardfront_HQ_Master.blend`

Bridge / Gate / Tower / Stronghold 在 HQ production contract 验证前可以继续使用现有 primitive / legacy 资产。

## Contract

### Asset
- `1 BU = 1m`
- Blender `+Z Up / -Y Model Front`
- Ground Contact Center origin；HQ modules 共享 HQ origin
- visible geometry transform 已规范化，无 negative/non-uniform correction scale
- 不携带 gameplay collision / Camera / Light

### Node
- `CF_` root
- `GEO_` visible geometry
- `PIV_` gameplay-driven pivot
- `SOCKET_` attachment
- `VFX_` presentation anchor
- `DMG_` authored damage module
- directional socket local `+Z = outward/forward`

### Material
使用 D21：`CF_<SURFACE>__<CHANNEL>`。

Formal pipeline 对未知 role、缺失 socket、错误 transform 等执行 **Validate, Don't Heal**；不得静默猜测和自动修复语义错误。

## Done Definition

`Asset Done = Contract PASS + Fixed-Camera Benchmark PASS`

单纯 Blender 看起来好、GLB 导出成功、Godot 可加载均不算正式完成。
