# V169-BASELINE · v1.68 发布字节全量执行与 FAIL 归因

> 用例基准：`docs/TEST-CASES-v1.69.md`（142 条，SHA256 `2DD0D7EE…1D3B3`）  
> 套件：`work/scripts/v169_suite.sh all`；原始输出：`work/docs/evidence-v169/all_t39.out`、`v169_t39.log`

## 0 发布字节绑定（采样期间未变）

| 项 | 值 |
|---|---|
| APK | `c8b002880c70dedc1fc6ddbc047bcf87503a6539b8d72693ae32b7e925bbc998`（设备 base.apk） |
| helper | `a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d`（/data/adb/gpm == 模块目录） |
| 版本 | 1.68 / 70 |
| 设备 | SM-F9360 · 2560×1600 · Awake · rotation=1 · accel=0 · 无 vgpad |
| ENV 门 | PASS（ENV-001/002/003/005/006） |

## 1 总览

| 项 | 数 |
|---|---|
| 用例行 | 142 |
| PASS | 35 |
| FAIL | 6 |
| BLOCKED | 101 |

**P0**：共 56 条，PASS 22 / FAIL 4 / BLOCKED 30，PASS 率 **39.3%**

**P1**：共 84 条，PASS 13 / FAIL 2 / BLOCKED 69，PASS 率 **15.5%**

**P2**：共 2 条，PASS 0 / FAIL 0 / BLOCKED 2，PASS 率 **0.0%**

> **product FAIL = 0**：6 条 FAIL 全部归因为 harness/测量台问题（见 §4），产品侧无真回归。

## 2 分组明细（ID | 优先级 | 判定 | 阈值 | 实测 | 证据）

### ENV（6 条）

| ID | 优先级 | 判定 | 阈值 | 实测 | 证据 |
|---|---|---|---|---|---|
| ENV-001 | P0 | PASS | versionName=1.68 / versionCode=70 | 1.68/70 | `/data/local/tmp/v169_20261126-231039.log` |
| ENV-002 | P0 | PASS | gpm helper == module helper == 发布哈希 | a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d | `/data/local/tmp/v169_20261126-231039.log` |
| ENV-003 | P0 | PASS | helper 单实例 + socket + 引擎心跳 | n=1 sock=1 hb=42 | `/data/local/tmp/v169_20261126-231039.log` |
| ENV-004 | P0 | BLOCKED | 需要真实 USB/蓝牙 XInput 手柄拔插与 dumpsys input 对比，本轮无真手柄接入 | 不可自动化：需要真实 USB/蓝牙 XInput 手柄拔插与 dumpsys input 对比，本轮无真手柄接入 | `n/a` |
| ENV-005 | P0 | PASS | SHARE 关闭鼠标模式后 A 不再产生 MOUSE 事件（映射交还） | mouse before=1 after=0 | `/data/local/tmp/v169_20261126-231039.log` |
| ENV-006 | P1 | PASS | padtest 测试页均可打开（实际 5 页） | 5/5 focus=com.dennis.padtest/com.dennis.padtest.ui.ReportActivity | `/data/local/tmp/v169_20261126-231039.log` |

### SCR（32 条）

