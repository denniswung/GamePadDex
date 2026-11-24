# TEST-CASES-v1.68 · LB/RB 连续拖拽（助手 d/m/e 原语）用例表与证据摘要

> 判据同前：每条都有客观真机证据（引擎 `drag end total` / helper `SWIPE|WHEEL` 计数 / uiautomator 内容位移 / 前台组件 / 截图度量），阈值可证伪。
> 本轮改动：助手新增连续拖拽原语（`d`/`m`/`e`）+ 本机触摸面板 90° 映射反解；应用侧 LB/RB 触屏模式从离散 560px swipe
> 改为一次 down→多帧 move→up 的**连续拖拽**，速度按 `scroll_speed` 可调。滚轮模式与其它动作未改。

## 0 版本与字节

| 项 | 值 |
|---|---|
| 应用 | `com.dennis.dexpad` · versionName **1.68** / versionCode **70** |
| **发布 APK** | `release/dexpad-v1.68.apk` sha256 = **`c8b002880c70dedc1fc6ddbc047bcf87503a6539b8d72693ae32b7e925bbc998`**（2684731 B，`assembleRelease`） |
| 验证用 APK（同源码，debuggable） | `991c051090a3286a83bd0d6433d268f4db722fc0b96e3b727d55b1226102c143`（3152543 B；t37 的 22 项跑在这个字节上） |
| 中间字节（历史） | `e2e9a05b…`（t31 初版，固定速度）、`8ea4cb07…`/`df26e461…`（v1.67 系列）——只作演进记录 |
| **发布助手** | `release/gpminput-v1.68` sha256 = **`a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d`**（852328 B，含 `d/m/e` 与 `touch_panel_xy`） |
| 模块 | `release/gpm_dex-v1.68.zip`（内含同一助手哈希），`module.prop` version=v1.68 / versionCode=70 |

> 发布包是 `assembleRelease`（debuggable=false），`DEBUG`/`HCMD` 广播按设计被忽略；因此滚轮开关在发布字节上用
> 「改 prefs XML + 强制重启引擎」验证（本轮修正了 `set_vt` 顺序：先 sed、再 force-stop、再 start，避免模块 watchdog 抢跑缓存旧值）。

## 1 执行方法

```bash
# 发布字节 LB/RB 17 项（哈希/版本/横屏 + 100ms/300ms/1.5s + 纯拖拽 + 内容位移 + 滚轮 9/0 + PiliPlus）
adb push work/docs/evidence-v168/verify_v168_lbrb.sh /data/local/tmp/
adb shell "su -c 'sh /data/local/tmp/verify_v168_lbrb.sh'"

# 发布字节回归冒烟 23 项
adb shell "su -c 'sh /data/local/tmp/verify_v168_smoke.sh'"

# PiliPlus 截图度量（PC 侧，2560×1600 原图）
python work/docs/evidence-v168/pili_diff.py work/docs/evidence-v168/shots
```

原始证据：`work/docs/evidence-v168/verify_v168_lbrb.result.txt`、`verify_v168_smoke.result.txt`、`shots/`（pili_before/after、prog0-3）、
`work/docs/VERIFY-drag-v168-t37.md`（debug 字节 22 项）、`work/docs/LBRB-v168.md`、`work/docs/HELPER-v168.md`。

