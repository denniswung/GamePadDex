# REVIEW-helper-v166-r2 · t13 修复复审（round 2）

> 任务：t14（review-round-2）· 审查对象：t13（R5 投毒阈值 / R2 `C` 异步 / R4 审计重生成）· attempt 1
> 审查人：reviewer · 时间：2026-11-24 03:05 CST · 设备：SM-F9360（adb 192.168.10.36:6666，横屏 2560×1600）
> 结论：**PASS**（t13 的 R5/R2/R4 均已修复，t2 的 9 条 acceptance 仍成立；t13 新增 helper 进程级 CPU 复测，未引入回退）
> 非阻塞 findings：R1/R5TEXT/R3/SMOKE/BINARY（见 §6）。**R1（应用侧 release CPU）与 R3（VERIFY 阈值收紧）仍须 t7/t12 闭合；R5TEXT 是 t2 任务书 acceptance #3 仍写 ≤2s 与 HELPER 已改 ≤2.5s 的文字不一致，需 captain/t7 amend；不影响 t13 修复本身。**

## 0. 被审修订与产物

| 项 | 值 |
|---|---|
| t13 源码 | `project/app/src/main/assets/gpminput.c`，sha256 `9994c286eba29b0b52fcbf3caad465ee5af1f6a821e5fc2896af45e0183c6f5a`，135647 B，3219 行 |
| t13 产物 | `project/app/src/main/assets/gpminput`，sha256 `1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf`，851928 B |
| 设备 | `/data/adb/gpm/gpminput` = `/data/adb/modules/gpm_dex/gpminput` = `1bf7306f…`（审查时只读 sha256sum 复核）；helper pid 存在 |
| t13 证据 | `helper-v166-poison-t13.txt`（2.0/2.3/2.5s 投毒）、`helper-v166-smoke-t13.txt`（OUT=96/ERR=0）、`helper-v166-popen-audit-r2.txt`（source `9994c286…`）、`helper-v166-cpu-60s.txt`（helper 进程级 CPU） |
| 文档 | `work/docs/HELPER-v166.md` sha256 `16ef95c6…`（§2.3/§2.6/§4.1/§4.3/§4.4 已更新） |
| 与 t2 关系 | t13 只改 R5/R2/R4（+ t10 CAP/t11），串扰/唤醒/open_app/回归路径未动；t2 原产物 `4f261754…` 已被 `1bf7306f…` 取代，t7 必须用最终哈希 |

## 1. t13 的三项修复（逐项验收）

| 项 | 要求（t5 finding） | t13 实现 | 证据 | 判定 |
|---|---|---|---|---|
| R5 投毒 ≤2s | 投毒纠正 ≤2s 未成立（证据 2.4s；最坏 ~4s）。二选一：周期刷新绕过 mtime 节流并把阈值改 ≤2.5s，或周期缩到 ≤1.5s | `bounds_refresh_request(display,maxX,maxY,force)`（L1822）：周期刷新 **force=1** 绕过 `mtime<2s` 节流（L1841 `if (!force && stat…<2) return;`）；滑动路径 **force=0** 保留 2s 节流（L2045）；主循环 L3094 force=1；最坏 = 下一 tick(≤2s) + dumpsys(≈0.1–0.3s) ≈≤2.3s | `helper-v166-poison-t13.txt`：每次投毒后立刻 900,408（被带偏），2.0s/2.3s/2.5s 三次取样均 1280,480（task 0..2560/0..1600），cache 均恢复；HELPER §2.3 | **PASS**（≤2.5s；2.0s 样本已 ≤2s，阈值文字见 R5TEXT） |
| R2 C 阻塞 | `case 'C'` 主循环 `usleep(8ms)×n+30+8ms×n`（8 键 ~158ms）未 fork | `case 'C'`（L2702–2736）`pid_t kc=fork()`（L2724），子进程 `cmd_key_combo`+`out("KCOMBO…")`（L2727–2728），父进程仅错误分支；主循环无该 158ms 阻塞 | `helper-v166-popen-audit-r2.txt` §5；HELPER §2.6/§4.3；t13 smoke `OUT lines=96 ERR=0` | **PASS**（源码+审计；smoke 细节见 R3/SMOKE） |
| R4 审计旧行号 | popen 审计/HELPER 行号对的是 3021 行旧版 | `probe_v166_helper_audit.sh` 在最终源码 `9994c286…`（3219 行）重生成 `helper-v166-popen-audit-r2.txt`；全部 popen/system 行号+关键函数行号；`cmd_swipe`（L2025）体内 popen/system/execv/fork=none；HELPER §2.6/§4 改用新行号 | 审计文件 §1–§6；审查人逐条对照当前源码（637/746/772/803/…/2915 等）一致 | **PASS** |

