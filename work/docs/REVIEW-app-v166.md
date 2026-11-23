# REVIEW-app-v166 · t3 应用侧实现审查

> 任务：t6（审查 t3 应用侧：dpi/速度/居中/边界、Y+上/下、摇杆唤醒、提速、无回归）· attempt 1
> 审查人：reviewer · 时间：2026-11-24 02:45 CST · 设备：SM-F9360（adb 192.168.10.36:6666，横屏 2560×1600）
> 结论：**NEEDS_REVISION**（t3 的 9 条 acceptance 中 7 条满足；**#4 dpi 与 #5 滑动速度的“实测依据”不成立/不可证伪**：t4 B5/C4 是硬编码 PASS，B1 满推从贴边起手被右边缘夹取，C 组只测注入手势几何、未测实际滚动；另 H3 CPU 口径不可比——见 R1–R4。t3 代码的核心修复本身经审查成立，问题集中在证据/验证链。）
> Blocking findings：**R1（B5/C4 硬编码 PASS）**、**R2（B1 夹取）**、**R3（C 速度口径）**、**R4（CPU 口径）**；R5–R9 为非阻塞质量项。
> 被审 t3：应用 1.66/68；源码 `EngineService.kt` sha256 `16ccc5b3…`（106161 B）、`ActionRouter.kt` `ed37ab70…`、`Prefs.kt` `183f9199…`、`RootInput.kt` `87746573…`、`ConfigActivity.kt` `0e7018e3…`、`ButtonDetailActivity.kt` `408e3eeb…`、`DisplayState.kt` `962b67fb…`（与 t4 reviewedArtifacts 一致）。
> 装机 APK sha256 `e8a9118592d07b4be10116f12ae93cccb864799da116425e1948ebd9fcf7b031`（= 本机 `app-debug.apk`，3130719 B；与 t4 基线一致）。t3 输出里的 `1F8A4234…` 是 t8 重建前旧值，APP-v166.md 已改为实际值；本报告按实际 hash 记录（R8）。

## 1. 结论摘要

1. **L3 居中根因修复成立**：`requestCenter()` 先清 `nativeNav`、`refreshGeometry(force)`，用 `g` 写当前增益 + `P` 绝对定位，再通过 `c` 真实落点闭环（最多 3 次修正，误差 ≤8px 提前结束）；`moveGain` 运行时标定并落盘，`currentGain()` 不再是固定 2.16/325。t4 D0 删 `move_gain` 冷启自标定 3.2465813、首落点 1278,800（err 2px）；D-PS0/3/7 各 3 次 9/9 ≤5px；D5 L3 后 A=mouse_click=1/key_enter=0。**不是加长等待/放宽容差**（但有 740ms 固定等待，见 R7）。
2. **边界卡死修复成立**：每帧夹取用运行时 `currentGain()`，估算 `ptrX/ptrY` 由 `c` 回包同步；撞夹取边界立即发一次 `c`（`allowGain=false`）。t4 E1–E4 真实 0/2559/0/1599，估算-真实 0–1px；E5 贴边 5×200ms 零位移、反向到对边；E6 d-pad 后 x=0；E7 空闲隐藏后 x=2559。
3. **空闲隐藏“原地隐形恢复、无修正移动”未被破坏**：`hidePointer()` 只发 `h`，`showPointer()` 只发 `j`，不移动；`handlePassiveCursor`/`finishCenter` 只读 `c` 不改位置。t4 I5 P1=P2=2559,803（0px）+`pointer shown at last position (no correction move)`。
4. **摇杆唤醒逻辑成立**：`checkWake()` 幅度阈值 `wake_stick=800`（0.80）、保持 `wake_hold_ms=200`、上升 `wake_rise_ms=120`；小幅/中幅/慢爬负例不触发。t4 F1/F2/F4 保持 Dozing 且无 WAKE；F3 0.92→Awake。**但日志 `rise=206ms` 是“首次 >0.30 到发送”的耗时，不是上升时间**，文档把它当作 ≤120ms 的证据（R6）。
5. **Y+上/下 映射成立**：`Prefs.defaultMixKeys(10/11)=y+up/y+down`、`defaultMixAction=OPEN_APP`、`defaultMixValue=PKG_PILIPLUS/PKG_DOUYIN`；`mixKeys/mixAction/mixValue` 用 `getString(key, default)`，用户已有自定义优先，不覆盖。t4 G1/G2 真机前台正确 + helper `via` 组件解析；G3 预置 `mix_10=x+rb/wheel_left` 后 `OPEN_APP=0`、前台回桌面（t4 console 的 prefs 行确认 `mix_10_keys=x+rb`）。
6. **8ms 循环无阻塞/无重复 prefs 读取**：`step()` 只在 `prefsGen` 变化时刷新 `lastSeenPrefsGen`，参数由 `prefsListener` 一次性刷新 `refreshCachedPrefs()`；`prefs_per_tick=0`。`refreshGeometry()` 每 2s 读 `DisplayState` 缓存（非 dumpsys）；`queryTop()` 每 1s 发非阻塞 helper 命令。t4 H1 事件→动作中位 7/6ms、最大 13ms（基線 8/20）；帧耗时 128–155µs。
7. **回归保持**：t4 I1 DPAD_CENTER（mouse_click=0/key_enter=1）、I1B 摇杆后鼠标、I2 X 双击→Recents、I3 X+LB dx=+359、I4 X+RB dx=-1536、I5 空闲恢复 0px、I6 SELECT→NotificationShade（NOTIF rc=0 + 截图 4,124,291B）。
8. **证据链问题（阻塞）**：t4 B5/C4 是**无条件 `ck … PASS`**（不是实测）；B1 满推从贴左边缘起手、300ms 后撞右边缘，2524px 是夹取后的位移，无法证明“未夹取 ≤1.2 屏宽”；C1/C2 只统计注入手势几何（`SWIPE` 线），未测实际屏幕滚动，且“同一手势横:竖”按单条是 1152/560=2.06（不在 0.8–1.25），报告用的是 1.5s 总行程 1.029；H3 的 3.53% 是存活线程快照、进程级 6.03% 超 4%。**「不接受弱证据」→ needs_revision。**

