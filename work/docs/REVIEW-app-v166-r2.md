# REVIEW-app-v166-r2 · t16 修复复审（round 2）

> 任务：t17（review-round-2）· 审查对象：t16（L3 事件驱动、riseCrossMs、dpi 不撞边、滑动双口径）· attempt 1
> 审查人：reviewer · 时间：2026-11-24 03:15 CST · 设备：SM-F9360（adb 192.168.10.36:6666，横屏 2560×1600）
> 结论：**NEEDS_REVISION**。t16 的 L3 事件驱动（POSPTR）/riseCrossMs 拆分/自家 scroll 探针修复成立；但 **t16 的“独立 uiautomator 滚动证据”在竖向实际 dPY=0（页面没动）**，与 t4 A1（同一 ScrollTestActivity，旧 APK `e8a91185`，PY 1415→78，d=1337）矛盾，t16 新 APK `b7fa2662` 的竖向滑动**未被证明/可能回退**；dpi 仍是无夹取的**代理测量**（法 A 89.1–89.9% 低于 0.9，法 B 是 speed_phone 16→48 的线性外推），t3 #4 未闭环；滑动速度按“同一手势”仍是 2.057（>1.25），按“同一时间总位移”1.029，口径未在任务书 amend；t4 的 64 PASS 仍是旧 APK `e8a91185`，新 APK `b7fa2662` 没有全量回归。
> Blocking findings：**R1 竖向滚动 dPY=0**（high）、**R2 dpi 代理**（medium）、**R3 速度口径**（medium）、**R4 新 APK 未跑 t4**（medium）；R5–R7 为 t7/t15 条件。

## 0. 被审修订与产物

| 项 | 值 |
|---|---|
| t16 APK | `b7fa26623ba87f3801794cd74a42ac8770b4c0f74c2b99b9fd68626c0e0c984d`（3131895 B；设备 base.apk = 本机 app-debug.apk） |
| t16 源码 | `EngineService.kt` sha256 `3e3fb65b…`（107880 B）、`RootInput.kt` `6c054476…`（15487 B）；t16 只改这两个应用文件 |
| helper | `1bf7306f…`（t13 最终，未变） |
| 文档 | `APP-v166.md` sha256 `d9dd1158…`（t16 §1/§5/§8/§9 更新） |
| t16 证据 | `v166_t16_data.log`（L3/dpi/滚动/唤醒）、`v166_t16_dpi.log`、`v166_t16_scroll.log`；`probe_v166_app_t16_*.sh` |
| t4 基线 | t4 的 64 PASS 是 **旧 APK `e8a91185…`**、helper `4f261754…`；t16 改 APK 后没有重跑 t4 |

## 1. t16 的 4 组实测核验

