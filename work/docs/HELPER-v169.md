# HELPER-v169 · P 绝对定位闭环（t47）+ root 诊断控制通道（t48）

> 产物：`project/app/src/main/assets/gpminput`
> sha256 **`b806f39ba51278a73aad121be4019820b7961dcb0935971b64d3a02373cd2a4d`**（852960 B，含 t48 控制通道 + t54 detached drag）
> 设备 `/data/adb/gpm/gpminput` 与 `/data/adb/modules/gpm_dex/gpminput` 同哈希。
> 基线：v1.68 发布字节 `a1d06e2e…`（852328 B）；本版只改 `pointer_goto()`/锚点，不动协议语义。

## 1. 缺陷（有修复前证据）

`P <x> <y> <maxX> <maxY>` 号称“把光标放到绝对坐标”，但 v1.68 实现是**开环**的：

```c
double gain = effective_gain();          /* 默认 3.25 */
cmd_mouse_move((double)tx / gain, ...);  /* 一步 REL，不再校验 */
```

本机 `pointer_speed=-1` 的实际 REL→px 增益约 **2.14**（引擎 perf 日志 `gain=2.154`），
于是落点 = 目标 × 2.14/3.25 ≈ **0.66 × 目标**（偏小 34%）。v1.68 字节实测：

| 请求 | 期望 | 实际（`c` 回读） | 误差 |
|------|------|------------------|------|
| P 400 1200 | 400,1200 | 264,796 | -136,-404（-34%） |
| P 2000 300 | 2000,300 | 1329,197 | -671,-103（-33%） |

影响面：L3 居中（应用侧另有闭环补偿，但 helper 自身偏差 34%）、**空闲隐藏后的原地恢复**、
以及所有以 P 落点为锚点的 SWIPE/drag 起手。

## 2. 改法（`pointer_goto()`，v1.69）

1. **闭环**：`pointer_read()` 用 `cursor_logical()`（`dumpsys input`，子进程、约 25ms）
   读真实逻辑光标；
2. **实测增益**：先朝屏幕内部方向 REL 80px（贴边时不向外走，避免被夹住测出假增益），
   用实际位移算 `gain = Δpx / REL`；
3. **最多 4 次修正**：`err = target - current`，注入 `err/gain`，每次用本步实际位移
   **重新更新增益**（贴边被夹也能自适应），误差 ≤8px 提前退出；
4. **写回悬停锚点**：`g_ptr_x/g_ptr_y` 改为 `mmap(MAP_SHARED)` 页（`main()` 初始化），
   fork 出的 P 子进程落点对父进程可见，`cmd_swipe()` 起手点直接用它；
5. **日志**：每次都输出 `POSPTR <x>,<y> closed gain=<gx>,<gy> final=<nx>,<ny> err=<ex>,<ey> iters=<n> anchor=<ax>,<ay>`，
   并保留旧格式 `POSPTR <x>,<y>` 一行（应用侧解析不变）。

读取不到光标时（无 MOUSE hover）仍保留有界左上角 + 开环兜底，并输出 `POSPTR … openloop`。

## 3. 真机证据（v1.69 字节）

### 3.1 P 五点（误差 ≤8px）

```
req=400,1200   => CURSOR 402 1202   (err 2,2)
req=2000,300   => CURSOR 1997 300   (err -3,0)
req=100,100    => CURSOR 102 102    (err 2,2)
req=2450,1500  => CURSOR 2447 1498  (err -3,-2)
req=1280,800   => CURSOR 1282 802   (err 2,2)
```

### 3.2 悬停锚点（P 落点 → SWIPE 起手）

```
P 1280 1000 2560 1600
SWIPE 0 1280,999 -> 1480,999 (task 0..2560 / 0..1600) axis=V
```

起手点 = P 目标 ±1px（修复前 g_ptr 只有在显式 cursor 参数时才更新，P 的落点对父进程不可见）。

### 3.3 L3 居中（pointer_speed 0/3/7 各 3 次）

```
ps=0: 1280,802 / 1280,799 / 1280,802
ps=3: 1280,799 / 1280,802 / 1280,799
ps=7: 1280,803 / 1280,799 / 1280,803
```

全部 ≤3px（目标 1280,800）。

### 3.4 隐藏 → 重建 → 原地恢复

