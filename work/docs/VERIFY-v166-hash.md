# VERIFY-v166-hash · 最终哈希复验（t10/t11 之后）

> **历史记录（t15 之后）**：本文件绑定助手 `6076b63b…` / APK `e8a91185…`，已被 **`work/docs/VERIFY-v166-final.md`**（最终 APK + 助手 `1bf7306f…`）取代；本文件仅作历史证据保留。

> 任务：t12（最终哈希复验）· 设备：SM-F9360（adb `192.168.10.36:6666`，横屏 2560×1600）
> 目的：t4 的 64 项验证跑在助手 `4f261754…` 上；t10/t11 又把 `cmd_selftest` 改了两轮，发布哈希变成 `6076b63b…`。
> 本复验在**最终哈希**上重跑「自检 / K 组 / 控制面抽检」，并论证 t4 其余项仍有效，消除「验收哈希 ≠ 发布哈希」的风险。
> 运行时间：`?` 自检 + 控制面 02:18:04–02:19:3x（≈90s），K 组 02:19:39–02:21（≈90s），合计 < 4 分钟（要求 10 分钟内）。
> 原始证据：`work/docs/evidence-v166-hash/`（`hashes.txt`、`sha256_device.txt`、`hash_recheck.log`、`K.result.txt`、`K.log`）

## 0 结论

| # | 项 | 结果 |
|---|---|---|
| 1 | 最终助手 sha256 = **`6076b63b806eb26985d9f0d26d2aa4e546e2b68daf6de5c737c4f6fb815233b0`**（851880 B），`/data/adb/gpm` 与模块目录一致，且 = 本地编译产物 | PASS |
| 2 | **此哈希即 v1.66 发布哈希**（HELPER-v166.md §1.6/§2.9 与 integrator 约定同值） | PASS |
| 3 | `?` 自检：指针可见 / 空闲隐藏后两态，13 项 CAP 全 1、`ERR count=0`，唯一差异 `INFO pointer device=on/off`（t11 修复点） | PASS |
| 4 | K 组复跑（最终哈希）：`u` 负例 skip=1、`u` 正例 Dozing→Awake done=1、`g`→`CENTER(steps+gain 4.68)`、`c` 与 `P` 真值 max 3px、`P` 落点 max 4px、10 条命令 48ms | **PASS=10 FAIL=0**（含 4 条基线） |
| 5 | 控制面抽检：串行队列 overlaps=0；Y+上/下 组件解析启动；X 双击→Recents；SELECT→NotificationShade；L3 居中 3px+mouse_click | **PASS=8 FAIL=0** |
| 6 | 设备恢复：横屏 2560×1600、Awake、rotation1/accel0、无 vgpad、助手+引擎运行、padtest 前台 | PASS |

## 1 哈希来源与链条

| 阶段 | 助手 sha256 | 说明 |
|---|---|---|
| t2 | `dc41cb9b…` | 串行手势队列 + `u`/`c`/`g` + open_app 组件解析 |
| t2-r2 | `4f261754d80bea69dfc6d8af46608800195c05bc4bd68bca0e220e5d37d059a5` | **t4 的 64 项全量验证所用**（`VERIFY-v166.md` 基线行） |
| t10 | `139087e75c706eae8a29da13ac0ba3b8bb9d079787a35415b806fa3c05b09376` | `CAP gesture` 改「能力」语义 |
| **t11 / 发布** | **`6076b63b806eb26985d9f0d26d2aa4e546e2b68daf6de5c737c4f6fb815233b0`**（851880 B） | `CAP mouse/kbd/wheel` 改「能力」语义 + `CAP gamepad` + `INFO pointer/kbd device` |

四个同哈希副本（`hashes.txt` / `sha256_device.txt`）：

```
6076b63b…  project/app/src/main/assets/gpminput        （本地编译产物）
6076b63b…  /data/adb/gpm/gpminput                      （设备运行副本）
6076b63b…  /data/adb/modules/gpm_dex/gpminput          （模块目录；service.sh:40 开机以它为源同步）
6076b63b…  /data/local/tmp/gpminput_v166               （设备暂存）
```

验证命令原样输出：

