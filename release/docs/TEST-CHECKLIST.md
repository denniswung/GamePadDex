# GamePadDex 测试清单

> 用法：按编号顺序在目标机（SM-F9360，KernelSU + LSPosed，HDMI 可接可不接）上执行。
> 标注「自动」的用例由 `work/scripts/checklist_run.sh` 覆盖，结果看脚本输出的 PASS/FAIL。
> 每次发布前跑一遍「快速回归」（标 ⚡ 的用例）。

## 0. 环境准备

| 编号 | 步骤 | 期望 |
|---|---|---|
| P0.1 | `adb connect <ip>:6666`，`getprop ro.product.model` | `SM_F9360`（不是别的机器） |
| P0.2 | `adb shell sh /data/local/tmp/dexpad_start.sh` | 输出 `helpers=1` / `engine requested` |
| P0.3 | 等 3 s，`logcat -d -s DexPad | grep 'helper ready'` | 有 `helper ready` |
| P0.4 | `logcat -d -s DexPad | grep 'dex from helper'` | 有 `display=-1`（手机/镜像）或 `display=<id>`（真 DeX） |
| P0.5 | `dumpsys package com.dennis.dexpad | grep versionName` | 与发布版本一致 |
| P0.6 | 屏幕保持点亮：`svc power stayon true`（测试完改回 false） | 截图不是黑屏 |

## 1. 连接与状态（⚡自动）

| 编号 | 用例 | 步骤 | 期望 |
|---|---|---|---|
| A1 | 助手连接 | 重启助手后等 3 s | 引擎日志 `helper ready`，`EngineState` 显示已连接 |
| A2 | 屏幕判定 | 查看 `dex from helper` / `focus display` | 手机模式 `DEX -1`、`FOCUS 0`；真 DeX `DEX <id>` |
| A3 | 鼠标模式默认 | 打开 App 状态卡 | 鼠标模式「开启」、DeX 状态与实际一致 |
| A4 | 断连恢复 | `kill -9` 助手 PID | 8 s 内 supervisor 拉起，引擎重新 `helper ready` |

## 2. 指针（左摇杆 / A / 滚轮）

| 编号 | 用例 | 步骤 | 期望 |
|---|---|---|---|
| B1 ⚡ | 左摇杆移动 | `vgpad stick 0 20000 700 3000` | `dumpsys input` 的 hoveringPointers 坐标改变 |
| B2 ⚡ | A 左键 | `vgpad key 304 150 3000` | 引擎 `left button down` / 抬起后再 log；实际点击光标处 |
| B3 | B 右键 | 映射 B=右键 | 引擎 `right button down`，界面出现上下文菜单 |
| B4 | 滚轮 | LB/RB 按住 | 页面滚动（引擎无日志，看截图/滚动条） |
| B5 | 死区 | 摇杆推到 10% 保持 | 指针不动（<16% 死区） |
| B6 | 精准移动 | 按住 X 推左摇杆 | 指针速度约为正常 15% |

## 3. 方向键（原生导航 + A 跟随焦点）⚡

| 编号 | 用例 | 步骤 | 期望 |
|---|---|---|---|
| C1 ⚡ | 原生转发 | 打开设置，`vgpad hat 0 1 400 3000` | 助手 `PAD 108`；引擎 `pad key 108` + `native navigation`；App 侧 `arrow key` 注入 0 次 |
| C2 ⚡ | A 激活焦点 | 承 C1，`vgpad key 304 150 3000` | 引擎 `A -> DPAD_CENTER (native nav)`；界面进入焦点项（截图） |
| C3 ⚡ | 组合 X+↓ | `vgpad key 307 6000 2600` 后 `vgpad hat 0 1 300 2600` | 引擎 `mix 1 x+down -> volume_down`，助手 `KEYON 0 25` |
| C4 ⚡ | 摇杆退出原生态 | 承 C2，推左摇杆后再按 A | 引擎 `native navigation OFF (stick moved)`，随后 `left button down` |
| C5 | 转发关闭回落 | 把 `btn_left` 改成非方向键，按 ↑ 再按 A | 引擎 `arrow key 19` + `native navigation`，A 仍是 `DPAD_CENTER` |
| C6 | 四个方向 | 分别按 ↑↓←→（单独） | 每次只移动一格；助手 `PAD 103/108/105/106` |
| C7 | 按住重复 | 长按 d-pad 1 s | 目前一按一格（如需连发见「已知限制」） |

