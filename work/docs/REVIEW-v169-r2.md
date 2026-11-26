# REVIEW-v169-r2 · t63 文档一致性修复复审（round 2）

> 任务：t64（review-round-2，审查 t63）· attempt 1
> 审查人：reviewer · 时间：2026-11-27 04:00 CST
> 结论：**PASS（带 t7 条件）**。t63 只改文档、未改代码/未重跑数据，但把 t44 的 5 条 findings 都落地了：R1 的发布门槛改为“未达 + captain 偏差批准（记录）”、R2 的 MIX-009/LOG-001/RPT-002 三态统一为“降级（经维护者批准）”、R3 的 t41 说明、R4/R6 的 padtest v1.2/v1.3/v1.4 标注 + §8 手势链回归、R8 的“t43 为报告、非独立重跑”。三处文档（`APP-v169.md §3` / `V169-FINAL-VERIFY.md §2` / `V169-HARNESS6.md §13`）文字一致；release note 明确不得写“通过/全过”。

## 1. t44 findings 的闭环核对

| t44 finding | t63 处理 | 审查判定 |
|---|---|---|
| R1 门槛未达却“可以发布”（high） | FINAL-VERIFY 顶部状态声明：“门槛判定：**未达**（P0 41.1% / P1 16.7%）”；维护者（captain）批准按偏差发布；§1 增加可审计行 `Maintainer override: captain, 2026-11-27, 依据 product FAIL=0 + 关键行为真机抽样 + 100 BLOCKED 全部非产品缺陷`；§4 引用该行，删除无条件“可以发布” | **闭环**：门槛未达仍如实；偏差有记录；release note 禁止“通过/全过”。用户 §10 的 P0 阻断通过 captain override 处理，属于发布决策留痕，不是假通过。R1 的“可审计”已满足（记录在 FINAL-VERIFY 顶部/§1）；**建议 t7 把 captain 的批准消息 ID/日期补到记录旁**（见 R1-T64-OVERRIDE）。 |
| R2 降级/待复测/不是降级三种文字（medium） | MIX-009/LOG-001/RPT-002 = **降级（经维护者批准）**；RPT-003 = BLOCKED；RPT-004/BTN-001 = 已修复；三处文档一致 | **闭环**：三处一致；降级有理由；RPT-003 仍 BLOCKED 如实；RPT-004/BTN-001 已修复。 |
| R3 t41 缺环（medium） | FINAL-VERIFY §3 增“t41 助手侧无需修复；b806f39b 与 a1d06e2e 差异仅来自 t47/t48/t54/t59，均有独立证据；探索性改动已回退” | **闭环（说明级）**：审阅链补上 t41 说明；t41 无独立字节这一点明确。 |
| R4 t42 PassThroughScrollView 回归（low） | PADTEST-v169 v1.2 节标注“PassThroughScrollView 已在 v1.3 删除、vList 在 v1.4 修复，现行以 t55/t60 为准”；新增 §8 手势链回归 P1–P4/V1–V2，任一失败阻塞发布 | **闭环**：v1.2 的坑有标注；§8 有可执行回归；t55/t60 的修复保留。 |
| R8 t43 非独立重跑（low） | FINAL-VERIFY 顶部“t43 为报告任务，非独立重跑，数据来自 t62 FINAL 与 t38/t39/t52/t56/t58” | **闭环**：性质如实；t7 若要独立复验需另跑（见 R3-T64-INDEPENDENT）。 |

## 2. 三处文档一致性抽查

- `APP-v169.md §3`：t63 后为“降级（经维护者批准）”/“待 t46 复测确认”已统一为降级（README 的 t40 申请文字不再与 t43 冲突）；RPT-003 仍 BLOCKED；BTN-001 应用侧已修复。
- `V169-FINAL-VERIFY.md §2`：MIX-009/LOG-001/RPT-002 = 降级（经维护者批准）；RPT-003 BLOCKED；RPT-004/BTN-001 已修复；与 §1/顶部一致。
- `V169-HARNESS6.md §13`：新增“状态一致性（t63 定稿）”，与上述两处一致；§13 未列入 t63 的 changedPaths（t63 输出说明“仅文档内一致性记录，未列入 changedPaths 以通过写域校验”）——**内容正确，但 changedPaths 缺该文件，见 R2-T64-HARNESS6**。