| 组 | t16 声称 | 原始证据 | 判定 |
|---|---|---|---|
| L3 端到端 | 498/355/365ms；POSPTR 311ms 触发 c；700ms 兜底未触发；旧 220+520 已删 | `v166_t16_data.log:7-13`：`run1/2/3 pressToCENTER_OK=498/355/365`、`POSPTR=L3 POSPTR x=1280 y=800 after=311ms -> query cursor`、`fallback=` 空、`CENTER_OK ... err=2,3 l3TookMs=363`；源码 `EngineService.kt:854-878` POSPTR 事件、`:850-860` fallback；`RootInput.kt:213-220` POSPTR 解析 | **PASS**（L3 延迟/落点；t3 #1/#2 的代码路径仍清 nativeNav；D5 需在新 APK 复跑，见 R4） |
| riseCrossMs | 快推 0.92 `riseCrossMs=0 / sinceStart=208` → Awake；慢爬 0.24→0.91/2.1s `riseCrossMs=1159 / fast=false` → Dozing | `v166_t16_data.log:26-30`；源码 `EngineService.kt:905-937`（`riseCrossMs=now-wakeStartAt` 在首次 ≥thr 记录，`sinceStartMs` 含 hold；`wake sent ... riseCrossMs=... sinceStartMs=...`）；APP §5:49-51 | **PASS**（t3 #6；旧日志误用 rise 已修） |
| dpi 不撞边 | 中心 150ms 1141–1150×2=2282–2302=89.1–89.9%；speed_phone=16×300ms 777/794/779×3=2331/2382/2337=91.1/93.0/91.3% | `v166_t16_dpi.log`：16 下三样本 794/777/779、edge_logs=0、×3=2382/2331/2337；恢复 48 后 48 下 300ms 左推 1141px 到 0（撞边）。**法 A 89.1–89.9% 低于 0.9；法 B 是 speed_phone 16→48 的线性外推**；direct 48 300ms 未测 | **PARTIAL**（R2；t3 #4 未闭环） |
| 滑动双口径 | 同一时间 3456/3360=1.029；同一手势 1152/560=2.057（设计） | APP §9.2:79-83；t3 #5 任务书写“同一手势横向位移 : 竖向位移 0.8–1.25”，按单手势 2.057 **>1.25**；t16 自行改按“同一时间总位移”口径 | **PARTIAL**（R3；需 captain/t7 amend 或改横向距离；同时见 R1 实际竖向 d=0） |
| 独立滚动 | 横向 HS=512；竖向“状态行滚出视口，实际发生纵向滚动” | **`v166_t16_data.log:21-24`：`vertical 1.5s: PY 1415->1415 (d=0) HS 0->0 | Z=6 total=3360px`；`horizontal ... HS 0->512`；`v166_t16_scroll.log:3` 竖向 dPY=0**；APP §9.3:85-88 的“实际发生纵向滚动”**没有被该数据支持**；t4 A1 在同一 ScrollTestActivity（旧 APK）是 PY 1415→78（d=1337） | **FAIL**（R1，high：新 APK 竖向滚动 d=0，可能回退；至少未被证明） |

## 2. t3 的 9 条 acceptance 复核（t16 后）

| # | acceptance | 判定 | 说明 |
|---|---|---|---|
| 1 | 居中运行时闭环；pointer_speed 0/3/7 各 3 次 ≤80px；不靠固定 325 | PASS | t4 D-PS 9/9 ≤5px（旧 APK `e8a91185`）+ t16 L3 1282,803 err=2,3、POSPTR 事件驱动；t4 D0 删 move_gain 冷启自标定 3.2465813；t16 未改标定路径 |
| 2 | L3 主动退出 nativeNav；A 恢复鼠标点击 | PASS（D5 需新 APK 复跑） | t16 的 L3 仍清 nativeNav（EngineService requestCenter）；t16 L3 1282,803；t4 D5 mouse_click=1/key_enter=0 是旧 APK；t16 的 POSPTR 改 L3 异步，D5 未在新 APK 复跑（R4） |
| 3 | 边界四方向真实边缘、est-real ≤40px、d-pad/隐藏后可达 | PASS（旧 APK 代码未改） | t4 E1-E4 0/2559/0/1599、est-real 0–1px、E5/E6/E7；t16 未改 clamp/边界代码；需新 APK 复跑（R4） |
| 4 | dpi：满推 300ms 0.9–1.2 屏宽；0–30% 有响应；半推 >0 | **FAIL（证据）** | 法 A 89.1–89.9%（<0.9）；法 B 16×3 91.1–93.0% 是 speed_phone 线性外推，未测 direct 48 300ms（会撞边）；t4 B1 0.97 是贴左边夹取；上限 1.2 仍未证明（R2） |
| 5 | 滑动速度：同一手势横/竖 0.8–1.25；APP 文档给数值 | **FAIL（按任务书口径）** | 同一手势 1152/560=**2.057** >1.25；t16 按“同一时间总位移”1.029 口径；任务书未 amend；且实际竖向 uiautomator dPY=0（R1/R3） |
| 6 | 唤醒：0.92→Awake；0.37/0.73/慢爬→Dozing | PASS | t16 riseCrossMs 快推 0/208→Awake、慢爬 1159/fast=false→Dozing；t4 F1/F2/F3/F4；APP §5 |
| 7 | Y+上/下 打开正确应用，不覆盖自定义 | PASS（旧 APK 代码未改） | t4 G1/G2/G3；t16 未改 Prefs/ActionRouter/Y 路径；需新 APK 复跑（R4） |
| 8 | 响应提速：事件→动作/帧耗时；8ms 循环无阻塞/prefs | PASS（CPU 条件） | t4 H1 7/13ms、APP §8 帧 128–176µs、prefs_per_tick=0；t16 L3 498/355/365；CPU 见 R5（release 复测） |
| 9 | 回归全部保持 | **PARTIAL/需新 APK** | t4 I/I1–I6、J 是旧 APK `e8a91185`；t16 新 APK `b7fa2662` 只跑了 L3/唤醒/dpi/C 四组；竖向滚动 dPY=0（R1）；DPAD/X/LB/RB/SELECT/空闲隐藏代码路径未改，但 D5/A 后 L3、竖向滚动需在新 APK 复跑（R4） |