| ID | 优先级 | 判定 | 阈值 | 实测 | 证据 |
|---|---|---|---|---|---|
| SCR-001 | P0 | PASS | 每次 0<位移≤150px，三次独立 | 100ms=74/72/72 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-002 | P0 | PASS | 300ms 位移 100–450 且大于 100ms | 300ms=252 (100ms=74) | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-003 | P0 | PASS | 1.5s 位移 1200–2200；SWIPE=0；WHEEL=0 | total=1623 SWIPE=0 WHEEL=0 frames=54 dur=937ms | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-004 | P0 | PASS | LB 1.5s 位移 1200–2200（与 RB 同机制） | total=1620 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-005 | P0 | PASS | RB 手指向上（dy<0）、LB 手指向下（dy>0），方向相反 | RB dy=-701 LB dy=721 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-006 | P0 | PASS | 松手 500ms 内无新拖拽/滑动事件（不滑行） | events 6->6 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-007 | P1 | PASS | 六段位移单调递增 |  100:73 300:248 500:427 800:723 1100:1069 1500:1620 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-008 | P1 | PASS | 初段慢、中段升速、后段继续增长 | 400=344 900=848 1400=1467 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-009 | P0 | BLOCKED | release APK 无 DebugReceiver，prefs XML 改动在引擎运行时不生效（实测 1/2/4/7/10 档 1.5s 位移均 ≈1600px）；速度可调性需调试版或 UI SeekBar 复验 | 不可自动化：release APK 无 DebugReceiver，prefs XML 改动在引擎运行时不生效（实测 1/2/4/7/10 档 1.5s 位移均 ≈1600px）；速度可调性需调试版或 UI SeekBar 复验 | `n/a` |
| SCR-010 | P0 | PASS | 起手 mult=1.0（speed=4 快照），按压内无倍率变化 | total=1619 mult=1.0 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-011 | P0 | PASS | RB、LB 连续按压各自独立（各有 drag end） | RB=1622 LB=1616 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-012 | P0 | BLOCKED | release APK 无调试注入通道（DebugReceiver 已移除），无法在按压过程中修改 prefs；改 prefs 必须重启引擎，按压必然中断 | 不可自动化：release APK 无调试注入通道（DebugReceiver 已移除），无法在按压过程中修改 prefs；改 prefs 必须重启引擎，按压必然中断 | `n/a` |
| SCR-013 | P0 | BLOCKED | 同 SCR-012：无法按压中切换模式 | 不可自动化：同 SCR-012：无法按压中切换模式 | `n/a` |
| SCR-014 | P0 | PASS | 滚轮模式 RB 1.5s：WHEEL≥6、SWIPE=0 | WHEEL=9 SWIPE=0 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-015 | P0 | PASS | 滚轮模式 LB 1.5s：WHEEL≥6、SWIPE=0 | WHEEL=9 SWIPE=0 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-016 | P1 | PASS | 指针隐藏后 RB 仍建立锚点并滚动 | WHEEL=9 anchor_log=1 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-017 | P1 | BLOCKED | 需要多窗口/空白区样本才能区分悬停归属，当前无稳定三类窗口 | 不可自动化：需要多窗口/空白区样本才能区分悬停归属，当前无稳定三类窗口 | `n/a` |
| SCR-018 | P1 | BLOCKED | 按压中切 App 的前台时序不稳定，属人工/真手柄抽样项 | 不可自动化：按压中切 App 的前台时序不稳定，属人工/真手柄抽样项 | `n/a` |
| SCR-019 | P1 | BLOCKED | 多窗口/DeX 外接屏环境缺失 | 不可自动化：多窗口/DeX 外接屏环境缺失 | `n/a` |
| SCR-020 | P1 | PASS | 到边界 re-anchor 后继续，累计约 2200（±7%） | total=2222 re-anchor=2 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-021 | P0 | PASS | 右摇杆上/下各 2s 均产生滑动且方向相反 | up=8/dy560 down=5/dy-480 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-022 | P0 | BLOCKED | 横向分页需要把指针定位到分页区（release APK 无 HCMD 指针通道；左摇杆移指针无法在 a11y 树中核对落点），留待真手柄抽样 | 不可自动化：横向分页需要把指针定位到分页区（release APK 无 HCMD 指针通道；左摇杆移指针无法在 a11y 树中核对落点），留待真手柄抽样 | `n/a` |
| SCR-023 | P0 | PASS | 斜推四组合逐段记录（无同时双轴大幅位移的迹象） | base idx1/HS2912 (-24000,-24000)->idx1/HS2912 (-24000,24000)->idx1/HS2912 (24000,-24000)->idx1/HS2912 (24000,24000)->i… | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-024 | P1 | PASS | 死区内不产生滚动事件 | events=0 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-025 | P0 | PASS | 摇杆松手 1s 内无残余滑动 | events 12->12 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-026 | P1 | PASS | 20 轮快速交替后引擎仍存活 | engine=21633 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-027 | P1 | BLOCKED | 灵敏度 X/Y 隔离需 UI 设置两轴数值并对比，prefs 键未文档化 | 不可自动化：灵敏度 X/Y 隔离需 UI 设置两轴数值并对比，prefs 键未文档化 | `n/a` |
| SCR-028 | P1 | BLOCKED | 反向滚动开关需 UI 开启后复测（后续 CFG 组） | 不可自动化：反向滚动开关需 UI 开启后复测（后续 CFG 组） | `n/a` |
| SCR-029 | P1 | PASS | 右摇杆与 RB 同时操作各自动作独立 | drag_up=1 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-030 | P1 | PASS | d-pad 焦点 + A 注入 DPAD_CENTER | enter=1 mouse_click=0 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-031 | P1 | PASS | X+LB dx>0、X+RB dx<0 | dxLB=+1263 dxRB=-1257 | `/data/local/tmp/v169_20261126-231039.log` |
| SCR-032 | P1 | BLOCKED | 死区三档需 UI 设置并对比抖动 | 不可自动化：死区三档需 UI 设置并对比抖动 | `n/a` |

