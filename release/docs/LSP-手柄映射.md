# LSP 手柄映射模块（有线 DeX）

工作目录 `E:\Dennis\GamePadDex复刻`。目标是给**有线 DeX** 增加手柄 → 鼠标的映射能力，
并把配置入口做进系统「Samsung DeX」设置页：设置页里多出「手柄映射」一行，点开是模块
自带的 One UI 风格配置页。

复刻版 App（`com.dennis.gamepadmouse`）仍然保留，但这个模块不再依赖它的无障碍服务：
映射引擎放在新模块 App `com.dennis.dexpad` 里，输入来自 root 助手 `gpminput`
（`EVIOCGRAB` 独占手柄 + `/dev/uinput` 虚拟鼠标），与复刻版使用同一套经过验证的注入通道。

## 1. 交付物

| 路径 | 说明 |
|---|---|
| `project/lsp-dexpad/` | LSPosed（Vector）模块 App（Kotlin + Java hook） |
| `project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/Hook.java` | 往 `DexModeSettingsFragment` 注入「手柄映射」行 |
| `project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ConfigActivity.kt` | 配置页（开关 / 状态 / 指针 / 滚轮 / 按键映射） |
| `project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt` | 映射引擎（前台服务，连接 root 助手） |
| `project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt` | 与 `gpminput` 的行协议桥接（重连 + 设备列表） |
| `project/lsp-dexpad/tools/start_helper.sh` | 重启手机后启动 root 助手的一键脚本 |
| `project/ksu-module/service.sh` | KernelSU 模块（`gpm_dex`）：守护助手（socket 已改为 `com.dennis.dexpad`） |

## 2. 注入系统设置页

反编译 `SecSettings.apk` 后确认：手机上的「Samsung DeX」页由
`com.samsung.android.settings.desktop.DexModeSettingsFragment` 构建。

- `onCreate()` 里 `addPreferencesFromResource(...)`，再用 `getPreferenceScreen().addPreference(...)`
  追加「无线连接」按钮；
- 「键盘 / 鼠标和触控板 / S Pen 输入模式」三行属于同一个 `PreferenceCategory`
  （`PreferenceGroup` 的 `mPreferences` 私有列表）。

注入点选在 `DexModeSettingsFragment#onCreate` 之后：

```java
Object anchor = XposedHelpers.callMethod(screen, "findPreference", "key_mouse_and_trackpad");
Object group  = XposedHelpers.callMethod(anchor, "getParent");   // PreferenceCategory
XposedHelpers.callMethod(group, "addPreference", pref);          // 追加到该卡片末尾
```

`pref` 用 `androidx.preference.SecPreference` 的 `(Context, AttributeSet)` 构造器反射创建
（该类的无参 Context 构造器不存在），标题「手柄映射」、摘要「用手柄控制 DeX 的鼠标指针、左右键和滚轮」，
点击后 `startActivity` 打开 `com.dennis.dexpad/.ConfigActivity`。

配置页**开在设置页所在的显示上**（手机屏）：Hook 里用
`ActivityOptions.makeBasic().setLaunchDisplayId(ctx.getDisplay().getDisplayId())` 显式指定，
否则 Android 可能按当前焦点显示（DeX 显示器）去启动，页面会跑到 DeX 桌面。

早期踩过的坑：直接往 `PreferenceScreen.mPreferences` 里插入会落到页面最后（锚点在子
`PreferenceCategory` 里，不在顶层列表），外观上会跑到「无线连接」按钮后面。

## 3. 配置页

`ConfigActivity` 用代码构建 One UI 风格页面（黑底、圆角卡片、行分隔线）：

- **常规**：启用手柄映射、连接有线 DeX 时自动开启、**手机上也启用（非 DeX，默认开）**；
- **状态**：Root 助手连接、手柄列表、鼠标模式、有线 DeX、指针位置（调试用，点击时显示坐标）；
- **指针**：DeX 指针速度、手机指针速度、摇杆死区、**精准移动（X + 左摇杆，5%–50%，默认 15%）**、
  **方向键同时移动光标（默认关）**、**方向键移动步长（8–120 px，默认 36）**；
- **滚轮**：滚动速度（1–10）、**滚动死区（5%–60%，默认 35%）**、**水平滑动速度（1–10，默认 7）**、
  **上下滑动用触摸拖动（默认开）**、反向滚动；**右摇杆左右 = 水平滑动**（注入真实触摸拖动：
  很多 App（PiliPlus 等分页/列表）不响应 REL_HWHEEL，触摸拖动才有效；每次推杆触发一次**固定**拖动
  **620 px / 260 ms**（约 2380 px/s，不再随力度改距离，否则 PiliPlus 的翻页动画会时快时慢），
  手势结束后冷却 170 ms 才允许下一次，必须回中才会再次触发，一次推杆切换一页）；
- **按键映射**：**全部 18 个控件**都能单独映射：
  A / B / X / Y、LB / RB、**LT / RT（扳机）**、**十字键 ↑↓←→**、L3 / R3、START / SELECT、**GUIDE（Xbox 键）**、
  **SHARE（分享键）**。
  可映射到鼠标左键 / 右键 / 中键 / **向上/向下/向左/向右滚动（按住持续）** / **向上/向下/向左/向右滑动+滚动** /
