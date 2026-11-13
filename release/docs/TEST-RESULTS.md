# 测试结果（v1.23 / v1.24 检查）

执行环境：SM-F9360（Android 16, KernelSU late-load, LSPosed），adb `192.168.10.36:6666`，
手机模式（HDMI 接了但为屏幕镜像，`DEX -1`）。执行脚本：`work/scripts/checklist_run.sh`。

## 1. 自动化用例（19 项）

一次链路健康的完整运行（debug 构建，v1.23 代码）结果：

```
PASS  A0 link ready (probe)
PASS  A1 helper ready
PASS  A2 dex detection
PASS  B1 left stick moves pointer
PASS  B2 A = left click
PASS  C1 d-pad native forward
PASS  C2 A activates focus
PASS  C3 combo X+down
PASS  C4 stick exits native nav
PASS  D1 right stick touch scroll
PASS  E1 L3 center (CENTER(park) -> 802,1271, target 800,1280)
PASS  F1 START switch app
PASS  F2 GUIDE close app
PASS  H1 double X
PASS  I1 SHARE -> mouse off
PASS  I2 SHARE -> mouse on
PASS  C6 four d-pad directions (PAD 103/108/105/106)
PASS  I3 mode off -> system native
PASS  J1 helper crash recovery
PASS  J2 engine crash recovery
PASS=19 FAIL=0
```

## 2. 人工/截图验证

| 用例 | 结果 |
|---|---|
| C2 A 激活焦点（截图） | Settings 焦点在「蓝牙」时按 A → 打开蓝牙页（不是光标位置） |
| D3 水平滑动 | X+RB → `SWIPE 0 802,1271 -> 182,1271`（dx=-620） |
| E1 居中 | `CENTER(park) -> 801,1272`（目标 800,1280） |
| B4 滚轮 | 注入 `REL_WHEEL`；本次截图对比不稳定（测试时屏幕熄灭），列为**未确认** |

## 3. 本轮发现并修复的问题

1. **A 跟随焦点只在助手转发 `PAD` 时生效** → 增加 `ActionRouter.onArrowKey()` 路径，
   App 自己注入方向键时也进入 nativeNav（v1.23）。
2. **设备按键按住时被移除会让转发永久失效** → `remove_dev()` 清空 `g_held`（v1.23）。
3. **关闭鼠标模式时方向键被双重投递**（系统原生 + 虚拟键盘）→ `ungrab_all()` 复位 `g_dpad_native`，
   引擎在 `setMode(false)` 时补发 `I 0`。
4. **助手崩溃会被 SIGPIPE 杀死**（客户端断开后写 socket）→ 忽略 SIGPIPE。

## 4. 已解决：Samsung Freecess 冻结进程（v1.25）

现象：使用一段时间后，所有映射（A、方向键、摇杆）突然全部失效，但引擎进程仍在、`isForeground=true`；
adb 看线程栈：

```
dexpad-link  : __refrigerator → unix_stream_data_wait
dexpad-engine: __refrigerator → do_epoll_wait
```

`__refrigerator` 是内核冻结标志，logcat 里同时有
`FreecessController: FZ : com.dennis.dexpad(...) reason: LEV [cached:X]`。

结论：**Samsung Freecess 把我们的进程当作 cached 冻结了**，前台服务（specialUse / mediaPlayback）
和 PARTIAL_WAKE_LOCK 都没能阻止。冻结后：
- 方向键/按键不再处理 → “映射失灵”；
- `PAD` 不再产生 → `nativeNav` 不成立 → 再按 A 就退回鼠标左键（用户看到的“点在光标处”）。
- 打开一次配置页、或 `am start-foreground-service` 可以临时解冻（本次测试第一次 A 成功、25 秒后又冻结）。

已尝试：
- FGS 类型从 `specialUse` 改为 `mediaPlayback` + `WAKE_LOCK`（仍被冻结）；
- supervisor 每 8 秒发一次 `am start-foreground-service`（只能偶尔解冻，服务已在运行时通常无效）。

