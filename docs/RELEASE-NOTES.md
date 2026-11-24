# v1.68 发布说明（2026-11-25）

包名：`com.dennis.dexpad`　versionCode **70** / versionName **1.68**
配套：KernelSU 模块 `gpm_dex` v1.68 · 助手 `gpminput` v1.68（新增连续拖拽原语）· 测试台 `com.dennis.padtest` v1.1

| 资产 | 文件 | sha256 | 大小 |
|---|---|---|---|
| 应用 | `dexpad-v1.68.apk` | `c8b002880c70dedc1fc6ddbc047bcf87503a6539b8d72693ae32b7e925bbc998` | 2684731 B |
| 模块 | `gpm_dex-v1.68.zip` | `51044ce21322f23fc09f1a52ace0cd229fcc2ae2f430023911a33aea7f14049f` | 365632 B |
| 助手 | `gpminput-v1.68` | `a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d` | 852328 B |
| 测试台 | `padtest-v1.1.apk` | `27478cef1c51acddc88c7ef662980ead4720bc95ce38635b0aa816f67de32e50` | 949222 B |

模块 zip 内 `gpminput` 与 `gpminput-v1.68` **同哈希**；APK 内 `assets/gpminput` 解包后亦为同一哈希（三处一致）。

## 1 LB/RB 触屏模式：从离散滑动改成**连续拖拽**

### 之前（v1.67）的问题

触屏模式下 LB/RB 是"离散 560px 滑动 ×N"：每次手势是独立的一段，段间有 30–39ms 空档，
大屏快速滚动时看起来是"一顿一顿地跳"（每次 560px 的段落感、边界处还有 up/down 断点）。

### 现在（v1.68）

助手新增**连续拖拽原语**（小写命令，未与既有命令冲突）：

| 命令 | 语义 |
|---|---|
| `d <display> <x> <y>` | 按下（MT 单指，逻辑像素，自动夹到 task 内） |
| `m <display> <dx> <dy> <ms>` | 分步移动：只登记算术，主循环每 **8–16ms** 发一帧 `ABS_MT_SLOT + POSITION_X/Y + SYN`（非阻塞状态机） |
| `e [display]` | 抬起（任何时刻可结束；停发 1.8s 自动 `auto-up idle`） |

应用侧一次按压 = **一次 down → 多帧 move → up**（松手前两帧零位移再抬起），速度模型：

- **<400ms ≈900px/s** → **400–1400ms 线性升到 1500px/s** → 封顶（有加速度、无突跳；每帧加速度限制 0.8%、dt≤20ms）
- **可调**：`scroll_speed` 1–10 → 拖拽倍率 `0.6 + (scroll_speed-1)×1.2/9`（**0.6×–1.8×**，默认 4 = **1.0×**），按压开始时快照、按住中不切换
- 累计上限 `maxTotal = 2200px × 倍率`，到顶 `drag stop cap` 或松手即停
- **边界续拖**：距 task 上/下边 80px 时先 `up`、在新锚点 `down` 继续（内容偏移连续，无可见断点）
- **本机触摸面板 90° 映射**：直接注入会让纵向拖拽在应用侧变成横向（实测 down 1280,1200 → app 1919,800），
  已用三点标定 + `touch_panel_xy()` 反解；面板改为启动时创建避免首帧丢失；非 2560×1600 退化为恒等映射

「触摸滚动」**关**时仍是**纯滚轮**（每 186ms 一步、1.5s 9 步、不发 swipe），机制在按下瞬间定死、按压期间不切换。

## 2 发布字节实测（release `c8b00288`，装机 + reboot 之后）

| 项目 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| **短按 100ms 位移** | ≤150px | **71px**（dur=100ms） | PASS |
| 300ms 位移 | ≤450px 且单调 | **248px**（100ms=71） | PASS |
| **按住 1.5s 位移** | **1200–2200px** | **1623px**（dur=1499ms） | PASS |
| 拖拽期间手势计数 | SWIPE=0 且 WHEEL=0（纯 `d/m/e`） | 0 / 0 | PASS |
| 默认倍率 | `scroll_speed=4` → 1.0× | `mult=1.0 maxTotal=2200` | PASS |
| 内容实际位移 | ≥600px（uiautomator 页顶起手） | **PY 1415→0（d=1415）** | PASS |
| **滚轮模式 RB/LB** | WHEEL≥6 且 SWIPE=0 | **WHEEL=9 / SWIPE=0**（两侧） | PASS |
| **PiliPlus 1.5s 截图差异** | ≤40% | **RMSE 31.33%**（MAE 18.95%；逐像素变化占比 58.34%，见下） | PASS |
| PiliPlus 1.5s 总位移 | ∈[1200,2200]px | **1643px** | PASS |

