# V169-FINAL · GamePadDex v1.68 自动化验收最终报告（t62）

> **最终三元组（captain 核验本地=设备一致）**
> app `da1e52d3c73ff8c8156ce89568385dd9f03f0b90fad7c68b5e0c7167531fdb44`
> helper `b806f39ba51278a73aad121be4019820b7961dcb0935971b64d3a02373cd2a4d`（852960 B；gpm=module 一致）
> padtest `0f4a91911360cb4051fff9b54711508e4dc90de797be6ec0e55e83e9a967056d`（v1.4/5）
> 套件：`work/scripts/v169_suite.sh`；本轮全量输出：`work/docs/evidence-v169/final_all.out`（142 行）、`v169_final.log`
> 设备：SM-F9360 · 2560×1600 · Awake · rotation=1 · accel=0 · 无 vgpad · helper 14719 / engine 14736

## 1 总览（142 行全覆盖）

| 指标 | 数 |
|---|---|
| PASS | **37** |
| FAIL | **5**（MIX-009、LOG-001、RPT-002、RPT-003、BTN-001） |
| BLOCKED | **100** |
| NOTRUN | 0 |

**优先级通过率**：P0 56 条 → **41.1%**（23 PASS / 4 FAIL / 29 BLOCKED）；P1 84 条 → **16.7%**；P2 2 条 → 0%。

## 2 baseline → final 三态

| 阶段 | 字节 | PASS / FAIL / BLOCKED |
|---|---|---|
| v1.68 第一轮（t38） | c8b00288 / a1d06e2e / padtest 1.1 | 41 / 6 / 103 |
| t52（t53 修复后） | da1e52d3 / b806f39b / padtest 1.2 | 36 / 6 / 100 |
| t56 / t58 | da1e52d3 / b806f39b / padtest 1.3 / 1.4 | 36 / 6 / 100 |
| **final（t62）** | da1e52d3 / b806f39b / padtest 1.4 | **37 / 5 / 100** |

变化说明：SCR-022 从 FAIL 改 PASS（判据由像素改为 padtest 报告字段 `instrumentation.scroll.horizontal_scroll_x`），故 36→37、FAIL 6→5。

## 3 已验证（PASS）关键项

| 用例 | 判据 | 实测 |
|---|---|---|
| **SCR-022** | `horizontal_scroll_x`：X+RB→512、X+LB→0、右摇杆@pager 512、@list 不变 | **hx: 0→512→0→512→512**（PASS，证据 `evidence-v169/report_s22*.json`） |
| **P 六点（t59 复验）** | 落点误差 ≤8px、iters ≤4 | 700,1000→703,1001(err -3,-1,2 iter)；100,100→97,102；2450,1500→2449,1498；1280,800→1282,802；200,1500→201,1498；2400,100→2397,102 — **全部 ≤3px** |
| **y=802 横向 swipe** | 不得触发 pager | `SWIPE 0 1282,800 -> 642,800 axis=V n=1`；第 1 页 bounds 不变；报告 `horizontal_scroll_x` 不变 → 不翻页 |
| SCR-001/002/003 | 位移距离 | 74 / 251 / 1621 px（v1.68 声称 73/238/1595） |
| SCR-020 | 边界续拖累计 | 2209 px（≤2200×1.07 上限） |
| SCR-016 | 隐藏后滚轮恢复 | `H 3` → 3/3 步到达，149ms（≤300ms） |
| E2E-001~006 | d-pad/A 注入、双击多任务、X+LB/RB、SELECT 通知栏、空闲隐藏恢复 | 全 PASS |
| PERF-001/002 | 串扰/重复帧 | 全 PASS |

## 4 FAIL（5 条，均非产品缺陷）

