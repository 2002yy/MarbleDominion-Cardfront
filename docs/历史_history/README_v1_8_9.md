BallWar v1.8.9

更新内容：
1. 控制仓宽度 / 控制球半径 / 弹射点半径 / 弹射点间距集中为一组固定比例参数：
   - CONTROL_BALL_RADIUS
   - PEG_RADIUS
   - PEG_SPACING
   - SIDE_EXTRA_CLEARANCE
   - WALL_EMBED_RATIO
   - ROW_3_OFFSET_RATIO
2. 控制仓宽度不再手写，而是由“弹射点比例参数”反推得到。
3. 底部 x2 / 发射口改为随时间动态变化：
   - 开局发射口较长、x2 较短；
   - 半个周期后反过来；
   - 两个出口都有最小宽度，避免某一侧过短导致卡住或长期无法触发。
4. 实际触发逻辑同步使用动态出口分界线，不只是视觉变化。