```
$ adb -s 192.168.10.36:6666 shell "sha256sum /data/adb/gpm/gpminput /data/adb/modules/gpm_dex/gpminput"
6076b63b806eb26985d9f0d26d2aa4e546e2b68daf6de5c737c4f6fb815233b0  /data/adb/gpm/gpminput
6076b63b806eb26985d9f0d26d2aa4e546e2b68daf6de5c737c4f6fb815233b0  /data/adb/modules/gpm_dex/gpminput
```

## 2 t10/t11 到底改了什么（源码级证据）

`project/app/src/main/assets/gpminput.c`（只读核对，未修改）：

| 符号 | 定义 | 全部引用点 | 结论 |
|---|---|---|---|
| `cmd_selftest` | 1693 | 定义 + 2675（`case '?'` 分支内 `fork()` 后调用） | 只有 `?` 能到达；子进程执行完即 `_exit(0)` |
| `uinput_capable` | 1663 | 定义 + 1694（`cmd_selftest`） | 只被自检调用 |
| `input_enum_capable` | 1669 | 定义 + 1707（`cmd_selftest`） | 只被自检调用 |
| `any_device_grabbed` | 1674 | 定义 + 1714（`cmd_selftest`） | 只被自检调用 |
| `gesture_queued` | 2061 | 声明 180 + 定义 + 1713（`cmd_selftest`） | 只被自检调用 |

`?` 的处理（gpminput.c:2674 附近）：

```c
case '?':
    ...
    if (fork() == 0) {
        child_quiet_stdio();
        cmd_selftest();
        _exit(0);
    }
```

自检输出（gpminput.c:1696–1714，t10/t11 后的口径）：

```c
out("CAP mouse %d", ui);  out("CAP kbd %d", ui);  out("CAP wheel %d", ui);
out("CAP swipe %d", access("/system/bin/input", X_OK) == 0 ? 1 : 0);
out("CAP notif %d", access("/system/bin/cmd", X_OK) == 0 ? 1 : 0);
out("CAP power %d", access("/system/bin/input", X_OK) == 0 ? 1 : 0);
out("CAP force %d", access("/system/bin/cmd", X_OK) == 0 ? 1 : 0);
out("INFO apex %d", access("/apex/com.android.art/lib64/libnativeloader.so", R_OK) == 0 ? 1 : 0);
out("CAP screen %d", screen_awake_readable());
out("CAP wake %d", (ui || access("/system/bin/input", X_OK) == 0) ? 1 : 0);
out("CAP cursor %d", access("/system/bin/dumpsys", X_OK) == 0 ? 1 : 0);
out("CAP gamepad %d", input_enum_capable());
out("CAP devices %d", g_ndev);
out("CAP gesture %d", access("/system/bin/input", X_OK) == 0 ? 1 : 0);
out("INFO pointer device=%s", g_mouse >= 0 ? "on" : "off");
out("INFO kbd device=%s", g_kbd >= 0 ? "on" : "off");
out("INFO gesture busy=%d queued=%d", gesture_busy() ? 1 : 0, gesture_queued());
out("INFO devices_grabbed=%d", any_device_grabbed());
```

- t10 的改动 = `CAP gesture` 从 `gesture_busy()` 换成 `input` 可执行；运行时状态移入 `INFO gesture busy/queued`。
- t11 的改动 = `CAP mouse/kbd/wheel` 从「设备当前已创建」换成 `/dev/uinput` 可写（`uinput_capable`），新增 `CAP gamepad`、`INFO pointer/kbd device`。
- 两次改动新增/修改的符号**全部**只在 `cmd_selftest` 内被引用（上表），`?` 分支是唯一入口；控制命令（`M/B/S/H/V/Z/O/P/W/J/F/X/E/t/f/L/r/A/D/C/N/K/G/U/I/q/k/l` 等）没有调用它们，也没有任何 `if (CAP …)` 之类的分支——CAP 行只是打印。
- 结论：**受影响面 = `?` 自检文本 + App 设置页「链路自检」显示**；控制面（手势队列/唤醒/open_app/指针/按键）代码路径未变。

## 3 `?` 自检两态（最终哈希）