## 2. t2 的 9 条 acceptance 复核（t13 后仍成立）

| # | acceptance | 判定 | 说明 |
|---|---|---|---|
| 1 | 单次推杆只注一个轴/一个区域；双轴超阈按仲裁 | PASS | t13 未动 `swipe_submit`/`swipe_spawn`/`gesture_*`；t4 A1/A2/A3 + t2 appaxis 证据仍有效 |
| 2 | 串行队列，应用侧 TOUCH 完整 | PASS | 同上；t4 A4 starts=18=dones、overlaps=0；t2 appaxis 5/5、6/6、4/4 |
| 3 | 投毒 ≤2s 纠正；起手点回 task 内 | PASS（按 ≤2.5s；R5TEXT） | t13 2.0/2.3/2.5s 三点均 1280,480；2.0s 样本已 ≤2s；HELPER §2.3 写 ≤2.5s；t5 requiredFix 允许 |
| 4 | 唤醒：Dozing→Awake；已亮空操作 | PASS | t13 未动 wake；t13 smoke `p`→Dozing、`u`→Awake；t2/t4 K1/K2 仍有效 |
| 5 | open_app 主路径 resolve+am start -n | PASS | t13 未动 `case 'w'`/`resolve_component`；t2 final-all via rc=0、fallback=0/monkey=0；t4 G1/G2 |
| 6 | 主循环无同步 popen/dumpsys/input；prep 中位<1500、最大<5000µs | PASS | 审计 r2 全 popen 在子进程；C 已 fork；prep 未变（t2 中位 200/max 391、t4 108/226 max 661）；R/j 见 §4.3 |
| 7 | 增益查询/设置；g_pointer_gain 参与 | PASS | t13 未动 `g`/`effective_gain`/`pointer_goto`；t2 gain 证据 |
| 8 | smoke 全部命令 + DPAD_CENTER/SELECT/WHEEL 不回退 | PASS | t13 smoke OUT=96、ERR=0；C 改异步后 `KCOMBO` 由子进程回包；t4 I1/I3/I4/I6 仍有效 |
| 9 | aarch64 静态编译；推送哈希=编译产物 | PASS（最终哈希） | t13 源码 9994c286 → 产物 1bf7306f（851928 B）；设备/模块同哈希；changedPaths 未列 binary，见 BINARY |

## 3. 主循环阻塞审计（t14 acceptance #2）

- 当前源码全部 `popen/system`（审计 r2 §1）都在子进程分支或子进程专用函数：`caption_fullscreen_click`（J，fork 内）、`wake_slow_path`（fork 内）、`top_package`（t，fork）、`cmd_close_app`（L，fork）、`cmd_cursor_query`（c，自身 fork）、`bounds_refresh_poll`（fork）、`wake_refresh_async`（fork）、`cmd_switch_app`（Y，fork）、`resolve_component`（w，fork）等。
- **J 路径**：`case 'J'` fork →`caption_fullscreen_click`，内部 popen/system/usleep 全在子进程；主循环不阻塞。**wake 慢链路**：`wake_slow_path` 自身 fork（L1063），`cmd_wake_screen`（L1110）只读缓存+可选 uinput+fork。**c**：`cmd_cursor_query`（L1318）自身 fork。
- **C**：已 fork（L2724），主循环无 158ms 阻塞；**R**≈150ms、`j`/`ensure_mouse`≈120ms 设备创建仍在主循环，已在 HELPER §4.3 记录（不含 popen/input）；键释放延时队列非阻塞。
- 审计 r2 的 `cmd_swipe`（L2025）函数体内 popen/system/execv/fork=**none**；滑动注入 `spawn_exec`（L204，fork+execv）在 `swipe_spawn` 里，prep 不含 fork 等待。
- 结论：**主循环没有同步 popen/dumpsys/input**；仅 R/j 两个设备创建固定等待（已知边界），C 已消除。PASS。

## 4. 回归 / 其他 acceptance

