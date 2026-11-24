# REVIEW-drag-v168 · t31/t30 连续拖拽审查

> 任务：t33（审查 t30 助手拖拽原语 + t31 应用连续拖拽 + t32 证据）· attempt 1
> 审查人：reviewer · 时间：2026-11-25 00:45 CST · 设备：SM-F9360（adb 192.168.10.36:6666，横屏 2560×1600）
> 结论：**PASS（带 t15/t7 条件）**。触屏模式主路径已是 `d/m/e` 连续拖拽（不是“离散 swipe + 小参数”伪装）；速度模型 `dragSpeedAt(t)*mult` 与 t37 曲线 208/418/666/947/1242/1570（100/300/1500=74/242/1586）一致，无起步突跳；边界续拖 re-anchor 1740→2218、53/53 帧 17.8ms、停后 1s 无 move；助手 down/move/up 有 auto-up idle 1500ms、无 down 拒绝、越界夹取、drag 中单击/双指 abort；滚轮/翻页/右摇杆/d-pad/双击/空闲/SELECT 全 PASS。
> **t31 原始 APK `e2e9a05b` 的固定速度/PiliPlus 截图差判据已被 t36 的速度可调 + 三图渐进替代；最终产物是 t36/t37 的 `991c0510`（设备=本机，1.67/69）+ helper `a1d06e2e`；t31 原始态不能直接当发布证据（见 R1/R2/R4）。**

## 0. 被审对象与三轮演进

| 轮次 | APK/helper | 结果 | 关键差异 |
|---|---|---|---|
| t31 原始 | `e2e9a05b` / `a1d06e2e` | t32 通过（t31 的 8 条） | 触屏 LB/RB = 连续拖拽；速度固定 900→1500；PiliPlus 用截图差 57.01/50.39% |
| t36 修复 | `991c0510` / `a1d06e2e` | t37 复验 | `scroll_speed` 映射 mult 0.6–1.8（默认 4=1.0）；capStep/maxTotal；PiliPlus 改三图渐进 + 总位移 ≤2200 |
| t37 最终 | `991c0510` / `a1d06e2e` | **主套件 25 PASS/1 FAIL（H2 仪器时序）；专项重测 PASS** | 100/300/1500=74/242/1586；六点 208/418/666/947/1242/1570，18%；speed2/4/7=1167/1591/2255；无弹回；re-anchor 2218 |

## 1. t31 的 8 条 acceptance 核对（最终态 t37）

| # | acceptance | 判定 | 证据 |
|---|---|---|---|
| 1 | 触屏模式主路径是 down/move/up 连续拖拽，不是离散 swipe+小参数 | **PASS** | 源码 `EngineService.kt:1518 startDrag` → `:1534 root.dragDown`；`:1543 dragStep` → `:1564 root.dragMove`；`:1575 endDrag` → `:1580 root.dragUp`；`RootInput.kt:326-336 d/m/e`；helper `gpminput.c:1921/1961/1904 drag_down/move/release`；t37 F-TOUCH `SWIPE=0 WHEEL=0`（纯 d/m/e） |
| 2 | 速度曲线 250..1500 单调、100/300/1500 达标、无起步突跳 | **PASS（t37 默认档）** | t37 A-100=74≤150、A-300=242≤450、A-1500=1586∈[1200,2200]；B-CURVE 208/418/666/947/1242/1570，相邻增量差 18%≤25%；100ms 74 与 900px/s×0.1s=90 的差来自起步滤波，非突跳；t31 原始 205/423/674/936/1263/1593 同形 |
| 3 | PiliPlus 渐进滚动、总位移 ≤2200 | **PASS（t36/t37 口径）** | t37 PiliPlus 单次 1.5s total=1617；三次 500ms 累计 433/427/423，P0→P1 62.96%、P1→P2 59.26%、P2→P3 58.43%（两两 >5%）；t31 原始 57.01/50.39% 截图差是旧口径，已由 t36 §3 改为三图渐进（R2） |
| 4 | RB 页顶/LB 页底可达；边界续拖不跳段、到顶/到底停 | **PASS（带 LB 内层说明，R3）** | t37 B? RB 页顶 dPY=1415；LB 页底 dPY=1415；D-REANCHOR `re-anchor y=960 (total=1740)` → `drag end total=2218`；D-SMOOTH 53/53 帧 17.8ms；D-STOP 1s 内无新 move；t31 的 LB 25% 页底落入内层 ListView 是 padtest 特有，t36/t37 用真实 App + re-anchor 验证 |
| 5 | 触屏 SWIPE=0/WHEEL=0；滚轮 9 WHEEL/0 SWIPE | **PASS** | t37 F-TOUCH 0/0；F-WHEEL WHEEL=9/SWIPE=0；F-MOVE 设置列表 dSET=921≥200 |
| 6 | 3 次连续按压无串扰 | **PASS** | t37 C-CONSIST 3×1000ms=941/956/931（1.4%）；C-REBOUND 事件 2→2、截图差 0.15%；SWIPE_DROP=0 |
| 7 | 其它回归未改 | **PASS** | t37 G：X+LB +1258、X+RB −1262、右摇杆 Z=6/V=3、d-pad key_enter=1/mouse_click=0、Recents、隐藏恢复 0px+no correction、SELECT shade=12 |
| 8 | t31 原始 e2e9a05b 的 t32 证据 + 最终 t36/t37 | **PASS（最终态）** | t31 原始 8 条 + t32；t36 速度可调；t37 最终 25/1（H2 仪器时序）+ 专项 H2 PASS；最终 hash `991c0510` |

