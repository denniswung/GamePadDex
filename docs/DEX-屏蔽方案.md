# DeX 下屏蔽"三星自带手柄控制"——问题、根因与实现

> 结论先行：**用 root 的 `EVIOCGRAB` 独占手柄设备节点**，是唯一能在 DeX 下彻底屏蔽系统侧手柄处理的方案；实测 A/B 通过（见 §4）。
> 配套用 `/dev/uinput` 造一个虚拟鼠标，才让 DeX 桌面/任务栏的点击真正生效（Touch 手势在 DeX 桌面上不生效，见 §3）。

---

## 1. 现象（用户描述）

> 在 DeX 里开启原版 Gamepad Mouse 的鼠标模式后，"DeX 桌面上手柄被当成方向键导航图标"。

即：明明 App 已经进入"鼠标模式"，手柄的 D-Pad / 摇杆却仍然被 DeX 桌面（`com.sec.android.app.launcher/com.honeyspace.dexservice.SecondaryLauncher`）当成方向键，导致图标选中框乱跳、焦点被抢走。

## 2. 根因分析（在设备上实测得到）

设备：SM-F9360（Galaxy Z Fold4，Android 16 / API 36），外接 HDMI 2560×1600（`displayId=8`，
`FLAG_EXTERNAL_DEX_HOSTING`），系统为 KernelSU root。

| 观测 | 结论 |
|---|---|
| `dumpsys accessibility` → `Enabled features of Display [8] = [MotionEventInjector]`（display 0 才是 `[KeyboardInterceptor, MotionEventInjector]`） | **DeX 显示上无障碍键盘拦截器不启用**：App 的 `AccessibilityService.onKeyEvent()` 在 DeX 上收不到按键，手柄按键必然落到当前焦点窗口（桌面 Launcher），于是变成"方向键导航"。 |
| 注入虚拟手柄（`/dev/uinput`）后，App 的覆盖窗口虽然是 DeX 上的焦点窗口，`View.onGenericMotionEvent()` 依旧收不到摇杆 MotionEvent | 摇杆（`SOURCE_JOYSTICK`）MotionEvent 在 DeX 上也不会送到无障碍覆盖窗口。 |
| 用 `dispatchGesture`（Touch）点击 DeX 任务栏 / 桌面图标 | **无效**：DeX 桌面只认鼠标事件（`SOURCE_MOUSE`），注入的触摸被忽略。 |
| 用 `/dev/uinput` 造虚拟鼠标发 `REL_X/REL_Y + BTN_RIGHT` | **有效**：桌面右下角弹出 DeX 右键菜单（壁纸/小部件/设置），说明原生鼠标事件被正常处理。 |

所以原版在 DeX 下的问题不是"焦点没抢到"，而是两条输入通道（无障碍按键拦截 / 摇杆 MotionEvent）在 DeX 显示上都不可用；应用层再怎么写都无法可靠地把手柄事件从系统手里抢过来。

## 3. 方案

### 3.1 root 独占（核心）

`gpminput`（随 App 打包的静态 aarch64 可执行文件，`app/src/main/assets/gpminput`，源码同目录 `gpminput.c`）：

1. 扫描 `/dev/input/event*`，用 `EVIOCGBIT` 判定"手柄"（有 `BTN_GAMEPAD/BTN_SOUTH` + `ABS_X`，且不是触摸屏）；
2. 鼠标模式**开启时** `ioctl(fd, EVIOCGRAB, 1)` 独占；
   从这一刻起 **system_server、DeX 桌面、GameTools、前台游戏全都收不到这个设备的事件**；
3. 自身 `read()` 原始事件，按行协议（`AX`/`KEY`）把归一化后的数据发给 App；
4. 鼠标模式**关闭时** `EVIOCGRAB, 0` 释放，游戏恢复原样。

> 为什么不用"改设置/关服务"的办法：三星把 DeX 的手柄处理放在 system_server 的输入分发里，没有对外开关；`EVIOCGRAB` 是内核层面的独占，最彻底、可逆、随 App 存活状态自动回收（进程退出 fd 关闭即自动释放）。

