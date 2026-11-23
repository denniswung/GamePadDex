# VERIFY-v166 · GamePadDex v1.66 真机全量验证（可证伪阈值 / PASS-FAIL 表）

> **历史记录（t15 之后）**：本文件的 64 项跑在助手 `4f261754…` / APK `e8a91185…` 上，已被
> **`work/docs/VERIFY-v166-final.md`** 取代（绑定最终 APK `b7fa2662…` + 助手 `1bf7306f…`，
> 收紧 D≤8px / E≤8px / I5≤10px、H2 max<5000µs，并新增 A5 空闲隐藏后首次推杆用例）。
> 本文件仅作历史证据保留，不再作为验收依据。

> 任务：t4（真机全量验证）· 设备：SM-F9360（adb `192.168.10.36:6666`，横屏 2560×1600）
> 一键脚本：`work/scripts/v166_auto_suite.sh`（设备端 `sh`，root；单节/全量均可跑）
> 本次权威运行：**run1** `mode=all start=Tue Nov 24 01:33:31 CST 2026` → **PASS=64 FAIL=0**
> 复跑（同一命令）：`work/docs/evidence-v166-verify/auto_suite_run2.txt`（见 §17）
> 原始证据：`work/docs/evidence-v166-verify/`（`auto_suite_console.txt` 全量控制台、`auto_suite.result.txt` 逐条判定、`auto_suite.log` 阶段日志、`shots/` 截图、`shotdiff.txt` 像素级差异）

判定纪律：每个用例都必须有**坐标/计数/位移/前台组件/截图/时间戳**这类客观真机证据；「日志里有这行」不单独作为通过依据（日志只作为注入/仲裁过程的辅助证据）。

> **哈希更新（t12）**：本文件 64 项跑在助手 `4f261754…` 上；之后 t10/t11 只改 `?` 自检上报（CAP 语义 + INFO 行），
> 最终 / 发布哈希为 **`6076b63b806eb26985d9f0d26d2aa4e546e2b68daf6de5c737c4f6fb815233b0`**。
> 最终哈希上的 `?` 自检两态、K 组复跑、控制面抽检，以及「其余 58 项为何仍有效」的论证见
> **`work/docs/VERIFY-v166-hash.md`**（含打包注意事项：module.prop 仍写 v1.65、两个本地旧助手副本需替换）。

## 0 基线校验（不一致立即 FAIL 并停止）

| 项 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| 应用版本 | versionName=1.66 且 versionCode=68 | `versionName=1.66 versionCode=68` | PASS |
| 设备 base.apk sha256 | == 本机构建产物 `app-debug.apk` | `e8a9118592d07b4be10116f12ae93cccb864799da116425e1948ebd9fcf7b031`（= `project/lsp-dexpad/app/build/outputs/apk/debug/app-debug.apk`，3130719 B，DEBUGGABLE） | PASS |
| 助手 gpminput sha256 | == `4f261754…d059a5` 且 `/data/adb/gpm` 与模块目录一致 | `/data/adb/gpm/gpminput` = `/data/adb/modules/gpm_dex/gpminput` = `4f261754d80bea69dfc6d8af46608800195c05bc4bd68bca0e220e5d37d059a5` | PASS |
| padtest 前台/焦点 | `mCurrentFocus` 含 padtest | `Window{… com.dennis.padtest/com.dennis.padtest.ui.CursorTestActivity}` | PASS |
| 显示（信息项，不计入 PASS 计数） | 横屏 2560×1600、`user_rotation=1`、`accelerometer_rotation=0`、`pointer_speed=-1` | `dumpsys window displays: cur=2560x1600 app=2560x1600`、`cmd window user-rotation → lock 1` | 记录 |

**关于任务书里的 `C6AC4B6D…`**：那是 t8（横屏大屏适配）重建**之前**的装机值。t8 完成后本机 debug 构建产物与设备 `base.apk` 都是 `e8a91185…fcf7b031`（versionCode 68），本次按「设备 hash == 本机构建产物」判定通过，并在报告首部如实记录该变化；助手 hash 与任务书一致。

测量前标准动作（脚本 `baseline()` 内固定执行）：`cmd statusbar collapse` → 断言 padtest 有焦点 → `settings put system accelerometer_rotation 0`；空闲 8s 指针自动隐藏的行为在各用例中单独考虑（E7/I5 就是测它）。

## 1 结果汇总