## 2. t3 的 9 条 acceptance 逐条核对

| # | acceptance | 判定 | 证据 | 备注 |
|---|---|---|---|---|
| 1 | 居中增益运行时闭环；pointer_speed 0/3/7 各 3 次 ≤80px；禁止固定 325 | **PASS** | t4 `auto_suite.result.txt` D-PS0/3/7：3/3 全过，err max 5px；D0 删 `move_gain` 冷启自标定 3.2465813、click 1278,800；源码 `currentGain/updateMoveGain/handleCenterCursor`（EngineService 618-783） | 阈值写 80px（DIAG 建议 ≤8px），实测 5px 满足；R9 |
| 2 | L3 主动退出 nativeNav；随后 A 恢复鼠标点击 | **PASS** | 源码 `requestCenter` 824-827 `nativeNav=false`；t4 D5 `mouse_click=1 key_enter=0`；I1B 同 | — |
| 3 | 边界：四方向真实边缘、估算-真实 ≤40px、不锁死 | **PASS** | t4 E1–E4 real 0/2559/0/1599，est-real 0–1px；E5/E6/E7；源码 clamp 2142-2171 | 阈值 40px（DIAG ≤8px），实测 0–1；R9 |
| 4 | dpi：满推 300ms 0.9–1.2 屏宽；0–30% 有响应；半推 >0 | **FAIL（证据）** | B2 498px、B3 39px（旧 0）、B4 center 612 vs edge 498；**B1 满推从贴左边缘起手到 2559，2524/2485px 被右边缘夹取**；B5 硬编码 PASS | 源码参数正确（speed_phone=48、γ=1.6、0.2px、edge 0.6），但“满推 300ms”只在夹取后测得，**上限 1.2 屏宽未被证明**；R1/R2 |
| 5 | 滑动速度：横/竖一致性 0.8–1.25；APP 文档给调整前后数值 | **FAIL（口径/证据）** | C1 n=6/3360px、C2 n=3/3456px、C3 总比 1.029；但 C1/C2 只读 helper `SWIPE` 几何，不测实际滚动；单条横向 1152 / 竖向 560 = **2.06**；C4 硬编码 PASS | 若按“1.5s 总行程”则 1.029 成立；若按“同一手势”则 2.06 超范围。需明确口径并补实际滚动/或改验收文字；R1/R3 |
| 6 | 摇杆唤醒：灭屏大幅快推→Awake；小幅慢推不唤醒 | **PASS（附 R6）** | t4 F1 0.37、F2 0.73、F4 慢爬 2.1s 保持 Dozing、无 WAKE；F3 0.92→Awake + `WAKE … done=1`；源码 `checkWake`（EngineService 866-907），阈值 0.80/200ms/120ms | F3 日志 `rise=206ms` 是发送耗时，不是上升时间；文档表述错误（R6） |
| 7 | Y+上 PiliPlus / Y+下 抖音，走 open_app，不覆盖自定义 | **PASS** | t4 G1/G2 top 正确 + `OPEN_APP … via …`、fallback=0/monkey=0；G3 `mix_10=x+rb/wheel_left` prefs + `OPEN_APP=0`、前台 launcher；源码 `Prefs.defaultMix*` 132-169、`mixKeys` 522-537 | t3 自己的 G3 日志 custom prefs 为空，但 t4 覆盖；R8 |
| 8 | 响应提速：事件→动作或帧耗时前后对比；8ms 循环无阻塞/重复 prefs | **PASS（附 R4）** | t4 H1 中位 7/6ms、最大 13ms（基线 8/20）；`perf tick avg 128–155µs`、`prefs_per_tick=0`；源码 `step` 1947-2015 只比较 `prefsGen`；`refreshGeometry` 缓存 | CPU 3.53% 线程级 vs 进程级 6.03%，debug JIT 偏差，release 复测前不能宣称资源不回退（R4） |
| 9 | 回归全部保持 | **PASS** | t4 I1/I1B/I2/I3/I4/I5/I6 全 PASS；源码未改 d-pad/双击/X+LB/RB/隐藏恢复/SELECT 路径 | — |

