BallWar v1.9.9

本次更新：
1. 新增 BulletPool 对象池：
   - 子弹不再频繁 new / queue_free；
   - 回收后复用，降低大量发射时的节点创建销毁成本。
2. 存档恢复子弹改为分帧恢复：
   - MAX_RESTORE_BULLETS = 5000；
   - RESTORE_BULLETS_PER_FRAME = 160；
   - 避免读档瞬间生成大量子弹导致卡死。
3. 大量子弹时简化拖尾：
   - 普通情况 trail_max_points = 8；
   - 活跃子弹超过阈值后 trail_max_points = 3；
   - 存档恢复的 trail_points 最多恢复 3 个。
4. 右下角新增 FPS 显示。