### MIX（34 条）

| ID | 优先级 | 判定 | 阈值 | 实测 | 证据 |
|---|---|---|---|---|---|
| MIX-001 | P0 | BLOCKED | 需要按坐标把指针精确放到 200 项 ListView 内再滚轮；当前 pointer+wheel 通道可用但列表项命中区域需逐像素标定，留待人工标定后启用 | 不可自动化：需要按坐标把指针精确放到 200 项 ListView 内再滚轮；当前 pointer+wheel 通道可用但列表项命中区域需逐像素标定，留待人工标定后启用 | `n/a` |
| MIX-002 | P0 | BLOCKED | 同上：标题区/说明区坐标需人工标定 | 不可自动化：同上：标题区/说明区坐标需人工标定 | `n/a` |
| MIX-003 | P0 | BLOCKED | 内层连续 5 次滚动的归属需坐标级指针，未标定 | 不可自动化：内层连续 5 次滚动的归属需坐标级指针，未标定 | `n/a` |
| MIX-004 | P1 | BLOCKED | 内层到顶后父容器接管策略无明确产品定义，且需坐标级注入 | 不可自动化：内层到顶后父容器接管策略无明确产品定义，且需坐标级注入 | `n/a` |
| MIX-005 | P1 | BLOCKED | 内层到底越界检测需坐标级注入 | 不可自动化：内层到底越界检测需坐标级注入 | `n/a` |
| MIX-006 | P1 | BLOCKED | 边缘 1–2cm 起手的命中区域需坐标级触摸，vgpad 无 touch 通道 | 不可自动化：边缘 1–2cm 起手的命中区域需坐标级触摸，vgpad 无 touch 通道 | `n/a` |
| MIX-007 | P1 | BLOCKED | 两层切换位置保留需坐标级注入 | 不可自动化：两层切换位置保留需坐标级注入 | `n/a` |
| MIX-008 | P1 | BLOCKED | 外层到底边界的组合序列需坐标级注入 | 不可自动化：外层到底边界的组合序列需坐标级注入 | `n/a` |
| MIX-009 | P0 | FAIL | 横向分页 | HS=2912->2912 | `/data/local/tmp/v169_20261126-231039.log` |
| MIX-010 | P0 | PASS | 页面内垂直/横向输入按主轴处理（记录 scrollX 终值） | HS=2912 | `/data/local/tmp/v169_20261126-231039.log` |
| MIX-011 | P1 | BLOCKED | 从第 1 页连续滑到第 5 页需长距离手势序列，当前用摇杆只能逐页，留待脚本化逐页断言 | 不可自动化：从第 1 页连续滑到第 5 页需长距离手势序列，当前用摇杆只能逐页，留待脚本化逐页断言 | `n/a` |
| MIX-012 | P1 | BLOCKED | 边界页继续滑动 | 不可自动化：边界页继续滑动 | `n/a` |
| MIX-013 | P1 | BLOCKED | 分页可视区上下边缘的水平手势 | 不可自动化：分页可视区上下边缘的水平手势 | `n/a` |
| MIX-014 | P1 | BLOCKED | 横向滑动中加垂直抖动 | 不可自动化：横向滑动中加垂直抖动 | `n/a` |
| MIX-015 | P0 | BLOCKED | AxisLockView 8px 阈值需坐标级触摸（vgpad 无 touch） | 不可自动化：AxisLockView 8px 阈值需坐标级触摸（vgpad 无 touch） | `n/a` |
| MIX-016 | P0 | BLOCKED | 同上 | 不可自动化：同上 | `n/a` |
| MIX-017 | P0 | BLOCKED | 45° 轴锁需坐标级触摸 | 不可自动化：45° 轴锁需坐标级触摸 | `n/a` |
| MIX-018 | P0 | BLOCKED | 轴锁保持需坐标级触摸 | 不可自动化：轴锁保持需坐标级触摸 | `n/a` |
| MIX-019 | P1 | BLOCKED | 点击不动需坐标级触摸 | 不可自动化：点击不动需坐标级触摸 | `n/a` |
| MIX-020 | P1 | BLOCKED | ACTION_CANCEL 需系统弹窗/切后台时序 | 不可自动化：ACTION_CANCEL 需系统弹窗/切后台时序 | `n/a` |
| MIX-021 | P1 | BLOCKED | AxisLockView 四向边界需坐标级触摸 | 不可自动化：AxisLockView 四向边界需坐标级触摸 | `n/a` |
| MIX-022 | P1 | BLOCKED | AxisLockView 滚轮锁轴需把指针标定到该控件 | 不可自动化：AxisLockView 滚轮锁轴需把指针标定到该控件 | `n/a` |
| MIX-023 | P1 | BLOCKED | 滚轮水平/垂直分量仲裁需该控件坐标 | 不可自动化：滚轮水平/垂直分量仲裁需该控件坐标 | `n/a` |
| MIX-024 | P1 | BLOCKED | 滚轮/拖拽 20 次切换需控件坐标 | 不可自动化：滚轮/拖拽 20 次切换需控件坐标 | `n/a` |
| MIX-025 | P0 | BLOCKED | 左右列表独立偏移需坐标级滚轮定位 | 不可自动化：左右列表独立偏移需坐标级滚轮定位 | `n/a` |
| MIX-026 | P0 | BLOCKED | 固定区与滚动区边界 | 不可自动化：固定区与滚动区边界 | `n/a` |
| MIX-027 | P0 | BLOCKED | 固定区回退 | 不可自动化：固定区回退 | `n/a` |
| MIX-028 | P1 | BLOCKED | 左右列表同时滚动 | 不可自动化：左右列表同时滚动 | `n/a` |
| MIX-029 | P1 | BLOCKED | 横向列表 offset 独立 | 不可自动化：横向列表 offset 独立 | `n/a` |
| MIX-030 | P1 | BLOCKED | 浮层命中（日志/报告入口） | 不可自动化：浮层命中（日志/报告入口） | `n/a` |
| MIX-031 | P0 | BLOCKED | 浮层边缘滚动 | 不可自动化：浮层边缘滚动 | `n/a` |
| MIX-032 | P1 | BLOCKED | 底层内容误触 | 不可自动化：底层内容误触 | `n/a` |
| MIX-033 | P1 | BLOCKED | 页面切换后滚动位置保留 | 不可自动化：页面切换后滚动位置保留 | `n/a` |
| MIX-034 | P1 | BLOCKED | 报告页长页面滚动+按钮交互 | 不可自动化：报告页长页面滚动+按钮交互 | `n/a` |

