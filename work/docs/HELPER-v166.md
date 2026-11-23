# HELPER-v166 — 助手侧（gpminput，C）实现与真机证据

> 任务：t2 + t10 + t11 / 版本：v1.66（基线 v1.65）/ 设备：SM-F9360（adb 192.168.10.36:6666，横屏 2560×1600）
> 源码：`project/app/src/main/assets/gpminput.c`
> 产物：`project/app/src/main/assets/gpminput`，sha256 `1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf`（851928 B）
> 设备 `/data/adb/gpm/gpminput` 与 `/data/adb/modules/gpm_dex/gpminput` 均为同一 sha256（见 §7）。
> 变更记录：t2 `dc41cb9b…` → t2-r2（`c` 多显示修复）`4f261754…` → t10（`CAP gesture`）`139087e7…` → t11（CAP mouse/wheel）`6076b63b…` → **t13（R5 投毒阈值≤2.5s + R2 `C` 异步 + R4 审计重生成）`1bf7306f…`（最终）**。**integrator 以 §1.6/§2.9 的 `1bf7306f…` 为发布哈希。**

## 1. 改动总览

| # | 目标 | 实现（源码位置） | 关键日志 |
|---|------|------------------|----------|
| 1 | 滑动串扰：一次手势只作用一个区域 | 串行手势队列 `SWIPE_QUEUE_MAX`(1752) + `swipe_submit`/`swipe_spawn`/`gesture_reap`/`gesture_poll`(1790-1860) | `SWIPE … axis=… n=… prep=…us`、`SWIPE_QUEUED`、`SWIPE_DROP … reason=crosstalk/axis_guard/queue_full`、`SWIPE_DONE … rc=… dur=…ms` |
| 2 | task 边界缓存：display+包名+分辨率校验，投毒 ≤2s 纠正 | `BOUNDS_STALE_MS`(1621)、`bounds_cache_read`(1630)、`bounds_refresh_poll`(1675)、主循环每 2s 主动刷新 | 缓存文件 `/data/adb/gpm/taskbounds-<display>.txt`，格式 `pkg x1 y1 x2 y2 w h`；legacy `taskbounds.txt` 只写不读 |
| 3 | 唤醒命令 `u` | `cmd_wake_screen`(1122)、`wake_slow_path`(1070)、`wake_refresh_async`(1028)、`wake_cached`/`wake_cache_write`/`wakefulness_probe` | `WAKE was=… now=… uinput=… req=1`、`WAKE … done=1 src=uinput|input224|power`、`WAKE … skip=1 probe=1`、`WAKE_STATE A -> B` |
| 4 | open_app 组件解析为主路径 | `resolve_component`(2318) + `case 'w'`：`cmd package resolve-activity --brief` → `pm resolve-activity --brief` → `am start -W -n <pkg>/<act>` | `OPEN_APP <pkg> via <comp> rc=0 out=…`；`am start -p` 只在解析失败时 `fallback=pkg`；再失败才 `monkey` |
| 5 | 增益标定 | `g_pointer_gain`(1407) + `effective_gain`(1409) 真正参与 `pointer_goto`/`cmd_center`；`g [center] [ptr]` 查询/设置 | `GAIN center=… ptr=… effective=…` |
| 6 | 主循环去同步阻塞 | 所有 `popen/dumpsys/input/am` 命令改为 fork 子进程（见 §4 审计）；`M/B/S/H/K/A/D/p/O/P/V/Z/N/g/u/c` 只做内存+write/fork；按键释放改延时队列 `key_release_later`(311) | `SWIPE … prep=` 采样、`KEYUIN`、`ARROW` |

### 1.1 串行手势队列（根因修复）

`input swipe` 每次起一条独立注入流，两条并发会互相吞并（DIAG v166 §2：应用只收到 1 click / 0 TOUCH）。现在：

- 任意时刻最多 **1 条** `input swipe` 在飞（`g_swipe_pid`）；
- 在飞期间收到**另一轴**手势 → 直接丢弃并记录 `SWIPE_DROP … reason=crosstalk`（这就是“一次手势只作用一个区域”的硬保证）；
- 手势结束后的 **90ms 换轴保护窗**（`SWIPE_AXIS_GUARD_MS`）内反向滑动继续丢弃（`reason=axis_guard`）；
- **同轴**请求进 1 深度队列（`SWIPE_QUEUE_MAX=2`），前一条结束后 60ms（`SWIPE_SETTLE_MS`）按序执行，不丢当前方向；
- 注入不再经过 `fork()+system()+sh -c`：`spawn_exec("/system/bin/input", argv)` 直接 exec，少一层进程（prep 更快）；
- 注入进程 stdout/stdin 全部 `/dev/null`，不会被应用协议污染；
- 通知栏 `N` 也走同一队列（`NOTIF swipe async/rc`），不再和滚动/翻页并发。