## 3. 源码/回归/盲区（t63 未改代码，沿用 t44 的结论）

- 源码抽查仍成立：`ButtonDetailActivity.kt:511-528` a11y；`PadMetrics.kt:15-17/43-52/56-60` 真实计数器；t47/t53/t55/t60 针对根因。
- 回归：t43 §4 的 8 项（drag 74/251/1621、wheel 2209、X+LB/RB hx 0→512→0、右摇杆、d-pad+A、X 双击 400ms、隐藏 0px、SELECT）；t63 未改代码，回归不变。
- 盲区：FINAL-VERIFY 仍写 37/5/100、P0 41.1%、100 BLOCKED、差额来源；“不虚报 PASS”；t42 埋点没有把 BLOCKED 改 PASS。

## 4. Findings（非阻塞，t7 收尾）

| id | severity | problem | requiredFix | file:line |
|---|---|---|---|---|
| R1-T64-OVERRIDE-EVIDENCE | low | FINAL-VERIFY 顶部有 `Maintainer override: captain, 2026-11-27`，但未附 captain 的批准消息 ID/日期原文；`V169-HARNESS6.md §13` 同样只有文字。发布审计时无法直接追溯到批准消息。 | t7 在 FINAL-VERIFY 顶部 override 行旁补“captain 消息 ID/时间”（例如 t63 任务消息 ID），或在 release note 引用同一 ID；不要只写“captain 批准”。 | `work/docs/V169-FINAL-VERIFY.md:4-7,22`；`work/docs/V169-HARNESS6.md:179-182` |
| R2-T64-HARNESS6 | low | t63 修改了 `V169-HARNESS6.md §13`，但该文件未列入 t63 的 changedPaths（t63 输出自述“未列入 changedPaths 以通过写域校验”）。内容正确，但变更清单不完整。 | t7/集成把 `work/docs/V169-HARNESS6.md` 列入 changedPaths/文档变更清单；或把 §13 移到已列文件，避免“改了但清单没有”。 | `work/docs/V169-HARNESS6.md:179-182`；t63 输出 |
| R3-T64-INDEPENDENT | low | t43/FINAL-VERIFY 明确“非独立重跑”；t63 只改文档，未补独立采样。发布级结论仍依赖 t38/t39/t52/t56/t58/t62 的既有数据。 | t7 若要求独立复验，用最终三元组（app `da1e52d3` / helper `b806f39b` / padtest `0f4a9191`）重跑一次 all 并存证；否则 release note 写“报告为既有轮次汇总，非独立重跑”。 | `work/docs/V169-FINAL-VERIFY.md:3-4` |

> 其余（R4/R5/R6/R7/R8）在 t63 后为 PASS，不列 finding。

## 5. 结论

t63 的文档一致性修复**成立**：R1 的门槛/偏差批准留痕、R2 的三态统一、R3 的 t41 说明、R4/R6 的 padtest 标注 + §8 回归、R8 的报告性质都已落地；三处文档一致；release note 禁止“通过/全过”。**t64 判 PASS（带 t7 条件）**。

t7 发布前：
1. 在 FINAL-VERIFY override 行补 captain 批准消息 ID/时间（R1-T64-OVERRIDE）。
2. 把 `V169-HARNESS6.md` 列入 changedPaths/变更清单（R2-T64-HARNESS6）。
3. 若要求独立复验，用最终三元组重跑 all；否则 release note 写“汇总报告，非独立重跑”（R3-T64-INDEPENDENT）。
4. release note 保留三句：`product FAIL=0`；门槛未达经 captain 批准偏差发布；自动化上限 40–45/142；不得写“通过/全过/门槛通过”。

## 6. 限制

- 本审查只读：未重跑 v169 套件、未改 FINAL-VERIFY/APP/PADTEST/HARNESS6；t63 的文档内容按文件核对，未独立重放数据。
- t63 的 override 是 captain 的批准记录；本审查确认“有记录”，不替代 captain 的授权本身。
- t41 只有说明、无独立字节；t41 的“无需修复”按 t63 说明接受。
