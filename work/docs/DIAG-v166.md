# DIAG-v166 · 真机诊断与现状量化（根因报告）

- 版本基线：**v1.65**（`versionName=1.65`、`versionCode=67`，装机 APK sha256 见 §10）
- 设备：**SM-F9360 / RFCT817KWEH**，Android 16（sdk 36），KernelSU（`su -c` 可用）
  - 物理折起外屏 904×2316（当前 ON），内屏 1812×2176（OFF），HDMI 外接 2560×1600（display 25，ON）
- 诊断时间：2026-11-23 21:30–22:20（+08:00），设备单台串行
- 性质：**只读诊断**，不改源码；仅在可逆范围内改设备设置（`user_rotation`、`pointer_speed`、`center_gain`、`taskbounds.txt` 投毒），每项都已恢复（§10）
- 证据：`work/docs/evidence-v166/`（原始 dumpsys / logcat / 截图）+ 脚本 `work/scripts/probe_v166_*.sh`
- 真值来源：`com.dennis.padtest`（1.1）在 `CursorTestActivity` 里打印的 `PadProbe:` 行
  - `MOUSE/hover x=.. y=..`：真实光标轨迹（含时间戳，用于算位移/速度）
  - `MOUSE/click-down x=.. y=.. btn=..`：A 键点击时系统真实落点（本报告所有"真实落点"）
  - `TOUCH/swipe dx=/dy=`：应用真正收到的触摸拖拽
  - 输入注入：`/data/local/tmp/vgpad`（虚拟手柄，轴 0=LX 1=LY 3=RX 4=RY 9=GAS(LT)，键 304=A 317=L3 311=RB）

---

## 0. 结论摘要（TL;DR）

| # | 用户症状 | 复现 | 根因（可证伪） | 量化 |
|---|---|---|---|---|
| 1 | 一次滑动手势串扰到两个区域 | **6/6 稳定**（C/E/H 两轮） | 右摇杆 X 与 Y **各自独立**判定（同一 8ms tick），`RX ≥ scroll_deadzone(0.35)` 时竖向 `Z` 与横向 `V` 两条注入并发；`input swipe` 每条起一个独立注入流，且起手区域不同（`Z` 起手 y=30%/65%，`V` 起手 y=光标） | RX=0.40+RY=0.73 → 1.5s 内 **Z 5 次 + V 3 次**（两区域 y=480 与 y=800）；RX=0.31 → Z 5 次 + V **0**；RX=0.36 → 两者都触发 |
| 2 | L3 居中偶发失败 | **7/7 稳定，非偶发** | App 用 `center_gain=2.16`，真机实际 `REL→px` 增益 **G=3.24–3.25**（1.503×）→ helper `pointer_goto` 落点 = 中心×1.503 | 2560×1600：目标 1280,800，实测 **1925,1200**（误差 **+645,+400**）；`center_gain=325` 时实测 **1278,796**（误差 −2,−4） | 
| 2b | （"偶发"的错觉来源） | 1/1 | d-pad 粘性导航中 A 注入 `DPAD_CENTER/KEY_ENTER`（不得回退的特性），**根本不点鼠标**；L3 不清除 `nativeNav` | 实测 `mouse_click=none, key_enter=1`；推一下摇杆后同一 L3 落点仍是 1925,1200 |
| 3 | 光标在某些区域被夹住 | **稳定** | 每帧夹取用 `ptrX/ptrY`（引擎估算）与同一个 2.16 增益；真实增益更大 → 估算永远落后真实 33%×位移，真实贴边后引擎仍认为有空间，于是"推杆无效段" | 左边界：真实 x=0 时估算仍 1785（还有 1785px 余量）→ 再推 **5×200ms 真实零位移**；右边界：真实 2559 时估算 2227（还有 333px） |
| 4 | 光标 dpi / 滑动速度 | 量化 | 指针曲线 γ=2.5 + 速度 30px/16ms + 真实增益 3.25：满推 300ms 实测 **1559px**（≈ 62% 屏宽），半推（0.49）仅 **169px**，0.24 推杆 **完全不动**；右摇杆 1.5s = 竖向 6 次手势×560px=3360px / 横向 3 次×1024px；滑动 prep **398–2410µs**（中位 ~1035µs，n=20） | 见 §5 |
| 5 | "当前好像被改成竖屏了" | **稳定** | 诊断开始时 `display_size_forced=1600,2560` + `user_rotation=0` → display0 = **1600×2560 竖屏**（宽<高）；`force_landscape=true` 只在 **helper ready 时** 调一次 `setRotation(1)`，之后不再复验；实测重启引擎可从 0→1（2560×1600） | 竖屏：mBounds `Rect(0,0-1600,2560)`、mRotation 0；横屏：`Rect(0,0-2560,1600)`、mRotation 1；`wm size reset`/`display_size_forced=null` **无法去掉** 该 override（三星侧保留） |

> 关键常量事实：helper 里 `g_pointer_gain = 3.25`（gpminput.c:1067）**从未被使用**；App 每次用 `center_gain`（默认 216，Prefs.kt:303-306）覆盖 helper 的 `g_center_gain`（gpminput.c:81/1790）。App 侧 `RAW_TO_PX = 2.16f`（EngineService.kt:248）是**死常量**（无引用）。即"真值早就在代码里，只是两条路径各用各的"。

---

## 1. 环境与方法

### 1.1 实测几何（诊断窗口内）