**向上滑动 / 向下滑动 / 向左滑动 / 向右滑动** /
**缓慢向上/向下/向左/向右滑动** / 切换鼠标模式 /
  **放大 / 缩小（Ctrl + + / Ctrl + -，按住 LT/RT 连续缩放）** /
  **音量增加 / 音量减小 / 静音 / 播放暂停 / 上一首 / 下一首** /
  **DeX 窗口快捷动作（最大化窗口 / 最小化窗口 / 向左对齐窗口 / 向右对齐窗口 / 关闭当前窗口 /
  开始或退出 DeX 模式 / 截取窗口截图）** / **光标居中** / **切换软件（Alt+Tab）** /
  **方向键 ↑/↓/←/→（系统方向键，移动焦点/选区，不动指针）** /
  多任务界面 / 主屏幕 / 返回 / 通知栏 / 键盘快捷键 / 无。
  十字键默认就是这四个方向键（按 D-pad 只移动焦点/选区，鼠标指针不动；随后推动摇杆移动指针时，
  悬停会把焦点交回光标区域，这是系统行为）。
  选「键盘快捷键」会弹出输入框（例如 `ctrl+alt+f`、`alt+tab`、`win+d`、`f5`），行摘要显示成「键盘快捷键（Ctrl + Alt + F）」。
  「切换软件」在 DeX 里不能用注入 Alt+Tab 实现（DeX 会忽略注入的 Alt+Tab 组合），
  助手改为读 `dumpsys activity activities` 找出本屏的另一个 App，用 `am start -n <component> --display <id>` 把它的任务带到前台。
  点按键行的流程：单击一行进入**按键详情页**——上半部分是「单击动作」和「双击动作」（320 ms 内连按两下），
  下半部分列出所有「此键 + 其它键」的组合（可点开改键位/动作、长按删除），底部「添加组合…」选其它按键 + 动作即新增一个组合。
  带双击动作的按键，单击会等 320 ms 再触发；320 ms 内再按一次则取消单击、只触发双击。默认只有 X 设了双击（切换软件）。
- **组合键**：**24 个槽位**，每个槽位可选 2 个以上按键同时按住触发一个动作（例如 `X + 十字键 ↑` = 音量增加）。
  组合不再单独占一张卡：主页面只列按键，组合统一放在**按键详情页**里（点 X 就看到所有 `X+…` 组合，
  点 LB 也能看到 `X+LB` 这类组合，两个方向都能管理）。
  默认：组合 1 `X+↑` 音量增加、组合 2 `X+↓` 音量减小、组合 3 `X+←` 上一首、组合 4 `X+→` 下一首、
  组合 5 `X+LB` 向左滚动、组合 6 `X+RB` 向右滚动，其余未设置。默认 LB 向下滚动、RB 向上滚动。
  参与组合的按键单击仍然会触发它自己的映射（按下时先挂起，松开才触发；组合一旦命中就取消该键的单击，
  所以「X+↑」只会出音量，不会先开多任务）。

DeX 窗口快捷动作来自 DeX 的「键盘快捷键」帮助页（`work/probe/dex_kb4.png` 等）：
最大化 = CMD + =、最小化 = CMD + -、向左/右对齐 = CMD + [ / ]、关闭 = ALT + F4、
开始/退出 DeX = CMD + W、截取窗口截图 = ALT + PRTSCN（CMD 即 Meta/Windows 键，Android keycode 117）。

**实测 DeX 会忽略注入的 CMD 组合键**（`input -d 6 keycombination 117 70/69/71/72` 窗口都不变；ALT+F4 关闭有效），
所以「最大化窗口 / 向左对齐 / 向右对齐」改成助手直接调 `am task resize`：
找当前焦点 task，按 DeX 分辨率减去任务栏高度（读 `dumpsys window windows` 里 `DexTaskbarWindow` 的 `fillxNN`，
2560×1600 − 56 = 1544）设置 bounds——最大化 `0,0,2560,1544`、左对齐 `0,0,1280,1544`、右对齐 `1280,0,2560,1544`。
「最小化窗口」「开始/退出 DeX 模式」仍用 CMD + - / CMD + W 注入（这两个在 DeX 上可能无效）。

默认映射（已按用户调好的配置冻结为代码默认值）：
A=左键、B=返回、X=多任务界面、Y=主屏幕、LB=滚轮上、RB=滚轮下、**SHARE=切换鼠标模式**、
**LT=缩小、RT=放大（按住连续缩放）**、**L3=光标居中**、**START=切换软件（Alt+Tab，等价于在已运行 App 间切换）**、
**SELECT=最大化窗口**、**GUIDE=键盘快捷键（Alt+F4）**、**十字键 ↑↓←→=系统方向键**、R3=无；
**双击动作默认只有 X = 切换软件（Alt+Tab）**，其余按键不设双击；
**X + 左摇杆 = 精准移动**（指针速度降到 15%，可在「指针」卡用「精准移动（X+左摇杆）」滑块调 5–50%）；
指针速度 DeX/手机=30 px/帧、死区 16%、滚动速度 4。

按键来源：A/B/X/Y/LB/RB/L3/R3/START/SELECT/GUIDE 走 `KEY` 事件（Android keycode 96..110）；
**SHARE 键在内核里是 `KEY_RECORD`（167）**，KeyMap 里转成 `KEYCODE_MEDIA_RECORD`（130）后当普通按键处理；
**十字键走 HAT 轴（AXIS_HAT_X/Y，±1，>0.5 视为按下）**，
**LT/RT 走扳机轴（AXIS_LTRIGGER/RTRIGGER，或 GAS/BRAKE，>0.5 视为按下）**，两者都在引擎里做边沿检测后走和按键相同的映射路径；
鼠标模式关闭或助手断线时会释放所有按住的鼠标键，避免卡键。

## 4. 映射引擎

- `EngineService`（前台服务，`specialUse`）连接 `/data/data/com.dennis.dexpad/files/gpm.sock`，
  断线每 1.5 s 重连；