## 2. 源码核验

### 2.1 连续拖拽主路径

```kotlin
// EngineService.kt（t31/t36 最终）
1426/1437  startDrag(-1/1)                 // LB/RB 触屏模式
1518       startDrag(dir) { dragMult = 0.6+(cScrollSpeed-1)*1.2/9; …
1534         root.dragDown(dragDisplay, dragX, dragAnchorY) }
1543       dragStep(now) { capStep=dragSpeedAt(t)*dragMult*dt; …
1564         root.dragMove(dragDisplay, 0, dy, 16) }
1575       endDrag(now) { dragActive=false; root.dragMove(0,0,16)×2; root.dragUp(dragDisplay) }
```
`RootInput.kt:326-336`：`d <display> <x> <y>` / `m <display> <dx> <dy> <ms>` / `e <display>`。helper `gpminput.c:1921 drag_down`（MT 单指）、`:1961 drag_move`（只登记目标，主循环 `:1987 drag_tick` 每 `DRAG_STEP_MS=10ms` 发 `ABS_MT_SLOT+POSITION_X/Y+SYN`）、`:1904 drag_release`。**不是离散 swipe**：t37 F-TOUCH `SWIPE=0 WHEEL=0`，拖拽只走 d/m/e。

### 2.2 速度模型

- `dragSpeedAt(t)`（L1513）：t<400ms = 900px/s；400–1400ms 线性到 1500；≥1400 封顶；`dragMult = 0.6+(scroll_speed-1)*1.2/9`（1→0.6、4→1.0、10→1.8）；`capStep = dragSpeedAt(t)*mult*dt`；`maxTotal = 2200*mult`。
- 对应 t37：默认 4（mult=1.0）100/300/1500=74/242/1586；六点 208/418/666/947/1242/1570；250ms 增量 208/210/248/281/295/328，最大差 18%≤25%。t31 原始固定 900→1500 的 205/423/674/936/1263/1593 与之一致。**参数-曲线对应成立，无起步突跳。**
- 可调性：t37 speed2=1167（mult 0.733）、speed4=1591（1.0）、speed7=2255（1.4），单调；默认档 ∈[1200,2200]；引擎 pid 16326→16326 不重启；按压 1.7s 改 10 时起手仍 mult=1.0（t36 的按压快照）。

### 2.3 边界续拖

- `dragStep` 距边 80px：`dragUp` → `dragDown(newY)` 新锚点续拖（L1557-1561）；累计 `maxTotal` 或松手 `endDrag`（L1568/1575）；`endDrag` 两帧 0 move + up。
- t37 D-REANCHOR 1740→2218；D-SMOOTH 53/53 帧 17.8ms；D-STOP 1s 无 move。**源码 + t37 证明不会卡住/继续注入。**
- t31 的 LB 25% 在 padtest 页底落入内层 ListView 是 probe 页面结构；t36/t37 用真实 App + re-anchor 验证，不是控制逻辑缺陷（R3）。

### 2.4 助手安全（t30）

