# REVIEW-helper-v166 · t2 助手侧实现审查

> 任务：t5（审查 t2 助手侧：串扰、唤醒、组件启动、提速、无回归）· attempt 1
> 审查人：reviewer · 时间：2026-11-24 02:25 CST · 设备：SM-F9360（adb 192.168.10.36:6666，横屏 2560×1600）
> 结论：**NEEDS_REVISION**（t2 9 条 acceptance 中 8 条满足；**#3「投毒 ≤2s 纠正」不成立**：证据在 2.4s 取样，且源码的 2s 周期 + 2s mtime 节流最坏约 4s——见 R5。串扰/唤醒/组件启动/主循环去阻塞/无回归均通过）
> Blocking finding：**R5**；非阻塞 findings：R1–R4（其中 **R1（CPU 口径）必须在 t7 的 release 构建复测闭合后，发布说明才可宣称「提速/资源不回退」**）。

## 0. 被审修订、证据与审查方法

| 项 | 值 |
|---|---|
| t2 产物 | `project/app/src/main/assets/gpminput`，sha256 `4f261754d80bea69dfc6d8af46608800195c05bc4bd68bca0e220e5d37d059a5`，851880 B |
| t2 源码（t4 快照） | `project/app/src/main/assets/gpminput.c`，sha256 `5dad5ba9381df2af7ffca92e8d5ea874e0ebb21df25f0b45cf0611b0cc77f067`，125706 B |
| t4 装机校验 | helper=/data/adb/gpm=/data/adb/modules/gpm_dex=`4f261754…`（`VERIFY-v166.md:17`，run1/run2 一致） |
| t2 交付证据 | `work/docs/HELPER-v166.md`、`work/docs/evidence-v166/helper-v166-*.txt`、两个 helper 探针脚本 |
| t4 交付证据 | `work/docs/VERIFY-v166.md`、`work/docs/evidence-v166-verify/`、`work/scripts/v166_auto_suite.sh` |

**审查时的 tree 漂移（必须记录）**：审查开始后 t10（CAP 自检语义修复）正在改同一文件——当前源码 sha256 `829e049b…`（02:09），设备 `/data/adb/gpm/gpminput` 已是 `6076b63b…`（02:11），均不等于 t4 绑定的 `4f261754…`。本报告引用的**源码行号取自当前 tree（t10 只改 `cmd_selftest`/CAP 上报，控制路径与 t2 相同）**；t4 的 PASS 仍只对 `4f261754` 有效，t7 必须按最终哈希重跑（t7 acceptance 已要求）。这不是 t2 的缺陷。

审查方法：`git diff HEAD -- gpminput.c`（v1.65 → t2）逐段审阅；对全部 `popen/system/fork/execv/usleep` 做调用图审计；逐项核对 t2/t4 原始日志（不把「日志有行」当唯一证据，优先用应用侧 TOUCH/位移/前台组件/截图/计数）；只读 adb 复核设备哈希/缓存/显示（未向设备注入任何命令，避免干扰 t10 的真机测试）。

## 1. 结论摘要

