# v1.65 测试用例与结果（2026-11-14）

- 被测版本：`com.dennis.dexpad` **v1.65**（versionCode 62）／助手 `gpminput` v1.65／模块 `gpm_dex` v1.65
- 测试 App：`com.dennis.padtest`（专用测试台，见 [`PADTEST-README.md`](PADTEST-README.md)）
- 测试方式：adb 脚本 `work/scripts/v160_auto_suite.sh` 驱动虚拟手柄（`vgpad`），
  **判定以测试 App 写出的 JSON 报告 + 系统状态为准**，不依赖人眼
- 结果：**35/35 通过**

## 0. 前置条件

| 项 | 要求 |
|---|---|
| Root | KernelSU，助手单实例运行（`/data/adb/gpm/gpminput`） |
| LSPosed | 模块作用域含「设置」 |
| 鼠标模式 | 通知栏显示「鼠标模式：开」（SHARE 切换） |
| 测试 App | `padtest` 已安装（`com.dennis.padtest`） |
| 屏幕 | 亮屏解锁；测试脚本会自动 `KEYCODE_WAKEUP` |

---

## A. 版本与链路（4 条）

| ID | 用例 | 步骤 | 期望 | 结果 |
|---|---|---|---|---|
| A1 | 版本正确 | `dumpsys package com.dennis.dexpad \| grep versionName` | `1.60` | PASS |
| A2 | 测试 App 就绪 | `dumpsys package com.dennis.padtest` | 已安装 | PASS |
| A3 | 助手链路 | 启动引擎后看 `logcat -s DexPad` | `hb ready=true` | PASS |
| A4 | 鼠标模式 | 读 prefs `mode_on` | `true` | PASS |

## B1. 测试台自检 T1..T7（7 条，由测试 App 自己判定）

| ID | 检查项 | 步骤（脚本注入） | 测试 App 判定逻辑 | 结果 |
|---|---|---|---|---|
| B1-T1 | 指针移动 | 左摇杆推 400ms | 收到 `ACTION_HOVER_MOVE` 且坐标变化 >4px | PASS |
| B1-T2 | 鼠标点击 | 按 A | 收到鼠标 `ACTION_DOWN` + `ACTION_UP` | PASS |
| B1-T3 | 长按 | 按住 A 900ms | DOWN→UP 间隔 ≥ 600ms | PASS |
| B1-T4 | 方向键焦点 | 十字键↓ ×3 | 收到 `DPAD_*` 且焦点索引变化 ≥2 次（实测 4 次） | PASS |
| B1-T5 | 滚动 | 右摇杆上 600ms / 下 600ms | 触摸拖动使 `scrollY` 双向变化（实测 0..285） | PASS |
| B1-T6 | 双指缩放 | 按住 LT 900ms | 双指间距变化 ≥5% | PASS |
| B1-T7 | 键盘组合 | `hatkey`（十字键 + LT） | 收到 `Ctrl + MINUS` | PASS |

## B2. 返回键（1 条）

| ID | 用例 | 步骤 | 期望 | 结果 |
|---|---|---|---|---|
| B2-T8 | 返回键 | 按 B | 测试 App 收到 `KEYCODE_BACK` 后退出，报告写入 | PASS |

## B3. 触摸点击模式（可选开关，1 条）

| ID | 用例 | 步骤 | 期望 | 结果 |
|---|---|---|---|---|
| B3-T9 | 触摸点击 | prefs 置 `left_touch=true` → 重启引擎 → 按 A | 助手日志出现 `TOUCH down`，且 App 收到点击 | PASS |

## C. 系统动作实际效果（7 条）

| ID | 用例 | 步骤 | 期望 | 结果 |
|---|---|---|---|---|
| C1 | Y=主屏 | 设置页按 Y | 前台变成桌面 launcher | PASS |
| C2 | B=返回 | 设置子页按 B | 前台 activity 变化 | PASS |
| C3 | SELECT=通知栏 | 测试台页按 SELECT | 助手 `NOTIF uinput=1`，且截图变化 >300 字节 | PASS |
| C4 | R3=静音 | 按住 R3 900ms（越过双击窗口） | 助手 `KEYUIN 0 164`（KEY_MUTE） | PASS |
| C5 | X+↑=音量+ | 组合键 | 助手 `KEYUIN 0 24`（KEY_VOLUMEUP） | PASS |
| C6 | GUIDE=杀前台 | 测试台前台时短按 GUIDE | 进程被杀死（pid 消失） | PASS |
| C7 | Y+L3=电源 | 组合键 | `mWakefulness` 从 Awake → Dozing | PASS |

## D. 打开目标应用（每槽参数，1 条）

| ID | 用例 | 步骤 | 期望 | 结果 |
|---|---|---|---|---|
| D1 | 每槽独立目标应用 | prefs: `btn_y=open_app`、`par_y=com.android.settings` → 按 Y | 前台切到设置 | PASS |

## E. 稳定性（2 条）

| ID | 用例 | 期望 | 结果 |
|---|---|---|---|
| E1 | 无崩溃 | crash buffer 无本应用记录 | PASS |
| E2 | 无 ANR | logcat 无 `ANR in com.dennis.dexpad` | PASS |

---

## 本轮测试发现并修复的真实缺陷

