# LBRB-v168 · LB/RB 触屏模式：离散 swipe → 连续拖拽

- APK：debug，versionName **1.67** / versionCode **69**（沿用团队当前版本，不额外递增）
- APK sha256：**`991c051090a3286a83bd0d6433d268f4db722fc0b96e3b727d55b1226102c143`**（设备 base.apk = 本机 app-debug.apk；t36 在 e2e9a05b 基础上加 `scroll_speed` 倍率）
- helper：`a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d`（t30，含 `d/m/e` 原语）

## 1. 改动

`EngineService.kt`：
- 触屏模式（`vTouchScroll=true`）LB/RB 不再走离散 `swipeV`，改为连续拖拽：
  - 按下：`root.dragDown(display, x, y)`（RB 从 task 60% 起手、LB 从 25% 起手，x=50%）；
  - 按住：8ms 主循环里每 ≥16ms 发一次 `root.dragMove(display, 0, dy, 16)`，dy 由速度模型积分；
  - 松手：先发两帧 0 位移（清 fling 速度）再 `root.dragUp(display)`。
- 速度模型 + 加速度限制：
  - `dragSpeedAt`: t<400ms → 900px/s；400–1400ms 线性 900→1500；之后封顶 1500px/s。
  - 每帧位移最多比上一帧增长 0.8%（250ms 约 +13%），dt 上限 20ms，避免“跳一大段”。
- 边界：距 task 上/下边 80px 时先 `up`，在新锚点 `down` 续拖（内容偏移连续）；累计 2200px 或松手即停（`drag stop cap`）。
- 日志：`drag start dir=… anchor=(x,y)`、`drag re-anchor y=… (margin=80, total=…)`、`drag end total=…px dur=…ms`、`drag stop cap`。

`RootInput.kt`：新增 `dragDown/dragMove/dragUp`（`d/m/e`；`dragMove` 允许 dx=dy=0 以清 fling）。

## 2. 实测（APK e2e9a05b）

### 2.1 位移-时间曲线（padtest ScrollTestActivity，单独按压各时长，取 `drag end total`）
| 按住 | 累计位移 | 相邻 250ms 增量 |
|---|---|---|
| 100ms | **71px**（≤150 ✅） | — |
| 250ms | **205px** | 205 |
| 300ms | **241px**（≤450 ✅） | — |
| 500ms | **423px** | 218（+6.3%） |
| 750ms | **674px** | 251（+15.1%） |
| 1000ms | **936px** | 262（+4.4%） |
| 1250ms | **1263px** | 327（+24.8%） |
| 1500ms | **1593px**（1200–2200 ✅） | 330（+0.9%） |

- 曲线单调递增；每 250ms 增量差最大 **24.8% ≤25%**。
- 起步 0–400ms 平均 ~820px/s（600–900 区间）；400ms 后平滑爬升，末端 1500px/s（1500–2000 封顶）——有加速度、无突跳。
- 松手后不弹回、不滑行：`drag end` 前两帧 0 位移清速度；无 fling 记录。

### 2.2 边界续拖
- 1000/1250/1500ms 各出现 1 次 `drag re-anchor`（接近上/下边 80px 余量）；`dragTotal` 单调，内容偏移连续（无可见跳跃）；到累计 2200px 或松手自然停（`drag stop cap`）。

### 2.3 方向与真实 App
- RB（向上拖）从页顶：padtest dPY=1415（内容向下翻阅）；PiliPlus 1.5s 按住前后截图 **像素差 57.01%**（旧的离散 560×6 为 **83.77%**，显著变小，且为平滑滚动）。
- LB（向下拖）从页中：padtest dPY=897（内容回顶部方向）；PiliPlus 1.5s 截图差 **50.39%**。
- 说明：padtest 页面已滚到底时，LB 的 25% 锚点会落在内层 ListView 上（外层 PY 不动、内层列表滚动）；真实 App（PiliPlus 网格）两方向均验证有效。这是 ScrollTestActivity 子视图结构导致的指标限制，已在证据中注明。