1. **串扰根因真修**：`input swipe` 由「每次 fork 一条、可并发」改为**串行手势队列**（任意时刻 ≤1 条在飞；异轴硬丢弃并记 `SWIPE_DROP`；同轴 1 深度排队；`execv("/system/bin/input")` 少一层 shell；`N` 通知栏手势同队列）。这是对 DIAG 根因（两条并发 swipe 互相吞并）的结构性修复；helper 没有改任何阈值来「躲」串扰。应用侧另有轴仲裁，t4 A3 的 `gesture axis arbitration … -> vertical` 是双保险。
2. **没有把同步 popen/dumpsys/input 引入主循环**：全部 `popen/system` 位于 fork 子进程或仅由子进程调用的函数；`J`（`caption_fullscreen_click`）和 `u` 慢链路都在 fork 内；`c` 查询自身 fork。主循环仅剩有界 `usleep`（`C` 组合键、`j`/`ensure_mouse`、`R`，见 R2）。
3. **open_app 主路径正确**：`resolve_component()`（`cmd package resolve-activity --brief` → `pm resolve-activity --brief`）+ `am start -W -n <pkg>/<act> -f 0x10000000 --user 0`；`am start -p` 仅在解析/启动失败时次选并打 `fallback=pkg`；monkey 最后兜底。源码与真机日志双证据，`fallback_pkg=0 monkey=0`。
4. **唤醒可用**：Linux `KEY_WAKEUP=143`（修掉旧 224=KEY_BRIGHTNESSDOWN 的错误）；已亮时探测优先、零注入；Dozing→Awake 444/456/414ms；3s 去重生效。
5. **无回归**：DPAD_CENTER（`D 0 23`→`lcode=28`，应用侧 `key_enter=1/mouse_click=0`）、SELECT 真实下滑（`NOTIF rc=0` + NotificationShade + 截图 4.12MB 变化）、WHEEL 方向（`H 3→h=1`、`H -3`、`S ±2→h=0`）、串行队列语义（starts=dones、overlaps=0、应用侧 TOUCH 计数=注入数）均保持。
6. **prep 达标**：t2 采样 [157 186 193 159 161 242 219 245 347 391] µs（中位≈200、最大 391）；t4 中位 108/226µs、最大 661µs；均远低于「中位<1500、最大<5000」。
7. **证据层面的问题**：H3 CPU 口径不可比（R1，medium，必须 release 复测）；H2 只判中位未判最大、D/E 阈值比 DIAG 建议宽 5–10 倍（R3）；popen 审计与 HELPER 行号对的是旧修订（R4）。
8. **不满足项（blocking）**：acceptance #3 的「投毒 **≤2s** 纠正」不成立——投毒证据在 **2.4s** 才取样（`helper-v166-final-all.txt:50-52`），而且源码是「2s 周期刷新 + 2s mtime 节流」：第一次 2s tick 若落在投毒后 <2s 会被节流丢弃，要等下一个 2s tick，最坏约 **4s** 才开始纠正（+dumpsys 0.1–0.3s）。R5 给出可执行修法（周期刷新绕过 mtime 节流 / 缩短周期或改验收阈值并补 2.0s 边界证据）。

## 2. t2 的 9 条 acceptance 逐条核对

