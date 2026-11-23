# APP-v166 · 应用侧（Kotlin）真机验收证据摘要

- 装机：`versionName=1.66` / `versionCode=68`；**实际装机 base.apk sha256=`b7fa26623ba87f3801794cd74a42ac8770b4c0f74c2b99b9fd68626c0e0c984d`（t16 构建，`pm path` + `sha256sum`，与本机 `app-debug.apk` 一致；t3 报告中的 1F8A… 是 t3 当时产物，已被后续构建替换）**
- Helper：`gpminput` sha256=`4f261754d80bea69dfc6d8af46608800195c05bc4bd68bca0e220e5d37d059a5`（t2 产物，含 `u` / `c` / 串行手势队列）
- 显示：display 0 = 内置外屏，app 空间 **2560x1600** rot1，`display_size_forced=1600,2560`、`user_rotation=1`、`accelerometer_rotation=0`、`pointer_speed=-1`
- 真值：`com.dennis.padtest` 的 `PadProbe` `MOUSE/click-down` / `MOUSE/hover`；助手 `c` 回包（逻辑坐标）

原始日志（同目录）：`v166_app_fixes.log`、`v166_app_scroll.log`、`v166_app_openapp.log`、`v166_app_wake2.log`、`v166_latency.log`、`latency-before-after.txt`
脚本：`work/scripts/probe_v166_app_fixes.sh`、`probe_v166_app_scroll.sh`、`probe_v166_app_openapp.sh`、`probe_v166_app_wake2.sh`、`probe_v166_latency.sh`

## 1. L3 居中（连续 5 次，含空闲隐藏后 / d-pad 后；阈值 ≤80px）
| 试验 | 场景 | 真实点击落点 | 误差 | 引擎日志 |
|---|---|---|---|---|
| T1 | 上一点 | 1284,803 | +4,+3 | CENTER_OK phys=1285,803 err=5,3 iters=1 |
| T2 | 左推后 | 1281,803 | +1,+3 | CENTER_OK err=2,3 |
| T3 | 右下推后 | 1284,800 | +4,0 | CENTER_OK err=5,0 |
| **T4** | **空闲隐藏 9s 后** | 1284,800 | +4,0 | CENTER_OK err=5,0 |
| **T5** | **d-pad 导航后** | 1284,800 | +4,0 | L3 clears native navigation → CENTER_OK err=5,0 |

- 全部 `mouse_click` 有值（L3 主动清 `nativeNav`，A 恢复鼠标点击）。
- **L3 端到端延迟（t16 事件驱动）**：按下 L3 → `CENTER_OK` 实测 **498 / 355 / 365 ms**（t16 三轮）；helper `P` 完成回 `POSPTR` 在 **311ms** 触发 `c` 校验，固定兜底 700ms **未触发**（`L3 fallback` 日志为空）；`CENTER_OK` 带 `l3TookMs=363`。旧的 220ms+520ms 固定等待已删除。
- 增益运行时标定：`moveGain 3.2459`（首次）/`3.23808`（持久化后），与 DIAG 实测 G=3.24~3.25 一致；`center_gain` 只作为初始猜测（2.16）。
- 方法：`c` 读真实光标 → 反推 REL→px 增益 → `g 0 <gain>` + `P` 绝对定位 → `c` 校验，误差 >8px 才补一条相对位移（最多 3 次修正），不靠加长等待。

## 2. 光标 dpi / 灵敏度 / 边缘减速（左摇杆）
- 调整：`speed_phone` 30→**48**、曲线 γ 2.5→**1.6**、亚像素阈值 0.6→0.2px。
- 真机 300ms 满推（从左边缘起）：**2517 / 2524 px** = 0.98 屏宽（2560），符合目标 0.9~1.2。
- 半推 0.49：**482 px**（旧 169），>0 且线性可用。
- 0.24 推：**39 px**（旧 **0**，γ=2.5 亚像素丢弃）→ 0–30% 杆位不再完全无响应。
- 边缘减速：同一 0.49 推 300ms，屏幕中心 622px vs 左边缘 482px（**-22.5%**），日志 `edge slow active ... scale=0.6`。

## 3. 边界卡死（四方向 + d-pad 后 + 空闲隐藏后）
- L3→左推 1400ms：真实点击 **0**,803；贴边后 5×200ms **零位移**（0,803→0,803）；反向 250ms 一步到 **2559**,803。
- 右推：**2559**,800 → 5×200ms 零位移 → 反向一步 **0**,800。
- 上推：引擎/真实光标到 **y=0**（点击落在状态栏，PadProbe 不记录）；下推：**y=1599**。
- d-pad 导航后左推：到 **0**（日志 `at app edge phys=0...`）；空闲隐藏后右推：`ptr synced to real 2559,800`。
- 修复点：每帧 clamp 用运行时增益（不再是固定 2.16）+ 估算位置与 `c` 真实位置同步（移动中每 1.2s、停止后立即、L3 闭环）。