## 3. 源码审查要点（t3 的 Kotlin 改动）

### 3.1 dpi / 曲线 / 夹取

- `cSpeedPhoneInt` 默认 48（EngineService 193），`curve(v, dead)` γ=1.6（2380-2385），亚像素 0.2px（2137），`cEdgeSlow=40`→scale 0.6（2124-2130）；`ConfigActivity` “手机指针速度”滑杆范围 5–100（ConfigActivity:228），默认 48 在范围内，UI 滑杆未失效。
- 指针位移 `mx = dx * speed * dtScale * physScale`（2134），夹取用 `currentGain()`（2142-2144），撞边发 `c`（2167-2168），`ptrX/ptrY` 按 `rx*gNow` 更新（2170-2171）。`refreshGeometry` 把 `physScale=1/offset=0`（540-544），与 t2 `c` 的 logical 坐标一致。
- **B1 证据问题**：满推从贴左边缘起手（t3 `probe_v166_app_fixes.sh:75-81`；t4 suite 360-383），到右边 2559 被夹；`from=35/42/74 -> to=2559`，dx=2524/2517/2485。`2524` 是“屏幕宽 - 起手余量”，不是未夹取的 300ms 位移；若真实速度 >1.2 屏宽，测试仍会 PASS。t3 脚本注释“L3 后先推到左边缘，避免右边缘夹取”与实际行为相反。

### 3.2 L3 居中闭环

- `requestCenter()`（819-864）：`showPointer()`（j）→清 nativeNav→`refreshGeometry(force)`→目标=app 物理中心→`centerGainUsed=currentGain()`→`g 0 <gain>`→220ms 后再 `g`+`P`→520ms 后 `c`；`handleCenterCursor`（738-783）用 `c` 落点反推 G、误差>8px 补一条 REL、最多 3 次修正；`finishCenter` 记录 CENTER_OK。
- 增益标定：`updateMoveGain`（621-640）对 l3-initial/passive/l3-correct 设不同比例上限；`robustGain` 过滤夹边/取整；`moveGain` 持久化。t4 D0 删 `move_gain` 冷启实测 3.2465813，证明不依赖单机遗留值。
- **R7**：总固定等待 220+520=740ms，加上 P 的 40 步（~280ms）；注释和 t3 输出称“不靠加长等待”，但实际是固定等待 P 完成。helper `P` 完成时打印 `POSPTR`，应用未用该完成信号；L3 延迟可优化。

### 3.3 边界 / 估算 / 空闲隐藏