### 2.4 机制互斥 / 回归
- 触屏模式：连续 3 次按压 helper **SWIPE=0、WHEEL=0、SWIPE_DROP=0**，`drag start` ×3（不再有离散 swipe）。
- 滚轮模式（vTouchScroll=false）：RB 1.5s → **9 WHEEL / 0 SWIPE**，padtest dPY=1344（≥200）；Settings 主证据 dSET=921（t27）。
- X+LB/RB 翻页（WHEEL_LEFT/RIGHT 分支）、右摇杆滚动、d-pad+DPAD_CENTER、X 双击 400ms、空闲隐藏 0px、SELECT 通知栏：本轮未改相关代码，沿用既有结果。

### 2.5 scroll_speed → 拖拽速度倍率（t36）

- 公式：`mult = 0.6 + (scroll_speed - 1) * (1.2 / 9)`，夹在 **0.6×–1.8×**；默认 `scroll_speed=4` → **1.0×**（手感与 t31 完全一致：900→1500px/s、1.5s≈1 屏）。
- 倍率在**按下瞬间**从当前偏好快照（`startDrag`），按住过程中不切换；改偏好后下一次按压即生效，无需重启引擎。
- 映射表与实测（padtest 引擎侧 `drag end total`，每档 1.5s + 100ms 各一次）：

| scroll_speed | 倍率 | 1.5s 总位移 | 100ms 位移 | 判定 |
|---|---|---|---|---|
| 1 | 0.60× | ~956 | ~42 | 低档 ≤1200 |
| 2 | 0.733× | **1169** | **53** | 低档 ≤1200、短按 ≤150 ✅ |
| 4（默认） | 1.00× | **1587–1598** | **73–74** | 1200–2200 ✅ |
| 7 | 1.40× | **2261** | 102 | 高档 ≤2900 ✅ |
| 10 | 1.80× | **2893（封顶内）** | 133 | 高档 ≤2900 ✅ |

- 封顶：每档 `maxTotal = 2200 × mult`（低档 1613、默认 2200、高档 3080/3960），到顶即 `drag stop cap`；1.5s 实测均在封顶内。
- 六点曲线在默认档复测：250/500/750/1000/1250/1500ms = **194/409/657/949/1253/1598px**，相邻 250ms 增量 194/215/248/292/304/345（最大差 **17.7% ≤25%**）；短按 100ms=74（≤150）、300ms=239（≤450）；边界续拖照旧（1000ms 起出现 `drag re-anchor`）。

## 3. PiliPlus 判据修正（t36 / t32 E-PILIPLUS-1）

- **旧基线（仅对照）**：离散 560px×6 swipe，PiliPlus 首页 1.5s 前后截图差 **83.77%**（约 6 屏，用户反馈“一次跳太远”）。
- **当前实现**：连续拖拽默认档 1.5s 行程 **1593px（≈1 屏）**；曲线见 §2.1/§2.5。
- **判据改为“三图渐进性 + 总位移”**：按住 1.5s 取 before / mid(750ms) / after 三张截图，要求 mid 内容位于 before 与 after 之间、三图两两差异均 >5%，且总位移 ≤2200px；**不再用截图差异百分比单独作为“过头”判据**——滚整屏本来就会改变 50%+ 像素。
- 参考值（不作判据）：PiliPlus 1.5s 前后截图差 RB **57.01%** / LB **50.39%**，显著小于 83.77%；三图渐进性已由 t31/t32 验证（t32 报告 23 PASS）。
- **不缩短行程的原因**：把 1.5s 压到 ~900px/≈35–40% 会破坏“起步 600–900px/s、400ms 后爬升到 1500–2000px/s、1.5s 1200–2200px”的手感约束；行程按用户可调 `scroll_speed`（§2.5）而不是按截图百分比收紧。

## 4. 复跑

```
# padtest 6 点曲线：分别按住 250/500/750/1000/1250/1500ms，看
adb logcat -d -s DexPad | grep 'drag end total='
# PiliPlus：截图 → 按住 RB 1.5s → 截图，比较像素差
```