- 助手在会话开始时 `EVIOCGRAB` 独占手柄，因此 DeX / GameTools / 前台 App 收不到手柄事件；
- 引擎映射循环跑在独立线程 `dexpad-engine`（**URGENT_DISPLAY 优先级，nice -8**），**每 8 ms 一步**（旧版在主线程 16 ms，
  主线程忙时体感就是输入延迟）；助手 `gpminput` 以 **nice -20** 运行；
- 每 8 ms 一步：左摇杆 → `M dx dy`（死区 + 2.5 次方曲线，DeX 用 `speedDex`、手机用 `speedPhone`）；
  按真实 elapsed 换算 `dtScale`，所以 8 ms 循环下速度与原来 16 ms 手感一致；
  按住 X 时左摇杆进入**精准移动**（速度 × `precisionScale%`，默认 15%）；
  右摇杆上下 → **默认竖向触摸拖动** `Z <display> <dy> <ms> <maxX> <maxY>`（助手执行
  `input -d <display> swipe ...` 竖向拖动，固定 620 px / 260 ms，一次推杆一次拖动、回中才再次触发）；
  关掉「上下滑动用触摸拖动」后改为 `S ±n`（REL_WHEEL）；右摇杆左右 → `V <display> <dx> <ms> <maxX> <maxY>`（水平触摸拖动）；
  滚轮用**独立的「滚动死区」**（默认 35%，
  比指针死区 16% 更大，摇杆漂移/轻碰不会自己滚动），越过死区后把剩余行程重映射到 0–1
  （`scrollCurve`，γ=0.7：刚过死区慢滚、推到底快滚）；
  **为什么默认用拖动**：竖向信息流/短剧页面是 ViewPager 式，只有真实拖动才会吸附翻页；
  滚轮会把页面停在上、下两页各占一半的位置（截图里“卡住、没滑下去”）。
- A/B/X 按下给 `B 0/1/2 1`、松开给 `0`，按住 A 同时移动 = 拖拽；
- 「向上/向下/向左/向右滑动+滚动」先执行一次短快滑（25% 屏 / 120 ms），再进入持续滚动直到松手——用于那些只有滑动才能激活滚动的页面。
  注意方向：向上滑 → 接向下滚；向下滑 → 接向上滚（滑动的方向是手指方向，滚动是内容方向，两者相反）；左右同理。
- 「向上/向下/向左/向右滚动」是**按住持续**动作：按下立即生效并每 80 ms 重复（左右方向每 140 ms 发一次短触摸拖动），
  松开才停；它们不作为组合首位、不支持双击，可作为组合次位（如 X+LB）。顺序冲突时以先按下的键为准。
- 「向上/向下/向左/向右滑动」动作发一次统一触摸拖动
  （竖向 50% 屏高 200 ms，下滑 30%→80%、上滑 70%→20%；横向 40% 屏宽 200 ms，右滑 25% 起点、左滑 75% 起点）；
- 「缓慢××滑动」不是慢拖，而是**短距离快滑**：位移 25% 屏高/屏宽（320–900 px）、时长 120 ms
  （实测这是能真正触发抽屉/通知栏的最小步长；再短就只弹回）；竖向从 40%（下）/60%（上）开始，
  横向从 40%（右）/60%（左）开始；
- 「放大/缩小」（默认 LT=缩小、RT=放大）按住时每 250 ms 注入一次 `Ctrl + +` / `Ctrl + -`，松开停止；
- 水平滑动：`V <display> <dx> <ms> <maxX> <maxY>` → 助手取**当前焦点 task 的 mBounds**（取 topResumedActivity
  前最近的 mBounds；之前取整个 dump 的第一个会拿到 root task 全屏 bounds，指针在桌面时锚点就落错），
  「指针在任务内则用指针、否则任务中心」注入 `input swipe`；手势固定 620 px / 260 ms，冷却 170 ms；
  助手把 `input swipe` / `am start` / `am task resize` 都放进异步子进程，命令循环不会被 300+ ms 的系统调用堵住；
- 「光标居中」：助手 `O <maxX> <maxY> [park] [rotation]`（引擎传入当前屏分辨率，中心 = 分辨率/2）：
  DeX 上读当前位置（`dumpsys input` hoveringPointers），按实测增益（约 1.8×）一次移动，300 ms 后误差 >40 px 才补一步；
  **手机上用 park 模式**（手机 hover 坐标空间与逻辑分辨率可能不一致）：先顶到角落夹成 (0,0)，
  再按显示旋转（0/90/180/270）和增益一次跳到中心，需要时补一步——实测 rotation=1、2560×1600 时
  `CENTER(park) -> 1275,802 (target 1280,800)`；
  居中瞬间引擎会**锁定摇杆输入直到回中**（最多 3 s）；
- **手机 / DeX 统一寻址**：引擎用 `activeDisplay()`：有 DeX 用 DeX 屏，否则用手机屏（display 0），
  指针速度也按屏切换；**「手机上也启用（非 DeX）」默认开**，不接 DeX 也能映射；
  **DeX 判定不用「有没有外接屏」**（屏幕镜像也会插 HDMI）：助手检查 `dumpsys window windows` 里是否有
  `DexTaskbarWindow` 并取其 `mDisplayId`，连接时发 `DEX <id>`（镜像/未接为 `-1`），之后每 6 秒变化才重发；
  引擎收到后以它为准（`dexFromHelper`），动作/速度/模式跟着切；