`?` 通过 App 的调试通道 `am broadcast -a com.dennis.dexpad.HCMD --es cmd '?'` 发给运行中的助手（`helper.log` 记录 `SELFTEST begin/end`）。S1 前用真实 vgpad L3 显示指针；S2 在无输入 10s（> `idle_hide_sec=8`）后发（指针已被引擎销毁）。

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| S1 指针可见 | 13 项 CAP 全 1（`CAP devices` 为数量，不计）、`ERR=0`、`INFO pointer device=on` | CAP n=13，非 1 项=无，`ERR=0`，`INFO pointer device=on` | PASS |
| S2 空闲隐藏后 | CAP 行与 S1 逐字相同、全 1、`ERR=0`、`INFO pointer device=off` | CAP n=13，与 S1 完全一致（`same=yes`），`ERR=0`，`pointer=off` | PASS |

原始输出（`hash_recheck.log`）：

```
===== S1 `?` 自检：指针可见 =====
SELFTEST begin
CAP mouse 1 / CAP kbd 1 / CAP wheel 1 / CAP swipe 1 / CAP notif 1 / CAP power 1 / CAP force 1
INFO apex 1 / CAP screen 1 / CAP wake 1 / CAP cursor 1 / CAP gamepad 1 / CAP devices 1 / CAP gesture 1
INFO pointer device=on
INFO kbd device=on
INFO gesture busy=0 queued=0
INFO devices_grabbed=1
SELFTEST end
[S1] PASS | 13 项 CAP 全 1、ERR=0、pointer device=on

===== S2 `?` 自检：空闲隐藏后（>idle_hide 8s） =====
CAP 行与 S1 逐字相同（same=yes）；INFO pointer device=off；ERR=0
[S2] PASS | 指针隐藏后 CAP 与 S1 逐字相同全 1、ERR=0、pointer device=off
```

这一组正是 t10/t11 的修复目标：旧版在「手势在飞」或「指针已隐藏」时会把 `CAP gesture`/`CAP mouse`/`CAP wheel` 报成 0，设置页显示「缺失」；现在两态都全 1。

## 4 K 组复跑（最终哈希，`sh v166_auto_suite.sh K`）

`K` 段会短暂停掉正式助手/引擎、用 FIFO 起独立助手实例做命令级测试，结束后 `start_all` 恢复（模块 `service.sh` 监督进程 + 引擎）。基线 4 条（APK/版本/助手哈希/焦点）+ K1–K6：

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| BASE-HELPER | helper sha256 = 发布哈希且 gpm 与模块一致 | `6076b63b… / 6076b63b…` | PASS |
| K1 `u` 负例（亮屏） | 空操作 `skip=1`、无 uinput 注入 | `WAKE was=Awake now=Awake uinput=0 skip=1 probe=1` | PASS |
| K2 `u` 正例（Dozing） | → Awake 且 `done=1 src=uinput|input224|power` | `WAKE was=Toggling now=Awake uinput=1 done=1 src=uinput took=444ms` | PASS |
| K3 `g` → `O` | `O` 使用新增益 4.68 | `GAIN center=0.000 ptr=4.680 effective=4.680`；`CENTER(steps+gain 4.68) rot=1 -> 1280,800` | PASS |
| K4 `c` 回包 | `CURSOR … display=0 space=logical` 且与 P 真值 ≤5px | 3/3，max **3px**；`CURSOR 1278 797 display=0 space=logical …` | PASS |
| K5 `P` 落点 | 点击误差 ≤40px | 3/3，max **4px** | PASS |
| K6 10 条命令 | <100ms | **48ms**（10×`g`，写入→10 条 `GAIN` 全部回包） | PASS |

运行输出末尾：`PASS=10 FAIL=0`（4 基线 + 6 K）。