| 项 | 取值 |
|---|---|
| `wm size` | Physical `904x2316` / Override `1600x2560` |
| `settings global display_size_forced` | `1600,2560`（**常驻，见 §6**） |
| display 0（外屏，ON） | 竖屏 `1600x2560` rot 0 ←→ 横屏 `2560x1600` rot 1（两种都实测过） |
| display 1（内屏，OFF） | override `1600x2560`，rot 3 |
| display 25（HDMI） | `2560x1600` rot 0（不参与映射：`DisplayState` 只选内置屏，DisplayState.kt:17-35） |
| `system pointer_speed` | `-1`（三星默认） |
| `enhance_pointer_precision` | 1 |
| 应用空间（App 眼里） | 横屏 2560×1600 / 竖屏 1600×2560（`getSize()`，DisplayState.kt:42-58） |

### 1.2 真实落点测量法（可复核）

1. `vgpad key 317 100 800` → L3（`center_cursor`）
2. `vgpad key 304 80 0` → A（鼠标左键，`left_touch=false` 默认，走真实光标位置）
3. `logcat -d -s PadProbe | grep 'MOUSE/click-down' | tail -1` → 系统真实落点
4. 与引擎日志 `DexPad: cursor centered on WxH (display 0, rot R, gain G)`、helper 日志 `CENTER(steps+gain X)` 对照

> 编辑：`MOUSE/hover` 是真实光标轨迹，可算 300ms 位移；`engine ptr move ... at X,Y` 是**引擎估算**，两者对比即"估算 vs 真实"。

### 1.3 前置条件（踩过的坑，后续复现必看）

- 屏幕会 **8s 空闲自动隐藏指针**（`idle_hide_sec=8`）→ 长时间测试前先唤醒并随时确认 `pointer shown`。
- 通知栏被拉下时 `mCurrentFocus=Window{...NotificationShade}`，鼠标 hover/点击**全部不落进 padtest**，看起来"全挂"。脚本里先 `cmd statusbar collapse` 并断言 `mCurrentFocus=Window{...padtest}`。
- 三星会把 `accelerometer_rotation` 重新打开（诊断中出现过 0→1），随后 `user_rotation` 被写成 0/3 → **每个测量批次前固定 `accelerometer_rotation=0` + `user_rotation=1` 并记录实际值**。
- `vgpad` 每次调用都要重建一个虚拟手柄（~900ms 建机 + `pre` 延时）；两个 `vgpad` 并发 = 引擎侧 `axes[]` 合并，等价于"一个手柄同时推两个轴"。

---

## 2. item1：一次滑动手势串扰到两个区域

### 2.1 触发场景（全部真机，1.5s 窗口，`scroll_deadzone=0.35`）

| 场景 | 注入 | 竖向手势 Z | 横向手势 V | 起手区域 | 判定 |
|---|---|---|---|---|---|
| A 纯纵向 | RY=0.73 | 5 | 0 | Z@y=480（=30%×1600） | 正常 |
| B 纯横向 | RX=0.73 | 0 | 3 | V@y=800（光标 y） | 正常 |
| **C 斜推泄漏** | **RX=0.40 + RY=0.73** | **5** | **3** | **Z@480 与 V@800 并存** | **串扰** |
| D 低于死区 | RX=0.31 + RY=0.73 | 5 | 0 | Z@480 | 安全 |
| **E 略高于死区** | **RX=0.36 + RY=0.73** | **5** | **3** | Z@480 + V@800 | **串扰** |
| F RB 按住 | RB 1.5s | 1（Z@800） | 0 | Z@800 | 滑动+滚轮双通道：**+8 次 WHEEL** |
| **G RB + 右摇杆** | RB + RY=0.73 | RB 2 次@800 + 摇杆 5 次@480 | 0 | **两个不同 y 区域** | **串扰（两条独立竖向流）** |
| **H X+RB + 右摇杆** | X+RB（混搭=WHEEL_LEFT） + RY | 5 | 3 | Z@480 + V@800 | **串扰** |

- **阈值（可证伪）**：`RX < 0.35` → 无横向手势（0.31 实测 0 次）；`RX ≥ 0.36` → 出现横向手势（0.36 实测 3 次）。边界就是 `scroll_deadzone=350‰`（Prefs.kt:198-200）。
- **"两个区域"的坐标证据**（helper 日志原文）：
  ```
  SWIPE 0 1280,480 -> 1280,1040 (task 0..2560 / 0..1600)   # 摇杆 Y：从 30% 起手
  SWIPE 0 1280,800 -> 20,800   (task 0..2560 / 0..1600)   # 摇杆 X：从光标 y 起手，向上一页
  ```
  同一 1.5s 内交替出现 → 应用同时收到"滚动"和"翻页"两条触摸流。

### 2.2 根因判定（三选一，逐条给证据）

**① task 边界缓存跨任务污染 —— 机制成立，但不是本次串扰的主因**

- 机制：`cmd_swipe` 只用缓存文件 `/data/adb/gpm/taskbounds.txt`（gpminput.c:1264/1337-1342），刷新子进程 **2s 节流**（gpminput.c:1280-1282），刷新失败时兜底写 `0 0 maxX maxY`（gpminput.c:1317-1321）。
- 真机投毒实验（把缓存写成 `0 0 1200 800` 后立刻纵向滑）：
  ```
  污染后立刻: SWIPE 0 600,240 -> 600,780 (task 0..1200 / 0..800)      # 起手 y=240（30%×800）
  刷新后:     SWIPE 0 1280,480 -> 1280,1040 (task 0..2560 / 0..1600)  # 恢复
  ```
  → **缓存一错，整条触摸流就落到另一个区域**。在"单窗口全屏"时任务边界恒为全屏，所以本机当前场景**看不到**跨任务串扰；一旦分屏/自由窗口/快速切应用（<2s），这条路径必然把滑动丢进旧区域。
