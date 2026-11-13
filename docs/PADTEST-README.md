# 手柄映射测试台（padtest）

一个**独立**的 Android 测试 App，用来验证「手柄 → 映射守护进程 → uinput 注入 → 系统分发 → 应用接收」整条链路。
它不依赖被测程序的任何代码，只依赖 Android 标准事件分发与系统 API。

- 包名：`com.dennis.padtest`　版本：1.0（versionCode 1）
- 构建：Kotlin，`minSdk 26` / `targetSdk 36` / `compileSdk 36`，AGP 9.3.1（内建 Kotlin）
- 依赖：**零第三方依赖**（不用 AndroidX / Compose，只用框架 View），可离线编译
- 产物：`project/padtest/app/build/outputs/apk/debug/app-debug.apk`

> 为什么用传统 View 而不是 Compose：本机与目标设备都要求**离线可复现构建**。
> 现有工程（`project/lsp-dexpad`）同样零 AndroidX 依赖；Compose 需要额外下载整条
> compose-bom/compiler 依赖链，在无网或镜像不全时直接构建失败。
> 本项目的列表性能靠 `ListView` + 复用 convertView（200 项滚动无压力）。

---

## 一、项目结构树与模块职责

```
project/padtest/
├── settings.gradle.kts                 # 仓库与模块声明
├── build.gradle.kts                    # AGP 9.3.1
├── gradle.properties                   # android.useAndroidX=false
├── gradle/wrapper/                     # 与主工程同版本 wrapper
├── gradlew / gradlew.bat
└── app/
    ├── build.gradle.kts                # minSdk 26 / compileSdk 36 / 无依赖
    └── src/main/
        ├── AndroidManifest.xml         # 7 个 Activity，无敏感权限
        ├── res/values/{strings,styles}.xml
        └── java/com/dennis/padtest/
            ├── core/
            │   ├── ProbeEvent.kt       # 事件模型：来源(MOUSE/WHEEL/TOUCH/KEY/SYSTEM)、类型、参数
            │   ├── ProbeBus.kt         # 环形缓冲(3000) + logcat 镜像(tag=PadProbe) + UI 节流(60ms)
            │   ├── CheckRegistry.kt    # 测试点登记：PASS/FAIL/UNKNOWN、会话时间窗、报告生成
            │   └── Exporter.kt         # CSV/JSON/报告写入 App 外部目录（免权限）+ 分享
            ├── view/
            │   ├── CursorCanvas.kt     # 光标轨迹画布（最近 50 点、Σ 位移、点击标记）
            │   └── AxisLockView.kt     # 可横可纵的自绘容器，报告偏移/主轴锁定/px/s
            └── ui/
                ├── ProbeActivity.kt    # 基类：统一事件捕获 + 深色骨架 + 悬浮「日志/报告」
                ├── SelfCheckActivity.kt# ① 链路自检（启动页）
                ├── CursorTestActivity.kt# ② 光标测试
                ├── ScrollTestActivity.kt# ③ 滚动/滑动测试
                ├── KeyTestActivity.kt  # ④ 按键测试（接收端 + 预期比对）
                ├── SystemTestActivity.kt# ⑤ 系统动作测试
                ├── LogActivity.kt      # ⑥ 日志面板（过滤/暂停/清空/导出）
                └── ReportActivity.kt   # ⑦ 结果汇总（开始/结束/导出）
```

### 分层与关键设计

| 层 | 类 | 说明 |
|---|---|---|
| 事件捕获 | `ProbeActivity.dispatchKeyEvent / dispatchGenericMotionEvent / dispatchTouchEvent` | **不消费**事件（返回 super），页面控件仍会正常响应；捕获后先写总线再交给子类 |
| 状态管理 | `ProbeBus`（事件流）、`CheckRegistry`（结论） | 单一数据源；UI 通过监听 + 节流刷新，避免高频 hover 打爆主线程 |
| UI | 各 Activity | 每个页面只做「展示 + 少量判定」，判定结果写入 `CheckRegistry` |
| 导出 | `Exporter` | 写 `/sdcard/Android/data/com.dennis.padtest/files/export/`，无需存储权限 |

`ProbeBus` 会把每条事件镜像到 **logcat（tag `PadProbe`）**，因此 adb 侧可以直接断言：

```
11-13 18:36:22.124 I PadProbe: KEY/key-down KEYCODE_CTRL_LEFT(113) repeat=0
11-13 18:36:22.134 I PadProbe: KEY/key-down KEYCODE_MINUS(69) repeat=0
11-13 18:36:22.168 I PadProbe: KEY/key-up KEYCODE_MINUS(69) held=34ms
```

---

## 二、每个测试页：怎么用手柄操作、预期结果

### ① 链路自检（启动页）

| 操作 | 预期 |
|---|---|
| 打开 App | 「手柄识别」列出设备；「注入可见性」四行显示 `未收到` |
| 推左摇杆 | 鼠标行变成 `0.x 秒前` |
| 右摇杆上下 | 滚轮/触摸行刷新 |
| 按 A / R3 / 方向键 | 按键行刷新 |
| 看「自检结果」 | `LINK.INJECT` 变 `[PASS]`；`LINK.ROOT`/`LINK.UINPUT` 在沙箱内通常是 `[ -- ]`（正常，见限制） |

