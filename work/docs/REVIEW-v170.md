# REVIEW-v170 · t65/t66/t67 滚轮/控制通道拖拽审查

> 任务：t68（审查 t65 padtest 纵向滚轮 + t66 控制通道 drag 产品级化 + t67 证据）· attempt 1
> 审查人：reviewer · 时间：2026-11-27 14:10 CST · 设备：SM-F9360（adb 192.168.10.36:6666，2560×1600）
> 结论：**PASS（带 t7 条件）**。padtest 的滚轮支持是真实 `onGenericMotionEvent`/`ACTION_SCROLL`（ProbeActivity/AxisLockView），不是文案；控制通道拖拽 `d/m/e` 在 t72 有客观 `vertical_offset 5→7 / 7→12`、`ERR_ARG`/`ERR_STATE`、auto-up、pid 稳定；MIX-001/003 有内层 offset 0→3→5→7→12 的客观证据；S 8 的**投递**有 PadProbe v=8/h=8 四向证据，但**内容位移**如实记 `BLOCKED(wheel-content-displacement-unmeasurable)`，没有假 PASS。**t72 的 `V169-FINAL3.md` 把“投递 PASS / 内容 BLOCKED”分开写，符合要求；发布说明不得把 S 8 写成“内容 PASS”。**

## 0. 被审对象/三元组

| 项 | 值 |
|---|---|
| app | `d31e5128…`（1.69/71；设备=本机） |
| helper | `eb0b5dfc…`（gpm=module=assets；含控制通道/detached drag） |
| padtest | `0f4a9191…`（v1.4/5） |
| 报告/证据 | `work/docs/V169-FINAL3.md`（5358B）、`work/docs/evidence-v169/t72_all.out`、`/data/local/tmp/v169_20261127-134204.log` |

## 1. t65：padtest 纵向滚轮真实性

| 检查 | 证据 | 判定 |
|---|---|---|
| `onGenericMotionEvent`/`ACTION_SCROLL` 处理 | `ProbeActivity.kt:148-163`：`ACTION_SCROLL` → `AXIS_VSCROLL`/`AXIS_HSCROLL` 取值；`AxisLockView.kt:113-133`：`onGenericMotionEvent` 的 `ACTION_SCROLL` 分支；不是只改文案 | **PASS** |
| 四向投递 | t72 §3：`S 8`→`WHEEL 8 h=0` + PadProbe `v=8.0 h=0.0`；`S -8`→`v=-8.0`；`H 8`→`h=8.0`；`H -8`→`h=-8.0`；方向正确 | **PASS（投递）** |
| 内容位移 | t72 §4：前台 Settings 搜索页无滚动内容；DisplaySettings 后 a11y 树退化为全屏根节点（text=0、bounds 全屏）；`input swipe` 对照同样不可读 → `BLOCKED(wheel-content-displacement-unmeasurable)` | **BLOCKED（如实）** |
| t55/t60 回归 | t72 §7 + FINAL3 §8：pager `hx 0→512→0`、vList 内层 offset 仍在；t65 未改 v1.3/v1.4 的手势链 | **PASS** |
| padtest 自身滚轮计数 | t72 引 t71 的 0→2→4；本机 a11y 文本为空不可读，已记 `padtest-cannot-measure-wheel`（测试台自身限制），不冒充内容位移 | **PASS（有区分）** |

> **关键**：S 8 的 PASS 是“投递链 PASS”，不是“内容位移 PASS”。t72 的 §3 vs §4 分得清楚；t68 接受这个区分，但要求发布/报告不得把 S 8 写成“列表实际滚动 PASS”（R1）。

## 2. t66：控制通道 drag 产品级化

| 检查 | 证据 | 判定 |
|---|---|---|
| 根因/两条路径 | helper `gpmctl.sock`（`g_ctl_listen`、`g_out_fd` 临时切输出；`HELPER-v169.md` §6）与 App `gpm.sock` 复用同一 `handle_line`；拖拽状态放 mmap 共享页（`struct gpm_drag_sh`：active/disp/ox/oy/dx/dy/ms/release/stamp），父进程 `shared_drag_poll()` 每 20px 分块交 `drag_move`，`drag_tick()` 发帧；`e` 先 drain 再 `drag_release`；1.5s 无 `m` 由 `drag_tick` auto-up（§7）。**不是靠延时/重试** | **PASS** |
| 客观位移 | t72 §5：`d 0 1280 1000`→`m 0 0 -400 900`→`e`，`vertical_offset 5→7`；更大位移 auto-up `7→12`（Δ5） | **PASS** |
| 回包/故障码 | `ERR_ARG d`（`d 0 1280`）、`ERR_STATE m no-down`（无 down 的 m）；`DRAG down/move/up` 齐全 | **PASS** |
| auto-up | 不发 `e`，3.5s 后 `DRAG up … why=auto-up idle`；1.5s 空闲保护在 helper `drag_tick` | **PASS** |
| 并发/稳定 | 控制通道连续 10 次命令 0 失败、helper pid 25220 不变、无 SIGPIPE；App 通道/控制通道共享 drag 状态，断开不影响 App（§6/§7） | **PASS** |
| frames 口径 | `emitted==frames` 成立；`frames>0` 未稳定（cmd-e 路径 `frames=0 emitted=0 dur=529ms why=cmd-e`，auto-up 本轮也 0，仅一次 15/15）——t72 按 captain 新口径如实记录，位移由 offset 证明，不算 FAIL | **PASS（记录级）** |