- `drag_down` 先 `drag_release("re-down")`；`drag_move` 只登记；`drag_tick` 超 `DRAG_IDLE_UP_MS=1500` → `auto-up idle`；无 down 的 move → `ERR drag move (no down)`；`d` 参数错 → `ERR d args`；越界 `drag_clamp_xy` 夹到 task；拖拽中单击/双指 `drag_abort_if_active` 先安全抬起。
- t30 证据：50 个 `ABS_MT_POSITION_Y` 间隔 9.21–10.46ms、越界 0、单调；padtest dx/dy 误差 0%；多段 down→3×move→up 53 事件；停发 1.8s auto-up 后单击正常；`?` 自检 ERR=0；smoke 95/ERR=0。**主循环非阻塞（move 登记算术，tick 发帧）。**

## 3. Findings（t31 原始态的真实缺口；t36/t37 已闭合；t15/t7 收尾）

| id | severity | problem | requiredFix | file:line |
|---|---|---|---|---|
| R1-T31-ORIGINAL-SPEED | **medium** | t31 原始 `e2e9a05b` 的触屏拖拽速度固定 900→1500（t32 的 205/423/674/936/1263/1593），不可调；t36 才把 `scroll_speed` 映射 mult 0.6–1.8、cap 2200*mult。t31 原始态不能当“速度可调”证据。 | t36 已修：`startDrag` L1521 `dragMult`；`dragStep` L1547 `capStep`；t37 speed2/4/7=1167/1591/2255、默认 1586。发布说明用 t37 的最终态，t31 原始速度只作历史。 | `work/docs/LBRB-v168.md` §2.5；`EngineService.kt:1513-1568`；`work/docs/VERIFY-drag-v168-t37.md:39-46` |
| R2-T31-PILIPLUS-METRIC | **medium** | t31 原始 PiliPlus 用“截图差 57.01%(RB)/50.39%(LB)，旧 83.77%”作判据；t36 改成“before/mid/after 三图渐进 + 总位移 ≤2200”，t37 实测 total=1617、三次 500ms 累计 433/427/423、两两 >5%。旧截图差百分比不是最终判据。 | 发布说明用 t36 §3 / t37 §3 的三图渐进 + total 1617；57.01/50.39/83.77 只作基线对照；不要把截图差当唯一判据。 | `work/docs/LBRB-v168.md` §3；`work/docs/VERIFY-drag-v168-t37.md:48-53` |
| R3-T31-LB-ANCHOR | low | t31 的 LB 25% 起手在 padtest 页底会落入内层 ListView（外层 PY 不动、内层滚动）；t31 已注明是 padtest 页面结构。t36/t37 用真实 App + re-anchor 验证，但 padtest 的 LB 页底覆盖仍弱。 | 保留真实 App 两方向证据（t37 PiliPlus/B?）；如要 padtest 也覆盖 LB 页底，改用外层可滚页或把 LB 锚点按当前 task 高度动态夹到外层；发布说明写清 padtest 限制。 | `work/docs/LBRB-v168.md` §3；`work/docs/VERIFY-drag-v168-t37.md:26-28` |
| R4-T31-FINAL-HASH | low | t31 `e2e9a05b`；t36/t37 `991c0510`；helper `a1d06e2e`。t31 输出说“新字节请 t15/发布重绑”；t37 已绑定最终哈希，但 t31/t32 的旧哈希仍在 LBRB/证据历史里。 | t15/t7 发布用 `991c0510` + `a1d06e2e`；t31 的 `e2e9a05b` 只作历史；WHEEL/拖拽文档统一最终哈希。 | `work/docs/VERIFY-drag-v168-t37.md:11`；`work/docs/LBRB-v168.md` |
| R5-T31-H2-NOSWITCH | low | t37 主套件首轮 H2-NOSWITCH FAIL（0.4s 改 pref → mult=1.8 total=2853）；根因是仪器时序（0.4s 在 drag start 之前），1.7s 复测 PASS（起手 mult=1.0、total=2212）。 | t37 报告 §4 已定位；后续套件把改 pref 放在 drag start 之后 ≥1.5s，或先等 `drag start` 日志再改；不要把首轮 FAIL 当产品回归。 | `work/docs/VERIFY-drag-v168-t37.md:55-58` |
| R6-T31-CAP-2212 | low | t37 的 1.7s 改 10 档：起手 mult=1.0、total=2212，而 `maxTotal=2200`；差 +12px（0.5%）。t36 的 cap 是 2200*mult，t37 的 2212 是 cap 判断在最后一帧后的累计，属容差。 | t36/t37 已接受 2212（0.5%）；发布说明写“≈2200（±1%）”，不要把 2212 写成严格 2200；如要严格，`dragStep` 在 cap 后截断最后一帧。 | `work/docs/VERIFY-drag-v168-t37.md:46`；`EngineService.kt:1568` |
| R7-T31-T30-MAPPING | info | t30 的虚拟触摸面板在本机被系统 90° 映射，已加 `touch_panel_xy()` 反解 + 启动时创建，非 2560×1600 退化为恒等；t30 的三点标定/证据成立。 | 保留 `touch_panel_xy` 与启动创建；后续换设备/分辨率需重新标定；发布说明写“本机 90° 映射已反解”。 | `gpminput.c:393-411`；`HELPER-v168.md` |
| R8-T31-T32 | info | t32 是 t31 原始 `e2e9a05b` 的证据；t37 是 t36/t28? 之后的最终复验。t31 的 8 条在最终态由 t37 覆盖，但 t32 的截图/日志不是最终 APK。 | t37 报告已绑 `991c0510`；t32 只作历史；发布引用 t37。 | `work/docs/VERIFY-drag-v168-t37.md:11` |