## 5 控制面抽检（最终哈希，`v166_hash_recheck.sh`）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| C1 串行手势队列 | 6 次交替推杆：`overlaps=0` 且 `starts==dones≥6` | `starts=18 dones=18 overlaps=0 orphan=0 drops=0 queued=6 inflight=0` | PASS |
| C2A Y+上 | 前台 piliplus + 组件解析启动（fallback=0 monkey=0） | `top=com.example.piliplus/.MainActivity`；`OPEN_APP com.example.piliplus via com.example.piliplus/.MainActivity rc=0` | PASS |
| C2B Y+下 | 前台抖音 + 组件解析启动（fallback=0 monkey=0） | `top=com.ss.android.ugc.aweme/.splash.SplashActivity`；`OPEN_APP com.ss.android.ugc.aweme via com.ss.android.ugc.aweme/.splash.SplashActivity rc=0` | PASS |
| C3 X 双击（400ms） | 前台 RecentsActivity | `top=com.sec.android.app.launcher/com.android.quickstep.RecentsActivity` | PASS |
| C4 SELECT | NotificationShade + `NOTIF swipe rc=0` | `shade=1`；`NOTIF swipe rc=0 dur=390ms` | PASS |
| C5 L3 居中 | 落点误差 ≤80px 且为鼠标点击 | `click=1281,803`（err **3px**），`mouse_click=1 key_enter=0` | PASS |

运行输出末尾：`PASS=8 FAIL=0`（S1/S2 + C1–C5）。

## 6 t4 其余项为什么仍然有效（58 项）

**逻辑链**：

1. **App 侧零变化**：安装的 APK sha256 `e8a91185…fcf7b031` 与 t4 时完全相同（本次 K 的 BASE-APK 行复核）；t10/t11 没有改 Kotlin 代码，也没有改 APK。t4 中所有 app 侧行为（H1 时延、I2 双击逻辑、J4/J5 分栏、J6 竖屏回落、E/D 的应用侧闭环等）跑的是**同一份机器码**。
2. **助手控制面零变化**：t10/t11 新增/修改的符号只在 `cmd_selftest` 内被引用，`?` 是唯一入口（§2 表）。所有控制命令（手势队列、`u` 唤醒、`w` open_app、`P/O/c/M` 指针、按键/滚轮/触摸）走的还是 t2 时代那段代码。
3. **行为等价已抽检**：最终哈希上重跑了 K 组（u/g/c/P/10 命令）与控制面 5 条（串行队列、两个 open_app、双击、SELECT、L3），数值与 t4 一致（L3 3px vs t4 2–5px；`c` max 3px；`P` max 4px；10 条命令 48ms vs 61/62ms）。
4. **本次复验直接覆盖的 t4 行**：基线 4 + K 6 + 控制面 8 = 18 行；其余 46 行按 (1)(2) 论证不受 t10/t11 影响，其中风险最高的几类也被抽检（见映射表）。

| t4 组 | 是否依赖助手 | 本次如何覆盖 |
|---|---|---|
| A 串扰（串行队列/仲裁） | 是（手势队列） | C1 `overlaps=0`、`starts==dones`；A3 仲裁在 t4 已证，代码路径未动 |
| B dpi / C 速度 / E 边界 | 是（`P/O/c/M`、`V/Z`） | K4/K5（`c`/`P`）证明指针与手势坐标链路可用；参数、代码未动 |
| D L3 居中 / J3 | 是（`P/O/c` + app 闭环） | C5：L3 落点 1281,803（3px）+ mouse_click |
| F 摇杆唤醒 | 是（`u`） | K1/K2（负例 skip=1、正例 done=1 src=uinput） |
| G 打开应用 | 是（`w`） | C2A/C2B（组件解析 via、fallback=0、monkey=0） |
| H1 时延 / H3 CPU / J4/J5/J6 | 否（app 侧） | APK 未变（同一机器码）；H2 prep 来自 SWIPE 队列，C1 的 SWIPE 行仍有 `prep=<us>` |
| I1/I3/I4（DPAD_CENTER、X+LB/RB） | 是（`D`、`V` 手势） | 未再抽检；`V` 手势队列 = C1 同一队列，`D` 键码路径未动 |
| I2 双击 / I5 空闲恢复 / I6 SELECT | 是（`N`）+ app | C3（双击→Recents）、C4（NOTIF）、S2（隐藏后 pointer off）+ C5（隐藏后 L3 恢复居中 3px） |
| J1/J2/J7（横屏/守护） | 是（`r`） | 未再抽检；`r` 路径未动，且 C5 证明当前仍是横屏 2560×1600 |