## 2 发布字节（release c8b00288）LB/RB 实测：**17/17 PASS**

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| V168-APK | 设备 base.apk == 发布 APK | `c8b00288…25bbc998`（2684731 B） | PASS |
| V168-HELPER | gpm == 模块 == 发布助手 | `a1d06e2e…bd06d` / 同 | PASS |
| V168-VER | versionName=1.68 / versionCode=70，module.prop v1.68/70 | `1.68/70` + `v1.68/70` | PASS |
| V168-LAND | 默认横屏 user_rotation=1、accel=0、app 2560×1600 | `rot=1 accel=0 app=2560x1600` | PASS |
| **V168-SHORT** | RB 短按 **100ms 位移 ≤150px** 且 >0 | **71px**（dur=100ms） | PASS |
| V168-NOSWIPE | 触屏拖拽期间 SWIPE=0 且 WHEEL=0（纯 `d/m/e`） | SWIPE=0 WHEEL=0 | PASS |
| V168-300MS | 300ms 位移 ≤450px 且 >100ms（单调） | **248px**（100ms=71） | PASS |
| **V168-1500** | 按住 1.5s 位移 **∈[1200,2200]px** | **1623px**（dur=1499ms） | PASS |
| V168-1500-PURE | 1.5s 拖拽期间仍 SWIPE=0/WHEEL=0 | SWIPE=0 WHEEL=0 | PASS |
| V168-MULT | 默认 `scroll_speed=4` → 倍率 1.0（可调基准） | `scroll_speed=4 mult=1.0 maxTotal=2200` | PASS |
| V168-MOVE | RB 1.5s 内容实际位移 ≥600px（uiautomator，页顶起手） | **PY 1415→0 d=1415** | PASS |
| V168-VT-OFF | release 包上 `v_touch_scroll=false` 生效（sed prefs + 强制重启引擎） | `vtouch=false`，新 engine pid | PASS |
| **V168-WHEEL-RB** | 滚轮 RB 1.5s：**WHEEL≥6 且 SWIPE=0** 且 `mode=wheel` | **WHEEL=9 SWIPE=0** | PASS |
| **V168-WHEEL-LB** | 滚轮 LB 1.5s：同上 | **WHEEL=9 SWIPE=0** | PASS |
| V168-RESTORE | 恢复 `v_touch_scroll=true`（默认安装态） | `vtouch=true`，helper/engine 在 | PASS |
| V168-PILI-TOP | PiliPlus 在前台（截图对象正确） | `com.example.piliplus/.MainActivity` | PASS |
| V168-PILI-TOTAL | PiliPlus 1.5s 引擎总位移 ∈[1200,2200]px（≈2200 封顶） | **1643px**（dur=1499ms） | PASS |

### 2.1 PiliPlus 1.5s 截图差异（PC 侧三口径）

`pili_before → pili_after`（2560×1600 RGB 原图，无缩放）：

| 口径 | 值 | 与 ≤40% 判据 |
|---|---|---|
| **RMSE**（ImageMagick `compare -metric RMSE` 同义，归一化） | **31.33%** | **≤40% PASS** |
| **MAE**（平均像素差/255） | **18.95%** | ≤40% PASS |
| 逐像素变化占比（max channel |Δ|>8） | 58.34% | 不作为判据（见下） |

> **口径说明（重要）**：t31 报的 57.01%（旧离散 83.77%）是"逐像素变化占比"——滚过一整屏内容时该值必然 50%+，
> 所以 t33/t37 已把截图像素比从"过头"判据中移除，正式判据 = **总位移 ≤2200px + 三图渐进**（t37：total=1617，三次 500ms 累计 433/427/423，两两 >5%）。
> 本轮发布字节的 RMSE **31.33%** 满足验收写的 ≤40%；同时如实列出另外两个口径，避免口径混淆。
> 三图渐进（本轮发布字节）：prog0→1 / 1→2 / 2→3 的 RMSE = **34.86% / 38.37% / 40.24%**，逐段推进、无跳页。

## 3 t37 复验（debug 字节 991c0510，22 项全通过）

