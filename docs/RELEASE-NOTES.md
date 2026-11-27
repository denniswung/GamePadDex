# v1.70 发布说明（2026-11-27）

包名：`com.dennis.dexpad`　versionCode **72** / versionName **1.70**
配套：KernelSU 模块 `gpm_dex` v1.70 · 助手 `gpminput` v1.70（`eb0b5dfc`，控制通道拖拽产品级化）· 测试台 `com.dennis.padtest` **v1.4**（`0f4a9191`，本轮不升 v1.5）

| 资产 | 文件 | sha256 | 大小 |
|---|---|---|---|
| 应用 | `dexpad-v1.70.apk` | `05f4f11f2e48b498556abc35ea58bbc873f032128529d83d6abe9ea5eced876c` | 2688107 B |
| 模块 | `gpm_dex-v1.70.zip` | `60bdd8d30a9e453bafa139cf09eb7facef1b3dd4460e5d70dcec64fbfd9a9ac8` | 368446 B |
| 助手 | `gpminput-v1.70` | `eb0b5dfc6d5403b30d8200467f773e628729ea5290d1574aeb5651bf33c8c31c` | 852976 B |
| 测试台 | `padtest-v1.4.apk` | `0f4a91911360cb4051fff9b54711508e4dc90de797be6ec0e55e83e9a967056d` | 956738 B |

模块 zip 内 `gpminput` 与 `gpminput-v1.70` 同哈希；APK 内 `assets/gpminput` 解包后亦为同一哈希（六处一致：仓库三处 + release + zip 内 + APK assets + 设备两处）。

## 0 覆盖率与门槛（先读这一段）

- **`product FAIL = 0`**：142 条用例 **37 PASS / 5 FAIL / 100 BLOCKED**；5 条 FAIL 均非产品缺陷
  （MIX-009 / LOG-001 / RPT-002 经维护者批准降级、RPT-003 padtest TXT 导出未实现、BTN-001 启动时序）。
- **发布门槛：未达**（P0 41.1%、P1 16.7%）；按 `work/docs/V169-FINAL-VERIFY.md` 的
  `Maintainer override: captain, 2026-11-27` **批准按偏差发布**。
- **自动化上限 40–45/142**，其余以已知限制 + 真机抽样覆盖，**不虚报 PASS**。
- 明细：`work/docs/V169-FINAL3.md`（t72 复验）、`work/docs/V169-FINAL-VERIFY.md`、`work/docs/REVIEW-v170.md`；
  原始证据 `work/docs/evidence-v169/t72_all.out` 等。

## 1 本轮改动（padtest 滚轮 + 控制通道拖拽产品级化）

### 1.1 助手：root 控制通道支持拖拽（t66，产品级）

- `gpmctl.sock` 与 App 通道**复用同一套命令语义**（`handle_line`），拖拽状态放在 **mmap 共享页**，
  以 `shared_drag_poll` 每 20px 分块交给 `drag_move`，`drag_tick` 负责发帧；`e` 先 drain 再 `drag_release`。
- **协议**：`d <display> <x> <y>` 按下 → `m <display> <dx> <dy> <ms>` 移动 → `e [display]` 抬起；
  **1.5s 无 `m` 自动抬指**（helper 日志 `why=auto-up`），不会留下僵尸拖拽。
- **故障码**：`ERR_ARG d`（缺参）、`ERR_STATE m no-down`（未按下就移动）。
- 连接断开不影响 App 会话；`?` 自检 CAP 13 项、ERR=0。

### 1.2 padtest：真实滚轮事件（t65 / t71）

- `ProbeActivity` 处理 `ACTION_SCROLL` / `AXIS_VSCROLL`，`AxisLockView` 在 `onGenericMotionEvent` 记录纵向/横向滚轮；
  padtest 自身计数在 a11y 不可读时以 `PadMetrics` / JSON 计数为证据（t71：0→2→4）。

### 1.3 结论口径（重要）

| 项目 | 结论 | 说明 |
|---|---|---|
| **滚轮投递（4 向）** | **PASS** | `S 8` → `WHEEL 8 h=0` + PadProbe `v=8.0`；`S -8` → `WHEEL -8 h=0` + `v=-8.0`；`H 8` → `WHEEL 8 h=1` + `h=8.0`；`H -8` → `WHEEL -8 h=1` + `h=-8.0` |
| **滚轮内容位移** | **BLOCKED(wheel-content-displacement-unmeasurable)** | 前台无可滚内容 / a11y 树退化为仅全屏根节点（text=0、bounds 全屏），`input swipe` 对照同样不可读。**本条不是 PASS，发布说明不得写成“S 8 内容 PASS”** |
| **控制通道拖拽** | **PASS** | t72：`vertical_offset` 5→7；更大位移 auto-up 7→12；本轮发布字节：竖向 `voff 0→3`、横向 `hx 0→500`、auto-up `voff 3→5`、`ERR_ARG`/`ERR_STATE` 正确、pid 稳定无 SIGPIPE |
| **MIX-001 / MIX-003** | **PASS** | 内层 offset 0→3→5→7→12 单调增，外层不动 |
| **MIX-002 / 004~008** | **BLOCKED(outer-measurement-inconclusive)** | a11y 树空，外层不可读 |

