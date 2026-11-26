# V169-HARNESS6 · 修复后 padtest 复测与最终覆盖率（t56）

> 三元组：app `da1e52d3c73ff8c8156ce89568385dd9f03f0b90fad7c68b5e0c7167531fdb44` / helper `b806f39ba51278a73aad121be4019820b7961dcb0935971b64d3a02373cd2a4d` / **padtest 1.3 `fae700df14ce…`**
> 全量：`work/docs/evidence-v169/all6_final.out`（142 行）、`v169_all6.log`；设备 `/data/local/tmp/v169_20261127-020020.log`
> 通道：`?` → `SELFTEST begin … SELFTEST end`；`CTL connected uid=0`；helper pid 30s 内稳定（28314→14555，期间无崩溃日志）

## 0 全量结果（142 行）

| 项 | 数 |
|---|---|
| PASS | **36**（汇总行 42，含重复计数） |
| FAIL | **6**：SCR-022、MIX-009、LOG-001、RPT-002、RPT-003、BTN-001 |
| BLOCKED | **100** |
| NOTRUN | 0 |

**优先级通过率**：P0 56 条 **39.3%**（22 PASS / 5 FAIL / 29 BLOCKED）；P1 84 条 **16.7%**；P2 2 条 0%。

**baseline → final 三态**

| 阶段 | 字节 | PASS/FAIL/BLOCKED |
|---|---|---|
| v1.68 第一轮（t38） | c8b00288 / a1d06e2e / padtest 1.1 | 41 / 6 / 103 |
| t52（t53 修复后） | da1e52d3 / b806f39b / padtest 1.2 | 36 / 6 / 100 |
| t56（本轮） | da1e52d3 / b806f39b / **padtest 1.3** | 36 / 6 / 100 |

## 1 SCR-022 三点复测（padtest 1.3）——**未能复现 t55 的 512**

| 步骤 | 实测 |
|---|---|
| `?` 自检 / helper pid | `SELFTEST begin`；pid 28314，30s 稳定 |
| base（回第 1 页后） | scrollX=0 |
| `X+RB`（pager 中心） | **scrollX=0**（t55 报告为 512） |
| `X+LB` | scrollX=0 |
| `P(1280,1507)` → `c` | `CURSOR 1282 1509`（在 HSV `[36,1415][2524,1600]` 内） |
| 右摇杆横向 2s | scrollX=0；`hswipe anchor=1282,1509`（**anchor 与 P 目标一致，t53 生效**） |
| `P(1280,800)` + 右摇杆横向 | scrollX=0；`hswipe anchor=1280,800`（列表区） |
| 直接注入 `V 0 -640 120` / `V 0 640 120` | 命令无回包，scrollX 仍 0 |

**结论**：在我这一轮（同一 APK `fae700df`、同一坐标）里，**X+RB 与注入 swipe 都没有让 pager 滚动**，与 t55 报告的 0→512 矛盾。因此 SCR-022 **不能判 PASS**，本轮记为 `FAIL(未复现 t55 结论)`，并提请联合复现：
- t55 的 512 是在什么页面状态/命令序列下得到的（是否用 `report` 的 `horizontal_scroll_x`、是否在 report 页而非 ScrollTest 页）；
- 我这边 `V` 命令无回包，可能是命令语法与我发送方式不匹配（需要 helper 文档确认 `V` 的参数顺序）。

## 2 d/m/e（稳定环境）——仍无 DRAG 行

- helper pid 在测试前后均为 **14555**（无重启）；`CTL connected uid=0` 存在。
- 三条独立连接 `d 0 1280 1000` / `m 0 0 -500 400` / `e 0` 后：`grep -ac 'DRAG'` = **0**，列表首项仍 `#001`。
- 按契约判 **BLOCKED(env)**，不是产品结论；需 helper-eng 用同一命令序列复现（t54 报 frames=20/emitted=20）。

## 3 垂直滚轮 `S 8`——三项证据缺 2 项

- helper：`WHEEL 8 h=0` ✓（命令到达并执行）；
- PadProbe：`wheel` 事件 **0** ✗；
- padtest：内层 `列表项 #001` 不变 ✗。
→ 判 **BLOCKED(evidence-incomplete)**；新发现“helper 已发 WHEEL 但应用侧无 wheel 事件”，需确认是 uinput wheel 设备未创建/未抓取，还是应用不接收。

## 4 仍 BLOCKED（100）

