BallWar v1.9.7

安全与稳定性收口版：
1. 终局后清理已有子弹，避免胜利后地图继续被改写、炮台继续受伤。
2. 读档 grid_size 增加白名单校验，仅允许 10/20/30/40/50/60。
3. 读档增加版本检查，仅允许 save_version 以 1.9 开头的存档。
4. 读档 bullets / control_balls / trail_points 增加数量上限：
   - MAX_RESTORE_BULLETS = 300
   - MAX_RESTORE_CONTROL_BALLS = 8
   - MAX_RESTORE_TRAIL_POINTS = 8
5. 读档 burst_remaining / burst_total / burst_index / pending_count / locked_remaining 全部按 GameConfig.MAX_PENDING_COUNT 夹住。
6. 控制仓防卡检测增强：
   - 除了低速不动，还检测“靠墙且 y 坐标长期不下降”的墙边抖动卡住。
7. 画面尺寸从 1180×700 微调为 1160×720，横向略收、纵向略放。
