# V169-HARNESS3 · root 控制通道接入与 MIX 定位（t49）

> 字节：app `3ea7f324…` / helper `a88c544a…` / padtest 1.2；设备 2560×1600 横屏
> 套件：`work/scripts/v169_suite.sh`（新增 `ctl`/`ptr_to`）
> 原始输出：`work/docs/evidence-v169/t_mix2.out`、`t_rpt2.out`、`t_log2.out`、`t_btn2.out`（设备 `/data/local/tmp/v169_*.log`）

## 0 结论

- **root 控制通道打通**：`gpmctl /data/adb/gpm/gpmctl.sock 'P …'` → `POSPTR … err≤2px`，`'c'` 回读 `CURSOR 1282 1511`，**引擎运行中即可用**（无需停引擎）。
- **MIX-009 定位完成（结论 c）**：右摇杆横向**不驱动** `HorizontalScrollView`；正确路径是 **指针 P 到分页区 + 水平滚轮 `H n`**。手动实测 `H 8` → `scrollX 0→512`（≥400，PASS 口径成立）。套件内该条仍 FAIL 是因为 dump（停引擎→拉起）后窗口锚点未稳定，10s 内 H 被吞；属测试台时序，非产品回归。
- 覆盖率：**≈38/142**（未达 ≥90）。MIX 主体仍 BLOCKED：垂直滚轮在 padtest 不滚动（`WHEEL ±8` 实测 item/offset 均不变）、拖拽锚点不随指针（引擎固定锚点），因此“内层/外层归属”类用例缺少可控的纵向滚动通道。

## 1 通道验证（可复跑）

```sh
G=/data/local/tmp/gpmctl; S=/data/adb/gpm/gpmctl.sock
$G $S 'j'
$G $S 'P 900 640 2560 1600'   # → POSPTR 900,640 closed gain=2.15,2.14 final=901,642 err=-1,-2
$G $S 'c'                      # → CURSOR 901 642 display=0 space=logical
$G $S 'P 1280 1509 2560 1600'  # → final=1282,1511 err=-2,-2
$G $S 'H 8'                    # → WHEEL 8 h=1（横向滚轮）
```

三次落点误差：(-1,-2) / (0,0) / (-2,-1)，均 ≤2px。

## 2 MIX-009/010 结论（逐条）

| 项 | 实测 | 判定 |
|---|---|---|
| MIX-009 手动（pad → P(1280,1509) → `H 8`） | **scrollX 0→512**，外层 PY 1415 不变 | **PASS（判定口径成立）** |
| MIX-009 套件内 | P 落点 1282,1511 正确，但 `H 8` 后 scrollX 0→0 | FAIL（时序：dump 重启引擎后 H 被吞） |
| MIX-010 | P(1280,1509) → `WHEEL -8` → scrollX 不变 | PASS |

**根因结论（三选一）**：
- (a) 指针未悬停分页区 → **否**：`c` 回读 1282,1511 在分页区；
- (b) 右摇杆横向未驱动 HorizontalScrollView → **是**（`stick 3 ±30000` 后 scrollX 仍 0，PadProbe 无横向滚动事件）；
- (c) 该用组合键/横向滚轮 → **是**：水平滚轮 `H n` 即 `WHEEL n h=1`，P 到位后 scrollX 0→512。

## 3 本轮修复（5 条 harness FAIL）

| ID | 结果 | 说明 |
|---|---|---|
| RPT-001 | PASS | 报告页控件（开始/结束/导出）在 dump 中可见 |
| RPT-004 | PASS | JSON 导出 `auto-report-latest.json` 409B（`/sdcard/Android/data/com.dennis.padtest/files/`） |
| RPT-002 | FAIL | `开始测试` 点击后 `结束测试` 结果行仍为 0；改用 JSON 内 results 数（下一轮） |
| RPT-003 | FAIL | TXT 未导出（JSON 已存在），判定为 padtest 导出实现/路径差异，非手柄链路 |
| LOG-003 | PASS | 清空后 rows=0 |
| LOG-001 | FAIL | LogActivity 首屏无事件时无文本行；事件后 dump 才有（“共 8 条”），用例顺序需先注入 |
| BTN-001 | FAIL | force-stop 后 `am start ButtonDetailActivity` 未到前台（dump 仍是上一页），需 focus 断言+重试 |

## 4 仍 BLOCKED（原因具体化）

| 类别 | 条数 | 具体原因 |
|---|---|---|
| MIX-001~008（内/外层归属） | 8 | 垂直滚轮在 padtest 不滚动（实测 item/offset 不变）；拖拽锚点由引擎固定、不随指针 → 无“可控纵向滚动”通道 |
| MIX-011~024（分页/AxisLock） | 14 | 分页需连续横向手势；AxisLock 需坐标级**触摸**（vgpad 无 touch，helper 拖拽锚点固定） |
| MIX-025~029（左右列表/固定区） | 5 | padtest v1.2 的 `left_offset/right_offset/fixed_area_scrolls` 需经 ExportReceiver 读，且左右列表在后续页（需滚动定位） |
| MIX-030~034（浮层/页面切换） | 5 | 需 UI 点击浮层并保持滚动状态 |
| SCR-017/022 | 2 | 同 MIX 分页/悬停；helper-eng 已有 SCR-017 结论可引用 |
| SCR-009/010/012/013 | 4 | 按压中改 prefs：release 无 DebugReceiver（debug 探索待 t43） |
| UI 二级（CFG/BTN/LOG/RPT 其余） | 49 | SeekBar/选择器/输入法/对话框，需逐控件 UI 脚本 |
| 长压测/DeX/多窗口/真手柄 | 15 | 环境类，见 t39 §4 |

## 5 证据

- 通道：`work/docs/evidence-v169/t_mix2.out`（P 回读行）、设备 `helper.log` 的 `POSPTR`/`CURSOR`/`WHEEL 8 h=1`
- 分组：`t_rpt2.out`、`t_log2.out`、`t_btn2.out`
- 设备侧完整：`/data/local/tmp/v169_evidence/20261127-0051xx/`、`/data/local/tmp/v169_20261127-*.log`

## 6 给 t43/captain 的判断

- **≥90/142 在当前产品与测试台上不可达**：MIX 的纵向归属类需要“指针锚定的纵向滚动”或“坐标级触摸”，两者现有能力都不具备（垂直滚轮不滚动 padtest；拖拽锚点固定）。
- 可稳定自动化的上限约 **45~55 条**（ENV 5 + SCR 22 + E2E 6 + PERF 2 + MIX 2 + LOG 2 + RPT 2 + 其余零散）。
- 若要继续提升，建议按优先级：(1) 修 padtest 垂直滚轮支持/加 ScrollView 的 wheel 处理；(2) 给 vgpad 加坐标级 touch（或 helper 支持 `D x y` 锚点指定）；(3) 再铺 MIX 全量。
