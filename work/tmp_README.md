# Gamepad Mouse · DeX 复刻版

对 `com.pkyul13.gamepadmouse`（Google Play 上的 "Gamepad mouse" v2.0.2）的**净室复刻**，
重点解决它在 **三星 DeX** 下的核心缺陷：*进入鼠标模式后，手柄仍被 DeX 当成方向键来导航桌面*。

> 分析结论与实现细节：[原版分析](docs/原版分析.md) ｜ [DeX 屏蔽方案](docs/DEX-屏蔽方案.md)

---

## 1. 它做了什么

用一个手柄控制手机 / 平板 / **三星 DeX（外接显示器）**：

* 左摇杆 → 鼠标指针（死区 + 2.5 次方灵敏度曲线，手机 50 px/帧、DeX 35 px/帧，可调）
* A 键 → 单击；按住 >250 ms 或悬停按住 >500 ms → 拖拽
* B 键 → 返回；Y → 播放/暂停；L1/R1 → 上/下一曲；D-Pad 左/右 → 快退/快进
* 右摇杆 → 滚动（原版的"纯水平方向不滚动"怪癖也保留了）
* L3 → 进入/退出鼠标模式（键位可改、可配长按）
* X + 按键 → 8 个可自定义动作槽位（15 种动作：Home/最近/音量/静音/亮度/快进快退/截图/旋转/启动应用/点击指定位置/循环点击…）
* START / SELECT → Home / 最近任务；R3 → 手机 ↔ DeX 显示切换

## 2. DeX 屏蔽（本项目的核心）

| | 原版 | 本复刻 |
|---|---|---|
| DeX 上按键拦截 | ❌ DeX 显示不启用无障碍键盘拦截器，D-Pad 落到桌面 | ✅ root 侧 `EVIOCGRAB` 独占手柄，系统侧**完全收不到** |
| DeX 上点击 | ❌ `dispatchGesture` 注入触摸，桌面只认鼠标 | ✅ `/dev/uinput` 原生鼠标，点击/右键/滚轮全部生效 |
| 手柄数据 | 依赖焦点窗口的 MotionEvent | root 直读 `/dev/input`，不依赖焦点/拦截器 |

实测 A/B（DeX 显示上打开系统设置后注入 `KEY_BACK`）：

```
鼠标模式 OFF → 设置页被返回（系统看得到手柄）
鼠标模式 ON  → 设置页纹丝不动（手柄已被本 App 独占）
```

## 2.5 界面（与原版同构）

左侧抽屉 + 顶栏 + 单 ScrollView 内 7 个页面容器（与原版一样的"切换页面"而非多 Activity）：

1. **Initial Setup** — 三步引导（开无障碍、关电池优化、接手柄）+ Accept（写入 `pref_initial_setup_shown`）
2. **General** — 总开关、切换键（可现场按键捕获）、长按时长、A/B 互换、震动反馈与强度、全部重置
3. **Pointer** — 指针速度（手机/DeX）、指针大小、灵敏度、死区、滚动速度、自动隐藏、光标样式（36 色板 / 自定义 HEX / 导入 PNG）
4. **Root / DeX** — root 独占开关、原生系统指针开关、强制镜像，以及实时状态（无障碍/root helper/活动显示/鼠标模式）
5. **Button Mapping** — 8 个槽位 × 15 种动作，长按改重复间隔，可启动应用/点击位置捕获
6. **Keyboard** — 原版屏幕键盘的参数（键盘覆盖层本身未移植，页面已注明）
7. **About** — 版本、复刻说明、原版商店链接

## 2.5 root 助手常驻（推荐）

`gpminput` 是一个**常驻 daemon**：一个客户端断开后它回到 `accept()` 等下一次连接，
所以 App 重装 / 无障碍服务重启后会自动重连（实测重装 APK 后立刻 `connected to helper socket` + `helper ready`）。

开机自启由 `/data/adb/service.d/99-gpm-helper.sh` 负责（内部 `while true` 守护，助手异常退出 3 秒后自动拉起）。
没装脚本时，App 会退化为 `su -c` 启助手（需要 KernelSU 授权一次）。


## 2.6 按键映射（全键 + 组合）

- **全键映射**：A / B / X / Y / LB / RB / LT / RT / ↑ ↓ ← → / L3 / R3 / START / SELECT / GUIDE
  共 17 个按键，每个都能单独改成任意动作（默认行为、15 个内置动作，外加
  `鼠标左键点击`、`返回`、`切换鼠标模式`、`向上滚`、`向下滚`）。
  存储：`pref_btn_<name>_type` / `pref_btn_<name>_value`。
- **组合按键**：8 组，形式如 `X + A`、`LB + RB`，**组合优先于单键**（所有按键都按住时触发，
  单次按下只触发一次）。存储：`pref_combo_<i>_keys`（`+` 连接）/ `_type` / `_value`。