| 组 | 内容 | 条数 | PASS | FAIL |
|---|---|---|---|---|
| 0 | 基线（apk/版本/助手/焦点） | 4 | 4 | 0 |
| A | 修复1 滑动串扰（两独立滚动区 + 串行手势） | 6 | 6 | 0 |
| B | 修复2 光标 dpi（满推/半推/0.24/边缘减速/参数） | 5 | 5 | 0 |
| C | 修复3 滑动速度（竖/横/比值/数值） | 4 | 4 | 0 |
| D | 修复4 L3 居中（新装机自标定 + 3 档 pointer_speed ×3 + A 点击） | 7 | 7 | 0 |
| E | 修复5 边界卡死（四方向 + 贴边 + d-pad 后 + 空闲隐藏后） | 7 | 7 | 0 |
| F | 功能6 摇杆唤醒（正例 + 3 个负例） | 4 | 4 | 0 |
| G | 功能7/8 Y+上/Y+下 打开应用（+不覆盖自定义） | 3 | 3 | 0 |
| H | 提速与资源（时延/prep/60s CPU/c 查询） | 4 | 4 | 0 |
| I | 回归 6 项（d-pad、双击、X+LB/RB、空闲恢复、通知栏） | 7 | 7 | 0 |
| J | 横屏大屏（默认/守护/居中/分栏/竖屏回落） | 7 | 7 | 0 |
| K | 助手新命令（u/g→O/c/P/10 条耗时） | 6 | 6 | 0 |
| **合计** | | **64** | **64** | **0** |

复跑输出最后一行：`PASS=64 FAIL=0`（脚本 exit 0）。

## 2 A 修复1：滑动串扰 —— 单次推杆只作用一个区域

**「两个独立滚动区域」怎么量**（`com.dennis.padtest/.ui.ScrollTestActivity`，uiautomator 读实时渲染状态，不依赖日志）：

- **纵向区 PY**：页面纵向滚动量 = 横向分页区「第 N 页」节点的 top y（初始 1415；页面往上滚则变小）。滚动内容在页面里，PY 变化即「纵向这一块动了」。
- **横向区 HS**：横向分页 `HorizontalScrollView` 的 `scrollX`（每页宽 600px，由首屏可见页的可见宽度反推：`scrollX = 600·(n−1) + (600−可见宽)`；初始 0，一次横滑 = 512）。
- 判别力自检 A0：**绕过 App** 直接顺序注入「竖 + 横」两条真实触摸手势 → PY 与 HS 必须都变化，证明本用例**能**同时看到两个区域动（不是「永远只报一个区」）。
- 之后 A1/A2/A3 要求：**只有一个指标变化**（另一个 ≤20px）**且 helper 只出现一个轴**。

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| A0 判别力自检（直接注入竖+横，绕过 App） | PY 变化>20 且 HS 变化>20 | PY 1415→366（d=1049）、HS 0→512 | PASS |
| A1 单次竖向推杆（RY=+0.73，450ms） | 只纵向区动：PY d>20、HS d≤20；helper 仅 Z | PY d=1337、HS d=0、helper Z=2 / V=0 | PASS |
| A2 单次横向推杆（RX=+0.73，450ms） | 只横向区动：HS d>20、PY d≤20；helper 仅 V | PY d=0、HS d=512、helper V=1 / Z=0 | PASS |
| A3 双轴同时超阈（RY=0.73 已在，RX 由 0.24 抬到 **0.36 > scroll_deadzone 0.35**，常驻手柄 `sendevent` 同批事件） | 只一区动：PY d>20、HS d≤20；helper 仅 Z | PY d=1415、HS d=0、helper Z=5 / V=0；`gesture axis arbitration: RY=0.7324 RX=0.36 -> vertical` | PASS |
| A4 双向连续 3 次（竖/横交替共 6 次推杆） | helper.log 无两条并存 SWIPE：overlaps=0 且 starts==dones≥6 | `starts=18 dones=18 overlaps=0 orphan=0 drops=0 queued=6 inflight=0` | PASS |
| A5 不靠「丢弃」掩盖 | `SWIPE_DROP` 计数 = 0（应用侧已先仲裁） | drops=0 | PASS |

原始注入证据（`helper.log`，真实 `input swipe`；axis=Z 竖向 / axis=V 横向）：