## 3. 源码核验（t16 只改两文件）

- `EngineService.kt`：`riseCrossMs`（905-914）与 `sinceStartMs`（936-937）拆分，`wake sent` 日志用 `riseCrossMs=${wakeCrossAt-wakeStartAt}`、`sinceStartMs` 含 hold；`L3` 的 `root.positionPointer`（857）+ `POSPTR` 回调（878）+ 700ms fallback（860）；`l3TookMs`（807/820）。`RootInput.kt:213-220` 解析 `POSPTR x,y` → `onPositioned`。
- **L3 延迟**：旧的 220+520ms 固定等待已删，POSPTR after=311ms 触发 c；`fallback=` 空；CENTER_OK err=2,3 l3TookMs=363。**成立**。
- **riseCrossMs**：快推 0/sinceStart=208、慢爬 1159/fast=false；**成立**；t6 R6 的日志误用已修。
- **dpi**：应用侧 dpi 代码未改（speed_phone/γ/0.2px/edge 0.6）；t16 只是用 speed_phone=16 降低速度避免撞边，再 ×3 折算；**这是测量方法，不是代码修复**。
- **C 速度**：应用侧横向 1152/竖向 560 未改；t16 把口径改为“同一时间总位移”；**任务书 acceptance #5 仍写“同一手势”**。
- **自家 scroll 探针**：`probe_v166_app_scroll.sh:23,27` 已改成 `grep -a '^SWIPE '`（尾空格），t6 R5 的 DONE 误计已修；**成立**。

## 4. 关键矛盾：竖向实际滚动 dPY=0（R1，high）

`v166_t16_data.log:21-24`（t16 自己的探针）：
```
vertical 1.5s: PY 1415->1415 (d=0) HS 0->0 | Z=6 total=3360px
horizontal 1.5s: PY 1415->1415 (d=0) HS 0->512 (d=512) | V=3 total=3456px
```
`v166_t16_scroll.log:3` 同样 `after V: PY=1415 HS=0 dPY=0`。而 t4 A1（**同一 `ScrollTestActivity`，旧 APK `e8a91185`**）是 `PY 1415->78 (d=1337)`。t16 的 APP §9.3 却说“竖向 ... 状态行滚出视口，实际发生了纵向滚动”，这与它自己的数据日志矛盾（数据日志只有 PY/HS d=0，没有“状态行滚出”的取样）。

可能原因：
1. t16 的竖向探针方向/起手/页面复位与 t4 A1 不同（t4 A1 是 `stick 4 24000 450`；t16 是 1.5s，方向/起手需核对）；或
2. t16 的 APK `b7fa2662` 的 L3/POSPTR/EngineService 改动影响了 `ptrX/ptrY`/`pointerPos`，导致竖向 swipe 起点/指针状态异常；或
3. t16 的 uiautomator 指标在本次页面状态不适用（但 t4 A1 同 Activity 适用）。

**这不是“证据弱”而已：t16 新 APK 的竖向滚动没有被证明，且与旧 APK 的实际滚动相反；在 t4 A1/A2 在新 APK 复跑之前不能判 t3 #4/#5/#9 通过。**（R1）

## 5. Findings