- `ptrX/ptrY` 由 `c` 回包同步（handlePassiveCursor 718-721），夹取用 `currentGain()`；撞边立即 `c`（2167-2168）；`at app edge` 日志。t4 E1-E4 0-1px。
- `hidePointer`（600-605）只 `h`；`showPointer`（609-614）只 `j`；不移动。t4 I5 0px + `no correction move`。`refreshGeometry` 变化时只置 `ptrX=NaN` 并异步 `c`，不发修正移动（551-556）。
- 无回退：`nativeNav` 只在 d-pad/箭头标记，摇杆移动/ L3 清除（1924-1935、824-827、2029-2033）。

### 3.4 摇杆唤醒

- `checkWake`（870-907）：`m=hypot(axes[0],axes[1])`；`m<0.30` 重置；首次 >0.30 设 `wakeStartAt`，若 `m>=0.80` 设 `wakeFast`；`m>=thr` 时若 `now-wakeStartAt<=120ms` 置 `wakeFast`；`hold>=200ms` 且 `wakeArmed` 且距上次≥2500ms → 若 `!isInteractive` 调 `root.wakeScreen()`。
- 负例：0.37/0.73 不达 0.80；慢爬首样本 <0.80、到 0.80 时已 >120ms → wakeFast=false。t4 F1/F2/F4 通过。
- **R6**：日志 901 行 `rise=${now - wakeStartAt}` 在发送时刻打印（已含 hold），不是上升时间；t3 APP-v166.md:46-50 / VERIFY:136 把 `rise=206ms` 当“上升 ≤120ms”的证据，逻辑上矛盾。实际 `wakeFast` 是布尔；F4 慢爬才是 rise 规则的正证。建议单独记录首次 ≥thr 的 `riseCrossMs`，或把字段改名 `sinceStartMs`。

### 3.5 Y+上/下 / open_app

- Prefs 默认：slot10 `y+up`→OPEN_APP→`com.example.piliplus`；slot11 `y+down`→OPEN_APP→`com.ss.android.ugc.aweme`（Prefs 132-169）。`mixKeys/mixAction/mixValue` 用 `getString(key, default)`（522-537），用户自定义优先。
- `ActionRouter` OPEN_APP（192）→`launchTargetApp(pkg)`（EngineService 1903-1918）→`root.openApp(pkg)`（helper `w`）；t4 G1/G2 真机前台 + `via` 组件解析；G3 自定义 prefs + `OPEN_APP=0`。
- t3 自己的 `v166_app_openapp.log` G3 `custom prefs=` 为空（探针读取/广播失败），但 t4 G3 console 的 `mix_10_value/keys/action` 齐全；以 t4 为准（R8）。

### 3.6 提速 / 循环

- `step()`（1947-2015）：`prefsGen` 比较；`prefsListener`（364-368）→`refreshCachedPrefs()` 一次性刷新 cSpeed/cScroll/cHswipe/cEdge/cWake 等；`prefs_per_tick=0` 日志。
- `refreshGeometry` 用 `DisplayState` 缓存（521-557），每 2s；`queryTop` 每 125 ticks（~1s）发 helper 命令；无 `Thread.sleep`/dumpsys/文件 I/O 在 8ms 循环。
- t4 H1 7/13ms；t3 latency-before-after：中位 8→7、最大 20→13；帧 128–155µs。**CPU**：t3 自报 2.93%→5.6%（engine 4.37%），t8 后 3.70–3.80% 线程级；t4 H3 3.53% 线程级但 `/proc/<pid>/stat` 6.03%，见 R4。

## 4. t4 证据审计（重点找假通过/弱阈值）