### 1.2 task 边界缓存

旧缓存问题（DIAG §2 实测）：单一文件跨 display 覆盖、刷新失败写全屏、永不过期、不校验归属、刷新 fork 在滑动路径里。现在：

- 每 display 一份 `/data/adb/gpm/taskbounds-<display>.txt`，内容 `pkg x1 y1 x2 y2 w h`；
- 读取校验：分辨率一致、`pkg` 与 `top.txt`（App 的 `t` 查询维护）一致、矩形在屏幕内且 ≥120×120、mtime ≤4s；
- 任一项不满足 → 本次用全屏边界（决定论），并置 flag 由主循环刷新（滑动路径零 fork）；
- 主循环每 2s 主动刷新一次该 display 的真实边界 → 被写坏的缓存最多 2s 被覆盖；
- legacy `taskbounds.txt` 仍写（给磁盘诊断脚本看），但**不再参与决策**。

### 1.3 唤醒命令协议（给应用侧）

```
u
→ WAKE was=<Awake|Dozing|Asleep|Toggling|unknown> now=pending uinput=<0|1> req=1 age=<ms>
→ WAKE was=<旧> now=<实测> uinput=<0|1> done=1 src=<uinput|input224|power> probe=<0|1> took=<ms>
   或（已亮/刚灭屏但探测到 Awake）: WAKE was=Awake now=Awake uinput=0 skip=1 probe=1
   或（3s 内重复）: WAKE … uinput=0 dedup=1 req=1
```

- `uinput KEY_WAKEUP` 用 **Linux 143**（旧 `wake_key_once()` 写的 224 在 Linux 上是 `KEY_BRIGHTNESSDOWN`，是历史 bug，已修）；
- 兜底链：uinput 143 → `input keyevent 224`（Android KEYCODE_WAKEUP）→ `su -M -c 'cmd power wakeup'`；
- 已亮时**零注入**；缓存说 Awake 但可能刚灭屏 → 子进程先探测再决定（探测到 Awake 就跳过，所以负例仍是零注入）；
- `p`/`D … 26` 会写 `Toggling` 让缓存立即失效，避免刚灭屏后的唤醒被旧缓存吞掉；
- 慢路径全在子进程：命令循环不阻塞。

### 1.4 增益命令

```
g                 → GAIN center=… ptr=… effective=…
g <center>        → 设居中增益（旧行为兼容）
g 0 [ptr]         → center 归零：effective 用实测 ptr 增益（供闭环标定）
g <center> <ptr>  → 同时设置
```
`ptr` 默认 **3.25**（DIAG §4 实测 pointer_speed=-1）；`pointer_goto`/`cmd_center` 用 `effective_gain()`，`g_pointer_gain` 不再闲置。

### 1.5 光标查询命令 `c`（给应用侧闭环，v1.66-r2 修多显示歧义）

`dumpsys input` 的 `CursorStatesByDisplay` 是**按 display 分段**的，且段内 `hoveringPointers` 是
**raw natural 坐标**（例如面板 904×2316 竖屏空间）；App 的 `Display.getSize()` 是逻辑空间
（2560×1600）。旧实现扫全文取第一个 `hoveringPointers`，会随机命中 display 1/30（HDMI/DeX）
的陈旧状态，闭环会把光标推到别的显示上。现在：

```
c → CURSORQ pid=<child>                              （立即回包）
  → CURSOR <lx> <ly> display=<id> space=logical frame=<pfx,pfw> raw=<rx>,<ry> took=<us>
  → CURSOR -1 -1 display=-1 took=<us>                （找不到）
```

- 分段解析：优先 `display=0` 的 MOUSE hover，否则第一个有 MOUSE hover 的 display（`display=` 告知是哪个）；
- 用该 display 的 `Viewport: orientation / logicalFrame / physicalFrame / deviceSize` 换算：
  ROTATION_90 → `X = y_raw`, `Y = naturalWidth - x_raw`；再按 `physicalFrame → logicalFrame` 缩放平移
  （与 Android InputReader 的 `rotateAndScaleLocked` 一致）；结果裁到 logicalFrame 内并四舍五入；
- 缺 viewport 时退化为 `space=raw` 并给出 `frame=`，应用可自行换算；
- raw 值也一并回传，便于对比/诊断；`dumpsys input` 仍在子进程里跑（回包 24–53µs，循环零阻塞）。

### 1.6 自检 CAP 语义（v1.66-r4 / t10+t11）

`?` 自检的每一行都是**能力**，不是运行时状态；App 设置页把 `CAP <name> 0` 全部显示为「缺失」，
所以不能把瞬时状态（“当前有没有手势在飞”“指针设备当前是否已打开”）写进 CAP。
**发布哈希见本节末尾。**