- 结论：**是隐患、需要修（缓存应带 display+taskId+分辨率校验，且热路径不能靠 2s 节流），但不是本次"一次手势撞两个区域"的直接原因**。

**② MT slot 残留 —— 排除（对滑动这条路径不成立）**

- 滑动根本不走 helper 的虚拟触摸屏：`V`/`Z` 命令是 `fork()` + `system("input -d N swipe ...")`（gpminput.c:1388-1404）；MT slot（`g_touch_slot0/1`、slots 11/12）只用于单击 `k` 与双指 `l`（gpminput.c:264-338）。
- 真机反证：滚动飞行中按 A，点击照常落地（`click-down=6`，`PadProbe TOUCH/swipe=4`）；双指缩放与单击交替也无丢点（`PINCH start/stop` + `click-down=2`）。
- 结论：**不是 MT slot 残留**。

**③ swipe 与 wheel 同帧并发 —— 部分成立，是"双通道"而非主因**

- 实测 F：RB 按住一次 = 1 条 `SWIPE` + 8 次 `WHEEL`（`wheelIntervalMs()`=240−3×18=186ms，EngineService.kt:787）；即同一按键在"滑动起手 + 滚轮续滚"两条通道上并行输出。
- `X+RB`（WHEEL_LEFT）还会额外起一条横向 `V`（`startWheel`→`doSwipe(false,...)`，EngineService.kt:844-853）。
- 结论：**在"按键+摇杆"组合下会叠加成 3 条流**（滑动+滚轮+摇杆），但它不是"单次摇杆手势串两个区域"的原因。

**④ 主因（结论）**：`step()` 里右摇杆 Y（竖向，EngineService.kt:1565-1600）与 X（横向，EngineService.kt:1618-1649）**各自独立判定、各自冷却、同一 tick 同时触发**，没有"本帧只允许一种手势"的仲裁；而 `vSwipeArmed`/`hSwipeArmed`（EngineService.kt:153/157）**只写不读（死变量）**，注释里"摇杆回中才能再次触发"的保护并不存在（每 250/560ms 重复正好证明它没生效）。两条 `input swipe` 并发注入本身又会互相破坏：单独实验（不经过 App，直接并发两条 `input -d 0 swipe`）→ 应用只收到 **1 个 click（300,800）**、**0 条 TOUCH/swipe**，其中一条被吞掉/降级成点击。

> 修复方向（留给实现成员）：同一 tick 做 **轴向仲裁**（|RY| 与 |RX| 比较，或竖向优先 + 横向需连续 2 帧 |RX|>dead），并恢复"一次推杆只发一次"的 armed 语义；`input swipe` 改常驻注入器（一个固化的虚拟触摸屏）以避免并发流互相取消。

---

## 3. item2：L3 居中偶发失败

### 3.1 真机数据（2560×1600 横屏，`center_gain=216`）

| 试验 | 起点/模式 | 引擎日志 | helper 日志 | 真实落点 | 误差 | 反推真实增益 G |
|---|---|---|---|---|---|---|
| T1 | 上一点 | `centered on 2560x1600 (display 0, rot 1, gain 2.16)` | `CENTER(steps+gain 2.16) rot=1 -> 1280,800` | 1922,1203 | +642,+403 | 3.24 |
| T2 | 左推 500ms 后 | 同上 | 同上 | 1925,1200 | +645,+400 | 3.25 |
| T3 | 右下推后 | 同上 | 同上 | 1925,1200 | +645,+400 | 3.25 |
| T4 | **空闲隐藏 10s 后** | 同上（`pointer shown at last position`） | 同上 | 1922,1200 | +642,+400 | 3.24 |
| T5 | **d-pad 导航后** | 同上 | 同上 | **无鼠标点击**（A→`DPAD_CENTER`，`KEYCODE_ENTER`） | — | — |
| T5b | d-pad 后 + 右摇杆退出导航 | 同上 | 同上 | 1925,1200 | +645,+400 | 3.25 |
| T6a/T6b | 空闲隐藏后再 L3 ×2 | 同上 | 同上 | 1925,1200 / 1922,1200 | +645,+400 / +642,+400 | 3.25 / 3.24 |

- **落点完全确定**（7 次全部 1922–1925 / 1200–1203），不是"偶发"。
- 隐藏/恢复（`pointer shown at last position (no correction move)`）后 L3 依然只偏 1.5×，**与空闲隐藏/重建无关**。
- 竖屏几何（1600×2560, rot 0）同样：目标 800,1280 → 实测 **1200,1925**（误差 +400,+645，G=3.24）。**增益与几何无关，是纯倍率错误**。

### 3.2 根因：`center_gain` 与实际 `REL→px` 增益不符（1.503×）

helper 的绝对定位算法（gpminput.c:1086-1126）：

```
pointer_goto(tx,ty): 40 步有界推到 (0,0)（必撞左上角，与起点无关）
                     + 一步 (tx/gain, ty/gain)
=> actual = (tx/gain) × G      （G = 系统真实 REL→px 增益）
=> G = actual_x × gain / (w/2)
```

真机增益扫描（每次都先停引擎改 prefs 再重启，回到默认后恢复原 prefs）：

| `center_gain` | 期望中心 | 实测落点 | 误差 | 反推 G |
|---|---|---|---|---|
| 4.00 | 1280,800 | 1037,650 | −243,−150 | **3.241** |
| **3.25** | 1280,800 | **1278,796** | **−2,−4** | 3.245 |
| 2.16（默认） | 1280,800 | 1925,1200 | +645,+400 | 3.248 |