## 4. 滚动 / 滑动

| 编号 | 用例 | 步骤 | 期望 |
|---|---|---|---|
| D1 ⚡ | 竖向拖动 | 在可滚动页推右摇杆下 | 助手 `SWIPE 0 x,30%h -> x,80%h`（display 0 或 DeX id），页面平滑翻页；启动器上下滑能触发真正的系统手势 |
| D2 | 竖向拖动（关掉开关） | 「上下滑动用触摸拖动」关掉后推右摇杆 | 引擎发滚轮（页面小步滚动） |
| D3 | 水平拖动 | X+RB / 右摇杆右 | 助手 `SWIPE ... start 25%/75%w -> ±40%w`，页面横向切换 |
| D4 | 方向键不干扰 | 方向键后立刻推摇杆 | 先原生导航，摇杆一动恢复鼠标（无卡死） |

## 5. 光标居中（L3）

| 编号 | 用例 | 步骤 | 期望 |
|---|---|---|---|
| E1 ⚡ | 手机居中 | L3 | 助手 `CENTER(park) -> 接近 w/2,h/2`（±40 px） |
| E2 | DeX 居中 | 接 HDMI 进 DeX 后 L3 | 助手 `CENTER ... -> 接近 1280,800`（2560×1600） |
| E3 | 居中后摇杆 | 居中后立刻推摇杆 | 3 s 锁定内不动，回中后恢复 |

## 6. 应用 / 窗口动作

| 编号 | 用例 | 步骤 | 期望 |
|---|---|---|---|
| F1 ⚡ | 切换软件 | START | 助手 `SWITCH ... rc=0`，前台换成另一个 App |
| F2 ⚡ | 关闭应用 | GUIDE | 引擎 `alt+f4 -> close app on phone`，助手 `CLOSE_APP <pkg> rc=0`，回到桌面 |
| F3 | 关闭（close_window 映射） | 把某键映射为「关闭当前窗口」并按 | 同上（走 `L`） |
| F4 | 关闭桌面时 | 桌面前台按 GUIDE | 助手 `CLOSE_APP skip ...`，桌面不被杀 |
| F5 | 最大化/对齐（手机） | SELECT 等 | 引擎 `maximize skipped on phone`，无副作用 |
| F6 | 最大化（DeX） | 接 DeX 后按 SELECT | 窗口 `am task resize` 生效 |
| F7 | 截图 | 映射截图键 | 手机 `SYSRQ`；DeX `ALT+SYSRQ` |
| F8 | 通知栏 / 主屏 / 返回 | 对应按键 | 分别展开通知、回桌面、返回 |

| F9 | 滑动动作映射 | 把某键映射为「向下滑动」/「向上滑动」 | 助手 `SWIPE ... 30%h -> 80%h` / `70%h -> 20%h`，桌面下拉出通知栏、上滑出应用抽屉 |
| F10 | 缓慢滑动动作 | 映射「缓慢向下滑动」/「缓慢向右滑动」 | 引擎 `swipe ... slow=true ms=700`；位移与普通滑动相同，但拖动更慢（列表逐步滚动） |

## 6.5 强制横屏 / 前台自适应

| 编号 | 用例 | 步骤 | 期望 |
|---|---|---|---|
| L1 | 强制横屏 | 引擎连上助手 | settings get system user_rotation=1 且 ccelerometer_rotation=0；退出引擎恢复自动旋转 |
| L2 | 前台包上报 | 分别打开桌面/抖音/红果/PiliPlus | 助手日志出现 TOP <包名>，引擎 	op package: 同步 |
| L3 | 抖音短滑 | 抖音内推右摇杆上/下 | 助手 SWIPE 的 dy≈30% 屏高，一次一条视频 |

