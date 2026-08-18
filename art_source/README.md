# Art Source / 可编辑美术母版

本目录保存**可编辑 DCC 源文件**，与 Godot runtime 资产分离。

当前 Cardfront 3D 使用：

`art_source/cardfront_3d/`

其中 `.gdignore` 明确阻止 Godot 把 Blender 母版当成 `res://` runtime 资源扫描。

## 原则

- `.blend` 是 source master，不是 runtime asset。
- runtime GLB 由验证后的导出流程写入 `assets/cardfront_environment/formal/`。
- 源文件保留明确、稳定的模块结构和版本历史；正式 runtime 文件名不使用 `final/new/v002` 等人为尾缀。
- 第三方来源与许可继续记录在 `assets/ASSET_SOURCES_AND_LICENSES.md`。
- 不把大型临时 render/cache/benchmark 输出提交到这里。

D21/D22 之后，Cardfront 3D 的权威关系为：

`Blender source master → GLB contract validation → formal runtime asset → fixed-camera benchmark → GO`