解决方案（v1.25 已实现并验证）：
- 引擎启动后播放一路 **0 音量静音音频**（`AudioTrack` / USAGE_MEDIA / 48 kHz），系统把“有音频播放”的进程
  排除在 Freecess 之外（`dumpsys audio` 里可见 `state:started`、`clientVolume` 静音）。
- 实测：连续闲置 **3 分钟**后 `__refrigerator` 计数 0，按 A 正常触发；此前约 13 秒就会被冻结。
- 配套修复：SHARE 开关持久化（supervisor 每 8 s 的 start 不再顶掉“关”）；鼠标模式关闭时只允许 SHARE、
  助手只上报按键不上报轴（避免方向键双重触发）；supervisor 发现引擎丢失时把助手一起重启，
  避免旧会话占着 socket 导致新引擎连不上。
- 副作用：静音音频会出现在系统媒体会话/音量面板里（音量为 0），属预期。

## 5. 滑动统一优化（v1.26）

- 问题：右摇杆下滑只会“滑一小段又弹回”，启动器下拉/上滑出不了应用抽屉或通知栏。
- 原因：竖向拖动固定 620 px / 260 ms，且从指针/任务中心开始，距离和速度都不足以触发系统手势（Lawnchair 抽屉、
  通知栏下拉都要求足够的位移+fling）。
- 统一后的手势（引擎计算，助手执行）：
  - 竖向：拖动距离 = 任务高度 50%（420–1800 px），时长 200 ms；下滑从 30% 高度开始（→80%），上滑从 70% 开始（→20%）；
  - 横向：拖动距离 = 宽度 40%（500–1200 px），时长 200 ms；向右从 25% 开始，向左从 75% 开始；
  - `V`/`Z` 命令新增可选 `startPct` 参数（0–100，缺省 -1 = 沿用指针锚点）。
- 实测（release v1.26，Lawnchair）：
  - 下滑：`SWIPE 0 420,768 -> 420,2048` → 打开通知栏（截图）；
  - 上滑：`SWIPE 0 420,1792 -> 420,512` → 打开应用抽屉（截图，`work/probe/u2.png`）；
  - 自动化清单 20 项仍 `PASS=20 FAIL=0`。

## 6. 结论

- 自动化清单 20 项（含防冻结 3 分钟场景）在 release v1.25 上 `PASS=20 FAIL=0`。
- 长期困扰的“用一会儿就失灵/A 点到光标”已定位为 Freecess 冻结并用静音音频解决。
- 测试脚本：`work/scripts/checklist_run.sh`（自动化）、`checklist_visual.sh` / `checklist_wheel.sh`（人工辅助）、
  `dexpad_test_*.sh`（单项）。


## 7. v1.35 横屏与按应用滑动

- 强制横屏：ccelerometer_rotation=0、user_rotation=1，横屏 2560×1600；CENTER(corner) 目标 1280,800。
- 助手 TOP 上报 + 引擎自适应：桌面 SWIPE 0 1280,1040 -> 1280,560（480=30%×1600）；
  抖音同；PiliPlus/红果因强制竖屏任务，SWIPE 0 904,1664 -> 904,896（768=30%×2560）。
- 横屏自动化清单 20 项 PASS=20 FAIL=0（E1 现校验 CENTER 目标值）。


## v1.44（恢复 v1.43 骨架 + 按键默认值按《手柄按键处理》）

- 清单 25 项全绿：A0-A2、B1-B2、C1-C6、D1、E1、F1-F2、H1、I1-I3、J1-J2、K1（1279,799）、M1-M2、N1、P1（POWER=2）。
- 按键变化：X 单击无动作/双击多任务、SELECT=通知栏、GUIDE=无、R3 双击=播放暂停。
- 摇杆未改动（沿用 v1.43 死区/速度/滚动）。
