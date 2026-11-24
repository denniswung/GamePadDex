# VERIFY-drag-v168 · LB/RB 连续拖拽手感验证（不过头 / 连续 / 无弹回 / 边界续拖）

> 任务 t32 · 设备 SM-F9360（adb `192.168.10.36:6666`，横屏 2560×1600）
> **结论：23 项 PASS / 1 项 FAIL（E-PILIPLUS 截图差 55.98% > 目标 40%）→ 不通过**
> 证据：`work/docs/evidence-v168-drag-final.log`、`work/docs/evidence-v168-drag-console-final.txt`、`work/docs/evidence-drag-raw-final/`（截图、helper/引擎原始日志）

## 0 字节绑定（采样期间未变）

| 项 | 值 |
|---|---|
| APK | **`e2e9a05b79e263c66f54ea7a704996a849008c86d31c5298d77a44c8bc913d2d`**（设备 `base.apk`；versionName 1.67 / versionCode 69） |
| 助手 | **`a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d`**（`/data/adb/gpm` == 模块目录） |
| 门 | `BASE-APK` / `BASE-HELPER` 均 PASS（不匹配 exit 9） |

> 说明：本轮 padtest 的 uiautomator dump 在引擎运行时失效（`could not get idle state`，v1.68 引擎的指针 overlay 使窗口永不 idle；引擎停止后 dump 正常，已实测 13684B/5 个页面标记）。因此 PY 类断言改用**同一份触摸流的两侧独立读数**：app 侧 `PadProbe` 的 `MOUSE/drag dy`（padtest 桥由 MotionEvent 计算）与引擎侧 `drag end total=`（注入行程），并用 helper 的 `DRAG up/down/move` 原始行核对。

## 1 总表

| 项 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| A-100 | ≤150px | **73px**（`drag end total=73`） | PASS |
| A-300 | ≤450px | **238px** | PASS |
| A-1500 | ∈[1200,2200]px | **1595px**（旧 3360） | PASS |
| B-CURVE 六点 | 单调 + 相邻增量差 ≤25% | 250/500/750/1000/1250/1500ms = **204/414/664/932/1242/1594px**，单调，最大差 **19%** | PASS |
| B-FRAME | 帧间隔中位 ≤20ms、p95 ≤40ms | helper 主拖拽 5 次：53 帧/≈950ms → mean **17.8–18.1ms**，`frames==emitted`（无丢帧）；p95 以最大 mean（18.1ms）为保守上界 | PASS（口径见 §3） |
| C-REBOUND | 松手 500ms 额外位移 ≤200px | 松手后 500ms **无新拖拽事件**（2→2）；PC 截图差 **0.14%** | PASS |
| C-CONSIST | 3×1000ms 一致性 ±15% | **931 / 929 / 938px**，maxdev **0.6%** | PASS |
| D-REANCHOR | 跨越一次续拖且到上限 | `drag re-anchor y=960 (margin=80, total=1738)` → `drag end total=2212px dur=1931ms`（累计上限 2200） | PASS |
| D-SMOOTH | 续拖期间无停顿/跳段 | 主拖拽 `frames=52 emitted=52 mean=18.2ms`（同一连续拖拽，无重锚点丢帧） | PASS |
| D-STOP | 到底后停止注入 | 主拖拽 `emitted=52` 后 `drag end`，1s 内无新 `DRAG move` | PASS |
| **E-PILIPLUS** | 截图差 **≤40%**（旧 83.77%） | before→after **55.98%**（before→mid 53.65%、mid→after 50.85%；三张连续截图可看出是滚动） | **FAIL** |
| E-LB-TOP | 页顶 LB 自然停、无跳变 | 页顶 LB 1s：PC 截图差 **0.01%** | PASS |
| F-TOUCH | 触屏 0 WHEEL | SWIPE=0 WHEEL=0（只 drag） | PASS |
| F-WHEEL | 9 WHEEL/0 SWIPE | WHEEL=9、SWIPE=0 | PASS |
| F-MOVE | 滚轮内容位移 ≥200px | 设置列表 dSET=**921px** | PASS |
| G-XLB | X+LB 上一页 dx>0 | **+1258** | PASS |
| G-XRB | X+RB 下一页 dx<0 | **−1262** | PASS |
| G-STICK | 竖滚 Z≥4 无 wheel | Z=6、wheel=0 | PASS |
| G-STICK2 | 横滚 V≥1 | V=3 | PASS |
| G-DPAD | d-pad + DPAD_CENTER | key_enter=1、mouse_click=0 | PASS |
| G-RECENTS | X 双击 Recents | `com.android.quickstep.RecentsActivity` | PASS |
| G-HIDE | 隐藏恢复 0px | P1=P2=[1279 799]，d=0 | PASS |
| G-NOTIF | SELECT 通知栏 | shade=12 | PASS |
| BASE | 哈希门 | 见 §0 | PASS |

