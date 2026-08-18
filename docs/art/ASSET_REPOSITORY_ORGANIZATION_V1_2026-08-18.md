# Cardfront Asset Repository Organization v1

日期：2026-08-18

目标：在不破坏当前 `res://` 路径、Registry 与 Godot `.import` 关系的前提下，把 Cardfront 资产仓库从“来源混杂”整理为“可编辑源 / Legacy 兼容 / Formal runtime”三层。

## 审计结论

当前仓库同时存在：

- `assets/cardfront/`：Cardfront 2D 原始/生成素材、提示词、卡牌图、战场实体等；
- `assets/cardfront_runtime/`：整理后的 2D runtime 导出；
- `assets/cardfront_environment/source/custom/`：早期自制 3D GLB；
- `assets/cardfront_environment/source/kaykit_medieval_hexagon/`：第三方 KayKit；
- `CardfrontEnvironmentAssetRegistry.gd` 直接引用上述 `source/...` 3D 路径。

因此本轮不能把 `source/custom` 直接改名或搬进新目录，否则会触发 Registry、Godot import cache 和 runtime path 连锁变化。

## 本轮落地结构

### 1. 可编辑源

新增：

`art_source/cardfront_3d/`

- 放 Blender source master；
- `.gdignore` 阻止 Godot 把 `.blend` 当 runtime 资源扫描；
- 第一母版建议 `Cardfront_HQ_Master.blend`；
- 与 runtime GLB 明确分离。

### 2. Legacy / Source Compatibility

保留：

`assets/cardfront_environment/source/`

- `custom/` 与 KayKit 原位不动；
- 现有 whole-model material override/tint 仍允许用于旧 presentation 兼容；
- 若旧资产进入正式大改，不继续在 legacy 原地堆补丁，优先转成新的 source master + formal runtime。

### 3. Formal Runtime 3D

新增：

`assets/cardfront_environment/formal/`

D21/D22 后的新正式 GLB 才进入这里。

第一批目标：

- `formal/hq/hq_common.glb`
- `formal/hq/hq_hero_balanced.glb`
- `formal/hq/hq_theme_castle.glb`
- `formal/hq/hq_damage_common.glb`

目录只建立 admission contract，不提前放空壳 GLB。

## 文件属性

`.gitattributes` 本轮显式补充：

- `*.gltf text eol=lf`
- `*.glb binary`
- `*.blend binary`

不在本轮引入 Git LFS 配置，避免在未确认团队/CI LFS 环境前改变仓库获取方式。

## 安全边界

本轮没有：

- 移动/删除任何现有图片、音频、GLB、glTF；
- 改 `CardfrontEnvironmentAssetRegistry.gd` 路径；
- 改 `EnvironmentBuilder` / arena / gameplay runtime；
- 改场景、测试、工作流；
- 删除历史资产或旧规范。

因此现有运行时路径保持不变，可回滚性不受影响。

## 后续正式迁移顺序

1. Formal HQ benchmark 打通 D21/D22 合同；
2. Registry 增加 `asset_contract/material_contract/module_role/...` 声明；
3. 实现 Material Resolver / validator；
4. HQ GO；
5. 再按 Gameplay Constraint Gradient 迁移 Tower → Gate/Fortification → Stronghold → Major Landmark；
6. O4 第三方 dressing 可长期保留 legacy adapter，不强迫全部重制。

## 验收

仓库组织 GO 的标准不是“目录变漂亮”，而是：

- 旧 runtime 引用零断裂；
- source/runtime 责任一眼可辨；
- 第一套 Formal asset 有明确落点；
- Blender master 不进入 Godot import scan；
- D21/D22 合同有可 diff 的仓库文本入口；
- 后续迁移不需要再次重构目录骨架。
