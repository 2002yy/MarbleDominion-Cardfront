# Repository Cleanup — 2026-08-18

## 1. 本次整理范围

本次只执行**低风险、可回滚、不改变运行时路径**的整理：

- 新增 `docs/README.md`，建立文档导航和权威级别；
- 新增 `docs/art/`，将新的正式美术/3D规范集中到一个入口；
- 新增本审计记录，明确哪些旧文件暂不移动以及后续迁移门槛；
- 不移动 `scripts/`、`scenes/`、`assets/`；
- 不删除测试、不改 Godot 逻辑、不改地图/碰撞/胜负权威；
- 不移动现有 `美术参考_art_reference/`，避免破坏已有引用和来源记录。

## 2. 当前结构判断

### 保持现状的部分

- 根目录已经保持了正常 Godot 项目边界：`assets/`、`scenes/`、`scripts/`、`docs/`、`addons/`、`archive/`。
- `archive/` 已有 `.gdignore`，适合继续作为真正的旧工程隔离区。
- `assets/cardfront_environment/source/` 已经把 KayKit 与 custom source 分开，不需要为“看起来更整齐”再次改运行时资源路径。
- `docs/cardfront_refactor_checkpoints/` 已经形成清晰的检查点集合，不拆散。

### 主要混乱点

`docs/` 根目录同时存在：

- 当前状态文档；
- 架构说明；
- P0/P1 dated execution specs；
- freeze/addendum/amendment；
- 实体/模拟方案；
- 平台说明。

它们在文件系统中处于同一级，容易让后续 Agent 把较旧的阶段性文档误当成当前权威。

因此本次优先解决“**入口与权威边界**”，而不是直接做大规模 rename/move。

## 3. 本次整理后的读取顺序

1. `docs/PROJECT_STATUS.md` — 当前状态唯一入口。
2. `docs/README.md` — 文档导航与分类。
3. 专题入口，例如 `docs/art/README.md`。
4. 具体工程规格/计划。
5. `docs/cardfront_refactor_checkpoints/` — 作为实施证据和验收记录。

阶段性日期文档不能因为日期看起来更晚，就自动推翻 `PROJECT_STATUS.md` 或专题冻结规范。

## 4. 下一轮可做、但本次不直接移动的候选

### `docs/design/`

候选：玩法设计、战场实体设计、地图/英雄/卡牌设计类文档。

### `docs/technical/`

候选：`ARCHITECTURE.md`、`B1_SIMULATION_MODEL.md`、Android/export/CI 等工程文档。

### `docs/history/p0/` 与 `docs/history/p1/`

候选：已经完成阶段使命、仅用于回溯的 dated batch、freeze、amendment 文档。

### 为什么暂不搬

物理迁移会改变相对链接。仓库当前有 README、PROJECT_STATUS、checkpoint、commit/PR 说明和可能的自动化脚本引用这些路径。未做全仓引用扫描时批量搬迁，可能制造“仓库看起来更整齐，但历史证据断链”的回归。

## 5. 后续物理迁移 GO 门槛

一次真正的文档目录迁移必须同时满足：

- 对每个候选文件执行全仓引用搜索；
- 更新所有 Markdown 相对链接；
- 检查 CI/脚本是否硬编码文档路径；
- `git diff` 仅包含预期移动和链接修正；
- 不修改任何 `res://` 运行时路径；
- 不删除测试；
- Godot headless/核心 CI 继续通过；
- 必要时保留 redirect/index 说明，保证历史 PR/issue 仍可人工定位。

## 6. 结论

本次整理把“当前真相、专题规范、实施证据、历史材料”四种角色分开，但刻意不做高风险的批量迁移。下一次若继续清理，应专门开一个 docs-only PR 进行 `design/technical/history` 物理归档，而不是与玩法或美术实现混在同一提交中。
