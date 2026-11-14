# GamePadDex · 手柄鼠标

把手柄（Xbox / 通用 XInput 系）变成 **DeX 与手机可用的鼠标 + 键盘**，并顺手解决一个老问题：
进入鼠标模式后，手柄按键**仍然**被系统当成方向键/焦点键，跟鼠标光标打架。

> 这是对 Google Play 应用 **Gamepad mouse**（`com.pkyul13.gamepadmouse`）的净室复刻：
> 原版用无障碍手势注入，本项目改成 **KernelSU root 助手 + LSPosed 模块**，不依赖无障碍，
> 也不需要在系统里常驻一个假光标。目标机型 SM-F9360（Galaxy Z Fold4，Android 16）。

**当前版本：v1.60** ｜ **[下载 APK / 模块](https://github.com/denniswung/GamePadDex/releases/latest)** ｜ [发布说明](release/RELEASE-NOTES.md) ｜ [架构说明](docs/ARCHITECTURE.md) ｜ [测试台说明](docs/PADTEST-README.md)

---

## 1. 它是怎么工作的

```
手柄 ──evdev──> gpminput（root 助手，EVIOCGRAB 独占）──unix socket──> DexPad App（LSPosed 模块）
                    │                                                      │
                    ├─ 虚拟鼠标  /dev/uinput (REL + 按键 + 滚轮)  <───────┤ 光标移动 / 点击 / 滚动
                    ├─ 虚拟键盘  /dev/uinput (KEY_*)              <───────┤ 方向键 / 组合键 / 电源键
                    └─ 虚拟绝对指针（仅备用）                              │
                                                                           └─ 决定每个按键做什么
```

- **助手** `gpminput`（C，静态 aarch64）用 `EVIOCGRAB` **独占**手柄：系统、DeX 桌面、前台应用都收不到手柄事件，
  于是标题里那个"手柄还会被当方向键"的问题从根上消失。
- 助手把归一化事件经 unix socket 发给 App，App 用 8 ms 的循环把摇杆换算成光标位移、把按键翻译成动作，
  再让助手用 `uinput` 注入回系统——于是系统看到的只是一只普通鼠标和一只普通键盘。
- **LSPosed 模块**负责注入三星设置页入口 + 绕过系统对后台服务的限制（免费冻结、后台弹窗等）。

## 2. 功能

### 鼠标 / 滚动
- 左摇杆移动光标：死区、曲线、速度、边缘减速、精确模式（按住 X）全部可调
- 松手**立刻停**：摇杆回死区就重置滤波并丢弃 < 0.6 px 的亚像素位移，不会"再滑一段"
- 空闲 **8 秒**自动隐藏指针（可关）：助手销毁虚拟鼠标设备，系统没有指针设备可画；
  一动摇杆/按键立刻恢复
- **A 键 = 左键点击**（按住即长按）。默认注入**鼠标左键事件**——系统按真实光标位置处理，最可靠；
  若某个 App 只认触摸事件，可在设置里把「左键注入方式」切到**触摸点击**（坐标来自估算，可能偏）。
  d-pad 模式下 A 仍是「确认焦点」（`DPAD_CENTER`）
- 右摇杆上下 = **真实触摸拖动**：向上拨看上方内容、向下拨继续往下，两个方向都是中屏拖动
  （不会从顶部起手误触通知栏）；左右 = 水平拖动。按住可连续滚
- LB / RB = 手持上滑 / 下滑（相当于"内容下一页 / 上一页"），桌面与系统弹窗上自动转成方向键

### 按键
- A 左键、B 返回、X 长按菜单（双击多任务）、Y 主屏
- L3 **一次性居中**：40 个有界小步归零 + 一步到屏幕中心，不跳、不丢光标（增益可调）
- R3 静音（双击播放/暂停）、START 切换应用、SELECT 通知栏
- **GUIDE（Xbox 键）短按 = 杀掉前台应用**（长按显示帮助；X+GUIDE 也可强杀）
- 扳机 **LT / RT = 以光标为中心的双指缩放**：按住连续缩放，松手立即结束；
  d-pad 模式下自动改为 **Ctrl + - / Ctrl + +**
- 动作表新增 **「打开目标应用」**（默认不绑键）：**每个映射槽各配各的**——按键详情页
  （单击/双击/长按）、组合槽位、映射列表长按，任一处设成该动作都会弹**应用列表**让你挑 App
  （Android 11+ 包可见性已声明，实测可列出 47 个可启动应用；查不到时可手动输入包名）

### 方向键与组合键
- d-pad 默认 = **系统方向键**（焦点导航），不会跟光标抢
- 组合键 24 槽，默认：`X+↑/↓` 音量、`X+←/→` 上/下一曲、`X+LB/RB` 左右翻页、`Y+L3` **开关屏幕**
- 每个按键都能自定义：单击 / 双击 / 长按 / 组合（动作表见 `Actions.kt`）

### 模式
- **鼠标模式**开关（SHARE 键切换）：关掉时手柄立即交还系统，所有映射按键不动作
- 「手机上也启用」：手机（非 DeX）模式同样可用
- DeX 判定用 `DexTaskbarWindow`，区分真 DeX 与 HDMI 镜像
- 前台服务 + KernelSU 守护，关掉配置页 / 划掉任务不会停

## 3. 默认键位表

| 手柄 | 默认动作 | 备注 |
|---|---|---|
| 左摇杆 | 移动光标 | 按住 X = 精确模式（慢速） |
| 右摇杆 ↑↓ / ←→ | 竖向 / 横向触摸拖动 | 真实触摸事件，能触发翻页吸附 |
| A | 左键点击（鼠标事件） | 可长按；设置里可切"触摸点击"；d-pad 模式 = 确认焦点 |
| B | 返回 | |
| X | 无（长按菜单 / 双击多任务） | 也是组合键的修饰键 |
| Y | 主屏 | |
| LB / RB | 手指下滑 / 上滑 | 桌面等不可滚界面自动转方向键 |
| LT / RT | 双指缩小 / 放大 | 以光标为基准、按住连续；d-pad 模式 = `Ctrl+-` / `Ctrl++` |
| L3 | 光标居中 | 一次性，可调增益 |
| R3 | 静音（双击播放/暂停） | |
| START | 切换应用 | |
| SELECT | 通知栏 | |
| GUIDE | 杀前台应用 | 长按 = 帮助；X+GUIDE = 强杀 |
| d-pad | 系统方向键 | 按住 400 ms 后每 110 ms 连发 |
| SHARE | 切换鼠标模式 | 关 = 手柄交还系统 |
| X + ↑ / ↓ | 音量 + / − | |
| X + ← / → | 上一曲 / 下一曲 | |
| X + LB / RB | 向左 / 向右翻页 | |
| Y + L3 | 开 / 关屏幕 | 走虚拟键盘 KEY_POWER |

> 「打开目标应用」是动作表里的一项（`open_app`），默认不绑定按键：
> 在「设置 → 手柄鼠标 → 按键映射」里**点开某个键**（或**长按列表行**直接换动作）→ 把某一槽设成
> 「打开目标应用」→ 随后弹出的应用列表就是**这一槽**的目标 App。不同按键可以指不同 App。

## 4. 安装

### 前置
- Root：**KernelSU**（Magisk 理论上也行，模块格式相同）
- **LSPosed**（或 Vector），作用域必须勾选 **系统设置 `com.android.settings`**
- Android 12L 及以上（`minSdk 32`）

### 步骤
1. 安装 `dexpad-v1.53.apk`；
2. LSPosed 里启用本模块，**作用域勾选「设置」**，重启；
3. 把 `gpm_dex-v1.53.zip` 作为 **KernelSU 模块**安装（或解压到 `/data/adb/modules/gpm_dex/`），重启；
4. 打开 **设置 → 手柄鼠标**，打开开关（通知栏会出现"鼠标模式：开"）；
5. 接上手柄，按 SHARE 切换鼠标模式。

> **late-load KernelSU 的机器注意**：部分机型（含 SM-F9360）的 KernelSU 是 late-load 模式，
> 模块脚本开机不会自动执行，需要手动拉起助手：
> `adb shell "setsid /data/adb/gpm/gpminput --socket /data/data/com.dennis.dexpad/files/gpm.sock &"`
> （也可以用 `release/dexpad_start.sh`）。

## 5. 目录结构

```
project/
  lsp-dexpad/                      LSPosed 模块（Kotlin）
    app/src/main/java/com/dennis/dexpad/
      Hook.java                    注入三星设置页入口
      ConfigActivity.kt            配置页
      ButtonDetailActivity.kt      单键详情（单击/双击/长按/组合）
      EngineService.kt             8 ms 映射循环（光标/滚动/组合/模式）
      ActionRouter.kt              一次性动作执行（手机 / DeX 分支）
      Actions.kt                   动作表（唯一来源）
      Prefs.kt                     偏好与默认值
      RootInput.kt                 助手 socket 客户端
      KeyCodes.kt                  Linux → Android → 按钮名
      DisplayState.kt              显示判定（尺寸/旋转/DeX）
  app/src/main/assets/
      gpminput.c                   root 助手源码（evdev + 协议 + 注入）
      display.c                    显示辅助（DeX 判定 / 分辨率 / 任务栏）
      gpminput                     aarch64 静态二进制（构建产物）
  ksu-module/                      KernelSU 模块（service.sh 守护 + inject.dex）
  padtest/                         独立测试台 App（见下）
docs/                              设计文档 / 测试用例 / 测试结果
release/                           打包产物（APK、模块 zip、助手、校验和）
work/scripts/                      adb 自动化测试脚本
```

## 6. 构建

环境：Linux 或 WSL（Ubuntu 22.04+）、**JDK 17**、Android SDK（platform 36）、NDK 可选。

```bash
# 模块 App
cd project/lsp-dexpad
JAVA_HOME=~/tools/jdk-17 ANDROID_HOME=~/android-sdk \
  ./gradlew --no-daemon assembleRelease     # 产物 app/build/outputs/apk/release/

# root 助手（aarch64 静态）
cd project/app/src/main/assets
aarch64-linux-gnu-gcc -O2 -static -o gpminput gpminput.c display.c -lm
```

测试台 App：

```bash
cd project/padtest
./gradlew assembleDebug
```

## 7. 测试台（project/padtest）

> v1.60 起新增 **`AutoTestActivity`（自动化测试台）**：页面自己判断每个动作是否真的生效
> （指针移动/点击/长按/方向键焦点/滚动/双指缩放/键盘组合/返回键/触摸点击），
> 结果写到 `files/auto-report.json`，配合 `work/scripts/v160_auto_suite.sh` 可一键跑完 24 条用例。
> 详细用例：[docs/TEST-CASES-v1.60.md](docs/TEST-CASES-v1.60.md)。


一个**不需要 root、不需要 LSPosed** 的独立 App，用来验证手柄本身和映射行为：
7 个页面（链路自检 / 光标 / 滚动滑动 / 按键 / 系统动作 / 日志面板 / 结果汇总），
事件全部来自 `dispatchKeyEvent` / `dispatchGenericMotionEvent` / `dispatchTouchEvent`，
可导出 CSV / JSON / TXT 报告。详见 [docs/PADTEST-README.md](docs/PADTEST-README.md)。

> 注：因为助手用 `EVIOCGRAB` 独占手柄，普通 App **看不到**被独占的按键；
> 测试台用「监听窗口」+ 助手日志来验证映射结果。

## 8. 验证方式

所有改动都用 adb 脚本在真机上端到端自测，不靠肉眼：

| 套件 | 内容 | 结果 |
|---|---|---|
| `work/scripts/v145_checklist.sh` | 按键/组合/摇杆/点亮/居中 | 16/16 |
| `work/scripts/v147_checklist.sh` | 自检/双后端/任务范围/延迟 | 9/9 |
| `work/scripts/v153_release_smoke.sh` | **Release 冒烟**：杀应用 / 电源键 / 居中 | 8/8 |
| `work/scripts/padtest_smoke.sh` | 测试台 7 页 + 导出 | 17/17 |

Release v1.53 冒烟实测输出：

```
PASS  版本 1.53            PASS  助手链路
PASS  鼠标模式开            PASS  GUIDE 短按杀应用（进程 -> 已死）
PASS  电源键 (Awake -> Dozing)
PASS  居中命令执行          PASS  居中落点 x≈1319（目标 1280）
PASS  无崩溃                PASS=8 FAIL=0
```

## 9. 已知限制

- **鼠标模式关闭时所有映射按键都不动作**——这是设计（手柄已交还系统）。按 SHARE 打开。
- 助手用 `EVIOCGRAB` 独占手柄，其它 App 看不到手柄输入（这是屏蔽系统默认行为的代价）。
- 本机型上系统**指针坐标读不到可靠值**（`dumpsys input` 的 hover 会坐标对调/超范围），
  所以"是否正好居中"靠肉眼 + 落点日志，偏了请调设置里的「居中增益」。
- `settings global display_size_forced` 会改变指针空间与增益标定，换分辨率后需重新标定。
- 只支持 A/B/X/Y + 双摇杆 + 肩键/扳机 + d-pad 的标准手柄；非标准 HID 需要改 `is_gamepad()`。
- 光标位置由引擎估算（读不到系统真实指针坐标），已做"不出屏"夹取，但长时间使用后仍可能有少量偏差；
  按 **L3** 会把光标和估计值一起拉回中心。
- 未在 DeX 外接屏（display 9）上做完整回归，仅验证了手机屏路径。
- 触摸点击/双指缩放走"默认显示"的虚拟触摸屏，DeX 外接屏上的这两个功能暂未验证。
- 「触摸点击」模式需要系统指针的精确坐标，而本机型读不到可靠值，因此坐标来自引擎估算，
  长距离移动后可能点偏——默认用鼠标事件即可避免。
- 带双击动作的按键（如 R3）单击会延迟一个双击窗口（320 ms）才触发。
- 应用列表只显示带启动入口（LAUNCHER）的应用；系统内部页面需手动输入包名。
- 滑动用的 task 边界有 2 秒缓存；切换应用后最多 2 秒内，非全屏（多窗口）场景的滑动边界可能还是旧的。

## 10. 版本历史

| 版本 | 主要变化 |
|---|---|
| **v1.60** | 修复 HOME/返回/音量/静音/截图/通知栏之前其实注入失败（input 在 root 域 rc=512 → 改进程内 uinput）；主屏改用 KEY_HOMEPAGE；横向翻页方向修正；新增专用测试台 AutoTestActivity + 24 条自动化用例（全部通过） |
| v1.59 | 滑动不再同步 `dumpsys`（task 边界缓存 + 光标坐标随命令下发），滑动准备耗时 200–600ms → 0.4–1.1ms |
| v1.58 | 映射列表精简（46→38）、修复"打开目标应用"选不了 App（Android 11+ 包可见性）、代码审计修 12 处（扳机阈值/居中增益/自定义快捷键/重连竞态/掉线释放等） |
| v1.57 | 左键真正改为鼠标事件（触摸点击变可选）、鼠标设备自动重建、光标不再被推出屏幕 |
| v1.56 | 右摇杆上/下都改为中屏拖动（原来向上拨会触发通知栏）、目标应用改为每槽独立配置、d-pad 按住连发 |
| v1.55 | 左键默认回到鼠标事件（触摸点击改为可选）：触摸点击依赖估算坐标，会点偏 |
| v1.54 | 新增虚拟触摸屏：LT/RT = 以光标为基准的双指缩放（d-pad 模式走 `Ctrl±`）、新增「打开目标应用」动作 |
| v1.53 | GUIDE 短按杀应用（+SIGKILL 兜底）、电源键改走 uinput `KEY_POWER`、L3 改「有界小步归零 + 一步居中」 |
| v1.52 | 居中改到引擎侧一次性相对位移 |
| v1.51 | 回退失效的绝对指针方案；L3 先重建被空闲隐藏的指针 |
| v1.50 | 指针空闲 8 s 自动隐藏（销毁虚拟鼠标设备） |
| v1.49 | 尝试绝对指针一次性居中（该设备不生效，已回退） |
| v1.48 | 修 Y 键锁屏、松手滑行、LB/RB 方向、d-pad 架构、桌面滑动转方向键 |
| v1.44 - v1.47 | 鼠标/滚动/组合键/居中/DeX 判定的基础实现 |

完整说明见 [release/RELEASE-NOTES.md](release/RELEASE-NOTES.md)。

## 11. 免责声明

- 仅供**个人学习与自用**，未声明开源许可证；请勿用于商业分发。
- 需要 root 与 LSPosed，刷写模块/改系统行为有风险，出问题请自行承担。
- 与 `com.pkyul13.gamepadmouse` 的开发者无关，本项目是独立实现（净室复刻）。
- 手柄映射涉及输入注入，部分游戏/应用可能判定为异常输入。