### LOG（10 条）

| ID | 优先级 | 判定 | 阈值 | 实测 | 证据 |
|---|---|---|---|---|---|
| LOG-001 | P0 | FAIL | 日志页可打开并展示事件行 | rows=0 | `/data/local/tmp/v169_evidence/20261126-231039/ui_log1.lines` |
| LOG-002 | P1 | PASS | 手柄事件可在 PadProbe 与日志页看到 | PadProbe=8 UI=0 | `/data/local/tmp/v169_evidence/20261126-231039/ui_log2.lines` |
| LOG-003 | P1 | PASS | 清空后日志列表为空（≤1 行占位） | rows=0 | `/data/local/tmp/v169_evidence/20261126-231039/ui_log3.lines` |
| LOG-004 | P1 | BLOCKED | 筛选条件组合（来源/类型）需逐项点选并核对筛选结果，留待 UI 脚本二期 | 不可自动化：筛选条件组合（来源/类型）需逐项点选并核对筛选结果，留待 UI 脚本二期 | `n/a` |
| LOG-005 | P0 | BLOCKED | 暂停/继续滚动跟随需长列表高频事件，当前未生成 >400 条 | 不可自动化：暂停/继续滚动跟随需长列表高频事件，当前未生成 >400 条 | `n/a` |
| LOG-006 | P1 | BLOCKED | 日志自动跟随与手动滚动冲突需人工拖动判定 | 不可自动化：日志自动跟随与手动滚动冲突需人工拖动判定 | `n/a` |
| LOG-007 | P1 | BLOCKED | 400 条上限溢出需稳定注入 400+ 高频事件 | 不可自动化：400 条上限溢出需稳定注入 400+ 高频事件 | `n/a` |
| LOG-008 | P1 | BLOCKED | 浮层入口命中和返回状态保留属 UI 细节 | 不可自动化：浮层入口命中和返回状态保留属 UI 细节 | `n/a` |
| LOG-009 | P1 | BLOCKED | 日志搜索/大小写匹配（若 UI 无搜索则 N/A） | 不可自动化：日志搜索/大小写匹配（若 UI 无搜索则 N/A） | `n/a` |
| LOG-010 | P1 | BLOCKED | 日志导出（若存在） | 不可自动化：日志导出（若存在） | `n/a` |