### 3.2 原生鼠标注入（DeX 可用性）

`gpminput` 同时通过 `/dev/uinput` 创建：
* `Gamepad Mouse Pointer`（`REL_X/REL_Y`、`REL_WHEEL/REL_HWHEEL`、`BTN_LEFT/RIGHT/MIDDLE`）
* `Gamepad Mouse Keyboard`（媒体/音量/方向键等）

App 的 `PointerEngine` 有两种渲染后端：
* **gesture**（默认无 root 时）：自绘橙色箭头光标 + `dispatchGesture` 注入触摸——与原版一致，适合手机屏幕；
* **native**（有 root 且 `pref_native_pointer=true`，默认开）：不再画光标，直接发 `REL_*`/`BTN_*`，由系统绘制真正的鼠标指针——**DeX 下必须用这个**，点击/右键/滚轮才生效。

`pref_native_pointer` 默认 `true`，但只有在 root helper 就绪时才会真正启用，否则自动回落到 gesture。

### 3.3 输入通道选择

```
鼠标模式 ON  → helper 已就绪 ? (EVIOCGRAB 独占 + 原生鼠标) : (无障碍覆盖窗口 + 手势)
鼠标模式 OFF → helper 释放设备；无障碍 onKeyEvent 只在需要时消费按键（不再是"吞掉所有手柄键"）
```

## 4. 验证（实测 A/B）

在 DeX 显示上打开系统"设置"，然后注入手柄 `KEY_BACK`（Linux 158 → Android `KEYCODE_BACK`）：

| 状态 | `topResumedActivity`（display 8） |
|---|---|
| 鼠标模式 **OFF**（未独占） | 设置 → **返回到了 DeX 桌面**（系统看到了 BACK） |
| 鼠标模式 **ON**（已 `EVIOCGRAB`） | **停在设置页，纹丝不动**（系统完全收不到手柄事件） |

其它已实测通过的点：
* 虚拟手柄摇杆 → 光标从 `x=1260` 移动到 `x=2540`（16 ms 帧循环，DeX 速度 35 px/帧）；
* `BTN_A` → `primary down` → `tap at 1280,800 disp=8`（gesture 后端）/ `BTN_LEFT`（native 后端）；
* native 鼠标 → DeX 桌面右键菜单弹出（证明 DeX 只认鼠标事件）；
* App 通过 unix socket 连上 root helper（`/data/adb/service.d/99-gpm-helper.sh` 开机自启），无需每次弹 `su` 授权。

## 5. 装机步骤

1. 安装 APK（debug 即可）：`adb install -r app-debug.apk`
2. 开启无障碍：设置 → 无障碍 → 已下载的服务 → "Gamepad Mouse Service"
3. root 常驻（推荐）：
   ```sh
   adb push gpminput /data/local/tmp/
   adb push tools/99-gpm-helper.sh /data/local/tmp/
   adb shell sh /data/local/tmp/install-helper.sh   # 或手动 cp 到 /data/adb/gpm + /data/adb/service.d
   ```
4. 打开 App → Root/DeX 页确认 "root helper connected: yes"；打开 "Use the native system pointer"
5. 手柄 L3（或 `pref_toggle_keycode` 设定的键，或 App 内按钮）进入鼠标模式

## 6. 代码位置

| 文件 | 作用 |
|---|---|
| `project/app/src/main/assets/gpminput.c` | 原生助手（EVIOCGRAB + uinput + 行协议） |
| `project/app/src/main/assets/gpminput` | 编译好的静态二进制（aarch64，`aarch64-linux-gnu-gcc -O2 -static`） |
| `project/app/src/main/java/.../RootInput.kt` | 助手进程/套接字桥接、Linux→Android 键码映射 |
| `project/app/src/main/java/.../PointerEngine.kt` | 光标状态机 + gesture/native 两种后端 |
| `project/app/src/main/java/.../MouseAccessibilityService.kt` | 鼠标模式开关、输入分发、动作映射 |
| `project/tools/99-gpm-helper.sh` | KernelSU/Magisk 开机自启脚本 |