## 7. 媒体 / 音量

| 编号 | 用例 | 步骤 | 期望 |
|---|---|---|---|
| G1 | 音量 ± | X+↓ / X+↑ | 音量变化，`KEYON 0 25/24` |
| G2 | 静音 | 映射静音 | `KEYON 0 164` |
| G3 | 播放/暂停、上/下一首 | 映射 | `KEYON 0 85/88/87` |

## 8. 双击 / 长按 / 组合边界

| 编号 | 用例 | 步骤 | 期望 |
|---|---|---|---|
| H1 ⚡ | 双击 X | `vgpad double 307 60 90 3000` | `double x -> switch_app`，只触发一次 |
| H2 | 滚轮按住持续 | 按住 LB（向下滚动）/ RB（向上滚动）1.5 s | 按下瞬间 `wheel ... started`；助手收到约 15 次 `WHEEL`；松开 `wheel stopped` |
| H3 | 滚轮作次位组合 | 先按住 X 再按 LB | `mix 4 x+lb -> wheel_left`，LB 自身滚动不启动 |
| H4 | 冲突以第一个为准 | 先按住 LB 再按 X | 滚动继续，不触发 X+LB |
| H5 | 非首位键立即响应 | 单独按「上」（或 SELECT） | 按下即执行，日志无 `deferred`，不等松手 |
| H2 | 单击 X（有双击动作） | 单击 X | 延迟 320 ms 后 `single recents fired` |
| H3 | 组合优先 | X+LB | `mix ...`，X 的单击/双击都不触发 |
| H4 | 修饰用法 | 按住 X 推摇杆 | 不触发 X 的单击 |
| H5 | 未映射键 | 按 R3（默认无） | 无任何注入/日志 |

## 9. 模式切换

| 编号 | 用例 | 步骤 | 期望 |
|---|---|---|---|
| I1 ⚡ | SHARE 关闭 | 按 SHARE | 引擎 `mouse mode OFF`，助手 `GONE`（手柄交还） |
| I2 ⚡ | SHARE 开启 | 再按 SHARE | `mouse mode ON` + `GRABBED` |
| I3 | 模式关闭时按键 | 关闭后按 A/d-pad | 系统原生响应（无我们的注入） |
| I4 | 设置页开关 | 关「启用手柄映射」 | 同上；再打开恢复 |

## 10. 稳定性 / 资源

| 编号 | 用例 | 步骤 | 期望 |
|---|---|---|---|
| J1 | helper 崩溃恢复 | `kill -9` helper | 8 s 内 supervisor 重启，引擎重连 |
| J2 | 引擎被杀 | `kill -9` 引擎进程 | 约 10 s 内自动恢复前台服务 |
| J3 | 设备热插拔 | 拔插手柄 / 换手柄 | 助手 `GONE`/`DEV`/`GRABBED`，映射继续可用 |
| J4 | 屏幕旋转/折叠 | 展开/合盖后 L3、滑动 | 居中仍准确（`CENTER(park)`，旋转补偿） |
| J5 | 长时间待机 | 闲置 10 min 后操作 | 首键无丢失（可接受 <100 ms 延迟） |
| J6 | 日志大小 | 连续操作 1 min | `helper.log` 增长可控（无刷屏错误） |

## 11. 已知限制（不是 bug）

- 方向键按住不连发（一按一格）；需要连发可后续加。
- 手机上的「最大化/对齐/切 DeX」跳过。
- 少数只认 ENTER 的 App，A（DPAD_CENTER）可能不激活焦点（待补兼容发送）。
- KernelSU late-load：每次重启需手动跑 `dexpad_start.sh`。
- 强行停止 App 后 Android 禁止后台重启，需手动打开一次。

## 快速回归（发布前必跑）

`A1 A2 B1 B2 C1 C2 C3 C4 D1 E1 F1 F2 H1 I1 I2`，全部 PASS 才发布。