| 行 | 判定口径 |
|----|----------|
| `CAP mouse` / `CAP kbd` / `CAP wheel` | **能否创建/注入 uinput 设备** = `/dev/uinput`（或 `/dev/input/uinput`）可写；空闲隐藏（`h` 销毁鼠标）**不会**影响该值 |
| `CAP swipe` / `CAP power` | `/system/bin/input` 可执行（注入器的能力） |
| `CAP notif` / `CAP force` | `/system/bin/cmd` 可执行 |
| `CAP screen` | **能读到屏幕状态**（`dumpsys power` 能解析出 `mWakefulness`），不是“当前是否亮屏” |
| `CAP wake` | 有可用的唤醒注入通道（uinput 或 `input`） |
| `CAP cursor` | `dumpsys` 可执行（`c` 查询能力） |
| `CAP gamepad` | 能枚举/抓取手柄 = `/dev/input` 可读可进入（能力） |
| `CAP devices <n>` | **例外：当前 grab 到的游戏手柄数量**。0 = 未接手柄，属**真实状态**而非能力缺失（设置页会如实显示「缺失: devices」；能力项看 `CAP gamepad`） |
| `CAP gesture` | 串行手势队列可用 = `/system/bin/input` 可执行；不用 `gesture_busy()` |
| `INFO pointer device=on\|off` | 运行时状态：虚拟鼠标设备当前是否已创建（空闲隐藏后为 off） |
| `INFO kbd device=on\|off` | 运行时状态：虚拟键盘设备当前是否已创建 |
| `INFO gesture busy/queued` | 运行时状态（是否有手势在飞/排队），只做诊断 |
| `INFO devices_grabbed` | 是否至少有一个手柄已 GRAB |
| `INFO apex` | ART apex 可读（历史诊断项，保持 INFO） |

**v1.66 发布哈希（integrator 以此为准）：`1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf`（851928 B）**
（t2 `dc41cb9b…` → t2-r2 `c` 修复 `4f261754…` → t10 `CAP gesture` `139087e7…` → t11 `CAP mouse/wheel` `6076b63b…`）



## 2. 验收逐条证据

原始日志：`work/docs/evidence-v166/helper-v166-*.txt`（设备输出直存）。

### 2.1 单次推杆只注入一次 / 双轴同阈值只作用一个区域 — PASS

- 助手单测（`crosstalk` case1，同 tick `Z`+`V`）：
  ```
  SWIPE 0 1280,480 -> 1280,20 (task 0..2560 / 0..1600) axis=Z n=1 … prep=235us
  SWIPE_DROP axis=V busy=Z n=1 x=20,y=800 reason=crosstalk
  SWIPE_DONE 0 axis=Z n=1 rc=0 dur=242ms
  starts=1 dones=1 overlaps=0 drops=1
  ```
- 应用侧（真实 vgpad 推杆 + EngineService + PadProbe，`probe_v166_helper_appaxis.sh`）：
  - `RX=+11796(0.36) + RY=-11796(0.36)` 1200ms → `helper: Z=5 V=0`、区域 `5 Z@480`、`app: TOUCH/swipe=5 click=5` → **只有一个轴/一个区域**；
  - `RX=+13000(0.40) + RY=-24000(0.73)`（DIAG 场景 C）→ `helper: Z=4 V=0`，区域 `3 Z@480 + 1 Z@800`（同一轴两次不同起手，串行；无 V 区域）；
  - DIAG 原脚本 `probe_v166_crosstalk.sh` 复跑（新助手 + 旧 v1.65 App）：场景 C/E/H 由“Z=5 V=3 两区域并存”变为 **Z=5 V=0**；A/B 单轴正常（Z=5 / V=3）。

### 2.2 串行队列：两条手势都完整到达 — PASS

- 同轴连发 Z×2（间隔 30ms）：
  ```
  SWIPE … axis=Z n=2 queued=0 prep=122us
  SWIPE_QUEUED axis=Z depth=1 n=2
  SWIPE_DONE n=2 rc=0 dur=261ms
  SWIPE … axis=Z n=3 queued=1 prep=0us
  SWIPE_DONE n=3 rc=0 dur=281ms
  starts=2 dones=2 overlaps=0
  ```
- 全部 5 组场景 `overlaps=0`（任何时刻在飞 ≤1）、`starts==dones`、`inflight_at_end=0`；
- 应用侧完整性：纯纵向 1200ms → helper 注入 5 条、`PadProbe TOUCH/swipe=5`（DIAG 的并发吞并是 2 条手势只到 1 click / 0 TOUCH）；同轴连发 → 注入 6、`TOUCH/swipe=6`；滑动飞行中点击 → `click-down=5 TOUCH/swipe=5`（无丢手势）。

### 2.3 task 边界缓存校验 + 投毒 ≤2.5s 纠正 — PASS（t13/R5 修：周期刷新绕过 mtime 节流）

