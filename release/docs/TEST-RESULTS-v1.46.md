# v1.46 测试结果（2026-11-13）

## 自动化结果

| 套件 | 环境 | 结果 |
|---|---|---|
| `work/scripts/v145_checklist.sh`（按键/组合/摇杆/点亮，15 项） | Debug v1.46 | **PASS=15 FAIL=0** |
| `work/scripts/v146_checklist.sh`（长按/组合命名空间/灵敏度/导入导出/Profile，10 项） | Debug v1.46 | **PASS=10 FAIL=0** |
| Release 冒烟 | Release v1.46 | 链路 + X 双击多任务通过 |

## 本轮新增并通过的用例

| 用例 | 证据 |
|---|---|
| 长按动作（X 长按=多任务） | `long x -> recents` + `KEYON 0 187` |
| 长按抑制单击（A 长按不点左键） | `long a -> recents`，无 `left button down` |
| 组合发起键（X+A 直接命中） | `mix 0 x+a -> volume_up (direct)` + `KEYON 0 24` |
| 组合命名空间（A+X 独立） | `mix 1 a+x -> volume_down (direct)` + `KEYON 0 25` |
| 等价继承（删 A+X 后 A 先按） | `inherited` + `KEYON 0 24` |
| X 灵敏度 50% | 位移 13 px vs 256 px |
| 配置导出 | `dexpad-config.json 180B` |
| Profile 保存/加载 | `profile save/load testprofile ok=true` |
| 角色互换（左=滚动 右=指针） | R1 PASS |
| 接入点亮 | `WAKE_CONNECT` + `Dozing -> Awake` |

## 实现清单（v1.46）

- **按键四段模型**：单击/长按（默认 500ms，可调 300–1000）/双击/组合；长按触发后取消单击与双击；按键详情页新增“长按动作”。
- **组合命名空间与等价继承**：按实际先按下的键（发起键）匹配；直接配置优先，反向配置作为等价继承；日志标注 `direct`/`inherited`。
- **配置导入/导出/Profile**：`Prefs.exportJson/importJson`，设置页新增“导出配置/导入配置/保存为 Profile/加载 Profile”；JSON 覆盖全部 SharedPreferences。
- **摇杆**：X/Y 独立灵敏度（20–300%）、边缘减速（0–60%）、One Euro 滤波（低速稳、高速跟手）、L3 居中重置位置估计。
- 旧功能回归：GUIDE/强停/SELECT+START/音量与横滑连续/R3 双击取消/L3 锁/角色互换/接入点亮全部通过。

## 仍待完成

- 控件级焦点（当前任务 bounds + 光标锚点）。
- 滚轮模式的链路自检、权限缺失的显式提示。
- 导入/导出的 UI 端到端（文件与 API 已验证，界面点击流程未脚本化）。
- 10 分钟连续运行/端到端延迟 <50ms 的性能实测。

## 备注

- DebugReceiver 仅 Debug 可用：v145 的 role_swap 用例需 Debug APK；Release 冒烟不覆盖该项。
- 真实 prefs 在 `/data/misc/<user>/prefs/com.dennis.dexpad/dexpad.xml`。
