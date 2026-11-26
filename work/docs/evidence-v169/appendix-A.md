
---

# 附录 A · v1.69 执行结果摘要与证据索引（integrator / t45，2026-11-27）

> 本附录由集成发布任务追加，**不修改上文的用户原始测试计划**（原文 142 条用例、P0/P1/P2 分层、记录模板均保持原样）。
> 判定口径与用词约束见 `work/docs/V169-FINAL-VERIFY.md` §5：不写"通过/全过/门槛通过"。

## A.1 发布三元组（本条发布绑定的字节）

| 组件 | 版本 | sha256 | 说明 |
|---|---|---|---|
| 主应用 `com.dennis.dexpad` | **1.69 / 71** | `d31e51285a0a3baa71a75ed2b7dca1a7f88697685ae982c35e2f807bfc92c7fb` | 发布包 `release/dexpad-v1.69.apk`（assembleRelease） |
| 助手 `gpminput` | v1.69 | `b806f39ba51278a73aad121be4019820b7961dcb0935971b64d3a02373cd2a4d` | `gcc -O2 -static` 重建逐字节一致；APK assets / zip 内 / 设备两处同哈希 |
| padtest `com.dennis.padtest` | **1.4 / 5** | `0f4a91911360cb4051fff9b54711508e4dc90de797be6ec0e55e83e9a967056d` | 发布包 `release/padtest-v1.4.apk`（t60 最终） |

> **padtest 版本说明（与任务书 "padtest v1.2" 的偏差，如实记录）**：计划编写时 padtest 是 v1.2，但 v1.2 的整页
> `PassThroughScrollView` 引入了分页回归（t55 已删除该组件、恢复普通 `ScrollView`），v1.4 又修了内层 `vList` 被外层抢手势（t60）。
> 因此发布绑定 **v1.4（0f4a9191）**，而不是把 padtest 退回有已知回归的 v1.2。

## A.2 142 条用例的执行结果（三态）

| 指标 | baseline（t39，v1.68 首轮） | final（t62） |
|---|---|---|
| 用例行数 | 142 | 142 |
| PASS / FAIL / BLOCKED / NOTRUN | 35 / 6 / 101 / 0 | **37 / 5 / 100 / 0** |
| P0（56 条） | 39.3% | **41.1%**（23 PASS / 4 FAIL / 29 BLOCKED） |
| P1（84 条） | 15.5% | **16.7%**（14 PASS / 0 FAIL / 69 BLOCKED） |
| P2（2 条） | 0% | **0%**（0 / 0 / 2） |

- **发布门槛：未达**（P0 41.1% / P1 16.7%）。
- **维护者（captain）批准按偏差发布 v1.69**（2026-11-27），依据：`product FAIL = 0` + 100 条 BLOCKED 全部为测试通道/自动化缺口 + 关键行为已真机抽样覆盖。
- **可自动化上限 40–45/142**，其余以已知限制 + 真机抽样覆盖，**不虚报 PASS**。

## A.3 baseline 的 FAIL 项：三态结论

| ID | 三态 | 结论 | 证据 |
|---|---|---|---|
| MIX-009（P0） | **降级（经维护者批准）** | 分页文本「第 N 页」不随 `scrollX` 刷新（max 512 < 页宽 600），文本判据不可用；横向滚动能力由 SCR-022 用 `horizontal_scroll_x` 验证（Δ512） | `V169-HARNESS6.md` §11、`evidence-v169/report_s22*.json` |
| LOG-001 | **降级（经维护者批准）** | 日志页首屏无事件时不渲染文本行（a11y 空树），事件后正常；属页面初始态 | `evidence-v169/ui_log1.lines` |
| RPT-002 | **降级（经维护者批准）** | 结果行需 session 结束 + 导出才填充；按钮文案已修正 | `evidence-v169/ui_rpt2.lines` |
| RPT-003 | **BLOCKED(padtest-txt-export-missing)** | TXT 导出未落盘（JSON 已生成 409B）；属 padtest 导出实现 | 与 RPT-004 PASS 对照 |
| RPT-004 | **已修复** | 导出路径补 `/sdcard/Android/data/com.dennis.padtest/files/` → JSON 409B | `evidence-v169/t_rpt2.out` |
| BTN-001 | **已修复（应用侧 a11y）** | `ButtonDetailActivity` 补 contentDescription + IMPORTANT_FOR_ACCESSIBILITY_YES；复测 73 行、`400 ms` text=1 | `work/docs/APP-v169.md`、`ui_btn1.lines` |

> final 的 5 条 FAIL **全部不是产品缺陷**：3 条经批准降级 + 1 条 padtest 导出实现 + 1 条启动时序（复测已修复）。