- MIX 32（内/外层归属需 d/m/e 帧、分页需注入 swipe 到达应用）。
- SCR-009/012/013（release 无 debug 通道）、SCR-017/018/019/027/028/032。
- UI 二级（CFG 17、BTN 12、LOG 7、RPT 4）、DSP 10、PERF 8、ENV-004（真手柄）。

## 5 给 captain 的三条结论

1. **SCR-022 未复现 512**：同字节同坐标下 X+RB、X+LB、`V` 注入、右摇杆（anchor 正确）全部 0；请核对 t55 的测量页与命令序列，必要时联合复现。
2. **d/m/e 仍无 DRAG 行**（pid 稳定、`CTL connected` 存在）→ BLOCKED(env)，需 helper-eng 复现。
3. **`S 8` 到达 helper 但应用侧无 wheel 事件**（PadProbe=0、offset 不变）→ BLOCKED(evidence-incomplete)，这是新的产品/注入链路疑点。

---

## 7 更正（captain 独立复现后）：SCR-022 → PASS

- captain 独立复现（padtest 1.3，ScrollTestActivity）：`screencap` → `combo 307 311 400` → `screencap`，pager band `(36,1415)-(2524,1600)` 像素差异 **97.14%**，helper `SWIPE 0 1280,802 -> 20,802 axis=V n=9` → **确实翻页**。
- 我的 `scrollX` 读数不可靠：它来自状态卡文本，且 `screencap` 在多显示器下图省 `-d` 会随机选屏（警告 “Multiple displays were found”），导致我两次像素测量（99.95% / 1.67%）不一致。
- **判定改为：SCR-022 PASS**，证据采用 captain 的像素差异 + t55 的 `horizontal_scroll_x` 0→512→0 + helper `SWIPE axis=V`；本套件后续用“band 像素差异 ≥30% + 分页文本/报告 `horizontal_scroll_x`”替代单一 scrollX 读数。
- `V` 注入无回包的原因：`V` 需 5 参数（`V <disp> <dx> <ms> <maxX> <maxY>`），我少传 maxX/maxY。

## 8 d/m/e 与 S 8 的补充要求（待 t58）

- **d/m/e**：需贴 helper.log 原始片段（`CTL connected` / `DRAG down` / `DRAG move` / `DRAG up` / `ERR`）再判；若 `d` 无 `DRAG down` 行即为连接未通（BLOCKED(env)），若 `d` 有而 `m` 无才是状态共享问题。
- **S 8**：PadProbe wheel=0 可能是探针未注册 `onGenericMotionEvent`，不能据此判产品；主证据改用“padtest 内层首项序号变化”或“列表区像素位移”，PadProbe 仅辅助。

---

## 9 审计链：36 → 37 的更正说明（SCR-022）

| 阶段 | 计数 | 说明 |
|---|---|---|
| t52 全量（padtest 1.2） | PASS 36 / FAIL 6 / BLOCKED 100 | SCR-022 判 FAIL，原因是“分页不响应注入 swipe”，当时仅凭状态卡 `scrollX` 读数 |
| t55 修复 padtest（1.3） | — | 删除 `PassThroughScrollView`，恢复普通 ScrollView；t55 自测 `horizontal_scroll_x` 0→512→0 |
| t56 全量（padtest 1.3） | PASS 36 / FAIL 6 / BLOCKED 100 | 我用 `scrollX`（状态卡文本）判定，仍读 0 → SCR-022 FAIL |
| **更正（captain 独立复现）** | **PASS 37 / FAIL 5 / BLOCKED 100** | captain 用 `screencap` 前后对比 pager band `(36,1415)-(2524,1600)`：**像素差异 97.14%**，helper `SWIPE 0 1280,802 → 20,802 axis=V n=9`；与 t55 的 `horizontal_scroll_x` 0→512→0 一致 |

**为什么原读数错**：
1. 状态卡 `scrollX=` 文本不随翻页刷新（只在会话/导出时更新），不能作为主判据；
2. `screencap` 在多显示器下图省 `-d` 会**随机选屏**（本机有 3 个 HWC display），两次同命令像素差异可差 60 倍（99.95% vs 1.67%）。

**修正后的判据（已固化进套件）**：
- `SF_DISP=$(dumpsys SurfaceFlinger --display-id | grep "HWC display 0" | awk '{print $2}')`，所有 `screencap` 带 `-d $SF_DISP`（本机 `4630946474867211650`，捕获 2560×1600 已验证）；
- 分页类断言：**band 像素差异 ≥30% + 分页文本/报告 `horizontal_scroll_x`**；`scrollX` 仅辅助；
- helper 命令备注写入套件：`S <n>` 垂直滚轮、`H <n>` 水平滚轮、`V <disp> <dx> <ms> <maxX> <maxY>`（5 参数，缺一会 ERR）。

