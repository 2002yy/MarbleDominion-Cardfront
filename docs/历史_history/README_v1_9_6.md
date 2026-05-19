BallWar v1.9.6

本次更新：
1. UI 横向空间增加：
   - 视口从 1100×700 调整为 1180×700；
   - +球按钮增加安全夹取，确保右侧按钮不出屏。
2. 修复炮塔发射角度问题：
   - 定位原因：Turret.gd 的 _current_burst_shot_angle() 之前没有直接使用当前视觉 rotation，而是用较窄 fan_start/fan_end 再混合 rotation；
   - 已改为子弹方向直接跟随炮塔当前可见 rotation。
3. 存档升级为更接近“完整精确存档”：
   - 保存/恢复正在飞行的子弹：阵营、位置、方向、年龄、last_cell、拖尾；
   - 保存/恢复控制仓小球：位置、速度、半径；
   - 保存/恢复 release_ball_index，避免锁定恢复后找不到对应小球；
   - 保存/恢复炮塔摆动相位、rotation、burst_index、burst_timer、burst_total、burst_locked；
   - save_version 升级到 1.9.6。