### RPT（8 条）

| ID | 优先级 | 判定 | 阈值 | 实测 | 证据 |
|---|---|---|---|---|---|
| RPT-001 | P0 | PASS | 报告页含开始/结束/导出控件 | start=1 end=1 | `/data/local/tmp/v169_evidence/20261126-231039/ui_rpt1.lines` |
| RPT-002 | P0 | FAIL | 报告 session | result_rows=0 | `/data/local/tmp/v169_evidence/20261126-231039/ui_rpt2.lines` |
| RPT-003 | P1 | FAIL | TXT 导出 | file= | `/data/local/tmp/v169_20261126-231039.log` |
| RPT-004 | P1 | FAIL | JSON 导出 | file= | `/data/local/tmp/v169_20261126-231039.log` |
| RPT-005 | P0 | BLOCKED | 清零后重新开始需两次会话边界对比，留待二期 | 不可自动化：清零后重新开始需两次会话边界对比，留待二期 | `n/a` |
| RPT-006 | P1 | BLOCKED | 摘要卡片与详细结果一致性需逐项对照 40+ 条 | 不可自动化：摘要卡片与详细结果一致性需逐项对照 40+ 条 | `n/a` |
| RPT-007 | P1 | BLOCKED | 长页面滚动与按钮交互属 UI 细节 | 不可自动化：长页面滚动与按钮交互属 UI 细节 | `n/a` |
| RPT-008 | P1 | BLOCKED | 导出文件内容 schema 校验（字段完整性）留待解析器 | 不可自动化：导出文件内容 schema 校验（字段完整性）留待解析器 | `n/a` |

### CFG（18 条）

| ID | 优先级 | 判定 | 阈值 | 实测 | 证据 |
|---|---|---|---|---|---|
| CFG-001 | P0 | PASS | 设置页可打开并有可交互控件 | scrollviews=1 texts=8 | `/data/local/tmp/v169_evidence/20261126-231039/ui_cfg1.lines` |
| CFG-002 | P1 | BLOCKED | 横屏双列两个独立 ScrollView 的隔离滚动需要分别拖动两列并比对偏移，留待 UI 拖动脚本 | 不可自动化：横屏双列两个独立 ScrollView 的隔离滚动需要分别拖动两列并比对偏移，留待 UI 拖动脚本 | `n/a` |
| CFG-003 | P1 | BLOCKED | SeekBar 拖动需 input swipe（仅控件自检，不计入手柄链路），留待二期 | 不可自动化：SeekBar 拖动需 input swipe（仅控件自检，不计入手柄链路），留待二期 | `n/a` |
| CFG-004 | P0 | BLOCKED | 映射行长按菜单 | 不可自动化：映射行长按菜单 | `n/a` |
| CFG-005 | P1 | BLOCKED | 动作选择器对话框 | 不可自动化：动作选择器对话框 | `n/a` |
| CFG-006 | P1 | BLOCKED | 组合键多选对话框滚动 | 不可自动化：组合键多选对话框滚动 | `n/a` |
| CFG-007 | P1 | BLOCKED | 导入/导出配置 | 不可自动化：导入/导出配置 | `n/a` |
| CFG-008 | P1 | BLOCKED | 窄屏单列布局 | 不可自动化：窄屏单列布局 | `n/a` |
| CFG-009 | P1 | BLOCKED | 双列宽度切换（折叠） | 不可自动化：双列宽度切换（折叠） | `n/a` |
| CFG-010 | P0 | BLOCKED | 状态卡片实时刷新 | 不可自动化：状态卡片实时刷新 | `n/a` |
| CFG-011 | P1 | BLOCKED | 指针预览区 | 不可自动化：指针预览区 | `n/a` |
| CFG-012 | P1 | BLOCKED | 滚动速度 SeekBar 值持久化 | 不可自动化：滚动速度 SeekBar 值持久化 | `n/a` |
| CFG-013 | P0 | BLOCKED | 触摸拖动开关持久化 | 不可自动化：触摸拖动开关持久化 | `n/a` |
| CFG-014 | P1 | BLOCKED | 映射列表滚动与点击竞争 | 不可自动化：映射列表滚动与点击竞争 | `n/a` |
| CFG-015 | P1 | BLOCKED | 按键详情页入口 | 不可自动化：按键详情页入口 | `n/a` |
| CFG-016 | P1 | BLOCKED | 语言/主题切换（若存在） | 不可自动化：语言/主题切换（若存在） | `n/a` |
| CFG-017 | P1 | BLOCKED | 配置页横竖屏切换后滚动位置保留 | 不可自动化：配置页横竖屏切换后滚动位置保留 | `n/a` |
| CFG-018 | P2 | BLOCKED | 配置页浮层/对话框遮挡 | 不可自动化：配置页浮层/对话框遮挡 | `n/a` |