```
A1: SWIPE 0 1282,1040 -> 1282,560 (task 0..2560 / 0..1600) axis=Z n=1 pid=5416 queued=0 async prep=380us
A2: SWIPE 0 1282,803 -> 130,803  (task 0..2560 / 0..1600) axis=V n=3 pid=5859 queued=0 async prep=376us
A4: starts=18 dones=18 overlaps=0 orphan=0 drops=0 queued=6 inflight=0
```

截图差异（PC 像素级，见 §11）：A2 横滑 **99.4% 的变化像素集中在最下方一条横带**（分页条，y≈1400–1600），A1/A3 竖向滚动则是整页变化 —— 与「单次手势只作用一个滚动区」一致；A2 另有 0.2% 像素在状态卡片（`scrollX` 读数刷新）。

> 结论：一次推杆只产生一个轴的一条/一组串行手势；双轴同时超阈时主导轴胜出（RY=0.73 > RX=0.36），另一轴**不产生**第二条触摸流。旧版（v1.65）在 RX≥0.36 时是 Z+V 两条并发（DIAG-v166 §2）。

## 3 B 修复2：光标 dpi（左摇杆定长推 300ms）

方法：L3 → 满推左 550ms 撞左边缘 → 再向右推 300ms，用 PadProbe 的 `MOUSE/hover` 轨迹首末差（30+ 个采样点）算位移。

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| B1 满推 300ms | 位移 ∈ [0.9,1.2]×屏宽 = [2304,3072]px | **2485px**（`from=74,803 to=2559,803 dt=283ms`） | PASS |
| B2 半推（X=0.49）300ms | 位移 > 0 | **498px** | PASS |
| B3 0.24 杆位 300ms | 位移 > 0（旧版 γ=2.5 时=0） | **39px** | PASS |
| B4 边缘减速 | 屏幕中心同推 > 左边缘同推 | center **612px** vs edge **498px**（-18.6%） | PASS |
| B5 调整后参数 | 源码默认值生效（prefs 未覆盖） | `speed_phone=48`（EngineService.kt:193）、曲线 γ=**1.6**（`Math.pow(n,1.6)`，:2384）、亚像素阈值 **0.2px**（:2137）、边缘 `scale=0.6`（:2128） | PASS |

## 4 C 修复3：滑动速度（按住右摇杆 1.5s）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| C1 竖向 1.5s（RY=-24000） | 注入手势数 ≥5（scroll_speed=4 → 250ms/次） | **n=6，总行程 3360px**（6×560） | PASS |
| C2 横向 1.5s（RX=+24000） | 注入手势数 ≥2（hswipe_speed=3 → 500ms/次） | **n=3，总行程 3456px**（3×1152） | PASS |
| C3 横/竖总位移比 | ∈ [0.8,1.25] | **1.029**（3456/3360）（旧 3072/3360=0.914） | PASS |
| C4 调整后数值 | 竖 560px/250ms、横 1152px/500ms | 实测 3360px/1.5s 与 3456px/1.5s；prefs `hswipe_speed=3`、`scroll_speed=4`；横滑 `w×0.45`、节奏 `560−20×hswipe_speed` | PASS |

## 5 D 修复4：L3 居中（≤80px）+ 新装机自标定 + A 恢复鼠标点击

方法：`c` 读真实光标 → 反推 REL→px 增益 → `g/P` 闭环；真值 = PadProbe `MOUSE/click-down` 落点（横屏中心 1280,800）。

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| D0 新装机自标定（删掉持久化 `move_gain` 后重启引擎，模拟新装） | 居中误差 ≤80px | click=**1278,800**，CENTER_OK err=**-2,0**；`moveGain calibrated 0.0 -> 3.2465813 (src=l3-initial center_gain=2.16)` | PASS |
| D0B 标定结果落盘 | 日志有 `moveGain calibrated` 且 prefs 重新写入 | prefs `move_gain=3.2465813` | PASS |
| D-PS0 `pointer_speed=0` ×3 | 每次误差 ≤80px | 3/3：`1283,802|3`、`1279,798|1`、`1283,798|3` | PASS |
| D-PS3 `pointer_speed=3` ×3 | 每次误差 ≤80px | 3/3：`1278,798|2`、`1278,798|2`、`1278,798|2` | PASS |
| D-PS7 `pointer_speed=7` ×3 | 每次误差 ≤80px | 3/3：`1279,802|2`、`1279,794|5`、`1279,794|5` | PASS |
| D4 总体 | 9/9 且 ≤80px（实际 ≤5px） | **9/9**，最大 5px | PASS |
| D5 居中后按 A | 必须是鼠标点击：mouse_click≥1 且 key_enter=0 | `mouse_click=1 key_enter=0`（L3 主动清 d-pad 原生导航） | PASS |

