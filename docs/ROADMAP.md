# Roadmap / 路线图

Role / 作用: main progress board / 主进度板

This file is the single place for project direction and phase status.  
这份文档只回答项目“已经完成了什么、正在推进什么、接下来做什么、哪些内容暂缓”。

## 1. Current Line / 当前主线

- Current line: `v0.1.x` Cardfront prototype / 卡牌前线原型线
- Current completed slice: `v0.1.1-a-region-map`
- Next slice: `v0.1.1-b-region-instances`
- Foundation baseline: BallWar / Marble Dominion Ricochet War `v2.1.11.1`
- Current theme:
  - region ownership as the strategic layer above Battlefield cell ownership
  - economy and deployment rules built from region control, not from bullet internals
  - card systems added only after region/yield/deployment boundaries are testable
  - keep `Battlefield`, bullets, turrets, and chambers reusable for old BallWar modes

## 2. Cardfront Version Plan / 卡牌前线版本规划

| Version | Status | Scope |
|---|---|---|
| `v0.1.1-a-region-map` | Done / 已完成 | Region types, deterministic `RegionMap`, Cardfront-only overlay. No economy tick, cards, or AI. |
| `v0.1.1-b-region-instances` | Next / 下一步 | Add `region_id`, explicit region instances, and region-control statistics. |
| `v0.1.1-c-region-yield` | Planned / 计划中 | Region-control yield with 50% / 80% thresholds. |
| `v0.1.2-region-morale` | Planned / 计划中 | Morale fluctuation system tied to region state. |
| `v0.1.3-deployment-rules` | Planned / 计划中 | Deployment permission by owned region, owned border, and region control degree. |
| `v0.1.4-fortify-layer` | Planned / 计划中 | Frontline fortification layer. |
| `v0.1.5-card-core-lite` | Planned / 计划中 | Pseudo-card core: fixed hand and energy costs. |
| `v0.1.6-first-card-effects` | Planned / 计划中 | First effects such as calibrated shot, pioneer beacon, and morale fluctuation. |
| `v0.1.7-unit-devices` | Planned / 计划中 | Device-style systems for bullet absorber core, engineer robot, and pioneer beacon. |

### Design Boundaries / 设计边界

- `v0.1.1-b` should add region identity and control statistics only; no resource income yet.
- `v0.1.1-c` is the first slice that may calculate region yield.
- Economy calculation must stay outside `Battlefield.apply_bullet()`.
- Card effects should wait until region/yield/deployment rules are already testable.
- Do not modify `Bullet`, `BulletPool`, `Turret`, or `ControlChamber` for region planning slices unless a later slice explicitly requires it.

## 3. Foundation Completed / 已完成基础

### Gameplay loop / 玩法闭环

- 四阵营战场争夺、角落炮台、控制仓发射节奏已经形成稳定闭环
- 基础模式、占领模式、限时模式、狂野模式已接入主流程
- 事件转盘、事件日志、胜负判断和对局结束流程已打通

### Save/load and orchestration / 保存恢复与编排

- `SaveFlowController` 已拆成 `prepare_*` / `apply_*`
- `RestorePlan.gd` 已进入主动恢复链路
- `ControlChamber.gd`、`Turret.gd`、`Bullet.gd` 各自拥有 `restore_from_state(...)`
- `Main.gd` 已明显收缩，主要承担顶层生命周期编排

### UI and product surfaces / UI 与用户面

- `StartMenu.tscn`、`GameHUD.tscn`、`SettingsPanel.tscn`、`ResultPanel.tscn` 已形成当前主 UI 结构
- 设置系统已接入：
  - 显示性能信息
  - 低特效模式
  - 事件日志显示开关
- 结算页已接入：
  - 胜利原因
  - 游戏时长
  - 最终占领率
  - 最高活跃子弹
  - 事件次数

### Runtime cleanup / 运行时收口

- `BattlefieldDecorLayer.gd` 从每帧轮询改为事件/脏标记模式
- `BulletPool.gd` 已维护峰值活跃子弹统计
- `EventRouletteController.gd` 已维护事件触发计数
- `ChamberState.gd` 已从 `ControlChamber.gd` 外提为纯状态容器

### Documentation cleanup / 文档收口

- `README.md` 作为仓库入口（9 个精选区块，链接到 `docs/`）
- `CHANGELOG.md` 作为精简版本脊柱
- `docs/`: `ARCHITECTURE.md`, `TESTING.md`, `PERFORMANCE.md`, `SAVE_SYSTEM.md`, `ANDROID_EXPORT.md`, `RELEASE_PROCESS.md`, `ROADMAP.md`
- `docs/history/` — 历史阶段记录
- `docs/technical/`, `docs/design/`, `docs/performance/` — 工程、设计、性能附录