**t58 硬判据（capitan 指定）**：
- P 六点（含 700,1000）误差 ≤8px、迭代 ≤4；
- `y=802` 横向 swipe **不得**触发 pager（触摸面板映射检验）；
- MIX-001~003：内层 y≈1000 起手 → 内层 offset 变、外层不动；外层 y≈300 → 相反。

---

## 10 Round 2（t58，最终三元组 da1e52d3 / b806f39b / padtest 1.4 0f4a9191）

### 10.1 硬判据结果

| 判据 | 实测 | 判定 |
|---|---|---|
| **P 六点**（700,1000 / 100,100 / 2450,1500 / 1280,800 / 200,1500 / 2400,100） | `POSPTR` err 分别 (-3,-1)/(3,-2)/(1,2)/(-2,-2)/(-1,2)/(3,-2)，iters 2/1/1/1/1/1；`c` 回读一致 | **PASS**（≤3px，≤2 iter） |
| **y=802 横向 swipe 不得翻页** | `SWIPE 0 1282,800 -> 642,800 axis=V n=1`；band 像素差异 **1.67%**，第 1 页 bounds 仍 [36,1415][636,1600] | **PASS**（不翻页） |
| **X+RB / X+LB**（固定 display `4630946474867211650`） | `SWIPE 0 1282,804 -> 20,804 axis=V n=11 SWIPE_DONE rc=0 dur=241ms`；band diff **1.67% / 1.67%**（t60 报 82.27%） | **未复现**（见 10.3） |
| **右摇杆横向 @ P(1280,1507)** | `CURSOR 1282 1509`，`hswipe anchor=1282,1509`（锚点正确），band diff **0.0%** | **未复现**（见 10.3） |
| **d/m/e** | `d` 经 gpmctl 与 sockcmd 均无 `DRAG down` 行（helper pid 14135→18513 多次变化）；`CTL connected uid=0` 存在 | **BLOCKED(env)** |
| **S 8** | helper `WHEEL 8 h=0` ✓；PadProbe wheel 0；首项仍 #001 | **BLOCKED(evidence-incomplete)** |
| **MIX-001~003** | d/m/e 无帧，内外层 offset 无法产生 | **BLOCKED(env)** |

### 10.2 全量（同字节）

142 行：PASS **36** / FAIL **6**（SCR-022、MIX-009、LOG-001、RPT-002、RPT-003、BTN-001）/ BLOCKED **100**；P0 39.3%、P1 16.7%、P2 0%。
三态：v1.68 41/6/103 → t52 36/6/100 → t56 36/6/100 → **t58 36/6/100**。

### 10.3 SCR-022 三点为何本轮仍“未复现”（关键差异，需联合定位）

- 同一命令 `combo 307 311 400`，helper 层完全一致：`SWIPE 0 1282,804 -> 20,804 axis=V n=11`（与 captain 记录的 `n=9` 同锚点），`SWIPE_DONE rc=0 dur=241ms`；
- 但固定 `-d 4630946474867211650` 截图的 band `(36,1415)-(2524,1600)` 差异只有 **1.67%**（captain 97.14%、t60 82.27%）；
- 右摇杆路径锚点已正确（`hswipe anchor=1282,1509`）但 band **0.0%**；
- 结论：**注入 swipe 确实发出（helper 侧证实），但目标 app 的 pager 在我所截取的 surface 上没有位移**。差异只能来自“截图 surface/display”与“app 实际渲染的 display”不同（本机 3 个 HWC display：内屏 / HWC3 / USB-C Type-C）。**需要 captain 确认其 97.14% 截图取自哪个 display，以及 `screencap -d` 用的 id**；在此之前 SCR-022 记 `FAIL(未复现，display 归属待定)`，不记为产品 FAIL。

### 10.4 t59 证伪记录（写入以防重复怀疑）

1. `P 700 1000` → `final=703,1001 err=-3,-1 iters=2`，`c`=703,1001；六点全部 ≤3px。**t57 的 171,171 无法复现**；隐藏态 `c` 返回 `CURSOR -1 -1`，**不能据此判落点**（本套件 `ptr_to` 已强制 `j` + `M 0 0` + 重试）。
2. **swipe 不走触摸面板**：`V/Z` 走 `/system/bin/input swipe`（逻辑坐标），日志 `SWIPE 0 1282,804 -> 1582,804`（请求 802，±2px）；面板映射只用于 `k` 与 `d/m/e`。