- 「切换软件」：助手 `Y <display>`：读 `dumpsys activity recents`（最近使用优先）里的 `mActivityComponent` 与
  `rootTaskId`，只保留 **root task 在 DeX display 上**的 App（跳过桌面/SystemUI，手机屏独有的 App 不会被拉过来），
  取「最近使用且**包名不同**于当前 App」的那个，`am start -n <component> --display <id>` 把任务带到前台；
  **必须按包名比较**：同一个 App 常有多个 Activity（如 Settings 的 `Settings$ConnectionsSettingsActivity`
  与 `SettingsHomepageActivity`），按组件比较会“切”到同 App 的另一个页面，看起来就是没切换；
  在桌面（launcher 前台）按也能切回最近用的 DeX App（DeX 会忽略注入的 Alt+Tab）；
- **窗口动作**：最大化/左对齐/右对齐 = 助手 `A <display> <max|left|right>` → 找当前焦点 task 后
  `am task resize <taskId> <l> <t> <r> <b>`（DeX 忽略注入的 CMD 组合键，这是等效实现）；
  **手机上自动降级**：最大化/对齐/DeX 切换跳过，最小化→HOME，**关闭窗口→ `L`（force-stop 前台应用）**，截图→SYSRQ；
  **键盘快捷键里的 ALT+F4 在手机上也改走 `L`**（日志 `alt+f4 -> close app on phone`），DeX 上仍注入 ALT+F4；
- **组合键**：24 个槽位，引擎在按键按下时检查「所有槽位按键都在按住」，命中即触发槽位动作；
  参与组合的按键单击动作会挂起到「松开」：组合在按住期间任意时刻命中就取消该键的单击，否则松手时补发单击；
  **修饰用法也会取消单击**：按住这种键的同时只要摇杆有输入（左摇杆移动 / 右摇杆滚轮 / 水平滑动），
  就把它视为“当修饰键用”（例如 X+左摇杆精准移动），松手不再补发单击——
  否则会出现“按住 X 推左摇杆，松手却打开了多任务”的误触；单独点按该键仍正常触发；
  **按住型动作**（鼠标键/滚轮/缩放）作为组合键时先等 150 ms 再开始，组合命中就取消——`X+LB` 只出「向左滑动」，
  不会顺带滚动（LB 单独按住超过 150 ms 仍是滚轮）；
- 「切换鼠标模式」（默认绑在 SHARE 键上）= `G`（重新独占）/ `U`（交还给系统）；
- **系统动作/快捷键**（一次性，按下即触发，注入目标为当前 DeX 屏）：
  - 方向键（默认绑十字键）：**原生转发（有作用域）**——四个方向都映射为 `arrow_*` 时，助手把物理 d-pad
    （`ABS_HAT0X/Y` / `BTN_DPAD_*`）转成**真实键盘方向键事件**（`KEY_UP/DOWN/LEFT/RIGHT`），用助手的虚拟键盘发给系统
    （`I <0|1>`；日志 `PAD 108`），同值去重、一次一格；**但只要还有别的按键按住（如 X），就不转发**，
    方向键照常上报 App，保证 `X+↑/↓/←/→` 组合键能匹配（日志 `mix 1 x+down -> volume_down`）。
    系统收到的是原生方向键：DeX/应用里就是原生焦点导航；App 收到方向键时也不动光标（临时退出鼠标模式）。
    **A 键跟随焦点**：收到 `PAD`（助手转发）或 App 自己注入方向键时进入 nativeNav，A（`left_click`）改为发 `KEYCODE_DPAD_CENTER` 激活焦点控件
    （日志 `A -> DPAD_CENTER (native nav)`）；推摇杆（相对进入时的位置有位移）退出 nativeNav，A 恢复鼠标左键。
    摇杆仍归模块（左摇杆光标/右摇杆滑动），推摇杆即回鼠标模式。任一方向改成别的动作时助手自动关转发，回落到 App 注入；
    「方向键同时移动光标」默认关；原生转发开启时 App 根本收不到 d-pad，这一项只在回落注入模式下生效；
  - 多任务界面 / 主屏幕 / 返回：`D <display> <KeyEvent>` → 助手执行 `input -d <display> keyevent <code>`
    （187 / 3 / 4）；
  - 通知栏：`N` → 助手执行 `cmd statusbar expand-notifications`（手机侧通知栏）；
  - 键盘快捷键：`C <display> <androidKeyCode...>` → 助手执行 `input -d <display> keycombination <codes>`，
    例如 `ctrl+a` 解析成 `[113, 29]`、`ctrl+alt+f` 解析成 `[113, 57, 34]`；快捷键名→Android keycode
    的解析在 `KeyCombo.kt`（ctrl/shift/alt/meta/win、a-z、0-9、f1-f12、tab/space/enter/esc/方向键…）；
  - DeX 窗口快捷动作（同样走 `C` 命令）：最大化 `[117,70]`、最小化 `[117,69]`、左对齐 `[117,71]`、
    右对齐 `[117,72]`、关闭 `[57,134]`（ALT+F4）、开始/退出 DeX `[117,51]`、截取窗口截图 `[57,120]`（ALT+PRTSCN）；
  - 放大 / 缩小：`[113,81]`（Ctrl + =） / `[113,69]`（Ctrl + -）；
  - 音量/媒体：音量加 `24`、音量减 `25`、静音 `164`、播放暂停 `85`、下一首 `87`、上一首 `88`（`D` 命令，keyevent）；
- `autoDex` 打开时：检测到外接显示（且名字不同于内置屏）即自动进入鼠标模式，
  拔掉后自动交还手柄——内置折叠屏也带 `FLAG_PRESENTATION`，必须用 display name 区分。