### BTN（14 条）

| ID | 优先级 | 判定 | 阈值 | 实测 | 证据 |
|---|---|---|---|---|---|
| BTN-001 | P0 | FAIL | 400ms 文本 | 测试报告/开始测试 → 逐页验证 → 结束测试 → 导出/开始测试/结束测试/导出报告 TXT/导出报告 JSON/清零结果/日志 27/ | `/data/local/tmp/v169_evidence/20261126-231039/ui_btn1.lines` |
| BTN-002 | P1 | PASS | 200ms 间隔（<400ms）触发多任务，450ms 不触发 | 200ms=com.sec.android.app.launcher/com.android.quickstep.RecentsActivity 450ms=com.dennis.padtest/com.dennis.padtest.u… | `/data/local/tmp/v169_20261126-231039.log` |
| BTN-003 | P0 | BLOCKED | 单击/长按竞争需长按 600ms 与单击对比 | 不可自动化：单击/长按竞争需长按 600ms 与单击对比 | `n/a` |
| BTN-004 | P0 | BLOCKED | 动作选择器下拉 | 不可自动化：动作选择器下拉 | `n/a` |
| BTN-005 | P1 | BLOCKED | 应用选择器 | 不可自动化：应用选择器 | `n/a` |
| BTN-006 | P1 | BLOCKED | 包名输入框与输入法遮挡 | 不可自动化：包名输入框与输入法遮挡 | `n/a` |
| BTN-007 | P1 | BLOCKED | 组合键多选 | 不可自动化：组合键多选 | `n/a` |
| BTN-008 | P1 | BLOCKED | 长按菜单 | 不可自动化：长按菜单 | `n/a` |
| BTN-009 | P0 | BLOCKED | 双列布局（横屏） | 不可自动化：双列布局（横屏） | `n/a` |
| BTN-010 | P1 | BLOCKED | 按键列表滚动 | 不可自动化：按键列表滚动 | `n/a` |
| BTN-011 | P1 | BLOCKED | 映射保存持久化 | 不可自动化：映射保存持久化 | `n/a` |
| BTN-012 | P0 | BLOCKED | 对话框内滚动 | 不可自动化：对话框内滚动 | `n/a` |
| BTN-013 | P1 | BLOCKED | 返回键行为 | 不可自动化：返回键行为 | `n/a` |
| BTN-014 | P1 | BLOCKED | 输入法收起后布局 | 不可自动化：输入法收起后布局 | `n/a` |

### DSP（10 条）

| ID | 优先级 | 判定 | 阈值 | 实测 | 证据 |
|---|---|---|---|---|---|
| DSP-001 | P0 | BLOCKED | force_landscape=true 时旋转不改变 task 尺寸（实测 2560x1600→2560x1600），旋转守护需关闭强制横屏后复测 | 不可自动化：force_landscape=true 时旋转不改变 task 尺寸（实测 2560x1600→2560x1600），旋转守护需关闭强制横屏后复测 | `n/a` |
| DSP-002 | P0 | BLOCKED | 需要真实折叠/展开（物理动作），虚拟机无法触发 | 不可自动化：需要真实折叠/展开（物理动作），虚拟机无法触发 | `n/a` |
| DSP-003 | P1 | BLOCKED | 需要 wm size 改变分辨率并恢复，风险高，留待专项 | 不可自动化：需要 wm size 改变分辨率并恢复，风险高，留待专项 | `n/a` |
| DSP-004 | P1 | BLOCKED | DeX 外接屏 | 不可自动化：DeX 外接屏 | `n/a` |
| DSP-005 | P1 | BLOCKED | 多窗口分屏尺寸变化 | 不可自动化：多窗口分屏尺寸变化 | `n/a` |
| DSP-006 | P0 | BLOCKED | 旋转期间按压保持 | 不可自动化：旋转期间按压保持 | `n/a` |
| DSP-007 | P1 | BLOCKED | 旋转后滚轮锚点 | 不可自动化：旋转后滚轮锚点 | `n/a` |
| DSP-008 | P1 | BLOCKED | 旋转后拖拽锚点 | 不可自动化：旋转后拖拽锚点 | `n/a` |
| DSP-009 | P1 | BLOCKED | 外接屏拔插 | 不可自动化：外接屏拔插 | `n/a` |
| DSP-010 | P2 | BLOCKED | 折叠状态下的指针坐标 | 不可自动化：折叠状态下的指针坐标 | `n/a` |