R5 指出的问题：主循环每 2s 才置一次刷新请求，而 `bounds_refresh_poll()` 会因 `mtime<2s`
把这次请求丢掉，最坏要再等一个 tick（≈4s）才纠正。修法（验收选项 a）：

- `bounds_refresh_request(display, maxX, maxY, force)`：**周期刷新 force=1，绕过 mtime 节流**
  （周期本身已是节流）；**滑动路径 force=0，保留 2s 节流**（避免每次滑动都 fork dumpsys）；
- 最坏 = 下一个 tick（≤2s）+ dumpsys（≈0.1–0.3s）≈ **≤2.3s**，验收阈值按 **≤2.5s** 写明。

真机复测（投毒为合法格式的错误矩形 `- 600 240 1200 800 2560 1600`，然后分别等 2.0/2.3/2.5s 再滑动）：

```
[wait 2.0s]
  SWIPE 0 900,408 -> 900,260 (task 600..1200 / 240..800) axis=Z … prep=227us   ← 投毒后立刻（被带偏）
  SWIPE 0 1280,480 -> 1280,20 (task 0..2560 / 0..1600) axis=Z … prep=353us    ← 2.0s 后已纠正
[wait 2.3s]
  SWIPE 0 900,408 -> 900,260 (task 600..1200 / 240..800) … prep=146us
  SWIPE 0 1280,480 -> 1280,20 (task 0..2560 / 0..1600) … prep=290us            ← 2.3s 已纠正
[wait 2.5s]
  SWIPE 0 900,408 -> 900,260 (task 600..1200 / 240..800) … prep=168us
  SWIPE 0 1280,480 -> 1280,20 (task 0..2560 / 0..1600) … prep=318us            ← 2.5s 已纠正
cache 每次均为 com.dennis.padtest 0 0 2560 1600 2560 1600
```

即 **≤2.5s 内起手点一定回到 task 内**（本次三点全部 ≤2.0s 就恢复，2.3/2.5s 的余量是给
tick 相位 + dumpsys 抖动）。缓存带 `pkg + w h`（display 分文件）；DIAG 原脚本场景 J（投毒
legacy `taskbounds.txt` 为 `0 0 1200 800`）仍然**完全无效**。原始输出：`helper-v166-poison-t13.txt`。


### 2.4 唤醒命令 — PASS

```
before: mWakefulness=Awake
负例（已亮）: WAKE was=Awake now=Awake uinput=0 skip=1 probe=1
              negative uinput=1 count=0 ；after: mWakefulness=Awake（不变）
正例（p 灭屏后 u）: screen off: mWakefulness=Dozing
              WAKE was=Toggling now=pending uinput=1 req=1 age=3098ms
              WAKE was=Toggling now=Awake uinput=1 done=1 src=uinput probe=0 took=444ms
              after: mWakefulness=Awake
去重（3s 内第二次）: WAKE … uinput=0 dedup=1
```

### 2.5 open_app 组件解析主路径 — PASS

```
OPEN_APP com.example.piliplus via com.example.piliplus/.MainActivity rc=0
  out=Starting: Intent { flg=0x10000000 cmp=com.example.piliplus/.MainActivity }
  top: topResumedActivity=ActivityRecord{… u0 com.example.piliplus/.MainActivity t805}
OPEN_APP com.ss.android.ugc.aweme via com.ss.android.ugc.aweme/.splash.SplashActivity rc=0
  top: topResumedActivity=ActivityRecord{… u0 com.ss.android.ugc.aweme/.splash.SplashActivity t806}
fallback_pkg_count=0   monkey_count=0   resolve_failed_count=0
```
源码主路径：`cmd package resolve-activity --brief` →（失败）`pm resolve-activity --brief` → `am start -W -n <comp> -f 0x10000000 --user 0`；`am start -p` 只在解析失败时做次选且必打 `fallback=pkg`，monkey 仅最后兜底。

### 2.6 主循环无同步阻塞 + prep — PASS（`C` 已异步、`R` 例外见 §4.3）

- 审计（**t13/R4 在最终源码上重生成**）：`work/docs/evidence-v166/helper-v166-popen-audit-r2.txt`
  （source sha256 `9994c286…`、3196→3219 行版，含全部 `popen/system` 行号 + 关键函数行号）；
  `cmd_swipe`（L2025）函数体内 `popen|system|execv|fork` 调用 = **none**；
- 重命令全部 fork：`W/J/F/X/E/t/f/L/r/?/O/P/Y/T/w/C`、`c`、`u` 慢路径、边界/顶部/wake 刷新；指针移动/按键/滚轮/触摸/捏合是纯 uinput `write`；
- `C`（组合键）原先在主循环里 `usleep(8ms)×n + 30ms + 8ms×n`（8 键最坏 ≈158ms）——**t13/R2 已改成
  fork 子进程执行**（L2702–2736，`pid_t kc = fork()`；`KCOMBO` 由子进程回包），主循环不再被阻塞；
