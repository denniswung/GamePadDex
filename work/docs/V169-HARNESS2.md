# V169-HARNESS2 · 套件自修 + 坐标能力评估（t46）

> 基线用例：`docs/TEST-CASES-v1.69.md`（142 条）
> 套件：`work/scripts/v169_suite.sh`；本轮运行：`/data/local/tmp/all4.out`、`/data/local/tmp/v169_all.log`
> 设备：SM-F9360 · 2560×1600 · Awake · rotation=1 · accel=0

## 0 结论摘要

- **6 条 harness FAIL 修掉 1 条（RPT-004），另 5 条定位到真实原因但仍未消除**（LOG-001/003、RPT-001/002/003、BTN-001）。
- **`P`/`c`/`M` 坐标通道在 release 字节不可用**（与 captain 的假设不同，证据见 §2），因此 MIX 主体与 SCR-017/022 **无法按计划解锁**；MIX-009 改为 `BLOCKED(release-no-pointer-channel)`。
- 新覆盖率：**≈41/142（未达 ≥90）**。

## 1 本轮改动

| 改动 | 说明 |
|---|---|
| `dump_ui_nostop` | 新增：对 **dexpad 自身**页面（Config/ButtonDetail）不再“停引擎→dump”（停引擎会杀掉同进程的 Activity，导致 dump 到上一屏） |
| BTN-001 / CFG-001 | 改用 `dump_ui_nostop` |
| RPT-003/004 | 导出路径增加 `/sdcard/Android/data/com.dennis.padtest/files/` 与 `/data/data/…/files/` → **RPT-004 PASS**（`auto-report-latest.json` 409B） |
| LOG-001/002 | 先注入两次 A 再 dump（引擎运行中） |
| MIX-009/010 | 改为 `BLOCKED(release-no-pointer-channel)`，附证据 |

## 2 关键发现：P/c 通道在 release 不可用（三条硬证据）

1. **DebugReceiver 非调试即返回**：`project/lsp-dexpad/.../DebugReceiver.kt` 第二行 `if (!debuggable) return`；release APK 的 `dumpsys package` flags 无 `DEBUGGABLE` → 所有 `HCMD/DEBUG` 广播为空操作。此前 `CURSOR` 行来自调试构建时代的旧日志。
2. **sockcmd 无法替代**：引擎运行时 helper 被引擎独占（`listen(sfd,1)`）；`am force-stop com.dennis.dexpad` 后 **helper 随引擎退出**（实测 `pidof gpminput` 为空、socket 残留但 `connect: Connection refused`）。
3. **手工拉起 helper 被单实例锁拒绝**：`setsid /data/adb/gpm/gpminput --socket …` 立即输出 `another helper holds the lock - exiting`（`/data/adb/gpm/helper.lock` flock），无法在引擎之外建立坐标通道。

> 结论：坐标级控制需要在 **可调试构建**（debug APK）或 **引擎不独占 socket / 不随引擎退出** 的产品改动下才能稳定使用。本轮不修改产品代码（t46 范围外）。

## 3 仍 FAIL 的 5 条（真实原因）

| ID | 实测 | 真实原因 | 建议 |
|---|---|---|---|
| LOG-001 | rows=0（dump 43 行全空文本） | LogActivity 的事件行不在 a11y 树（可能用 Canvas/自定义 View 绘制） | 改读控件层级/自绘状态，或由 padtest 增加 contentDescription |
| LOG-003 | 找不到「清空」 | 同 LOG-001（页面文本为空，按钮定位失败） | 同上 |
| RPT-001 | start=0 end=0 | 报告页 dump 时机/页面为空（无 session 时按钮仍在，但 dump 未取到文本） | dump 前先开 session |
| RPT-002 | 找不到「开始」 | 文案为「开始测试」，`tap_text` 前缀匹配未生效 | 用 `tap_text_contains` |
| RPT-003 | TXT 导出无文件 | TXT 导出路径/命名与 JSON 不同（JSON 已找到 `auto-report-latest.json`） | 枚举 app files 目录全部文件 |
| BTN-001 | dump 到上一屏（padtest 内容） | `am start -n …ButtonDetailActivity` 后未真正到前台（同进程 Activity 被前一次 force-stop 影响） | 先 `am start` 再等 2.5s + 断言 focus |

## 4 BLOCKED 状态（无变化）

