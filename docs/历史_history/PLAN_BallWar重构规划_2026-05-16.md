> **历史方案归档** | 归档日期: 2026-08-18 | 来源: BallWar重构规划.docx
>
> **状态**: 已执行完毕：本仓库即该规划产物（BallWar 底座复用 + Cardfront 上层新增）。
文中模块复用表（Battlefield/BulletPool/Turret/SaveGameCodec）为现行架构的历史依据。
>
> 现行唯一状态入口: `docs/PROJECT_STATUS.md`。本文件为 docx 原文转写（表格已拍平为文本行），不再维护。

# BallWar 重构规划 - 受控重构策略与模块复用边界

《Marble Dominion: Cardfront》弹珠领土：卡牌前线
基于 BallWar 的专业游戏开发重构规划
目标：保留弹珠占领、炮塔、Battlefield、BulletPool、测试与发布底座，新增区域经济、卡牌构筑、单位部署与 AI 对抗。
执行结论：建议新建一个独立工作文件夹或 Git 分支来做 Cardfront 重构，但不是“随便复制后乱改”。专业做法是保留 BallWar 主线稳定，先创建 cardfront-prototype 分支或兄弟目录工作副本；第一阶段只做新模式入口和双阵营战场，验证后再抽成新仓库或正式版本。
0. 关键结论：应该新建文件夹复制过去重构吗？
结论：可以，但要按“受控重构”的方式做。你的情况最适合“两层保险”：Git 分支 + 新工作目录。
方案
适用场景
推荐程度
说明
只在原 BallWar main 上改
不推荐
低
容易把稳定版本改乱，后续 release、README、测试都会被新方向污染。
在 BallWar 新建 cardfront-prototype 分支
短期验证
高
最适合前 1-2 周：复用完整工程，不破坏 main。
新建兄弟文件夹 BallWar_CardfrontPrototype
大改目录和玩法
高
适合你现在这个方向：可以大胆重构，但保留原项目可回退。
新建全新仓库从零写
玩法验证后
中
等垂直切片证明好玩，再考虑拆为正式 Cardfront 仓库。
推荐路径：
1. 保留原 BallWar 文件夹不动。2. 从 GitHub clone 或复制一份到 BallWar_CardfrontPrototype。3. 在新目录中创建 cardfront-prototype 分支。4. 第一阶段只新增 Cardfront 模式，不删除旧模式。5. 等 v2.2.3 垂直切片成立后，再决定是否独立成新仓库。
不要做的事：不要直接把 BallWar 原目录改到无法回退；不要一开始删除事件转盘、四阵营模式、旧 UI；不要先大规模改 Main.gd。先新增 CardfrontMode，把新系统挂在旁边。
1. 产品定位与设计边界
Cardfront 的定位不是“卡牌游戏套皮”，而是 BallWar 的策略化进化：子弹仍然是战场主角，卡牌只是改变子弹、炮塔、地图和单位之间的规则。
层级
设计内容
玩家感受
10 秒循环
观察前线压力，打出一张卡：改炮塔角度、放反弹板、派吸弹单位、强化某类子弹。
我能立刻干预战场。
1 分钟循环
争夺能源区、工厂区、实验室，形成能量和零件产出。
占领不是面积数字，而是经济来源。
8-10 分钟循环
形成反弹流、吸弹流、经济流、干扰流、堡垒流。
一局有构筑成长和反转。
v0.1 必须做
玩家 vs AI 双阵营对抗
40x40 默认地图，60x60 可选
4 类区域：普通区、能源区、工厂区、实验室
2 种资源：能量、零件
先做 6 张卡跑通，再扩到 12 张
8 分钟结算、70% 占领胜利或经济评分胜利
复用 BallWar 的 BulletPool、Battlefield、Turret、测试和发布体系
v0.1 明确不做
不做 PvP，不做联网同步
不做完整 Roguelite 长线成长
不做超过 2 种资源
不做几十张卡牌
不做复杂单位寻路和复杂 AI
不做大地图战役
不把随机转盘继续作为核心胜负机制
不在每帧全图扫描经济，不在主循环频繁 new 对象
2. BallWar 复用策略
BallWar 已经具备 Godot 4.6、GDScript、Windows/Android、headless tests、CI、存档、性能探针、事件系统和架构分层。Cardfront 应该复用底座，新增玩法上层。
BallWar 模块
Cardfront 中的用途
处理方式
风险
Battlefield
格子归属、占领统计、基础绘制
保留；旁路新增 RegionMap、defense/effect 层
不要把经济逻辑塞进 apply_bullet
BulletPool
对象池、子弹数量上限、轨迹压力控制
保留；给 Bullet 加 effect_tags 或 modifier
不要为每张卡新建一堆子弹类
Turret / ControlChamber
炮塔执行层、发射节奏、pending/burst 思路
保留；让卡牌修改 aim/fire modifier
不要让炮塔自己决定策略
EventRoulette
payload、banner、历史日志、持续效果思路
不做核心；另建 CardEffectResolver
不要把主动卡牌做成随机转盘
SaveGameCodec
版本、hash、字段清洗、恢复思路
新建 CardfrontSaveCodec，复用写法
不要把新字段硬塞旧 schema
TestAssert / TestFixtures
测试基础设施和样例构造器
高度复用并扩展 Cardfront 测试
每加一类卡都要有验收或测试
GameConfig
通用配置、画质、子弹阈值、颜色
保留通用项；Cardfront 专属规则放 CardfrontRules
不要让 GameConfig 变成全局垃圾桶
推荐目录结构
scripts/  cardfront/    CardfrontMode.gd    CardfrontRules.gd    RegionMap.gd    EconomyTickSystem.gd    CardData.gd    CardEffectData.gd    DeckManager.gd    HandController.gd    CardEffectResolver.gd    UnitManager.gd    AICommander.gd    CardfrontHUD.gd    save/      CardfrontSaveCodec.gd      CardfrontSaveStateBuilder.gd      CardfrontSaveStateApplier.gd    tests/      CardfrontModeSmokeTestRunner.gd      RegionMapTestRunner.gd      EconomyTickTestRunner.gd      DeckFlowTestRunner.gd      CardEffectResolverTestRunner.gd
3. 分阶段开发规划
Phase 0：建立 Cardfront 分支与安全边界
目标：让 BallWar 主线稳定，Cardfront 在分支或兄弟目录里开发。
内容
边界
验收
测试
• 新建 cardfront-prototype 分支• 新增 scripts/cardfront 目录• 新增 CardfrontMode.gd / CardfrontRules.gd• Main.gd 只负责装配，不承载玩法规则
• 不改子弹物理• 不改存档• 不改 UI 大布局• 不删除旧模式
• 旧 BallWar 模式仍能运行• 新 Cardfront 模式能进入和退出• CI 不减少，旧测试通过• 新增 smoke test
• CardfrontModeSmokeTestRunner.gd
Phase 1：双阵营战场改造
目标：把四阵营混战收束成玩家 vs AI，为经济、卡牌、AI 建立清晰目标。
内容
边界
验收
测试
• 新增 Player/EnemyAI/Neutral 映射• Battlefield 增加 reset_cardfront_duel()• 玩家与 AI 各保留一个炮塔• 先用 8 分钟占领结算
• 不做资源• 不做卡牌• 不做复杂 AI• 不做区域经济
• 玩家/AI 子弹能改格子• 中立区可被双方争夺• 占领统计只显示玩家/AI/中立• 8 分钟能结算
• CardfrontBattlefieldTestRunner.gd
Phase 2：RegionMap 区域层
目标：让地图从纯棋盘变成经济战场。
内容
边界
验收
测试
• 新增 RegionMap.gd• 新增 RegionOverlayLayer.gd• 实现普通区、能源区、工厂区、实验室• 中央高价值争夺点固定生成
• 不算资源• 不直接改 owners• 不做矿区/遗迹/据点• 不随机到不可测
• 40x40/60x60 可生成区域• 区域图标不盖住子弹• 同 seed 地图可复现• 资源区不生成在出生点
• RegionMapTestRunner.gd
Phase 3：经济 tick 系统
目标：让占领区域产生能量和零件。
内容
边界
验收
测试
• 新增 EconomyTickSystem.gd• 新增 PlayerResourceState.gd• 新增 EconomyHUD.gd• 每 1 秒结算一次资源
• 不每帧扫描全图• 不做数据资源• 不做复杂供应链• 不让 EconomyTickSystem 改地图
• 占能源区产能量• 占工厂区产零件• 失去区域后停止产出• AI 也可有隐藏资源
• EconomyTickTestRunner.gd• PerfEconomyTickBenchmark.gd
Phase 4：卡牌数据层
目标：先让卡牌以数据和状态机存在，不急着做漂亮 UI。
内容
边界
验收
测试
• 新增 CardData / CardEffectData• 新增 DeckManager / HandController• 新增 CardEffectResolver 骨架• 先做 6 张卡数据
• 不做商店• 不做删卡升级• 不做稀有度• 不做抽卡动画
• 可抽牌、打牌、弃牌、洗牌• 费用不足不能打• 打牌产生 effect_payload• payload 可被 resolver 识别
• DeckFlowTestRunner.gd• CardDataValidationTestRunner.gd
Phase 5：第一批卡牌效果接入战场
目标：让玩家在 3 分钟内看懂“卡牌真的改变战场”。
内容
边界
验收
测试
• 染色强化• 临时反弹板• 校准射击• 吸弹核心• 持续效果和自动清理
• 不做复杂动画• 不做多段连锁• 不做自由旋转反弹板• 不做单位寻路
• 打牌后 1 秒内有明显反馈• 效果结束后状态清理• 不破坏 BulletPool 回收• 无 orphan node
• CardEffectResolverTestRunner.gd• CardBattleIntegrationTestRunner.gd
Phase 6：AI Commander 第一版
目标：让 AI 从随机发射变成会争夺资源区的对手。
内容
边界
验收
测试
• 新增 AICommander• 扩张型 AI• 经济型 AI• AI 每 2 秒决策一次• debug 显示当前目标
• AI 不抽真实手牌• 不做复杂预测• 不做路径规划• 不每帧决策
• 扩张型前期有压力• 经济型优先抢能源/工厂• 目标为空有 fallback• 玩家不操作会逐渐失势
• AICommanderTestRunner.gd• AITargetEvaluatorTestRunner.gd
Phase 7：HUD 与可读性
目标：控制画面混乱，让卡牌、资源、子弹和区域一眼可读。
内容
边界
验收
测试
• CardfrontHUD• HandView / CardView• EconomyHUD• TargetPreviewLayer• 区域 tooltip
• 不做华丽动画• 不做复杂卡面美术• 不让 UI 遮挡战场• 不堆大段文本
• 能量/零件一眼可见• 手牌可读• 打牌有范围预览• 预览不残留• 子弹仍最醒目
• CardfrontHUDSceneTestRunner.gd• CardTargetPreviewTestRunner.gd
Phase 8：胜负、结算与完整一局
目标：让原型从系统测试变成完整一局游戏。
内容
边界
验收
测试
• CardfrontMatchController• CardfrontWinEvaluator• CardfrontResultPanel• 8 分钟计时• 70% 占领胜利或经济评分胜利
• 不做剧情结算• 不做长线解锁• 不做排行榜• 不做账号系统
• 一局能自然结束• 胜负原因清晰• 结算显示占领率/资源区/打牌数• 重新开始无残留
• CardfrontWinEvaluatorTestRunner.gd• CardfrontMatchFlowTestRunner.gd
Phase 9：存档与恢复
目标：保存和恢复 Cardfront 中途局面。
内容
边界
验收
测试
• CardfrontSaveCodec• SaveStateBuilder• SaveStateApplier• 保存 owners/region/resources/deck/units/ai/timer
• 不保存复杂动画状态• 不保存 UI hover• 不保存完整战斗日志• 不改坏旧存档
• 读取后地图、资源、手牌、单位、AI 状态一致• 无效存档能 fallback• 版本号和 hash 正常
• CardfrontSaveRoundtripTestRunner.gd• CardfrontSaveValidationTestRunner.gd
Phase 10：性能基线与发布准备
目标：让它成为可展示 release，而不是只在编辑器里能跑。
内容
边界
验收
测试
• PerfCardBattleBenchmark• PerfCardEffectStressBenchmark• README/CHANGELOG/TEST_MATRIX/PERFORMANCE 文档• Windows zip 和 Android APK 验证
• 不追求内容量• 不默认 60x60 高压场景• 不在低画质保留满特效
• 40x40 默认流畅• 60x60 可选• 中画质 MX330 尽量 >=45 FPS• release 包可运行
• PerfCardBattleBenchmark.gd• ReleaseSmokeTestRunner.gd
4. v0.1 卡牌与区域内容表
先做 6 张卡，跑通后扩到 12 张
卡牌
类型
费用
效果
技术重点
校准射击
炮塔卡
2 能量
8 秒内玩家炮塔更偏向指定区域发射
TurretAimModifier
染色强化
炮塔卡
2 能量
己方子弹占领中立/敌方格效率提高
Bullet effect_tags + Battlefield 查询 modifier
临时反弹板
地图卡
2 能量 + 1 零件
在指定区域生成临时反弹边界
ReflectorManager，先固定方向
缓冲带
地图卡
2 能量
区域内敌方子弹减速
区域 effect_layer
吸弹核心
单位卡
2 零件
吸收敌方子弹并转为能量
UnitManager + BulletPool recycle
前线动员
规则卡
4 能量
短时间提高边界防御
active_effects + defense_layer
区域 v0.1 范围
区域
v0.1 状态
作用
说明
普通地块
做
基础占领分
保持规则简单
能源区
做
持续产出能量
支撑打牌频率
工厂区
做
产出零件
支撑单位和地图机关
实验室
做简化
少量能量或后续升级入口
v0.1 先显示战略价值
矿区
暂不做
建造材料
先合并进工厂区
中立遗迹
暂不做
一次性奖励
v0.2 再加
前线据点
暂不做
防御强化
先由前线动员模拟
5. 模块职责边界
模块
负责
不负责
Battlefield
格子归属、占领统计、基础绘制
经济、卡牌、AI、区域产出
RegionMap
区域类型、区域图标、区域查询
改变归属、发放资源
EconomyTickSystem
固定 tick 资源结算
每帧扫描、卡牌执行、改地图
DeckManager
抽牌、弃牌、洗牌、手牌状态
卡牌具体效果
CardEffectResolver
执行卡牌效果、管理持续效果
UI、抽牌、AI 决策
UnitManager
部署单位、单位 tick、单位清理
炮塔发射、牌库管理
AICommander
AI 决策、目标选择、策略类型
复杂预测、真实玩家模拟
Turret
发射子弹、读取 modifier
经济策略、卡牌规则判断
BulletPool
子弹创建、回收、压力统计
卡牌效果决策、资源结算
CardfrontHUD
资源、手牌、目标预览、结算展示
规则计算
CardfrontSaveCodec
序列化、校验、恢复
玩法决策
6. 性能红线与工程纪律
Cardfront 会比 BallWar 多出卡牌、单位、区域、AI 和经济 tick，因此必须从第一天设置红线。
项目
v0.1 红线
地图
40x40 默认，60x60 可选，不默认超大地图
活跃子弹
沿用 BallWar 画质分档；中画质不主动超过 2800
单位数量
同屏不超过 20 个
经济结算
1 秒一次，不每帧遍历全图
AI 决策
2 秒一次，不每帧决策
同时 active card effects
不超过 8 个
反弹板
同时不超过 12 个
低画质策略
自动减少轨迹、粒子、区域特效
主循环分配
禁止在 _process/_physics_process/_draw 中频繁 new Array/Node/大对象
Mindustry 风格落地：主循环中尽量不分配对象；子弹、单位、临时效果都走池化或集中管理；拆职责，不机械拆三行小函数。
必须新增的性能测试
PerfCardBattleBenchmark.gd  40x40 + 1000 子弹 + 6 active effects  60x60 + 2000 子弹 + 10 反弹板PerfEconomyTickBenchmark.gd  60x60 全图区域产出模拟 8 分钟PerfCardEffectStressBenchmark.gd  20 单位 + AI 决策 + 8 active effects
7. 第一刀开发清单：v2.2.0-cardfront-prototype
下一步不要直接做卡牌。先把 Cardfront 作为一个新模式跑起来，得到“对抗版 BallWar”的稳定基线。
顺序
任务
完成标准
1
创建 BallWar_CardfrontPrototype 工作目录或 cardfront-prototype 分支
原 BallWar main 不受影响
2
新增 scripts/cardfront 目录
新代码不散落在 Main.gd 周围
3
新增 CardfrontMode.gd
可以被 Main.gd 装配
4
新增 GAME_MODE_CARDFRONT
开始菜单/调试入口能进入新模式
5
Battlefield 增加 reset_cardfront_duel()
玩家/AI/中立初始格局正确
6
保留两个炮塔发射
玩家与 AI 都能占地
7
新增 8 分钟结算
时间结束显示胜负
8
新增 CardfrontModeSmokeTestRunner
headless 运行无错误
9
新增 README_v2_2_0_cardfront_prototype.md
记录本轮只做了模式入口和双阵营基线
建议的本地文件夹操作
# 推荐方式 A：Git 克隆为新工作目录cd C:\Users\96967\Desktopgit clone https://github.com/2002yy/BallWar.git BallWar_CardfrontPrototypecd BallWar_CardfrontPrototypegit checkout -b cardfront-prototype# 推荐方式 B：已经有本地项目时# 复制整个 BallWar 文件夹为 BallWar_CardfrontPrototype# 进入新文件夹后先确认 git remote 和当前分支，再创建 cardfront-prototype 分支。
命名建议：文件夹可以叫 BallWar_CardfrontPrototype；仓库/正式项目后续再叫 MarbleDominion-Cardfront。不要一开始就把原 BallWar 改名，避免导出包名、截图、README、release 全部连锁变化。
8. 版本里程碑
版本
目标
完成标准
v2.2.0-cardfront-prototype
新模式入口 + 双阵营战场 + 8 分钟结算
Cardfront 可进入、退出、结算，旧 BallWar 不受影响
v2.2.1-region-economy
RegionMap + 能源区/工厂区/实验室 + 资源 tick
占领经济区会产生能量/零件
v2.2.2-card-core
卡牌数据层 + DeckManager + 6 张基础卡
能抽牌、打牌、扣资源，产生 effect_payload
v2.2.3-card-battle-slice
染色强化、反弹板、校准射击、吸弹核心
3 分钟内能看懂卡牌改变战场
v2.2.4-ai-opponent
扩张型 AI + 经济型 AI
AI 会抢资源区，玩家不操作会失势
v2.2.5-full-mvp
12 张卡 + 完整 8 分钟局 + 存档 + 性能基线
可玩、可赢可输、可保存、可测试、可发布
最终目标：不是把系统一次堆满，而是每个版本都有可玩、可测、可回退的增量。
附录：规划依据
资料
在本规划中的作用
用户提供的新方向文档
确定 Cardfront 核心循环、MVP 范围、资源/区域/AI/卡牌边界和性能风险。
独立游戏类型与 Godot 新游方向选型地图
确定 Deckbuilder、Grid Tactics、Automation、Roguelite 的组合方向，以及“成熟类型底座 + 独特机制 + 可完成 MVP”的选型原则。
BallWar GitHub README 与代码结构
确认 Godot 4.6、GDScript、测试、CI、存档、性能探针、Windows/Android 导出和现有架构可复用。
Battlefield.gd / BulletPool.gd / SaveGameCodec.gd / TestFixtures.gd
确认格子占领、对象池、存档校验、测试夹具是 Cardfront 的可复用底层。