## 2 发布字节验证（装机 + reboot 之后，`05f4f11f`）

| 项目 | 结果 |
|---|---|
| 装机/自启/横屏 | base.apk == 本地 `05f4f11f…`；`/data/adb/gpm` == 模块 == `eb0b5dfc…`；module.prop v1.70/72；helper + EngineService 自启；rotation 1 / app 2560×1600 / rot=1 / accel=0 |
| LB/RB 拖拽三档 | **74 / 254 / 1622px**（判据 150 / 450 / 1200–2200），期间 `SWIPE=0 / WHEEL=0`（第二轮 71 / 246 / 1597px） |
| 滚轮模式 | RB 1.5s → **WHEEL=9 / SWIPE=0** |
| **控制通道 d/m/e** | 竖向 `voff 0→3`；横向 `hx 0→500`；auto-up `voff 3→5` + helper `why=auto-up`（6 条）+ 后续 `OK e`；`ERR_ARG d` / `ERR_STATE m no-down` |
| P 六点 | `402,1202` `1997,300` `104,104` `2445,1496` `1284,804` `700,999`，最大 err **3px** |
| `?` 自检 | CAP **13/13 = 1**、ERR=0 |
| X+LB / X+RB | dx **+1260** / **−1260** |
| 回归冒烟 23 项 | 21 项直接 PASS；RS3-V / RS4-HIDDEN 的“外层 PY”判据受 padtest v1.4 内层 `vList` 抢手势影响，改用 `vertical_offset 0→14` + `touch.path_px 475` + helper `Z=4` 复测 → 2/2 PASS；SELECT 判据修正为“焦点窗口 = NotificationShade”（展开后 `mCurrentFocus=null`，旧判据漏判）→ PASS |
| 其它回归 | L3 `1281,804`、满推 `2559,801`、Y+上 PiliPlus / Y+下 抖音、d-pad+DPAD_CENTER、X 双击 Recents、I5 0px、SELECT `rc=0 dur=389ms`、横屏守护 ≈3750ms、CURSORQ=0 |

证据：`work/docs/evidence-v170/`（`verify_v170_extra.result.txt` 19/19、`verify_v170_smoke.result.txt`、`verify_v170_recheck2.result.txt` 2/2）。

## 3 升级注意

- **助手必须与 APK 一起换**（`b806f39b` → `eb0b5dfc`）：顺序 装 APK → 刷 `gpm_dex-v1.70.zip` → **重启**。
- **padtest 保持 v1.4**（`0f4a9191`）：v1.5 未交付，滚轮在测试台的可测性受限已回退；滚轮内容位移保持 BLOCKED，不为凑数改写结论。
- 回退 v1.69：`adb install -r -d dexpad-v1.69.apk` + 刷 v1.69 模块 zip（助手回 `b806f39b`）+ 重启。
- 控制通道仅 root 可用：`/data/adb/gpm/gpmctl.sock`（0700 目录 / 0600 socket / `SO_PEERCRED` uid==0），
  客户端 `/data/local/tmp/gpmctl <sock> <cmd>`；不需要时 `touch /data/adb/gpm/gpmctl.disabled` 后重启助手。

## 4 已知限制与盲区

- **滚轮内容位移不可自动判定**（`wheel-content-displacement-unmeasurable`）：这是测试台/前台页面能力限制，不是滚轮失效（投递链与 9 步累计 2209px 已证）。
- **`ctl-channel-drag-not-delivered`（32 条）**：经 App 通道的 `d/m/e` 在测试台侧收不到，属测试通道限制；控制通道（`gpmctl`）路径已实测 PASS。
- **padtest v1.4 内层 `vList`** 会接住竖推（外层 PY 不动），必须用 `vertical_offset` / `touch.path_px` 判定。
- 滚轮仍受指针悬停窗口限制（`ensureWheelAnchor` 已缓解）；`display_size_forced=1600,2560` 清不掉（v1.66 起 caveat）；DeX 外接屏未完整回归。

## 5 安装

```bash
adb install -r dexpad-v1.70.apk
adb push gpm_dex-v1.70.zip /data/local/tmp/
adb shell "su -c '/data/adb/ksu/bin/ksud module install /data/local/tmp/gpm_dex-v1.70.zip'"
adb reboot
adb shell "su -c 'grep version /data/adb/modules/gpm_dex/module.prop; sha256sum /data/adb/gpm/gpminput'"
# 预期：version=v1.70 / versionCode=72；助手 sha256 = eb0b5dfc…c8c31c
```

校验和见同目录 `SHA256SUMS.txt`；装机校验表见 `work/docs/INSTALL-v170.md`。
