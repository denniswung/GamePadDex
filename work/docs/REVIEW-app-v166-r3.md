# REVIEW-app-v166-r3 · t18 修复复审（round 3）

> 任务：t19（review-round-3）· 审查对象：t18（R1 竖向滚动探针假象、R2 dpi direct 48、R3 速度口径）· attempt 1
> 审查人：reviewer · 时间：2026-11-24 03:35 CST · 设备：SM-F9360（adb 192.168.10.36:6666，横屏 2560×1600）
> 结论：**PASS（带 t7 条件）**。t18 无代码变更（APK 仍 `b7fa2662`），R1 的 dPY=0 被证明是 t16 探针假象（指针空闲隐藏 + 未先 L3），t15 在 `b7fa2662` 上 A1 `PY 1415→63 d=1352`、A2 `HS 0→512`、D5/I5 PASS；R2 direct 48 300ms 2462/2485/2481px=96.2/97.1/96.9% 落在 0.9–1.2；R3 按 captain 口径同一时间 1.029。**但 t15 的 67 PASS/1 FAIL（D6）原始套件结果未落到 `evidence-v166-verify`（现有 result 仍是 t4 旧 APK `e8a91185`），D6 是旧 wallClock 口径、当前套件已改 `l3TookMs≤800`，必须由 t7 用最终套件保存并确认 D6 PASS；release CPU 同样归 t7。**

## 0. 被审对象与证据

| 项 | 值 |
|---|---|
| APK | `b7fa2662…0c984d`（与设备 base.apk 一致；t16/t17/t18 未变；1.66/68） |
| helper | `1bf7306f…`（t13 最终，未变） |
| t18 变更 | **无代码**；只改 `work/docs/APP-v166.md`（sha256 `a23031c7…`）与 `work/docs/evidence-v166-app/v166_t16_data.log`（追加 t18 rerun 段） |
| t15 套件 | t18 输出称 `b7fa2662` 上 67 PASS/1 FAIL（D6），D5/I5/A1/A2/BASE-APK PASS；**原始 result 未在 `work/docs/evidence-v166-verify/`**（现有 `auto_suite.result.txt` 仍是 1:43 的 t4 旧 APK `e8a91185`） |
| 当前套件 | `v166_auto_suite.sh` `EXPECT_APK=b7fa2662`；B5/C4 已条件化（`:429-444`、`:482-498`）；D6 已改 `l3TookMs≤800`（`:627-651`） |
| t16 日志 | `v166_t16_data.log` 原有 §3 竖向 `PY 1415→1415 d=0`；t18 在文件末尾追加 “t18 rerun on b7fa2662” 段（A1/A2/manual/control/R2） |

## 1. t18 对 t17 findings 的回应（逐项）

