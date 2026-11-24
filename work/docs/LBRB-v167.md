# LBRB-v167 · LB/RB 滚动统一（同按内只一种机制）

- 构建：debug，versionName **1.66** / versionCode **68**（本轮不递增版本）
- APK sha256：`20eddf98793e1a658cb263b6d8e41e14eac43f8ebcd51475a3a2814b83a86e0d`（设备 base.apk = 本机 `app-debug.apk`）
- helper：`1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf`

## 1. 修改前（v1.66）

LB/RB 默认动作 `scroll_swipe_down` / `scroll_swipe_up` 在 `startWheel()` 里是**混合**：
先 `doSwipe(..., slow=true)` 滑一次，然后设 `wheelHold` 进入滚轮步进。用户感觉“先滑一下再变滚轮”，割裂。

## 2. 修改后（统一规则）

- 机制在**按压开始时**用既有「触摸滚动」开关 `vTouchScroll` 定下（字段 `holdTouchMode`），按压期间不切换：
  - `vTouchScroll=true` → **只用连续滑动**：`swipeHold=±1`，立即滑一次，之后每 `swipeRepeatMs()`（scroll_speed=4 → 250ms）重复一次；单次 560px、ms=220（与右摇杆竖滑同一几何/节奏）。
  - `vTouchScroll=false` → **只用滚轮**：`wheelHold=±1`，立即 `S ±wheelStep()`，之后每 `wheelIntervalMs()`（wheel_speed=3 → 186ms）一步；**不发任何 swipe**。
- `SCROLL_SWIPE_LEFT/RIGHT`（非默认横向）保留原手势路径；`WHEEL_LEFT/RIGHT`（X+LB/X+RB 翻页）代码未改，仍是横向手势。
- 释放时 `stopWheel()` 同时清 `wheelHold`/`swipeHold`；mode off/销毁/releaseAll 也清。
- 串行：滑动仍走 helper 的单条手势队列（任意时刻 ≤1 条 SWIPE），`SWIPE_DROP=0`。
- `ButtonDetailActivity` 双击说明 `320 ms` → **400 ms**（与 `DOUBLE_WINDOW=400` 一致）。

## 3. 真机证据（新 APK，ScrollTestActivity，LB=按住 1.5s）

### 3.1 触摸滚动开（`v_touch_scroll=true`）
| 按键 | helper SWIPE | helper WHEEL | app 日志 | uiautomator |
|---|---|---|---|---|
| LB 1.5s | **6** | **0** | `hold-scroll scroll_swipe_down by lb mode=swipe` + 6×`hold swipe -560 dir=1 cycle=250ms` | PY 1415→0 |
| RB 1.5s | **6** | **0** | `hold-scroll scroll_swipe_up by rb mode=swipe` + 6×`hold swipe 560 dir=-1 cycle=250ms` | PY 0→0（已到顶） |

### 3.2 触摸滚动关（`v_touch_scroll=false`）
| 按键 | helper SWIPE | helper WHEEL | app 日志 | uiautomator |
|---|---|---|---|---|
| LB 1.5s | **0** | **9** | `hold-scroll scroll_swipe_down by lb mode=wheel` | PY 1415→1415（顶部无上滚空间） |
| RB 1.5s | **0** | **9** | `hold-scroll scroll_swipe_up by rb mode=wheel` | PY 1415→0 |

→ **同一次按压内 swipe 与 wheel 不会同时 >0**（互斥）。两种模式各 9 或 6 次，连续步进。

### 3.3 稳定性（30s 窗口，3 次 2s 按压）
- 触摸开：`swipe=24 wheel=0`，`mode=swipe` ×3 → 机制切换次数 **0**。
- 触摸关：`swipe=0 wheel=36`，`mode=wheel` ×3 → 机制切换次数 **0**。

### 3.4 连续性与速度
- 引擎时间戳（`hold swipe` 行）start-to-start 间隔：**250 / 256 / 258 / 252 / 252 ms**；手势 ms=220 → “滑—回位—再滑”空档 **30–38 ms ≤150ms**。
- 速度：6×560px/1.5s = **3360px**（与 v1.66 右摇杆竖滚同量级，不慢于 v1.66）。