- **A 组**：A0 判别力自检（绕 App 直接注入竖+横，两区都动），A1/A2 单轴，A3 双轴超阈，A4 串行计数，A5 drops=0；A2 另有 PC 像素 diff 99.4% 横带。**证据链强**；A3 的 sendevent 等价性见 t5 REVIEW（状态等价，可接受）。
- **B 组**：B1 真实但**夹取**（from 74→2559）；B2 498px（阈值 >0，弱但方向对）；B3 39px（>0，弱）；B4 center 612 > edge 498（仅方向）；**B5 无条件 PASS**（suite:425，硬编码字符串 `prefs speed_phone 未覆盖(默认48)`，不读源码/prefs）——**假通过**。
- **C 组**：C1/C2 用 helper `SWIPE` 几何（`picked`，`grep '^SWIPE '` 正确排除 DONE），n=6/3、总行程 3360/3456；C3 总比 1.029 真实；**C4 无条件 PASS**（suite:462，硬编码“竖 560px/250ms、横 1152px/500ms”）。**实际滚动未测**；按单条手势横/竖=1152/560=2.06，不在 0.8–1.25。t3 自己的 `probe_v166_app_scroll.sh:26` 用 `grep -a '^SWIPE'`（无尾空格）把 `SWIPE_DONE` 当 V，导致 C1 `V=11`、斜推 `V=10` 的**假串扰**；t4 的 `picked` 正确，V=0。
- **D 组**：D0/D0B/D-PS0/3/7/D4/D5 真实（D0 删 move_gain 冷启自标定、9/9 ≤5px）。阈值 80px 比 DIAG ≤8px 松（R9）。
- **E 组**：E1-E4 real 0/2559/0/1599、est-real 0–1；E5/E6/E7 真实。阈值 40px 比 DIAG ≤8px 松（R9）。
- **F 组**：F1/F2/F4 真实负例；F3 真实正例；日志 rise 字段问题见 R6。
- **G 组**：G1/G2/G3 真实；G3 console prefs 显示 `mix_10_keys=x+rb` 等，`OPEN_APP=0`；t3 自己的 G3 日志为空（R8）。
- **H 组**：H1 7/13ms 真实；H2 108/226µs 真实（只判中位，未判 max<5000）；H3 线程级 3.53/3.47 vs 进程 6.03/5.97（R4）；H4 CURSORQ=0 真实。
- **I 组**：I1/I1B/I2/I3/I4/I5/I6 真实（I3 dx=+359 仅方向、无最小位移；I6 截图+焦点+rc 三重）。
- **J/K**：J 属 t8（t9 审查）；K 属 helper（t2/t5）。

## 5. Findings