## A.4 本轮修复清单（每项都有独立真机证据）

| 任务 | 修复 | 证据 |
|---|---|---|
| t47 | `P` 绝对定位改闭环：实测增益重估 + 最多 4 次修正（≤8px 提前退出）+ 落点回写共享页；日志 `POSPTR … closed gain=… final=… err=… iters=…` | 六点 ≤3px（本轮发布字节控制通道复测见 `verify_v169_extra.result.txt`） |
| t53 | SCR-022 横向锚点：横向独立冷却 + `ignoreCooldown` + 每 400ms `c` 被动同步真实光标；日志 `hswipe dir/nx/anchor/hidden` | `hx 0→512→0`（`APP-v169.md`） |
| t55 | padtest 删除整页 `PassThroughScrollView`（v1.3），恢复普通 ScrollView | `V 0 -640 120 …` 0→512→0（`PADTEST-v169.md` §5） |
| t60 | padtest v1.4：`vList` 在 ACTION_DOWN 时 `requestDisallowInterceptTouchEvent(true)` | 内层 `vertical_offset 0→2`、外层标题 603 不动（`PADTEST-v169.md` §7） |
| t48/t54 | root 控制通道 `gpmctl.sock`（0700 目录 / 0600 socket / `SO_PEERCRED` uid==0）+ detached drag | `HELPER-v169.md` §6；`?` CAP 13 项全 1、d/m/e frames=20/20 |
| t41（助手侧） | **无需修复**：基线 `product FAIL = 0`；`b806f39b` 与 v1.68 的 `a1d06e2e` 差异仅来自 t47/t48/t54/t59（各有独立证据）；探索性改动已回退 | `HELPER-v169.md` §8 |

## A.5 已知盲区（100 条 BLOCKED 的分组）

1. `ctl-channel-drag-not-delivered`（32 条）：helper 已发 `d/m/e`（getevent 可见 BTN_TOUCH+ABS_MT），应用端未收到 → MIX 主体无法自动判定；
2. `evidence-incomplete`：垂直滚轮 `S 8` 已发 `WHEEL 8 h=0`，padtest 无可读 offset；
3. `release-no-debug-channel`（v1.68 时期）：SCR-009/012/013 需按压中改 prefs；v1.69 起有了 root `gpmctl` 通道，可按需补测；
4. UI 二级交互（CFG 17、BTN 12、LOG 7、RPT 4）、长压测 8、DeX/多屏 6、真手柄 1。
5. **padtest 盲区**：`PassThroughScrollView` 历史（v1.2 引入、v1.3 删除）与 `vList` 手势（v1.4 修复）——现行行为以 t55/t60 为准，引用旧结论必须带这条标注。

## A.6 关键行为真机抽样（发布字节，套件外的独立证据）

- LB/RB 连续拖拽：100ms **71px** / 300ms 248px / 1500ms **1623px**（判据 150 / 450 / 1200–2200）；拖拽期间 SWIPE=0 / WHEEL=0。
- PiliPlus 1.5s：总位移 1643px、截图 **RMSE 31.33%**（≤40%）。
- 滚轮模式 RB/LB：**9 WHEEL / 0 SWIPE**。
- SCR-022：`horizontal_scroll_x` **0→512→0**；P 六点 ≤3px/≤2 iter；右摇杆 up=8/dy560、down=5/dy-480。
- 不得回退 6 项：d-pad+DPAD_CENTER、X 双击 400ms、X+LB/RB 方向、空闲隐藏 0px 恢复、SELECT 通知栏。

## A.7 证据索引

| 类别 | 路径 |
|---|---|
| 三态结论 | `work/docs/V169-FINAL-VERIFY.md`、`work/docs/V169-FINAL.md`、`work/docs/V169-BASELINE.md` |
| 套件与判据 | `work/docs/V169-HARNESS*.md`（§9–§13）、`work/docs/V169-HARNESS6.md` |
| 应用侧 | `work/docs/APP-v169.md`、`work/docs/REVIEW-v169*.md` |
| 助手侧 | `work/docs/HELPER-v169.md` |
| 测试台 | `work/docs/PADTEST-v169.md`、`docs/PADTEST-README.md`（v1.4） |
| 原始证据 | `work/docs/evidence-v169/`（final_all.out、scr_final.out、report_s22*.json、ui_*.lines、截图） |
| 发布字节复测 | `work/docs/evidence-v169/verify_v169_smoke.result.txt`、`verify_v169_extra.result.txt` |
| 装机校验 | `work/docs/INSTALL-v169.md` |