> 「不得依赖单机遗留 prefs」：D0 是**删掉 `move_gain` 后冷启动引擎**测的，引擎从 `center_gain=2.16` 初始猜测出发，第一次 L3 自行标定到 3.2466 并落盘，落点 1278,800。三档 `pointer_speed` 下都靠运行时闭环收敛（不是固定 325/2.16）。

## 6 E 修复5：边界卡死（四方向 + 贴边 + d-pad 后 + 空闲隐藏后）

真值 = `helper.log` 的 `CURSOR <lx> <ly>`（助手回包的应用逻辑坐标）；估算 = 引擎 `ptr synced to real … (est was …)` / `at app edge … logical=…`。

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| E1 左推 1400ms | 真实到 x≈0，估算-真实 ≤40px | real=**0,803**，est=0,803（d=0,0），click=0,803 | PASS |
| E2 右推 1400ms | 真实到 x≈2559，≤40px | real=**2559,803**，est=2560,803（d=1,0），click=2559,803 | PASS |
| E3 上推 1400ms | 真实到 y≈0，≤40px | real=**1285,0**，est=1285,0（d=0,0） | PASS |
| E4 下推 1400ms | 真实到 y≈1599，≤40px | real=**1285,1599**，est=1285,1600（d=0,1），click=1284,1599 | PASS |
| E5 贴左边缘 5×200ms + 反向 250ms | 5 次零位移且反向一步到对边 | P1=0,800 → P2=**0,800**（零位移）→ P3=**2559,800** | PASS |
| E6 d-pad 导航后再摇杆 | 仍可达左边缘 x=0 | real_x=**0**，click=0,800；`native navigation OFF (stick moved)` | PASS |
| E7 空闲隐藏（9s）后再摇杆 | 仍可达右边缘 x=2559 | real_x=**2559**，`ptr synced to real 2559,800 (est was 2560,800)` | PASS |

原始证据节选：`ptr synced to real 0,803 (est was 0,803) gain=3.2377949`、`ptr synced to real 2559,803 (est was 2560,803)`、`ptr synced to real 1285,1599 (est was 1285,1600)`。

## 7 F 功能6：摇杆唤醒（正例 0.92 / 负例 0.37、0.73、慢爬 2.1s）

方法：**一个常驻虚拟手柄**（先接入，屏幕亮时接入不触发助手的「接入点亮」），之后用 `sendevent` 改轴模拟「手柄一直连着、人推摇杆」；`u` 命令与 `WAKE` 日志由助手侧记录。

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| F1 负例 0.37 持续 1.4s | 保持 Dozing 且无唤醒注入（done=0） | wf=**Dozing**，WAKE 行=无 | PASS |
| F2 负例 0.73 持续 1.4s | 保持 Dozing 且无唤醒注入 | wf=**Dozing**，WAKE 行=无 | PASS |
| F3 正例 0.92 快速推（≥0.80 且保持 ≥200ms） | Dozing→Awake 且 helper `WAKE … done=1` | before=Dozing，+250ms=**Awake**，after=Awake；`wake sent: helper u (m=0.9156 rise=206ms hold=206ms thr=0.8)`；`WAKE was=Dozing now=Awake uinput=1 done=1 src=uinput took=456ms` | PASS |
| F4 负例 慢爬 2.1s（0.24→0.92，rise>120ms） | 保持 Dozing 且无唤醒注入 | before=Dozing，after=**Dozing**，无 `wake sent` | PASS |

