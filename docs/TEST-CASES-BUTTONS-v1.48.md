# 全按键测试用例（v1.48）

> 目标：把《手柄按键处理》里映射的**每一个按键、每一个语义**都在真机上跑一遍。
> 设备 SM-F9360（RFCT817KWEH），Debug APK（需要广播改配置的长按/窗口用例）。
> 证据来源：`logcat -s DexPad`（引擎语义）、`/data/adb/gpm/helper.log`（注入结果）、`dumpsys power`（屏幕）。

## 0. 前置（L）

| ID | 用例 | 预期 |
|---|---|---|
| L-01 | 链路自检 `?` | 9 项 CAP 全 1，无缺失 |
| L-02 | 引擎连上助手 | 日志 `engine started` / `hb ready=true` |
| L-03 | 鼠标模式默认开 | `mode → true` |
| L-04 | 屏幕常亮设置 | `screen_off_timeout=600000`，结束后还原 |

## 1. 单击（S）

| ID | 按键 | 预期动作 | 证据 |
|---|---|---|---|
| S-01 | **A** | 鼠标左键 | `left button down` |
| S-02 | **B** | 返回 | `back on display` + `KEYON 0 4` |
| S-03 | **X** | 无动作 | 无 `left button`、无 `KEYON` |
| S-04 | **Y** | Home | `home on display` + `KEYON 0 3` |
| S-05 | **LB** | 向上滑动 | `wheel scroll_swipe_up started by lb` + `SWIPE` |
| S-06 | **RB** | 向下滑动 | `wheel scroll_swipe_down started by rb` + `SWIPE` |
| S-07 | **LT** | 缩小 | `zoom out -> [113, 69]` |
| S-08 | **RT** | 放大 | `zoom in -> [113, 81]` |
| S-09 | **L3** | 光标居中 | `CENTER(linear …)` |
| S-10 | **R3** | 静音 | `volume mute on display` + `KEYON 0 164` |
| S-11 | **START** | 切换上一个 App | `switch app on display` |
| S-12 | **SELECT** | 下拉通知栏 | helper `NOTIF` |
| S-13 | **GUIDE** | 无动作 | 无任何注入 |
| S-14 | **SHARE** | 关闭鼠标模式 | `toggle -> mouse mode false` + `mouse mode OFF` |
| S-15 | **SHARE** 再按 | 打开鼠标模式 | `toggle -> mouse mode true` + `mouse mode ON` |
| S-16 | **D-pad ↑↓←→** | 原生方向键转发 | helper `PAD 103/108/105/106` + `pad key …` |

## 2. 双击（D）

| ID | 用例 | 预期 | 证据 |
|---|---|---|---|
| D-01 | **X 双击** | 多任务 | `double x -> recents` + `KEYON 0 187` |
| D-02 | **R3 双击** | 播放/暂停 | `double r3 -> play_pause` + `KCOMBO … 85` |
| D-03 | R3 双击 + 右摇杆移动 | 取消 | `double r3 cancelled (right stick moved)`，无 `KCOMBO 85` |

## 3. 长按（G）

| ID | 用例 | 预期 | 证据 |
|---|---|---|---|
| G-01 | 默认长按（配置为空） | 无动作 | 长按 900 ms 后无注入 |
| G-02 | 配置 `长按 X = 多任务` 后长按 | 多任务 | `long x -> recents` + `KEYON 0 187` |
| G-03 | 长按抑制单击 | 不长按时不误触发 | 仅 `long`，无 `left button down` |

## 4. 组合（C）

| ID | 组合 | 预期 | 证据 |
|---|---|---|---|
| C-01 | **X+↑** | 音量+（300 ms 后连续） | `mix 0 x+up -> volume_up` + `KEYON 24` ≥2 |
| C-02 | **X+↓** | 音量− | `mix 1 x+down -> volume_down` + `KEYON 25` |
| C-03 | **X+←** | 上一首 | `mix 2 x+left -> prev_track` + `KEYON 88` |
| C-04 | **X+→** | 下一首 | `mix 3 x+right -> next_track` + `KEYON 87` |
| C-05 | **X+LB** | 向左大段滑动（60% 宽） | `mix 4 x+lb -> wheel_left` + `SWIPE` 位移 ≥1200 |
| C-06 | **X+RB** | 向右大段滑动 | `mix 5 x+rb -> wheel_right` + `SWIPE` 反向 |
| C-07 | **Y+L3** | 开/关屏幕 | `mix 9 y+l3 -> power` + helper `POWER` |
| C-08 | **SELECT+START 1 s** | 开关屏幕 | `select+start -> screen toggle` + `POWER` |
| C-09 | **X+GUIDE 1.5 s** | 强停前台 | `force stop by X+GUIDE` + helper `FORCE_STOP` |
| C-10 | **X+左摇杆** | 慢速指针（默认 15%） | `ptr move …` 的位移明显小于普通推杆 |

## 5. A 的焦点窗口（F）

| ID | 用例 | 预期 | 证据 |
|---|---|---|---|
| F-01 | D-pad 与 A 同一爆发（<1.2 s） | 激活焦点 | `A -> DPAD_CENTER (native nav)` + `KEYON 0 23` |
| F-02 | D-pad 后等待 2 s 再按 A | 鼠标左键 | `left button down`，且无 `DPAD_CENTER` |
| F-03 | 窗口内推动左摇杆再按 A | 立即恢复左键 | `native navigation OFF (stick moved)` 后 `left button down` |

## 6. 摇杆（R）

| ID | 用例 | 预期 | 证据 |
|---|---|---|---|
| R-01 | 左摇杆推 | 指针移动 | `ptr move dx=… dy=…` 非零 |
| R-02 | 右摇杆上下 | 滚动/滑动 | helper `SWIPE`（手势）或 `WHEEL`（滚轮） |
| R-03 | 右摇杆左右 | 左右滑动 | `SWIPE` 横向位移 |
| R-04 | 摇杆与按键滚动互斥 | 摇杆一动停止 LB/RB 滚动 | `wheel stopped by …` |
| R-05 | L3 居中后立刻推杆 | 指针不动 250 ms | `ptr move` 无输出 |
| R-06 | 角色互换开 | 左=滚动、右=指针 | 左杆无 `ptr move`，右杆有 |

## 7. 不该发生的事（X）

| ID | 用例 | 预期 |
|---|---|---|
| X-01 | X+GUIDE 期间 | 不触发 X 双击 |
| X-02 | X+方向键期间 | 不触发 X 双击 |
| X-03 | 组合命中 | 参与键单键动作被抑制 |
| X-04 | 全程 | `FATAL EXCEPTION` 计数 = 0 |

## 统计

共 **42** 条：L 4 / S 16 / D 3 / G 3 / C 10 / F 3 / R 6 / X 4。