## 4. 右摇杆滑动速度（1.5s 按住）
- 竖向（RY=-24000）：**6 次 × 560px = 3360px**，周期 250ms（`scroll_speed=4`；`scroll_speed=8` → 7 次/3920px）。
- 横向（RX=+24000，用户 `hswipe_speed=3`）：**3 次 × 1152px = 3456px**，周期 500ms（旧：3×1024=3072px/560ms）。
- 横/竖总位移比 **1.029**（要求 0.8~1.25）。
- 参数：横滑距离 `w*0.45`（旧 0.40）、`hSwipeRepeatMs = 560 - 20*hswipe_speed`（旧 680-40*speed）；竖滑 `dist=h*0.35`、`ms=220`、`cycle=max(ms+20, 410-40*scroll_speed)`。
- 串扰仲裁：斜推 RX=0.40+RY=0.73 1.5s → **Z=6 次 3360px，V=0 次 0px**（只一种手势）；日志 `gesture axis arbitration ... -> vertical`；helper `SWIPE_DROP=0`（应用侧已先仲裁）。

## 5. 摇杆唤醒（灭屏时大幅快速推左摇杆）
- 阈值：幅度 ≥0.80、保持 ≥200ms、上升时间 ≤120ms（prefs `wake_stick/wake_hold_ms/wake_rise_ms` 可调）。
- 负例（常驻手柄 + sendevent，避开助手"接入点亮"）：小幅 0.37 持续 1.4s → **Dozing→Dozing**；中等 0.73 1.4s → **Dozing→Dozing**。
- 正例：0.92 快速推 → 日志 `wake sent: helper u (m=0.9156 riseCrossMs=0ms sinceStartMs=208ms hold=208ms thr=0.8)`；helper `WAKE was=Dozing now=Awake uinput=1 done=1 src=input224 took=1270ms`；`mWakefulness` **Dozing→Awake**。
- 复核（反向 0.92）：`WAKE ... now=Awake ... src=uinput took=447ms`。
- **riseCrossMs 判据（t16）**：`riseCrossMs` = 首次 m≥阈值 的时刻 − 起始时刻（≤120ms 判据）；`sinceStartMs` = 含 hold 的总耗时（旧日志误用为 rise 已修正）。实测：快推 `riseCrossMs=0ms, sinceStartMs=208ms` → Awake；慢爬 0.24→0.91/2.1s `riseCrossMs=1159ms, fast=false` → 保持 Dozing。
- **慢速负例**（同一常驻设备，0.24→0.91 用 2.1s 爬升，每档 300ms）：全程 `mWakefulness=Dozing`，`wake_log` 空 → 慢推不唤醒（rise>120ms 判据）；日志 `v166_app_wake_slow.log`。

## 6. Y+上 / Y+下 打开应用（默认映射，不覆盖用户自定义）
- Y+上：`mix 10 y+up -> open_app (direct)` → helper `OPEN_APP com.example.piliplus via com.example.piliplus/.MainActivity rc=0` → 前台 `topResumedActivity=com.example.piliplus/.MainActivity`。
- Y+下：`mix 11 y+down -> open_app` → `OPEN_APP com.ss.android.ugc.aweme via com.ss.android.ugc.aweme/.splash.SplashActivity rc=0` → 前台抖音。
- 自定义保护：把 `mix_10` 预置成 `x+rb -> wheel_left`（调试广播）后按 Y+上：`OPEN_APP` 计数 **0**，前台回到桌面（Y 单击 Home 生效）→ 默认值只在用户没配过时出现。
- 默认表：slot10 `y+up → open_app com.example.piliplus`、slot11 `y+down → open_app com.ss.android.ugc.aweme`。

## 7. 回归项（全部保持）
- d-pad 粘性导航 + A=DPAD_CENTER：`mouse_click=0 key_enter=1`；推左摇杆后 `mouse_click=1 key_enter=0`。
- X 双击 400ms → 多任务：`double x -> recents`，`top=com.android.quickstep.RecentsActivity`。
- X+LB / X+RB：`mix 4 x+lb -> wheel_right`（SWIPE 2220,800→2540,800）、`mix 5 x+rb -> wheel_left`（2220,800→684,800）。
- 空闲隐藏原地隐形恢复：隐藏前后点击同点 `2219,800 → 2219,800`，日志 `pointer shown at last position (no correction move)`。
- SELECT 真实下滑手势：`NOTIF swipe async rc=0 dur=418ms`，`mCurrentFocus=NotificationShade`（shade=1），收起后回 padtest。