- 按键释放不再 `usleep(8~45ms)` 卡循环，改延时队列（`key_release_later` L308 / `key_release_due` L327）；
- `prep` 采样（`helper.log` 原文）：`[157 186 193 159 161 242 219 245 347 391]` → **中位 ≈200us、最大 391us**（阈值：中位 <1500us、最大 <5000us）；串扰脚本内另一组 `[279 255 274 301 292 250] max=301`。

### 2.7 增益标定 — PASS

```
GAIN center=0.000 ptr=3.250 effective=3.250
GAIN center=3.250 ptr=3.250 effective=3.250
GAIN center=0.000 ptr=4.680 effective=4.680
CENTER(steps+gain 4.68) rot=1 -> 1280,800      ← 不带 gain 的 O 真正用了 g_pointer_gain
CENTER(steps+gain 3.25) rot=1 -> 1280,800      ← 显式 gain 优先
```

### 2.8 既有命令 smoke + 不回退项 — PASS

- `smoke` 模式：`M/B/S/H/V/Z/O/T/Y/K/G/U/f/p/r/I/L/D/C/t/h/j/A/N/P/R/Q/w/q/k/l/g` + `u/c/?` 各调用一次，t2 版 `OUT lines=91`、t13 复跑 `OUT lines=96`，**`ERR count=0`**（`helper-v166-smoke-t13.txt`；`C` 现在由子进程回 `KCOMBO`）；
- DPAD_CENTER：`D 0 23` → `KEYUIN 0 23 lcode=28`（Linux ENTER，v1.66 约定不变）；
- SELECT：`N` → `NOTIF swipe async` + `NOTIF swipe rc=0 dur=402ms`（真实下滑手势，起手 y=4→55%）；
- WHEEL 方向（v1.62）：`H 3`→`WHEEL 3 h=1`、`H -3`→`WHEEL -3 h=1`、`S 2`→`WHEEL 2 h=0`、`S -2`→`WHEEL -2 h=0`（符号未反转）；
- `A` 方向键、`P` 绝对定位、`O` 居中、`h/j` 指针隐藏/重建、`q/k/l` 触摸与双指：均在 smoke 内正常。

### 2.9 编译与装机哈希 — PASS

```
$ aarch64-linux-gnu-gcc -O2 -static -o gpminput gpminput.c display.c -lm   # exit 0
$ sha256sum project/app/src/main/assets/gpminput
1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf  gpminput
$ adb shell su -c 'sha256sum /data/adb/gpm/gpminput /data/adb/modules/gpm_dex/gpminput'
1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf  /data/adb/gpm/gpminput
1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf  /data/adb/modules/gpm_dex/gpminput
```

### 2.10 `c` 逻辑坐标（多显示） — PASS

用 `P` 把光标放到逻辑目标点并点击，padtest 报告的应用逻辑坐标作为真值，对比 `c`：

| P 目标 | padtest 点击真值 | `c` 回包 |
|--------|------------------|----------|
| 1280,800 | 1278,796 | `CURSOR 1278 797 display=0 space=logical frame=435,1446 raw=453.8,1157.1` |
| 40,800 | 39,796 | `CURSOR 39 797 display=0 … raw=453.8,457.0` |
| 1280,1590 | 1278,1587 | `CURSOR 1278 1587 display=0 … raw=7.3,1157.1` |
| 2540,10 | （未记到 click）| `CURSOR 2541 7 display=0 … raw=900.3,1870.0` |
| 20,1590 | （未记到 click）| `CURSOR 16 1587 display=0 … raw=7.3,444.2` |

误差 1–3px（1px 取整 + 缩放），全部落在 display 0，不再出现 904×2316/HDMI 空间串台。
原始输出：`helper-v166-cursor-logical.txt`；标定脚本：`work/scripts/probe_v166_helper_calib.sh`。
改完后重跑 smoke：`OUT lines=111、ERR count=0`（`helper-v166-smoke-after-cursor.txt`）。

### 2.11 自检 CAP 语义（t10） — PASS

真机 `?` 自检（空闲、无手势在飞）原始输出（`helper-v166-selftest-capability.txt`）：

```
SELFTEST begin
CAP mouse 1
CAP kbd 1
CAP wheel 1
CAP swipe 1
CAP notif 1
CAP power 1
CAP force 1
INFO apex 1
CAP screen 1
CAP wake 1
CAP cursor 1
CAP devices 1
CAP gesture 1          ← 修复前是 0（busy 语义），设置页显示「缺失：gesture」
INFO gesture busy=0 queued=0
INFO devices_grabbed=1
SELFTEST end
```
- `CAP zero count=0`、`begin/end=1/1`、`ERR count=0`；
- 应用设置页截图：`work/ui_config_after_t10.png`（`链路自检` 一行为 **「全部通过（12 项）」**，无「缺失：gesture」）；
  修复前对照：`work/ui_config_land.png`（同一页面显示「缺失：gesture」）。
