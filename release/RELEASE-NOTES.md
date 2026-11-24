# v1.67 发布说明（2026-11-24）

包名：`com.dennis.dexpad`　versionCode **69** / versionName **1.67**
配套：KernelSU 模块 `gpm_dex` v1.67 · 助手 `gpminput` v1.67（**本轮未改助手，沿用 v1.66 的字节**）· 测试台 `com.dennis.padtest` v1.1

| 资产 | 文件 | sha256 | 大小 |
|---|---|---|---|
| 应用 | `dexpad-v1.67.apk` | `8aeef7b7d6d5ea01b650a26e18c0eb8f0c4233f647a0cb0a17048be1e2180312` | 2678947 B |
| 模块 | `gpm_dex-v1.67.zip` | `b39af5c500055568331b4acbe0d755510306e686d24c94d1d05eaaf9a58c0f19` | 362092 B |
| 助手 | `gpminput-v1.67` | `1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf` | 851928 B |
| 测试台 | `padtest-v1.1.apk` | `27478cef1c51acddc88c7ef662980ead4720bc95ce38635b0aa816f67de32e50` | 949222 B |

模块 zip 内 `gpminput` 与 `gpminput-v1.67` **同哈希**；APK 内 `assets/gpminput` 解包后亦为同一哈希（三处一致）。

## 1 LB/RB 滚动统一：同一次按压内只走一种机制

### 之前（v1.66）的问题

LB/RB 的默认动作 `scroll_swipe_down` / `scroll_swipe_up` 走的是**混合**路径：先用 `doSwipe(..., slow=true)` 滑一下，
再切进滚轮步进。用户感觉"先滑一下再变成滚轮"，同一次按住里两种机制前后打架，速度也不统一。

### 现在（v1.67）的规则

机制在**按下瞬间**由设置里的「触摸滚动」开关（`v_touch_scroll`）定死，按压期间不切换、释放即清空：

| 「触摸滚动」 | 机制 | 参数 | 1.5s 实测 |
|---|---|---|---|
| **开**（默认） | **连续滑动**（只用 swipe） | 每次 560px、手势 220ms、周期 250ms（`scroll_speed=4`） | **6 × 560 = 3360px**，`SWIPE=6 / WHEEL=0` |
| **关** | **纯滚轮**（只用 wheel） | 每 186ms 一步（`wheel_speed=3`） | **9 步**，`SWIPE=0 / WHEEL=9` |

补充细节：
- **锚点**：纵向固定在 task 的 **40%（手指上滑）/ 60%（手指下滑）**，行程恒 **560px**；只有 task 高度不足时才缩短并记日志
  `shortened reason=task-height`。这样不会再出现 v1.66 里"锚点把行程夹短到 460/540px"的问题。
- **候选锚点**：横向 30% / 70% 交替（保留"两个候选重试"的健壮性，但不影响纵向行程）。
- **滚轮锚点**（`ensureWheelAnchor`）：`REL_WHEEL` 只作用于**指针悬停的窗口**，而空闲 8 秒会销毁指针设备。
  所以滚轮模式在按压开始时先把指针放回 task 中心（隐藏时用 `positionPointer`，只一次，不每帧），
  日志 `wheel anchor: pointer to task center (hidden=true was=…)`。实测空闲隐藏 9s 后按住 RB 1.5s → 内容位移 **921px**（系统设置）。
- `X+LB / X+RB`（翻页动作 `wheel_left/right`）**未改**，仍是横向手势（dx=+1263 / −1257）。
- 串行性不变：任意时刻 ≤1 条手势，`SWIPE_DROP=0`。

### 双击文案修正

`ButtonDetailActivity` 里双击说明从「320 ms」改为「**400 ms**」，与 `DOUBLE_WINDOW=400L` 一致（v1.62 起的实际行为就是 400ms，之前只是文案没跟上）。

## 2 验证（可复跑）