失败判定：手柄已连接、映射程序在跑，但四行始终 `未收到` → 注入链路断（先看映射程序日志是否 `KEYON/SWIPE rc=0`）。

### ② 光标测试

| 操作 | 预期 |
|---|---|
| 推左摇杆 | 画布出现折线轨迹，`pointer x,y` 连续变化，速度显示 `px/s` |
| 推到底/停止 | 速度回落到 0（200ms 无移动即归零） |
| 点 A | 画布出现黄色落点，`点击 x,y` 更新 |
| 把小格子网格推近 | 单次点击只命中一个格子（`格子命中 (r,c)`） |
| 指针移到「可滚动内容」上 | `焦点容器 ScrollView（可滚动）` |

失败判定：轨迹跳变/不跟手 → 速度或采样问题；点击坐标与落点偏差 > 一个格子 → 落点精度问题；进入列表区域仍显示「不在可滚动控件上」→ 焦点判定链路问题（映射程序的焦点锚定会直接影响这里）。

### ③ 滚动 / 滑动测试

| 操作 | 预期 |
|---|---|
| 右摇杆上下 | 纵向列表滚动，`offset/速度/持续=是`；`SCROLL.VERTICAL` PASS |
| 右摇杆左右 | 横向 5 页翻动，`scrollX` 变化；`SCROLL.HORIZONTAL` PASS |
| 斜推（同时上下左右） | `AxisLockView` 只锁一个方向（`锁定：横向` 或 `纵向`），不会来回抖 |
| 指针指向左/右列表再滚 | 只有指针所在那个列表滚（`焦点：左列表在滚`） |
| 在「固定区域」触发滚动 | 列表仍按光标位置滚，不会乱滚（回退到光标锚点） |
| 切「手势后端 / 滚轮后端」再滚 | `后端统计` 分别 +1；日志里颜色不同（触摸绿 / 滚轮黄） |
| 持续推动摇杆 | 列表连续滚，`持续=是`，松手后 `持续=否` |

失败判定：一直滚但 `offset` 不变 → 事件到了控件没动；斜推时两个方向都动 → 轴向锁定失效；指针在 A 列表却滚了 B → 焦点锚定错误。

### ④ 按键测试（接收端）

> 前提：映射程序用 `EVIOCGRAB` 独占手柄，**A/B/X/Y 不会到达 App**。
> 本页看到的是映射后的注入键流；用「监听」按钮间接验证「某个手柄键 → 什么动作」。

| 操作 | 预期 |
|---|---|
| 按 LT / RT | 收到 `Ctrl+Minus` / `Ctrl+Plus`（缩放），`组合识别：Ctrl → +`；`KEY.COMBO` PASS |
| 按「监听」再按手柄键 | 3 秒窗口内出现动作即判定：绿色 `✔` / 红色 `✘` / 灰色超时 |
| 三行内置（A→左键、B→返回、Y→Home、R3→静音） | 符合预期即绿 |
| X+A 与 A+X 两行分别监听 | 两行结论一致 → 等价继承；不一致 → 独立映射（按你的配置核对） |
| 长按某个注入键（音量/方向键） | `按住中 XXXms（已达长按阈值）`，`KEY.LONG` PASS |

失败判定：窗口内完全没有动作 → 该键未映射或注入失败；动作与预期不符 → 映射表配置错误。

### ⑤ 系统动作测试

| 操作 | 预期 |
|---|---|
| 按音量加/减 | `音量 N%` 变化，历史新增一行 |
| 按 Y+L3 / SELECT+START | `屏幕：灭/亮` 变化，记录最近变化时间 |
| 按 LT / RT | `缩放注入：放大/缩小 N 次` 增加（系统缩放比例第三方不可读，用注入计数代替） |
| 强停应用 | 重新打开本页 → `上次未正常退出：HH:mm:ss` |
| 按 R3（静音）/媒体键 | `媒体：播放/暂停键 N 次` 增加 |
| 通知栏 | 始终显示「未检测（权限不足）」，见限制 |

### ⑥ 日志面板

- 颜色区分来源；顶部按钮：全部 / 鼠标 / 滚轮 / 触摸 / 按键 / 暂停 / 清空 / 导出 CSV / 导出 JSON。
- 导出路径：`/sdcard/Android/data/com.dennis.padtest/files/export/probe-log-*.csv`。
- 「收到事件但控件不动」→ 看日志里的坐标与参数；「什么都没收到」→ 看映射程序日志。

### ⑦ 结果汇总

- 「开始测试 / 结束测试」记录时间窗；
- 汇总 `通过/失败/未测`，失败项各附最近 5 条日志；
- 导出 `report-*.txt` / `report-*.json`。

---

## 三、已知限制与替代验证

