# 全按键测试用例（v1.49，配套「手柄测试页」）

> 测试载体：App 内置 **手柄测试页**（`com.dennis.dexpad/.GamepadTestActivity`，设置页「手柄测试页」按钮进入）。
> 它接收映射**真正注入**的事件，逐项计数并写日志（tag `GpTest`）：
> `click down` / `scroll v=.. h=..` / `key down code=..` / `hover` 位移。
> 注入类按键（HOME/BACK/VOLUME/DPAD）系统会直接消费，因此同时用 root 助手日志 `KEYON 0 <code>` 佐证。
>
> 设备：SM-F9360（RFCT817KWEH），Debug APK（长按/窗口类用例要广播改配置）。

## 证据来源

| 来源 | 命令 | 用途 |
|---|---|---|
| 测试页 | `logcat -s GpTest` | 点击、滚轮、按键到达、指针位移 |
| 引擎 | `logcat -s DexPad` | 语义（`mix … -> volume_up`、`double x -> recents`） |
| 助手 | `/data/adb/gpm/helper.log` | 注入结果（`KEYON`、`SWIPE`、`WHEEL`、`POWER`、`NOTIF`、`CENTER`） |

## 0. 前置（L）

| ID | 用例 | 预期 |
|---|---|---|
| L-01 | 引擎启动 | `engine started` |
| L-02 | 助手链路 | 心跳 `hb ready=true`（等 2 次心跳） |
| L-03 | 鼠标模式 | `mode → true`（默认开） |
| L-04 | 链路自检 | 9 项 CAP 全 1 |

## 1. 单击（S）

| ID | 按键 | 预期 | 证据 |
|---|---|---|---|
| S-01 | A | 左键 | GpTest `click down` |
| S-02 | B | 返回 | `KEYON 0 4` |
| S-03 | X | 无动作 | 无 `click`、无 `KEYON` |
| S-04 | Y | Home | `KEYON 0 3` |
| S-05 | LB | 向上滚动 | GpTest `scroll`/`wheel` 或 `SWIPE` |
| S-06 | RB | 向下滚动 | 同上 |
| S-07 | LT | 缩小 | `zoom out -> [113, 69]` |
| S-08 | RT | 放大 | `zoom in -> [113, 81]` |
| S-09 | L3 | 光标居中 | `CENTER` |
| S-10 | R3 | 静音 | `volume mute` + `KEYON 0 164` |
| S-11 | START | 切换上一个 App | `switch app on display` |
| S-12 | SELECT | 通知栏 | `NOTIF` |
| S-13 | GUIDE 短按 | 无动作 | 无注入 |
| S-13b | GUIDE 长按 900 ms | 帮助 | `guide help` |
| S-14 | SHARE | 关鼠标模式 | `toggle -> mouse mode false` |
| S-15 | SHARE 再按 | 开鼠标模式 | `toggle -> mouse mode true` |
| S-16 | D-pad ↑↓←→ | 原生方向键 | GpTest `key down code=19/20/21/22` |

## 2. 双击（D）

| ID | 用例 | 预期 | 证据 |
|---|---|---|---|
| D-01 | X 双击 | 多任务 | `double x -> recents` |
| D-02 | R3 双击 | 播放/暂停 | `double r3 -> play_pause` + `KEYON 0 85` |
| D-03 | R3 双击 + 右摇杆 | 取消 | `double r3 cancelled` |

## 3. 长按（G）

| ID | 用例 | 预期 | 证据 |
|---|---|---|---|
| G-01 | 默认长按 X | 无动作 | 无 `long x ->` |
| G-02 | 配 `长按 X=多任务` 后长按 | 多任务 | `long x -> recents` + `KEYON 0 187` |
| G-03 | 长按抑制单击 | 不误触发 | 无 `click`/`left button down` |

## 4. 组合（C）

| ID | 组合 | 预期 | 证据 |
|---|---|---|---|
| C-01 | X+↑ | 音量+（300 ms 起连续） | `mix 0 x+up -> volume_up` + `KEYON 0 24` ≥2 |
| C-02 | X+↓ | 音量− | `KEYON 0 25` |
| C-03 | X+← | 上一首 | `KEYON 0 88` |
| C-04 | X+→ | 下一首 | `KEYON 0 87` |
| C-05 | X+LB | 左滑（60% 宽） | `mix 4 x+lb -> wheel_left` + `SWIPE` ≥1200 px |
| C-06 | X+RB | 右滑 | `mix 5 x+rb -> wheel_right` + `SWIPE` |
| C-07 | Y+L3 | 开关屏 | `mix 9 y+l3 -> power` + `POWER` |
| C-08 | SELECT+START 1.3 s | 开关屏 | `select+start -> screen toggle` + `POWER` |
| C-09 | X+GUIDE 2 s | 强停前台 | `force stop by X+GUIDE` |
| C-10 | X+左摇杆 | 慢速指针（15%） | `ptr move` 位移 < 普通推杆 |

## 5. A 焦点窗口（F）

| ID | 用例 | 预期 | 证据 |
|---|---|---|---|
| F-01 | D-pad + A 同爆发 | 激活焦点 | `A -> DPAD_CENTER` |
| F-02 | 等 2 s 再按 A | 左键 | GpTest `click down`，无 `DPAD_CENTER` |
| F-03 | 窗口内推左摇杆再按 A | 立即恢复左键 | `native navigation OFF (stick moved)` + `click down` |

## 6. 摇杆（R）

| ID | 用例 | 预期 | 证据 |
|---|---|---|---|
| R-01 | 左摇杆推 | 指针移动 | GpTest hover Σ\|dx\|>0 |
| R-02 | 右摇杆上下 | 滚动 | `SWIPE`/`WHEEL` 或 GpTest `scroll` |
| R-03 | 右摇杆左右 | 横滑 | `SWIPE` |
| R-04 | 摇杆抢占按键滚动 | 停止 | `wheel stopped by rb` |
| R-05 | L3 居中后 250 ms | 指针不动 | 该窗口内无 hover 位移 |
| R-06 | 角色互换 | 右杆=指针 | 右杆 hover 位移 >0、左杆无 |

## 7. 不该发生（X）

| ID | 用例 | 预期 |
|---|---|---|
| X-01 | X+GUIDE 期间 | 不触发 X 双击 |
| X-02 | X+方向键期间 | 不触发 X 双击 |
| X-03 | 组合命中 | 抑制 X 单键 |
| X-04 | 全程 | `FATAL EXCEPTION` = 0 |

共 **44** 条（L4 / S17 / D3 / G3 / C10 / F3 / R6 / X4 → 含 S-13b、S-16 四向合并计 1）。