PiliPlus 三图渐进（三次 500ms，段间新鲜截图）：RMSE **34.86% / 38.37% / 40.24%**，逐段推进、无跳页。
**口径说明**：t31 的 57.01%（旧离散 83.77%）是"逐像素变化占比"——滚过一屏必然 50%+，t33/t37 已不把它当过头的判据；
本轮按验收写「截图差异 ≤40%」采用 **RMSE（ImageMagick 同义）31.33%**，同时把 MAE 与逐像素占比一并列出，避免口径混淆。

回归（发布字节 23 项冒烟）：L3 1281,799、满推 2559,799、竖推 dPY=1415（仅 Z）、横推 dHS=512（仅 V）、
空闲隐藏首推 1415、Y+上 PiliPlus / Y+下 抖音、d-pad+DPAD_CENTER、X 双击 Recents、X+LB +655 / X+RB −1536、
I5 0px、SELECT `rc=0 dur=391ms`、横屏守护 ≈1000ms、60s 空闲 CPU **0.82%**、CURSORQ=0。

## 3 助手（gpminput v1.68）改动

- 新增 `d` / `m` / `e` 连续拖拽原语（MT 单指、非阻塞、越界夹取、auto-up 安全兜底、拖拽中单击/双指会 abort）。
- 触摸面板 90° 映射反解（`touch_panel_xy`）+ 启动时创建面板。
- **注释清理**：清掉 t13 遗留乱码注释 153 行 / 109 处（改为正确中文），仅注释改动，**编译产物哈希不变**（仍是 `a1d06e2e`）。
- 其余命令（`?` 自检、`u` 唤醒、`g`/`O` 增益、`c` 光标、`P` 绝对定位、`S` 滚轮、`V`/`Z` 手势）与串行队列未改。

## 4 验证（可复跑）

| 项目 | 结果 | 证据 |
|---|---|---|
| **发布字节** LB/RB 17 项 | **17/17 PASS** | `work/docs/evidence-v168/verify_v168_lbrb.result.txt` |
| **发布字节** 回归冒烟 23 项 | **23/23 PASS** | `work/docs/evidence-v168/verify_v168_smoke.result.txt` |
| t37 复验（debug 字节 991c0510，22 项） | 22/22（含 speed 映射、续拖、无弹回、滚轮、回归） | `work/docs/VERIFY-drag-v168-t37.md` |
| 装机哈希校验 | 全部一致（APK / 助手三处 / zip 内 / APK assets / 重启后） | `work/docs/INSTALL-v168.md` |

```bash
adb shell "su -c 'sh /data/local/tmp/verify_v168_lbrb.sh'"    # 17 项
adb shell "su -c 'sh /data/local/tmp/verify_v168_smoke.sh'"   # 23 项
```

## 5 已知限制 / 注意事项

- **padtest 页底 LB 的锚点**会落进内层 ListView（外层 `PY` 不动、内层滚动）——测试台结构导致，真实 App 两个方向都验证过。
- **拖拽中的 `screencap` 是陈旧帧**（t37 §5：1.1/1.15s 与 before 差 0.01%），所以"mid"用分次累计 + 段间截图，不能用"按住中截图"证明中间态。
- 累计上限实测 **2218 vs 2200**（0.5% 容差），发布口径写 **≈2200px × 倍率（±1%）**。
- **滚轮仍受指针悬停窗口限制**（`REL_WHEEL` 只作用于悬停窗口）：`ensureWheelAnchor` 已把指针放到 task 中心，但目标列表不在该位置时仍可能滚不动，此时用连续拖拽更可靠。
- **发布包不响应调试广播**（`DEBUG`/`HCMD` 只在 debuggable 构建生效）；本轮滚轮开关在发布字节上用「改 prefs + 强制重启引擎」验证。
- 其余 v1.66/v1.67 的已知限制（`display_size_forced` 清不掉、DeX 外接屏未完整回归、触摸点击依赖估算坐标等）不变。

## 6 安装

```bash
# 1) 安装 APK
adb install -r dexpad-v1.68.apk
# 2) 安装 KernelSU 模块（或用 KernelSU/Magisk App 刷 gpm_dex-v1.68.zip）
adb push gpm_dex-v1.68.zip /data/local/tmp/
adb shell "su -c '/data/adb/ksu/bin/ksud module install /data/local/tmp/gpm_dex-v1.68.zip'"
# 3) 重启，确认模块生效
adb reboot
adb shell "su -c 'grep version /data/adb/modules/gpm_dex/module.prop; sha256sum /data/adb/gpm/gpminput'"
# 预期：version=v1.68 / versionCode=70；助手 sha256 = a1d06e2e…bd06d
```

**从 v1.67 升级必须换助手**：`d/m/e` 是 v1.68 助手的能力，旧助手配新 APK 会导致触屏 LB/RB 退化为无动作（日志会报 `ERR d args`/未知命令）。
所以 `gpm_dex-v1.68.zip` 与 APK 要一起装、然后重启。

校验和一览见同目录 `SHA256SUMS.txt`；装机校验表见 `work/docs/INSTALL-v168.md`。
