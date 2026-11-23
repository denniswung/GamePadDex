# APP-v166 · 应用侧（Kotlin）真机验收证据摘要

> **哈希注记（t7 集成）**：本文件头部与正文的数字是 t16/t20 时期在 **debug 字节**上测的（`b7fa2662` → `d2194406`）。
> v1.66 的**发布字节**是 `assembleRelease` 的 `73477ecaef948aa4b4a9ffdc5f51e8026200a66228cebd635b8aba8c79aa8bf5`（2677039 B），
> 发布助手是 `1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf`（851928 B）。
> 两者 Kotlin 源码相同，差异只有构建变体标志与 `assets/gpminput`；发布字节上的行为由
> `work/docs/evidence-v166-install/release_smoke.result.txt`（23/23 PASS）复核，完整对照见 `work/docs/RELEASE-v166.md`。

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

### 9.1 dpi 不撞边（直接测量 + 两种代理）
- **直接测量（t18，48 速）**：L3 后先左推到 x≈0，再 300ms 满推右；三次可见位移 **2462 / 2485 / 2481px = 96.2 / 97.1 / 96.9% 屏宽**，终点 2559（最后 <100px 撞右边缘；`at app edge` 日志 500ms 节流，窗口内 grep=0）。按 0.9–1.2 判据 **PASS**（可见位移 ≥0.96）。
- 说明：2560 屏宽下 48 速的 300ms 真实行程 >1 屏，无法完全不撞边；cap 后仍可见 2462–2485px。250ms×6/5 折算也撞边（2485→2982，不可用），故采用 300ms 直接可见位移。
- **代理 A（中心 150ms×2，标注“代理”）**：1141–1150px ×2 = 2282–2302px = 89.1–89.9%（含起步加速，低估）。
- **代理 B（speed_phone=16×300ms×3，标注“代理”）**：777/794/779px ×3 = 2331/2382/2337px = 91.1/93.0/91.3%（假设满杆 γ=1、px/帧 ∝ speed_phone）。
- 结论：direct 48/300ms = 96.2/97.1/96.9%（在 0.9–1.2）；proxy B（speed_phone=16 线性外推）= 91.1–93.0%；proxy A（中心 150ms×2）= 89.1–89.9% 属**低估**，仅作参考。

### 9.2 滑动速度两种口径（同一份 t16 数据）
- 手势注入：竖 **6 次 × 560px = 3360px / 1.5s**；横 **3 次 × 1152px = 3456px / 1.5s**（`grep -a '^SWIPE '`，排除 `SWIPE_DONE/DROP/QUEUED`；helper Z=6 V=3）。
- **验收口径（captain/t7 已定）**：以**同一时间（1.5s）总位移比**为准，3456 / 3360 = **1.029** ∈ [0.8,1.25] PASS。
- 同一手势单次 1152/560 = **2.057**，属**设计取舍**（横向单次步长更大），不作为判据，不再与“同一时间总位移”口径混用。
- 依据参数：`speed_phone=48`、`γ=1.6`、亚像素阈值 `0.2px`、横 `dist=w*0.45`、`hSwipeRepeatMs=560-20*hswipe_speed`（用户 hswipe_speed=3 → 500ms）、竖 `dist=h*0.35`、`ms=220`、`cycle=max(ms+20, 410-40*scroll_speed)`（scroll_speed=4 → 250ms）。

### 9.3 实际滚动测量（uiautomator，数据订正）
- **竖向（t4 套件 A1，b7fa2662）**：`PY 1415→63（d=1352），HS 0→0`，helper `SWIPE 0 1282,1040→1282,560 axis=Z n=2`，**PASS**。手动复现（starts → L3 → 右摇杆上推 1.5s）：`PY 1415→0（d=1415）`，helper 3 条 Z swipe，`SWIPE_DROP=0`。
- **横向（A2）**：`HS 0→512（d=512），PY 0`，helper `SWIPE 0 1282,803→130,803 axis=V n=1`，**PASS**。
- **t16 的 dPY=0 与 t18 的 dPY=0 是两类不同假象（详见 §10）**：
  - t16 探针：脚本未先 L3 且测试前指针已空闲隐藏 8s+（helper 仍发 SWIPE，锚点/可见性条件不满足）→ dPY=0；先 L3 后同流程 dPY=1415。
  - t18 idle-10s 对照：页面已被 A1 滚到顶 PY=0，再上推没有可滚空间 → dPY=0（起手位置选取不当）。
  - **不是 t16 的 L3/POSPTR/EngineService 改动导致**：POSPTR 只驱动居中校验，不修改 ptrX/ptrY/pointerPos 的滑动锚点或竖向 swipe 起手；源码核对 + 直接复测均确认。
- 助手计数：竖 Z=2（套件）/ Z=3（手动），横 V=1；`SWIPE_DROP=0`，未见误计。

## 10. t20：指针空闲隐藏后首次滑动（锚点）加固

- **预期行为（R5）**：指针空闲隐藏后，**首次滑动会先恢复指针（原地出现、零修正移动）**；恢复后指针保持可见，继续空闲 8s 后再次销毁。这是 v1.66 的预期行为，不是缺陷。
- **两类 dPY=0 必须分开（R3）**：
  - (a) **t16 探针那次**：`PY=1415` 起手，但指针已空闲隐藏且脚本**未先 L3** → `dPY=0`（helper 仍发出 SWIPE；锚点/可见性条件不满足）。根因是探针缺少“先 L3 让指针可见”的步骤。
  - (b) **t18 的 idle-10s 对照**：页面已被 A1 滚到顶 `PY=0`，再上推没有可滚空间 → `dPY=0`。根因是对照实验的起手位置选取不当。
  - 两类假象成因不同，**不能混写**。
- **根因与加固（R7）**：摇杆路径原本即可恢复（`stickActive` 时 `showPointer()`，早于 `doSwipe`），锚点从未失效；v1.66 **额外加固的是“按钮触发 `doSwipe` 的隐藏分支”**——发 `V/Z` 前若 `pointerHidden` 则 `showPointer()` 一次（只发 `j`，不做修正移动，不每帧发）。不能表述为“隐藏首滑失效已被修复（所有路径）”。
- **实测（新 APK d2194406…）**：隐藏后首推竖 **dPY=1415**（PY 1415→0）、横 **dHS=512**（HS 0→512）；可见指针竖推 dPY=1415（页面到顶）；helper `SWIPE 0 1282,1040→1282,560 axis=Z`、`SWIPE 0 1282,803→130,803 axis=V`，`SWIPE_DROP=0`。
- **延迟（R4）**：**57ms 是摇杆路径**（`stickActive` 既有恢复，无额外 `j`）；**按钮触发 `doSwipe` 的隐藏分支会多一次 `j`（约 120ms 设备重建）**。发布说明不得把 57ms 泛化到所有滑动路径。
- **I5 不回退**：隐藏后 A 点击 **1281,803**，日志 `pointer shown at last position (no correction move)`，0px 修正。