## 5. 安装 / 部署

```bash
# 构建（WSL）
cd /mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad
JAVA_HOME=~/tools/jdk-17.0.20.1+1 ANDROID_HOME=~/android-sdk ./gradlew --no-daemon --no-build-cache assembleDebug

# 安装 + 在 Vector 里启用并设置作用域
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell /data/adb/lspd/cli modules enable com.dennis.dexpad
adb shell /data/adb/lspd/cli scope add com.dennis.dexpad com.android.settings/0

# 重启 Settings 让 hook 生效
adb shell am force-stop com.android.settings
adb shell am start -n 'com.android.settings/.Settings$DexModeActivity'
```

root 助手（本机 KernelSU 为 late-load 模式，模块开机脚本不会执行，重启后需要手动跑一次）：

```bash
adb shell sh /data/local/tmp/dexpad_start.sh     # 脚本在 project/lsp-dexpad/tools/start_helper.sh
```

KSU 模块 `gpm_dex` 的 `service.sh` 已改为：
- 目标包名 `com.dennis.dexpad`、socket `/data/data/com.dennis.dexpad/files/gpm.sock`；
- 自身 `setsid` detach 成新会话再循环守护（避免 ksud 的阶段退出把助手一起收掉）；
- 用 `pgrep -f 'gpm_dex/service.sh --supervisor'` 做单实例；
- 开机完成后 `am start-foreground-service` 拉起映射引擎。

root 助手在原有命令之外新增了 `C`（键盘组合）和 `N`（通知栏）两个命令，改的是
`project/app/src/main/assets/gpminput.c`，需要重新交叉编译并同步到三处：
`project/ksu-module/gpminput`、`project/lsp-dexpad/app/src/main/assets/gpminput`、
设备上的 `/data/adb/modules/gpm_dex/gpminput` 与 `/data/adb/gpm/gpminput`（改完用 `dexpad_start.sh` 重启助手）。

## 6. 真机验证（SM-F9360 / Android 16 / DeX 2560×1600）