| t17 finding | t18 回应 | 审查判定 |
|---|---|---|
| R1 竖向 dPY=0（high） | 不是回退，是 t16 探针假象：t16 未先 L3 且指针已空闲隐藏 8s+；t15 套件 A1 `PY 1415→63 d=1352`、A2 `HS 0→512`；手动 starts→L3→上推 1.5s `PY 1415→0 d=1415`、helper Z×3、SWIPE_DROP=0；对照 idle 10s 后同推 dPY=0（helper 仍发 SWIPE，锚点失效）；源码 POSPTR 只驱动居中校验，不改 ptrX/ptrY/pointerPos/竖向起手；APP §9.3 已改为真实数字并删除无据表述 | **PASS（R1 关闭）**：t18 的 t16_data.log 追加段 + APP §9.3:88-91 与 t15 A1/A2 一致；t4 A1（旧 APK）d=1337、t15 A1（b7fa2662）d=1352、t18 manual d=1415，三者同量级；idle-hidden 对照解释 t16 d=0。**但 t15 原始 A1/A2 行未保存，见 R3。** |
| R2 dpi 代理/法 A<0.9（medium） | 直接测量（48 速）：从 x≈0 起手 300ms 满推 2462/2485/2481px=96.2/97.1/96.9%，终点 2559（末段 <100px 撞边；`at app edge` 500ms 节流窗口内 0）；250ms×6/5 撞边 2982 不可用；代理 A 89.1–89.9%、代理 B 91.1–93.0% 均标注“代理”；APP §9.1 已标直接/代理 | **PASS（R2 关闭）**：direct 0.962–0.971 在 0.9–1.2；0.9 下限满足；**APP §9.1:80 的“三种测量…均落在 0.9–1.2”对代理 A（0.891–0.899）不成立，见 R1**；上限 1.2 仍非直接证明（2560 屏 48 速 300ms 必撞边），但 0.96–0.97 已满足“落在目标内”。 |
| R3 速度口径 2.057（medium） | 按 captain 定口径，APP §9.2 正式判据=同一时间 1.5s 总位移比 1.029（PASS）；单手势 2.057 仅作设计取舍说明；t3 #5 任务书文字未在 team.json 改 | **PASS（R3 关闭，带文字条件）**：APP §9.2:82-85 已明确；**t3 acceptance #5 仍写“同一手势”，需 captain/t7 amend 为“同一时间总位移”，见 R2。** |
| R4 新 APK 未跑 t4（medium） | t15 在 b7fa2662 重跑：67 PASS/1 FAIL（D6）；D5、I5、A1/A2、BASE-APK PASS；D6 旧 wallClock 含 `l3()` 1.1s sleep+logcat 轮询，当前套件已改 `l3TookMs≤800`（本轮 661 应 PASS），由 t7 用最终套件确认 | **PARTIAL**：D5/I5/A1/A2/BASE-APK 的 PASS 只来自 t18 转述；**t15 的原始 67/1 result 未保存**，当前 result 仍是 t4 旧 APK；D6 的最终 PASS 未落地；见 R3/R7。 |
| R5 release CPU（medium） | 归 t7 | **OPEN → t7 条件**（R4） |
| R6 B5/C4/VERIFY（low） | 当前套件 B5/C4 已条件化（本轮 PASS，vpg=560/hpg=1152）；VERIFY 收紧归 t15/t7 | **PASS（套件）/OPEN（VERIFY）**：`:429-444`/`:482-498` 已是条件检查；VERIFY 仍 80/40 等，t7/t15 收紧（R6）。 |
| R7 hash（low） | APP 已 b7fa2662；t3/VERIFY 仍 1F8A/e8a91185 | **OPEN → t7 统一**（R5） |

## 2. t3 的 9 条 acceptance 复核（t18 后）

| # | acceptance | 判定 | 说明 |
|---|---|---|---|
| 1 | L3 运行时闭环；pointer_speed 0/3/7 各 3 次 ≤80px；不靠固定 325 | PASS | t4 D-PS 9/9 ≤5px（旧 APK）+ t16 L3 1282,803 err=2,3、POSPTR 311ms、l3TookMs=363；t4 D0 删 move_gain 冷启自标定 3.2465813；t18 无代码 |
| 2 | L3 主动退出 nativeNav；A 恢复鼠标点击 | PASS（t15 D5） | t15 在 b7fa2662 上 D5 PASS（t18 转述）；t4 D5 旧 APK 也 PASS；t16 的 POSPTR 不改 nativeNav 清除路径 |
| 3 | 边界四方向真实边缘、est-real ≤40px、d-pad/隐藏后可达 | PASS（t15 D5/I5） | t4 E1-E4 0/2559/0/1599、est-real 0–1px；t15 D5/I5 在 b7fa2662 PASS（t18 转述）；t18 无代码 |
| 4 | dpi：满推 300ms 0.9–1.2 屏宽；0–30% 有响应；半推 >0 | **PASS（direct 0.96–0.97）** | t18 直接测量 2462/2485/2481=96.2/97.1/96.9%；代理 A 0.891–0.899 是低估（<0.9）；代理 B 0.911–0.930；t4 B1 0.97 旧；0.9–1.2 满足；上限 1.2 非直接，但 acceptance 是“落在”范围 |
| 5 | 滑动速度：同一手势横/竖 0.8–1.25；APP 文档给数值 | **PASS（按 captain 口径）** | APP §9.2 正式=同一时间 1.5s 总位移 3456/3360=1.029；单手势 2.057 仅设计说明；**t3 acceptance #5 的文字仍是“同一手势”，需 amend（R2）** |
| 6 | 唤醒：0.92→Awake；0.37/0.73/慢爬→Dozing | PASS | t16 riseCrossMs 快推 0/208→Awake、慢爬 1159/fast=false→Dozing；t4 F1–F4 |
| 7 | Y+上/下 打开正确应用，不覆盖自定义 | PASS | t4 G1/G2/G3；t18 无代码；t3 #7 的 G3 自定义不被覆盖 |
| 8 | 响应提速：事件→动作/帧耗时；8ms 循环无阻塞/prefs | PASS（CPU 条件） | t4 H1 7/13ms、APP §8 帧 128–176µs、prefs_per_tick=0；t16 L3 498/355/365；CPU 见 R4（release t7） |
| 9 | 回归全部保持 | **PASS（带 t7 D6 条件）** | t15 在 b7fa2662 上 67 PASS/1 FAIL（D6）；D5/I5/A1/A2 PASS；竖向 dPY=0 已证明探针假象；D6 是脚本口径（旧 wallClock），当前套件 l3TookMs≤800；**t7 用最终套件确认 D6 PASS 并保存原始 result（R3）**；DPAD/X/LB/RB/SELECT/idle 代码未改 |

