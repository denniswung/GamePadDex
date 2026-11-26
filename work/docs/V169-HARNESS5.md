# V169-HARNESS5 · 最终三元组全量 + SCR-022 复测（t52 预交付）

> 三元组：app `da1e52d3c73ff8c8156ce89568385dd9f03f0b90fad7c68b5e0c7167531fdb44` / helper `b806f39ba51278a73aad121be4019820b7961dcb0935971b64d3a02373cd2a4d` / padtest 1.2 `8febba47…`
> 全量输出：`work/docs/evidence-v169/all5_final.out`、`v169_all5.log`；设备原始：`/data/local/tmp/v169_20261127-012053.log`
> 通道自检：`?` → `SELFTEST begin … SELFTEST end`，`CTL connected uid=0`，helper pid 7594→18522（中途多次重启）

## 0 全量结果（142 行全覆盖）

| 项 | 数 |
|---|---|
| PASS | **36**（汇总行 42，含重复计数） |
| FAIL | **6**：SCR-022、MIX-009、LOG-001、RPT-002、RPT-003、BTN-001 |
| BLOCKED | **100** |
| NOTRUN | 0 |

分组：ENV 5/0/1、SCR 22/1/9、MIX 1/1/32、LOG 2/1/7、RPT 2/2/4、CFG 1/0/17、BTN 1/1/12、E2E 6/0/2、DSP 0/0/10、PERF 2/0/8。

## 1 SCR-022 复测（t53 修复后）——**新发现：padtest 1.2 分页不响应注入 swipe**

| 步骤 | 结果 |
|---|---|
| `?` 自检 / helper pid | `SELFTEST begin`；pid 18522 |
| HSV 节点 bounds | `[36,1415][2524,1600]` → 中心 (1280,1507) |
| `P(1280,1507)` → `c` | `CURSOR 1282 1509`（在分页区内） |
| 右摇杆横向 2s | `scrollX 0→0`；`hswipe dir=1 nx=-0.907 anchor=1282,1509 hidden=false`（**anchor 已跟随指针，t53 生效**） |
| X+RB（基准） | `scrollX 0→0`（**同一坐标、同一命令，t50 在 padtest 1.1 上为 0→512**） |

**结论**：t53 的锚点同步已生效（hswipe anchor 与 P 目标一致，±2px）；但 **padtest 1.2 的 5 页 HorizontalScrollView 对注入式横向 swipe 不再响应**（与 t50/padtest 1.1 的 0→512 对照）。属 **测试台回归**，不是产品回归。
→ SCR-022 应在 padtest 1.1 或真实 App（PiliPlus 横向轮播）上复测；padtest 1.2 上记 `BLOCKED(testbed-pager-no-injected-swipe)`。

## 2 d/m/e detached drag（helper b806f39b）

- 三条独立连接 `d`/`m`/`e` 在本轮 **未产生 DRAG 日志**（`grep -ac DRAG`=0，命令输出为空）；helper pid 在此期间多次变化（7594→10535→5931→18522）。
- 与 captain 报的 “frames=20 emitted=20” 不一致，**判定为环境/连接问题，不出结论**；需在 pid 稳定时重测。
- 内层 offset≥300 的判定改用：`列表项 #00N` 首项序号变化 + `DRAG up frames/emitted`；本轮未取得。

## 3 垂直滚轮（`S n`）三项证据

- 本轮未取得干净样本（命令发送时 helper 连续重启，`WHEEL` 行与 PadProbe wheel 均为 0）。
- 固定顺序（t52 执行）：`?` → `CTL connected uid=0` → `S 8` → 查 helper.log `WHEEL 8 h=0` + PadProbe wheel + padtest offset；缺一项记 `BLOCKED(helper-restarted-during-test)`。

## 4 仍 BLOCKED（100）

- MIX 主体 32：内层/外层归属需 d/m/e 帧（本轮未证实）+ padtest 1.2 分页不响应。
- SCR-009/012/013（release 无 debug 通道）、SCR-017/018/019/027/028/032 等。
- UI 二级（CFG 17、BTN 12、LOG 7、RPT 4）、DSP 10、PERF 8、ENV-004（真手柄）。

## 5 证据

- `work/docs/evidence-v169/all5_final.out`（142 行）、`v169_all5.log`
- 设备：`/data/local/tmp/v169_20261127-012053.log`、`/data/local/tmp/v169_evidence/20261127-012053/`
- SCR-022 复测：设备 `/data/local/tmp/v169_scr022.log`（含 hswipe 行与 HSV bounds）

## 6 给 captain 的两个即时结论

1. **SCR-022 不能在 padtest 1.2 上验收**：t53 锚点修复已生效（anchor=P 目标），但 padtest 1.2 分页不响应注入 swipe（同坐标 t50/padtest 1.1 为 512）。请在 PiliPlus 横向轮播或 padtest 1.1 上复测。
2. **d/m/e 本轮未能复现 t54 的 frames**：命令无 DRAG 日志（helper 多次重启）。需固定 helper 后重测；在此之前 MIX 主体保持 BLOCKED。