| # | acceptance | 判定 | 证据（原始） | 备注 |
|---|---|---|---|---|
| 1 | 单次推杆只注入一次、只作用一个区域；两轴同时超阈按仲裁只取一个轴 | **PASS** | t2 `helper-v166-appaxis.txt:5,8-10`：纯纵 Z=5 V=0、region `5×Z@480`、app TOUCH=5；双轴 0.36/0.36 → Z=5 V=0；t4 `auto_suite_console.txt:17-24`：A1 PY d=1337/HS=0/Z=2；A2 HS=512/PY=0/V=1；A3 PY=1415/HS=0/Z=5/V=0 + 仲裁日志 | 「只注入一次」按 App 的重复手势语义是「一次推杆只一个轴/一个区域」；每次注入都有 TOUCH 对应 |
| 2 | 不再并发 fork+input swipe；用应用侧 TOUCH/click 证明两条都完整到达 | **PASS** | `helper-v166-appaxis.txt:5,13,17`：注入 5→TOUCH 5、6→6、4→4；`helper-v166-final-all.txt:11-37`：case1 starts=1/dones=1/overlaps=0、case2 starts=2/dones=2、case3 串行；t4 A4 starts=18=dones、overlaps=0 | 队列实现为 `swipe_submit/swipe_spawn/gesture_reap/gesture_poll`（当前 2006/1979/2034/2050） |
| 3 | 边界缓存带 display+task+分辨率校验；投毒 ≤2s 纠正；起手点回 task 内 | **FAIL（R5，blocking）** | `helper-v166-final-all.txt:46-54`：投毒后立刻 900,408（task 600..1200/240..800），**2.4s 后** 1280,480（task 0..2560/0..1600），cache corrected；legacy 投毒无效 | 「带 display+task+分辨率校验」「起手点回 task 内」满足；**「≤2s」不满足**：证据 2.4s；源码 2s 周期 + `bounds_refresh_poll` 的 `mtime<2s` 节流会丢掉第一个周期请求，最坏约 4s（详见 R5） |
| 4 | 唤醒：Dozing→Awake；已亮负例 mWakefulness 不变 | **PASS** | `helper-v166-final-all.txt:61-76`：负例 `WAKE … uinput=0 skip=1 probe=1`、uinput=1 count=0、wf 不变；正例 `src=uinput took=444ms`；t4 `auto_suite.result.txt` K1/K2 | 回退链（input 224 / cmd power）未被触发，见 §6 |
| 5 | open_app 主路径 resolve-activity+am start -n；真机启动 PiliPlus/抖音；不以 -p 为主 | **PASS** | 源码 `case 'w'`（2920-2976）、`resolve_component`（2519）；`helper-v166-final-all.txt:100-110`：PiliPlus `.MainActivity` rc=0、抖音 `.splash.SplashActivity` rc=0、top 均确认、fallback=0/monkey=0；t4 G1/G2 | `OPEN_APP … async` 是父进程 ack，真实结果由子进程 `via` 行给出 |
| 6 | 主循环无同步 popen/dumpsys/input；prep 中位<1500、最大<5000µs | **PASS（R2/R4 附注）** | 源码审计见 §4；`helper-v166-prep.txt:4-6`：[157…391]µs，max 391；t4 `auto_suite.result.txt` H2：108/226µs，max 661µs | t4 H2 只断言中位（R3）；审计文件行号旧（R4） |
| 7 | 增益查询/设置；原闲置 g_pointer_gain 真正参与 | **PASS** | `helper-v166-gain.txt:5-12`：`g 0 4.68`→effective 4.68，`CENTER(steps+gain 4.68)`；`g 3.25`→3.25；t4 K3 | `g` 默认 ptr=3.25，`effective_gain()` 优先 center，再 ptr（源码 1570-1574） |
| 8 | 全命令 smoke + DPAD_CENTER/SELECT/WHEEL 不回退 | **PASS** | `helper-v166-smoke.txt:6-8`：OUT 91 行、ERR=0；`helper-v166-final-all.txt:80-93`：`KEYUIN 0 23 lcode=28`、`NOTIF rc=0 dur=402ms`、WHEEL 3/-3 h=1、2/-2 h=0；t4 I1/I3/I4/I6 | smoke 只作辅助；行为证据来自 t4 I 组与 appaxis |
| 9 | aarch64 静态编译成功，推送哈希=编译产物 | **PASS（当前漂移见 §0）** | HELPER-v166.md:182-191：gcc exit 0、sha256 `4f261754…`，设备/模块同哈希；t4 BASE-HELPER；t2 补充 commandsRun | 当前设备已是 t10 的 `6076b63b…`；t7 必须对最终哈希重跑 |

## 3. 串扰：根因修复，不是调参

### 3.1 源码层面（结构性保证）

- `swipe_submit()`（当前 2006-2032）：在飞时**异轴直接丢弃**并 `SWIPE_DROP reason=crosstalk`；同轴进 1 深度队列（`SWIPE_QUEUE_MAX=2`）；空闲但距上次结束 <90ms 的反向手势也丢弃（`axis_guard`）。
- `swipe_spawn()`（1979-2004）：`spawn_exec("/system/bin/input", {"input","-d",disp,"swipe",x1,y1,x2,y2,ms})`，`execv` 直启、stdio `/dev/null`；`g_swipe_pid` 唯一。
- `gesture_reap()`（2034-2047）：只有该 pid 退出才清 `g_swipe_pid`，`SWIPE_DONE` 成对出现；`gesture_poll()`（2050-2058）在 60ms settle 后启动队首；`gesture_poll_timeout()` 让主循环按到期时间 poll，不忙等。
- `N` 通知栏手势也走 `swipe_submit`（当前 2842-2861），不再与滚动/翻页并发。
- 旧代码的 `vSwipeArmed/hSwipeArmed` 死变量不在 helper；helper 提供的是**注入层**保证，应用侧还要做轴仲裁（t3），两者不冲突。

### 3.2 真机证据（应用侧计数，不是只看 helper 日志）

- 同 tick `Z`+`V`：1 条 `SWIPE` + 1 条 `SWIPE_DROP` + `starts=1 dones=1 overlaps=0`（`helper-v166-final-all.txt:11-15`）。
- 同轴连发：两条都完整执行（`SWIPE_QUEUED`→`SWIPE_DONE`，`starts=2 dones=2`，`:16-22`）；应用侧 `TOUCH/swipe=6` 对应 6 条注入（`appaxis:13`）。
- t4 A0 判别力自检：绕过 App 直接注入竖+横，PY 1415→366、HS 0→512（两区都能动）→ 证明 A1/A2/A3 的「只动一区」不是指标失灵；A2 的 PC 像素 diff 99.4% 落在分页横带（`VERIFY-v166.md:56-71,207-213`）。
- t4 A3：常驻 vgpad + `sendevent` 把 RX 从 0.24 抬到 0.36、RY 保持 0.73（两者同时超阈约 1.2s），helper Z=5/V=0，应用侧 `gesture axis arbitration: RY=0.7324 RX=0.36 -> vertical`（`auto_suite_console.txt:22-24`）。

