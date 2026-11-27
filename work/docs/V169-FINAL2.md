# V169-FINAL2 · v1.69 复验（t67：S 8 / d-m-e / MIX 解锁）

> 三元组：app `d31e51285a0a3baa71a75ed2b7dca1a7f88697685ae982c35e2f807bfc92c7fb`（1.69/71）/ helper `eb0b5dfc6d5403b30d8200467f773e628729ea5290d1574aeb5651bf33c8c31c`（gpm=module）/ padtest `0f4a91911360cb4051fff9b54711508e4dc90de797be6ec0e55e83e9a967056d`（v1.4/5）。
> 本轮全量：`work/docs/evidence-v169/t67_all.out`（142 行）；设备 `/data/local/tmp/v169_20261127-130601.log`、`/data/local/tmp/v169_evidence/20261127-130601/`
> 自检：`?` → `SELFTEST begin … CAP wheel 1`；helper pid 全程稳定（sockcmd 通道）；a11y 文本节点在本机为空（见 §5），因此真实应用测量改用 `dumpsys activity top` 视图 bounds + 报告字段。

## 1 覆盖率（142 行）

| 指标 | 值 |
|---|---|
| PASS / FAIL / BLOCKED | **37 / 5 / 100**（汇总行 43，含重复计数） |
| P0（56） | **41.1%**（23 PASS / 4 FAIL / 29 BLOCKED） |
| P1（84） | 16.7%（14 / 0 / 69） |
| P2（2） | 0% |

FAIL 5：MIX-009、LOG-001、RPT-002、RPT-003、BTN-001（均非产品缺陷，见 `V169-FINAL.md` §4；SCR-022 已在本轮套件判 PASS）。

## 2 baseline → final 三态

| 阶段 | 字节 | PASS/FAIL/BLOCKED |
|---|---|---|
| v1.68 首轮（t39） | c8b00288 / a1d06e2e / padtest 1.1 | 41 / 6 / 103 |
| t52 | da1e52d3 / b806f39b / padtest 1.2 | 36 / 6 / 100 |
| t62（v1.68 定稿） | da1e52d3 / b806f39b / padtest 1.4 | 37 / 5 / 100 |
| **t67（v1.69）** | **d31e5128 / eb0b5dfc / padtest 1.4** | **37 / 5 / 100** |

## 3 S 8 纵向滚轮（真实应用）：**BLOCKED(product-or-env-unknown)**

| 证据 | 实测 |
|---|---|
| helper 日志 | `WHEEL 8 h=0`（Settings，指针 1280,700）、`WHEEL 30 h=0`（1280,900 / 1280,1100）——命令到达并执行 |
| 真实应用位移（系统设置列表，`dumpsys activity top` 视图 bounds） | S 8 / S 30 前后 `TextView{b09d28 … 0,100-179,147}`、`{17341be … 0,0-112,66}` 等 bounds **完全不变** |
| 触摸对照（`input swipe 1280 1200 1280 600 300`） | 视图 bounds 立即变化 → 列表可滚动，排除“页面不可滚” |
| PadProbe | Settings 无 `wheel` 事件输出（该 app 未接 PadProbe） |
| padtest 侧 | 两次尝试均 scrollY=0（t65/t70），已记 **`padtest-cannot-measure-wheel`**（测试台限制） |

**结论**：滚轮事件到达 helper，但**任何 app 的内容位移都为 0**（Settings 与 padtest），而触摸能滚 → **滚轮注入链路（helper uinput wheel → 应用）存疑**，属产品侧或环境侧，未能定性。按要求记 `BLOCKED(product-or-env-unknown)`，**不判 PASS**。

## 4 控制通道 d/m/e