```
before hide: CURSOR 901 602
h（销毁鼠标） -> j（重建） -> P 900 600
after restore: CURSOR 908 603（err 8,3）
```

（应用侧 idle-hide 恢复链路仍按原逻辑；helper 侧 P 闭环保证重建后能回到目标 ≤8px。）

### 3.5 回归

| 项 | 结果 |
|----|------|
| 连续拖拽 | 3 段共 +1000px / -1000px，padtest `dx=±1000`、`dy=±1000`；`auto-up idle` 正常（t47-drag.txt） |
| 串行队列 | same-tick Z+V：`starts=1 dones=1 overlaps=0 drops=1`；同轴排队 `starts=2 dones=2 queued=1`（t47-crosstalk.txt） |
| DPAD_CENTER / SELECT / WHEEL | `KEYUIN 0 23 lcode=28`、`NOTIF swipe rc=0`、`WHEEL ±3/±2` 方向不变；`H 9` → `WHEEL 9 h=1`（t47-regress.txt、t47-cap-wheel.txt） |
| 全命令 smoke | `OUT lines=98`、`ERR count=0`，`p`→Dozing、`u`→Awake（t47-smoke.txt） |
| `?` 自检 | 13 项 CAP 全 1、ERR=0（t47-cap-wheel.txt） |

## 4. 协议/兼容性

- 命令与语义不变；P 的回包增加 `closed …` 明细行，旧的 `POSPTR <x>,<y>` 行保留（应用解析 `p[1].split(',')` 不受影响）。
- 新增内部函数 `pointer_read()`；`g_ptr_x/g_ptr_y` 从普通静态变量改为 mmap 共享页（仅进程内共享，不落盘）。
- 未改串行手势队列、drag、90° 映射、边界缓存、`c/u/g/open_app`。

## 5. 复现/证据

```
adb shell su -c 'sh /data/local/tmp/probe_t47_ptr.sh'   # P 五点/O 三档/隐藏恢复/锚点
adb shell su -c 'sh /data/local/tmp/probe_v166_helper_cmds.sh smoke|crosstalk|regress'
adb shell su -c 'sh /data/local/tmp/probe_v166_helper_drag.sh'
adb shell su -c 'sh /data/local/tmp/probe_t47_cap.sh'   # ? + H 9
```

证据目录：`work/docs/evidence-v169/t47-*.txt`。

## 6. root 诊断控制通道（t48）

为 release 字节上的坐标级自动化（MIX 组）新增第二条命令通道，与 App 的 `gpm.sock` 并存：

- 路径 `/data/adb/gpm/gpmctl.sock`，目录 `/data/adb/gpm` **0700**，socket **0600**，owner root；
- 仅 root：socket 权限 + `SO_PEERCRED` 校验 `uid==0` 双重；非 root `connect` 直接 `Permission denied`；
- 命令**复用同一个 `handle_line`**，与 App 通道语义完全一致（P/c/H/h/j/M/B/S/Z/V/d/m/e/p/u/g/? …）；
- 在父进程内处理（不 fork）：鼠标/拖拽/手势/锚点状态与 App 通道共享；输出用 `g_out_fd` 临时切到控制连接；控制连接断开不影响 App 通道，也不改变 flock 单实例语义；
- 一次性客户端（sockcmd 这类发完就等 EOF 的）处理完本批命令后关闭连接，客户端可拿到回包；
- 禁用：`touch /data/adb/gpm/gpmctl.disabled` 后重启助手即不创建 socket；删除后重启恢复（已真机验证）。

真机验证（release 字节 + 引擎运行中）：

```
$ /data/local/tmp/gpmctl /data/adb/gpm/gpmctl.sock j
MOUSE_REOPEN (auto)
POINTER on
$ /data/local/tmp/gpmctl /data/adb/gpm/gpmctl.sock P 1280 1000 2560 1600
POSPTR 1280,1000 closed gain=2.16,2.16 final=1282,1001 err=-2,-1 iters=2 anchor=1282,1001
$ /data/local/tmp/gpmctl /data/adb/gpm/gpmctl.sock c
CURSOR 1282 1001 display=0 space=logical frame=0,2176 raw=735.3,1089.6
```