| # | 缺陷 | 影响 | 修复 |
|---|---|---|---|
| 1 | `pointKey` 走 `input` 注入，在 ksu 域返回 `rc=512`，事件进不去 | **HOME / 返回 / 音量 / 静音 / 播放暂停 / 下一首 / 截图 全部"日志有、实际没反应"** | 改为走虚拟键盘 uinput 注入（`android→linux` 键码表），只有未映射的键才退回 `input` |
| 2 | `KEY_HOME(102)` 在 Android 上不回主屏 | Y=主屏失效 | 映射改为 `KEY_HOMEPAGE(172)` |
| 3 | 通知栏走 `cmd statusbar expand-notifications`，同域注入失败 | SELECT 无效 | 改走 uinput `KEY_NOTIFICATION_CENTER(444)` |
| 4 | X+LB / X+RB 横向翻页方向与名称相反 | 左右翻页反向 | 交换方向（向左滚动 = 手指向左） |
| 5 | 组合键自定义快捷键大部分被丢弃（键映射表不全） | `ctrl+alt+f` / `win+d` / `f5` 无效 | 补全字母/数字/F1–F12/空格/回车/ESC/方向键/PageUp-Down/Win 等（v1.58 已修，本轮回归确认） |

## 复跑方式

```bash
# 设备已装 v1.65 + padtest
adb push work/scripts/v160_auto_suite.sh /data/local/tmp/
adb shell "sh /data/local/tmp/v160_auto_suite.sh"
# 期望最后一行： PASS=24 FAIL=0
```

## F. d-pad 导航 / 鼠标切换（v1.65 新增）

| ID | 用例 | 步骤 | 期望 | 结果 |
|---|---|---|---|---|
| F1 | d-pad 选中后 A 确认 | 测试台页按 d-pad 两次 → 等 2 秒 → 按 A | 测试台收到按钮点击（T10=true） | PASS |
| F2 | A 注入方式 | d-pad 后按 A | 引擎日志 `A -> DPAD_CENTER`，且无 `left button down` | PASS |
| F3 | 摇杆切回鼠标 | d-pad 后推左摇杆再按 A | 日志出现 `native navigation OFF (stick moved)` + `left button down` | PASS |
| F4 | d-pad 连发 | 按住 d-pad 1.6 秒 | 助手收到 ARROW ≥3 次（实测 12 次） | PASS |

### 本轮修复的两个缺陷

| # | 缺陷 | 说明 |
|---|---|---|
| 1 | 确认键无效 | `DPAD_CENTER` 映射到 Linux `KEY_OK(352)`，三星上不触发确认；改 `KEY_ENTER(28)` |
| 2 | 导航模式过期太快 | 原来 1.2 秒后 A 变回鼠标点击；改为粘性模式，推左摇杆才退出 |

## G. 双击 / 组合方向（v1.65 新增）

| ID | 用例 | 步骤 | 期望 | 结果 |
|---|---|---|---|---|
| G1 | X 双击 = 多任务 | 两次快速按 X（间隔 120ms） | 进入 `RecentsActivity` | PASS |
| G2 | 慢双击 | 两次按 X（间隔 300ms） | 仍识别为双击 | PASS |
| G3 | X+LB 方向 | 组合键 | 手指向右（x 增大） | PASS |
| G4 | X+RB 方向 | 组合键 | 手指向左（x 减小） | PASS |

### 本轮修复

| # | 缺陷 | 说明 |
|---|---|---|
| 1 | 双击“无效” | 双击判定正常，但最近任务键 `187` 错映射成 `META_LEFT(125)`；改为 `APP_SWITCH(580)` |
| 2 | 双击太难触发 | 窗口 320ms → 400ms |
| 3 | X+LB/RB 方向反直觉 | 对调：LB = 上一页（手指向右），RB = 下一页（手指向左） |

## H. 打开应用 / 光标重居中（v1.65 新增）

| ID | 用例 | 步骤 | 期望 | 结果 |
|---|---|---|---|---|
| H1 | Start+上 打开应用 | 组合键 start+up → open_app(com.example.piliplus) | 前台变为 PiliPlus | PASS |
| H2 | 恢复上次位置 | 移动光标→等 10s（空闲隐藏）→推左摇杆 | 恢复坐标≈隐藏前坐标（不是屏幕中心） | PASS |
| H3 | 光标四向可达 | 居中后向四个方向各推一次 | 日志里 +x/-x/+y/-y 都有位移 | PASS |

### 本轮修复

| # | 缺陷 | 说明 |
|---|---|---|
| 1 | 打开应用对部分 App 无效 | `am start -p` 解析失败；改为 `resolve-activity` + `am start -n`，再回退 `-p` / `monkey` |
| 2 | d-pad 后光标卡边界 | 空闲隐藏销毁鼠标设备 → 重建后系统光标位置改变，估算未同步导致夹取锁死；重建后自动居中+同步估算 |

## v1.65 增补

| ID | 用例 | 说明 | 结果 |
|---|---|---|---|
| H2（更新） | 空闲隐藏后恢复到**上次位置** | 助手新增 `P x y w h` 绝对定位（有界到左上角再增益一步） | PASS |
| C3（收紧） | SELECT 通知栏 | 改为真实下滑手势；截图差阈值 200B → 500KB，防假通过 | PASS |

## v1.65 增补

| ID | 用例 | 说明 | 结果 |
|---|---|---|---|
| H2（更新） | 光标空闲隐藏后**隐形恢复** | 隐藏前 hover 坐标 → 恢复后点击落点，误差 ≤120px（实测 0px） | PASS |

### 本轮修复

| # | 问题 | 说明 |
|---|---|---|
| 1 | 修正过程可见（跳到角落再飞回） | 实测鼠标设备销毁/重建后系统会**保留光标坐标**，因此恢复时完全不做移动，光标直接在原地出现 |