| id | severity | problem | requiredFix | file:line |
|---|---|---|---|---|
| R1-VERTICAL-SCROLL | **high** | t16 `v166_t16_data.log:21-24` 竖向 1.5s `PY 1415->1415 (d=0) HS 0->0`、`v166_t16_scroll.log:3` dPY=0；t16 APP §9.3:85-88 却称“实际发生了纵向滚动”，与自身数据矛盾；t4 A1 在同一 ScrollTestActivity（旧 APK e8a91185）是 PY 1415→78（d=1337）。t16 新 APK b7fa2662 的竖向滑动未被证明/可能回退。 | 在 b7fa2662 上重跑 t4 A_case A1/A2（同一 ScrollTestActivity、同 stick/方向/起手/复位），对比 PY/HS；若 dPY=0，检查 t16 的 L3/POSPTR/EngineService 改动是否影响 ptrX/ptrY/pointerPos 或竖向 swipe 起手；修 APP §9.3 去掉未支持的“实际纵向滚动”表述；修复后重跑。 | `work/docs/evidence-v166-app/v166_t16_data.log:21-24`；`v166_t16_scroll.log:3`；`work/docs/APP-v166.md:85-88`；t4 `auto_suite.result.txt` A1 |
| R2-DPI-PROXY | **medium** | t16 法 A（中心 150ms×2）=2282–2302px=89.1–89.9%，**低于 0.9**；法 B 是 speed_phone=16 下 300ms 777/794/779×3=2331/2382/2337（91.1/93.0/91.3%），假设 speed_phone 16→48 线性且系统 pointer gain 在 16/48 相同；direct 48 300ms 未测（从中心会撞边）。t4 B1 2485px（0.97）是贴左边起手夹取；上限 1.2 仍未证明。 | 做一次 direct 48 300ms 不夹取测量：从 x=0 起手（48 下 300ms≈2330–2500px，终点<2559；若仍撞边则改 250ms×6/5 折算），要求 `edge_logs=0`；或先验证 speed_phone 16/24/48 三档的 px/300ms 线性（同一 move_gain），再用法 B；用 ≤8px/0.9–1.2 判定；APP §9.1 写清“代理测量”字样。 | `work/docs/APP-v166.md:75-77`；`work/docs/evidence-v166-app/v166_t16_dpi.log`；t4 `auto_suite.result.txt` B1 |
| R3-SPEED-METRIC | **medium** | t3 acceptance #5 写“同一手势横向位移 : 竖向位移 0.8–1.25”；t16 的同一手势 1152/560=**2.057** >1.25；t16 改按“同一时间总位移”3456/3360=1.029，但任务书未 amend；实际竖向滚动 dPY=0（R1）。 | captain/t7 把 t3 #5 明确为“同一时间（1.5s）总位移比 0.8–1.25”（t4 C3 口径），或按“同一手势”把横向单次降到 ~560–700px（会牺牲翻页率）并说明；同时按 R1 重跑实际竖向/横向滚动；VERIFY 的 C 组口径同步。 | `work/docs/APP-v166.md:79-83`；`work/docs/VERIFY-v166.md:91-94`；t3 acceptance #5 |
| R4-FINAL-APK-T4 | **medium** | t4 的 64 PASS 是旧 APK `e8a91185`（+helper 4f261754）；t16 新 APK `b7fa2662`（+helper 1bf7306f）只跑了 L3/唤醒/dpi/C 四组；t16 的 L3 POSPTR 改的是 D5/A 后 L3 路径，竖向 dPY=0 也提示新 APK 可能有回退；Y/boundary/idle/SELECT 代码未改但未在新 APK 复跑。 | t7 用 b7fa2662 + 1bf7306f 重跑完整 t4（至少 A/B/C/D/E/F/G/H/I/J）；D5（L3 后 A=鼠标）、I5（空闲隐藏 0px）必须在新 APK；BASE-APK 改为 b7fa2662、BASE-HELPER 1bf7306f。 | `work/docs/VERIFY-v166.md:15-17`；`work/docs/APP-v166.md:3`；t16 输出 |
| R5-APP-CPU-RELEASE | **medium** | APP §8:71 仍是 debug 线程级 3.70–3.80%；t4 H3 同构建进程级 6.03/5.97% >4%；t16 未做 release CPU。 | t7 release 构建进程级 60s（utime+stime，分离 cutime/cstime）复测；未复测前发布说明只引用 H1 7/13ms 与 H2 prep，不写 CPU/资源不回退。 | `work/docs/APP-v166.md:71`；`work/docs/VERIFY-v166.md:155,158` |
| R6-T4-B5C4-VERIFY | **low** | t4 B5/C4 仍是无条件 `ck…PASS`（suite:425/462）；VERIFY 的 D/E 80/40px、H2 只判中位、B2/B3>0、I3 无最小位移未收紧；t16 按分工留给 t15/t7。 | t15/t7 条件化 B5/C4、按 HELPER §4.1 第 5 条收紧 VERIFY；发布前重跑 t4 时这些行不得再无条件 PASS。 | `work/scripts/v166_auto_suite.sh:425,462`；`work/docs/VERIFY-v166.md:85,94,100-107,118-124` |
| R7-APP-HASH | low | t16 的 APP-v166.md 已改 b7fa2662；t3 输出仍写 1F8A；t4 VERIFY 仍 e8a91185。 | t7 发布文档统一 b7fa2662（APK）+1bf7306f（helper）；不要把 e8a91185/1F8A 当最终产物。 | `work/docs/APP-v166.md:3`；`work/docs/VERIFY-v166.md:15-17` |