## 8 G 功能7/8：Y+上 → PiliPlus、Y+下 → 抖音

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| G1 Y+上 | 前台 = com.example.piliplus 且 helper 走**组件解析**启动（fallback=0、monkey=0） | `top=com.example.piliplus/.MainActivity`；`OPEN_APP com.example.piliplus via com.example.piliplus/.MainActivity rc=0 out=Starting: Intent { flg=0x10000000 cmp=com.example.piliplus/.MainActivity }`；fallback=0 monkey=0 | PASS |
| G2 Y+下 | 前台 = 抖音包 且组件解析启动 | `top=com.ss.android.ugc.aweme/.account.business.login.DYLoginActivity`（启动目标 `.splash.SplashActivity`，随后进入登录页，同包）；`OPEN_APP com.ss.android.ugc.aweme via com.ss.android.ugc.aweme/.splash.SplashActivity rc=0`；fallback=0 monkey=0 | PASS |
| G3 不覆盖用户自定义 | 预置 `mix_10` 后 Y+上 不再打开 PiliPlus（OPEN_APP=0） | 预置 `mix_10_keys=x+rb / action=wheel_left` 后：`top=me.efesser.flauncher/.MainActivity`，`OPEN_APP=0`（Y 单击 Home 生效） | PASS |

> 「非 `am start -p`」证据：helper 日志是 `via <pkg>/<Activity>` + `cmp=<pkg>/<Activity>`，`fallback=pkg` 计数 0、`monkey` 计数 0。

## 9 H 提速与资源

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| H1 事件→动作时延（12 次 A 单击，同一 logcat 时钟：`button a down`→`MOUSE/click-down`） | 中位 ≤7ms 且最大 ≤15ms | 样本 **10 10 7 6 7 11 7 6 5 8 13 12** ms → 中位 **7**、最大 **13** | PASS |
| H2 `cmd_swipe` prep | 中位 <1500us | 采样 `[217 0 279 0 269 0 315 0 364 0 661 0]` us → 中位 **108us**、最大 **661us**（n=12） | PASS |
| H3 engine 静置 60s CPU | ≤4%（基线 2.93%，允许 +1%） | **3.53%**（线程级求和；`dexpad-engine=2.57%`、`dexpad-silent-a=0.82%`、`dexpad-link=0.05%`、`Profile Saver=0.08%`） | PASS |
| H4 60s 空闲 `c` 查询 | ≤15 次（按需/限频） | **CURSORQ=0 / CURSOR=0** | PASS |

**H3 口径说明（如实披露）**：本机 `/proc/<pid>/stat` 的 utime+stime 与「进程内各线程 utime+stime 之和」在该应用上不一致（同一 60s 窗口：线程级求和 3.53%，`/proc/<pid>/stat` 口径 6.03%；本机 `top -p <pid>` 也随采样窗在 3.5–6% 间跳）。基线（v1.65 2.93%、t8 同法 3.70–3.80%）用的是**线程级实测**，故 H3 以线程级求和判定：`engine` 线程 2.57% 与 t8 的 2.73–2.77% 同量级、且低于基线 2.93%；两口径都记录在案，差异原因未定位（不作为通过依据）。空闲期间 `c` 查询 0 次、帧耗时由引擎自报（`perf tick … avg≈150–200us`）。

## 10 I 回归 6 项（不得回退）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| I1 d-pad 粘性导航 + A 注入 DPAD_CENTER | `mouse_click=0` 且 `key_enter≥1` | `mouse_click=0 key_enter=1`（PadProbe 收到 `KEY/key-down KEYCODE_ENTER`） | PASS |
| I1B 摇杆移动后退回鼠标模式 | `mouse_click≥1` 且 `key_enter=0` | `mouse_click=1 key_enter=0` | PASS |
| I2 X 双击（400ms 窗口）→ 多任务 | 前台 = RecentsActivity | `top=com.sec.android.app.launcher/com.android.quickstep.RecentsActivity`；引擎 `double x -> recents` | PASS |
| I3 X+LB 上一页 | 真实横向手势、方向不回退（向右） | `SWIPE 0 2181,803 -> 2540,803 axis=V` → dx=**+359**；`mix 4 x+lb -> wheel_right (direct)` | PASS |
| I4 X+RB 下一页 | 真实横向手势、方向不回退（向左） | `SWIPE 0 2181,803 -> 645,803 axis=V` → dx=**−1536**；`mix 5 x+rb -> wheel_left (direct)` | PASS |
| I5 空闲隐藏原地隐形恢复 | 同点误差 ≤60px 且无修正移动日志 | P1=**2559,803** → 隐藏（`pointer hidden` 计数 +1）→ P2=**2559,803**，d=**0px**；`pointer shown at last position (no correction move)` | PASS |
| I6 SELECT 真实下滑手势通知栏 | 前台 NotificationShade + `NOTIF swipe rc=0` + 截图变化 >500KB | shade=**1**；`NOTIF swipe async … / NOTIF swipe rc=0 dur=415ms`；PNG 132109B→4256400B，**delta=4,124,291B**；PC 像素差异 **4,095,995 px = 16000KB** | PASS |