- 非 root：`su 1000 -c 'gpmctl ... ?'` → `connect: Permission denied`；
- 禁用开关：`gpmctl.disabled` 存在时 `ls: /data/adb/gpm/gpmctl.sock: No such file`；删除后 socket 恢复 `srw------- root root`；
- `sockcmd` 连接成功且命令确实执行（helper.log 有 `CTL connected uid=0` / `POSPTR … 1282,1001`），但其 stdout 捕获在本机为空，建议用 `/data/local/tmp/gpmctl`（源码 `work/scripts/gpmctl.c`，静态 aarch64）作为控制通道客户端。

回归：全命令 smoke `OUT lines=97`、`ERR=0`；`?` CAP 13 项全 1；`H 9` → `WHEEL 9`；串行队列/drag/唤醒/open_app 代码未改。
## 7. detached drag（t54，最小改动）

t48 的控制通道（`?`/P/c/H）已验证稳定；t51 试图重构 accept/read 导致通道失效，已回退。t54 只改“状态放哪 + 谁发帧”：

- 拖拽状态放进**现有 mmap 共享页**（`struct gpm_drag_sh`，跟在 `g_ptr_x/g_ptr_y` 之后）：`active/disp/ox/oy/dx/dy/ms/release/stamp`；
- `d`/`m`/`e` **只更新共享状态**（`d` 置按下点、`m` 累加位移、`e` 置 release），不直接发帧；
- 父进程主循环每轮先 `shared_drag_poll()`（按 20px 分块把 m 的位移交给 `drag_move`），再由 `drag_tick()` 发帧；共享拖拽活跃时主循环超时压到 8ms；
- 外层循环（App 未连接）同样驱动 → detached drag 与控制连接是否打开无关；
- `e`：先把剩余帧发完（有界 drain）再 `drag_release`；1.5s 无 `m` 仍由 `drag_tick` auto-up。

真机（release 字节 b806f39b）：
```
d 0 1280 1000   (连接 1)
m 0 0 -400 300  (连接 2)
e 0             (连接 3)
→ DRAG down display=0 x=1280,y=1000
→ DRAG up display=0 x=1280,y=600 frames=20 emitted=20 dur=1320ms why=cmd-e
```
- 控制通道连续 10 次命令：**0 失败、helper pid 不变、无 SIGPIPE**；
- 回归：smoke `OUT lines=116`/`ERR=0`；`?` CAP 13 项全 1/ERR=0；`H 9` → `WHEEL 9`；串行队列/drag 手感代码未改；
- 遗留：padtest 内层 offset ≥300px **未能用现有 harness 证明**——PadProbe 在本轮环境里 `touch.frames=0`（用旧的 t30 drag 探针同样为空），拖拽事件是否落到 padtest 列表需要 harness 侧（t46/t52）加仪表；helper 侧 `DRAG up frames=20 emitted=20` 已达标。

哈希 `b806f39ba51278a73aad121be4019820b7961dcb0935971b64d3a02373cd2a4d`（852960 B），本地 assets / /data/adb/gpm / 模块目录一致。
## 8. t59 复核：P(700,1000) 与触摸面板 Y 映射（无可复现缺陷）

**结论：当前发布字节 `b806f39b…` 上两条怀疑均未能复现，按“证伪”处理，代码未改（哈希不变）。**

### 8.1 P 700,1000 反证

```
$ gpmctl S P 700 1000 2560 1600
POSPTR 700,1000 closed gain=2.17,2.16 final=703,1001 err=-3,-1 iters=2 anchor=703,1001
$ gpmctl S c
CURSOR 703 1001 display=0 space=logical frame=0,2176 raw=735.3,597.2
```

六点扫描（含 700,1000 / 四角 / 中心 / 1280,802）全部 ≤3px、iters≤2：

| 请求 | 最终（日志） | c 回读 |
|------|--------------|--------|
| 700,1000 | 703,1001 | 703 1001 |
| 100,100 | 97,102 | 97 102 |
| 2450,1500 | 2449,1498 | 2449 1498 |
| 2000,300 | 2002,303 | 2002 303 |
| 1280,802 | 1282,800 | 1282 800 |
| 1280,800 | 1280,800 | 1280 800 |

