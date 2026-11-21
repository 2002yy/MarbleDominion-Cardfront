# Targeted Deployment / 定向部署最小可玩原型（独立 Draft）

**Status: experimental, default OFF. No P1 authorization or formal P0 GO is claimed.**

## 启用与实际操作

在该 Draft PR 分支目录运行 Godot 4.6+：

```sh
godot --path . -- --cardfront-targeted-deployment-prototype
```

或在 Godot 编辑器的运行参数中加入 `--cardfront-targeted-deployment-prototype`（用户参数）。

1. 选择正式 Cardfront 1v1 地图和英雄，进入正常比赛。
2. 第一轮或后续轮的三选一中，选择 **「装甲护卫·定向部署（原型）」**；仅启用原型时，该选项才会进入玩家的三张卡中。AI 卡池不变。
3. 双方升级结算展示结束后，齐射暂缓；合法的 Core 或在线 Support 部署格以绿色 3D 方格标出，顶部提示进入定向部署。
4. 鼠标左键点击绿色区域，部署一名已有规则的装甲护卫，随后恢复自动齐射；或按 **Esc / 跳过** 不生成单位并恢复齐射。
5. 点击非法格不会改用其他自动选点；系统解释失败原因并刷新预览。部署权威/位置被改变时必须重新校验。

**不加此启动参数**，不创建原型控制器，不替换三选一选项，不绑定部署预览源，现役三选一和自动部署路径保持原样。

## 实现边界

- 仅使用现役 `CardfrontRoundDirector` 的升级结算暂停点。不扩展正式的18张升级池，也不恢复四卡手牌、经济、士气或 `CardfrontTargetPreviewLayer`。
- 只在 opt-in 时临时将玩家一张 Offer 替换为已有的装甲护卫；该卡正常提升 Selected Level，区别只在部署位置由玩家指定。AI Offer 不改。
- 玩家**主动点击**该强化才要求定向选点；如三选一倒计时结束后系统自动选中它，沿用自动部署，不让超时回合陷入新一轮等待。
- `CardfrontTargetedDeploymentPrototypeController` 负责输入/UI/选择状态；`CardfrontDeploymentZoneLayer3D` 继续只显示经判定的 `cells + revision`，不自行决定合法性。
- `DeploymentPlacementResolver.validate_exact()` 与自动放置复用同一个 `DeploymentRules.evaluate(SUPPORT_NETWORK)`；可用格还受现有单位数和每格槽位限制。
- **提交时再调用现役权威重新评估**，检查 Support 版本、当前地块归属和容量；不合法时拒绝提交且不消耗/替换玩家所选坐标。
- 通过现有的 `CardfrontAuthoritativeCreatureActionCoordinator.spawn_armored_guard_at()` 生成实体，沿用真实实体事件、表现、回合行动和数量上限，不生成仅用于展示的假单位。
- 无合法位置时自动跳过，不能把已暂停的对局锁死；取消不会扣除正常的弹幕/升级结算。

## 已知限制 / 未来产品决策

- **不是**正式可玩的持续性定向部署机制：原型仅覆盖装甲护卫一次点选，不覆盖维修单位多点部署、掘城单位或其他类型。
- Opt-in 模式固定提供一张护卫，扭曲随机 Offer 分布，**不得用于平衡统计**。
- 原型中未定义额外的手动部署存档/恢复语义，不新增正式存档字段；勿把实验中断恢复作为 P0 完成证据。
- 需要独立真人试玩确认：玩家是否理解 Support 失效/可部署区域、主动选位是否有价值、暂停时长是否破坏齐射节奏，以及点击反馈是否可理解。
- `docs/PROJECT_STATUS.md` 当前 P0-DA5B NO-GO、独立真人复测和 P1 锁定状态不变。只有实际玩法 GO 且产品负责人授权，才考虑将原型改成正式升级机制。

## 验证方式

```sh
godot --headless --path . --script res://scripts/tests/CardfrontUiClickThroughTestRunner.gd
godot --headless --path . --script res://scripts/tests/CardfrontDeploymentAutomaticSpawnTestRunner.gd
godot --headless --path . --script res://scripts/tests/CardfrontThreeChoiceRuntimeTestRunner.gd
godot --headless --path . --script res://scripts/tests/CardfrontLiveRuntimeBoundaryTestRunner.gd
```

UI 套件额外通过真实鼠标事件验证 Offer 点击、3D 投影反算、单位出现在选定格、暂停继续及 Esc 跳过；部署套件覆盖越界、过期 revision、撤销部署源并重新校验，不使用旧卡牌预览链。