## 11 J 横屏大屏（t8）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| J1 默认配置即横屏 | `user_rotation=1`、`accel=0`、app 宽>高 | `user_rotation=1 accel=0`、`dumpsys window displays cur=2560x1600 app=2560x1600`、`cmd window user-rotation → lock 1` | PASS |
| J2 旋转守护 | 外部改竖屏后 ≤5s 回横屏 | 改 `user_rotation=0 + accelerometer_rotation=1` 后 **≈3250ms（13×250ms 轮询）** → settings 回 1/0、app 回 2560×1600；`landscape guardian: rotation 3 -> 1 (force_landscape=true)` | PASS |
| J3 居中目标 = 横屏中心 | 误差 ≤80px | click=**1281,803**，err=**2,3**（目标 1280,800） | PASS |
| （引用）四方向可达真实边缘（同一次横屏会话，见 §6 E1–E4；不单独计数） | x≈0 / x≈2559 / y≈0 / y≈1599 且估算-真实 ≤40px | 0,803 / 2559,803 / 1285,0 / 1285,1599；dEst=(0,0)(1,0)(0,0)(0,1) | PASS |
| J4 ConfigActivity 横屏分栏 | ≥2 个半屏宽 ScrollView 并排 | **count=2**；截图 `shots/J_config_land.png`（235324B） | PASS |
| J5 ButtonDetail 横屏分栏 | ≥2 个半屏宽 ScrollView 并排 | **count=2**；截图 `shots/J_button_land.png`（155259B） | PASS |
| J6 竖屏回落（负例） | `force_landscape=false + rotation 0` → 引擎 geometry 高>宽、单列、无崩溃 | 引擎 `geometry changed -> 1600x2560 rot=0 display=0`（`geometry app=1600x2560`）、pid 存活、half_scrollviews=**0**、截图 `shots/J_config_portrait.png` | PASS |
| J7 恢复默认横屏 | 引擎 geometry 与 dumpsys 都宽>高 | `engine=2560x1600`、`dumpsys=2560x1600`、prefs `force_landscape=true` | PASS |

> 说明：本机折叠屏 `dumpsys window` 的 DisplayRotation 常量横屏=ROTATION_0（t8 已记录），所以「横屏」以 `dumpsys window displays 的 app 宽>高` + `cmd window user-rotation=lock 1` + 引擎 `geometry app=WxH` 三重证据判定（J1 判定用前两项；run1 的 J1 时点 logcat 已被前序用例清空，引擎 geometry 在 J2/J6/J7 有实测）；竖屏回落时 `dumpsys window displays` 仍报 2560×1600（那是别的 display 的 app 尺寸），故 J6 用**引擎 geometry / 应用 getSize 空间**作权威。

## 12 K 助手新命令（t2）

K 段按 t2 的方式**停掉正式助手/引擎**，用 FIFO 起一个独立助手实例做命令级测试，结束后 `start_all` 恢复（模块 `service.sh` 监督进程 + 引擎前台服务）。

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| K1 `u` 负例（屏幕已亮） | 空操作：`skip=1` 且无 uinput 注入 | `WAKE was=Awake now=Awake uinput=0 skip=1 probe=1`；wf 保持 Awake | PASS |
| K2 `u` 正例（`p` 灭屏 → Dozing） | → Awake 且 `done=1 src=uinput|input224|power` | `WAKE was=Toggling now=Awake uinput=1 done=1 src=uinput took=414ms`；wf Dozing→**Awake** | PASS |
| K3 `g` 设置 → `O` 使用新增益 | `O` 日志显示 4.68 | `GAIN center=0.000 ptr=4.680 effective=4.680`；`CENTER(steps+gain 4.68) rot=1 -> 1280,800`；随后恢复 `g 3.25 3.25` | PASS |
| K4 `c` 回包格式与真值 | `CURSOR <lx> <ly> display=0 space=logical …` 且与 `P` 放置误差 ≤5px（display 1/44 同时存在） | 3/3，max **3px**：`CURSOR 1278 797 display=0 space=logical frame=435,1446 raw=453.8,1157.1`；`CURSOR 237 397 display=0 …`；`CURSOR 2401 1398 display=0 …`；`dumpsys display` 同时有 displayId 0/1/44，仍取 display 0 | PASS |
| K5 `P` 绝对定位后点击落点 | 误差 ≤40px | 3/3，max **4px**（1278,796 / 237,396 / 2400,1398 vs 目标 1280,800 / 240,400 / 2400,1400） | PASS |
| K6 连续 10 条命令总耗时 | <100ms | **61ms**（10×`g`，从写入到 10 条 `GAIN` 回包全部出现） | PASS |