- 原版那 8 个 `X + 方向/肩键` 槽位仍然保留（Button Mapping 页上半部分），
  新增的"全键映射 / 组合按键"追加在同一个页面的下半部分。

## 2.7 守护与部署

- **KernelSU 模块** `project/ksu-module/`（id `gpm_dex`）：开机同步 `gpminput` + `inject.dex` 到
  `/data/adb/gpm/`，并阻塞式运行助手，退出即重启（socket 现在指向 `com.dennis.dexpad`）。
- **助手内 watchdog**：每 ~2s `waitpid(WNOHANG)` 检查 `ScrollInject` 子进程，死了立即重拉；
  管道写失败（EPIPE）同样重建，避免"注入器一死滚动永久失效"。
- **App 侧重连**：`rootRetry` 每 6/10s 检查助手，断线自动重连并切换 native/gesture 后端。

## 2.8 LSPosed 手柄映射模块（新，推荐）

`project/lsp-dexpad/` 是一个 LSPosed（Vector）模块 **`com.dennis.dexpad`**：

- **入口做进系统设置**：「设置 → Samsung DeX」页里多出「手柄映射」一行（原生 `SecPreference`，
  插在「键盘 / 鼠标和触控板 / S Pen 输入模式」那张卡片的末尾），点开是模块自带的 One UI 风格配置页。
- **映射能力**：手柄 → DeX 鼠标。左摇杆指针、右摇杆滚轮 + **水平滑动**（触摸拖动，PiliPlus 这类
  不认 REL_HWHEEL 的 App 也能翻页；一次推杆一次拖动，回中才再次触发）、**全部 18 个控件**
  （A/B/X/Y、LB/RB、LT/RT、十字键 ↑↓←→、L3/R3、START/SELECT、GUIDE、SHARE）都能单独改映射到：
  鼠标左/右/中键、滚轮上/下/左/右、切换鼠标模式、**放大/缩小（LT/RT 按住连续缩放）**、
  **音量加/减/静音、播放暂停、上一首/下一首**、
  **DeX 窗口动作**（最大化 / 最小化 / 左右对齐 / 关闭窗口 / 开始退出 DeX / 截取窗口截图）、
  多任务界面 / 主屏幕 / 返回 / 通知栏 / **键盘快捷键**（例如 `ctrl+alt+f`、`alt+tab`、`win+d`，在页面的输入框里设置）；
  **8 组组合键**：同时按住 2 个以上按键触发一个动作，默认组合 1 `X+↑`=音量加、组合 2 `X+↓`=音量减、
  组合 3 `X+←`=上一首、组合 4 `X+→`=下一首、**组合 5 `X+LB`=向左滑动、组合 6 `X+RB`=向右滑动**。
  参与组合的键单击动作会挂起到松开（组合命中就取消单击），按住型动作（鼠标键/滚轮/缩放）也会先等 150ms，
  所以「X+↑」只会出音量、「X+LB」只会向左滑动，不会顺带开多任务或滚动；
  默认映射已按用户调好的配置冻结：**SHARE=切换鼠标模式、SELECT=最大化窗口、START=切换软件（Alt+Tab）、
  GUIDE=Alt+F4、LT=缩小、RT=放大、L3=光标居中、B=返回、X=多任务、Y=主屏、A=左键、LB/RB=滚轮**；
  指针速度 30/30、死区 16%、滚动速度 4、**滚动死区 35%**（独立于指针死区，越过后慢滚→推到底快滚）、
  **水平滑动速度 7**（1–10 可调，越慢拖动越久）。
- **引擎**：`EngineService`（前台服务）连接 root 助手 `gpminput` 的 socket，助手继续负责
  `EVIOCGRAB` 独占 + uinput 注入，因此不再需要无障碍服务；检测到有线 DeX 自动进入鼠标模式，
  拔掉显示器自动交还手柄。
- **重启后**：这台机器的 KernelSU 是 late-load 模式，模块开机脚本不会执行，
  需要跑一次 `adb shell sh /data/local/tmp/dexpad_start.sh`（脚本在 `project/lsp-dexpad/tools/`）。

详细架构、注入点、安装命令与真机验证证据见 [LSP-手柄映射](docs/LSP-手柄映射.md)。