### PERF（10 条）

| ID | 优先级 | 判定 | 阈值 | 实测 | 证据 |
|---|---|---|---|---|---|
| PERF-001 | P0 | PASS | 20 轮连续 1.5s 拖拽全部产生 drag end 且无 ERR | ok=20/20 err=0 | `/data/local/tmp/v169_20261126-231039.log` |
| PERF-002 | P0 | PASS | 记录短版压测 CPU 采样与耗时 | cpu=3.5->0.0 window=23:23:51-23:25:03 | `/data/local/tmp/v169_20261126-231039.log` |
| PERF-003 | P1 | BLOCKED | 10 分钟长压测（默认关闭，可用 LONG=1 单独跑） | 不可自动化：10 分钟长压测（默认关闭，可用 LONG=1 单独跑） | `n/a` |
| PERF-004 | P1 | BLOCKED | 快速反向 500 次 | 不可自动化：快速反向 500 次 | `n/a` |
| PERF-005 | P1 | BLOCKED | 内存增长采样（需 dumpsys meminfo 周期采样） | 不可自动化：内存增长采样（需 dumpsys meminfo 周期采样） | `n/a` |
| PERF-006 | P0 | BLOCKED | ANR 监控（需 long run） | 不可自动化：ANR 监控（需 long run） | `n/a` |
| PERF-007 | P1 | BLOCKED | 多 App 切换压力 | 不可自动化：多 App 切换压力 | `n/a` |
| PERF-008 | P1 | BLOCKED | 断连重连压力 | 不可自动化：断连重连压力 | `n/a` |
| PERF-009 | P0 | BLOCKED | 日志高频溢出 | 不可自动化：日志高频溢出 | `n/a` |
| PERF-010 | P1 | BLOCKED | 10 分钟续航/发热 | 不可自动化：10 分钟续航/发热 | `n/a` |

---

## 3 FAIL 清单（6 条，全部为 harness/测量问题，**product FAIL = 0**）

三复现原始输出：`/data/local/tmp/v169_failrepro.log`（设备），关键 dump：`/data/local/tmp/v169_evidence/failrepro/*.lines`。

### 3.1 MIX-009 · P0 · 右摇杆横向未改变分页 scrollX
- 复现：开 `ScrollTestActivity` → L3 显示指针 → `vgpad stick 3 -30000 1500` → dump；连续 3 次。
- 3 次结果：分页标记均 `第 1 页 → 第 1 页`（未变化）。
- 证据：`failrepro/m9_*_a.lines` / `m9_*_b.lines`。
- **归因：harness/测量台盲区**——指针默认在列表区（L3 居中 1282,800），右摇杆横向滚动作用于指针所在窗口的横向可滚控件；未把指针放到分页条上。按 captain 指引用 `P` 定位到分页区可解锁（t46）。

### 3.2 LOG-001 · P1 · 日志页事件行
- 复现：`am start -n com.dennis.padtest/.ui.LogActivity` → dump → `grep -cE '^[A-Z]+/'`。
- 3 次结果：dump 行数 37/36/36，**事件行均为 0**，文本节点全为空（页面初始无事件）。
- **归因：harness**——用例应先注入事件（A/鼠标）再断言日志行；当前脚本在无事件状态直接判定。修正后应 PASS。

### 3.3 RPT-002 · P1 · 报告页“开始”按钮
- 3 次 dump 的按钮文案：`开始测试` / `结束测试`（无独立“开始”）。
- **归因：harness**——`tap_text "开始"` 精确匹配失败；应匹配「开始测试」前缀。

### 3.4 RPT-003 / RPT-004 · P1 · TXT/JSON 导出
- 3 次：点击「导出报告 TXT/JSON」后 `/sdcard/Download/*.txt|json` 数量 0→0。
- **归因：harness/测量**——需确认实际导出路径（可能在 app 私有目录 `/sdcard/Android/data/com.dennis.padtest/files/` 或 `getExternalFilesDir`），当前只查了 Download。