| 用例 | 证据 |
|---|---|
| 设置页出现入口 | 「手柄映射」行位于「S Pen 输入模式」下方、同一张卡片内（`work/probe/now_p0e.png`） |
| 点击进入配置页（手机屏） | 顶层 Activity 变为 `com.dennis.dexpad/.ConfigActivity`，页面开在手机显示上（`work/probe/final_phone_cfg.png`） |
| DeX 识别 | 日志 `displays: [0 内置屏幕 …][6 HDMI 屏幕 …] dex=true`，mouse mode ON |
| 指针移动 | `dumpsys input` 中 `hoveringPointers=[Pointer(id=0, MOUSE) at (x, y)]` 随摇杆变化（232,53 → 1488,814） |
| 左键 | `touch src=12290 action=0 x=1323 y=814 buttons=1`（ACTION_UP buttons=0） |
| 右键 | `touch src=12290 action=0 buttons=2` |
| 滚轮 | `generic action=8 vs=-1.0` 连续事件 + 页面实际滚动（`work/probe/w_before.png` / `w_after.png`） |
| 滚动死区（35%） | 右摇杆偏转 ≤ 0.35 → 虚拟鼠标无 `REL_WHEEL`（0.20/0.30/0.35 均为 0 步）；0.40 → 约 3 步/1.2 s、0.80 → 约 8 步、推到底更快（`work/scripts/dexpad_test_scroll.sh`） |
| 滚动死区可调 | `--es pref scroll_deadzone --ei ival 500` 后 0.40/0.50 均为 0 步，0.60 → 3 步；页面「滚动死区」滑块 5%–60% 可直接调（`work/probe/wheel_card2.png`） |
| 独占 A/B | 鼠标模式 ON 时注入 BACK：DeX 上配置页不退出；L3 切到 OFF 再注入 BACK：配置页被返回（top 变 PiliPlus） |
| 多任务界面 | 把 X 映射成「多任务界面」，按 X → 引擎日志 `recents on display 6`，DeX 顶层 Activity 变为 `com.android.quickstep.RecentsActivity` |
| 主屏幕 | 把 START 映射成「主屏幕」，按 START → `home on display 6`，DeX 顶层变 `SecondaryLauncher` |
| 返回 | 把 SELECT 映射成「返回」，按 SELECT → DeX 上当前配置页被关闭（顶层变 PiliPlus） |
| 通知栏 | 把 LB 映射成「通知栏」，按 LB → 手机通知栏展开（截图 `work/probe/notif.png`） |
| 键盘快捷键 | Y 设为 `ctrl+a`，按 Y → `key combo 'ctrl+a' -> [113, 29] on display 6`；DeX 上前台 Activity 收到 `key code=29 meta=12288`（CTRL_ON）；X 设为 `ctrl+alt+f` → `[113, 57, 34]` |
| 快捷键编辑 UI | 动作列表包含新动作，选「键盘快捷键」弹出输入框（`work/probe/dlg2.png` / `work/probe/edit.png`） |
| 全键覆盖 | 映射页列出全部 18 个控件（`work/probe/rows_mid.png` / `work/probe/share_row2.png`） |
| 十字键（HAT 轴） | down→多任务：`button down down=true mapped=recents` + `recents on display 6`，DeX 顶层变 RecentsActivity；up→主屏幕：`AX 1 16 -1.0000` + `button up … mapped=home` + `KEYON 6 3`，DeX 顶层变 SecondaryLauncher |
| LT（扳机轴） | lt→ctrl+a：`button lt down=true mapped=key_combo` → `[113, 29]`，DeX 前台 Activity 收到 `key code=29 meta=12288` |
| RT（扳机轴） | rt→返回：`button rt down=false mapped=back`，DeX 上的配置页被关闭 |
| R3 / GUIDE | R3→中键 `button r3 … mapped=middle_click`；GUIDE→切换 `button guide … mapped=toggle_mouse` → `mouse mode OFF` |
| SHARE | 手柄的 KEY_RECORD(167) 在 KeyMap 里转 MEDIA_RECORD(130)；默认映射=切换鼠标模式：按 SHARE → `button share down=true mapped=toggle_mouse` → `mouse mode OFF`，再按一次 → `mouse mode ON` |
| SHARE→多任务（可改映射） | `button share down=true mapped=recents` + `recents on display 6`，DeX 顶层变 RecentsActivity |
| 最大化窗口（SELECT 默认） | PiliPlus 窗口 `Rect(1290,300-2300,1200)` → 按 SELECT → 助手 `ARRANGE max task 381 -> 0,0,2560,1544 rc=0`，窗口变 `Rect(0,0-2560,1544)`（DeX 忽略注入的 CMD+=，改用 `am task resize`） |
| 左/右对齐窗口 | r3→左/右对齐后按键：窗口分别变 `Rect(0,0-1274,1544)` / `Rect(1286,0-2560,1544)` |
| 最小化 / 关闭窗口 | `minimize -> [117, 69]` 后窗口消失、DeX 顶层回 launcher；`close window -> [57, 134]` 同样关闭窗口 |
| 截取窗口截图 | `screenshot -> [57, 120]`（ALT+PRTSCN）后 `/sdcard/DCIM/Screenshots/Screenshot_20261106_233256.jpg` 生成 |
| 动作列表 UI | 动作选择里出现「最大化窗口 / 最小化窗口 / 向左对齐窗口 / 向右对齐窗口 / 关闭当前窗口 / 开始或退出 DeX 模式 / 截取窗口截图」（`work/probe/actions1.png`）；SELECT 行显示「最大化窗口」（`work/probe/final_sel.png`） |
| 水平滑动 | 右摇杆左右 → 助手日志 `AX 1 12 0.9156`，随后 `SWIPE 6 1279,777 -> 679 (task 588..1970) rc=0`；PiliPlus 窗口内一次推杆 推荐→热门，反向推杆回到 推荐（`work/probe/g1.png` / `g2.png` / `g3.png`） |
| 放大 / 缩小（LT/RT 默认） | RT 按住 → `zoom in -> [113, 81]` 每 250 ms 一次；DeX 前台收到 `key code=81 meta=12288`；三星浏览器里页面文字实际变大（`work/probe/z7.png` → `z8.png`）。LT → `zoom out -> [113, 69]`、`key code=69 meta=12288` |
| 组合键默认值 | 主页面不再有组合卡片；点 X 进入「X 键」详情页，列出 `X+↑ 音量增加 / X+↓ 音量减小 / X+← 上一首 / X+→ 下一首 / X+LB 向左滑动 / X+RB 向右滑动 / X+Y`（`work/probe/btn_x5.png`），组合编辑器多选按键（`work/probe/combo_edit.png`） |
| 组合键生效 | X+↑ → `mix 0 x+up -> volume_up` + `volume up on display 6`，`cmd media_session volume --get` 从 9 变 10；X+↓ → `mix 1 x+down -> volume_down`，10 变 9 |
| X+LB / X+RB | X+LB → `mix 4 x+lb -> wheel_left` + `SWIPE … -> 1818`（dx 为正=上一页）；X+RB → `mix 5 x+rb -> wheel_right` + `SWIPE … -> 268`（dx 为负=下一页） |
| START 切换软件 | DeX 上两个 App 交替：ConfigActivity → PiliPlus → ConfigActivity；桌面（launcher 前台）按 START → 回到最近的 DeX App `com.dennis.dexpad/.ConfigActivity`。手机屏独有的 Settings（display 0）不会出现在候选中：`SWITCH com.dennis.dexpad/.ConfigActivity -> com.example.piliplus/.MainActivity rc=0`（候选取 recents 里 root task 在 display 6 的 App） |
| 光标居中（L3 默认） | 指针 `(1411,722)` → 按 L3 → 日志 `CENTER 1411,722 -> 1281,799`（一次移动，无 step）；指针 `(2559,1599)` → `CENTER … -> 1280,799`。**摇杆保持偏转时按 L3**：居中后持续采样 hoveringPointers 一直稳定在 `(1275.97, 799.952)`，直到摇杆松开也没有二次跳动（引擎居中后锁定摇杆直到回中，最多 3 s） |
| X+LB / X+RB 组合 | X+LB → `mix 4 x+lb -> wheel_right` + `SWIPE … -> 678`（dx 为负=下一页），没有 wheel 滚动；X+RB → `mix 5 x+rb -> wheel_left` + `SWIPE … -> 2228`（dx 为正=上一页）（页面组合 5/6 见 `work/probe/combos2.png` 之前的版本，默认已改为 LB/RB） |
| 水平滑动速度 | 手势固定 620 px / 260 ms（约 2380 px/s），推杆距离不再影响速度；助手 SWIPE 日志 `167,534 -> 787`（dx=620）；手势后 170 ms 冷却 |
| 上下滑动（触摸拖动） | 番茄短剧页推一下右摇杆：`SWIPE 6 1366,1114 -> 1366,494 (task 0..2560 / 0..1544)`，页面完整翻到下一集（修复前滚轮会停在两页之间半页状态）；截图 `work/probe/v2.png` |
| 手机（非 DeX）模式 | 手机 display 0（2560×1600、rotation=1）：SELECT → `maximize skipped on phone`；X → `recents on display 0` + `KEYON 0 187`；START → `switch app on display 0`；右摇杆 → `SWIPE 0 452,1158 -> 452,538`；L3 → `CENTER(park) -> 1275,802 (target 1280,800)`，hoveringPointers `(1275.47, 802.96)` |
| HDMI 但屏幕镜像 | 助手 `DEX -1`（无 `DexTaskbarWindow`）→ 按 X `recents on display 0`、START `switch app on display 0`、L3 park 居中；以前会误判 DeX 发到 display 11 |
| 方向键（原生转发） | 四方向=`arrow_*` → 助手 `PAD <key>`；按一下 ↓ 设置列表焦点移动一格；随后按 A → `A -> DPAD_CENTER (native nav)` 打开焦点项；推一下左摇杆再按 A → `left button down`（鼠标点击） |
| 方向键（D-pad 默认） | 按十字键 ↑：`button up down mapped=arrow_up` → `arrow key 19 on display 6` → 助手 `KEYON 6 19 rc=0`；按 ↓：`arrow key 20` → `KEYON 6 20`（方向键异步注入，发送后 300 ms 内指针不动） |
| 精准移动（X+左摇杆） | 同一位置、同样推杆 800 ms：普通 `(1282.6,815.8) → (1854.1,815.8)`（Δ571 px）；按住 X 后 `(1244.0,801.1) → (1328.6,801.1)`（Δ84.5 px ≈ 15%） |
| 单键详情页 | 点 X 行进入「X 键」页：上半部分单击动作，下半部分列出 `X+↑/↓/←/→/LB/RB` 组合，底部「添加组合…」；实测新增 `x+y` 组合写入 `mix_8_keys=x+y`、`mix_8_action=wheel_right`，按 X+Y → `mix 8 x+y -> wheel_right` + `SWIPE … -> 20`（`work/probe/btn_x3.png`） |
| 响应优先级 | `dexpad-engine` 线程 nice **-8**（URGENT_DISPLAY）、8 ms 周期；`gpminput` nice **-20**；`input swipe`/`am start`/`am task resize` 走异步子进程（助手日志 `SWIPE … async` 后跟 `rc=0`，命令循环不阻塞） |
| 组合不误触单击 | 先按 X 停 0.5 s 再按 ↑（故意放慢）→ 日志 `single recents deferred (mix key x)` → `mix 0 x+up -> volume_up`，音量 +1，DeX 顶层不变（没有先开多任务）；把 ↑ 也映射成主屏幕再测，同样只出音量、不出主屏幕（`work/scripts/dexpad_test_combo_slow.sh`） |
| 单键与组合共存 | X 单击（无组合）→ 日志 `single recents deferred` → 松开 `single recents fired on release` → `recents on display 6`（顶层变 RecentsActivity）；组合命中时日志 `single recents cancelled (consumed by mix)`，不会再触发单击 |
| 修饰键不误触 | 按住 X 并推左摇杆：`single recents deferred (mix key x)` → `single deferred for x cancelled (stick used while held)` → 松开 `single recents cancelled (button was used as modifier)`，顶层保持 PiliPlus、没有打开多任务；随后单独点按 X 仍然 `single recents fired on release` → 打开多任务 |
| 双击 X（默认切换软件） | `vgpad double 307 60 90`：两次按下日志 → `double x -> switch_app` + `switch app on display 6`，顶层从 PiliPlus 切到另一个 App；单击 X → 320 ms 后 `single recents fired (after double window)` + 打开多任务；X+LB 组合 → `mix 4 x+lb -> wheel_left` + `single for x skipped (mix consumed)`，单击被抑制 |
| 切换软件跨包名 | 在 Settings(Connections) 双击 X → `SWITCH com.android.settings/.Settings$ConnectionsSettingsActivity -> com.example.piliplus/.MainActivity rc=0`，顶层变 PiliPlus；再双击 → `SWITCH com.example.piliplus/.MainActivity -> com.android.settings/.homepage.SettingsHomepageActivity rc=0`，切回设置（按包名比较，不会切到同 App 的另一个页面） |