## 3. 目录
```
project/                        Android 工程（AGP 9.3.1 / Gradle 9.6.1 / JDK 17，WSL 内构建）
  app/src/main/assets/gpminput.c     原生助手源码（EVIOCGRAB + uinput + 行协议）
  app/src/main/assets/gpminput       预编译 aarch64 静态二进制
  app/src/main/java/com/dennis/gamepadmouse/
      Prefs.kt                       全部偏好键/默认值（与原版键名一致）
      MouseAccessibilityService.kt   鼠标模式开关、输入分发、动作映射
      PointerEngine.kt               光标状态机（gesture / 原生指针两种后端）
      RootInput.kt                   root 助手桥接（su 或 unix socket）
      ActionDispatcher.kt            动作实现（Home/最近/音量/亮度/截图/启动应用…）
      MainActivity.kt                设置界面
      DebugReceiver.kt               调试广播（仅 debug 构建生效）
  lsp-dexpad/                       LSPosed 模块 com.dennis.dexpad
    app/src/main/java/com/dennis/dexpad/
        Hook.java                   往 DexModeSettingsFragment 注入「手柄映射」行
        ConfigActivity.kt           One UI 风格配置页
        EngineService.kt            映射引擎（前台服务）
        RootInput.kt                与 gpminput 的 socket 行协议
    tools/start_helper.sh           重启后启动 root 助手
  ksu-module/                       KernelSU 模块 gpm_dex（守护助手 + 拉起引擎）
  tools/99-gpm-helper.sh             KernelSU/Magisk 开机自启脚本
  tools/install-helper.sh            一键把助手装到 /data/adb 并启动
docs/DEX-屏蔽方案.md                 问题 → 根因 → 方案 → 实测证据
docs/原版分析.md                     逆向分析摘要
docs/LSP-手柄映射.md                 LSP 模块的注入点、引擎、部署与验证记录
work/                              反编译产物与分析文档（不计入应用）
```


## 4. 构建

```bash
# WSL Ubuntu
cd /mnt/e/Dennis/GamePadDex复刻/project
JAVA_HOME=~/tools/jdk-17.0.20.1+1 ANDROID_HOME=~/android-sdk ./gradlew --no-daemon assembleDebug
# → app/build/outputs/apk/debug/app-debug.apk
```

原生助手重新编译（源码改动后）：

```bash
cd /mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets
aarch64-linux-gnu-gcc -O2 -static -o gpminput gpminput.c -lm
```

## 5. 安装 / 使用

```bash
adb install -r project/app/build/outputs/apk/debug/app-debug.apk

# 1) 开启无障碍：设置 → 无障碍 → 已下载的服务 → "Gamepad mouse"
# 2) 装 root 助手（推荐，避免每次启动都要 su 授权）
adb push project/app/src/main/assets/gpminput /data/local/tmp/
adb push project/tools/99-gpm-helper.sh /data/local/tmp/
adb shell sh /data/local/tmp/install-helper.sh
# 3) 打开 App：
#    - Root/DeX 页确认 root helper connected: yes
#    - 打开 "Use the native system pointer"（DeX 下必需）
#    - 按手柄 L3 / App 内按钮进入鼠标模式
```

## 6. 已知限制

* **屏幕键盘覆盖层未移植**（原版支持韩/英/西两벌式屏幕键盘）。UI 中已注明。
* 原生指针模式下，App 无法读回系统光标绝对坐标，因此"点击指定位置"功能在原生模式下仍用触摸注入（普通 App 可用，DeX 桌面点不动）。
* DeX 桌面图标需要**双击**打开；原版/复刻的单击是"选中"。
* 静音/亮度/旋转通过 `AudioManager` / `Settings.System` 实现，需要"修改系统设置"权限（App 内会引导授权）。
* 复刻版使用独立包名 `com.dennis.gamepadmouse`，可与原版共存；原版需自行关闭其无障碍服务以免抢占焦点。
* **LSP 模块重启后需要手动启动一次 root 助手**：本机 KernelSU 是 late-load 模式，模块开机脚本不会执行，
  重启后跑 `adb shell sh /data/local/tmp/dexpad_start.sh` 即可（详见 [LSP-手柄映射](docs/LSP-手柄映射.md)）。
* 装置上的 adb over WiFi（`192.168.10.36:6666`）重启后不会自动恢复，需要重新开启无线调试。
* 旧复刻 App 的无障碍服务已停用；`gpm_dex` 模块现在只服务 `com.dennis.dexpad`。

## 7. 发布 / 备份（v1.21，2026-11-08）

`release/` 下是本次发布物（`SHA256SUMS.txt` 校验，`RELEASE-NOTES.md` 说明）：

| 文件 | 说明 |
|---|---|
| `release/dexpad-v1.21.apk` | LSPosed 模块（`com.dennis.dexpad`，versionCode 22 / versionName 1.21，debug 证书签名，可直接覆盖升级） |
| `release/gpm_dex-v1.21.zip` | KernelSU 模块（`module.prop` v1.21 + `gpminput` + `inject.dex` + 引擎守护），KernelSU 里刷入 |
| `release/gpminput-v1.21` | root 助手二进制（不刷模块时手动放到 `/data/adb/gpm/gpminput`） |
| `release/dexpad_start.sh` | 重启后手动启动助手（late-load KernelSU；含 Doze 白名单） |
| `release/docs/` | 模块说明与 README 快照 |