| 组 | 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|---|
| BASE | 字节绑定 | APK==t36/t37 报告哈希、helper a1d06e2e | 均一致 | PASS |
| 不过头 | 100/300/1500ms | ≤150 / ≤450 / ∈[1200,2200] | **74 / 242 / 1586px** | PASS |
| 连续性 | 六点曲线 | 单调、相邻增量差 ≤25% | 208/418/666/947/1242/1570，最大差 **18%** | PASS |
| 帧间隔 | 主拖拽 | 帧间隔稳定 | 5 次 **17.9–18.1ms**，frames==emitted | PASS |
| 可调性 | speed 2/4/7/10 | 单调、默认档 ∈[1200,2200] | **1167 / 1591 / 2255 / 2893px** | PASS |
| 快照 | 按压中改 speed | 按压内倍率不变 | 1.7s 时改 10 → 起手仍 `mult=1.0`，total=2212（封顶 ≈2200） | PASS |
| 无弹回 | 松手后 500ms | 无新拖拽、额外 ≤200px | 事件 2→2、截图差 0.15%；3×1000ms=941/956/931（1.4%） | PASS |
| 边界续拖 | 距边 80px | up→新锚点 down 续拖至封顶 | re-anchor total=1740 → end **2218**，53/53 帧 17.8ms，停后 1s 无 move | PASS |
| 互斥 | 触屏 | SWIPE=0 / WHEEL=0 | 0 / 0 | PASS |
| 滚轮 | 滚轮模式 | WHEEL=9 / SWIPE=0 + 内容位移 | 9 / 0，dSET=921px | PASS |
| 回归 | 7 项 | 6 项不得回退 + 隐藏恢复等 | 全 PASS（X+LB +1258、X+RB −1262、摇杆 Z=6/V=3、DPAD_CENTER、Recents、隐藏 0px、SELECT） | PASS |

### 3.1 助手拖拽原语（t30）

- `d <display> <x> <y>` 按下（MT 单指，夹到 task 内）；`m <display> <dx> <dy> <ms>` 分步移动（主循环每 8–16ms 一帧 `ABS_MT_SLOT+POSITION_X/Y+SYN`，非阻塞）；`e [display]` 抬起。
- 单段 `m 1000 0 500`：getevent 50 个 `ABS_MT_POSITION_Y`，间隔 9.21–10.46ms、越界 0、单调递增；padtest `dx=1000 dy=0`（误差 0%）。
- 安全：无 down 的 move → `ERR drag move (no down)`；`ERR d args`；越界夹 (20,1580)；停发 1.8s → `auto-up idle` 后单击正常；`?` 自检 13 CAP+5 INFO、ERR=0。
- **本机触摸面板 90° 映射**：直接注入会让纵向拖拽在应用侧变横向（实测 down 1280,1200 → app 1919,800）；加入 `touch_panel_xy()` 反解后应用侧坐标/位移与请求一致，非 2560×1600 退化为恒等映射。

## 4 发布字节回归冒烟（`verify_v168_smoke.sh`，23 项）

与 v1.67 相同的 23 项，在 v1.68 发布字节上重跑（期望 APK/版本/助手哈希改为 1.68/70/c8b00288/a1d06e2e）：
L3 居中 1281,799 / 满推 2559,799 / 竖推 dPY=1415（仅 Z）/ 横推 dHS=512（仅 V）/ 隐藏首推 1415 /
Y+上 PiliPlus、Y+下 抖音 / d-pad+DPAD_CENTER / X 双击 Recents / X+LB +677、X+RB −1536 / I5 0px /
SELECT `NOTIF rc=0 dur=390ms` / 横屏守护 ≈500ms / 60s 空闲 CPU 0.90%、CURSORQ=0 —— 结果见 `verify_v168_smoke.result.txt`。

## 5 已知限制（如实记录）

- **padtest 页底 LB 锚点**会落进内层 ListView（外层 PY 不动、内层列表滚动）——测试台页面结构，真实 App 两方向已验证（t31/t33 R3）。
- **拖拽中的 screencap 是陈旧帧**（t37 §5：1.1/1.15s 与 before 差 0.01%），所以"mid"用分次累计 + 段间截图；本轮 prog1–3 都是段间新鲜帧。
- **cap 2218 vs 2200** = 0.5% 容差（发布说明写 ≈2200 ±1%）。
- **H2 首轮 NOSWITCH FAIL** 是仪器时序（0.4s 改 pref 发生在 drag start 之前），1.7s 复测 PASS，不是产品回归（t37/t33 R5）。
- 滚轮仍受指针悬停窗口限制（`ensureWheelAnchor` 缓解，README §9 已写）。

## 6 复跑

```bash
adb shell "su -c 'sh /data/local/tmp/verify_v168_lbrb.sh'"     # 17 项
adb shell "su -c 'sh /data/local/tmp/verify_v168_smoke.sh'"    # 23 项
adb push work/docs/evidence-v168/verify_install.sh /data/local/tmp/ && adb shell "sh /data/local/tmp/verify_install.sh"
```