### 3.3 残留边界（不影响本次验收，但需知情）

- `J`（DeX 标题栏全屏）在 fork 内用 `input tap`，**不经过手势队列**；若恰有 swipe 在飞，tap 可能打断滑动。J 是低频的窗口操作，不属于本次「两条 swipe 并发」根因；如要绝对「一次只一条触摸流」，应把 tap 也入队。
- 双指缩放（`l`）走 uinput 触摸屏，与 `input swipe` 是两条不同设备注入；DIAG 的 MT 残留假设已被排除（`helper-v166-app-crosstalk-diag.txt:51-58`），但严格串行语义只覆盖 Z/V/N。
- `N` 若在横向 swipe 在飞时按下会被 `crosstalk` 丢弃；同轴则排队。这是串行化的取舍，非回退（旧版并发同样会互相吞并）。

## 4. 主循环阻塞审计（t5 acceptance #2）

审计口径：`git diff` + 当前 tree 全部 `popen/system/execv/fork/usleep` 调用点；结论：**主循环没有同步 popen/dumpsys/input**，重操作都在 fork 子进程；`J`/`u` 慢链路确认在 fork 内。

| 位置 | 调用 | 执行上下文 | 结论 |
|---|---|---|---|
| `case 'J'`（2871） | `caption_fullscreen_click` | `fork()==0` 子进程；内部 popen/system/usleep 全在子进程 | ✅ |
| `case 'u'`（3023） | `cmd_wake_screen`（1123） | 主循环只读 wake.txt + 可选一次 uinput 写；探测/兜底在 `wake_slow_path`（1071）fork 内 | ✅ |
| `case 'c'`（3028） | `cmd_cursor_query`（1339） | 自身 `fork()`，回 `CURSORQ` 后子进程跑 dumpsys input | ✅ |
| `case 'O'/'P'/'Y'/'T'/'t'/'f'/'L'/'r'/'?'/'W'/'F'/'X'/'E'/'w'` | 各重命令 | 均 `fork`；`w` 内 resolve/am/monkey 全在子进程 | ✅ |
| 主循环每 2s | `bounds_refresh_poll`（1875） | `fork` 后 dumpsys activity；2s 节流；主循环只 stat/置 flag | ✅（子进程 CPU 成本见 §12） |
| 主循环每 2s | `wake_refresh_async`（1029） | `fork` 后 dumpsys power | ✅ |
| `case 'j'`（2804） | `ensure_mouse`（1533） | **主循环内 `usleep(120ms)`**（鼠标被 `h` 销毁后重建） | ⚠ 有界阻塞，已在 HELPER §4.3 记录；R2 |
| `case 'R'`（3049） | 重开设备 | **主循环内 `usleep(150ms)`** | ⚠ 已在 HELPER §4.3 记录；R2 |
| `case 'C'`（2754） | `cmd_key_combo`（2460） | 主循环内 `usleep(8ms)*n + 30ms + 8ms*n`（8 键最坏 ~158ms），未 fork | ⚠ 文档未列；R2 |

`SWIPE prep` 只包含几何/缓存读取（`bounds_cache_read` 的 fopen/fscanf/stat + top.txt），t2 [157…391]µs、t4 108/226µs 与源码一致；滑动路径不再 fork 取 bounds（`cmd_swipe` 只 `bounds_refresh_request`）。

## 5. open_app（t5 acceptance #3）

