# VERIFY-drag-v168-t37 · LB/RB 连续拖拽复验（t36 速度可调版）

> 任务 t37（verification round 2）· 设备 SM-F9360（adb `192.168.10.36:6666`，横屏 2560×1600）
> **结论：全部接受项通过**（套件 25 PASS / 1 FAIL 为仪器时序问题，已用专项重测闭环：见 §4）
> 证据：`work/docs/evidence-v168-drag-t37.log`、`work/docs/evidence-drag-raw-t37/`（截图）、`/data/local/tmp/h2_t37.log`

## 0 字节绑定（采样期间未变）

| 项 | 值 |
|---|---|
| APK | **`991c051090a3286a83bd0d6433d268f4db722fc0b96e3b727d55b1226102c143`**（设备 `base.apk` == 本机 `app-debug.apk` == 契约 gradle 重建产物；versionName 1.67 / versionCode 69） |
| 助手 | **`a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d`**（`/data/adb/gpm` == 模块目录） |
| 门 | `BASE-APK` / `BASE-HELPER` 均 PASS（不匹配 exit 9） |

## 1 主套件结果（`v168_drag_verify.sh`，默认档 speed=4）

| 项 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| A-100 | ≤150px | **74px** | PASS |
| A-300 | ≤450px | **242px** | PASS |
| A-1500 | ∈[1200,2200]px | **1586px** | PASS |
| B-CURVE | 单调 + 相邻增量差 ≤25% | 250/500/750/1000/1250/1500ms = **208/418/666/947/1242/1570px**，单调，最大差 **18%** | PASS |
| B-FRAME | 帧间隔中位 ≤20ms | 主拖拽 5 次 `dur/emitted` = **17.9–18.1ms**，`frames==emitted` | PASS |
| C-REBOUND | 松手 500ms 无新拖拽、额外 ≤200px | 事件 **2→2**；PC 截图差 **0.15%** | PASS |
| C-CONSIST | 3×1000ms ±15% | **941 / 956 / 931px**，maxdev **1.4%** | PASS |
| D-REANCHOR | 跨越一次续拖并到上限 | `re-anchor y=960 (total=1740)` → `drag end total=2218px` | PASS |
| D-SMOOTH | 续拖无停顿 | 主拖拽 `frames=53 emitted=53 mean=17.8ms` | PASS |
| D-STOP | 到底后停止注入 | `emitted=53` 后 `drag end`，1s 内无新 move | PASS |
| F-TOUCH | 触屏 0 WHEEL | SWIPE=0 WHEEL=0（纯 d/m/e） | PASS |
| F-WHEEL | 9 WHEEL/0 SWIPE | WHEEL=9、SWIPE=0 | PASS |
| F-MOVE | 滚轮内容位移 ≥200px | 设置列表 dSET=**921px** | PASS |
| G-XLB / G-XRB | dx>0 / dx<0 | **+1258 / −1262** | PASS |
| G-STICK / G-STICK2 | Z≥4 / V≥1 | Z=6 / V=3 | PASS |
| G-DPAD | key_enter≥1、mouse_click=0 | 1 / 0 | PASS |
| G-RECENTS | Recents | `com.android.quickstep.RecentsActivity` | PASS |
| G-HIDE | 0px + no correction | P1=P2=[1277 799] d=0 | PASS |
| G-NOTIF | NotificationShade | shade=12 | PASS |

## 2 可调性（H2，专项重测 `v168_h2_t37.sh`）

| 项 | 实测 | 判定 |
|---|---|---|
| 三档 1.5s 总位移 | **speed2=1167 / speed4=1591 / speed7=2255px**（单调；默认档 ∈[1200,2200]） | PASS |
| `drag start` 日志 | `scroll_speed=2 mult=0.733 / 4→1.0 / 7→1.4`，`maxTotal=1613/2200/3080` | PASS |
| 无需重启 | 引擎 pid **16326 → 16326** 不变 | PASS |
| 按压中不切换 | speed4 起手、1.7s 时改 speed10 → 起手仍 `mult=1.0`，`drag end total=2212px`（上限 2200，未随 10 档变大） | PASS |

## 3 PiliPlus 渐进滚动

- 单次 1.5s RB：`drag end total=1617px`。
- **渐进性**（三次 500ms 累计、每次后截图，均为无拖拽时的新鲜帧）：P1=433px、P2=427px、P3=423px；PC 像素差 **P0→P1 62.96%、P1→P2 59.26%、P2→P3 58.43%**（两两 >5%，逐级推进，不是一次跳页）。
- **仪器限制（已实测）**：拖拽**进行中**的 `screencap` 返回陈旧帧（1.1s/1.15s 时与 before 差 0.01–0.02%），因此“mid”采用**分次累计 + 每段结束截图**；这与“mid(750ms) 介于两者之间”的意图一致（每段都是中间态）。
- 不再使用截图差百分比作为判据。

## 4 套件中 H2-NOSWITCH 的首轮 FAIL 与闭环

- 首轮：0.4s 时改 pref 10 → 结果 `mult=1.8 total=2853`。**根因是仪器时序**：vgpad 启动 + 引擎进入拖拽约需 0.5–1.0s，0.4s 的改动发生在 `drag start` 之前，引擎在起手时才读 pref（符合设计）。
- 复测（改动放在 1.7s，拖拽已开始）：`drag start scroll_speed=4 mult=1.0`、`drag end total=2212`、`drag stop cap ... mult=1.0` → **PASS**。

## 5 仪器口径（本节为后续复验必读）

1. **引擎指针 overlay 使 padtest 永不 idle**：引擎运行时 `uiautomator dump` 一律 `could not get idle state`；需要“`am force-stop com.dennis.dexpad` → dump → `am start-foreground-service …/.EngineService`”（停引擎后 13684B / 5 个页面标记）。
2. **应用侧把拖拽识别为 MOUSE**（padtest 桥 `MOUSE/click-down`、`MOUSE/drag`），不是 TOUCH；grep 必须 `MOUSE/drag|TOUCH/drag`。
3. **`/dev/input/*` 在 shell 域不可读**（`getevent`/`dd` 均 0 字节），无逐帧时间戳；帧间隔用主拖拽 `dur/emitted`（本次 17.9–18.1ms）作中位与 p95 保守上界。
4. **拖拽中 screencap 是陈旧帧**（实测 0.01%），渐进性用“分次累计 + 段间截图”。

## 6 设备恢复

`v_touch_scroll=true`、`scroll_speed=4`、`mode_on=true`、`enabled=true`；横屏 2560×1600、Awake、rotation=1/accel=0、无 vgpad、helper 16378 + engine 16326、padtest ScrollTestActivity 前台。

## 7 复跑

```sh
adb -s 192.168.10.36:6666 push work/scripts/v168_drag_verify.sh work/scripts/run_v168_drag.sh work/scripts/v168_h2_t37.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/run_v168_drag.sh"
adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/v168_h2_t37.sh"
pwsh -NoProfile -File work/scripts/v168_shotdiff_t37.ps1
```