测试辅助脚本在 `work/scripts/`：`dexpad_stick.sh`（虚拟手柄推摇杆）、`dexpad_ptr.sh`（读指针坐标）、
`dexpad_nudge.sh`（按轴微调并读坐标）、`dexpad_start.sh`（启动助手）、`dexpad_open_settings.sh`、
`dexpad_restore_map.sh`（用 DebugReceiver 批量设映射）。调试广播（debug 构建）：
`am broadcast -a com.dennis.dexpad.DEBUG -n com.dennis.dexpad/.DebugReceiver --es button x --es mapped key_combo --es value ctrl+alt+f`。

## 7. 已知限制 / 注意

- **KernelSU late-load**：`ksud services` 不会执行模块脚本（用 marker 脚本实测确认），
  所以重启后 `gpm_dex/service.sh` 不会自动跑；需要 `dexpad_start.sh` 手动启动一次。
- **adb over WiFi**：这台机器重启后 6666 端口不会自己回来，需要手机上重新开启无线调试。
- **指针"消失"**：DeX 显示器断开或指针停在任务栏 / 窗口标题栏上时，点击会被系统窗口吃掉，
  看起来像"没反应"；确认 DeX 已连接、指针在应用内容区。
- 滚轮步进和指针速度需要按手感调（默认滚动速度 3 ≈ 8 格/秒，DeX 指针 35 px/帧）。
- 复刻版 App 的旧无障碍服务已停用；`gpm_dex` 模块现在只服务 `com.dennis.dexpad`。


