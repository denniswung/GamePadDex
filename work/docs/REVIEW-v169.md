# REVIEW-v169 · v1.69 修复/降级/埋点/回归审查

> 任务：t44（审查 t40/t41/t42 修复 + t43 最终验证）· attempt 1
> 审查人：reviewer · 时间：2026-11-27 03:50 CST · 设备：SM-F9360（adb 192.168.10.36:6666，2560×1600）
> 结论：**NEEDS_REVISION**。t40 的 BTN-001 a11y、t42 的 padtest 埋点、t47/t53/t55/t60 的根因修复、t43 的最终报告**基本诚实**（37/5/100、P0 41.1%、product FAIL=0、盲区如实）；但 **t43 `V169-FINAL-VERIFY.md` 在“发布门槛判定：未达（P0 41.1%、P1 16.7% vs P0 全 PASS/P1 ≥95%）”之后仍写“可以发布 v1.69（versionCode 71）”**，与用户文档 `docs/TEST-CASES-v1.69.md` §10 的 **P0 发布阻断** 冲突；且 **MIX-009/LOG-001/RPT-002 的“降级”仍是“待复测”，t40 APP-v169 §3 写“不是降级”、t42 改“待 t46 复测确认”、t43 写“降级为已知限制”三种状态不一致，未见维护者批准**；t40/t42/t43 的 t41 修复/证据不在依赖结果中，无法核对。**故 t43 的发布建议/降级结论未达 review pass。**

## 1. 发布门槛对照（用户 §10）

`docs/TEST-CASES-v1.69.md` §10（P0 核心输入/滚动错误、错误页面/列表接收事件、松手不停、模式混用、数据丢失、崩溃/ANR：**发布阻断**）；ENV 门还要求发布 APK/helper 三处字节一致（§10.2，line 60）。t43 的 final：

| 指标 | t43 final（t62） | 用户 §10 门槛 | 判定 |
|---|---|---|---|
| P0 56 条 | 23 PASS / **4 FAIL / 29 BLOCKED = 41.1%** | P0 全 PASS | **未达** |
| P1 84 条 | 14/0/69 = **16.7%** | P1 ≥95% | **未达** |
| PASS/FAIL/BLOCKED | 37/5/100 | — | 如实 |
| product FAIL | 0（5 条均为测量/页面态/padtest 导出） | — | 与 t39 一致 |
| 二元组 | app `da1e52d3` / helper `b806f39b` / padtest `0f4a9191` | 三处字节一致 | 已绑（t43 §0） |

t43 §1 自己写“**发布门槛判定：未达（如实记录）**”，这是诚实的；但 §4“**可以发布 v1.69（versionCode 71）**”与 §1 的门槛判定直接冲突。**审查不能把“门槛未达 + 仍建议发布”当作 pass**：发布需要用户/captain 的显式 override，且发布文档必须写明“P0 41.1%、P1 16.7%、100 BLOCKED，未达 §10 门槛”，不能写“通过/全过”。

## 2. baseline 6 条 FAIL 的三态核对

| ID | t43 三态 | 审查判定 |
|---|---|---|
| MIX-009（P0） | “降级为已知限制（待复测）” | **不成立（待复测≠降级）**：t40 APP-v169 §3 写“待 t46 复测确认（**不是降级**）”；t42 改“待 t46 复测确认”；t43 写“降级为已知限制（待复测）”。三种状态不一致，未见维护者批准。能力由 SCR-022 PASS 覆盖（hx 0→512→0）是事实，但 MIX-009 本身仍是 P0 FAIL/BLOCKED，不能标“降级已批准”。 |
| LOG-001 | “降级为已知限制（待复测）” | 同上；t40 §3 是“待 t46 复测确认”。影响面/复现（APP-v169 §3：save 空态、注入后显示“共 N 条”）有，但“降级”未批准。 |
| RPT-002 | “降级为已知限制（待复测）” | 同上；t40 §3“待 t46 复测确认”。按钮文案修正（“开始测试”）是 harness 匹配问题，不是应用缺陷；但降级未批准。 |
| RPT-003 | **BLOCKED(padtest-txt-export-missing)** | 合理：JSON 409B（RPT-004 PASS）但 TXT 未落盘，属 padtest 导出实现；仍 BLOCKED。 |
| RPT-004 | **已修复（实测）** | 合理：`/sdcard/Android/data/com.dennis.padtest/files/auto-report-latest.json` 409B；t39 的“0→0”已变为 409B。 |
| BTN-001 | **已修复（应用侧）/套件侧待复测** | 应用侧合理：t40 `ButtonDetailActivity.header()` L511-528 设 `contentDescription=summary` + `IMPORTANT_FOR_ACCESSIBILITY_YES`；复测 73 行、`400 ms` text=1、desc=1、package=com.dennis.dexpad（t39 基线 43 行空）。套件仍 force-stop 后抓不到 Activity，是启动时序，不是应用回归。 |

> 结论：**6 条中只有 RPT-004 是“已修复”、BTN-001 是“应用侧修复/套件待复测”、RPT-003 仍 BLOCKED；MIX-009/LOG-001/RPT-002 的“降级”仍是“待复测”，未获批准，不能算三态闭合。** t43 §2 的“降级为已知限制（待复测）”自相矛盾（既是降级又待复测）。