### Public repository hardening / 公开仓库收口

- README 顶部重构：面向玩家/招聘官，30 秒看懂项目价值
- GitHub Actions CI workflow：validate + 10 测试并行 matrix，日志 artifact
- Android 导出脚本去本机绝对路径（`$PSScriptRoot` 相对路径）
- `export_presets.cfg` 三处不对齐修复（preset 名称、script_export_mode、version）
- 版本叙事三处统一（README / CHANGELOG / Releases 页面）
- 历史版本文档全部归档到 `docs/history/`，根目录保持干净

## 4. In Progress / 当前进行中

### Cardfront region model / 卡牌前线区域模型

- `v0.1.1-a-region-map` 已完成：
  - `RegionType.gd`
  - `RegionMap.gd`
  - `RegionOverlayLayer.gd`
  - `RegionMapTestRunner.gd`
- 当前下一刀是 `v0.1.1-b-region-instances`：
  - 给区域层增加稳定 `region_id`
  - 建立区域实例数据结构
  - 统计每个区域内玩家/AI/中立控制度
  - 暂不做经济 tick、卡牌和 AI

### Android export hardening / Android 导出固化

- 导出配置与资源压缩设置已基本对齐
- Debug APK 已进入 release 资产流；后续重点是签名包和可重复交付流程

### Chamber refactor phase 2 / 控制仓第二阶段拆分

- 当前已完成状态外提与 `ChamberBallPhysics.gd` 初步拆分
- 配套补充 `ChamberBallPhysicsTestRunner.gd`
- 后续再继续拆出几何、绘制和保存适配边界

### Public repo hygiene / 公开仓库整理

- Release 与主 README 已按 Latest Stable / Milestone / Historical 分层对齐
- 根目录已收束为外部入口，过程文档归入 `docs/`
- 已完成，转入下一阶段视觉与音效收口

### Performance evidence capture / 性能证据归档

- 性能探针脚本已存在
- 仍需要补齐更成体系的基线记录，尤其是高压弹幕与较大网格场景

## 5. Next / 下一步

1. **`v0.1.1-b-region-instances`**：region_id、区域实例、区域控制度统计
2. **`v0.1.1-c-region-yield`**：50% / 80% 控制度产出档位
3. **`v0.1.2-region-morale`**：民心起伏系统
4. **`v0.1.3-deployment-rules`**：部署权限：我方区域 / 我方边界 / 区域控制度
5. **`v0.1.4-fortify-layer`**：前线加固层

## 6. Later / 中期候选

- `v0.1.5-card-core-lite`：伪卡牌、固定手牌、能量消耗
- `v0.1.6-first-card-effects`：校准射击、拓荒信标、民心起伏等效果
- `v0.1.7-unit-devices`：吸弹核心、工程机器人、拓荒信标装置化
- 新手引导
- 模式说明页
- 更完整的结算统计
- Android 签名包与商店发布流程

## 7. Not Now / 暂不处理

- 在 `v0.1.1-b` 中提前做经济 tick
- 在区域实例前做卡牌和 AI
- 在性能基线不稳定前继续扩大弹幕规模
- 把 UI 重新塞回纯代码动态生成
- 把 `docs/history/README_v*.md` 当成当前真相入口
- 在没有边界设计前大规模增加复杂特殊事件或特殊球

## 8. Canonical Doc Split / 文档分工

- `README.md`
  - 项目入口，9 个区块链接到 `docs/`
- `CHANGELOG.md`
  - 精简版本脊柱
- `docs/ARCHITECTURE.md`
  - 系统分层、归属规则、架构原则
- `docs/TESTING.md`
  - 10 个测试 runner、分类说明、运行建议
- `docs/PERFORMANCE.md`
  - 性能探针概览与基线摘要
- `docs/SAVE_SYSTEM.md`
  - 存档槽、备份恢复、版本校验、输入清洗
- `docs/ANDROID_EXPORT.md`
  - Android 导出检查清单
- `docs/RELEASE_PROCESS.md`
  - 打包与发布流程
- `docs/ROADMAP.md`
  - 当前方向、已完成、下一步、暂缓项
- `docs/history/README.md`
  - 历史阶段索引
- `docs/technical/AI_HANDOFF_CURRENT.md`
  - AI / Codex 接管卡片