## v1.35 变化

- 手机模式强制横屏（orce_landscape 默认开）：引擎连助手即  1，退出恢复  -1。
- 光标居中改为「夹到角落 + 跳半个屏幕」：hover 上报的是窗口局部坐标，不能当反馈；CENTER(corner) -> target W/2,H/2，横屏 1280,800、竖屏 452,1158。
- 竖向拖动按前台应用自适应（助手每 2 s TOP <pkg>）：桌面/抖音/PiliPlus/红果 30% 屏高、150–200 ms；其它 50%。实测 dy：桌面 480（30%×1600）、抖音 480、PiliPlus/红果竖屏任务 768（30%×2560）。


## v1.36 变化

- 所有页面强制横屏： 1 同时执行 wm set-ignore-orientation-request true（App 自己锁竖屏也会被忽略）； -1 时恢复 false。实测 PiliPlus 横屏 2560×1600。
- 光标居中改为一次定位：先把指针夹到角落（-30000,-30000），再按 (屏宽/2)/gain、(屏高/2)/gain 通过 move_display(rot) 跳一次到屏幕中心；日志 CENTER(corner+gain) -> target 1280,800。


## v1.38 变化

- 主页面「滚轮」卡片新增 **滚轮速度（按住持续滚动）** 滑杆 1–10（默认 3）：
  - 重复间隔 = 240 − 18×speed ms（speed 3 ≈ 186 ms，speed 8 ≈ 96 ms）；
  - 每次步长 = 1 + (speed−1)/3（默认 1 格，最高 5 格）。
  - 旧版固定 80 ms × 3 格，体感明显过快；现在默认约为旧版的 1/5 速度。


## v1.39 变化

- 右摇杆上下/左右改为**持续翻页**：只要摇杆保持在死区外，就按间隔重复发触摸拖动（不再要求回中）。
- 重复间隔 = 620 − 30×滚动速度 ms（滚动速度默认 4 → 约 500 ms），范围 260–700 ms。
- 实测：按住右摇杆 2 秒 → 4 次 SWIPE（8 行日志，含 async/rc 各一行）。


## v1.40 变化

- 右摇杆连续翻页：普通 App 用 35% 屏高的**长拖 450 ms**，间隔仅 40 ms 连续发，内容基本不停；信息流（抖音/红果/PiliPlus）仍一条一次；桌面一次推一格。
- 向下推：任何非信息流页面都从**屏幕顶边（3%）**下拉，保证能拉出通知栏（实测 SWIPE 0 451,48 -> 451,768 → 截图 3.5 MB）。
- 桌面自适应：助手新增 HOME <包名> 上报（cmd package resolve-activity ... HOME），引擎据此识别**任意启动器**（当前是 com.k2.consolelauncher），不再写死 Lawnchair。


## v1.41 变化

- 新增动作 **开/关屏幕（电源键）** power：助手以 root 执行 input keyevent 26，亮屏/息屏都生效。
- 默认组合 **Y + L3**（组合槽 9），可在组合编辑器里改。
- 居中增益实测更新为线性值；本轮设备重启后实测为 **3.25**，L3 一次到 (1280,800)，探针 1278,800。增益会随系统指针加速度状态变化，以清单 K1 实测为准。
- 注意：测试/使用时若开启「充电时保持唤醒」（svc power stayon true），息屏会被系统自动唤醒，看起来像开关没生效；请先 svc power stayon false。


## v1.42：只支持手机屏幕（移除 DeX）

- 引擎不再检测/注入 DeX 显示：DisplayState 只返回当前亮着的内置屏（Fold 外屏/内屏），所有动作都发到显示 0 对应的手机屏。
- 助手不再上报 DEX/FOCUS，也不再跑 dumpsys 检测 DeX 任务栏/聚焦显示器；启动时只上报 HOME。
- 删除 DeX 专属动作：最大化窗口、左/右贴边、切换 DeX、窗口截图（改为手机 SYSRQ 截图）；SELECT 默认改为无。
- 删除设置项：连接 DeX 自动开启、手机上也启用、DeX 指针速度；指针速度只剩一项。
- 默认按键与组合保持不变（见 docs/DEFAULTS-v1.41.md），仅 Y+L3 电源键、X 组合、双击等照旧。


## v1.43：不做单 App 适配（手势统一）

- 本项目不再按前台包名调整行为：删除信息流包名列表（抖音/红果/PiliPlus）与启动器判定，引擎里不再有 TOP/HOME 解析。
- 手势统一为：**上推** = 65% 起手、35% 屏高、450ms 长拖，背靠背连续（间隔 40ms）；**下拉** = 顶边 3% 起手、45% 屏高、200ms，一次一放。
- 助手不再每 2 秒 dumpsys activity 取前台包名、也不再查默认启动器（少一轮询、少一条 TOP/HOME 上报）。
- 单 App 的按键/手势差异交给 PadCtl 等其它模块；本模块只做通用传输与几何。


## v1.43 补充

- 居中改为线性 **3.25**（重启后实测值，探针 1278,800）；若系统指针加速状态变化导致偏移，重新跑 probe_center.sh 标定后改常量即可。


## v1.44：恢复 v1.43 + 按键默认值调整

- 源码回到 v1.43 骨架，摇杆保持旧版（死区/速度/滚动未改）。
- 默认按键：X 单击无动作、双击=多任务；SELECT=通知栏；GUIDE=无；R3 双击=播放暂停。
- 居中增益 2.16（实测 1279,799）。
- 清单 25/25。