- K 组快速复验（`?` + u/c/g/P）：
  ```
  POSPTR 1280,800
  CURSORQ pid=20757
  CURSOR 1278 797 display=0 space=logical frame=435,1446 raw=453.8,1157.1 took=50us
  GAIN center=0.000 ptr=3.250 effective=3.250
  GAIN center=0.000 ptr=4.680 effective=4.680
  CURSOR 1278 797 display=0 space=logical … took=58us
  WAKE was=Awake now=pending uinput=0 req=1 probe=1
  WAKE was=Awake now=Awake uinput=0 skip=1 probe=1
  ```
- 改后全命令 smoke：`OUT lines=93、ERR count=0`、`p`→Dozing、`u`→Awake（`helper-v166-smoke-t10.txt`）。

### 2.12 CAP mouse/wheel 能力语义（t11，空闲隐藏不误报） — PASS

同一份 `?` 在“指针可见 / 空闲隐藏”两种状态下 CAP 完全一致，差异只在 INFO：

```
[visible]      CAP mouse 1 CAP wheel 1 … CAP gamepad 1 CAP devices 1 CAP gesture 1
               INFO pointer device=on      CAP zero count=0
[h = 销毁鼠标]  CAP mouse 1 CAP wheel 1 … CAP gamepad 1 CAP devices 1 CAP gesture 1
               INFO pointer device=off     CAP zero count=0   ← 修复前 mouse/wheel 会是 0
[visible-again] CAP 同 hidden；INFO pointer device=on        CAP zero count=0
selftest begin/end=1/1  ERR=0
```

应用侧（引擎真实连接、设备指针被 HCMD `h` 销毁并等 9s > idle_hide 8s 后触发 `?`）：
- helper.log：13 项 CAP 全 1，`INFO pointer device=off`，`hidden CAP zero count=0`；
- `logcat DexPadLink: selftest … mouse=1 wheel=1 gamepad=1 …`（App 解析到的 caps 全 1）；
- 设置页截图 `work/docs/evidence-v166/ui_config_hidden_t11.png`：**「链路自检 全部通过（13 项）」**（指针隐藏状态下截图；修复前是「缺失：mouse，wheel」）；
- 改后全命令 smoke：`OUT lines=96、ERR count=0`（`helper-v166-smoke-t11.txt`），`p`→Dozing、`u`→Awake，DPAD_CENTER/SELECT/WHEEL 未变。

原始日志：`helper-v166-cap-visible-hidden.txt`、`helper-v166-capscreen-idle-hidden.txt`；脚本：`work/scripts/probe_v166_helper_cmds.sh capidle`、`work/scripts/probe_v166_helper_capscreen.sh`。

## 3. 复现命令

```sh
# 构建
wsl -d Ubuntu-24.04 -e bash -c "cd '/mnt/e/Dennis/GamePadDex复刻'; python3 work/scripts/fix_crlf.py"
wsl -d Ubuntu-24.04 -e bash -c "cd '/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets'; aarch64-linux-gnu-gcc -O2 -static -o gpminput gpminput.c display.c -lm"

# 装机（草稿状态，测试后恢复）
adb -s 192.168.10.36:6666 push project/app/src/main/assets/gpminput /data/local/tmp/gpminput_v166
adb -s 192.168.10.36:6666 shell su -c 'cp -f /data/local/tmp/gpminput_v166 /data/adb/gpm/gpminput; cp -f /data/local/tmp/gpminput_v166 /data/adb/modules/gpm_dex/gpminput; chmod 755 /data/adb/gpm/gpminput'

# 助手单测（会临时停 watchdog/引擎，结束后自动恢复）
adb -s 192.168.10.36:6666 push work/scripts/probe_v166_helper_cmds.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell su -c 'sh /data/local/tmp/probe_v166_helper_cmds.sh all'
#   smoke | crosstalk | wake | openapp | poison | gain | regress | prep | all

# 应用侧（需要 vgpad + EngineService + PadProbe）
adb -s 192.168.10.36:6666 push work/scripts/probe_v166_helper_appaxis.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell su -c 'sh /data/local/tmp/probe_v166_helper_appaxis.sh'
```

## 4. 已知边界 / 同步阻塞 / 资源口径

### 4.1 已知边界（留给应用侧）

