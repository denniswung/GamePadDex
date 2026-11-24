# VERIFY-lbrb-v166 · LB/RB 机制互斥 / 连续性 / 速度 / 回归（真机）

> 任务 t23 · 设备 SM-F9360（adb `192.168.10.36:6666`，横屏 2560×1600）
> 结论：**PASS=16 / FAIL=2（B-RB、C-MOVE）→ 本验证不通过**（C 滚轮模式内容不滚动，需 app/helper 侧确认；B-RB 为页面状态的测量限制，见 §3）
> 原始证据：`work/docs/evidence-lbrb/`（`verify.log` 全量输出、`console.txt`、`raw/` 原始 helper.log 切片、截图）

## 0 绑定与环境

| 项 | 值 |
|---|---|
| 应用 APK sha256 | **`20eddf98793e1a658cb263b6d8e41e14eac43f8ebcd51475a3a2814b83a86e0d`**（= 本机 `app-debug.apk`；versionName=1.66 / versionCode=68） |
| 助手 sha256 | **`1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf`**（`/data/adb/gpm` == 模块目录） |
| 屏幕 / 唤醒 | 2560×1600（landscape）、Awake、user_rotation=1、accelerometer_rotation=0 |
| 关键 prefs | `v_touch_scroll`（脚本切换）、`hswipe_speed=3`、`scroll_speed=4`、`mode_on=true` |
| 脚本 | `work/scripts/v166_lbrb_verify.sh`（设备端 `/data/local/tmp/v166_lbrb_verify.sh`） |

**采样期间字节未变**：开跑前与结束后各核对一次 APK/助手哈希，一致。

## 1 方法（可证伪）

| 用例 | 阈值 | 方法 |
|---|---|---|
| A 互斥 | SWIPE>0 且 WHEEL=0（同一按压内） | 清空 helper.log → LB/RB 各按住 1.5s → 统计 `^SWIPE ` 与 `^WHEEL` 行 + 引擎 `hold-scroll … mode=` 日志 |
| B 触屏连续性 | dPY≥1000 或 dHS≥400；相邻位移空档 ≤150ms | padtest ScrollTestActivity（force-stop 后重启保证页面在顶部）→ 按住 1.5s → uiautomator 前后差；空档 = 相邻 `MOUSE/click-down` 时间戳差 − 220ms（手势时长） |
| C 滚轮模式 | WHEEL≥8、SWIPE=0、内容位移 ≥100px | `v_touch_scroll=false` → 系统设置列表按住 LB 1.5s → uiautomator 文本节点 y 前后差（同一文本） |
| D 稳定 | 每次按压机制与设置一致、切换=0 | 15s 触屏（5 次 LB/RB 交替）+ 15s 滚轮（5 次），逐次统计 |
| E 速度 | 竖 1.5s 总位移 ≥3360px；滚轮等效 ≥8 步 | helper SWIPE 行程求和 / WHEEL 计数 |
| F 回归 | 6 项（+2 附加） | X+LB/X+RB 方向、右摇杆竖/横滚、d-pad+DPAD_CENTER、X 双击 Recents、空闲隐藏 0px、SELECT 通知栏 |
| G | — | APK/助手/模块哈希 + 版本 + 屏幕/唤醒/rotation |

## 2 A 机制互斥（PASS ×2）

| 按压 | SWIPE | WHEEL | 引擎模式日志 | 判定 |
|---|---|---|---|---|
| LB 1.5s | 6（Z=6 V=0） | **0** | `hold-scroll scroll_swipe_down by lb mode=swipe` | PASS |
| RB 1.5s | 6（Z=6 V=0） | **0** | `hold-scroll scroll_swipe_up by rb mode=swipe` | PASS |

原始 helper.log：`raw/A_LB_helper.log`、`raw/A_RB_helper.log`（各 1.3KB，只含 SWIPE 行，无 WHEEL）。
→ 同一次按压内 **SWIPE 与 WHEEL 不会同时 >0**，t22 的“二选一”在触屏模式下成立。

## 3 B 触屏模式内容连续性（LB PASS / RB FAIL）

| 用例 | 实测 | 判定 |
|---|---|---|
| B-LB（页面顶部起手） | **PY 1415 → 0，dPY=1415**，SWIPE=6 | PASS |
| B-INT 相邻位移空档 | click-down n=6，gaps（扣除 220ms 手势）= 138/119/106/134/106ms，**max 138–147ms ≤150** | PASS |
| B-RB（向上滚） | 页面底部状态（PY=0）起手：**dPY=0**；另一次页面中段（PY=656）起手：**dPY=759**（6 条 SWIPE 全部注入） | **FAIL**（dPY<1000） |

分析（客观事实）：RB 的注入手势坐标固定为 `1284,480 -> 1284,1040`（helper SWIPE 行可查）。当页面滚到最底部（PY=0）时，该拖拽区间落在 padtest 的下部子视图（固定区域/左右列表）上，页面本身不再移动 → 测得 0；页面在中段（PY=656）时同一手势可把页面推回顶部（dPY=759），即 RB 的滑动机制本身有效，但**在可复现的页面状态下无法达到契约要求的 dPY≥1000**（页面最大行程 1415px，RB 需 ≥1000px 余量时拖拽区恰好被下部子视图拦截）。
本项按契约判 FAIL；建议 t22 侧确认 RB 的拖拽锚点是否应随页面内容自适应（或验证时改用 PiliPlus 等整页可滚应用——本机 PiliPlus 的 UI 无 a11y 文本节点，uiautomator 取不到内容位移，故无法作为替代）。