## 3. t18 的证据质量问题

- **t18 的 t16_data.log 追加段是自述摘要**（“R1 suite A1 ... result PASS”等），不是 t15 原始套件输出；`work/docs/evidence-v166-verify/` 里没有任何 t15/b7fa2662 的 `auto_suite.result` 文件（现有 `auto_suite.result.txt` 是 1:43 的 t4 旧 APK `e8a91185`）。因此 **t15 的 67/1、D5/I5/A1/A2 PASS 目前不可独立复核**；t19 只能按 t18 转述 + 当前套件代码 + APP/日志判断，最终必须由 t7 的套件 result 落盘（R3）。
- **APP §9.1:80 措辞**：“三种测量共同给出 ≥0.89、直接可见 ≥0.96，均落在 0.9–1.2 目标内”——代理 A 0.891–0.899 **不在** 0.9–1.2；应改成“direct 0.96–0.97 与 proxy B 0.91–0.93 在目标内；proxy A 0.89–0.90 是含起步加速的低估，仅作交叉印证”（R1）。
- **APP §9.2**：captain 口径已写；t3 acceptance #5 的 team.json 文本未改（R2）。
- **D6**：当前套件 `:644` 已改 `l3TookMs≤800`；t18 称“本轮 661 应 PASS”；t15 的 67/1 的 D6 是旧版 `wallClock` 含 `l3()` 1.1s sleep + logcat 轮询；t7 最终套件必须显示 D6 PASS 并保存 result（R3/R7）。

## 4. Findings（非阻塞，t7 关闭）

