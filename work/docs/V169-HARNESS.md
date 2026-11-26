# V169-HARNESS · v1.69 测试计划一键自动化套件

> 基线用例：`docs/TEST-CASES-v1.69.md`（从 `E:\win\Downloads\GamePadDex_TEST_CASES_v1.69.md` 原文复制，SHA256 `2DD0D7EE…1D3B3`，142 条 ID：ENV 6 / SCR 32 / MIX 34 / LOG 10 / RPT 8 / CFG 18 / BTN 14 / DSP 10 / PERF 10）
> 套件：`work/scripts/v169_suite.sh`（设备端 `/data/local/tmp/v169_suite.sh`）
> 本轮基线：见 §6（`work/docs/V169-BASELINE.md` 存放逐条结果）

## 1 如何运行

```sh
# 推送
adb -s 192.168.10.36:6666 push work/scripts/v169_suite.sh /data/local/tmp/v169_suite.sh
# 单组（ENV 是基线门，必须先过）
adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/v169_suite.sh ENV"
adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/v169_suite.sh SCR"
# 全量
adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/v169_suite.sh all"
# 取回证据
adb -s 192.168.10.36:6666 pull /data/local/tmp/v169_<run>.log work/docs/evidence-v169/
adb -s 192.168.10.36:6666 pull /data/local/tmp/v169_evidence/<run> work/docs/evidence-v169/
```

- 输出行格式：`<ID> <PASS|FAIL|BLOCKED|NOTRUN> | 阈值: … | 实测: … | 证据: <路径>`
- 汇总行：`PASS=… FAIL=… BLOCKED=… NOTRUN=…`，并列出 `FAILED:` / `BLOCKED:`
- 基线门：`ENV` 组任一 FAIL → 打印 `BASELINE GATE` 并 `exit 9`（`all` 模式同样先跑 ENV，失败即停）
- 环境变量：`EXPECT_VERSION`（默认 1.68）、`EXPECT_CODE`（70）、`EXPECT_HELPER`（`a1d06e2e…`）；发布前按实际清单覆盖。

## 2 运行前置（每次必做）

1. 亮屏解锁、锁横屏：`input keyevent KEYCODE_WAKEUP; wm dismiss-keyguard; settings put system accelerometer_rotation 0; settings put system user_rotation 1; svc power stayon true`
2. 清通知栏：`cmd statusbar collapse`；套件每次启动 padtest 后也会清一次。
3. 确认引擎运行：`am start-foreground-service -n com.dennis.dexpad/.EngineService`；helper 单实例；`/data/data/com.dennis.dexpad/files/gpm.sock` 存在。
4. 无 vgpad 残留（`ps -A | grep -c vgpad` 应为 0；套件自己会拉起/结束 vgpad）。
5. **本轮 release APK（1.68/70）没有 `DebugReceiver`**（`dumpsys package | grep -c DebugReceiver` = 0）：
   - 所有 `am broadcast -a com.dennis.dexpad.DEBUG/HCMD …` 都是**空操作**；
   - 套件改 prefs 的方式是**直接改 `/data/misc/*/prefs/com.dennis.dexpad/dexpad.xml` + 重启引擎**（`set_vt`/`set_speed`），因此“按压过程中改 prefs”类用例（SCR-012/013）只能 BLOCKED。
6. padtest 实际只有 5 个页面（SelfCheck/Scroll/Cursor/Log/Report），文档写的 7 页与实际构建不符（ENV-006 按 5 页判定并在行内注明）。

## 3 仪器口径（写报告/复验必须遵守）

| 现象 | 处理 |
|---|---|
| 引擎指针 overlay 让 padtest 窗口**永不 idle**，`uiautomator dump` 报 `could not get idle state` | 套件 `dump_ui` 采用“**停引擎 → dump → 拉起引擎**”；停引擎后 dump 正常（≈13–15KB、含 5 个页面标记） |
| 应用侧把拖拽识别为 **MOUSE/drag**（不是 TOUCH） | grep 必须 `MOUSE/drag|TOUCH/swipe`；`TOUCH/drag` 不会出现 |
| `/dev/input/*` 在 shell 域不可读（`getevent`/`dd` 均 0 字节） | 帧间隔用 helper `DRAG up … frames/emitted/dur` 作代理（见 SCR-003 证据） |
| 拖拽**进行中** `screencap` 返回陈旧帧（实测差 0.01%） | 渐进性用“分次累计 + 段间截图”，不做按压中截图 |
| `adb shell input swipe` | 仅用于控件自检（如设置列表滚到中间），**不计入手柄链路通过**；套件内已标注“控件自检：非端到端” |

## 4 组内覆盖（自动 / BLOCKED）

### ENV（6）
- 自动：ENV-001 版本、ENV-002 三处 helper 哈希、ENV-003 helper 单实例+socket+心跳（`hb ready=` 日志）、ENV-005 SHARE 切换（vgpad 注入）、ENV-006 padtest 页面
- BLOCKED：ENV-004（需要真实 USB/蓝牙手柄拔插与 `dumpsys input` 对比）

### SCR（32）
- 自动：001–011、014–016、020、021、023–026、029–031（共 23）
- BLOCKED：012/013（按压中改 prefs：release APK 无调试通道，改 prefs 必须重启引擎）、017（三类窗口悬停样本）、018（按压中切 App 时序）、019（多窗口/DeX）、022（横向分页需指针定位到分页区，release 无 HCMD 指针通道）、027（灵敏度 X/Y 隔离需 UI）、028（反向滚动需 UI）、032（死区三档需 UI）
- 客观量：引擎 `drag end total`/`mult`、helper `SWIPE/WHEEL/DRAG up`、PadProbe `MOUSE/drag|TOUCH/swipe` 计时与位移

