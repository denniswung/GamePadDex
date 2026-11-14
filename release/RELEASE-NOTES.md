# v1.62 发布说明（2026-11-14）

包名：`com.dennis.dexpad`　versionCode **64** / versionName **1.62**
配套：KernelSU 模块 `gpm_dex` v1.62 · 助手 `gpminput` v1.62 · 测试台 `com.dennis.padtest`

## 1. 双击无效（例如 X 双击进不了多任务）—— 根因

双击检测一直在工作（日志里有 `double x -> recents`），但**"最近任务"键注入错了**：

- Android 的 `KEYCODE_APP_SWITCH(187)` 被映射成 Linux `KEY_COMPOSE/125`；
- 而本机 `Generic.kl` 里 **`key 580 APP_SWITCH`** 才是最近任务；
- 结果：按了"最近任务"实际上是按了"Windows 键"，页面当然没反应。

已改为 **187 → 580（APP_SWITCH）**。实测：

```
engine: double x -> recents
helper: KEYUIN 0 187 lcode=580
after : com.sec.android.app.launcher/com.android.quickstep.RecentsActivity
```

另外把双击窗口从 **320ms 放宽到 400ms**（人手双击 300ms 左右很常见）。

## 2. X+LB / X+RB 功能对调

按要求把两个方向对调：

| 组合 | 现在的行为 | 效果 |
|---|---|---|
| **X + LB** | 手指向右滑 | 内容向右 → **上一页** |
| **X + RB** | 手指向左滑 | 内容向左 → **下一页** |

实测：`X+LB: 1280→2540`（向右）、`X+RB: 1280→20`（向左）。

## 3. 测试（32/32 通过）

新增 4 条用例：

| ID | 用例 | 结果 |
|---|---|---|
| G1 | X 双击 → 多任务页面（实测进入 RecentsActivity） | PASS |
| G2 | 慢一点的双击（间隔 300ms）也能识别 | PASS |
| G3 | X+LB 手指向右（1280→2540） | PASS |
| G4 | X+RB 手指向左（1280→20） | PASS |

完整结果：

```
A1 版本 1.62  A2 测试台  A3 链路  A4 鼠标模式
B1-T1..T7（指针/点击/长按/方向键焦点/滚动/双指缩放/键盘组合）
B2-T8 返回键  B3-T9 触摸点击
F1 d-pad 选中后 A 确认  F2 注入方式  F3 摇杆切鼠标  F4 d-pad 连发
G1 X 双击多任务  G2 慢双击  G3 X+LB  G4 X+RB
C1 主屏  C2 返回  C3 通知栏  C4 静音  C5 音量  C6 杀前台  C7 电源
D1 打开目标应用  E1 无崩溃  E2 无 ANR
PASS=32 FAIL=0
```

## 4. 已知限制

- 双击窗口 400ms：带双击动作的按键（X、R3）单击会延迟 400ms 才生效（这是双击判定的代价）。
- 其余同前。