- **open_app**：源码 `case 'w'`（当前 L2879+，resolve_component L2472）未改；t13 smoke/OPEN_APP 路径未改；t2 final-all `via .MainActivity`/`.splash.SplashActivity` rc=0、fallback=0/monkey=0；t4 G1/G2 仍有效。PASS。
- **DPAD_CENTER**：`case 'D'` 23→28 未改；t13 smoke KEYUIN；t4 I1 mouse_click=0/key_enter=1。PASS。
- **SELECT 真实下滑**：`case 'N'`/串行队列未改；t13 smoke `NOTIF swipe rc=0`；t4 I6 NotificationShade + 截图。PASS。
- **WHEEL 方向**：`cmd_wheel` 未改；t13 smoke `WHEEL ±3 h=1`、`±2 h=0`；t4 I3/I4。PASS。
- **串行队列语义**：R5 force 只改 bounds 刷新；C fork 不影响 swipe 队列；t4 A4 仍有效。PASS。
- **helper 进程级 CPU**：t13 新增 `helper-v166-cpu-60s.txt`：v1.66 helper 自身 23 ticks/60s=0.38%，子进程 81 ticks=1.35%；v1.65 0.35% / 2.32%。同一 60s 窗口、同一方法、release 静态二进制；helper 资源未回退（子进程更低）。PASS（仅 helper；应用侧见 R1）。

## 5. H 组 CPU 口径裁定（t14 acceptance #5）

- t13 的 helper CPU 用 **进程级 utime+stime** + 单列 cutime+cstime，已把子进程（dumpsys/input）分开，结论 0.38%+1.35% vs 0.35%+2.32%，方法合理。
- **应用侧**（engine）仍是 t4 H3 的**线程级快照**（3.53/3.47%），漏掉短命 JIT 线程；同构建进程级 `/proc/<pid>/stat` 为 **6.03/5.97%**，超过 4% 阈值。t13 的 HELPER §4.4 已明确「应用侧 release-build CPU 对比不在本任务范围（t7 负责）；H3 线程级仅辅助、不含短命 JIT；未复测前不得写 CPU 不回退/提速」。
- **裁定：不可比，必须 release 构建进程级 60s 复测后才可宣称「CPU 3.5%/提速」**。t13 的 helper 部分已闭环；应用侧留给 t7（R1）。这是条件，不是 t13 的失败。

## 6. Findings（非阻塞；R1/R3 留给 t7/t12）

| id | severity | problem | requiredFix | file:line |
|---|---|---|---|---|
| R1-APP-CPU-RELEASE | **medium** | t13 已把 helper 的 60s CPU 做成进程级（0.38%+1.35% vs 0.35%+2.32%），但应用侧 engine 仍用 t4 H3 的线程级 3.53/3.47%；同构建进程级 `/proc/<pid>/stat` 6.03/5.97% >4%。debug 构建下 JIT 短命线程造成偏差，应用侧「CPU 3.5%/提速」仍不可比。 | t7 在 release 构建做 60s 进程级（utime+stime，分离 cutime/cstime）复测，与 v1.65 同方法；未复测前发布说明只引用 H1 7/13ms 与 H2 prep，不写 CPU/资源不回退；H3 线程级仅辅助。 | `work/docs/VERIFY-v166.md:155,158`；`work/docs/HELPER-v166.md:363-379` |
| R5TEXT-2S | low | t2 任务书 acceptance #3 仍写「投毒 ≤2s 纠正」；t13 的实现/HELPER §2.3 已改为「≤2.5s」（最坏 2.3s），证据 2.0/2.3/2.5s 三点；2.0s 样本已 ≤2s。任务书文字与修复后的验收口径不一致。 | captain/t7 把 t2 acceptance #3 的「≤2s」amend 为「≤2.5s（2.0/2.3/2.5s 取样）」或在 VERIFY/集成文档写明该变更；不要把「≤2s 保证」写入发布说明。 | `work/docs/HELPER-v166.md:148-172`；t2 acceptance #3 |
| R3-VERIFY-OPEN | low | t13 的 §4.1 第 5 条把验证口径写清楚了（L3 ≤8px、prep max<5000、B2/B3 最小位移、I3 方向性），但 `VERIFY-v166.md` 本身仍是 D/E 80/40px、H2 只判中位、B2/B3 用「>0」、I3 无最小位移；t13 未改 VERIFY（按分工留 t12/t7）。 | t12/t7 按 HELPER §4.1 第 5 条收紧 VERIFY：D/E 按 ≤8px、H2 加 max<5000、B2/B3 标注最小位移、I3 标注方向性；否则未来 9–79px 回归会漏检。 | `work/docs/VERIFY-v166.md:100-107,118-124,155,887,991`；`work/docs/HELPER-v166.md:349` |
| SMOKE-EVIDENCE | low | `helper-v166-smoke-t13.txt` 只有 `OUT lines=96 / ERR count=0` 的摘要和 helper.log tail，没有 96 行原文；t13 输出声称的 `KCOMBO 0 2 emitted=2` 未在该证据文件中出现（源码审计证明了 C fork，但 smoke 的具体回包不可复核）。 | 把 96 行 OUT（至少 C/KCOMBO、NOTIF、WHEEL、KEYUIN 行）存入 evidence，或在文件里明确只作摘要、C 的行为以源码审计+单独探针为准。 | `work/docs/evidence-v166/helper-v166-smoke-t13.txt:6-8`；t13 输出 |
| BINARY-CHANGEDPATH | low | t13 的 changedPaths 只列 `gpminput.c` 与 `HELPER-v166.md`，实际 `project/app/src/main/assets/gpminput` 也从 `6076b63b…` 变为 `1bf7306f…`（851928 B，设备/模块同哈希）；t13 输出说明写域校验不接受该路径。 | t7/集成把 `assets/gpminput`（1bf7306f）列入发布 changedPaths/校验清单，与 `release/gpminput-v1.66`、设备/模块哈希一致；不要只用源码 hash 发布。 | `project/app/src/main/assets/gpminput`；`work/docs/HELPER-v166.md:1-7,383` |