| 限制 | 原因 | 替代验证 |
|---|---|---|
| 看不到手柄原始按键（A/B/X/Y） | 映射程序 `EVIOCGRAB` 独占设备，事件不再分发给任何 App | 用 `KeyTest` 的「监听」窗口做「按键 → 动作」间接验证；或看映射程序日志 `button a down mapped=left_click` |
| 音量/静音/电源/Home/最近任务 键可能不到达 App | 这些键由系统在应用之前消费 | 用 `helper.log` 的 `KEYON 0 <code>` 与 `dumpsys audio` 佐证；本 App 里用 `KEYON` 计数页代替 |
| 通知栏展开状态 | 需要无障碍/系统签名，第三方 App 读不到 | 截图对比，或看映射程序日志里 `NOTIF rc=0` |
| 媒体会话曲目 | 需要 `MediaSessionManager` 的通知监听权限，本 App 未申请 | 只统计“媒体键被注入”的次数；曲目用系统媒体面板看 |
| 系统缩放比例 | 不可读 | 统计 `Ctrl+Plus/Minus` 注入次数 + 可缩放图片区域目视 |
| root / `/dev/uinput` 在 App 沙箱内不可见 | 命名空间隔离 | 这两项只做展示；真正判据是「注入可见性」 |
| 手势后端注入在本机表现为鼠标拖拽事件 | 系统把注入的 touch 归一成鼠标事件 | 本 App 在 `ScrollTest` 里提供「手势滑动 → 列表滚动」桥接（探针模式），让“有没有真的滚”可见 |

---

## 四、测试执行清单（建议顺序）

| # | 页面 | 操作 | 判定 |
|---|---|---|---|
| 1 | 自检 | 打开 App，等 2 秒 | 「手柄识别」有设备；`LINK.INJECT` 至少 `[ -- ]` 不报红 |
| 2 | 自检 | 推摇杆 / 按 A / 按 R3 | 三个来源的「最近事件」都刷新 → **链路通** |
| 3 | 自检 | 看 `LINK.ROOT` / `LINK.UINPUT` | `[ -- ]` 属正常（沙箱不可见），不算失败 |
| 4 | 光标 | 推左摇杆画圈 | 轨迹连续、无跳变、跟手 |
| 5 | 光标 | 轻推停在网格某一格 | 落点稳定，不超过 1 格抖动 |
| 6 | 光标 | 指针移入「可滚动内容」 | 显示 `焦点容器 ScrollView（可滚动）` |
| 7 | 滚动 | 右摇杆上下推 3 秒 | 列表持续滚、`持续=是`、松手即停 |
| 8 | 滚动 | 右摇杆左右推 | 横向翻页，页码变化 |
| 9 | 滚动 | 斜推 | 只锁一个方向 |
| 10 | 滚动 | 指针分别指向左右列表再滚 | 只有指针所在列表动 |
| 11 | 滚动 | 切滚轮后端再滚 | 日志出现黄色 `WHEEL/scroll`，列表照样滚 |
| 12 | 滚动 | 在固定区域滚动 | 不乱滚，回退到光标所在容器 |
| 13 | 按键 | 按 LT / RT | 看到 `Ctrl+Minus` / `Ctrl+Plus` 组合 |
| 14 | 按键 | 逐个「监听」A→左键、B→返回、Y→Home、R3→静音 | 全部绿色 |
| 15 | 按键 | 监听 X+A 与 A+X | 两行结论一致（或按配置解释差异） |
| 16 | 按键 | 按住音量键 1 秒 | 出现「已达长按阈值」 |
| 17 | 系统 | 按音量、Y+L3、LT/RT | 音量%/屏幕状态/缩放计数都变化 |
| 18 | 系统 | 让映射程序强停前台应用 | 重开本页显示「上次未正常退出」时间 |
| 19 | 日志 | 观察有无断点；导出 CSV | 文件生成、行数 > 0 |
| 20 | 报告 | 开始→复跑 1~19→结束→导出 | 失败项都有原因与最近 5 条日志 |

**失败判据（任一即失败）**：自检四行全 `未收到`；轨迹跳变；落点偏差 > 1 格；持续滚动 < 1 秒即断；斜推双轴同时动；指针锚定滚错列表；滚轮后端无 `WHEEL` 事件；监听窗口无动作或动作不符；缩放在 LT/RT 下无 `Ctrl±` 注入；导出文件为空。

---

## 五、本测试台已经抓到的真实问题（价值证明）

1. **R3 单击默认值缺失**：文档要求「R3=静音」，但默认表里没有 `r3` 分支 → 已补 `"r3" -> VOLUME_MUTE`。
2. **`display=0` 的组合键被助手拒绝**：`C 0 113 69` 触发 `ERR C display`（校验写成 `cd <= 0`）→ 已改为 `cd < 0`。
3. **组合键注入方式不可用**：助手用 `input keycombination` 在 root 域返回 `rc=512`（权限不足）→ 改为**进程内 uinput 组合键**（按下→保持→逆序释放），现在 LT/RT 的 `Ctrl+Plus/Minus` 能真正到达应用。
4. **A 键语义切换过慢**：原来要等左摇杆离开死区才从「激活焦点」切回「左键」→ 改为 1.2 秒时间窗（可在设置里调），d-pad 后 2 秒再按 A 立即是左键。