### MIX（34）
- 自动：MIX-009/010（右摇杆横向改变 scrollX）
- BLOCKED：其余 32 条 —— 需要**坐标级触摸/指针**通道（vgpad 只有 stick/key/hat/combo/double，release 无 HCMD 指针设定），或需要多窗口/DeX/浮层命中；详见套件内逐条 reason

### LOG（10）
- 自动：LOG-001 页面可开、LOG-002 手柄事件进日志、LOG-003 清空
- BLOCKED：004–010（筛选组合、暂停跟随、400 条溢出、搜索/导出等需长事件流或 UI 二期）

### RPT（8）
- 自动：RPT-001 控件、RPT-002 session、RPT-003 TXT 导出、RPT-004 JSON 导出
- BLOCKED：005–008（清零边界、摘要一致性、长页面、schema 校验）

### CFG（18）
- 自动：CFG-001 页面可开且有控件
- BLOCKED：002–018（双列独立滚动、SeekBar、映射行、选择器、导入导出等 UI 交互；需二期 UI 拖动脚本）

### BTN（14）
- 自动：BTN-001 400ms 文本、BTN-002 双击阈值行为（200ms 不触发 / 450ms 触发 Recents）
- BLOCKED：003–014（长按竞争、选择器、输入框、组合键、双列等）

### E2E（8）
- 自动：E2E-001 PiliPlus RB、E2E-002 PiliPlus LB、E2E-003 抖音 RB、E2E-004/005 设置滚轮 RB/LB、E2E-006 PiliPlus 右摇杆
- BLOCKED：E2E-007（抖音登录态/首屏）、E2E-008（多 App 锚点）

### DSP（10）
- 自动：DSP-001 旋转守护（旋转后引擎仍响应）
- BLOCKED：002–010（折叠/展开、wm size、DeX、多窗口、旋转中按压等）

### PERF（10）
- 自动：PERF-001 20 轮连续 1.5s 拖拽、PERF-002 CPU/耗时采样
- BLOCKED：003–010（10 分钟长压测、快速反向 500 次、meminfo 周期采样、ANR 监控等；可用 `LONG=1` 二期开启）

## 5 BLOCKED 汇总（按原因归类）

| 原因 | 涉及 |
|---|---|
| release APK 无调试注入通道（DebugReceiver 已移除），无法在按压中改 prefs/坐标 | SCR-012, SCR-013 |
| vgpad 无坐标级触摸通道、release 无 HCMD 指针设定 | MIX 全部（除 009/010）、SCR-017/022 |
| 需要多窗口 / DeX 外接屏 / 折叠屏物理动作 | SCR-019, DSP-002~010, MIX 部分 |
| 需要真实手柄（USB/蓝牙）与手感判定 | ENV-004 |
| 需要长事件流 / 10 分钟压测 / 周期采样 | LOG-004~010, PERF-003~010 |
| 需要 UI 二级交互（SeekBar/选择器/输入法） | CFG-002~018, BTN-003~014, RPT-005~008 |

## 6 基线结果（2026-11-26，142 行全覆盖）

见 `work/docs/V169-BASELINE.md` 与 `work/docs/evidence-v169/`（`all_final.out`、`v169_all_final.log`、`20261126-224334/`）。要点：
- **PASS=41 / FAIL=6 / BLOCKED=103 / NOTRUN=0**
- ENV 全过（1 BLOCKED：ENV-004）；套件可作发布门：ENV 失败即 `exit 9`
- FAIL 全部为 UI 文案/时序类基线问题（RPT-002/003/004、LOG-001、BTN-001）与一条 MIX-009（横分页需指针定位）
- BLOCKED 原因分布见 BASELINE §4（坐标级注入缺失 35、UI 二级交互 37、长压测 15 等）

## 7 维护

- 新增用例：在对应 `g_*` 函数内加一行 `ck <ID> <PASS|FAIL> "阈值" "实测" "证据"`；ID 必须与 `docs/TEST-CASES-v1.69.md` 一致。
- 改断言必须同时更新本文件的覆盖表，避免“日志有行即 PASS”。

## 6.1 基线详表（2026-11-26 · 142 行全覆盖）

| 项 | 数 |
|---|---|
| PASS | **41** |
| FAIL | **6** |
| BLOCKED | **103** |
| NOTRUN | 0 |

| 组 | PASS | FAIL | BLOCKED |
|---|---|---|---|
| ENV | 5 | 0 | 1 |
| SCR | 22 | 0 | 10 |
| MIX | 1 | 1 | 32 |
| LOG | 2 | 1 | 7 |
| RPT | 1 | 3 | 4 |
| CFG | 1 | 0 | 17 |
| BTN | 1 | 1 | 12 |
| E2E | 4 | 0 | 2 |
| DSP | 0 | 0 | 10 |
| PERF | 2 | 0 | 8 |

FAIL 明细（基线问题，非套件崩溃）：
- MIX-009：右摇杆横向未改变分页 scrollX（需指针定位到分页区）
- LOG-001：LogActivity dump 无事件行（页面空/刷新时序）
- RPT-002：按钮实际文案为「开始测试」，前缀匹配未命中
- RPT-003/004：TXT/JSON 导出未在 /sdcard/Download 找到（导出路径可能在 app 私有目录）
- BTN-001：ButtonDetailActivity 转场后 dump 到上一页

BLOCKED 归类：无 DebugReceiver/prefs 通道 3；无坐标级触摸或指针通道 35；多窗口/DeX/折叠 12；UI 二级交互 37；长压测 15；真手柄 1。

原始结果：`work/docs/evidence-v169/all_final.out`、`v169_all_final.log`、`20261126-224334/`。