## 13 截图差异区域定位（PC 像素级，补充证据）

脚本：`work/scripts/v166_shotdiff.ps1`（`powershell -NoProfile -ExecutionPolicy Bypass -File …`，直接解 PNG 到 BGRA 内存逐像素比较，无第三方库）。
原始：`work/docs/evidence-v166-verify/shotdiff.txt`；截图：`work/docs/evidence-v166-verify/shots/`。

| 用例 | 尺寸 | 变化像素 | 变化面积 | bbox | 上/下半变化像素 | 左/右半变化像素 | 8 条横带占比% |
|---|---|---|---|---|---|---|---|
| A1 竖向推杆 | 2560×1600 | 3017968 | 11788.9KB | [36,26][2559,1599] | 1803827 / 1214141 | 1512604 / 1505364 | 10.2/16.5/16.5/16.5/16.6/7.8/0.7/15.3 |
| A2 横向推杆 | 2560×1600 | 380821 | 1487.6KB | [124,26][2461,1599] | 2145 / 378676 | 190803 / 190018 | **0.2/0.3/0.1/0/0/0/0/99.4** |
| A3 双轴同时超阈 | 2560×1600 | 2336393 | 9126.5KB | [36,0][2559,1599] | 1520430 / 815963 | 1179787 / 1156606 | 14.9/21.3/21.3/7.6/0.9/1.2/11.4/21.4 |
| I6 SELECT 通知栏 | 2560×1600 | 4095995 | 16000KB | [0,0][2559,1599] | 2047998 / 2047997 | 2047995 / 2048000 | 12.5×8（整屏） |

解读：
- **A2 99.4% 的变化像素落在最下一条横带**（横向分页条 y≈1400–1600），其余 0.6% 是状态卡片里的 `scrollX` 读数（band1–3）—— 「单次横滑只作用横向区」在像素级也成立。
- A1/A3 是整页纵向位移（页面滚动），但两个区域计数（§2）显示 HS 没动 → 只作用纵向区。
- I6 整屏 4,095,995 像素变化（16000KB ≫ 500KB 阈值），配合 `mCurrentFocus=NotificationShade` 证明是真实下滑展开通知栏，不是滚轮/点击。

## 14 复跑方式与单节定位

```sh
# 全量（合约里的验证命令）
adb -s 192.168.10.36:6666 push work/scripts/v166_auto_suite.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/v166_auto_suite.sh"        # 输出末尾 PASS=xx FAIL=yy

# 只跑某一节（仍会先做基线校验，便于失败定位）
adb shell "sh /data/local/tmp/v166_auto_suite.sh A"     # B C D E F G H I J K 同理
```

- 脚本要求 root（`id -u`=0），且运行前不能有残留 `vgpad`（脚本会 `BUSY` 退出，避免与别人抢设备）。
- 每个用例失败时，控制台/结果文件里会打印 `REPRO: <复现命令>`；`[id] FAIL | 阈值 … | 实测 …` 行给出当时的数字。
- 脚本末尾 `restore_state` 无条件恢复正式安装状态：`pointer_speed=-1`、`user_rotation=1`、`accelerometer_rotation=0`、`force_landscape=true`、引擎/助手在跑、padtest 前台、屏幕点亮。
- 设备端输出：`/data/local/tmp/v166_auto_suite.log`（阶段日志）、`/data/local/tmp/v166_auto_suite.result`（逐条判定）、`/data/local/tmp/v166shots/`（截图）。

## 15 设备恢复状态（run2 结束 = 本次交付时状态）