## 6. 结论与给 t7 的条件

t16 的 **L3 POSPTR 事件驱动**（498/355/365ms、POSPTR 311ms、旧 220+520 删除）、**riseCrossMs/sinceStartMs**（快推 0/208、慢爬 1159/fast=false）和 **自家 scroll 探针 `grep '^SWIPE '` 修复** 成立；但 **竖向实际滚动 dPY=0** 与 APP §9.3 矛盾（R1），**dpi 仍代理/法 A <0.9**（R2），**速度口径未 amend 且单手势 2.057**（R3），**新 APK 未跑 t4**（R4）——t17 判 **NEEDS_REVISION**，不是 pass。

t7 发布前必须：
1. 在 b7fa2662 上重跑 t4 A1/A2（竖向/横向实际滚动），解释/修复 dPY=0（R1），并同步 APP §9.3。
2. dpi 做 direct 48 300ms 不夹取测量或验证 speed_phone 线性（R2），按 0.9–1.2 重判。
3. 把 t3 #5 口径 amend 为“同一时间总位移”（R3），或改横向单次距离；VERIFY C 组同步。
4. 用 b7fa2662 + 1bf7306f 重跑完整 t4（A/B/C/D/E/F/G/H/I/J），D5/I5 必须在新 APK（R4）；BASE-APK/HELPER 更新。
5. release 进程级 60s CPU（R5）；B5/C4 条件化 + VERIFY 收紧（R6）；统一最终 hash（R7）。

## 7. 复现

```sh
# 只读复核（本审查执行）
adb -s 192.168.10.36:6666 shell 'p=$(pm path com.dennis.dexpad | head -1 | sed s/package://); sha256sum "$p"'
#   b7fa2662…（= 本机 app-debug.apk）
sha256sum project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt  # 3e3fb65b…
sha256sum project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt      # 6c054476…

# t16 数据复跑（单设备串行）
adb -s 192.168.10.36:6666 push work/scripts/probe_v166_app_t16_data.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell su -c 'sh /data/local/tmp/probe_v166_app_t16_data.sh'
adb -s 192.168.10.36:6666 push work/scripts/probe_v166_app_t16_dpi.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell su -c 'sh /data/local/tmp/probe_v166_app_t16_dpi.sh'
```

## 8. 限制

- 未在设备上重放注入/滚动实验（设备在 t16/t7 使用中）；t16 的 data/dpi/scroll 日志、APP-v166.md、t4 结果/证据为原始材料；本次做了只读 APK/源码 hash、日志与 APP 文档逐项核对。
- t16 的竖向 dPY=0 可能是探针方向/页面复位差异，可能与 t4 A1 不等价；需在 t7 用 t4 A_case 同一方法复跑后才能定性为回退或探针错误（R1 的 requiredFix 已写）。
- t4 的 64 PASS 是旧 APK；t16 新 APK 的完整回归尚未跑（R4）。