- **验收阈值可证伪**：`|actual − center| ≤ 8px`（1 个光标的整数舍入）→ `center_gain=325` 实测 **4px** 达标；默认 216 是 **645/400px**（80 倍阈值）。
- **增益随系统 `pointer_speed` 变**（同一个 `center_gain=4.00`）：

| `pointer_speed` | 实测落点 | 反推 G |
|---|---|---|
| −1（三星默认） | 1037,650 | **3.24** |
| 0 | 1153,722 | 3.60 |
| 3 | 1498,939 | 4.68 |
| 7 | 2306,1445 | 7.21 |

→ 硬编码/一次性标定的 `center_gain` 会随 `pointer_speed`（或其它指针加速开关）再次失效。**修复必须"运行时测一次 G"或"每次 L3 用二分/闭环校正"，不能只把 216 改成 325。**

### 3.3 "偶发"的两个错觉来源（必须一起修）

1. **d-pad 粘性导航中 A 不点鼠标**（实测 `mouse_click=none`、`key_enter=1`、`A -> DPAD_CENTER (native nav)`）。`nativeNav` 只由"摇杆移动"退出（EngineService.kt:1440-1449），L3 **不清除**它 → 用户"先 d-pad 选中、再 L3、再 A"时 A 变成确认键，看着就是"居中后点不到/点错"。这是**不得回退的特性**（d-pad 粘性导航 + A 注入 DPAD_CENTER），所以修复方向是 **L3/居中动作主动退出导航模式**（或 L3 后 `nativeNav=false`），不能删 DPAD_CENTER。
2. **固定 1.503× 偏移**：偏移方向与量级恒定（+645,+400），目标在屏幕中心附近时"看起来还行"，目标偏一侧时直接命中错误的控件 → 主观"有时成有时不成"。

### 3.4 其它观察（静态）

- `ActionRouter.kt:144-152`：`CENTER_CURSOR` 先 `host.onPointerNeeded()`（隐藏→重建 `j`）→ `lockCenterFor(700)`（ptrX=NaN）→ `root.centerCursor(...,gain)` → `onCentered()`（ptrX=w/2）。**估算无条件被重置为屏幕中心**，而此时真实落点是中心×1.503 → 给 §4 的夹取带埋下"估算与真实分离"的种子。
- `action "A"` 走 `DPAD_CENTER` 时不会触发 `left button down`，所以 `PadProbe` 只有 `KEY/key-down`（证据已留）。
- 另有一条"相对一次性居中"路径 `ActionHost.centerPointer()`（EngineService.kt:89-99，用 `(w/2−ptrX)/gain` 发一条相对位移）**声明并实现但无调用点**——同属死代码，容易误导后续修改。

---

## 4. item3：光标在某些区域被夹住

### 4.1 真机序列（L3 → 四方向推杆，每段 300ms 满推，另点 A 取真实值）

| 步骤 | 真实落点 | 引擎估算 `ptr move at` | 现象 |
|---|---|---|---|
| L3 基线 | 1925,1200 | 1280,800（`onCentered` 重置） | 估算比真实小 645/400 |
| 右推 R1 | **2559**,1200（贴右边） | 2227,800（仍认为有 **333px** 余量） | 真实已到边，估算没到 |
| 右推 R2–R4 | 2559,1200（**不动**） | 之后无 `ptr move` 日志（clamp=0 提前 return） | **推着不动** |
| 左推 L1 | 1271,1200（一步 1288px） | 2560,800（以为在右边） | 反向起步 1.5× 过冲 |
| 左推 L2 | **0**,1200（贴左边） | 1785,800（仍认为有 **1785px** 余量） | 真实已到边 |
| 左推 dead1..5 | **0**,1200 ×5（**零位移**） | 无新日志 | **1.0s 推杆无效段** |
| 下推 D1–D4 | 0,**1599**（贴下边） | 856,800 | 同上 |
| 上推 U1 | 0,183（一步 1416px） | 856,1600 | 反向过冲 |
| d-pad 后推杆 | 342,1203 | — | `native navigation OFF (stick moved)` ✓ |

### 4.2 根因（两段代码 + 一个错误常量）

```kotlin
// EngineService.kt:1526-1558
val (vw, vh) = displaySize(activeDisplay())
if (ptrX.isNaN()) { ptrX = vw / 2f; ptrY = vh / 2f }        // 估算位置
...
val gNow = prefs.centerGain                                   // 2.16（真实 3.25）
val rx = mx.coerceIn((0f - ptrX) / gNow, (vw - ptrX) / gNow)  // 用估算+错误增益夹取
if (Math.abs(rx) < 0.01f && Math.abs(ry) < 0.01f) return      // 两轴一起被丢
root.move(rx, ry)
ptrX = (ptrX + rx * gNow).coerceIn(0f, vw.toFloat())          // 估算按 2.16 累加
ptrY = (ptrY + ry * gNow).coerceIn(0f, vh.toFloat())
```

1. 真实每单位 REL 走 3.25px，估算只记 2.16px → **估算落后真实 = 位移 × 33.6%**（= 1 − 2.16/3.25）。
2. 真实贴边后，系统把 REL 消化掉（视觉不动），引擎却还在按估算"有空间"继续发 → **推杆无效段**；反过来（估算 > 真实）时 clamp 会给出过大的允许量 → **反向一步冲到对边**。
3. `centerGain` 的误差还让 **边缘减速**（`edgeSlow`，EngineService.kt:1529-1536，8% 边距）在错误的位置触发：按估算判断边缘，真实早已贴边。
4. L3 把估算**无条件重置为中心**（§3.4），所以"L3 → 往某方向推"最容易出现上述分离 —— 与用户"居中之后反而在边上夹住"的描述一致。

