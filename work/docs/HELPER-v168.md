# HELPER-v168 · gpminput 连续拖拽原语（t30）

> 产物：`project/app/src/main/assets/gpminput`
> sha256 **`a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d`**（852328 B）
> 设备 `/data/adb/gpm/gpminput` 与 `/data/adb/modules/gpm_dex/gpminput` 同一哈希。
> 基线：v1.66 最终版（`1bf7306f…`）的协议与行为全部保留；本版只**新增**连续拖拽原语并修正触摸面板坐标映射。

## 1. 背景

LB/RB 原来是“每次一条 560px 的 `input swipe`”（fling 式），无法跟手，用户反馈“一次跳太远 + 一顿一顿”。
新原语让应用可以“按住 = 手指按住持续移动”：

```
d <display> <x> <y>            # 手指按下（MT 单指，逻辑像素）
m <display> <dx> <dy> <ms>     # 在 ms 内分步移动 dx/dy（不是一次跳）
e [display]                    # 手指抬起（任何时刻都能结束）
```

命令字母 `d` / `m` / `e` 在现有协议里均未占用（原协议：`M B S H V Z O T Y K G U f p r I L D C t h j A N P R Q w q k l g u c ? W J F X E`）。

## 2. 分步语义（关键）

- `m` 只做**算术**并登记目标（`steps = clamp(ms/10, 1, 400)`，`step_ms = clamp(ms/steps, 8, 16)`），
  命令回包**不做任何 sleep / fork / IO**；
- 真正的 `EV_ABS + SYN` 由**主循环的非阻塞状态机** `drag_tick()` 在每轮 poll 前/后发一帧：
  主循环 timeout 被 `next_drag` 夹到最近一步的到期时间（≈10ms），所以命令循环不会被拖拽卡住；
- 一帧 = `ABS_MT_SLOT` + `ABS_MT_POSITION_X/Y` + `SYN_REPORT`（移动帧不带 TRACKING_ID，和真实触摸一致）；
- 位置按整数步进、余数留到下一步，**单调**推进；末步补齐全部余量；
- `m` 可以连续调用：剩余位移/步数累加，多段之间不会“跳”回起点（应用侧可以每帧发一小段）。

## 3. 安全

| 场景 | 行为 |
|------|------|
| 任意时刻 `e` | 立刻发 TRACKING_ID -1 + `BTN_TOUCH 0` + SYN，状态清零，回包 `DRAG up … why=cmd-e` |
| ≥1.5s 没有 `m` | 主循环自动抬起，回包 `DRAG up … why=auto-up idle`（掉线保护） |
| 没有 `d` 就 `m` | 回包 `ERR drag move (no down)`，**不会**创建触点 |
| `d` 参数错误 | 回包 `ERR d args`，不创建触点 |
| 越界坐标 | 夹到 task 矩形内（`rect=x1+20..x2-20 / y1+20..y2-20`），回包 `DRAG down … rect=…` |
| 拖拽中收到 `k`（单击）或 `l`（双指） | 先安全抬起再执行，回包 `DRAG up … why=touch-single/pinch-start` |
| 会话结束 / 进程退出 | `DRAG up … why=session end`，绝不留下按住的触点 |

## 4. 触摸面板坐标映射（本版修正）

真机标定（padtest ScrollTestActivity 的 `click-down` 坐标，`q 2560 1600` 时）：

```
逻辑 (400,300)   -> 应用收到 (479,1532)
逻辑 (2000,1400) -> 应用收到 (2239,200)
逻辑 (1280,800)  -> 应用收到 (1279,800)
```

拟合出本机 DeX 横屏（display0 逻辑 2560×1600，面板被系统按 90° 映射）：

```
应用 x = 1.6 * panel_y
应用 y = 1865 - 0.8325 * panel_x
反解：panel_y = 0.625 * x_logical ；panel_x = (1865 - y_logical) / 0.8325
```

`touch_frame()` 与拖拽的 `touch_move_frame()` 都经过 `touch_panel_xy()` 再转 0..32767。
因此应用侧看到的坐标/位移与请求一致（见 §5-A/B），面板的 `ABS_MT_POSITION_Y` 承载逻辑 X、
`ABS_MT_POSITION_X` 承载逻辑 Y（90° 旋转的必然结果）。
非 2560×1600 的逻辑尺寸没有标定数据，退化为恒等映射（保持旧行为，不会崩）。

## 5. 真机证据