| id | severity | problem | requiredFix | file:line |
|---|---|---|---|---|
| R1-DPI-A-WORDING | low | APP §9.1:80 写“三种测量…均落在 0.9–1.2”；代理 A 89.1–89.9%（<0.9）不在范围内；direct 96.2–97.1% 与 proxy B 91.1–93.0% 在范围内。 | 改为“direct 0.96–0.97 与 proxy B 0.91–0.93 在 0.9–1.2；proxy A 0.89–0.90 是含起步加速的低估，仅交叉印证”；不要把 proxy A 算进“均落在”。 | `work/docs/APP-v166.md:80` |
| R2-SPEED-ACCEPT-TEXT | low | t3 acceptance #5 在 team.json/任务书仍写“同一手势”；APP §9.2 已按 captain 口径改“同一时间 1.5s 总位移 1.029”，单手势 2.057 仅设计说明。 | captain/t7 把 t3 #5 的 acceptance 文字 amend 为“同一时间（1.5s）总位移比 0.8–1.25”，或把 APP 口径写进 VERIFY/集成文档；避免发布说明同时出现两种判据。 | t3 acceptance #5；`work/docs/APP-v166.md:82-85` |
| R3-T15-RAW-D6 | **medium** | t15 的 67 PASS/1 FAIL（D6）只在 t18 输出/t16_data.log 追加摘要里；`work/docs/evidence-v166-verify/` 没有 b7fa2662 的原始 `auto_suite.result`（现有 result 是 t4 旧 APK e8a91185）。D6 旧 wallClock 含 l3() 1.1s sleep+logcat 轮询；当前套件已改 l3TookMs≤800，但最终 D6 未落地。 | t7 用当前 `v166_auto_suite.sh`（EXPECT_APK=b7fa2662、l3TookMs≤800、B5/C4 条件化）跑完整套件，保存 `auto_suite.result.txt` + console 到 evidence-v166-verify，确认 67/68 PASS、D6 PASS、D5/I5/A1/A2 PASS；不要用 t18 的自述摘要当最终套件结果。 | `work/docs/evidence-v166-verify/auto_suite.result.txt`（当前 1:43 旧）；`work/scripts/v166_auto_suite.sh:627-651` |
| R4-CPU-RELEASE | **medium** | APP §8:71 仍是 debug 线程级 3.70–3.80%；t4 H3 同构建进程级 6.03/5.97% >4%；t18 未做 release CPU。 | t7 release 构建进程级 60s（utime+stime，分离 cutime/cstime）复测；未复测前发布说明只引用 H1 7/13ms + H2 prep，不写 CPU/资源不回退。 | `work/docs/APP-v166.md:71`；`work/docs/VERIFY-v166.md:155,158` |
| R5-HASH | low | APP 已 b7fa2662；t3 输出仍 1F8A；t4 VERIFY 仍 e8a91185；发布文档需统一。 | t7 发布文档/Release 用 b7fa2662（APK）+ 1bf7306f（helper）；t3/VERIFY 旧哈希只作历史。 | `work/docs/APP-v166.md:3`；`work/docs/VERIFY-v166.md:15-17` |
| R6-B5C4-VERIFY | low | 当前套件 B5/C4 已条件化（`:429-444`/`:482-498`）；VERIFY 的 D/E 80/40px、H2 只判中位、B2/B3>0、I3 无最小位移未收紧；t15/t7 分工。 | t15/t7 按 HELPER §4.1 第 5 条收紧 VERIFY；发布前套件 B5/C4 不得退回无条件 PASS。 | `work/scripts/v166_auto_suite.sh:429-444,482-498`；`work/docs/VERIFY-v166.md:85,94,100-107,118-124` |

## 5. 结论与给 t7 的条件

t18 的 R1（竖向 dPY=0 探针假象）、R2（direct 48 96.2–97.1%）、R3（同一时间 1.029）均成立；t3 #1/#2/#3/#4/#5/#6/#7/#8 通过，#9 带 t7 D6 条件。**t19 判 PASS（带条件）**。

t7 发布前必须：
1. 用当前套件在 `b7fa2662`+`1bf7306f` 上重跑完整 t4，保存 result/console 到 `evidence-v166-verify`，确认 D6 PASS（l3TookMs≤800）、D5/I5/A1/A2 PASS（R3）。
2. release 进程级 60s CPU（R4）；发布说明不写 CPU/资源不回退。
3. 把 t3 #5 口径 amend 为“同一时间总位移”（R2）；APP §9.1:80 措辞修正（R1）。
4. 发布文档/Release 统一 b7fa2662 + 1bf7306f（R5）；B5/C4/VERIFY 收紧（R6）。
5. B5/C4 当前条件化已在套件，不要退回无条件 PASS。

## 6. 复现

```sh
# 只读复核（本审查执行）
adb -s 192.168.10.36:6666 shell 'p=$(pm path com.dennis.dexpad | head -1 | sed s/package://); sha256sum "$p"'
#   b7fa2662…0c984d（= 设备；APP §9 已更新）
sha256sum work/docs/APP-v166.md                 # a23031c7…
grep -n 'D6\|l3Took\|B5\|C4' work/scripts/v166_auto_suite.sh
# t15/t7 套件（b7fa2662 + 1bf7306f）
adb -s 192.168.10.36:6666 push work/scripts/v166_auto_suite.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell su -c 'sh /data/local/tmp/v166_auto_suite.sh'
```

## 7. 限制

- 未在设备上重放套件（设备在 t15/t7 使用中）；t18 的 t16_data.log 追加段、APP §9、当前套件代码、t4 旧 result、t15 转述为审查材料；本次做了只读 APK/APP hash、套件 D6/B5/C4 行、t16 日志/APP §9 逐项核对。
- t15 的原始 67/1 result 未落盘，R3 的 PASS 是“t18 转述 + 当前套件代码 + APP/日志”的合议，**不是**独立复核 t15 的原始输出；t7 必须补原始 result。
- D6 的 661ms 来自 t18 转述；最终以 t7 套件为准。