### 4.3 与"空闲隐藏/重建"和"d-pad 粘性导航"的关系

- **空闲隐藏/重建本身不造成夹住**：T7 实测 `before` 与 `after-idle-move` 位置连续（1925,1203），`pointer shown at last position (no correction move)`，无修正移动 ✓（v1.65 不得回退项保持）。
- **d-pad 粘性导航会制造"看起来夹住"**：导航中 A 不点鼠标（§3.3），且 `nativeNav` 期间没有指针移动，用户以为"光标死了"；实测推一下摇杆即 `native navigation OFF (stick moved)`，指针恢复。
- **旋转/几何变化**：竖屏 1600×2560 下同一套 clamp 仍按 2.16 工作，误差同样是 1.5×（实测 L3 → 1200,1925；右推 → 1599 贴边）。

---

## 5. item4：基线量化（可作 v1.66 提速前后对照）

### 5.1 偏好默认值（代码事实，`Prefs.kt`）

| key | 默认 | 含义 | 本机实际 prefs |
|---|---|---|---|
| `speed_phone` | 30 | 每 16ms 帧像素 | 默认（未写盘） |
| `sens_x` / `sens_y` | 100 / 100 | 摇杆灵敏度 % | 默认 |
| `deadzone` | 160‰ | 指针死区 0.16 | 默认 |
| `scroll_deadzone` | 350‰ | 滚动死区 0.35 | 默认 |
| `scroll_speed` | 4 | 滚轮速率 | 默认 |
| `hswipe_speed` | 7 | 横向翻页节奏（本机用户改成 **3**） | **3**（=560ms/次） |
| `wheel_speed` | 3 | 滚轮按钮速率 | 默认 |
| `center_gain` | 216 | 居中增益（**错，应 ~325 且随 pointer_speed 变**） | 默认 |
| `idle_hide_sec` | 8 | 空闲隐藏指针 | 默认 |
| `v_touch_scroll` | true | 竖向滚动用真实拖拽（非滚轮） | 默认 |
| `force_landscape` | true | 强制横屏 | 默认 |
| `mode_on` / `enabled` | true/true | 鼠标模式 / 总开关 | true/true |

另外：`Advanced`/UI 里的"光标 dpi"没有独立项，**指的就是 `speed_phone` × `curve()` × 系统增益 G 的乘积**（见 5.2）。

### 5.2 左摇杆定长推 300ms 的真实位移（L3 起点居中；真值 = PadProbe hover 轨迹）

| 推杆（归一化） | 实测位移 | 折算 px/300ms | 说明 |
|---|---|---|---|
| X = −30000（0.92） | −1559 / −1557 px（dt=294/291ms） | **1591**（≈62% 屏宽） | 两次重复一致 |
| X = −16000（0.49） | −169 / −163 px（dt=291/283ms） | **174** | 只有满推的 10.9% |
| X = −8000（0.24） | **0**（无 hover） | **0** | 亚像素死区，杆推了但不动 |
| Y = −30000（0.92） | −1080 px（dt=196ms，末尾已进入上边 8% 边缘减速区） | ~1650（折算） | 与 X 同量级 |

机理：`curve()` 是 γ=2.5（EngineService.kt:1746-1751），再乘 `speed_phone=30` 与真实增益 3.25：
- 满推 = 30 × 3.25 = **97.5 px/16ms ≈ 6.1 px/ms**
- 半推 = (0.49−0.16)/0.84 = 0.393^2.5 = 0.0968 → 9.4 px/16ms
- 0.24 推 = 0.1^2.5 = 0.0032 → 0.31 px/16ms → 低于 0.6px 阈值被丢弃（EngineService.kt:1542）

> 这就是"光标 dpi/速度"主观问题的根源：**同一根杆 0→100% 的可用速度跨度只有 ~10×，但 0–30% 完全无响应、50% 只有 11% 速度、100% 立刻 62% 屏宽/300ms**。另外真实增益 3.25 让"满推"比代码注释假定的 2.16 快 1.5×。

### 5.3 右摇杆按住 1.5s（`v_touch_scroll=true`，横屏 2560×1600）

| 指标 | 实测 |
|---|---|
| RY=−24000（0.73）1500ms | **竖向手势 6 次**（`DexPad vswipe=6`；helper `SWIPE` 12 行 = 6 次 × (async+rc)），单次 560px（=h×0.35），总行程 **3360px** |
| 手势节奏 | ms=220 + 冷却 30 → **250ms/次** |
| RX=+24000（0.73）1500ms | **横向手势 3 次**，单次 1024px（=w×0.40），总 **3072px**，节奏 **560ms/次**（`hswipe_speed=3`） |
| 滚轮数（vTouch 模式） | **0**（走真实拖拽，不走 `WHEEL`） |
| RB 按住 1500ms（按钮） | 1 次滑动 + **8 次 WHEEL**（186ms/次） |

### 5.4 滑动 prep 与端到端

| 指标 | 实测 |
|---|---|
| helper `prep`（命令解析→fork 成功） | **398–2410 µs**，n=20，中位 **≈1035 µs**（早期单次最高 2335µs） |
| `input swipe` 手势时长 | 配置值（竖 220/380ms、横 200ms、按钮 slow 120ms），实测应用收到 `TOUCH/swipe` 与配置一致 |
| 引擎 tick | 8ms（EngineService.kt:279），hb `silent=0–1064ms` |
| 引擎自报时延 | `lat n=2 avg=3ms max=5ms`（仅部分动作统计） |

