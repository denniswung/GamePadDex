# GamePadDex v2 架构（重构后）

## 分层

```
ConfigActivity ── Cfg（SharedPreferences + JSON 导入导出 + Profile）
EngineService ── RootInput（socket 行协议）── gpminput（evdev/uinput, root）
      └── EngineV2
            ├── ComboTable   发起键命名空间 + 等价继承
            ├── KeyMachine   组合窗口 / 长按 / 双击 / 单击
            ├── StickFlow    角色互换 / 滤波 / 死区补偿 / 曲线 / 轴锁 / 脉冲 / 惯性
            └── Executor     动作表 + 按住重复 + 震动
```

## 关键判定

- **组合**：按住发起键后再按参与键，`(leader, second)` 直接命中；未配置时继承
  `(second, leader)`；两者都配置则各自独立。组合命中会取消双方的单键/长按/双击。
- **长按**：`comboWindow + longPress` 后触发（默认 50+500ms），触发后不再单击。
- **双击**：两次释放间隔 ≤ `doubleWindow`（默认 280ms）触发，取消第一次单击。
- **单击**：普通键在组合窗口结束后触发；发起键/参与键/有长按/有双击的键延迟到释放。
- **摇杆**：`滤波 → 径向死区(默认8%) → 起步补偿 → pow(curve) → 速度倍率`；
  滑动用脉冲（默认 50% 屏高，启动延迟 150ms，间隔 100ms，1s 后 40ms）；
  轴锁在主方向第一次过死区时确定；手势走 `cmd_swipe`（焦点 bounds → 光标锚定 → 全屏回退），
  滚轮模式先 `T/a` 锚定光标到任务内再发 wheel。
- **接入点亮**：助手每 2s 重扫 `/dev/input`，新设备出现且屏幕非 Awake 时先发
  `KEYCODE_WAKEUP`，400ms 后仍非 Awake 则回退 `KEYCODE_POWER`；3s 防抖。
- **模式**：`enabled && modeOn` 才 grab；SHARE 切换并持久化。

## 协议新增

| 方向 | 命令 | 说明 |
|---|---|---|
| App→helper | `w 0/1` | 接入点亮开关 |
| App→helper | `k` | 立即点亮（224，失败回退 26） |
| App→helper | `a <disp> <w> <h>` | 滚轮前把光标锚定到前台任务 |
| App→helper | `?` | 自检：设备数/抓取/点亮开关/屏幕状态 |
| helper→App | `WAKE_CONNECT ...` | 接入点亮结果 |

## 测试

`work/scripts/checklist_v2.sh`：链路门禁 + 18 项（R1a/b 角色、R2 速度、R3 持续、
R4 手势/滚轮、K1a/b/c 单击/长按/双击、K2a/b 命名空间、K3 继承、K4 抑制、
S1 接入点亮、S3 亮屏不重复）。Debug 构建实测 `PASS=18 FAIL=0`。

**未覆盖**：蓝牙接入（S2）、S4 防抖、S5 开关关闭、导入导出/Profile 的端到端、
端到端延迟（P1）、控件级"焦点"（当前是前台任务级）。


## v2.1 新增

- 按键：X 单击无动作、双击多任务；R3 双击播放/暂停（右摇杆移动取消）；SELECT+START 长按 1s 开关屏；GUIDE 长按 800ms 帮助，X+GUIDE 1.5s 强停；A 在方向键后激活焦点；X 按住 = 慢速指针。
- 组合：X+LB/RB 横向 60% 屏宽、按住 300ms 后连续；音量按住 300ms 后连续；LB/RB 按住 200ms 后连续。
- 互斥：摇杆滑动/滚轮接管时停止 LB/RB 滚动；手柄全部断开时复位轴与按键状态。
- 热插拔：助手用 inotify 监听 /dev/input，新设备毫秒级抓取。
- 接入点亮：KEYCODE_WAKEUP 失败重试一次，不再用 POWER 兜底（避免把已亮屏又关掉）。
- 测试接缝：DebugReceiver com.dennis.dexpad.INJECT 可注入 key/stick/pos，用于确定性逻辑测试。