**证据限制（如实写明）**：t4 时的助手二进制 `4f261754…` 与当时源码都没有留存（设备/本地均已被 t10/t11 覆盖），所以**无法做 t4↔最终 的二进制 diff**。上面的论证依靠：官方变更记录（HELPER-v166.md 变更链）+ 最终源码的符号/调用点隔离 + 最终哈希上的行为抽检。若 reviewer 需要二进制级证明，只能由 t10/t11 的执行者提供其编译中间产物或 git 提交；目前仓库没有这两次改动的独立提交（`git log` 仍停在 v1.65）。

## 7 发布打包风险（integrator 必看）

核对发布哈希时发现 3 处**本地旧副本/元数据**，不影响设备当前运行（设备四个副本都是 `6076b63b…`），但会影响「从仓库重新打 release 包」：

| 位置 | 现状 | 风险 |
|---|---|---|
| `project/ksu-module/gpminput` | `B8D12518…`（782920 B，11-08） | 若模块 zip 从这里取二进制，会把旧助手（无 `u/c/g`、无串扰修复）装到新设备；`service.sh:40` 是 `cp -f $MODDIR/gpminput /data/adb/gpm/gpminput`，模块目录是开机同步源 |
| `project/lsp-dexpad/app/src/main/assets/gpminput` | `10CBDBA1…`（782624 B，pre-t2） | 若重建 APK，APK 内 assets 仍是旧助手；`EngineService.ensureHelperBinary` 在 `/data/adb/gpm/gpminput` 缺失时会从 assets 解包 |
| `/data/adb/modules/gpm_dex/module.prop` | `version=v1.65` / `versionCode=67` | 模块管理器里会显示 1.65，与 v1.66 发布不符 |

建议 integrator：打包前把 `6076b63b…` 同步到上述两处二进制，并把 module.prop 升到 `v1.66/68`；发布后按 `hashes.txt` 复核 zip/apk 内的助手哈希。

## 8 设备恢复状态（复验结束）

| 项 | 实测 |
|---|---|
| 助手 | `/data/adb/gpm/gpminput`=`/data/adb/modules/gpm_dex/gpminput`=`6076b63b…`；单实例 pid 7745，`INFO devices_grabbed=1` |
| 引擎 | `pidof com.dennis.dexpad`=7748，前台服务在跑，`helper ready` |
| 显示 | 横屏 2560×1600、`cmd window user-rotation=lock 1`、`user_rotation=1`、`accelerometer_rotation=0` |
| 屏幕/前台 | `mWakefulness=Awake`；padtest CursorTestActivity 前台（`mCurrentFocus=Window{…padtest…}`） |
| 指针 | L3 → 1281,803（3px）、A=mouse click；空闲 8s 自动隐藏、再按 L3 恢复 |
| 其他 | `pointer_speed=-1`、`force_landscape=true`、prefs 原样、无 vgpad 残留 |

## 9 复跑方式与证据清单

```sh
# 1) 哈希（合约验证命令 1）
adb -s 192.168.10.36:6666 shell "sha256sum /data/adb/gpm/gpminput /data/adb/modules/gpm_dex/gpminput"

# 2) K 组（合约验证命令 2；脚本 EXPECT_HELPER 已更新为发布哈希，可用环境变量覆盖）
adb -s 192.168.10.36:6666 push work/scripts/v166_auto_suite.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/v166_auto_suite.sh K"

# 3) 自检两态 + 控制面抽检
adb -s 192.168.10.36:6666 push work/scripts/v166_hash_recheck.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/v166_hash_recheck.sh"
```

| 文件（`work/docs/evidence-v166-hash/`） | 内容 |
|---|---|
| `hashes.txt` | 发布哈希、四个副本、历史哈希链、打包注意事项 |
| `sha256_device.txt` | 合约验证命令 1 的原始输出 |
| `hash_recheck.log` | S1/S2 自检 + C1–C5 控制面抽检原始输出（PASS=8 FAIL=0） |
| `K.result.txt` / `K.log` | K 组逐条判定（PASS=10 FAIL=0）与阶段日志 |

脚本：`work/scripts/v166_hash_recheck.sh`（本次新增）、`work/scripts/v166_auto_suite.sh`（`EXPECT_HELPER` 更新为发布哈希并支持 `EXPECT_APK/EXPECT_HELPER` 环境变量覆盖）。
