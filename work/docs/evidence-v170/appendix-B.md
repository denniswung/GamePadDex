
---

# 附录 B · v1.70 新增用例与执行摘要（integrator / t69，2026-11-27）

> 本文前半部分（359 行）**原样继承 v1.69 的用户原始测试计划**（142 条、P0/P1/P2 分层、记录模板），
> 文件名按发布版本记为 `TEST-CASES-v1.70.md`；本附录只追加 v1.70 的新增用例、执行结果与证据索引，不改动上文。

## B.1 字节基线

| 角色 | 值 |
|---|---|
| 验证三元组（t72 采样，未变） | app `d31e51285a0a3baa71a75ed2b7dca1a7f88697685ae982c35e2f807bfc92c7fb`（1.69/71）/ helper `eb0b5dfc6d5403b30d8200467f773e628729ea5290d1574aeb5651bf33c8c31c` / padtest `0f4a91911360cb4051fff9b54711508e4dc90de797be6ec0e55e83e9a967056d`（v1.4/5） |
| **v1.70 发布字节** | app **`05f4f11f2e48b498556abc35ea58bbc873f032128529d83d6abe9ea5eced876c`**（1.70/72，仅版本号与 v1.69 发布包不同）/ helper **`eb0b5dfc…`**（852976 B）/ padtest **`0f4a9191…`**（不升 v1.5，理由见 B.5） |

## B.2 本轮新增用例

### B.2.1 滚轮投递 4 向（WHEEL 链路）

| 用例 | 步骤 | 判据 | 实测 | 结论 |
|---|---|---|---|---|
| WHEEL-V-UP | `gpmctl … S 8` | helper `WHEEL 8 h=0`；PadProbe `v=8.0 h=0.0` | 一致 | PASS |
| WHEEL-V-DOWN | `S -8` | `WHEEL -8 h=0`；`v=-8.0` | 一致 | PASS |
| WHEEL-H-RIGHT | `H 8` | `WHEEL 8 h=1`；`h=8.0` | 一致 | PASS |
| WHEEL-H-LEFT | `H -8` | `WHEEL -8 h=1`；`h=-8.0` | 一致 | PASS |
| **WHEEL-CONTENT** | 前台换可滚页面后滚轮 | 内容位移可读（scrollY/offset 前后差 ≥1） | Settings 搜索页无滚动内容；DisplaySettings 的 a11y 树退化为仅全屏根节点（text=0、bounds 全屏），`input swipe` 对照同样不可读 | **BLOCKED(wheel-content-displacement-unmeasurable)** |

> 纪律要求：滚轮 = **投递 PASS、内容位移 BLOCKED**；任何发布说明/摘要**不得**写成“S 8 内容 PASS”。

### B.2.2 控制通道拖拽（v1.70 产品级化，`gpmctl.sock`）

| 用例 | 步骤 | 判据 | 实测 | 结论 |
|---|---|---|---|---|
| CTL-DRAG-V | `d 0 1280 700` → `m 0 0 -400 400` → `e 0` | `instrumentation.vertical_offset` 增加 | **0→3** | PASS |
| CTL-DRAG-H | `d 0 1280 1000` → `m 0 -500 0 400` → `e 0` | `instrumentation.horizontal_scroll_x` 增加 | **0→500** | PASS |
| CTL-AUTOUP | `d` → `m`，**不发 e**，等 2.6s | helper `why=auto-up`；后续 `e` 返回 OK；无僵尸拖拽 | `voff 3→5`、`auto-up` 行 6 条、`OK e` | PASS |
| CTL-ERR-ARG | `d`（缺参） | `ERR_ARG d` | `ERR_ARG d` | PASS |
| CTL-ERR-STATE | `m`（无 down） | `ERR_STATE m no-down` | `ERR_STATE m no-down` | PASS |
| CTL-PROTO | 复用 App 通道 `handle_line`、拖拽状态在 mmap 共享页、`e` 先 drain 再 release | 连接断开不影响 App 会话；`?` 自检正常 | `?` → CAP 13/13=1、ERR=0 | PASS |

### B.2.3 混合界面归属（MIX）

| 用例 | 判据 | 实测 | 结论 |
|---|---|---|---|
| MIX-001 / MIX-003 | 内层 `vertical_offset` 单调增、外层不动 | 0→3→5→7→12 单调增，外层不动 | PASS |
| MIX-002 / MIX-004~008 | 需外层可读判定 | a11y 树空（仅全屏根节点） | BLOCKED(outer-measurement-inconclusive) |