## 3. 源码抽查（修复是否针对根因）

- **t40 BTN-001**：`ButtonDetailActivity.kt:511 header()`；`:526-528` `contentDescription = summary` + `importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_YES`；`:122` 文案 400ms。**针对 a11y 节点空文本的根因，不是调参。** 复测 73 行/400ms 与 t39 43 行空形成对照。
- **t42 padtest 埋点**：`PadMetrics.kt:15-17` `touchFrames/touchMaxGapMs/touchPathPx`；`:43-52` report JSON `frames/max_gap_ms/path_px/continuous`；`:56-60` `left_offset/right_offset/fixed_area_scrolls/fixed_area_wheel/fixed_area_touch`。是**真实计数器**（`frames++`/`maxOf`/`path +=`），不是写死；t42 实测 frames=24/maxGap=18ms/path=65px，t55 左 262/右 253/固定区 1，t60 内层 0→2、外层标题 603 不动。**埋点真实。**
- **t42 的回归**：`PassThroughScrollView` 重写外层 intercept 使分页不响应注入式横向 swipe（t55 删除后恢复）；`vList` 手势被外层抢（t60 `requestDisallowInterceptTouchEvent(true)` 修复）。**“补埋点”不是纯增量，t42 引入了两次手势链回归，t55/t60 已修，但说明 t42 的写域/验证不完整（R4）。**
- **t47/t53/t55/t60**：P 闭环（`pointer_read` + 4 次修正 + 回写共享页）、SCR-022 横向独立冷却/400ms `c` 同步、padtest 1.3 删 PassThrough、1.4 vList disallow——均针对根因，不是调参。
- **t48/t54**：`gpmctl.sock` 0600+SO_PEERCRED uid==0；root 通道与 App 通道共享状态；安全成立。

## 4. 无回归

t43 §4 列出的 v1.68 已确认行为：
- 连续拖拽 3 档 **74/251/1621px**（声称 73/238/1595，差 ≤1.6%）；滚轮 **2209px/9 步**；X+LB/RB **hx 0→512→0**；右摇杆 up=8/dy560、down=5/dy-480；d-pad+DPAD_CENTER；X 双击 400ms；空闲隐藏 **0px** 恢复；SELECT 通知栏。
- 与 v1.68 的 t33/t24/t21 证据一致；t47 的 P 六点 ≤3px、L3 三档 ≤4px、隐藏恢复 908,603（err 8,3）；串行队列 starts=dones/overlaps=0。
- **无回退证据成立**（t43 §4）；t42 的两次手势链回归已被 t55/t60 修，未留到 final。

## 5. 测试台盲区是否如实

- t43 §1/§4 写清 **37/5/100、P0 41.1%、P1 16.7%、100 BLOCKED**，差额为 `ctl-channel-drag-not-delivered` 32、`evidence-incomplete`、`release-no-debug-channel`、UI 二级 37、长压测 8、DeX/多屏 6、真手柄 1；§4 要求发布文档写“不是全过”。
- t62 的 `V169-FINAL.md` §6 写“可自动化上限约 40–45/142，其余以已知限制+真机抽样覆盖，不虚报 PASS”；t43 的 final §1/§4 沿用。
- t42 的“补埋点”没有把 BLOCKED 直接改成 PASS：final 仍 100 BLOCKED；SCR-022 的 PASS 是用 `horizontal_scroll_x` 权威字段改判（t53/t62），不是靠埋点文案。**盲区如实，未被埋点掩盖。**

## 6. Findings

