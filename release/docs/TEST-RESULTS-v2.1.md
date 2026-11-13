# v2.1 测试结果（2026-11-13）

## 套件与结果

| 套件 | 环境 | 结果 |
|---|---|---|
| `work/scripts/checklist_v2.sh`（真实手柄注入 18 项） | Debug，SM-F9360 | **PASS=18 FAIL=0** |
| `work/scripts/v21_inject.sh`（引擎逻辑注入 11 项） | Debug | **PASS=10 FAIL=0 SKIP=1**（边缘减速测量不确定） |
| `work/scripts/release_smoke.sh`（Release，默认配置 8 项） | Release v2.1 | **PASS=8 FAIL=0** |

## 关键用例证据

| 用例 | 证据 |
|---|---|
| X 单击无动作 | 单击后 helper 无 `KEYON`；`single x` 日志为 0 |
| X 双击=多任务 | `double x -> recents`，helper `KEYON 0 187` |
| A 在 D-pad 后=激活焦点 | `PAD` 后 `KEYON 0 23`（DPAD_CENTER） |
| 右摇杆停止 LB 滚动 | `hold start lb` → 摇杆 → `hold stop lb` |
| L3 居中锁 | `centerLock 4000ms`，期间指针坐标不变 |
| GUIDE 长按帮助 | `guide help` + HelpActivity 置顶 + `HELP 1` |
| X+GUIDE 1.5s 强停 | `force stop by X+GUIDE` + helper `CLOSE_APP` |
| SELECT+START 开关屏 | `select+start -> screen toggle` |
| R3 双击播放/暂停 | `double r3 -> play_pause` + `KCOMBO ... keys=85,` |
| X+↑ 音量 | `combo x+up -> volume_up` + `KCOMBO ... keys=24,` |
| 接入点亮 | `WAKE_CONNECT` 且 `mWakefulness: Dozing → Awake` |
| 手势/滚轮 | 手势 `SWIPE`，滚轮 `WHEEL` |
| 持续输出 | 800ms 推住产生多次 `SWIPE` |
| 横向惯性 | 松开后仍有多级衰减输出 |

## SKIP / 未覆盖

- **edge slowdown**：已实现（50% 边缘减速，`edge slow` 日志可见），但自动化位移测量受指针饱和影响，标记 SKIP；建议人工在慢速推杆时体验边缘降速。
- 蓝牙接入点亮（USB 虚拟设备等价验证通过；蓝牙需物理手柄）。
- 真机端到端延迟 <50ms、10 分钟连续运行（可用 `perf` 脚本后续补）。
- 导入/导出/Profile 的 UI 端到端（DebugReceiver 已验证配置写入，UI 交互未覆盖）。