| id | severity | problem | requiredFix | file:line |
|---|---|---|---|---|
| R1-B5C4-FAKE | **high** | t4 B5 与 C4 是**无条件 `ck … PASS`**：B5 打印 `prefs speed_phone 未覆盖(默认48)` 但不读源码/prefs/日志；C4 打印“竖 560px/250ms、横 1152px/500ms”但不校验源码/实测。t4 的 PASS=64 里至少 2 条是描述性行，报告把它们当作“源码默认值/调整后数值生效”的证据，属假通过。实际源码值确实正确（EngineService:193/2384/2137/2128；Prefs:208/235-241），但验证链是假的。 | 把 B5/C4 改为条件检查：从 `EngineService.kt`/`Prefs.kt` 读取常量，或从引擎启动日志/`perf`/`vswipe` 日志取实际值；不满足则 FAIL；或从 PASS 计数中移除并标为“源码审查项”。 | `work/scripts/v166_auto_suite.sh:425,462`；`work/docs/VERIFY-v166.md:85,94` |
| R2-B1-EDGE | **medium** | B1 满推 300ms 从贴左边缘起手（t3 probe:75-81；t4 suite:360-383），到 2559 被右边缘夹取：t3 `from=35/42 -> 2559 dx=2524/2517`、t4 `from=74 -> 2559 dx=2485`。2524 是“屏宽-起手余量”，不是未夹取的 300ms 位移；若真实速度 >1.2 屏宽，测试仍 PASS。t3 脚本注释“避免右边缘夹取”与实际相反。 | 用不撞边的方法重测：屏幕中心起手、150ms 满推（≤~1300px，不撞边）再按时间线性折算 300ms；或从引擎未夹取的 `mx`/`ptr move` 日志/`M` REL 总量求和（在 clamp 前）；重判 0.9–1.2。 | `work/scripts/v166_auto_suite.sh:360-383`；`work/scripts/probe_v166_app_fixes.sh:75-83`；`work/docs/VERIFY-v166.md:81` |
| R3-C-SPEED-METRIC | **medium** | C1/C2 只统计 helper `SWIPE` 手势几何（注入长度），不测实际屏幕滚动；t3 acceptance #5 写“同一手势横向位移 : 竖向位移 0.8–1.25”，按单条是 **1152/560=2.06**（不在范围），t4 C3 用的是 1.5s 总行程 1.029（在范围）；C4 是硬编码 PASS。口径未定义，两个答案相反。 | 明确验收口径：若按“1.5s 总速度”则把 acceptance 文字改为“同一时间总位移”，并保留 C1/C2/C3；若按“同一手势”则当前 2.06 不达标，需要调整横向单次距离或改文字。另补一次实际滚动测量（uiautomator PY/HS 前后差）作为独立证据，C4 改条件检查。 | `work/docs/VERIFY-v166.md:87-94`；`work/docs/APP-v166.md:38-43`；`work/scripts/v166_auto_suite.sh:429-462` |
| R4-H3-CPU | **medium** | H3 的 3.53/3.47% 是 t0/t1 **仍存活线程**快照求和（suite:899-917），短命 JIT 编译线程被漏掉；`/proc/<pid>/stat` 6.03/5.97% 才是进程 CPU，超过 4% 阈值。debug 构建下「CPU 3.5% / 资源不回退」不可比；t3 自己也曾报 2.93→5.6%。 | 在 **release 构建**上做 60s 进程级（utime+stime，说明 cutime/cstime）复测，与 v1.65 同方法比较；未复测前发布说明只引用 H1/H2（7ms/13ms、prep 108/226µs），不写 CPU/资源不回退；H3 线程级标为辅助指标。 | `work/docs/VERIFY-v166.md:155,158`；`work/scripts/v166_auto_suite.sh:899-917` |
| R5-T3-SCROLL-PARSER | **low/medium** | t3 自己的 `probe_v166_app_scroll.sh:26` 用 `grep -a '^SWIPE'`（无尾空格），把 `SWIPE_DONE`/`SWIPE_DROP` 也计入；`trav V` 对这些行算 `$1 != $3` → 统计成横向手势。结果 C1 竖向测试出现 `V=11`、斜推 `V=10`（总行程 0px），看起来像串扰复现；t4 的 `picked` 用 `grep '^SWIPE '` 正确，V=0。t3 的 APP 文档写 V=0，与自家 log 矛盾。 | 把 t3 探针改成 `grep -a '^SWIPE '`（尾空格）并排除 `SWIPE_DONE/SWIPE_DROP/SWIPE_QUEUED`；重跑 C1/C2/斜推；t3 日志/APP 文档统一用 t4 的干净计数。 | `work/scripts/probe_v166_app_scroll.sh:26`；`work/docs/evidence-v166-app/v166_app_scroll.log` |
| R6-WAKE-RISE-LOG | **low/medium** | 唤醒日志 `EngineService.kt:901` 的 `rise=${now - wakeStartAt}` 在发送时打印，已包含 hold；t3 APP-v166.md:46-50 / VERIFY:136 把它当“上升时间 ≤120ms”的证据，F3 显示 `rise=206ms` 与阈值矛盾。逻辑用 `wakeFast` 布尔（885 行），不是这个字段；F4 慢爬才是 rise 规则的正证。 | 单独记录首次 `m>=thr` 的 `riseCrossMs`（≤120 判据）并在日志/文档中使用；把现有字段改名 `sinceStartMs`；F3 证据改引 `riseCrossMs`。 | `project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt:901`；`work/docs/APP-v166.md:46-50`；`work/docs/VERIFY-v166.md:136` |
| R7-L3-FIXED-WAIT | **low** | L3 用 220ms + 520ms 固定等待（`requestCenter` 850-857）等 helper `P` 的 40 步完成；t3 输出称“不靠加长等待”，但实际固定等待 740ms；helper `P` 完成会打印 `POSPTR`，应用未用该完成信号。 | 用 `POSPTR`/事件驱动触发 `c`（或在 helper `P` 完成后回包），把固定 520ms 缩短到实测 P 完成时间；测一次 L3 端到端延迟并记录；若保留固定等待，在文档明确“740ms 是为异步 P 完成，不是掩盖误差”。 | `project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt:850-857`；`work/docs/APP-v166.md:11-22` |
| R8-T3-EVIDENCE-STALE | **low** | t3 自身证据多处与 t4 不一致：`v166_app_wake2.log` 负例 A/B 的 `wake_log` 是初始亮屏时 `wake skip … m=0.9155` 的旧行（不是负例自己的日志）；`v166_app_openapp.log` G3 `custom prefs=` 为空；t3 输出 APK hash `1F8A…` 与装机 `e8a91185…`（t8 后）不一致（APP-v166.md 已改）。t4 的 F1/F2/F3、G3、BASE-APK 覆盖了这些点。 | 修 t3 探针：负例前清 logcat 或取本次时间窗；G3 用与 t4 相同的 debug 广播并读回 prefs；t3 报告统一写实际装机 hash；或明确“t3 自身证据仅供定位，验收以 t4 为准”。 | `work/docs/evidence-v166-app/v166_app_wake2.log`；`work/docs/evidence-v166-app/v166_app_openapp.log`；`work/docs/APP-v166.md:3` |
| R9-DE-THRESHOLD | **low** | D 组阈值 80px、E 组 40px，比 DIAG 建议的 ≤8px 宽 5–10 倍；实测 D max 5px、E 0–1px 已满足更严值，但松阈值会让未来 9–79px 的回归漏检。 | 在 VERIFY/集成文档按 DIAG ≤8px 重新判定（数据已满足）；若保留 80/40，写明理由（例如“保守验收”）并同时记录 ≤8px 结果。 | `work/docs/VERIFY-v166.md:100-107,118-124`；`work/docs/DIAG-v166.md:349,353` |