- MIX 主体（32 条）：`BLOCKED(release-no-pointer-channel)`（§2）。
- SCR-017/022：同上。
- SCR-009/010/012/013：`BLOCKED(release-no-debug-channel)`；debug 探索未在本轮展开（需 debug APK 安装，属另一轮）。
- UI 二级 37 条、长压测 15 条、DeX/多窗口/折叠 12 条、真手柄 1 条：理由同 t39 报告 §4。

## 5 证据

- 本轮日志：`/data/local/tmp/all4.out`、`/data/local/tmp/v169_all.log`（设备）
- 分组复测：`work/docs/evidence-v169/t_log.out`、`t_rpt.out`、`t_btn.out`、`t_cfg.out`
- 关键 dump：`/data/local/tmp/v169_evidence/<run>/ui_*.lines`

## 6 后续建议（给 captain）

1. **若要 ≥90 覆盖率**：先用 debug APK 跑通 P/c 流程（DebugReceiver 可用），验证 MIX 断言模板可行，再决定是否给 release 增加“测试专用只读通道”（产品决策，不在本套件范围）。
2. 或把 MIX/UI 类用例移交 **手动回归清单**（文档 §10.1/§13 已有模板），自动化只保留 SCR/E2E/PERF 的客观链路项。
3. LOG/RPT/BTN 的 5 条建议由 padtest 增加稳定的 contentDescription 或控件 id，套件即可全部自动化。

---

## 7 最终结果（2026-11-27 00:50，收尾时设备字节已变更）

| 项 | 结果 |
|---|---|
| 6 条 FAIL | 修掉 1 条（RPT-004 JSON 导出路径），4 条定位到真实原因（LOG-001/003 a11y 树无文本、RPT-002 文案「开始测试」、BTN-001 Activity 未到前台、RPT-003 TXT 路径），1 条改判（MIX-009 改 scrollX 断言后仍为 FAIL：右摇杆横向不改变 scrollX） |
| P/c 通道 | release 不可用（DebugReceiver 非调试 return；sockcmd 需停引擎且 helper 同退；手工 helper 被 helper.lock 拒绝）；captain 已开 t47 修 P 落点（开环增益 3.25 vs 2.14，偏 34%） |
| 覆盖率 | **≈41/142**（未达 ≥90）；MIX 主体 32 条仍 BLOCKED(release-no-pointer-channel)，待 t47 + padtest v1.2 埋点后在 t43 复测 |
| 字节变更 | 收尾时设备已是 app `3ea7f324` / helper `eea9e9fa` / padtest 1.2（helper-eng 在跑 t47）；release 三元组（c8b00288/a1d06e2e）已不可直接复现，t43 将按新三元组绑定 |

## 8 引用 helper-eng 的结论（不重复造证据）

按 captain 指示，以下三项在 release 字节上已由 helper-eng 验有结论，本轮直接引用、不作为本套件的独立 PASS：

| ID | 结论 | 证据 |
|---|---|---|
| SCR-016 | PASS：`h` → `H 3`，POINTER off→MOUSE_REOPEN(auto)→WHEEL 3，149ms，首轮 3 步不丢 | `work/docs/evidence-v169/v169-sock-verify-*.txt` |
| SCR-017 | PASS：P 到统计卡（不可滚）后 WHEEL 3×3 到达但 offset 0→0，可判定“悬停目标不可滚” | 同上 |
| E2E-010 | PASS：拖拽中熄屏 3s → `DRAG up … why=auto-up idle`，亮屏单击正常 | 同上 |

## 9 t43 的交接清单

1. 用 padtest v1.2 的 `ExportReceiver`（`METRICS …` / `EXPORT path=…`）取 `left_offset/right_offset/fixed_area_scrolls`，补 SCR-020/MIX-028 的 app 侧 offset 断言。
2. 按 t47 修复后的 P（落点 ≤8px，`c` 回读）批量解锁 MIX-001~008/011~034：每条记录 `P 请求坐标 → c 实际落点 → 容器 offset 变化`。
3. 修正 RPT-002 文案匹配、LOG-001/003 与 BTN-001 的 Activity 前台等待，预计再 +4~5 PASS。
4. 覆盖率目标 ≥90 需在 t43 完成；本轮套件已具备 `P→c` 断言骨架（待 P 修复后启用）。