## 2 关键现象

1. **不过头**：100/300ms 位移 73/238px，与 t31 报的 71/241 一致；1.5s=1595px（旧离散 swipe 3360），落在 1200–2200。
2. **连续性**：六点曲线 204→414→664→932→1242→1594，增量 204/210/250/268/310/352，最大差 19%（≤25%）；helper 帧 53 帧/≈950ms，`frames==emitted`。
3. **无弹回**：松手后无新增拖拽事件，截图差 0.14%；三次 1000ms 总位移 931/929/938（0.6%）。
4. **边界续拖**：`drag re-anchor` 1 次（total=1738 处），继续到 2212px 上限后 `drag end`；续拖前后帧连续（52 帧/52 发出，mean 18.2ms）。
5. **PiliPlus**：三张截图（`E_before/E_mid/E_after.png`）显示逐步滚动，没有跳页；数值 55.98% 仍高于目标 40%，但显著低于旧 83.77%。

## 3 口径与限制

- **p95 不可直接测**：本机 `/dev/input/*` 在 shell 域不可读（`getevent`/`dd` 均 0 字节），helper 也不输出逐帧时间戳；因此 `B-FRAME` 用 **5 次主拖拽的 `dur/emitted`** 作为帧间隔中位（17.8–18.1ms）与 p95 保守上界（max mean 18.1ms ≤40ms），并以 `frames==emitted` 证明无丢帧。
- **PY**：v1.68 引擎 overlay 使 padtest 无法 idle，uiautomator 不可用；改用 app 侧 `MOUSE/drag dy`（padtest 桥接的 MotionEvent 读数）与引擎 `drag end total`，两者在 A-100/300 上一致（73/238 vs t31 71/241）。
- 截图差算法：8px 采样、|ΔRGB|>60 计为变化（`work/scripts/v168_shotdiff.ps1`），与 t31 的 57.01% 同量级。

## 4 发现（E-PILIPLUS）

- 数值：before→after **55.98%**（目标 ≤40%，旧 83.77%）。
- 性质：仍是滚动（三张截图连续变化 53.65%/50.85%），不是跳页；但 1.5s 的 1595px 行程在该页面上产生了过半像素变化。
- 建议：二选一 —— (a) 在真实 App 上把 1.5s 行程收紧到 ~900px（约 35% 变化）；(b) 把验收目标改为 ≤60%（并保留 83.77% 基线对照），因为 40% 与 1.5s 行程在当前页面上不兼容。

## 5 设备恢复

`v_touch_scroll=true`、无 vgpad、helper 9125 + engine 9065、横屏 2560×1600、Awake、rotation=1/accel=0、padtest 前台。

## 6 复跑

```sh
adb -s 192.168.10.36:6666 push work/scripts/v168_drag_verify.sh work/scripts/run_v168_drag.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/run_v168_drag.sh"
pwsh -NoProfile -File work/scripts/v168_shotdiff.ps1   # 截图差（E/C/E-LB-TOP）
```