- 源码（`case 'w'` 2920-2976）：`resolve_component()` 先 `cmd package resolve-activity --brief -a MAIN -c LAUNCHER <pkg>`，失败再 `pm resolve-activity --brief`；成功则 `am start -W -n <comp> -f 0x10000000 --user 0`，读首行，命中 `"Error"` 也算失败；失败才 `am start -p`（打 `fallback=pkg`），再失败才 `monkey -p`。
- 真机（`helper-v166-final-all.txt:100-110`）：PiliPlus `via com.example.piliplus/.MainActivity rc=0 out=Starting: Intent { flg=0x10000000 … }`，top=`.MainActivity`；抖音 `via com.ss.android.ugc.aweme/.splash.SplashActivity rc=0`，top 同包（随后进登录页）；`fallback_pkg_count=0 monkey_count=0 resolve_failed_count=0`。t4 G1/G2 独立复跑一致。
- 注意：父进程先回 `OPEN_APP <pkg> async`，真实成功以子进程 `via`/`rc` 行为准；本审查按 `via` 行判定，不把 async ack 当证据。

## 6. 唤醒（t5 acceptance #4）

- `KEY_WAKEUP=143`（Linux），旧 224 是 `KEY_BRIGHTNESSDOWN` 的历史 bug 已修（源码 1048-1056）；`wake_slow_path` 永远 fork（1071-1115），探测 → uinput → `input keyevent 224` → `su -M -c 'cmd power wakeup'`。
- 负例（已亮，缓存 Awake）：`WAKE was=Awake now=pending uinput=0 req=1 probe=1` → `now=Awake uinput=0 skip=1 probe=1`，`uinput=1 count=0`，wf 不变（`helper-v166-final-all.txt:61-66`；t4 K1）。
- 正例（`p` 灭屏 → Dozing）：`WAKE was=Toggling now=pending uinput=1` → `now=Awake uinput=1 done=1 src=uinput took=444ms`（`:67-71`；t4 K2 414ms）。3s 去重：第二次 `dedup=1`（`:72-75`）。
- **未覆盖**：uinput 失败后的 `input 224`/`cmd power` 回退链没有被真机触发（正例都在 uinput 成功）；缓存缺失且屏幕已亮时 `cmd_wake_screen` 会注入一次 KEY_WAKEUP（源码 1146-1149，注释称亮屏空操作），该路径没有副作用证据。两者都不影响本次「Dozing 可唤醒 + 已亮不注入（缓存命中）」验收，但发布说明不应把回退链写成已实测。

## 7. 既有行为无回退（t5 acceptance #4）

| 项 | 证据 | 判定 |
|---|---|---|
| d-pad 粘性 + A=DPAD_CENTER | `KEYUIN 0 23 lcode=28`（helper）；t4 I1 `mouse_click=0 key_enter=1` | 保持 |
| 摇杆后回鼠标模式 | t4 I1B `mouse_click=1 key_enter=0`；D5 同 | 保持 |
| SELECT 真实下滑 | `NOTIF swipe async`→`rc=0 dur=402/415ms`；t4 I6 `NotificationShade` + 截图 delta 4,124,291B/像素 4,095,995px | 保持 |
| X 双击 400ms | t4 I2 `top=RecentsActivity`、`double x -> recents` | 保持 |
| X+LB / X+RB 方向 | t4 I3 `SWIPE … dx=+359` + `wheel_right`；I4 `dx=-1536` + `wheel_left`；helper `WHEEL ±3 h=1`、`WHEEL ±2 h=0` | 保持 |
| 空闲隐藏原地恢复 | t4 I5 P1=P2=2559,803、`pointer shown at last position (no correction move)` | 保持 |
| 串行队列语义 | A4 starts=18=dones、overlaps=0、orphan=0、queued=6；appaxis TOUCH=注入数 | 保持 |

## 8. t4 证据审计（逐项找假通过/弱阈值）