> 结论：**prep 不是瓶颈**（≈1ms）；体感"滑动慢"主要来自手势时长 + 冷却（250/560ms）与"一次推杆重复多次"，不是注入准备时间。

---

## 6. item5：显示与方向基线（用户："当前好像被改成竖屏了"）

### 6.1 诊断开始时的真实状态（21:29，未动任何设置）

```
wm size:                     Physical size: 904x2316 / Override size: 1600x2560
display_size_forced:         1600,2560
user_rotation / accel:       0 / 0
display 0 (外屏, ON):        override real 1600 x 2560, rotation 0, mBounds Rect(0,0-1600,2560), mRotation=0
display 1 (内屏, OFF):       override real 1600 x 2560, rotation 0
display 25 (HDMI, ON):       real 2560 x 1600, rotation 0（外接屏，不参与映射）
mCurrentOrientation:         0 / 0 / 0
当前是否竖屏比例：            是（宽 1600 < 高 2560）
prefs force_landscape:       未写盘 → 默认 true
```
→ **用户看到的就是竖屏**：`display_size_forced` 以竖屏像素（1600 宽 × 2560 高）给出 override，`user_rotation=0` 时应用空间就是 1600×2560。

### 6.2 实测：forceLandscape（默认 true）+ setRotation(1) 叠加后的效果

| 实验 | 操作 | 结果 |
|---|---|---|
| B | `user_rotation=0` | display0 **1600×2560**（竖屏），`mBounds Rect(0,0-1600,2560)`，`mRotation=0` |
| C | `user_rotation=1` | display0 **2560×1600**（横屏），`mBounds Rect(0,0-2560,1600)`，`mRotation=1` ✓ |
| 3 | 横屏下灭屏/亮屏 | `user_rotation` 保持 **1**（不会被系统改回） |
| D | **`user_rotation=0` 后重启引擎** | `user_rotation` 自动变 **1**，helper 日志 `ROTATION 1` ✓ → **forceLandscape 只在 helper ready（onReady, EngineService.kt:1787）生效** |
| E | `wm size reset` | rc=0 但 **Override size 仍是 1600x2560**，`display_size_forced` 仍是 `1600,2560`（**去不掉**） |
| E2 | `settings put global display_size_forced null` | 值变 `null`，但 `wm size`/`mOverrideDisplayInfo` **仍 2560×1600**（三星侧保留 override）→ 已恢复为 `1600,2560` |

### 6.3 差距说明（现状 vs "默认应为横屏大屏"）

- **期望**：`force_landscape=true` → 应用空间 **2560×1600 横屏大屏**（宽>高），所有映射几何（中心 1280,800、竖滑起手 480/1040、横滑 1024px）都按 2560×1600 计算。
- **现状（诊断开始）**：`user_rotation=0` → **1600×2560 竖屏**，宽<高；引擎随之按 1600×2560 计算（实测竖屏 L3 目标 800,1280、推右贴边 x=1599），**与文档/默认几何全部错位**。
- **根因**：`user_rotation` 停在 0。`force_landscape` 不是"守护"，只在 helper 重连时写一次 `settings put system user_rotation 1`（RootInput.kt:274-277 → gpminput.c:1488-1501），**之后没有任何复验**；任何外部把 `user_rotation`（或 `accelerometer_rotation`）改掉的操作都会让机器停在竖屏，直到下一次 helper 重连。诊断中实测：三星把 `accelerometer_rotation` 重新置 1 后，`user_rotation` 被写成 0/3（`mRotation=3`，仍是横屏但方向反），**App 全程无感知**。
- **"大屏"还有一层物理事实**：物理外屏 904×2316（比例 0.390），override 1600×2560（0.625），横屏应用空间 2560×1600（1.600）→ 逻辑与物理比例不一致，`dumpsys display` 给出 **非等比 dpi `720dpi(445.3 × 713.1)`**（竖屏时 `712.98 × 445.37`）。即：**逻辑 1px 的横向/纵向物理距离不同**（1.6 倍），这会让"同样的推杆，横向与纵向看起来速度不一样"，也是"光标 dpi"主观问题的一部分。是否要保留 1600×2560 override 属于用户取舍（该 override 由用户工具常驻，`wm size reset` 清不掉），本次只报告事实与影响。

> 修复方向（留给实现成员）：把"横屏"做成**守护**而不是一次性写入（每次 helper ready + 周期/显示变化时校验 `Display.getRotation()`，不符就重设；或改用 `wm user-rotation lock 1`），并在 UI/日志暴露当前几何（w×h、rotation、是否宽<高），避免映射按错误几何静默运行。

---

## 7. 静态假设验证表