0. **dumpsys 单次耗时（`c` 闭环频率参考，真机测量）**：`dumpsys input` 25/25/60ms（中位≈25ms）、`dumpsys SurfaceFlinger` 89/92/89ms、`dumpsys power` 92/102/83ms（原始：`helper-v166-dumpsys-latency.txt`）。`c` 只跑 `dumpsys input`（r2 起不再退 SurfaceFlinger），典型回包 30–70ms；`W` 才走 SurfaceFlinger（≈90–100ms）。建议 `O` 之后只发 1 次 `c`、200ms 内不要连发。

1. 助手只能保证**注入层**不并发、不同轴；同 tick 的轴向仲裁仍应在 App 侧做（`vSwipeArmed/hSwipeArmed` 目前仍是死变量，见 DIAG §7）。助手会丢弃被仲裁掉的另一轴并留 `SWIPE_DROP` 证据。
2. `RB 按住 + 右摇杆` 会出现同一轴的两次不同起手（`Z@800` + `Z@480`）——同轴串行、互不吞并，但“一次推杆只发一次”仍需 App 侧 armed 语义。
3. `R`（重新打开设备）仍是同步 150ms 操作（不含 popen/input）；`ensure_mouse()` 在鼠标被闲置销毁后重建有 120ms 固定等待，属于设备创建必需。
4. `g` 的 `ptr` 需要按 `pointer_speed` 重标（DIAG §4：0→3.60 / 3→4.68 / 7→7.21）。
5. **验证口径（t13 记录，供 VERIFY/集成沿用）**：L3 居中按 **DIAG 的 ≤8px** 判定（t4 实测 9/9、最大 5px，已满足；旧文里的 ≤80px 是更宽的旧阈值，不作为通过依据）；prep 必须同时断言 **max<5000us**（实测 max 661us、t2 采样 max 391us）；B2/B3 是**最小位移检查**（半推 498px>0、0.24 推 39px>0，旧版 0.24=0）；I3（X+LB）是**方向性检查**（`dx=+359` 向右），不是精确位移阈值。VERIFY-v166.md 的同类收紧按 captain 分工由 t12/t7（R3）落地，本任务不改该文件。

### 4.3 同步阻塞清单（含 `C`，t13/R2）

命令主循环里仍可能阻塞的路径（除 `C` 外都已 fork 或只做 syscall）：

| 命令 | 最坏阻塞 | 说明 |
|------|----------|------|
| `C` 组合键 | **已消除（fork 子进程）** | t13/R2 起 `case 'C'` 在子进程执行 `cmd_key_combo`（L2702–2736）；修复前最坏 8×8+30+8×8≈158ms |
| `R` 重开设备 | ≈150ms | `usleep(150ms)` + 重新 open/grab 所有设备（不含 popen/input，改动会破坏设备 fd 语义） |
| `h`/`j` 指针隐藏/重建 | `j` ≈120ms | 仅设备创建/销毁；`h` 只有 ioctl+close |
| 键释放延时队列 | 0（非阻塞） | `key_release_later`（L308）登记到期时间，主循环 `poll` 超时按到期补发 |
| 其它重命令 | 0 | `W/J/F/X/E/t/f/L/r/?/O/P/Y/T/w/c/u` 全部 fork；`V/Z/N` 只入串行手势队列（fork+execv） |

### 4.4 60s 进程级 CPU（t13 复测，release helper vs v1.65）

口径：`/proc/<pid>/stat` 的 **utime+stime**（进程自身 CPU，用户态+内核态）；
**cutime+cstime** 是「已被本进程 `waitpid` 回收的子进程」累计 CPU（本助手会 fork `dumpsys`/`input`
子进程，它们计入 cutime/cstime），单独列出、不混入进程自身口径。条件：引擎已连接、无输入、
屏幕常亮、同一 60s 窗口、同一台设备；两版本同一方法。helper 是单个 `-O2 -static` 二进制，
release APK 的 `assets/gpminput` 与本机编译产物逐字节相同（无 debug/release 变体）。

| 版本 | utime+stime | 进程自身 CPU | cutime+cstime | 子进程 CPU |
|------|-------------|--------------|----------------|-------------|
| v1.66 helper（`1bf7306f…`） | 23 ticks | **0.38%** | 81 ticks | 1.35% |
| v1.65 helper（`18268d…`） | 21 ticks | **0.35%** | 139 ticks | 2.32% |

结论（仅限 helper 进程级）：v1.66 进程自身 0.38% vs v1.65 0.35%（同量级，差 0.03%≈1 tick/60s），
子进程累计 1.35% vs 2.32%（v1.66 更低）。**注意**：应用侧（engine）的 release-build CPU 对比
不在本任务范围（t7 负责）；H3 的线程级数字只能作为辅助指标、且不含短命 JIT 线程，
未复测前发布说明不得据此写“CPU 不回退/提速”结论。原始输出：`helper-v166-cpu-60s.txt`。

## 5. 设备恢复状态（测试结束）