### B.2.4 发布字节回归（v1.70 包上重跑）

- LB/RB 拖拽三档：**71 / 246 / 1597px**（判据 150 / 450 / 1200–2200），期间 `SWIPE=0 / WHEEL=0`。
- 滚轮模式 RB 1.5s：**WHEEL=9 / SWIPE=0**。
- P 六点（控制通道）：`402,1202` `1997,300` `104,104` `2445,1496` `1284,804` `700,999`，最大 err **3px**。
- X+LB **+1260** / X+RB **−1260**；`?` 自检 CAP 13/13。
- 23 项冒烟：L3 / 满推 / 横推 / 隐藏首推 / Y+上·下 / 6 项不得回退 / SELECT / 横屏守护 / 60s CPU —— 结果见 `work/docs/evidence-v170/verify_v170_smoke.result.txt`；
  其中 RS3-V / RS4-HIDDEN 的“外层 PY”判据受 padtest v1.4 内层 `vList` 抢手势影响，改用 `vertical_offset` + `touch.path_px` + helper `Z` 复测（同 v1.69 口径）。

## B.3 全量 142 行执行结果（t72 采样，未变）

| 指标 | 值 |
|---|---|
| PASS / FAIL / BLOCKED | **37 / 5 / 100** |
| P0（56） | **41.1%**（23 PASS / 4 FAIL / 29 BLOCKED） |
| P1（84） | 16.7% |
| P2（2） | 0% |
| 门槛 | **未达**；按 `V169-FINAL-VERIFY.md` 的 `Maintainer override: captain, 2026-11-27` 偏差发布 |
| 产品缺陷 | **`product FAIL = 0`**（5 条 FAIL 均为测量口径/页面初始态/padtest 导出实现） |

## B.4 本轮发布清单（t65/t66/t71/t72）

| 任务 | 结论 | 关键证据 |
|---|---|---|
| **t65** | padtest 真实滚轮支持（`ACTION_SCROLL`/`AXIS_VSCROLL` 路径 + 纵向/横向计数） | `work/docs/REVIEW-v170.md`；`evidence-v169/t71-wheel-getevent.txt` |
| **t66** | 助手控制通道拖拽产品级化（共享页拖拽状态、分块 `drag_move`、auto-up、`ERR_ARG`/`ERR_STATE`） | `work/docs/HELPER-v169.md` §6/§7；`evidence-v169/t66-protocol-replies.txt`、`t66-compare-swipe.txt` |
| **t71** | padtest 滚轮计数 0→2→4（a11y 不可读时的替代证据） | `evidence-v169/t71-wheel-app-count.txt` |
| **t72** | 复验：滚轮投递 PASS、内容位移 BLOCKED、ctl 拖拽 PASS（voff 5→7 / 7→12）、MIX-001/003 PASS；全量 37/5/100 | `work/docs/V169-FINAL3.md`；`evidence-v169/t72_all.out` |
| **t68** | 审查 t65/t66/t67：VERDICT=pass（R1: S 8 只算投递；R2: 计数用 PadMetrics；R3: 发布清单纳入三元组） | `work/docs/REVIEW-v170.md` |

## B.5 已知限制（与 v1.69 一致，新增两条）

1. **滚轮内容位移不可自动判定**（`wheel-content-displacement-unmeasurable`）：前台无滚动内容或 a11y 树退化时读不到 offset；
   投递链（WHEEL 计数 + PadProbe）才是可判定的部分。
2. **padtest 未升 v1.5**：v1.5 未交付，滚轮在测试台的可测性受限已回退；发布绑定 **v1.4 `0f4a9191`**，因此滚轮内容位移保持 BLOCKED 而不是伪 PASS。
3. padtest v1.4 内层 `vList` 会接住竖推（外层 PY 不动），必须用 `vertical_offset`/`touch.path_px` 判定。
4. `ctl-channel-drag-not-delivered` 32 条（经 App 通道的 d/m/e 在测试台侧收不到）仍为 BLOCKED；控制通道（`gpmctl`）路径已验证。

## B.6 用词约束（发布文档适用）

禁止：“通过”“全过”“门槛通过”“全部 PASS”。统一三句：
「`product FAIL = 0`（37 PASS / 5 FAIL / 100 BLOCKED）」、「发布门槛未达（P0 41.1% / P1 16.7%），经维护者批准按偏差发布」、「自动化上限 40–45/142，其余以已知限制 + 真机抽样覆盖，不虚报 PASS」。