| 假设 | 结论 | 证据 |
|---|---|---|
| `center_gain=216` 与实际增益一致 | **否** | §3.2 扫描：G=3.24–3.25（1.503×） |
| 增益是常量、与系统设置无关 | **否** | §3.2：pointer_speed −1/0/3/7 → G 3.24/3.60/4.68/7.21 |
| helper 已知真实增益 | **是但未用** | `g_pointer_gain = 3.25`（gpminput.c:1067）无任何读取；`g_center_gain` 每次被 App 的 `O` 命令覆盖（gpminput.c:81/1790，RootInput.kt:279-282） |
| App 侧有 2.16 常量参与计算 | **否（死代码）** | `RAW_TO_PX = 2.16f`（EngineService.kt:248）仅定义；实际用 `prefs.centerGain`（EngineService.kt:1545/1557） |
| "一次推杆只发一次"的保护 | **否（死变量）** | `vSwipeArmed`/`hSwipeArmed` 只写不读（153/157/1274-1275/1456-1457/1579/1599/1643/1648）；实测按住 1.5s 重复 6/3 次 |
| 横/竖摇杆之间有权重仲裁 | **否** | EngineService.kt:1565-1600（Y）与 1618-1649（X）顺序独立，各自 cooldown |
| 滑动走虚拟触摸屏（可能 slot 残留） | **否** | `fork()+input swipe`（gpminput.c:1388-1404）；slot 只用于 `k`/`l`（264-338） |
| task 边界缓存会滞后并用旧区域 | **是** | 2s 节流（1280-1282）+ 缓存文件（1264/1337-1342）；投毒实测起手点 1280,480 → 600,240 |
| d-pad 导航会清 A 的点击语义 | **是（特性）** | `A -> DPAD_CENTER (native nav)`；`nativeNav` 仅由摇杆移动退出（1440-1449） |
| L3 会重置估算为中心 | **是** | `onCentered()`（103-108，EngineService.kt）与 `lockCenterFor` 先置 NaN（115-122） |
| 空闲隐藏恢复会做修正移动 | **否** | `pointer shown at last position (no correction move)`（353-358）；实测位置连续 |
| `force_landscape` 会持续守护横屏 | **否** | 只在 `onReady` 写一次（1787）；实测外部改 `user_rotation`/`accelerometer_rotation` 后不再纠正 |
| "相对一次性居中"路径被 L3 使用 | **否（死代码）** | `centerPointer()` 仅声明/实现（ActionRouter.kt:50、EngineService.kt:89-99），无调用点 |
| `wm size reset` 能清掉 1600×2560 | **否** | §6.2 E/E2（三星保留 override） |

---

## 8. v1.66 验收阈值建议（可证伪，供各实现任务引用）

| 项 | 阈值（必须真机可测） |
|---|---|
| L3 居中 | 2560×1600 与 1600×2560 两种几何、各 5 次（含空闲隐藏后、d-pad 导航后）：`|actual−center| ≤ 8px`；且 d-pad 导航后 L3 再 A 必须**落鼠标点击**（`mouse_click` 有值），不允许只有 `KEYCODE_ENTER` |
| center_gain 自适应 | 在 `pointer_speed` = −1/0/3 三档下各测 3 次，误差都 ≤ 8px（即增益必须运行时求得，不能只改默认值） |
| 串扰 | 1.5s 窗口内：`RX=0.31 + RY=0.73` → 横向手势 **0**；`RX=0.40 + RY=0.73` → 同一次手势只允许 **一种** 手势类型（Z xor V），且同一 tick 不得出现两条 `SWIPE` |
| 并发注入 | 任意 1.5s 内不得有两条 `input swipe` 同时在飞（`SWIPE async` 与 `rc=0` 行必须配对、串行） |
| 边界夹住 | L3 后向任一边满推：真实贴边后继续推 5×200ms，**估算与真实偏差 ≤ 8px**；反向第一步位移不得 > 400px |
| 指针速度 | 300ms 满推位移当前 1591px（≈62% 宽）；目标值由产品定，但同一灵敏度下两次重复偏差 ≤ 5%（当前 1591/1605 ✓） |
| 死区 | 推杆 0.24 允许 0 位移（现状），修复后若希望"微推也动"，需给出新的可测阈值（例：0.30 → ≥40px/300ms） |
| 滑动 prep | ≤ 2500µs（当前最大 2410µs，中位 1035µs），**不得回退超过 10%** |
| 右摇杆 1.5s | 竖 6 次±1（3360px±560）、横 3 次±1（3072px±1024）作为回归基线 |
| 显示 | `force_landscape=true` 时 `dumpsys display` display0 恒为 `real 2560x1600`、`mRotation=1`、`mBounds Rect(0,0-2560,1600)`；被外部改成 0/3 后 **10s 内自动纠回** |

---

## 9. 复现脚本与证据文件

| 脚本（`work/scripts/`） | 作用 | 设备输出 |
|---|---|---|
| `probe_v166_state.sh` | 身份/装机/进程/prefs/显示/焦点/缓存 快照 | `/data/local/tmp/v166_state.log` |
| `probe_v166_sens.sh` | 300ms 位移、1.5s 滚动次数、prep 分布 | `v166_sens.log` |
| `probe_v166_crosstalk.sh` | 场景 A–L：串扰阈值、并发注入、缓存投毒、MT 反证 | `v166_crosstalk.log` |
| `probe_v166_center.sh` | T1–T6：L3 落点/隐藏/导航/gain 反推 | `v166_center.log` |
| `probe_v166_gain.sh` | 增益扫描 + pointer_speed 依赖（改 prefs 后自动恢复） | `v166_gain.log` |
| `probe_v166_boundary.sh` | 四方向贴边、估算 vs 真实、隐藏/导航/竖屏 | `v166_boundary.log` |
| `probe_v166_boundary2.sh` | 左边界"无效推杆段"计数 | `v166_boundary2.log` |

运行方式（设备单台串行，需 root）：

```sh
adb -s 192.168.10.36:6666 push work/scripts/probe_v166_*.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell "su -c 'chmod 755 /data/local/tmp/probe_v166_*.sh'"
adb -s 192.168.10.36:6666 shell "su -c 'sh /data/local/tmp/probe_v166_state.sh'"
# 其余同理；每个脚本约 40s–2min，跑完检查 log 的 RESULT/DONE 行
```

原始证据（`work/docs/evidence-v166/`）：

