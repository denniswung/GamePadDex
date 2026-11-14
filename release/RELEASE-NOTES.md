# v1.60 发布说明（2026-11-14）

包名：`com.dennis.dexpad`　versionCode **62** / versionName **1.60**
配套：KernelSU 模块 `gpm_dex` v1.60 · 助手 `gpminput` v1.60 · 测试台 `com.dennis.padtest`

## 1. 重大修复：HOME / 返回 / 音量 / 静音 / 截图 之前其实是失效的

**根因**：这些动作都走助手的 `D` 命令 → `system("input -d 0 keyevent N")`。
但 `input` 在 KernelSU 的 SELinux 域里注入失败（返回码 **512**），事件根本进不去。
日志里一直有 `KEYON 0 24` 之类，所以以前"看起来在执行"，实际没有任何效果。

**改法**：`D` 命令改成用**我们自己的虚拟键盘注入**（uinput，内核级，和电源键、方向键同一条路径）：

```
KEYUIN 0 24 lcode=115   ← 音量+
KEYUIN 0 3  lcode=172    ← 主屏
KEYUIN 0 164 lcode=113   ← 静音
```

顺手修了两处键码错误/缺口：

- **主屏**：`KEY_HOME(102)` 在 Android 上不触发回主屏，改用 `KEY_HOMEPAGE(172)`；
- **通知栏**：原来走 `cmd statusbar expand-notifications`（同域注入失败），改成 uinput
  `KEY_NOTIFICATION_CENTER(444)`。

## 2. 横向翻页方向修正

`X+LB` / `X+RB` 的方向和名字相反（"向左滚动"实际手指往右），已交换：
现在**向左滚动 = 手指往左**，和 LB/RB 竖向（手指下滑/上滑）的约定一致。

## 3. 新增专用测试 App 与全量测试套件

- 测试台 App 新增 **`AutoTestActivity`（自动化测试台）**：
  它自己判断"手柄动作有没有真的生效"（指针移动 / 鼠标点击 / 长按 / 方向键焦点 /
  滚动双向 / 双指缩放 / 键盘组合 / 返回键 / 触摸点击），并写入
  `files/auto-report.json`；
- 配套 adb 套件 `work/scripts/v160_auto_suite.sh`：驱动虚拟手柄 → 读测试 App 报告 +
  系统状态 → 逐条 PASS/FAIL；
- 详细用例见 [docs/TEST-CASES-v1.60.md](../docs/TEST-CASES-v1.60.md)。

## 测试结果（v1.60，24/24）

```
A1 版本 1.60          A2 专用测试 App 已安装   A3 助手链路   A4 鼠标模式
B1-T1 指针移动        B1-T2 鼠标点击           B1-T3 长按
B1-T4 方向键焦点      B1-T5 滚动               B1-T6 双指缩放
B1-T7 键盘组合        B2-T8 返回键             B3-T9 触摸点击
C1 Y 回主屏           C2 B 返回                C3 SELECT 通知栏
C4 R3 静音            C5 X+↑ 音量              C6 GUIDE 杀前台
C7 Y+L3 电源          D1 打开目标应用           E1 无崩溃  E2 无 ANR
PASS=24 FAIL=0
```

测试台自动报告（设备上的 `auto-report.json`）：

```json
{ "T1 指针移动": true, "T2 鼠标点击": true, "T3 长按": true,
  "T4 方向键焦点": true, "T5 滚动": true, "T6 双指缩放": true,
  "T7 键盘组合": true, "pass": 7, "total": 9,
  "hoverMoved": true, "focusMoves": 4, "scrollRange": "0..285" }
```

## 4. 安装校验（这次把"装的是不是当前编译版本"也做了检查）

| 检查 | 结果 |
|---|---|
| 设备上 APK sha256 vs 构建产物 | 一致（`cf5e7e2a…` → 本次 `dexpad-v1.60.apk`） |
| `/data/adb/gpm/gpminput` vs 构建产物 | 一致 |
| `/data/adb/modules/gpm_dex/gpminput` | 已同步（之前是旧文件，已修） |
| `/data/adb/modules/gpm_dex/module.prop` | 已同步为 v1.60/62（之前还停留在 v1.1/2） |

## 已知限制

- 带双击动作的按键（R3）单击会延迟 320ms（双击窗口）；跨过窗口再松手即可立即触发。
- 触摸点击模式仍依赖光标位置估算（默认关闭）。
- 滑动 task 边界有 2 秒缓存，切换应用后多窗口场景可能短暂沿用旧边界。
