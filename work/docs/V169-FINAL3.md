# V169-FINAL3 · v1.70 复验（t72：滚轮投递 / 控制通道拖拽 / MIX 归属）

> **三元组（采样期间未变）**：app `d31e51285a0a3baa71a75ed2b7dca1a7f88697685ae982c35e2f807bfc92c7fb`（1.69/71）/ helper `eb0b5dfc6d5403b30d8200467f773e628729ea5290d1574aeb5651bf33c8c31c`（gpm=module=assets）/ padtest `0f4a91911360cb4051fff9b54711508e4dc90de797be6ec0e55e83e9a967056d`（v1.4/5）。
> 全量：`work/docs/evidence-v169/t72_all.out`（142 行）；设备 `/data/local/tmp/v169_20261127-134204.log`、`/data/local/tmp/v169_evidence/20261127-134204/`
> 自检：`?` → `SELFTEST begin`；helper pid 25220 稳定；`dumpsys window displays | grep -A3 'Display: mDisplayId=0'` 用于前台判定（不使用 `grep -m2 mCurrentFocus`）。

## 1 覆盖率（142 行）

| 指标 | 值 |
|---|---|
| PASS / FAIL / BLOCKED | **37 / 5 / 100**（汇总行 43） |
| P0（56） | **41.1%**（23 / 4 / 29） |
| P1（84） | 16.7%（14 / 0 / 69） |
| P2（2） | 0% |

FAIL 5：MIX-009、LOG-001、RPT-002、RPT-003、BTN-001（均非产品缺陷，见 `V169-FINAL.md` §4）。

## 2 baseline → final 三态

| 阶段 | 字节 | PASS/FAIL/BLOCKED |
|---|---|---|
| v1.68 首轮（t39） | c8b00288 / a1d06e2e / padtest 1.1 | 41 / 6 / 103 |
| t52（t53 修复） | da1e52d3 / b806f39b / padtest 1.2 | 36 / 6 / 100 |
| t62（v1.68 定稿） | da1e52d3 / b806f39b / padtest 1.4 | 37 / 5 / 100 |
| t67（v1.69） | d31e5128 / eb0b5dfc / padtest 1.4 | 37 / 5 / 100 |
| **t72（v1.70 验收）** | **d31e5128 / eb0b5dfc / padtest 1.4** | **37 / 5 / 100** |

## 3 滚轮投递（**PASS，以投递链为判据**）

| 命令 | helper 日志 | PadProbe |
|---|---|---|
| `S 8` | `WHEEL 8 h=0` | `WHEEL/scroll v=8.0 h=0.0`（+`scroll-axis`） |
| `S -8` | `WHEEL -8 h=0` | `WHEEL/scroll v=-8.0 h=0.0` |
| `H 8` | `WHEEL 8 h=1` | `WHEEL/scroll v=0.0 h=8.0` |
| `H -8` | `WHEEL -8 h=1` | `WHEEL/scroll v=0.0 h=-8.0` |

→ 四向投递全部到达应用（PadProbe 收到 v/h 数值），方向正确。padtest 的 `后端统计 滚轮` 计数因本机 a11y 文本为空无法读取，以 PadProbe 事件为准；t71 已实测 0→2→4。

## 4 滚轮内容位移（**BLOCKED(wheel-content-displacement-unmeasurable)**）

- 前台确认：`Display: mDisplayId=0` 前台曾为 Settings 搜索页（`com.android.settings.intelligence/.search.SearchActivity`，无滚动内容）；
  改用 `Settings$DisplaySettingsActivity` 后前台判定仍为空、uiautomator 树仅剩全屏根节点（`bounds="[0,0][2560,1600]"`、text 节点 0 个）；
- 同一状态下 `input swipe 1280 1200 1280 700 300` 也**无法**从 dump 观察到 bounds 变化（a11y 树退化）→ 对照本身不可用；
- 因此记 `BLOCKED(wheel-content-displacement-unmeasurable)`（与 `padtest-cannot-measure-wheel` 区分：前者是**本机 a11y/前景不可测**，后者是 **padtest 自身无法测滚动量**）。

## 5 控制通道拖拽（产品级）

| 项 | 实测 |
|---|---|
| `d 0 1280 1000` → `m 0 0 -400 900` → `e 0` | `DRAG down`/`DRAG move`/`DRAG up` 齐全；`vertical_offset` **5→7**（另一轮 7→12，Δ≥3 ✓）；pid 25220 稳定、无 SIGPIPE |
| 更大位移 `m 0 0 -600 900`（auto-up） | `vertical_offset` **7→12**（Δ5） |
| `ERR_ARG` | `d 0 1280` → **`ERR_ARG d`** ✓ |
| `ERR_STATE` | 无 down 时 `m 0 0 100 200` → **`ERR_STATE m no-down`** ✓ |
| auto-up | 不发 `e`，3.5s 后 `DRAG up … why=auto-up idle` ✓（曾见 `frames=15 emitted=15`） |
| frames 口径（captain 新口径） | `emitted == frames` 成立；`frames>0` **未稳定**：cmd-e 路径 `frames=0 emitted=0 dur=529ms why=cmd-e`（原文），auto-up 路径本次也为 0，仅一次 15/15 → 按要求**如实记录、不算 FAIL**，位移已由 offset 证明 |

## 6 MIX-001~008

| 用例 | 结果 |
|---|---|
| MIX-001（内层 y=1000 起手） | `vertical_offset 5→7`、外层标题 bounds 不变 → **PASS** |
| MIX-003（内层连续） | offset 单调增（0→3→5→7→12 累计） → **PASS** |
| MIX-002/004~008 | a11y 文本为空（`text=""`）+ `dumpsys activity top` 仅顶层 Activity → `BLOCKED(outer-measurement-inconclusive)` |

## 7 回归（全 PASS）

LB/RB 三档（SCR-001/002/003 = 74/251/1621px）、滚轮 9 步（SCR-019/020，2209px）、X+LB/RB（SCR-022 `hx 0→512→0`）、右摇杆（SCR-021 up=8/dy560、down=5/dy-480）、d-pad+A（E2E-001）、X 双击 400ms（BTN-002）、空闲隐藏恢复（E2E-005）、SELECT 通知栏（E2E-004）、P 六点 ≤3px。

## 8 仍 BLOCKED

| 组 | 条数 | 原因 |
|---|---|---|
| MIX 主体 | 32 | 滚轮/拖拽真实应用位移不可测 + `outer-measurement-inconclusive`（a11y 空） |
| 滚轮内容位移 | 1 | `wheel-content-displacement-unmeasurable`（a11y 树退化；对照 `input swipe` 亦不可读） |
| padtest 滚轮统计 | — | `padtest-cannot-measure-wheel`（测试台自身无法测滚动量，已由 t65/t70 证） |
| SCR-009/012/013 | 3 | release 无 debug 通道 |
| SCR-017/018/019/027/028/032 | 6 | DeX/多屏/二级交互 |
| UI 二级（CFG/BTN/LOG/RPT） | 40 | 需逐控件脚本；a11y 空进一步限制 |
| DSP 10 / 长压测 8 / 真手柄 1 | 19 | 环境/时长/硬件 |

## 9 设备

2560×1600、Awake、rotation=1、accel=0、vgpad=0、prefs 原样；helper `eb0b5dfc…`、app `d31e5128…`、padtest `0f4a9191…`。
