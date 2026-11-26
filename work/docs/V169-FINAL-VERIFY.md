# V169-FINAL-VERIFY · 发布级复验结论（t43）

> **状态声明（2026-11-27，t63 修订版）**
> - **t43 为报告任务，非独立重跑**：final 数据来自 t62 的 `V169-FINAL.md`，以及 t38/t39/t52/t56/t58 各轮；本报告未新增采样。
> - **门槛判定：未达**（P0 41.1% / P1 16.7%）。**维护者（captain）批准按偏差发布 v1.69**，理由：`product FAIL = 0`；未达部分 100% 来自测试通道/自动化缺口（32 条 `ctl-channel-drag-not-delivered`、`evidence-incomplete`、`release-no-debug-channel`、UI 二级 40 条），且关键行为已用真机抽样覆盖（LB/RB 拖拽 PY 1415→0、PiliPlus 1623px、SCR-022 hx Δ512、P 六点 ≤3px、回归 8 项全绿）。偏差与证据索引见 §2（FAIL 三态）与 §3（修复清单）。
> - release note **不得**写“通过/全过”，必须披露 P0 41.1% / P1 16.7% / 100 BLOCKED / 未达门槛。
> - 偏差批准记录：captain，2026-11-27（t63 消息），批准范围仅限本次 v1.69 发布。
> 本文件是发布前的**结论性文档**，数据全部来自已完成轮次（t38/t39/t52/t56/t58/t62），本轮**未再跑数据**（避免重复采样与设备扰动）。
> 最终三元组（采样期间未变，ENV 门每轮实测）：app `da1e52d3c73ff8c8156ce89568385dd9f03f0b90fad7c68b5e0c7167531fdb44` / helper `b806f39ba51278a73aad121be4019820b7961dcb0935971b64d3a02373cd2a4d`（`gcc -O2 -static` 重建逐字节一致）/ padtest `0f4a91911360cb4051fff9b54711508e4dc90de797be6ec0e55e83e9a967056d`（v1.4/5）。
> 设备：SM-F9360 · 2560×1600 · Awake · rotation=1 · accel=0 · 无 vgpad。

## 1 三态与门槛对照

| 指标 | baseline（t39, v1.68 首轮） | final（t62） |
|---|---|---|
| 行数 | 142 | 142 |
| PASS / FAIL / BLOCKED | 35 / 6 / 101 | **37 / 5 / 100** |
| P0（56 条） | 39.3%（22/5/29） | **41.1%（23 PASS / 4 FAIL / 29 BLOCKED）** |
| P1（84 条） | 15.5% | **16.7%（14/0/69）** |
| P2（2 条） | 0% | **0%（0/0/2）** |

**门槛判定：未达（如实记录）；维护者已批准按偏差发布（见顶部状态声明与 §4）**

> **Maintainer override: captain, 2026-11-27, 依据 product FAIL=0 + 关键行为真机抽样 + 100 BLOCKED 全部非产品缺陷**
- 门槛要求 P0 全 PASS、P1 ≥95%；实际 P0 41.1%、P1 16.7%。
- **差额全部来自测试通道与 UI 自动化能力，不是产品失效**：
  1. `ctl-channel-drag-not-delivered`：helper 侧 `d/m/e` 已发（frames=20/emitted=20、getevent 可见 BTN_TOUCH+ABS_MT），应用端未收到 → MIX 主体 32 条无法判定；
  2. `evidence-incomplete`：垂直滚轮 `S 8` helper 已发 `WHEEL 8 h=0`，padtest 无可读 offset；
  3. `release-no-debug-channel`：SCR-009/012/013 需要按压中改 prefs，release 无 DebugReceiver；
  4. UI 二级交互（CFG 17、BTN 12、LOG 7、RPT 4）、长压测 8、DeX/多屏 6、真手柄 1。
- **已用真机抽样覆盖（v1.68 发布字节，非套件项）**：LB/RB 拖拽 padtest PY 1415→0、PiliPlus 1623px；SCR-022 `horizontal_scroll_x` 0→512→0；P 六点 ≤3px/≤2 iter；SCR-020 累计 2209px；E2E-001~006 全 PASS。

## 2 baseline → final：每条 FAIL 的三态

| ID（baseline FAIL） | 三态 | 实测/理由 | 证据 |
|---|---|---|---|
| **MIX-009**（P0） | **降级（经维护者批准）** | 分页文本「第 N 页」不随 `scrollX` 刷新（max 512 < 页宽 600），文本判据不可用；横向滚动能力已由 SCR-022 用 `horizontal_scroll_x` 验证 PASS（Δ512） | `V169-HARNESS6.md` §11；`evidence-v169/report_s22*.json` |
| **LOG-001** | **降级（经维护者批准）** | LogActivity 首屏无事件时不渲染文本行（a11y 树空），事件后显示「共 N 条」；属页面初始态，非手柄链路 | `evidence-v169/ui_log1.lines`（43 行空文本） |
| **RPT-002** | **降级（经维护者批准）** | 「开始测试」后结果行需 session 结束+导出才填充；按钮文案已修正（「开始测试」） | `evidence-v169/ui_rpt2.lines` |
| **RPT-003** | **BLOCKED(padtest-txt-export-missing)** | TXT 导出未落盘（JSON 已生成 `auto-report-latest.json` 409B）；属 padtest 导出实现 | `RPT-004` PASS 对照 |
| **RPT-004** | **已修复（实测）** | 导出路径补 `/sdcard/Android/data/com.dennis.padtest/files/` → JSON 409B 存在 | `evidence-v169/t_rpt2.out` |
| **BTN-001** | **已修复（应用侧 a11y）** | t40 修 `ButtonDetailActivity` a11y（contentDescription + IMPORTANT_FOR_ACCESSIBILITY_YES），复测 73 行、`400 ms` text=1；套件仍因 force-stop 后 Activity 未到前台抓不到，属启动时序 | `work/docs/APP-v169.md`；`ui_btn1.lines` |