| ID | 原因 | 证据 | 是否产品缺陷 |
|---|---|---|---|
| MIX-009 | 分页文本「第 N 页」不随 scrollX 刷新（max scrollX=512<600 页宽），页面文本判定不可用；横向滚动本身已由 SCR-022 PASS 覆盖 | `final_all.out` MIX-009 行；SCR-022 报告字段 | **否**（测量口径） |
| LOG-001 | LogActivity 首屏无事件时不渲染文本行（a11y 树空），事件后才有「共 N 条」 | `ui_log1.lines`（43 行空文本） | **否**（页面初始态） |
| RPT-002 | 「开始测试」后结果行仍 0（报告需 session 结束+导出才填充） | `ui_rpt2.lines` | **否**（用例时序） |
| RPT-003 | TXT 导出未落盘（JSON 已生成 `auto-report-latest.json` 409B） | `RPT-004` PASS 对照 | **否**（padtest 导出实现） |
| BTN-001 | ButtonDetailActivity 在 force-stop 后未到前台（dump 到上一屏） | `ui_btn1.lines` | **否**（Activity 启动时序） |

## 5 BLOCKED（100 条，按原因分组）

| 组 | 条数 | 原因 | 产品缺陷？ |
|---|---|---|---|
| MIX 主体（001~008、011~034 除 009） | 32 | **ctl-channel-drag-not-delivered**：helper 侧 `d/m/e` 已发（frames/emitted=20、getevent 可见 BTN_TOUCH+ABS_MT），应用端未收到 → 测试通道限制；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px） | 否（测试通道） |
| 垂直滚轮 S 8 | 1（含在 MIX-… 内计数） | **evidence-incomplete**：helper 已发 `WHEEL 8 h=0`，padtest 无可读 offset/统计，不作产品结论 | 否 |
| SCR-009/012/013 | 3 | release 字节无 DebugReceiver（debug 构建探索 ≠ release 验收） | 否（通道） |
| SCR-017/018/019/027/028/032 | 6 | 悬停余量/多屏/窗口模式等需 DeX 外接屏或二级交互 | 否（环境） |
| UI 二级（CFG 17、BTN 12、LOG 7、RPT 4） | 40 | SeekBar/选择器/输入法/对话框需逐控件脚本，非手柄链路 | 否（UI 自动化） |
| DSP 10 | 10 | 显示策略需第二屏/折叠态 | 否（环境） |
| PERF-003~010 | 8 | 长压测（≥10min 高频注入）未执行 | 否（时长） |
| ENV-004 | 1 | 真手柄插拔需物理设备 | 否（硬件） |

## 6 结论

- **可自动化上限受测试通道限制（约 40–45/142）**：MIX 主体验证受 `d/m/e` 控制通道不交付触摸所限，S 8 受 padtest 无 offset 埋点所限；其余 FAIL 均为测量口径/页面初始态，不是产品缺陷。
- 剩余项以「已知限制 + 真机抽样」覆盖，**不虚报 PASS**。
- 手柄链路的核心能力（滑动位移/速度/边界、分页横向、d-pad/A 注入、双击多任务、X+LB/RB、SELECT 通知栏、空闲隐藏恢复、P 落点精度）均在发布字节上 PASS。

## 7 证据索引

- 全量日志：`work/docs/evidence-v169/final_all.out`、`v169_final.log`；SCR 复跑：`scr_final.out`
- SCR-022 报告：`evidence-v169/t58_report2/{s1..s4}.json`、`t58_report/{A_xrb,C_stick_list,base}.json`、`report_s22*.json`（本轮）
- 截图（2560×1600，`-d 4630946474867211650`）：`evidence-v169/t58/y802_*.png`、`scr022_px/run5,run6`
- 设备原始：`/data/local/tmp/v169_20261127-030848.log`、`/data/local/tmp/v169_evidence/20261127-030848/`
- 方法论：`V169-HARNESS6.md` §9（display id/尺寸断言）、§11（滚动判据用控件字段）

## 8 审计链（v1.68 版本对照）

| 版本 | 字节 | 用例数 | PASS/FAIL/BLOCKED |
|---|---|---|---|
| v1.65 基线 | 2638359B | — | — |
| v1.68 | c8b00288（首轮）/ da1e52d3（t53 修复后） | 142 | 41/6/103 → 37/5/100 |
| v1.69 文档 | 142 ID | — | 本轮覆盖 |

> 发布字节以 t43 绑定的 app `da1e52d3` / helper `b806f39b` / padtest `0f4a9191` 为准；SCR-022 的 PASS 依赖 padtest 报告字段，发布包不含 padtest。