> 另：`C` 改异步后，主循环可在组合键的 8×8+30+8×8≈158ms 期间处理其它命令；若同时有按键走同一 uinput 键盘，事件可能与组合键交错。t13 smoke 未测并发按键；C 是低频用户组合，t5 的 requiredFix 明确要求 fork，故按已知边界记录，不单独列 finding（建议 t7 在多人/连按场景补一次 smoke）。

## 7. A3 等价性（t14 acceptance #6）

t13 未改 `vgpad`/sendevent/串行队列；t5 的裁定仍成立：A3 用常驻 vgpad + `sendevent` 让 RY=0.73 与 RX=0.36 **同时超阈约 1.2s**，应用侧 `gesture axis arbitration: RY=0.7324 RX=0.36 -> vertical`；应用逐事件读同一 evdev 轴值，不依赖同一 HID 帧。A0/A1/A2 已用真实 `vgpad stick` 验证单轴/判别力。**等价，可接受，不强制补测**；release 验收可顺手补一次真实物理双轴斜推。

## 8. 结论与给 t7 的条件

**t13 的 R5/R2/R4 全部闭环**，t2 的 9 条 acceptance 仍成立，未发现回退；helper 进程级 CPU 也做了（0.38%+1.35% vs 0.35%+2.32%）。**t14 判 PASS**。

t7 发布前仍需：
1. 应用侧 release 构建进程级 60s CPU 复测（R1）；未复测前不写 CPU/资源不回退。
2. 把 t2 acceptance #3 的 ≤2s amend 为 ≤2.5s（R5TEXT），或把 t13 的 ≤2.5s 作为正式口径写进 VERIFY/集成文档。
3. 按 HELPER §4.1 第 5 条收紧 VERIFY 的 D/E/H2/B2/B3/I3（R3，t12/t7）。
4. 把 `assets/gpminput` 1bf7306f 列入发布 changedPaths/哈希校验（BINARY），`release/gpminput-v1.66` = 设备 = 模块 = 1bf7306f；不要使用 t4 的 4f261754。
5. 把 smoke 96 行原文（或 C/NOTIF/WHEEL/KEYUIN 行）补进证据（SMOKE）。

## 9. 复现

```sh
# 只读复核（本审查执行）
adb -s 192.168.10.36:6666 shell su -c 'sha256sum /data/adb/gpm/gpminput /data/adb/modules/gpm_dex/gpminput; pidof gpminput'
#   1bf7306f… / 1bf7306f… / pid
sha256sum project/app/src/main/assets/gpminput   # 1bf7306f…
sha256sum project/app/src/main/assets/gpminput.c # 9994c286…

# t13 证据复跑（会临时停 watchdog/引擎，结束后恢复）
adb -s 192.168.10.36:6666 push work/scripts/probe_v166_helper_cmds.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell su -c 'sh /data/local/tmp/probe_v166_helper_cmds.sh poison'
adb -s 192.168.10.36:6666 shell su -c 'sh /data/local/tmp/probe_v166_helper_cmds.sh smoke'
```

## 10. 限制

- 审查期间 t16/t17（t6 后续）可能再改应用侧；本报告只审 t13 的 helper 修复与 t2 9 acceptance，不覆盖 t16/t17 的应用侧修复。
- 未重放注入/投毒实验（设备在 t13/t16 使用中）；t13 的证据/源码/审计/CPU 文件为原始证据；本次做了只读哈希、源码行号、HELPER 与证据逐项核对。
- C 异步的并发按键交错未真机测试（§6 注）；R/j 的固定等待仍为已知边界（HELPER §4.3）。