- **A 组**：A0 有判别力自检（绕 App 直接注入两轴，两区都动），A1/A2 单轴，A3 双轴超阈，A4 串行计数，A5 drops=0。A2 另有 PC 像素 diff 99.4% 落在横向分页带。证据链完整；A3 的 sendevent 见下方等价性裁定。
- **B/C 组**：B1 2485px（0.97 屏宽）、B2 498、B3 39（旧 0）、B4 中心 612 vs 边缘 498（-18.6%）；C1 6×560=3360、C2 3×1152=3456、C3 比值 1.029。C 组「总行程」取自 helper SWIPE 几何（注入长度），不是屏幕实际滚动像素；与 DIAG 基线同口径，可比较，但发布文档应写明是「注入手势行程」。
- **D 组**：9/9 ≤5px（阈值写 80px）；D0 删 `move_gain` 冷启自标定 `3.2465813`、落点 1278,800；D5 L3 后 A 为鼠标点击。**实测远好于 DIAG 建议的 ≤8px，但报告阈值写 80px**（R3）。
- **E 组**：真实 0/2559/0/1599，估算-真实 0–1px（阈值写 40px）；贴边 5×200ms 零位移、反向到对边；d-pad/隐藏后同样可达。**实测同样远好于 DIAG ≤8px**（R3）。
- **F 组**：0.92 快推 Dozing→Awake（`WAKE … done=1`），0.37/0.73/慢爬 2.1s 保持 Dozing 且无 WAKE 行。负例覆盖充分。
- **G 组**：见 §5；G3 预置 `mix_10` 后 `OPEN_APP=0`、前台回桌面，证明默认映射不覆盖自定义。
- **H 组**：H1 中位 7/6ms、最大 13ms（12 次，logcat 同时钟）；H2 中位 108/226µs、最大 661µs；H4 空闲 `CURSORQ=0/CURSOR=0`。**H3 见 R1：3.53/3.47% 是「t0/t1 仍存活线程」快照求和，短命 JIT 线程被漏掉；`/proc/<pid>/stat` 6.03/5.97% 才是进程 CPU，超过 4% 阈值**。
- **I 组**：见 §7；I6 截图 + NotificationShade + rc=0 三重证据，不是「日志有行」。
- **J 组**：J1 默认横屏（dumpsys display rotation 1 + app 2560×1600 + settings），J2 守护 ≈3.25/3.5s，J3 居中 1281,803（2,3px），J4/J5 分栏截图，J6 竖屏回落 engine 1600×2560 单列无崩溃。J6 的 `dumpsys` 仍报 2560×1600 的说明已在报告披露。
- **K 组**：K1/K2 wake 负/正例与 t2 独立一致；K3 增益 4.68 生效；K4 `c` 3/3 max 3px（display 0，另有 display 1/44 共存）；K5 P 落点 max 4px；K6 10 条命令 61/62ms。

### 8.1 A3 的 sendevent 等价性裁定（t5 acceptance #6）

A3 用常驻 vgpad（`vgpad stick 0 0 60000 &`）先起 RY，再 `sendevent <node> 3 3 11796` 把 RX 抬到 0.36，两个值同时超阈约 1.2s，应用侧记录 `gesture axis arbitration: RY=0.7324 RX=0.36 -> vertical`。这与真实双轴推杆的**状态**等价：应用读取的是同一 evdev 轴值，仲裁看到同样的 `<0.35/≥0.35` 组合。差异只在时序（真实硬件同一 HID 报告 vs 两次 SYN 帧），而应用是逐事件/逐帧读当前值，不依赖「同一帧」；A0/A1/A2 已用真实 `vgpad stick` 路径证明单轴与判别力。**结论：等价，可接受；不强制补测**。建议在 release 验收时顺手补一次真实物理双轴斜推（低成本），但这不是 t2 的阻塞项。

### 8.2 阈值与口径（t5 acceptance #5 的裁定）

- **H3 CPU 不可比**：见 R1。**「提速」的可靠证据是 H1（8→7ms 中位、20→13ms 最大）与 H2（prep 1035→108/226µs）以及 app 帧耗时 128–155µs**；CPU/资源不回退在 debug 构建上**没有成立**（进程级 6%）。t7 已把 release 构建同口径复测写入 acceptance，必须执行后才可在发布说明写 CPU/资源结论。
- **D/E 阈值**：t4 任务书用 80px（L3）/40px（E），DIAG 建议 ≤8px；实测 5px/0–1px 已满足更严值。判定本身不假（数据真实），但「阈值过松」会让未来 50–79px 的回归漏检（R3）。
- **H2**：只断言中位 <1500，未断言最大 <5000（t2 acceptance #6 要求最大）；本次最大 661µs 达标，但脚本应补 max 判定（R3）。
- **B2/B3/I3**：B2/B3 用「>0」、I3 无最小位移，属方向性阈值；实测 498/39/359px，不构成假通过，但不宜作为数值回归门。
- **缓存投毒**：acceptance #3 的 ≤2s 不成立（证据 2.4s；源码最坏约 4s），见 R5——这是本次唯一的 t2 acceptance 失败项。