> R1–R4 是 **t4 证据/报告** 的阻塞项（不是 t3 Kotlin 代码缺陷）：t3 的核心实现（L3 闭环、边界、隐藏恢复、唤醒、Y 映射、8ms 循环、回归）经源码审查成立。修复验证链后可重新 review；R5–R9 是低风险质量项，可与 t4/t7 的最终文档一起修。

## 6. 交付/发布前必须满足的条件（给 t7）

1. 修 R1（B5/C4 条件化）与 R2（B1 不夹取测量）并重跑 B 组；R3 明确 C 组口径并补实际滚动；否则 t3 acceptance #4/#5 不成立。
2. 修 R4：release 构建、进程级 60s CPU 同口径复测；未复测前不写 CPU/资源不回退。
3. 修 R5/R6/R7/R8 的证据/文档（t3 自家 log 解析、wake rise 字段、L3 等待说明、t3 hash）。
4. 用最终 helper（t10/t13 后）与应用 `e8a91185…` 重跑 `v166_auto_suite.sh`；BASE-APK/BASE-HELPER 必须等于发布产物。
5. 发布说明的「提速」只引用 H1/H2/帧耗时（有实测），CPU 引用 release 复测。

## 7. 复现命令

```sh
# t3 应用侧探针（会重启 padtest/引擎；单设备串行）
adb -s 192.168.10.36:6666 push work/scripts/probe_v166_app_fixes.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell su -c 'sh /data/local/tmp/probe_v166_app_fixes.sh'
adb -s 192.168.10.36:6666 push work/scripts/probe_v166_app_scroll.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell su -c 'sh /data/local/tmp/probe_v166_app_scroll.sh'
adb -s 192.168.10.36:6666 push work/scripts/probe_v166_app_wake2.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell su -c 'sh /data/local/tmp/probe_v166_app_wake2.sh'

# t4 全量（当前设备 helper 已被 t10/t13 重建，t7 用最终 hash 重跑）
adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/v166_auto_suite.sh"

# 只读复核（本审查实际执行）
adb -s 192.168.10.36:6666 shell "dumpsys package com.dennis.dexpad | grep -m1 versionName"
adb -s 192.168.10.36:6666 shell 'p=$(pm path com.dennis.dexpad | head -1 | sed s/package://); sha256sum "$p"'
#   e8a91185…（= 本机 app-debug.apk）
```

## 8. 限制与未覆盖

- 审查期间 t10 正在改 helper，t13 已因 t5 的 R5 创建；本报告只审 t3 的 Kotlin 源码与 t4 证据，不覆盖 helper 的 t10/t13 改动。
- 未在设备上重放 UI/注入实验（设备被 helper 测试占用）；t3/t4 已有原始证据；本次只做只读版本/哈希/显示检查。
- t3 自家 `v166_app_scroll.log`、`v166_app_wake2.log`、`v166_app_openapp.log` 与 t4 证据存在不一致（R8）；本报告以 t4 的干净计数/证据为准，t3 自家 log 仅作定位。
- B1 的真实 300ms 满推速度仍未被直接测量；R2 的修法（150ms 中心起手×2）需要 t4 重跑后重判。