| 项目 | 结果 | 证据 |
|---|---|---|
| LB/RB 专项（t29，debug 字节 df26e461） | **22/22 PASS** | `work/docs/VERIFY-lbrb-v167.md`、`work/docs/evidence-lbrb/verify-v167-t29.log` |
| **发布字节** `8aeef7b7` 抽检（哈希/版本/横屏 + 双机制 + 400ms 文案） | **12/12 PASS** | `work/docs/evidence-v167/verify_v167_release.result.txt` |
| **发布字节** 回归冒烟（23 项：5 修 3 功能 + 6 项不得回退 + 横屏守护 + CPU） | **23/23 PASS** | `work/docs/evidence-v167/verify_v167_smoke.result.txt` |
| 装机哈希校验（APK/助手三处/zip 内/APK assets/重启后） | 全部一致 | `work/docs/INSTALL-v167.md` |

关键数字：
- 触摸模式 LB/RB：`SWIPE=6 / WHEEL=0`，`mode=swipe`，内容位移 **dPY=1415**（PY 1415→0 / 0→1415）。
- 滚轮模式 LB/RB：`SWIPE=0 / WHEEL=9`，`mode=wheel`；设置列表内容位移 **921px**。
- 连续性：start-to-start **250–259ms**、手势 220ms → 典型空档 **30–39ms**；t29 最坏一次 **150ms**（≤150ms 阈值，贴边）。
- 30s 长稳（t22 样本）：触摸 `swipe=24 wheel=0`、滚轮 `swipe=0 wheel=36`，机制切换 **0**。
- 回归：X+LB dx=+651、X+RB dx=−1536、右摇杆竖 dPY=1415/横 dHS=512、L3 1281,799、空闲隐藏首滑 dPY=1415、
  Y+上 PiliPlus / Y+下 抖音、SELECT 通知栏 `rc=0 dur=391ms`、横屏守护 ≈2000ms。
- 发布字节 60s 空闲 CPU：**0.93%**（线程级 0.93%、`cutime+cstime` 0.00%），与 v1.66 的 0.82% 同量级，远低于 v1.65 的 1.62%。

## 3 已知限制 / 注意事项

- **滚轮也有"生效范围"**：`REL_WHEEL` 只作用于指针悬停的窗口。v1.67 已把指针放回 task 中心，但如果目标 App 的可滚列表
  不在该位置（或 App 只认触摸滚动），仍可能滚不动 —— 此时把「触摸滚动」打开用滑动手势更可靠。
- **空档贴边**：t29 长稳样本里出现过一次 150ms 空档（阈值 ≤150ms）。这是偶发抖动，不是机制切换；发布说明写"典型 30–39ms、最坏 150ms"。
- **多显示设备**：`uiautomator` / `screencap` 默认只附着 display 0，部分 App（系统设置、PiliPlus）的列表节点/截图不在该显示上，
  因此它们用 helper 计数 + app 日志证明机制，内容位移以 padtest 与系统设置同一文本节点（921px）为准。
- **发布包不响应调试广播**：`DEBUG` / `HCMD` 只在 debuggable 构建生效（`DebugReceiver` 主动忽略）。
  所以本轮机制开关在发布字节上用「改 prefs + 重启引擎」验证，不是广播。
- 其余 v1.66 的已知限制（`display_size_forced` 清不掉、DeX 外接屏未完整回归、触摸点击依赖估算坐标等）不变。

## 4 安装

```bash
# 1) 安装 APK
adb install -r dexpad-v1.67.apk
# 2) 安装 KernelSU 模块（或用 KernelSU/Magisk App 刷 gpm_dex-v1.67.zip）
adb push gpm_dex-v1.67.zip /data/local/tmp/
adb shell "su -c '/data/adb/ksu/bin/ksud module install /data/local/tmp/gpm_dex-v1.67.zip'"
# 3) 重启，确认模块生效
adb reboot
adb shell "su -c 'grep version /data/adb/modules/gpm_dex/module.prop; sha256sum /data/adb/gpm/gpminput'"
# 预期：version=v1.67 / versionCode=69；助手 sha256 = 1bf7306f…f4bf（与 v1.66 相同）
```

从 v1.66 升级：直接 `adb install -r` + 刷 v1.67 模块 zip + 重启；助手字节没变，所以只换 APK 也能用（模块 zip 主要更新 module.prop 版本号）。

校验和一览见同目录 `SHA256SUMS.txt`；装机校验表见 `work/docs/INSTALL-v167.md`。