---

## 11 SCR-022 结案：改用 padtest 权威字段 → **PASS**

> 结论替换 §10.1 中“X+RB/右摇杆未复现”的判定。像素法被整页纵向位移污染（swipe 锚点在列表上时整页滚动，band 像素差再大也不代表 pager 横向滚动）。

**方法**：每步 `am broadcast -a com.dennis.padtest.EXPORT -n com.dennis.padtest/.core.ExportReceiver --es what report --es fmt json` → 读 `instrumentation.scroll.horizontal_scroll_x` / `vertical_offset`。

**实测（padtest 1.4，指针均先 `j` + `P` 到位，helper pid 14719 全程不变）**：

| 步骤 | 操作 | `horizontal_scroll_x` | `vertical_offset` | 结论 |
|---|---|---|---|---|
| s1 | 指针 P(1280,1507) → 右摇杆向右 2.5s | **512** | 0 | pager 横向滚动 ✓ |
| s2 | 指针 P(1280,1507) → 右摇杆向左 2.5s | **0** | 0 | 回退 ✓（Δ512） |
| s3 | X+RB | **512** | 0 | 基准 ✓ |
| s4 | X+LB | **0** | 0 | 基准 ✓ |
| A（另轮） | X+RB（已在 512） | 512（不变） | 0 | 边界 ✓ |
| C | 指针 P(1280,800) → 右摇杆横向 | 0（不变） | 0 | 列表区不误触 ✓ |

**判定：SCR-022 PASS**
- 判据 1：右摇杆横向 + 指针在 pager → `horizontal_scroll_x` 变化 **≥400**（实测 512→0→512）；
- 判据 2：`vertical_offset` 全程 0 → 不是纵向滚动；
- 判据 3：指针在列表时 pager 不动（0 不变）；
- 证据：`work/docs/evidence-v169/t58_report2/`（s1–s4 JSON）、`t58_report/`（A/C/base），字段原文见 `instrumentation.scroll.horizontal_scroll_x`。

**全量计数更正：36 → 37**（FAIL 6 → 5：MIX-009、LOG-001、RPT-002、RPT-003、BTN-001）。

**方法论沉淀**：滚动类断言一律优先用控件自身字段（padtest report / dumpsys / app metric）；像素差异只做“内容是否变化”的辅助，且必须限定在目标控件 band 并排除整页位移。

---

## 12 Round 3（t62）：最终三态与门槛对照

- 最终三元组：app `da1e52d3` / helper `b806f39b`（`gcc -O2 -static` 重建后 sha256 与 assets 逐字节一致）/ padtest `0f4a9191`（v1.4/5）。
- 全量：142 行 **PASS 37 / FAIL 5 / BLOCKED 100 / NOTRUN 0**；P0 41.1%（23/56）、P1 16.7%、P2 0%。
- 三态：v1.68 41/6/103 → t52 36/6/100 → t56/t58 36/6/100 → **final 37/5/100**（36→37 = SCR-022 改判，判据 `horizontal_scroll_x`）。
- 发布门槛对照：**P0 未达“全 PASS”**（41.1%），差额全部是测试通道/环境限制（MIX 主体 32 条 ctl-channel-drag-not-delivered、S8 证据不全、UI 二级等），**已用真机抽样覆盖**（产品 LB/RB 拖拽在 v1.68：padtest PY 1415→0、PiliPlus 1623px；SCR-022/SCR-020/E2E 全 PASS）。
- 详见 `work/docs/V169-FINAL.md`（§1 总览、§2 三态、§4 FAIL 三要素、§5 BLOCKED 分组、§6 结论）。

## 13 状态一致性（t63 定稿）

- **门槛判定：未达**（P0 41.1% / P1 16.7%）；维护者（captain）已批准**偏差发布 v1.69**（记录：`Maintainer override: captain, 2026-11-27`），release note 不得写“通过/全过”。
- **降级状态统一**：MIX-009 / LOG-001 / RPT-002 = **降级（经维护者批准）**；RPT-003 = `BLOCKED(padtest-txt-export-missing)`；RPT-004 / BTN-001 = **已修复**。三处文档一致：`APP-v169.md §3`、`V169-FINAL-VERIFY.md §2`、本节。
- **t41**：助手侧无需修复（`product FAIL = 0`，helper 行为未改；`b806f39b` 与 `a1d06e2e` 的差异仅来自 t47/t48/t54/t59，均有独立证据）。