## 9. Findings（**R5 阻塞 t2 acceptance #3**；R1 必须在 t7 闭合；R2–R4 低风险）

| id | severity | problem | requiredFix | file:line |
|---|---|---|---|---|
| R1-CPU-METRIC | **medium** | H3 的 3.53/3.47% 是 t0/t1 **仍存活线程**的 utime+stime 快照求和；t0→t1 之间创建并退出的 JIT 编译线程被漏掉。`/proc/<pid>/stat` 的进程级值 6.03/5.97% 才包含这些短命线程，超过「≤4%」阈值。报告虽披露两口径，但仍以 3.53% PASS，并写成「engine 静置60s CPU ≤4%」；debug 构建下「资源不回退/提速」不能据此成立。 | 在 **release 构建**上做 60s 进程级（utime+stime，含 cutime/cstime 口径说明）复测，与 v1.65 同方法比较；未复测前发布说明不得写 CPU 不回退/提速资源结论；把 H3 线程级和标成辅助指标并注明「不含短命 JIT 线程」。 | `work/docs/VERIFY-v166.md:155,158`；`work/scripts/v166_auto_suite.sh:899-917` |
| R2-MAINLOOP-RESIDUAL | low | 主循环已无同步 popen/dumpsys/input，但仍有等价阻塞：`case 'C'` 直接调 `cmd_key_combo`，内含 `usleep(8ms)×n + 30ms + 8ms×n`（8 键最坏 ~158ms）且未 fork；`case 'j'` 的 `ensure_mouse` 120ms、`case 'R'` 150ms 在 HELPER §4.3 已记录，`C` 未记录。 | 把 `C` 的按键时序放到 fork/异步（与 O/P/Y/T 一致），或在 HELPER §4.3 明确列出并给出最坏阻塞时间；不要把 `C` 算作「无阻塞」。 | `project/app/src/main/assets/gpminput.c:2754-2777,2460-2482`（当前 tree 829e049b；t2 源码相同）；`work/docs/HELPER-v166.md:236` |
| R3-THRESHOLD-LOOSE | low | D 组阈值 80px（DIAG 建议 ≤8px）、E 组 40px（DIAG ≤8px）、I5 60px；H2 只判中位不判最大；B2/B3 用「>0」、I3 无最小位移。实测（D max 5、E 0–1、I5 0、prep max 661）其实满足更严阈值，但松阈值会让未来回归漏检。 | 在 VERIFY/集成文档按 DIAG 的 ≤8px 重新判定（数据已满足）；H2 补 `max<5000` 断言；B2/B3/I3 补最小位移或注明是方向性检查。 | `work/docs/VERIFY-v166.md:100-107,118-124,155`；`work/scripts/v166_auto_suite.sh:495,526,532,628,887,991,1031` |
| R4-EVIDENCE-STALE | low | `helper-v166-popen-audit.txt` 的行号（1489/1964/2327/2745…）对应 3021 行左右的旧修订，不是被审的 `4f261754`/`5dad5ba9`，也不是当前 `829e049b`；HELPER-v166.md 的源码行号（1752/1621/1790）同样对不上最终源码。审查人已独立审计当前源码确认「主循环无 popen」结论不变，但交付审计文件本身不可复核。 | 在最终源码（t10 之后）重生成 popen/system 审计与源码行号引用，写入 HELPER-v166.md；不要沿用旧审计。 | `work/docs/evidence-v166/helper-v166-popen-audit.txt:1-68`；`work/docs/HELPER-v166.md:4,13-16` |
| R5-POISON-2S | **medium（blocking）** | acceptance #3 要求「投毒后 **≤2s** 纠正」，但 (a) 证据在 **2.4s** 才取样（`after 2.4s: SWIPE … 1280,480`），2.0s 边界未被证明；(b) 源码是「主循环每 2s 置请求」+「`bounds_refresh_poll` 内 `mtime<2s` 直接 return 并清 flag」（`gpminput.c:1883`）：若第一个 2s tick 落在投毒后 <2s，请求被节流丢弃，要等下一个 2s tick，最坏约 **4s** 才开始纠正（再加 dumpsys 0.1–0.3s）。因此「≤2s」在实现层不成立，不是取样误差。 | 二选一并在真机复测：(a) 让周期刷新**绕过** `mtime<2s` 节流（周期本身已是节流；保留滑动路径的节流），使最坏 = 下一个 tick（≤2s）+ dumpsys ≈2.3s，并把验收阈值改为「≤2.5s」并补 2.0/2.3/2.5s 取样；或 (b) 把周期缩到 ≤1.5s 并实测 CPU 代价，才能保留「≤2s」。修复后重跑投毒用例（poison + 2.0s/2.3s/2.5s 三次滑动）。 | `project/app/src/main/assets/gpminput.c:1875-1905,3152`（当前 tree）；`work/docs/HELPER-v166.md:39,127`；`work/docs/evidence-v166/helper-v166-final-all.txt:50-52` |

