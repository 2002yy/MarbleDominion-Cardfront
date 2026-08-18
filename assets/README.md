# Assets / 资产总入口

本目录只放 Godot 项目可直接访问的 `res://assets/...` 资源与来源记录。**可编辑 Blender 母版不放这里**，统一放到仓库根目录 `art_source/`，并通过 `.gdignore` 与 Godot 导入管线隔离。

## 当前分区

- `cardfront/`：Cardfront 原始/生成的 2D 美术素材、提示词和源图片。
- `cardfront_runtime/`：Cardfront 已整理的 2D runtime 导出。
- `cardfront_environment/`：Cardfront 3D 环境与战场 presentation 资产。
- `ui/`、`背景_background/`、`音效_sfx/`：通用 UI、背景与音效资源。
- `ASSET_SOURCES_AND_LICENSES.md`：第三方/生成资产来源与许可记录。

## 3D 资产规则

`assets/cardfront_environment/source/` 是现有兼容区：当前 Registry 仍直接引用其中的 KayKit 与早期 custom GLB，因此本轮不搬动。

从 D21/D22 后新增的正式 3D runtime 资产进入：

`assets/cardfront_environment/formal/`

可编辑 Blender 母版进入：

`art_source/cardfront_3d/`

正式资产必须满足 `docs/art/` 中的 Material Role / Export Contract，并通过 validator + fixed-camera benchmark 后才算完成。

## 禁止

- 不把 `.blend` 当成 runtime 资产直接散入 `assets/`。
- 不因为目录整理移动仍被 `res://` 引用的现有资产。
- 不在玩法代码中新增散落 raw asset path；统一通过 Registry / presentation 层接入。