| 文件 | 内容 |
|---|---|
| `raw_dumpsys_display.txt` / `raw_dumpsys_window_displays.txt` / `raw_dumpsys_input.txt` | 21:29 未改动状态的原始 dump（display/window/input） |
| `raw_disp_now.txt` / `raw_wd_now.txt` / `raw_power_now.txt` / `raw_w_now.txt` | 测量过程中的原始 dump（含 NotificationShade 抢焦点那一刻） |
| `raw_logcat_dexpad_restore.txt` | 恢复后的引擎日志 |
| `shot_now2.png` / `shot_restored.png` | 恢复前后截图（2560×1600 横屏、padtest 光标测试） |
| `installed.apk` | 从设备拉回的 base.apk（用于 §10 哈希比对） |

---

## 10. 收尾：设备已恢复到 v1.65 正式安装 + 鼠标模式开 + 助手运行

| 项 | 实测 |
|---|---|
| 装机 APK sha256 | `ec79e94a1e214da33a5594d1aa3179e1659923a33ce5fdde8f44ff3385ce0481` = `release/dexpad-v1.65.apk` **一致** |
| 助手二进制 sha256 | `18268d3ba4dc9506944e8c1a0a6737688b4c354789697de7a19083193444b1dd` = `release/gpminput-v1.65` **一致** |
| 进程 | `com.dennis.dexpad`（EngineService）+ `gpminput` 均在跑；helper 日志 `GRABBED ... Gamepad Mouse Virtual Dpad` |
| 鼠标模式 | prefs `mode_on=true`、`enabled=true`；引擎 `engine started` → `helper ready: pointer device recreated` |
| 偏好 | 与诊断前逐字节一致：`hswipe_speed=3 / mode_on=true / enabled=true` |
| 显示 | `display_size_forced=1600,2560`（已从被临时置 null 的状态恢复）、`accelerometer_rotation=0`、`user_rotation=1` → **横屏 2560×1600**（诊断开始时是竖屏 1600×2560，见 §6.1；横屏是 `force_landscape` 的既定默认，也是"大屏横屏"期望态） |
| 临时改动 | `pointer_speed` 已回 `-1`；`center_gain` 未写盘（回默认 216，缺陷仍在，供 v1.66 修）；`taskbounds.txt` 已被 helper 自动重写为 `0 0 2560 1600`；无残留 vgpad 进程 |

---

## 11. 原始日志摘录（真机，时间戳原样）

### 11.1 L3 居中（`work/docs/evidence-v166/raw_center_run.txt`）

```
11-23 22:19:14.770 15540 15583 I DexPad  : button l3 down mapped=center_cursor mode=true ready=true
11-23 22:19:14.776 15540 15583 I DexPad  : pointer shown at last position (no correction move)
11-23 22:19:14.778 15540 15583 I DexPad  : cursor centered on 2560x1600 (display 0, rot 1, gain 2.16)
11-23 22:19:14.928 12327 12327 I PadProbe: MOUSE/hover x=0 y=695      <- 有界推到左上角的过程
11-23 22:19:14.942 12327 12327 I PadProbe: MOUSE/hover x=0 y=249
11-23 22:19:17.168 15540 15583 I DexPad  : button a down mapped=left_click mode=true ready=true
11-23 22:19:17.253 12327 12327 I PadProbe: MOUSE/click-up x=1925 y=1200 dx=0 dy=0 dist=0   <- 真实落点
```
helper（`/data/adb/gpm/helper.log`）同一时刻：

```
KEY 1 317 1 797657261
MOUSE_REOPEN (auto)
POINTER on
CENTER(steps+gain 2.16) rot=1 -> 1280,800
```

→ 目标 1280,800、真实 1925,1200、误差 +645/+400、反推 G=3.248。

### 11.2 d-pad 导航中 A 变成 DPAD_CENTER（"居中后点不到"的证据）

```
I DexPad  : button a down mapped=left_click mode=true ready=true
I DexPad  : A pressed: nativeNav=true navActive=true leftTouch=false
I DexPad  : A -> DPAD_CENTER (native nav)
I PadProbe: KEY/key-down KEYCODE_ENTER(66) repeat=0     <- 没有 MOUSE/click-down
```

### 11.3 串扰：同一 1.5s 内两条不同起手区域的注入

```
SWIPE 0 1280,480 -> 1280,1040 (task 0..2560 / 0..1600) async prep=2310us   <- 摇杆 Y（30% 起手）
SWIPE 0 1280,800 -> 20,800   (task 0..2560 / 0..1600) async prep=1072us   <- 摇杆 X（光标 y 起手）
SWIPE 0 1280,480 -> 1280,1040 (task 0..2560 / 0..1600) rc=0
SWIPE 0 1280,800 -> 20,800   (task 0..2560 / 0..1600) rc=0
```

（对应扫描 C/E/H：`Z=5 次 + V=3 次`，两区域 y=480 与 y=800。）

### 11.4 边界夹住：真实贴边而估算仍有空间

```
L3 -> actual=1925,1200  est=1280,800
右推 300ms -> actual=2559,1200  est=2227,800     <- 真实已贴边，est 还有 333px
右推 x3    -> actual=2559,1200（零位移）
左推 300ms -> actual=1271,1200  est=2560,800
左推 300ms -> actual=0,1200     est=1785,800     <- 真实已贴边，est 还有 1785px
左推 5x200ms -> actual=0,1200（零位移，估算继续减小直到 0）
```

### 11.5 空闲隐藏后原地恢复（不得回退项，实测保持）

```
I DexPad  : pointer hidden (device destroyed)
...（摇杆小幅移动）
I DexPad  : pointer shown at last position (no correction move)
I PadProbe: MOUSE/click-down x=1925 y=1203          <- 与隐藏前同位置（无修正移动）
```