## 4. 结论与给 t15/t7 的条件

t31/t30 的**连续拖拽主路径、速度模型、边界续拖、助手安全、滚轮/回归**均成立；t31 原始 `e2e9a05b` 的固定速度/PiliPlus 截图差判据已由 t36 的可调 mult + 三图渐进替代，t37 在最终 `991c0510` 上复验通过。**t33 判 PASS（带条件）。**

t15/t7 发布前：
1. 绑定 **`991c0510` + `a1d06e2e`**；t31 的 `e2e9a05b` 只作历史（R4）。
2. 发布说明用 t37 的速度/曲线（74/242/1586、208/418/666/947/1242/1570、speed2/4/7=1167/1591/2255）与 PiliPlus 三图渐进/total 1617；不要用 t31 的 57.01/50.39% 截图差（R1/R2）。
3. H2-NOSWITCH 首轮 FAIL 是仪器时序，发布写“1.7s 改 pref 的专项 PASS”；不要把首轮 FAIL 当产品回归（R5）。
4. cap 写“≈2200（±1%，实测 2212）”；如要严格 2200，`dragStep` 截断最后一帧（R6）。
5. padtest LB 页底内层限制写清；真实 App 两方向证据为准（R3）；touch_panel_xy 的本机 90° 反解保留（R7）。

## 5. 复现

```sh
# 只读复核（本审查执行）
adb -s 192.168.10.36:6666 shell 'p=$(pm path com.dennis.dexpad | head -1 | sed s/package://); sha256sum "$p"'
#   991c0510…（= 本机 app-debug.apk）
adb -s 192.168.10.36:6666 shell su -c 'sha256sum /data/adb/gpm/gpminput /data/adb/modules/gpm_dex/gpminput'
#   a1d06e2e… / a1d06e2e…
grep -n 'startDrag\|dragStep\|dragSpeedAt\|dragMult\|maxTotal\|dragDown\|dragMove\|dragUp' \
  project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt | head -30
grep -n "case 'd'\|case 'm'\|case 'e'\|drag_tick\|DRAG_IDLE_UP_MS\|touch_panel_xy" \
  project/app/src/main/assets/gpminput.c | head -20
# 复跑 t37 见 VERIFY-drag-v168-t37.md §7
```

## 6. 限制

- 未在设备上重放拖拽（设备在 t15/t7 使用中）；t37 的 verify 日志/截图、LBRB-v168、HELPER-v168、t30/t31/t36 输出、源码为审查材料；本次做了只读 APK/helper hash、源码 L1513-1580/326-336/1921-1992/393-411、t37 25/1 逐项核对。
- t31 原始 `e2e9a05b` 的 t32 证据不是最终 APK；t33 的 PASS 是“t31+t36 最终态 + t37”，不是 t31 原始态单独 PASS。
- 拖拽中 screencap 陈旧帧（t37 §5）；PiliPlus mid 用分次累计 + 段间截图；帧间隔用 `dur/emitted`（17.9–18.1ms）作保守上界，不是逐帧 getevent。