**本版改动**：代码结构整理（无行为变化）——动作表拆到 `Actions.kt`、屏幕判定/尺寸/旋转拆到 `DisplayState.kt`，新增 `docs/ARCHITECTURE.md`；回归测试全部通过。

**v1.20 已有**：方向键原生转发加了作用域——只有没按住其他按键时才转发；按住 X 等按键时方向键照常上报 App，`X+↑/↓/←/→` 组合键恢复（实测 `mix 1 x+down -> volume_down`）。

**v1.19 已有**：手机（非 DeX）下「关闭当前应用」覆盖两种来源——`close_window` 动作和默认的 GUIDE（Alt+F4 快捷键）；二者都改为 force-stop 前台应用（日志 `alt+f4 -> close app on phone`），DeX 上行为不变（助手 `L`，桌面/SystemUI/本模块跳过），之前降级成 BACK 不会真关应用。

**v1.17 已有**：方向键走**系统原生方向键**——四方向都映射成 `arrow_*` 时引擎发 `I 1`，助手把物理 d-pad
（`ABS_HAT0X/Y` / `BTN_DPAD_*`）转成真实键盘方向键事件（`KEY_UP/DOWN/LEFT/RIGHT`）经虚拟键盘发给系统
（同值去重，一次一格），App 不再注入方向键、也不动光标；摇杆仍归我们（左摇杆光标/右摇杆滑动）。
实测：设置列表按 ↓ 焦点移动一格，助手 `DPAD_NATIVE arrow=108`、App 注入 0 次。

**v1.15 已有**：HDMI 屏幕镜像不再被误判成 DeX——助手用 `dumpsys window windows` 中是否存在 `DexTaskbarWindow`
判断真正的 DeX 模式（并从该窗口取 `mDisplayId`），连接时发 `DEX <id>`（镜像/未接为 -1），之后每 6 秒变化才重发；
引擎以此为准。实测镜像模式下 `dex from helper: display=-1`，X/START/L3 全部落在手机 display 0。

**v1.11 修复**：上下滚动默认改为**真实触摸拖动**（新增「上下滑动用触摸拖动」开关，默认开）——
竖向信息流/短剧页面（ViewPager 式）只有拖动才会吸附翻页，滚轮会把它停在上、下两页各占一半的状态（“卡住、没滑下去”）。
助手新增 `Z` 竖向滑动命令（620 px / 260 ms，一次推杆一次拖动）。

**v1.10 修复**：切换软件按**包名**比较候选，不再按 Activity 组件——之前从「设置」这类多 Activity 应用切换时，
会“切”到同一个 App 的另一个页面（如 `Settings$ConnectionsSettingsActivity` → `SettingsHomepageActivity`），看起来就是没反应。

**v1.9 已有**：每个按键支持「双击动作」，默认双击 X = 切换软件（Alt+Tab）；双击窗口 320 ms，
带双击动作的按键单击会延迟 320 ms 生效；组合键仍优先（组合命中后单击/双击都不误触）。

**v1.8 已有**：组合键并入单键页面（主页面无组合卡片），组合位 24 个。

**v1.7 已有**：组合键修饰用法不再误触单击（按住组合键期间摇杆有输入，松手不再补发该键单击）。

**v1.6 已有**：十字键默认 = 系统方向键（可绑定，发送后 300 ms 内不移动指针）；
**X + 左摇杆 = 精准移动**（指针速度 15%，可调 5–50%）；8 ms 循环按真实 dt 换算速度。

**v1.5 已有**：单键详情页；水平滑动固定 620 px / 260 ms + 冷却；
独立引擎线程 URGENT_DISPLAY / 8 ms、助手 nice -20、swipe/am 异步化。

**后台运行 / 守护**：引擎是 `START_STICKY` 前台服务，关闭配置页/返回/划掉最近任务都不停；
`onTaskRemoved` 会立即重新请求服务；KernelSU 模块的 supervisor 每 8 秒检查 App 进程和
`EngineService`，缺一个就 `am start-foreground-service` 拉起来。实测 `kill -9` 掉 App 后
约 10 秒恢复、L3 居中照常；关闭 DeX 配置窗口后引擎仍在。

备份：`backup/GamePadDex-v1.9-src-*.zip`（源码 + 文档 + release 产物，不含 `work/probe` 截图与构建缓存）。

发布冒烟测试（真机）：双击 X → `double x -> switch_app` + `switch app on display 6`（顶层切到另一个 App）；
单击 X → 320 ms 后 `single recents fired (after double window)` + 打开多任务；
X+LB → `mix 4 x+lb -> wheel_left` + `single for x skipped (mix consumed)`；
X 键详情页显示「双击动作：切换软件（Alt+Tab）」（`work/probe/btn_x6.png`）。