> 说明：t39 基线列 6 条 FAIL 中的 MIX-009（P0）已由 SCR-022（P0）的 PASS 覆盖同一能力；其余 5 条均为测试台/页面态问题，**无产品缺陷**。

## 3 本轮修复清单与证据索引

| 修复 | 内容 | 证据 |
|---|---|---|
| **t47** P 绝对定位闭环 | 开环固定增益 3.25 → 实测增益重估 + 最多 4 次修正（≤8px 提前退出）+ 落点回写共享页；日志 `POSPTR … closed gain=… final=… err=… iters=…` | `work/docs/HELPER-v169.md`；六点 ≤3px（本轮 sockcmd：700,1000→703,1003 err -3,-3 iters=2） |
| **t53** SCR-022 横向锚点 | 横向独立冷却 + `ignoreCooldown` + 每 400ms `c` 被动同步真实光标；新增 `hswipe dir/nx/anchor/hidden` | `work/docs/APP-v169.md`；复测 `hx 0→512→0` |
| **t55** padtest 1.2 分页回归 | 删除整页 `PassThroughScrollView`，恢复普通 ScrollView | `work/docs/PADTEST-v169.md` §5；`V 0 -640 120 …` 0→512→0 |
| **t60** padtest 1.4 内层手势 | `vList` 在 ACTION_DOWN 时 `requestDisallowInterceptTouchEvent(true)` | `PADTEST-v169.md` §7；内层 `vertical_offset 0→2`、外层标题 603 不动 |
| **t48/t54** root 控制通道 | `gpmctl.sock`（0600+SO_PEERCRED uid==0）+ detached drag | `HELPER-v169.md` §6；`?` CAP 13 项、d/m/e frames=20/20 |
| **t41（助手侧）** | 无需修复：基线 `product FAIL = 0`，helper 行为未改；发布字节 `b806f39b` 与 v1.68 的 `a1d06e2e` 差异仅来自 t47/t48/t54/t59（各有独立证据）；t41 期间的一次探索性改动已回退（helper-eng 报告） | `HELPER-v169.md` §8 |\n| **t39/t52/t56/t58/t62** 套件 | P 六点、SCR-022 报告字段判据、截图 display/size 断言、MIX 统一理由 | `V169-HARNESS6.md` §9–§12；`V169-FINAL.md` |

## 4 发布建议

**门槛判定：未达。维护者（captain）已批准按偏差发布 v1.69 —— 见 §1 的 `Maintainer override: captain, 2026-11-27` 记录。发布文档必须如实写清以下三点：**
- **未达门槛的事实**：P0 41.1%、P1 16.7%、100 条 BLOCKED；release note **不得**写“通过/全过”。\n1. **覆盖率上限**：自动化 142 条中 PASS 37（P0 41.1%、P1 16.7%），其余 100 条为 `BLOCKED`（原因分组见 `V169-FINAL.md` §5），**不是**“全过”。
2. **P0 未达全 PASS 是已知差距**：差额来自测试通道（`ctl-channel-drag-not-delivered` 32 条、`evidence-incomplete`、`release-no-debug-channel`）与 UI 二级自动化缺口；已用真机抽样覆盖（LB/RB 拖拽 PY 1415→0、PiliPlus 1623px、SCR-022 hx 512、P 六点 ≤3px）。
3. **无产品缺陷**：5 条 FAIL 全部为测量口径/页面初始态/padtest 导出实现，`product FAIL = 0`。

**回归全绿（v1.68 已确认行为）**：连续拖拽 3 档（SCR-001/002/003：74/251/1621px，声称 73/238/1595）、速度五档与按压快照（SCR-009/010/011/012，其中 009/012 记 release 通道 BLOCKED）、滚轮 9 步（SCR-019/020：2209px 累计）、X+LB/RB 分页（SCR-022 hx 0→512→0）、右摇杆（SCR-021 up=8/dy560、down=5/dy-480）、d-pad+DPAD_CENTER（E2E-001）、X 双击 400ms（BTN-002）、空闲隐藏 0px 恢复（E2E-005/SCR-014）、SELECT 通知栏（E2E-004）。

**最小证据索引**：`work/docs/evidence-v169/`（2.97MB：final_all.out、v169_final.log、scr_final.out、t58_report2/*.json、t58/*.png、report_s22*.json）；设备 `/data/local/tmp/v169_evidence/20261127-030848/`、`/data/local/tmp/v169_20261127-030848.log`。

## 5 发布说明用词约束（v1.69 RELEASE-NOTES / README）

**禁止出现**：“通过”“全过”“门槛通过”“全部 PASS”。
**统一写法（三句）**：
- 「**product FAIL = 0**（37 PASS / 5 FAIL（均非产品缺陷）/ 100 BLOCKED）」
- 「**发布门槛：未达**（P0 41.1%、P1 16.7%），经维护者批准按偏差发布，偏差原因与证据索引见 §2/§3」
- 「可自动化上限 40–45/142，其余以已知限制 + 真机抽样覆盖，不虚报 PASS」

**PassThroughScrollView 历史标注**：凡提及 t42 新增的 `PassThroughScrollView`，必须同时写「该改动引入了分页回归与 vList 手势被抢，已分别由 t55（删除整页 PassThrough）与 t60（vList `requestDisallowInterceptTouchEvent`）修复；v1.3/v1.4 行为以 t55/t60 为准」。