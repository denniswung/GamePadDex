# 代码结构

```
LSPosed 模块（com.dennis.dexpad）
├─ Hook.java            往 Settings 里注入「手柄映射」入口行（LSPosed 入口）
├─ ConfigActivity       配置页（常规/指针/滚轮/按键列表/状态）
├─ ButtonDetailActivity 单键详情：单击 / 双击 / 参与的组合键
├─ DebugReceiver        仅 debug 包：脚本化改映射/改偏好
├─ BootReceiver         开机拉起前台服务
│
├─ EngineService        前台服务 + 8ms 映射循环（摇杆、滑动、缩放、组合调度）
├─ ActionRouter.kt      一次性动作执行（音量/方向键/窗口/居中/切应用…），按手机或 DeX 分支
├─ Actions.kt           动作表：id / 文案 / 全部动作（唯一来源）
├─ Prefs.kt             偏好读写：按键映射、双击、24 个组合槽、速度/死区/开关
├─ DisplayState.kt      注入目标屏：DeX vs 手机（含 DEX/FOCUS 上报、尺寸、旋转）
├─ RootInput.kt         与 root 助手的 unix socket 客户端
├─ KeyCodes.kt          Linux→Android keycode 映射 + Android keycode→按钮名
└─ EngineState.kt       进程内共享状态（连接/模式/设备）

root 助手（gpminput，静态 aarch64）
├─ gpminput.h           公共头：日志、显示辅助函数声明
├─ gpminput.c           evdev 抓取、命令循环、uinput 注入、协议处理
├─ display.c            DeX/焦点屏判定、分辨率、任务栏高度
├─ 虚拟设备（gpminput.c 内）：虚拟鼠标 / 虚拟键盘
└─ 构建：aarch64-linux-gnu-gcc -O2 -static -o gpminput gpminput.c display.c -lm

KernelSU 模块（gpm_dex）
├─ service.sh   supervisor + 引擎守护（8s 轮询）
├─ module.prop / post-fs-data.sh
└─ gpminput / inject.dex
```

## 数据流

```
手柄 --evdev--> gpminput --"AX/KEY/PAD"--> EngineService --"M/B/S/D/C/O/V/Z/Y/A/I/L"--> gpminput
                                   |                                          |
                                   +--> Prefs（映射/组合/双击）                 +--> uinput / input / am
```

- **按键**：助手把每个按键上报为 `KEY <dev> <linuxCode> <down>`；`RootInput.KeyMap` 转成 Android
  keycode，`EngineService.buttonName` 映射为 `a/b/x/y/up/down/...`，再查 `Prefs.action()`。
- **组合键**：按下时先看 24 个 `mix_<i>_keys` 槽，命中就触发槽动作并吞掉参与键的单击；
  左右摇杆/水平滑动说明这是“修饰键用法”，同样取消单击。
- **双击**：`double_<button>` 有动作时，单击延迟 320 ms（等第二击），第二击取消延迟并触发双击动作。
- **方向键**：默认四方向=`arrow_*`；助手在“无其他按键按住”时把 d-pad 转成系统方向键（原生焦点导航），
  按住 X 等键时照常上报 App 以匹配 `X+方向键` 组合；`PAD` 通知引擎进入 nativeNav（A 变 DPAD_CENTER）。
- **屏幕选择**：`DisplayState.active()` = DeX 屏（助手 `DEX <id>` 确认）→ 否则焦点屏（`FOCUS`）→ 否则开着的内置屏。
- **手机降级**：最大化/对齐/切 DeX 跳过；最小化→HOME；关闭应用→`L`（force-stop 前台包）；截图→SYSRQ。

## 约定

- 动作表的唯一来源是 `Actions.kt`；新增动作时加常量 + 文案，再在 `ActionRouter.fire()` 里实现手机/DeX 两个分支。
- 助手命令一行一条、首字母区分，新命令要同步 `RootInput.kt` 与 `docs/PROTOCOL`（工具链里）。
- 显示相关（DeX 判定/尺寸/旋转/焦点屏）只允许在 `DisplayState.kt` 与 `display.c` 里实现，其它模块禁止直接读 DisplayManager。
- 所有耗时系统调用（input/am/keyevent）在助手里 fork 异步，主循环只做 poll + 解析。
- 日志 tag 统一 `DexPad`；助手日志写 `/data/adb/gpm/helper.log`。
- 助手单实例：`flock` + socket 探测；KSU `service.sh` 用 pid 文件防重复 supervisor。
