# Free UI Integration Plan / 免费 UI 接入计划

Project / 项目:
- `BallWar`

Target visual direction / 目标视觉方向:
- deep navy tactical HUD / 深海军蓝战术 HUD
- gold accent lines and headers / 金色强调线与标题
- clear four-faction color coding / 清晰的四阵营配色区分
- clean sci-fi panels, not heavy cyberpunk clutter / 干净的科幻面板感，避免过重赛博朋克杂讯

## Downloaded Packs / 已下载素材包

Stored in / 存放目录:
- `C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar\art_reference\free_ui_assets`

Verified downloaded files / 已确认下载完成的文件:
- `kenney_ui-pack-sci-fi.zip`
- `wenrexa_ui-scifi-minimalism-01_real.zip`
- `cats_tooth_free-scifi-backgrounds_real.zip`
- `game-icons_science-fiction_svg_white-transparent.zip`

Reference pages saved locally / 已保存到本地的参考页面:
- `kenney_page.html`
- `sungraphica_page.html`
- `hexui_page.html`
- `gameicons_scifi.html`

## License Notes / 授权说明

- Kenney UI Pack - Sci-Fi: CC0
- Wenrexa UI Sci-Fi Minimalism #01: CC0
- Game-Icons science fiction set: CC BY 3.0
- Cat's Tooth free sci-fi backgrounds: custom free-use terms, no redistribution as-is, no AI training/use

Practical rule / 实操规则:
- For shipping the game, Kenney and Wenrexa are the safest base packs. / 如果要正式进项目并最终发布，Kenney 和 Wenrexa 是最稳妥的基础包。
- If Game-Icons assets are used, keep attribution in credits. / 如果用了 Game-Icons，记得在鸣谢或 credits 里保留署名。
- Do not redistribute the Cat's Tooth background pack outside the project/art reference folder. / 不要把 Cat's Tooth 背景包原样再分发到项目素材目录之外。

## Recommended Use By Screen / 按界面推荐用法

### 1. Start Menu / 开始菜单

File targets / 对应文件:
- `scenes/ui/StartMenu.tscn`

Use / 推荐用法:
- Kenney for main panel frame, button bodies, slot containers / 用 Kenney 替换主面板边框、按钮主体、存档槽容器
- Wenrexa for secondary separators, glass strips, option rows / 用 Wenrexa 补二级分隔条、玻璃质感装饰、选项行
- Cat's Tooth for background art behind the menu shade / 用 Cat's Tooth 做菜单遮罩后的背景图

Replace first / 第一批优先替换:
- `RootPanel`
- `ConfigPanel`
- `SavePanel`
- `StartButton`
- `ContinueButton`

Keep / 建议保留:
- current layout proportions / 现有版式比例
- current blue/gold palette logic / 现有蓝金主配色逻辑

### 2. Game HUD / 游戏 HUD

File targets / 对应文件:
- `scenes/ui/GameHUD.tscn`

Use / 推荐用法:
- Kenney for the top panel shell and segmented bar frames / 用 Kenney 替换顶部总面板外框和分段条框体
- Wenrexa for slim overlays, gloss strips, info blocks / 用 Wenrexa 补细长覆盖层、反光条、信息块
- Game-Icons for small semantic icons near timer, stage, events, performance HUD / 用 Game-Icons 补计时、阶段、事件、性能 HUD 的小语义图标

Replace first / 第一批优先替换:
- `TopPanel/Bg`
- `TopPanel/AccentLine`
- `TopPanel/BarBG`
- the four segment shells around faction bars / 四阵营分段条外壳

Do not replace / 不建议替换:
- faction fill colors / 阵营填充色
- numeric readability layer / 数值可读性层

### 3. Event Roulette / 事件轮盘

File targets / 对应文件:
- `scenes/ui/EventRouletteView.tscn`

Use / 推荐用法:
- Wenrexa for the modal shell and internal dividers / 用 Wenrexa 做弹窗外壳和内部结构分隔
- Kenney for pointers, thin highlights, button-like readout frames / 用 Kenney 做指针、细高亮、类似按钮的读数框
- Game-Icons for effect icons / 用 Game-Icons 补事件效果图标

Replace first / 第一批优先替换:
- `StagePanel/Bg`
- `LeftPointer`
- `RightPointer`
- title/value containers / 标题与数值容器

Suggested icon mapping / 建议图标语义映射:
- jam/short circuit -> lightning or warning icon / 短路或卡阻 -> 闪电或警报图标
- x2/x3 -> target, energy, or power icon / x2 或 x3 -> 目标、能量、火力图标
- +1 ball -> orb, sphere, or plus-energy icon / +1 球 -> 球体、能量球、加成图标
- faction result -> faction color plus effect icon / 阵营结果 -> 阵营色加效果图标组合

### 4. Settings Panel / 设置面板

File targets / 对应文件:
- `scenes/ui/SettingsPanel.tscn`

Use / 推荐用法:
- Kenney for the base panel and buttons / 用 Kenney 做基础面板和按钮
- Wenrexa for compact list rows and toggles / 用 Wenrexa 做紧凑列表行和开关条

### 5. Background / Atmosphere / 背景与氛围

Use / 推荐用法:
- Cat's Tooth backgrounds only for menu, preview, or static promo scenes / Cat's Tooth 背景更适合菜单、预览场景、静态展示页
- do not use them under the battlefield if they reduce grid clarity / 如果会影响战场格子识别，就不要铺在主战场下面

Best use cases / 最佳使用位置:
- start menu backdrop / 开始菜单背景
- preview scene backdrop / 预览场景背景
- game over / victory / intermission screens / 结束、胜利、过场界面

## Priority Order / 推荐接入顺序

1. `StartMenu`
2. `GameHUD`
3. `EventRouletteView`
4. `SettingsPanel`
5. optional backdrop polish / 可选背景氛围补强

## Best Free Stack / 最推荐的免费组合

If we want the cleanest all-free setup / 如果要做一套最稳的全免费方案:
- Kenney = structural UI pack / Kenney 负责结构型 UI 框体
- Wenrexa = elegant sci-fi overlays and panel dressing / Wenrexa 负责优雅的科幻装饰和薄层面板感
- Game-Icons = event/status iconography / Game-Icons 负责事件与状态图标语义
- Cat's Tooth = menu backdrop only / Cat's Tooth 只负责菜单和展示背景

## Notes / 备注

- `SunGraphica` and `HexUI` were researched and their reference pages were saved, but they were not required to complete the first usable free pack bundle. / `SunGraphica` 和 `HexUI` 已完成检索并保存参考页，但当前这套可落地免费方案并不依赖它们。
- Existing UI is already close to the target in palette; the biggest gain will come from replacing flat `ColorRect` blocks with framed assets, not from changing layout. / 你当前 UI 的配色方向已经接近目标，最大的提升点不是重做布局，而是把扁平 `ColorRect` 替换成有边框和层次感的素材。