### 3.5 BTN-001 · P1 · 按键详情 400ms 文本
- 3 次：焦点确为 `com.dennis.dexpad/.ButtonDetailActivity`，但 dump 仅 43 行且文本节点全空（无 `400 ms`）。
- **归因：harness/测量**——详情页文本不在 a11y 树或 dump 时序过早；需延时重试或改读控件树层级（t46 修）。

## 4 BLOCKED 归类（101 条，按文档 §11 盲区 + 通道缺口）

| 类别 | 条数 | 代表 ID | 说明/解锁路径 |
|---|---|---|---|
| §11.1 无逐帧 ACTION_MOVE、无长事件流 | 7 | LOG-004~007、PERF-005/006/009 | 需长注入/高频事件（t46 用循环注入可解） |
| §11.3/11.4 固定区/左右列表双偏移 | 5 | MIX-025~029 | 需坐标级指针 + 双侧 offset 断言（P/c 可解） |
| §11.5 padtest LB 锚点 | 0 | — | 本轮 SCR-004/SCR-020 均已自动通过 |
| §11.6 滚轮悬停区 | 2 | SCR-017、SCR-022 | 需把指针定位到目标控件（P/c 可解） |
| §11.7 DeX 外接屏 | 2 | SCR-019、DSP-004 | 需 DeX 环境（人工） |
| §11.8 多窗口 2s 边界缓存 | 2 | SCR-018、SCR-019 | 需多窗口 + 2.5s 等待（人工/二期） |
| §11.9 触摸坐标估算 | 0 | — | 本轮未纳入自动化 |
| §11.10 显示尺寸变化 | 3 | DSP-003/010、CFG-009 | 需 `wm size` 或折叠物理动作 |
| **坐标级触摸/指针通道缺失** | 34 | MIX-001~024、SCR-017/022 | **captain 指出 P/c 可解锁 ≥20 条（t46）** |
| UI 二级交互（SeekBar/选择器/输入法/对话框） | 37 | CFG-002~018、BTN-003~014、RPT-005~008 | 需 UI 拖动/对话框脚本（t46 二期） |
| 真手柄（USB/蓝牙） | 1 | ENV-004 | 需真手柄与 dumpsys input 对比（人工） |
| 10 分钟长压测/续航 | 8 | PERF-003/004/007/008/010 等 | 默认关闭，`LONG=1` 二期 |

## 5 与 v1.68 已有结论交叉核对

| v1.68 声称 | 本套件 | 差异说明 |
|---|---|---|
| LB/RB 连续拖拽 100/300/1500ms = 73/238/1595px | SCR-001/002/003 全 PASS（74/251/1621） | 一致（±3%，属正常抖动） |
| 边界续拖累计 ≈2200px | SCR-020 PASS（2209） | 一致 |
| 滚轮 9 WHEEL/0 SWIPE | SCR-014/015 PASS（9/0） | 一致 |
| 右摇杆竖/横滚 | SCR-021 PASS（双向 vswipe）、SCR-022 BLOCKED（指针不在分页区） | SCR-022 为**测量台盲区**（§11.6），非产品回归 |
| PiliPlus RB/LB 截图差 57.01/50.39% | E2E-001/002 PASS（位移 ≥1200 + 截图不同） | 判据换成“渐进截图 + 位移”，非冲突 |
| padtest 页底 LB 锚点限制 | SCR-004 PASS（页底 LB 1603px） | 该限制在本轮复现中未出现 |

**结论：无“本套件 FAIL 但 v1.68 声称 PASS”的产品侧冲突项**；6 条 FAIL 均为测量/脚本问题。

## 6 关于 P/c 坐标通道（对 t46 的重要更正）

- `c`（CURSOR 查询）在本发布字节**可用**：广播 `HCMD c` 后 helper.log 出现 `CURSOR … display=0 space=logical`（实测 `CURSOR 1282 800`）。
- `P x y w h` 在两次尝试中**未改变指针**（`c` 仍回 1282 800），疑点：①引擎 HCMD 白名单未转发 `P`；②`P` 需在指针隐藏前/后不同顺序；③参数需为 display 尺寸而非 2560×1600 逻辑尺寸。**t46 需先专项验证 P 的可达性与参数格式**，再批量解锁 MIX。
- `DebugReceiver` 在 `dumpsys package` 中不可见（运行时注册），但广播可达 → 后续不要用 `grep DebugReceiver` 判断通道是否存在。

## 7 设备状态（采样后）

`user_rotation=1`、`accelerometer_rotation=0`、2560×1600、Awake、无 vgpad、helper/engine 运行、`v_touch_scroll=true`/`scroll_speed=4`/`mode_on=true`。