## 3. t67 证据与 t72 全量

- t72 的 142 行：PASS 37 / FAIL 5 / BLOCKED 100；P0 41.1%；三态 41/6/103 → 36/6/100 → 37/5/100 → 37/5/100 → 37/5/100。FAIL 5 仍是 MIX-009/LOG-001/RPT-002/RPT-003/BTN-001（非产品缺陷，见 V169-FINAL §4）。
- MIX-001/003：内层 `vertical_offset` 0→3→5→7→12 单调、外层标题不动 → PASS；MIX-002/004~008：a11y 文本空 + `dumpsys activity top` 仅顶层 → `BLOCKED(outer-measurement-inconclusive)`，没有把 002/004~008 强行 PASS。
- 回归全 PASS：74/251/1621px、滚轮 9 步 2209px、`hx 0→512→0`、右摇杆、d-pad+A、双击、隐藏、SELECT、P 六点 ≤3px。

## 4. Findings（t7 收尾）

| id | severity | problem | requiredFix | file:line |
|---|---|---|---|---|
| R1-S8-CONTENT-BLOCKED | **medium** | t72 的 S 8 是**投递 PASS**（helper WHEEL + PadProbe v=8）但**内容位移 BLOCKED**（Settings/DisplaySettings a11y 不可读）；若发布/报告把 S 8 写成“纵向滚轮列表实际滚动 PASS”就是假通过。t72 §3/§4 已区分，但 release note/FINAL 摘要需保持。 | 发布说明/FINAL3 摘要固定写“S 8 投递 PASS、内容位移 BLOCKED(wheel-content-displacement-unmeasurable)”；不得写“S 8 滚轮内容 PASS”。若要闭合内容位移，需换可滚且 a11y 可读的前台 App（padtest 自身 v1.4 的 vList/ScrollTest 或第三方列表），用 `vertical_offset`/`scrollY` 前后差 ≥1 证明。 | `work/docs/V169-FINAL3.md:21-30`；`work/docs/evidence-v169/t72_all.out` |
| R2-PADTEST-WHEEL-COUNT | low | t72 的 padtest 自身“滚轮计数”因 a11y 文本为空不可读，只引 t71 的 0→2→4；当前证据链不能直接复现 padtest 计数。 | 保留 t65 的 `onGenericMotionEvent`/`ACTION_SCROLL` 实现；如要 padtest 计数作为证据，在 `ProbeActivity`/`ScrollTestActivity` 用 `PadMetrics` 计数并输出到 report JSON（不依赖 a11y 文本），或明确 t71 的 0→2→4 为历史证据。 | `ProbeActivity.kt:148-163`；`PADTEST-v169.md`；t72 §3 |
| R3-T65-T66-EVIDENCE | low | t68 的依赖结果里没有 t65/t66/t67 的独立交付文本，只有 t72 的最终报告；t65/t66 的 changedPaths/字节差异需从 t72/HELPER/PADTEST 追溯。 | t7/集成把 t65（padtest 滚轮）/t66（控制通道 drag）的 changedPaths 与字节列入发布清单；t72 已绑三元组（app d31e5128 / helper eb0b5dfc / padtest 0f4a9191），发布用该三元组。 | t72 报告；`HELPER-v169.md` §6/§7 |

> t65 滚轮实现、t66 控制拖拽、产品级要素、MIX-001/003、回归均 PASS，不列 finding。

## 5. 结论

t65 的 padtest 滚轮是真实 `onGenericMotionEvent`/`ACTION_SCROLL`；t66 的控制通道拖拽针对根因（共享 mmap drag + `shared_drag_poll` + `drag_tick` + `e` drain + auto-up），不是延时/重试；产品级要素（ERR_ARG/ERR_STATE、auto-up、并发 pid 稳定）齐备；t72 对 S 8 的“投递 PASS / 内容 BLOCKED”、MIX-001/003 PASS / 002/004~008 BLOCKED 分得清楚。**t68 判 PASS（带 t7 条件）**。

t7 发布前：
1. 发布说明/FINAL3 摘要保持“S 8 投递 PASS、内容 BLOCKED”，不得写“S 8 内容 PASS”（R1）。
2. 若要闭合滚轮内容位移，换可滚且 a11y 可读的前台，用 `scrollY`/`vertical_offset` 前后差证明（R1 的 requiredFix）。
3. padtest 自身滚轮计数如作证据，改为 `PadMetrics` 计数/JSON（R2）。
4. 发布三元组固定 app `d31e5128` / helper `eb0b5dfc` / padtest `0f4a9191`（R3）。

## 6. 限制

- 本审查只读：未重跑 t72；t72 的 FINAL3/证据、padtest/helper 源码为审查材料；本次做了只读 app/helper 哈希、padtest `ProbeActivity`/`AxisLockView`、helper `g_ctl_listen`/`g_out_fd`/`HELPER-v169` §6/§7 核对。
- t65/t66/t67 的独立 changedPaths 不在依赖结果里，R3 只能要求 t7 列入发布清单。
- S 8 内容位移本机不可测（a11y 退化）；R1 不要求伪造 PASS，只要求报告口径不越界。
