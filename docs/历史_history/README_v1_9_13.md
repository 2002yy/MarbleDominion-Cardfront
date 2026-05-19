BallWar v1.9.13

本次更新：电脑 + 安卓适配版

1. 项目显示设置适配：
   - 基准逻辑分辨率保持 1120×720；
   - 开启 canvas_items stretch；
   - aspect 使用 expand；
   - Android 方向设置为 landscape；
   - 支持不同宽高比屏幕自动扩展显示区域。

2. 输入适配：
   - 开启 emulate_touch_from_mouse；
   - 开启 emulate_mouse_from_touch；
   - 电脑鼠标与安卓触摸均可点击 UI 按钮。

3. 手机横屏适配：
   - 开始菜单增加“电脑/安卓均可游玩 · 手机建议横屏”提示；
   - 暂停 / 退出按钮改为更大的触摸按钮，并向中心收，避开手机边缘和安全区域；
   - +球按钮扩大为更适合触摸的尺寸；
   - 暂停菜单按钮增大，便于手机点击。

4. 当前说明：
   - 游戏结构更适合横屏手机，不建议竖屏游玩；
   - Android 导出仍需在 Godot 中安装 Android export template，并配置 SDK/JDK 后导出 APK。