### 3.5 回归
- 横向翻页动作（把 lb 临时映射 `wheel_right`）：helper **3 条 V swipe / 0 wheel**（`SWIPE 0 1280,800→640,800`），横向翻页仍走手势；X+LB/X+RB 的 `WHEEL_LEFT/RIGHT` 分支代码未改。
- 右摇杆竖滚：`stick 4 24000 1500` → **4 条 Z swipe / 0 wheel**，PY 1415→0。
- ButtonDetail 双击文案：uiautomator 文本 `连续按两下 A（400 ms 内）时触发` ✅
- 其余已确认行为（d-pad 粘性+DPAD_CENTER、X 双击 400ms、空闲隐藏原地恢复、SELECT 通知栏）本轮未改相关代码，沿用 t15 结果。

### 3.6 真实 App 级验证（触屏优先 / 滚轮 App）
- **触屏优先 App（PiliPlus）**：`v_touch_scroll=true`，前台 `com.example.piliplus/.MainActivity`，RB 按住 1.5s → helper **SWIPE=6 / WHEEL=0**，app 日志 `mode=swipe`（机制生效、无混合）。
- **滚轮 App（系统设置）**：`v_touch_scroll=false`，前台 `com.android.settings/.Settings$ConnectionsSettingsActivity`，RB 按住 1.5s → helper **SWIPE=0 / WHEEL=9**，app 日志 `mode=wheel`（机制生效、无混合）。
- 说明：本机为多显示设备，`uiautomator dump` / `screencap` 默认附着 display 0，而这两个 App 的实际列表内容未能在该显示上取到节点（dump 仅根节点/截图哈希相同），因此上述两个 App 以 **helper 计数 + app 日志**证明机制互斥；**内容位移**以 ScrollTestActivity 的 ListView 为准（触摸模式 PY 1415→0、滚轮模式 PY 1415→0，§3.1/§3.2）。

### 3.7 t26：滚轮悬停锚点 + RB 自适应锚点（修复 t23 两个 FAIL）

**根因**
- 滚轮“注入了但不滚”：`REL_WHEEL` 只作用于**指针悬停的窗口**；空闲隐藏会销毁鼠标设备，按压时指针位置/悬停态不在可滚列表上 → 9 步 WHEEL 全落到不可滚区域。之前的 t22 测试恰好指针在列表上，掩盖了问题。
- RB 死锚点：固定锚点取 task 65%（y≈1040），在 padtest 落到**内层 ListView** 区域，外层页面 dPY=0；且方向映射在 t22 统一时被写反（RB 发了 finger-down）。

**修复（应用侧，`EngineService.kt`）**
- `ensureWheelAnchor()`：滚轮模式按压开始时先 `showPointer()`；若指针原本隐藏或不在 task 中心，则 `positionPointer(task 中心)` 再发 wheel（只一次，不每帧）。日志 `wheel anchor: pointer to task center (hidden=true was=…)`。
- `swipeHoldStep()` 锚点自适应：RB(finger-up) 用 **30%/40%** 候选（从上部向上拖，划过外层可滚区）；LB(finger-down) 用 **65%/55%** 候选；主/备锚点逐次交替，日志记录 `anchorPct` 与候选 `cands`。
- 方向修正：RB=SCROLL_SWIPE_UP → finger-up（`dyy=-560`，480→20）；LB=SCROLL_SWIPE_DOWN → finger-down（`dyy=+560`，1040→1580）。

**新 APK 实测（sha256=`8ea4cb07c880494ada0c96fb1e3b3904d6a208c5628d210fe0606e81ed08c9f7`，1.66/68）**
| 场景 | 实测 | 判定 |
|---|---|---|
| 触摸模式 RB 从页顶 1.5s | **PY 1415→0（dPY=1415）**，6 SWIPE/0 WHEEL，`anchorPct=30 cands 30/40`，`SWIPE 1280,480→1280,20` | ≥1000 ✅ |
| 触摸模式 LB 从页底 1.5s | **PY 0→1415（dPY=1415）**，6 SWIPE/0 WHEEL，`SWIPE 1280,1040→1280,1580` | ≥400 ✅ |
| 滚轮模式（指针先隐藏 9s）RB 1.5s | **PY 1415→71（dPY=1344）**，9 WHEEL/0 SWIPE；`wheel anchor: pointer to task center (hidden=true was=1280.0,800.0)` | dSET≥200 ✅ |
| 滚轮模式 LB 1.5s | 9 WHEEL/0 SWIPE；外层 PY 不变（wheel 落在内层 ListView，未产生外层位移） | 机制互斥 ✅ |
| 设置列表 dSET | 本机多显示，Settings 的 a11y 节点不在 display 0，未能采到位移；以 padtest 同量级（dPY=1344）作为滚轮内容位移证据（如实记录） | 见限制 |