| id | severity | problem | requiredFix | file:line |
|---|---|---|---|---|
| R1-RELEASE-GATE | **high** | t43 `V169-FINAL-VERIFY.md` §1 明确“发布门槛判定：未达（P0 41.1%、P1 16.7% vs P0 全 PASS/P1 ≥95%）”，§4 却写“可以发布 v1.69（versionCode 71）”。用户 `docs/TEST-CASES-v1.69.md` §10 规定 P0 发布阻断；两者冲突。审查不能把“门槛未达 + 建议发布”当 pass。 | 二选一：①撤回“可以发布”，改为“未达 §10 门槛，需用户/captain 显式 override 后才能发”；②如果 captain 已决定 override，在 FINAL-VERIFY 顶部写明“captain override 记录（时间/人）+ 发布文档强制披露 P0 41.1%/P1 16.7%/100 BLOCKED/未达门槛”，且 release note 不得写“通过/全过”。不要把“未达”与“可以发”并列而不解释。 | `work/docs/V169-FINAL-VERIFY.md:17-18,50-55`；`docs/TEST-CASES-v1.69.md:32,60` |
| R2-DEGRADE-APPROVAL | **medium** | MIX-009/LOG-001/RPT-002 的三态不一致：t40 `APP-v169.md` §3 写“待 t46 复测确认（**不是降级**）”；t42 改“待 t46 复测确认”；t43 `V169-FINAL-VERIFY.md` §2 写“降级为已知限制（待复测）”。“降级”没有维护者批准记录，且“待复测”本身说明未闭合。 | 统一为一种状态并留痕：①若批准降级：在 APP/V169-FINAL 写“维护者批准（人/时间）+ 影响面 + 复现步骤 + 替代覆盖（SCR-022/hx、注入事件、前缀匹配/导出目录）”；②若未批准：保持 FAIL/BLOCKED，不写“降级”。t40/t42/t43 三处文字必须一致。 | `work/docs/APP-v169.md:35-43`；`work/docs/V169-FINAL-VERIFY.md:30-32` |
| R3-T41-MISSING | **medium** | 任务要求核对 t40/t41/t42 的修复与 t43 证据；但依赖结果里只有 t40/t42/t43，t41 的修复/证据不在。t43 §3 的修复清单也没有 t41 条目。无法核对 t41 的根因/回归。 | 在 t43/FINAL-VERIFY 或后续补充 t41 的交付（改了什么、证据、字节）；若 t41 只是 t40 的验证/同轮，明确“t41 = t40 的验证，无独立字节”，避免审阅链缺环。 | 依赖结果；`work/docs/V169-FINAL-VERIFY.md:39-48` |
| R4-T42-INSTRUMENTATION-REGRESSION | low | t42 的 `PassThroughScrollView` 重写外层 intercept，导致分页不响应注入式横向 swipe（t55 删除后恢复）；`vList` 手势被外层抢（t60 修）。t42 的“补埋点”不是纯增量，写域/回归验证不完整。 | 保留 t55/t60 的修复；在 PADTEST-v169 的 v1.2 节标注“v1.2 引入的 PassThroughScrollView 已在 v1.3 删除、vList 在 v1.4 修复”，避免后来者按 v1.2 复现；新增埋点时加一条“pager/vList 手势链”回归。 | `work/docs/PADTEST-v169.md` §5/§7；t42/t55/t60 |
| R5-BTN001 | pass | t40 ButtonDetail a11y 修复成立：L511-528 contentDescription/importantForAccessibility；复测 73 行、400ms text=1/desc=1、package=com.dennis.dexpad；套件侧仍因 force-stop 时序抓不到，属启动等待。 | 保留应用侧修复；套件在 force-stop 后等待 Activity 到前台再 dump（或先 am start 再等 2.5s），不要把套件时序当应用回归。 | `ButtonDetailActivity.kt:511-528`；`APP-v169.md:21-34`；`V169-FINAL-VERIFY.md:35` |
| R6-BLIND-SPOTS | pass | t43 §1/§4 如实写 37/5/100、P0 41.1%、100 BLOCKED、差额来源；t62 §6 写“不虚报 PASS”；t42 埋点没有把 BLOCKED 改成 PASS（final 仍 100 BLOCKED）。 | 保留；发布文档沿用“覆盖上限+已知差距+product FAIL=0”三点。 | `V169-FINAL-VERIFY.md:17-24,52-55`；`V169-FINAL.md` §6 |
| R7-REGRESSION | pass | t43 §4 回归 8 项：drag 74/251/1621、wheel 2209、X+LB/RB hx 0→512→0、右摇杆、d-pad+A、X 双击 400ms、隐藏 0px、SELECT；与 v1.68 证据一致。 | 保留；发布前如再跑，用同一字节三态。 | `V169-FINAL-VERIFY.md:57` |
| R8-FINAL-DATA | low | t43 明确“本轮未再跑数据”，final 数据来自 t38/t39/t52/t56/t58/t62；t43 是**报告**，不是独立复跑。报告引用的证据（final_all.out、v169_final.log、report_s22*.json）在 `evidence-v169/` 2.97MB 中；但 t43 自己未重放。 | 发布前如要求“独立复验”，t7 用最终三元组再跑一次 `all` 并把 result 存证；否则在 FINAL-VERIFY 写“本报告为既有轮次汇总，非独立重跑”，避免把 t43 当新采样。 | `V169-FINAL-VERIFY.md:3`；`work/docs/evidence-v169/` |

## 7. 结论

t40/t42 的修复、t47/t53/t55/t60 的根因、t42 埋点的真实性、t43 的盲区/回归披露均成立；但 **t43 的“门槛未达 + 可以发布”冲突（R1，high）** 和 **MIX-009/LOG-001/RPT-002 的“待复测/降级”未批准且三种文字不一致（R2，medium）** 使得 t43 的最终验证不能判 pass；t41 证据缺环（R3）。**t44 判 NEEDS_REVISION（status=failed）**，不是 pass。

返修后（或 captain 显式 override + 发布文档披露）可再判 pass；在此之前发布说明不得写“通过/全过/门槛通过”。

## 8. 限制

- 本审查只读：未重跑 v169 套件、未改 project/、release/、README、V169-FINAL；t43/t62 的数据按其报告/证据索引核对，未独立重放。
- t41 不在依赖结果中，R3 只能指出缺环；t43 的 §3 修复清单未列 t41。
- t42 的 PadMetrics 源码已核对（真实计数器），但 t42 的 pads 版本/回归在 t55/t60 后已变；t43 final 用 padtest v1.4（0f4a9191）。