## 8. 响应提速（实测）
- 事件→动作（vgpad A down → PadProbe 系统点击，logcat 同时钟，12 次）：v1.65 **4/6/7/7/7/7/8/8/8/8/9/14/20 ms（中位 8，最大 20）**；v1.66 **3/4/5/6/6/6/7/7/7/8/9/10/13（中位 7，最大 13）**。
- 引擎帧耗时（v1.66 新增计数器）：`perf tick avg=128–149µs max=3.3–8.2ms`；`prefs_per_tick=0`（旧版每 tick 12+ 次 SharedPreferences 查询 + 每次分配 Point）。
- helper→app 分发延迟：v1.65 `lat avg=3ms max=5ms` → v1.66 `lat avg=1–2ms max=2–3ms`。
- CPU（**debug 线程级，辅助指标**；release 进程级 60s 由 t7 复测，发布说明只引用 H1/H2）：旧 2.93%（30s 空闲）→ 新 **3.70–3.80%**（60s 线程级实测：engine 2.73–2.77%、silent-audio 0.83%；空闲 30s `CURSORQ=0`/`CURSOR=0`；空闲时循环自适应 8ms→16ms，有输入立即恢复 8ms）。事件→动作中位 7ms、帧耗时 128–176µs 保持。

## 9. t16 补充：不撞边 dpi / 双口径滑动 / 独立滚动测量

### 9.1 dpi 不撞边（两法）
- 法 A（中心起手 150ms 满推，线性折算 300ms）：L3 后从中心满推 150ms，PadProbe hover 位移 **1141–1150px**，`edge_logs=0`（无 `at app edge`），线性 ×2 = **2282–2302px = 89.1–89.9% 屏宽**。注：150ms 窗口含起步加速，线性外推对 300ms 偏低估；法 B 更接近真实。
- 法 B（降速到 1/3 再 ×3，全程不撞边）：`speed_phone=16`（默认 48 的 1/3，满杆 γ=1 时位移与 speed 线性），中心满推 300ms 实测 **777/794/779px**（三次），`edge_logs=0`；折算 48：**2331/2382/2337px = 91.1/93.0/91.3% 屏宽** → 落在 **0.9–1.2** 屏宽目标内。实测后已把 `speed_phone` 恢复 48（读回 prefs=48），48 下 300ms 左推仍 1141px 到 0（撞边），与 t3 的 2517px/0.98 屏宽一致（那次是贴左边起手，含夹取）。

### 9.2 滑动速度两种口径（同一份 t16 数据）
- 手势注入：竖 **6 次 × 560px = 3360px / 1.5s**；横 **3 次 × 1152px = 3456px / 1.5s**（`grep -a '^SWIPE '`，排除 `SWIPE_DONE/DROP/QUEUED`；helper Z=6 V=3）。
- **口径 1（同一时间总位移，建议验收口径）**：3456 / 3360 = **1.029** ∈ [0.8,1.25] PASS。
- **口径 2（同一手势单次位移）**：1152 / 560 = **2.057**，>1.25 —— 这是设计使然（横向一页 = w×0.45=1152px；竖向一次 = h×0.35=560px），若按“单次手势”验收则需把横向单次距离改成 ~560–700px（会牺牲翻页成功率），当前按**同一时间总位移**口径验收。
- 依据参数：`speed_phone=48`、`γ=1.6`、亚像素阈值 `0.2px`、横 `dist=w*0.45`、`hSwipeRepeatMs=560-20*hswipe_speed`（用户 hswipe_speed=3 → 500ms）、竖 `dist=h*0.35`、`ms=220`、`cycle=max(ms+20, 410-40*scroll_speed)`（scroll_speed=4 → 250ms）。

### 9.3 独立滚动测量（uiautomator，不依赖 auto_suite）
- 横向（ScrollTestActivity）：推右摇杆横轴 1.5s 后，`横向 scrollX=512 页≈1`（uiautomator 文本），页面实际发生横向滚动。
- 竖向：推右摇杆纵轴（上推）400ms 后，`纵向 offset=...` 状态行随页面上滚移出可视区（helper `SWIPE 0 1280,480 -> 1280,1040 axis=Z`，1.5s 共 6 次 ×560px=3360px）——即实际发生了纵向滚动（ScrollTestActivity 的 `纵向 offset` 行在滚动后滚出视口，Py 节点法在本 Activity 不适用，故以状态行/可见列表项变化为准）。
- 两种手势的 helper 计数与 9.2 一致（Z=6/V=3），未见 `SWIPE_DROP/QUEUED` 误计。