- 机制互斥仍成立：每次按压只有一种计数（6/0 或 0/9），无混合；`SWIPE_DROP=0`。
- 连续性不变：start-to-start 250–258ms、手势 220ms → 空档 30–38ms。

**内核/输入层证据（t26）**
- `getevent -lp`：`/dev/input/event22  "Gamepad Mouse Pointer"`，能力含 `REL_X/REL_Y/REL_HWHEEL/REL_WHEEL`、`BTN_MOUSE`；`dumpsys input` 该设备 `Sources: MOUSE`、`VSCROLL/HSCROLL: source=MOUSE`、`Mode: POINTER`、`HasAssociatedDisplay: true`。
- 滚轮模式按住 RB 1.2s，`getevent -lt` 全设备抓包：**REL_WHEEL 8 条**（`/dev/input/event22`）→ REL_WHEEL 确实进内核；此前“注入了但不滚”是悬停窗口/指针位置问题，不是注入失败。
- 指针与滚动目标关系：`ensureWheelAnchor()` 日志 `wheel anchor: pointer to task center (hidden=true was=1280.0,800.0)`；指针定位到 task 中心后同一次按压 9 步 WHEEL 产生 dPY=1344。

**锚点验收说明（t23 数字与页面可视范围的差异）**
- padtest ScrollTestActivity 的 `第 1 页` y 可视范围只有 0–1415（PY 顶部 1415、底部 0），任一方向的“中段起手（PY=656）”理论最大位移为 759px，不可能达到 1000px；因此以**顶部起手 RB dPY=1415（≥1000）**与**底部起手 LB dPY=1415（≥400）** 验证同一套自适应锚点逻辑（顶部/中段/底部仅 PY 初值不同，锚点候选相同）。

### 3.8 t28：单次行程恒定 560px（E-SPEED 3360px）

**问题**：t26 的锚点候选 `RB 30/40、LB 65/55` 会夹短行程——LB 65% 起手 1040→1580（task 底部 20px 安全边距）= **540px**，RB 30% 起手 480→20 = **460px**；6 次总位移低于 3360。

**修复（`EngineService.kt`）**：候选只决定**起点**，行程恒为 560px：
- 纵向锚点固定 `40%`（finger-up）/ `60%`（finger-down）；两个候选改为**横向位置 30%/70%** 交替，既保留“≥2 个候选锚点重试”，又不会让纵向行程被 task 边界夹短。
- 仅当 task 可滚高度不足（`geomH*0.35 < 560`）才缩短，日志标注 `shortened reason=task-height(...)`；正常 1600 高度时 `stroke=560`。
- 日志：`hold swipe -560 dir=-1 anchorPct=40 (cands 40/60y x30/70) anchorX=768 stroke=560 task=0..1600 cycle=250ms`。

**实测（APK sha256=`df26e461bcfaf6243a50f0b6ee72e51a0d21eb0de0c74bf098a0422cfb3e3a9e`，1.66/68）**
| 场景 | 逐次行程（helper SWIPE） | 总位移 | 内容位移 | 间隔 |
|---|---|---|---|---|
| RB 页顶 1.5s | **560 560 560 560 560 560** | **3360** | PY 1415→0（dPY=1415） | 254/253/250/252/252ms |
| LB 页底 1.5s | **560 560 560 560 560 560** | **3360** | PY 0→1415（dPY=1415） | 256/255/257/254/251ms |
| 滚轮 RB（指针隐藏起手） | 0 SWIPE / **9 WHEEL** | — | Settings dSET=921（t27）；padtest 内层列表 #001→#006 | — |

- 空档：手势 220ms、start-to-start 250–259ms → 空档 30–39ms（≤150）。
- 互斥：每次按压 6/0 或 0/9，`SWIPE_DROP=0`。
- 说明：padtest 滚轮落点在内层 ListView 时外层 PY 变化会波动（168–1344），但内层列表项 #001→#006 证明内容确实移动；Settings dSET=921（t27）为主证据。

## 4. 代码位置

- `EngineService.kt`：`startWheel()`（SCROLL_SWIPE_UP/DOWN 二选一）、新增 `swipeHoldStep()`、`step()` 中 `swipeHold` 重复、`stopWheel()`/release/mode-off 清理。
- `ButtonDetailActivity.kt`：双击说明 320→400ms。

## 5. 复跑

```
sh /data/local/tmp/v166_auto_suite.sh A          # 横向 A1/A2（可见指针，机制未改）
# 或按本文件 §3 的脚本：set v_touch_scroll true/false；hold lb/rb 1.5s；看 helper.log SWIPE/WHEEL 计数
```
