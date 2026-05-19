# BallWar / 领土战争 v1.9.20

本版只做警告清理与性能保护小收口。

## 修改内容

1. 修复 `Battlefield.gd` 中局部变量 `owner` 遮蔽 Node.owner 的 Godot warning。
2. 修复 `_format_time_text()` 中整数除法 warning，改为显式 `floori(float(...) / 60.0)`。
3. HUD 临时显示性能信息：FPS、active bullets、quality、grid size、pressure。
4. 中档最大活跃子弹数从 4200 降至 2800。
5. simple_draw 更早触发：低/中/高分别为 1200 / 1800 / 3600。
6. 拖尾点数下调：普通低/中/高为 2 / 4 / 6，中压拖尾为 2，高压为 1。
7. 炮台命中检测改为约 0.055 秒低频检测，并使用平方距离预筛，减少每帧 sqrt 开销。

## 备注

未改玩法核心逻辑，仍保持四控制仓决定四炮台发射、锁定期间不下球、子弹占格与炮台血量规则。