- 助手：`/data/adb/gpm/gpminput` + 模块副本 = `1bf7306f…`，进程运行中（`pidof gpminput` 有值，已 GRABBED）；
- 引擎：`com.dennis.dexpad` EngineService 运行中，socket `/data/data/com.dennis.dexpad/files/gpm.sock` 存在；
- 设置页已复验：`链路自检 = 全部通过（13 项）`，且是在**指针空闲隐藏（INFO pointer device=off）**状态下截图（`ui_config_hidden_t11.png`）；
- 屏幕 Awake、`user_rotation=1`（横屏 2560×1600）、`display_size_forced=1600,2560`（基线覆盖未改）；
- 无 vgpad 残留；padtest/PiliPlus/抖音已退出；prefs 未改（`hswipe_speed=3 / mode_on=true / enabled=true`）；
- 缓存：`taskbounds-0.txt` 已恢复为真实值，legacy `taskbounds.txt` = `0 0 2560 1600`。

## 6. 证据文件清单

| 文件 | 内容 |
|------|------|
| `helper-v166-final-all.txt` | crosstalk / poison / wake / regress / openapp 原始输出（最终产物） |
| `helper-v166-smoke.txt` | 全命令 smoke（ERR=0） |
| `helper-v166-prep.txt` | prep 10 次采样 |
| `helper-v166-gain.txt` | 增益查询/设置 + O 生效 |
| `helper-v166-appaxis.txt` | 应用侧：单区域、TOUCH/swipe 完整性 |
| `helper-v166-app-crosstalk-diag.txt` | DIAG 原 crosstalk 脚本复跑（新助手） |
| `helper-v166-popen-audit-r2.txt` | **t13/R4 在最终源码（3219 行）上重生成的** popen/system 审计 + 行号 |
| `helper-v166-cursor-logical.txt` | `c` 多显示逻辑坐标（P/padtest 真值对照） |
| `helper-v166-smoke-after-cursor.txt` | r2 改后 smoke |
| `helper-v166-selftest-capability.txt` | t10 `?` 自检 CAP 语义 + K 组（u/c/g/P） |
| `helper-v166-smoke-t10.txt` | t10 改后全命令 smoke（ERR=0） |
| `ui_config_after_t10.png` | 设置页「链路自检 全部通过（12 项）」截图（无「缺失：gesture」） |
| `helper-v166-cap-visible-hidden.txt` | t11：指针可见/隐藏/再可见三种状态的 CAP 对照 |
| `helper-v166-capscreen-idle-hidden.txt` | t11：真实引擎 + 隐藏 9s 后 `?` 的 CAP/INFO 原始输出 |
| `ui_config_hidden_t11.png` | t11：**指针隐藏状态**下设置页「全部通过（13 项）」截图 |
| `helper-v166-poison-t13.txt` | t13/R5：投毒后 2.0/2.3/2.5s 三次取样（起手点 + task 范围） |
| `helper-v166-cpu-60s.txt` | t13：60s 进程级 CPU（utime+stime / cutime+cstime）new vs v1.65 |
| `helper-v166-smoke-t13.txt` | t13 改后全命令 smoke（ERR=0） |

### 版本演进

- t2 完成版：`dc41cb9b…`（851960 B），验收全部通过（§2.1–2.9）；
- t3 反馈阻塞点（`c` 多显示坐标歧义）修复版：`4f261754…`（851880 B），新增 §1.5/§2.10 修正与证据；其余协议/行为不变，改后 smoke `ERR=0`；
- t10 自检 CAP 语义修复版：`139087e7…`（851880 B），新增 §1.6/§2.11：`CAP gesture` 改为能力语义、busy/queued 移入 `INFO`，其余 CAP 口径写入 §1.6；仅自检上报变化，控制路径未改，改后 smoke `ERR=0`；
- t11 CAP mouse/wheel 语义修复版：`6076b63b…`（851880 B），新增 §2.12：`CAP mouse`/`CAP kbd`/`CAP wheel` = uinput 节点可写（能力），`CAP gamepad` 新增为能力项，指针/键盘当前开关移到 `INFO pointer|kbd device=on|off`；控制路径零改动，改后 smoke `ERR=0`；
- **t13 修复版（最终产物 / 发布哈希）：`1bf7306f…`（851928 B）**：R5 周期刷新 force 绕过 mtime 节流（投毒阈值改为 ≤2.5s，2.0/2.3/2.5s 三点复测通过，§2.3）；R2 `case 'C'` 组合键改子进程执行（§2.6/§4.3，主循环不再有 158ms 阻塞）；R4 在最终源码上重生成 popen/system 审计与行号（§2.6/§4、evidence `helper-v166-popen-audit-r2.txt`）；改后 smoke `ERR=0`、60s 进程级 CPU 复测见 §4.4。



