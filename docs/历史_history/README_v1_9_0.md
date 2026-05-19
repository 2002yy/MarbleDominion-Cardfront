BallWar v1.9.0

更新内容：
1. 动态出口变化从“循环来回变”改为“随游戏进度单向变化”：
   - 开局发射口长、x2 短；
   - 随时间推进，x2 逐渐变长；
   - 约 5 分钟后达到最大；
   - 两侧保留最小宽度，避免某一出口过短导致卡住或长期无法触发。
2. 控制仓上下加长：
   - 高度从 214 调整到 240；
   - 纵向弹射点间距拉开；
   - 下落路径更宽松。
3. 控制仓比例参数继续集中：
   - CONTROL_BALL_RADIUS
   - PEG_RADIUS
   - PEG_SPACING
   - SIDE_EXTRA_CLEARANCE
   - WALL_EMBED_RATIO
   - ROW_3_OFFSET_RATIO
4. 继续保持动态出口的“视觉分界”和“触发逻辑分界”一致。
