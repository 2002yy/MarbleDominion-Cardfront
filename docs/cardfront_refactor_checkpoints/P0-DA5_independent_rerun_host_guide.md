# P0-DA5 Independent Rerun — Host Session Guide / 独立复验主持人引导摘要

Date / 日期: 2026-08-30

Source / 依据: [`P0-DA5_current_main_human_north_star.md`](P0-DA5_current_main_human_north_star.md)
（协议）; [`P0-DA5B_playtest_no_go_remediation.md`](P0-DA5B_playtest_no_go_remediation.md)
（修复记录）; launcher `scripts/tools/run_cardfront_p0_da5_session.ps1`.

Target runtime: remediation RC `9ec52d1`（当前 tip `7df8329`，代码一致）。

Role / 作用: 一页式主持人流程 + 提问词 + 场景观察表 + 判定勾选表。
**不是协议替代品**；逐字口径以协议为准。

---

## 0. 铁律（违反即整个会话作废，需换测试者重开）

- **主持人 ≠ 实现者**。实现代理不得担任测试者；本次复验必须找
  产品所有者之外、对实现无背景的独立人员。
- Phase A 六问未录完前，主持人**不得解释**：主路线/备用分支哪条是哪个；
  owned Support 为何会 offline；部署为何被拒；强力单位与低价控制单位的
  分工；失去前线后的恢复路径。只允许解释基本操作或解决启动问题。
- 不得用确定性夹具、截图包或自动化断言冒充人类理解证据。
- 旧 `def95b5` 会话、截图与封印一律不转移。

## 1. 会话前（主持人）

1. 启动器预检（自动做）：branch=main、HEAD==本地 origin/main==远端 main、
   工作树净、Godot 4.7.1、HEAD 含 `f2e4270` 祖先。
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/tools/run_cardfront_p0_da5_session.ps1
   ```
2. 确认证据目录 `artifacts/p0-da5-human/<时间戳>-<sha>/` 生成：
   `session_manifest.json`（源绑定已预填）+ 空白 `session_notes.md`。
3. 开录屏或准备逐字笔记。**测试者全程不被简报**路线与 Support 语义。

## 2. Phase A — 未简报首轮

让测试者走正常产品流程自由游玩。首轮结束后，按协议原话逐题提问，
**不提供预期答案词汇**，尽量逐字记录：

1. 两条路线在你看来有什么不同？
2. 为什么有的位置能部署、有的不能？
3. 某个战略点被压制或占领后，发生了什么变化？
4. 被推回之后，你感觉还剩哪些选项？
5. 哪些单位正面打赢了，哪些单位帮你把优势变成了控制？
6. 比赛在哪个时刻让你觉得胜负已定？在那之前是否存在可信的翻盘机会？

> 主持人自留判定表（不念给测试者）：
> Q1 双路线冗余 / Q2 ownership 与 online 部署可达性 / Q3 压制/占领后果 /
> Q4 Core 后备恢复 / Q5 战斗强度与控制的区分 / Q6 败方公平感。
> 六项都显出**实际理解**才算过关；含糊即不算。

## 3. Phase B — 托管覆盖（A 卷冻结后才允许提示状态）

逐场景在真实运行时完成，**不可用仅呈现夹具**。合理会话时间内无法到达
的状态 = 门禁失败。

| # | 场景 | 主持人观察点 |
|---|---|---|
| 1 | 正常推进 | 两路线是否都可用且推进自然 |
| 2 | 主路线丢失，备用分支仍有用 | 备用分支不是装饰、战略上仍可操作 |
| 3 | 失去全部前线 Support 后仅 Core 反击 | Core 后备**实际可用**，不是纸面 |
| 4 | 强力单位 + 低价控制单位把压力转成 Support 占领 | 控制单位角色可理解、不被强力单位掩盖 |
| 5 | 反复 Draft → 战场预览 → 返回 | 暂停保持、三选不变、可预测返回 |
| 6 | 至少一次可见 CapturedOffline 状态 | 状态可读、不阻碍战斗 |
| 7 | 在 owned-but-offline Support 尝试部署 | 测试者看到反馈后**自己解释出**为何被拒 |

## 4. 自动 FAIL 勾选表（出现任一项 → NO-GO）

- [ ] 源绑定 / 干净工作树 / 独立性 / Phase A 隔离缺失
- [ ] 备用桥读起来是装饰性或战略无关
- [ ] owned-but-offline Support 反复读起来可以部署
- [ ] Support 视觉阻碍活跃战斗
- [ ] Core 后备实际不可用
- [ ] 首个 Support 占领形成无翻盘窗口的不可阻挡自动刷兵链
- [ ] 低价控制单位在强力单位旁无任何可理解角色
- [ ] Draft 预览改变选项 / 解除暂停 / 无法预期返回
- [ ] 任一 Phase B 场景在真实运行时无法完成

## 5. GO 判定

全部满足才 GO：绑定字段齐全、独立性 YES、Phase A 未简报、七场景全完成、
无自动 FAIL、六项理解达标。

**模糊证据 = NO-GO（不是部分 PASS）**。NO-GO 将观察到的失败归还其所属
P0 合同，不授权平衡扩张或 P1。

## 6. 证据收口（主持人/评审）

补全 `session_notes.md` 剩余字段并**只选一个**结论：

```text
Tester: ___
Tester independent from implementation: YES / NO
Date/time: ___
Source commit: ___（launcher 预填，勿改）
Branch / local-and-remote origin-main match / clean worktree: ___（预填）
Godot version: ___（预填）
Recording or timestamped notes path: ___
Phase A unbriefed: YES / NO
Strategic hints before phase A answers: YES / NO
Unprompted answers 1-6: ___
Scenarios 1-7 completed: YES / NO per item
Observed failures: ___
Fair-chance finding: ___
Decision: GO / NO-GO
Reviewer: ___
Review date/time: ___
```

录完后：若 GO → 更新 `docs/PROJECT_STATUS.md` 门禁状态与时间线、
P0-DA5 协议 Gate report、并在 checkpoint 记录最终封印；若 NO-GO → 把失败
归还所属 P0 合同，锁新修复批次。P1 在封印前保持锁定。

## 7. 会话引导速查（主持人一页）

1. 启动器开跑 → 2. 测试者自由首轮 → 3. 录 A 卷六问（不提示）→
4. 冻结 A 卷 → 5. 托管七场景（观察表）→ 6. 勾选 FAIL 表 →
7. 评审独立填 `session_notes.md` → 8. 只选 GO/NO-GO → 9. 更新权威文档。