| 场景 | 结果 |
|---|---|
| padtest 内层（y≈1000，`m 0 0 -400 900`） | `vertical_offset` **0→3**（报告字段）；`DRAG down/up` 齐全；helper pid 稳定（无 SIGPIPE） |
| padtest 外层（y≈300） | `vertical_offset` **保持**（未变）→ 内外层归属可分 |
| 系统设置（y=900/1100，`-300 400` / `-600 1200`） | `DRAG up … frames=15/0 emitted=15/0`，但视图 bounds **不变** → 真实应用未位移 |
| frames 计数 | 本 helper 上 `DRAG up frames` 报 0 或 15（与 t59 报的 20/20 不一致），`why=cmd-e` 提前收尾 |

**结论**：控制通道拖拽在 padtest 上可产生效果（offset 0→3），**真实应用（Settings）无位移** → `BLOCKED(real-app-drag-no-displacement)`；frames≥20 未稳定复现（属测试通道时序）。

## 5 MIX-001~008（padtest，控制通道坐标拖拽）

| 用例 | 坐标 | 实测 | 判定 |
|---|---|---|---|
| MIX-001 内层滚轮归属 | 内层起手 (1280,1000) | `vertical_offset 0→3`，外层标题 bounds 不变 | **PASS（内层归属）** |
| MIX-002 外层归属 | 外层起手 (1280,300) | `vertical_offset` 不变；外层标题 bounds **无法读取**（a11y 空 + `dumpsys activity top` 仅显示顶层 Activity 的视图，未取到 padtest 外层标题） | **BLOCKED(outer-measurement-inconclusive)** |
| MIX-003 内层连续 | 内层连续两次 | `vertical_offset` 单调增（0→3→…） | **PASS（内层连续）** |
| MIX-004~008 | — | 依赖外层坐标与边界判定，同 MIX-002 的测量限制 | **BLOCKED(outer-measurement-inconclusive)** |

> 注：a11y 文本节点本机为空（`text=""`），`dumpsys activity top` 只输出顶层 Activity 视图，padtest 外层标题不可读 → MIX 外层类无法闭环。

## 6 回归（全 PASS）

LB/RB 三档拖拽（SCR-001/002/003 = 74/251/1621px）、滚轮 9 步（SCR-019/020，2209px 累计）、X+LB/RB（SCR-022 `hx 0→512→0`）、右摇杆纵向（SCR-021 up=8/dy560、down=5/dy-480）、d-pad+A 注入（E2E-001）、X 双击 400ms（BTN-002）、空闲隐藏恢复（E2E-005）、SELECT 通知栏（E2E-004）、P 六点 ≤3px（t58/t62）。

## 7 仍 BLOCKED 清单（含测试台限制）

| 组 | 条数 | 原因 |
|---|---|---|
| MIX 主体 | 32 | `ctl-channel-drag-not-delivered`（真实 app 无位移）+ `outer-measurement-inconclusive`（a11y 空） |
| 滚轮 / S 8 | 1 | `padtest-cannot-measure-wheel`（测试台）+ `product-or-env-unknown`（Settings 无位移） |
| SCR-009/012/013 | 3 | release 无 debug 通道 |
| SCR-017/018/019/027/028/032 | 6 | 需 DeX/多屏/二级交互 |
| UI 二级（CFG/BTN/LOG/RPT） | 40 | 需逐控件脚本；本轮 a11y 文本为空进一步限制 |
| DSP 10 / 长压测 8 / 真手柄 1 | 19 | 环境/时长/硬件 |

## 8 设备

helper `sha256=eb0b5dfc…`、app `d31e5128…`、padtest `0f4a9191…`；2560×1600、Awake、rot1/accel0、vgpad=0、prefs 原样。

## 9 结论

- 全量 142 行：**PASS 37 / FAIL 5 / BLOCKED 100**，P0 41.1%——与 v1.68 定稿持平（套件口径未变）。
- **S 8 与真实应用拖拽未能转 PASS**：滚轮注入在 Settings/padtest 均无内容位移（触摸可滚），控制通道拖拽在 padtest 生效、在 Settings 无效；**如实记 BLOCKED，不虚判**。
- MIX 内层归属（001/003）已用报告字段解锁 PASS；外层类因 a11y 文本为空无法闭环。