## 4 C 滚轮模式（C-WHEEL PASS / C-MOVE FAIL）

| 用例 | 实测 | 判定 |
|---|---|---|
| C-WHEEL | 系统设置列表按住 LB 1.5s：**WHEEL=9、SWIPE=0**，`mode=wheel` | PASS |
| C-MOVE | 同一文本节点 uiautomator 前后差 **dSET=0px**（`连接|144、WLAN|305、Anner_5G|368、蓝牙|492 …` 前后完全一致） | **FAIL** |

补充证据（同一轮）：
- padtest ScrollTestActivity（`v_touch_scroll=false`，LB 1.5s）同样：WHEEL=9、SWIPE=0，列表顶部 `#001@668` 前后不变、PY/HS 均不变 → 内容 **0px**。
- 直接向助手发 `WHEEL -10`（HCMD）时 helper.log **没有 `WHEEL` 行**（该调试通道未转发 wheel 命令），说明此路不可作为对照；但 LB 路径的 9 条 `WHEEL` 行确由助手输出（`gpm/helper.log`）。

结论：**滚轮模式下 wheel 事件已注入（9 步/1.5s），但受测应用内容不滚动**。这与 t22 报告“系统设置 RB→0/9（wheel）”只统计了 WHEEL 行、未验证内容位移相一致——属于 **t22 未覆盖的缺陷/风险**，需要 app-eng/helper-eng 确认（例如 uinput 鼠标设备的 REL_WHEEL 是否被系统当作滚轮、滚轮是否要求 hover/motion 前置事件、或 wheel 应改走 REL_HWHEEL/其他设备）。

## 5 D 机制不切换（PASS）

15s 触屏段 5 次按压全部 `SWIPE>0 WHEEL=0 mode=swipe`；15s 滚轮段 5 次全部 `WHEEL>0 SWIPE=0 mode=wheel`；**bad=0，切换次数=0**。

## 6 E 速度（PASS）

- 滑动模式 LB 1.5s：Z=6，总位移 **3360px**（单条 560px，≥基线 3360px）。
- 滚轮模式 LB 1.5s：WHEEL=**9 步**（≥8 步等效）。

## 7 F 回归（8/8 PASS）

| 用例 | 实测 | 判定 |
|---|---|---|
| F1 X+LB 上一页 | `SWIPE 1284,800 -> 2540,800` dx=**+1256** | PASS |
| F2 X+RB 下一页 | `SWIPE 1284,800 -> 20,800` dx=**−1264** | PASS |
| F3 右摇杆竖滚 | Z=6，V=0，wheel=0 | PASS |
| F4 右摇杆横滚 | V=3，Z=0，wheel=0 | PASS |
| F5 d-pad + DPAD_CENTER | mouse_click=0、key_enter=1 | PASS |
| F6 X 双击 400ms | top=`com.sec.android.app.launcher/com.android.quickstep.RecentsActivity` | PASS |
| F7 空闲隐藏恢复 | P1=[1284 799] → P2=[1284 799]，d=**0px**，`pointer shown at last position (no correction move)` | PASS |
| F8 SELECT 通知栏 | NotificationShade 命中 12 处、截图 19838B 前后（见 `raw/*.png`） | PASS |

## 8 G 哈希/环境（PASS）

```
apk=20eddf98793e1a658cb263b6d8e41e14eac43f8ebcd51475a3a2814b83a86e0d
helper=1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf
module=1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf
version=1.66/68  screen=2560x1600 wf=Awake rot=1 accel=0
```

## 9 设备恢复

恢复 `v_touch_scroll=true`、收起通知栏、回到 padtest ScrollTestActivity；助手/引擎运行中、横屏 2560×1600、Awake、rotation=1/accel=0、无 vgpad。

## 10 复跑

```sh
adb -s 192.168.10.36:6666 push work/scripts/v166_lbrb_verify.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/v166_lbrb_verify.sh"   # 输出 /data/local/tmp/v166_lbrb.log
adb -s 192.168.10.36:6666 shell "grep -ac 'SWIPE\|WHEEL' /data/adb/gpm/helper.log"
adb -s 192.168.10.36:6666 shell "uiautomator dump /sdcard/lbrb.xml >/dev/null 2>&1; echo ok"
```

## 11 结论与后续

- **通过**：A 互斥（LB/RB 各自 6 SWIPE / 0 WHEEL 且模式日志正确）、B-LB 竖向连续性（1415px）、B-INT 空档（≤147ms）、D 稳定性（10/10 机制一致、0 切换）、E 速度（3360px / 9 步）、F 全部回归（8/8）、G 哈希与环境、设备恢复。
- **未通过（阻塞）**：
  1. **C-MOVE**：滚轮模式 wheel 事件已注入但 Settings/padtest 内容 0px 位移 → t22 的 wheel 分支未真正滚动内容（t22 只验证了 WHEEL 行数）。
  2. **B-RB**：RB 的固定拖拽锚点在页面底部会被下部子视图拦截，`dPY=0`；页面中段时为 759px，仍 <1000px 契约值。
- 建议：t22 修复 wheel 注入（或明确 wheel 的适用场景并在契约中调整 C 的口径）；B-RB 需调整拖拽锚点或改用整页可滚应用并给出可复现的 dPY。