| 项 | 实测 |
|---|---|
| 应用 | `versionName=1.66 / versionCode=68`，base.apk sha256 `e8a91185…fcf7b031`（未改动） |
| 助手 | `gpminput` sha256 `4f261754…d059a5`；进程在跑（pid 15454），socket 已建 |
| 引擎 | `pidof com.dennis.dexpad`=15462，前台服务在跑 |
| 显示 | 横屏 2560×1600、`cmd window user-rotation=lock 1`、`user_rotation=1`、`accelerometer_rotation=0` |
| 指针 | `pointer_speed=-1`，L3 可居中，A 为鼠标点击 |
| 前台/屏幕 | padtest CursorTestActivity 前台（`mCurrentFocus=Window{… padtest/…CursorTestActivity}`），`mWakefulness=Awake` |
| prefs | `hswipe_speed=3`、`scroll_speed=4`、`force_landscape=true`、`move_gain=3.2377949`、`mode_on=true`、`idle_hide_sec=8`、`enabled=true`（测试期间的临时改动逐项恢复） |

## 16 证据文件清单（`work/docs/evidence-v166-verify/`）

| 文件 | 内容 |
|---|---|
| `auto_suite.result.txt` | run1：64 条用例的「阈值/实测/判定」原始行 + 分节标题 + `PASS=64 FAIL=0` |
| `auto_suite_console.txt` | run1 全量控制台（含每节的原始 helper.log/logcat/uiautomator 摘录、repro 提示） |
| `auto_suite.log` | run1 脚本阶段日志（baseline/prefs/geometry/恢复） |
| `auto_suite_run2.txt` | run2：验证命令原样复跑的完整输出（含 `PASS=64 FAIL=0`、exit code 0） |
| `auto_suite.result.run2.txt` | run2 逐条判定原始行 |
| `shotdiff.txt` | PC 像素级差异（本文件 §13 的数据源） |
| `shots/A1_before.png` `A1_after.png` | 竖向推杆前后 |
| `shots/A2_before.png` `A2_after.png` | 横向推杆前后 |
| `shots/A3_before.png` `A3_after.png` | 双轴同时超阈前后 |
| `shots/I6_before.png` `I6_after.png` | SELECT 通知栏前后（4.25MB 展开后截图） |
| `shots/J_config_land.png` `J_button_land.png` `J_config_portrait.png` | 横屏分栏 ×2、竖屏回落单列 |

## 17 复跑一致性

- run1（`mode=all`，01:33:31 起）：**PASS=64 FAIL=0**，控制台 `auto_suite_console.txt`、逐条 `auto_suite.result.txt`。
- run2（验证命令原样 `adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/v166_auto_suite.sh"`，01:48 起）：**PASS=64 FAIL=0，exit code 0**，完整输出 `auto_suite_run2.txt`、逐条 `auto_suite.result.run2.txt`。
- 两次的关键数字一致（只有采样小数波动）：

| 用例 | run1 | run2 |
|---|---|---|
| A1 纵向区 / 横向区 | PY d=1337，HS d=0，Z=2 V=0 | PY d=1331，HS d=0，Z=2 V=0 |
| A3 双轴超阈 | PY d=1415，HS d=0，Z=5 V=0 | PY d=1415，HS d=0，Z=5 V=0 |
| B1 满推 300ms | 2485px | 2481px |
| C3 横/竖比 | 1.029 | 1.029 |
| D4 L3 居中 | 9/9（最大 5px） | 9/9 |
| H1 时延（中位/最大） | 7 / 13 ms | 6 / 13 ms |
| H2 prep 中位 | 108us | 226us |
| H3 线程级 CPU（60s） | 3.53% | 3.47% |
| H4 空闲 c 查询 | 0 | 0 |
| I6 通知栏截图 delta | 4,124,291B | 4,124,697B |
| J2 旋转守护 | ≈3250ms | ≈3500ms |
| K6 10 条命令 | 61ms | 62ms |

## 18 已知边界与未覆盖

- A 段的「纵向区」用的是页面纵向滚动量（PY）而不是 ListView 的 firstVisiblePosition：实测 helper 注入的 `input swipe` 在 padtest 上是 **MOUSE 源**，拖拽会滚页面而不是内层 ListView（日志 `MOUSE/drag` + `TOUCH/swipe`），所以用页面滚动 + 横向分页 scrollX 这一对互相独立的区域做计数；两者都由 uiautomator 读实时渲染状态。
- K 段会短暂停掉正式助手/引擎（命令级测试需要独占 uinput 与日志），结束后立即恢复；若中途被打断，重跑一次脚本即可（`start_all` 在脚本末尾）。
- H3 的 `/proc/<pid>/stat` 与线程级求和差异已披露，未定位到根因；判定沿用基线同一口径（线程级）。