环境：SM-F9360，DeX 横屏 2560×1600，user_rotation=1，padtest `com.dennis.padtest/.ui.ScrollTestActivity`
（`topResumedActivity` 已确认），stdio 助手 + `q 2560 1600`。

### A) 分步：一次 `m 1000 0 500`（1000px/500ms）

```
DRAG down display=0 x=900,y=800 rect=20..2540/20..1580
DRAG move display=0 dx=1000 dy=0 ms=500 steps=50 step_ms=10 pending=1000,0
DRAG up display=0 x=1900,y=800 frames=50 emitted=50 dur=1544ms why=cmd-e
padtest: MOUSE/click-down x=899 y=800
padtest: MOUSE/drag x=1899 y=800 dx=1000 dy=0 dist=1000
padtest: TOUCH/swipe dx=1000 dy=0 dist=1000
getevent: ABS_MT_POSITION_Y = 50 个事件
          gap min=9.21ms max=10.46ms mean=10.11ms，越界(8~20ms)=0，单调递增
```

→ **≥20 个 EV_ABS 分步、间隔 9.2–10.5ms、单调**；应用侧位移 1000px vs 请求 1000px（误差 **0%**）。

### B) 多段：`down → 3×move（共 +1000px）→ up`

```
DRAG move dx=400 ms=200 steps=20 / dx=350 ms=180 steps=18 / dx=250 ms=150 steps=15
DRAG up x=1900,y=800 frames=53 emitted=53
padtest: MOUSE/drag dx=1000 dy=0 dist=1000
getevent: 53 个 ABS_MT_POSITION_Y
```

垂直方向同样验证：`down 1280,1200 → 3×move 共 -1000 → up`，padtest `dy=-1000`（误差 **0%**）。

### C) 安全

```
ERR drag move (no down)                    ← 没有 down 的 move
ERR d args                                 ← d 参数错误
DRAG down display=0 x=20,y=1580 rect=20..2540/20..1580   ← (-500,99999) 夹到 task 内
DRAG up display=0 x=20,y=1580 frames=0 emitted=0 dur=410ms why=cmd-e
```

### D) 掉线保护

```
DRAG down 1280,900 → DRAG move dy=-100 ms=120 → （1.8s 不再发）
DRAG up x=1280,y=800 frames=12 emitted=12 dur=1811ms why=auto-up idle
之后 k 单击：TOUCH down 1000,900 / TOUCH up（触点没有卡住）
```

### E) 不阻塞与自检

```
? 自检：CAP 13 行 + INFO 5 行，ERR=0
move 回包：脚本 5ms 轮询，5/5 次都在**第一个轮询**就见到 DRAG move 行（iter=0）；
           端到端 13–16ms 是脚本 date/grep 开销，不是助手处理时间
全命令 smoke：OUT lines=95、ERR count=0（WHEEL/SELECT/DPAD_CENTER/wake/open_app 均正常）
串行队列：Z 手势正常注入（queued=0，单条在飞），控制路径未改
```

## 6. 已知边界

1. 坐标映射是**本机标定**（2560×1600 DeX 横屏）；换分辨率/竖屏需要重新标定（当前退化为恒等映射）。
2. 触摸面板改为**启动时创建**（`make_touchscreen()`），避免“第一次 down 时设备尚未被 InputReader 注册、首帧丢失”；
   代价是多一个常驻虚拟触摸设备（无触摸时不产生事件）。
3. `d/m/e` 走 MT 触摸通道，不经过 `input swipe`，因此与串行手势队列（`SWIPE`/`SWIPE_DROP`）互不干扰；
   两者同时使用时由应用侧决定优先级。
4. 拖拽期间不做压力/大小变化（只发位置），对需要按压力度的场景不适用。

## 7. 复现

```
adb push work/scripts/probe_v166_helper_drag.sh /data/local/tmp/
adb push work/scripts/probe_v168_dragstep.sh /data/local/tmp/
adb push work/scripts/probe_v168_final.sh /data/local/tmp/
adb shell su -c 'sh /data/local/tmp/probe_v166_helper_drag.sh'    # A/B/C/D
adb shell su -c 'sh /data/local/tmp/probe_v168_dragstep.sh'       # 单段 1000px/500ms + getevent
adb shell su -c 'sh /data/local/tmp/probe_v168_final.sh'          # ? 自检 + 回包时延 + 队列
```

证据目录：`work/docs/evidence-v168/`。