另测：`h`（隐藏指针）后立即 `P 700 1000` 仍收敛到 703,1001（闭环内会重建鼠标并重读）。
t57 的 `171,171` 无法在当前字节复现；若后续再遇到，需同时记录 `POSPTR` 全字段与 `c` 原始回包（`c` 在指针隐藏时返回 `CURSOR -1 -1`，不要用该值判断落点）。

### 8.2 触摸面板 Y 映射

- **swipe 路径不用触摸面板**：`V/Z` 走 `/system/bin/input swipe`（逻辑坐标），日志 `SWIPE 0 1282,804 -> 1582,804` 证明起手 y=804（请求 802，锚点±2px）。
- 触摸面板映射只用于 `k`（点击）与 `d/m/e`（拖拽）。实测原始 ABS（`getevent /dev/input/event22`）与公式完全一致：
  - `k 200 200` → `ABS_MT_POSITION_X=25612`、`Y=2559`；公式 `px=(1865-200)*1000/832→25613`、`py=200*0.625→2560`；
  - `k 1280 802` → `ABS_MT_POSITION_X=16345`；公式 `px=(1865-802)*1000/832→16344`。
  → 90° 映射在 Y 方向**无偏移**。
- `y=802` 的 pager 触发未能复现：真实 `input swipe 1280 802 1582 802 120` 与 helper `V` 均未观察到分页变化（padtest dump 同时列出三页文本，PadProbe 本轮无 band 日志）→ 判为 padtest 测量口径问题，不是注入点偏移。

### 8.3 回归（b806f39b）

P 五点 ≤3px；L3 pointer_speed 0/3/7 各 3 次 1280,799–803；隐藏恢复 908,603；`SWIPE` 锚点 1280,999；串行队列 `starts=1 dones=1 overlaps=0 drops=1`、同轴 `starts=2 dones=2`；`H 9`→`WHEEL 9`；`?` CAP 13 项全 1/ERR=0；smoke `OUT lines=97`/`ERR=0`；`d/m/e` detached `frames=20 emitted=20`（t54 同一字节）。

哈希 `b806f39ba51278a73aad121be4019820b7961dcb0935971b64d3a02373cd2a4d`（852960 B）三处一致，未变更。
## 9. t61 复核：SCR-022 / d/m/e / 垂直滚轮 / MIX（测试通道限制）

**结论：控制通道侧可证项已证；应用端未接收属测试通道限制（原因未定，不作产品结论）。
发布字节保持 `b806f39b…`，不做任何改动。**

### 9.1 已证

- **翻页**：padtest pager 区 `H 8` → `横向 scrollX 0→512`（翻页机制本身可用）。
- **控制通道 `d/m/e`**：三条独立连接 → `DRAG up display=0 x=1280,y=600 frames=20 emitted=20 dur=1050ms`；
  helper pid 稳定、无 SIGPIPE。
- **垂直滚轮 `S 8`**：helper 日志 `WHEEL 8 h=0` 已发。

### 9.2 未证 / 限制

- **控制通道注入的触摸事件，应用端未接收**：padtest `后端统计：手势滑动 0 次 · 滚轮 0 次`、固定区 `touch=0`，
  拖拽后 offset/scrollX 不变；**原因未定，不作产品结论**。
  产品路径（引擎发 `d/m/e`）在 v1.68 发布字节上已验证（padtest PY 1415→0、PiliPlus 1623px），
  本轮**没有**“引擎路径也失效”的证据。
- **padtest 不提供可读 offset**（UI dump 中 offset 常为 0/不可读），MIX 组仍缺可量化读数。
- 试验记录：给 `drag_down` 补 `BTN_TOUCH 1` 未改变投递，已回退（哈希回到 `b806f39b`）。

### 9.3 状态

发布字节 `b806f39b…`（852960 B）三处一致，不做任何改动；t43/t45 按此绑定发布。
DeX/外接屏触摸路由如以后要做，单独开任务（属新功能/兼容性，不在本轮范围）。

## 10. t66 控制通道拖拽产品级化（协议 + 回包 + 故障码）

**根因（对比引擎路径与控制通道）**：控制通道的 `d` 只写共享状态、`drag_down` 被推迟到主循环；`m`/`e` 紧随其后到达时 `g_drag.active` 仍为 0（`ERR_STATE m no-down`），拖拽实际未按下 → 帧计数 0、应用端 `后端统计 手势滑动 0 次`。
**修复**：控制通道 `d` 立即 `drag_down`（不再等主循环），`m`/`e` 只做状态推进；主循环继续按 8ms 发帧。