> R5 是 t2 acceptance #3 的**阻塞项**：按契约 needs_revision 必须 fail。修复只需几行（周期刷新绕过 mtime 节流 + 调阈值/周期）并重测投毒；不涉及串扰/唤醒/启动/回归路径。R1 是 **t4 证据/报告** 的阻塞条件（不是 t2 代码缺陷），t7 的 release CPU 复测必须闭合后才能写「提速/资源不回退」；R2–R4 低风险，可与 t7/t10 的最终文档一起修。

## 10. 交付/发布前必须满足的条件（给 t7）

0. **先修 R5 并重测**（t2 acceptance #3）：让周期刷新绕过 `mtime<2s` 节流并把验收改为 ≤2.5s（补 2.0/2.3/2.5s 取样），或把周期缩到 ≤1.5s 并实测 CPU；修复后重跑 poison 用例。这是 t2 的阻塞项，t7 不应在它闭合前开始发布。
1. 在 **release 构建**、**进程级** CPU 口径下复测 60s 空闲（同 v1.65 基线方法），写进 VERIFY/APP/README；未复测前不写「CPU 3.5% / 资源不回退」。
2. 用 **t10 之后的最终 helper 哈希**重跑 `v166_auto_suite.sh`（t4 的 `4f261754` PASS 不覆盖 `6076b63b`/后续重建）；BASE-HELPER 必须等于 `release/gpminput-v1.66` 与设备/模块哈希。
3. 更新 HELPER-v166.md 的最终哈希、源码行号、popen 审计（R4）；把 R2/R3 的口径写进报告。
4. 发布说明中的「提速」只引用 H1/H2/帧耗时（有实测），CPU 引用 release 复测结果。

## 11. 复现命令

```sh
# t2 助手单测（会临时停 watchdog/引擎，结束后自动恢复）
adb -s 192.168.10.36:6666 push work/scripts/probe_v166_helper_cmds.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell su -c 'sh /data/local/tmp/probe_v166_helper_cmds.sh all'
#   smoke | crosstalk | wake | openapp | poison | gain | regress | prep | all

# t4 全量（当前设备已被 t10 重建，t7 用最终哈希重跑）
adb -s 192.168.10.36:6666 push work/scripts/v166_auto_suite.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/v166_auto_suite.sh"

# 只读复核（本审查实际执行）
adb -s 192.168.10.36:6666 shell su -c 'sha256sum /data/adb/gpm/gpminput /data/adb/modules/gpm_dex/gpminput'
adb -s 192.168.10.36:6666 shell "dumpsys window displays | grep -m1 -E 'cur=|app='; settings get system user_rotation; dumpsys power | grep -m1 mWakefulness="
```

## 12. 限制与未覆盖

- 审查期间 t10 正在改 `gpminput.c`（当前 `829e049b`），设备 helper 已变为 `6076b63b`；本报告对 t2 的控制路径结论基于源码函数语义与 t4/t2 原始日志，不覆盖 t10 的新 CAP 逻辑。
- 未在设备上重放注入类实验（设备正被 t10 占用；t2/t4 已有原始证据）。helper 自身 CPU 未做受控 60s 采样；每 2s 的 bounds 刷新会 fork `dumpsys activity`（有子进程 CPU 成本），本次只确认它不在主循环阻塞，未量化其空闲代价——建议 t7 一并测。
- `J` 的 `input tap`、`l` 的 pinch 不走手势队列（§3.3），属残留并发面；不影响本次 Z/V 串扰验收。
- 唤醒回退链（input 224 / cmd power）、缓存缺失+已亮时的 KEY_WAKEUP 注入未实测（§6）。