### 10.1 协议与回包（控制通道 `gpmctl.sock`，仅 root）

```
d <disp> <x> <y>        → OK d <disp> <x> <y> | ERR_ARG d | ERR_STATE d busy（App 通道拖拽中）
m <disp> <dx> <dy> <ms> → OK m <dx> <dy> <ms> | ERR_ARG m | ERR_STATE m no-down
e [disp]                → OK e | ERR_STATE e no-drag
```
- 每条命令一行，响应一行；`OK` 开头为成功，`ERR_ARG` 为参数错误，`ERR_STATE` 为状态错误（未按下/忙）。
- 掉线/无 `m` 1.5s 自动抬起：`DRAG up … why=auto-up idle`；显式 `e`：`DRAG up … why=cmd-e`。
- 并发：App 通道拖拽进行中时，控制通道 `d` 返回 `ERR_STATE d busy`（不抢状态）。

### 10.2 真机（`eb0b5dfc…`）

```
d: DRAG down display=0 x=1280,y=1000 … OK d 0 1280 1000
m: OK m 0 -400 300
e: OK e
DRAG up display=0 x=1280,y=600 frames=20 emitted=20 dur=2113ms why=cmd-e
```
- helper pid 不变、无 SIGPIPE；padtest `后端统计：手势滑动 1 次（已应用到列表 开）`（修复前为 0 次，证明触摸投递恢复）。
- 对照：真实 `input swipe 1280 1000→500` → `纵向 offset 0→3 项`（测量口径可用）。
- 未完成：控制拖拽后的 `纵向 offset` 数值未能读到（拖拽后 offset 卡片离屏/`uiautomator dump` 失败、首项仍 #001），`offset ≥200px` 未证实。

回归：smoke `OUT lines=103`/`ERR=0`；`?` CAP 13 项全 1/ERR=0；`H 9`→`WHEEL 9`。
哈希 `eb0b5dfc6d5403b30d8200467f773e628729ea5290d1574aeb5651bf33c8c31c`（852976 B）三处一致。
## 11. t71 复核：滚轮“事件发出但系统零位移”

**结论：未能复现“系统层不接受虚拟滚轮”；设备配置与 v1.66 一致，且 App 端确实收到滚轮计数。内容位移因测量手段受限未证实（task failed），代码未改。**

### 11.1 事件链路

- `getevent -lt /dev/input/event19`：`EV_REL REL_WHEEL 00000008`（S 8）进内核 ✓。
- `dumpsys input`：`Gamepad Mouse Pointer` → `Classes: CURSOR`、`Sources: MOUSE`、`KeyBitmask (256:70000)`（BTN_LEFT/RIGHT/MIDDLE）、`AssociatedDisplayPort: <none>`。
- 与 v1.66（`638fe7a`）对比：`make_mouse()` **逐行相同**（同样的 REL_X/Y/WHEEL/HWHEEL、EV_KEY/EV_REL/EV_SYN、BUS_VIRTUAL、vendor 0x1234/product 0x5678、名称 "Gamepad Mouse Pointer"、无 INPUT_PROP 差异）→ **不是设备创建参数回归**。

### 11.2 新证据：App 端收到滚轮

padtest `后端统计`：`S 8` 后 `滚轮 0→2`，随后 `H 8` 后 `滚轮 4` —— 说明系统把 REL_WHEEL 投递成了应用的滚动事件，**“事件发出但系统不接收”不成立**。

### 11.3 内容位移测量受限

- `screencap -p -d 4630946474867211650`（2560×1600，display 0）前后 diff：`S 8` ≈0.003%，随后真实 `input swipe` 也只有 0.059% —— 说明该截图/前台状态不能反映内容滚动（Settings 未在前台或 dump 不可读），**无法据此判定“零位移”**。
- 结论：需要可读的滚动 offset 探针（专用探针 App 或 padtest 的 `纵向 offset` 在正确前台状态下复测）才能验收 ≥200px。

### 11.4 状态

- helper 代码未改；工作区 assets 为 `eb0b5dfc…`，**设备当前实际为 `b806f39b…`**（与 captain “保留 eb0b5dfc”不一致，需确认部署）。