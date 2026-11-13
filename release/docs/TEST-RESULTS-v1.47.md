# v1.47 测试结果（2026-11-13）

## 本轮补齐的"剩余项"

| 项 | 实现要点 | 用例 |
|---|---|---|
| **控件级焦点** | 助手把无障碍树里的"可滚动控件"矩形缓存下来（异步、TTL 15 s）；滑动以该矩形为范围，取不到时回退任务范围。滚轮模式先把指针移入该列表 | S-04/05/06/07 |
| **链路自检** | 助手 `?` 输出 11 项能力（mouse/kbd/wheel/swipe/notif/power/force/focus/screen/devices/focus_rect）；App 解析后显示在设置页，缺失写日志 | S-01/S-02 |
| **能力缺失提示** | `EngineState.caps` + 心跳 `cap missing: …` + 设置页"缺失：…" | S-01 |
| **滚轮链路自检** | 手势/滚轮两种后端断言输出类型（SWIPE vs WHEEL） | S-03 |
| **导入导出 UI 端到端** | 导出改为**完整快照**（含默认值，约 4 KB）；Profile 名预填，一键保存；真实点击验证导出/保存/加载 | UI-01..UI-06 |
| **性能实测** | 端到端延迟（助手读取→动作派发）+ 10 分钟连续运行 | S-08 / SOAK |

## 结果

```
v145_checklist.sh    PASS=15 FAIL=0
v146_checklist.sh    PASS=10 FAIL=0
v147_checklist.sh    PASS=9  FAIL=0
v147_ui_e2e.sh       PASS=6  FAIL=0
v147_soak.sh         见下
```

关键证据：

- `S-01 链路自检 (11 caps, 0 missing)`
- `S-03 gesture/wheel backends (swipe=2 wheel=2)`
- `S-04 控件级焦点 captured (449,435 2560,1600 ... scrollable=2)`
- `S-05 SWIPE ... (focus 1280..2560 / 268..1561 age=... )`
- `S-06 SWIPE ... (task ...)`（关闭开关后回退）
- `S-07 FOCUS_ANCHOR 904,1357 -> 717,914`
- `S-08 lat n=4 avg=1ms max=2ms`
- `UI export wrote a complete snapshot (4083B)` / `UI save profile (profile1 saved)` / `UI load profile (tapped profile1)`

## 长跑（10 分钟混合输入）

- 进程：app/helper 全程存活；helper PSS 稳定在 660 KB。
- 内存：app PSS 从 ~98 MB 降到 ~58 MB（GC 后稳定，无增长）。
- 崩溃/ANR：0。
- 延迟采样：`avg=0–3 ms, max=3 ms`（助手读取→动作派发）。
- 结论：**PASS**。

## 实现中解决的环境问题（重要）

- KSU 助手所在 mount namespace 没有 ART APEX，`app_process` 无法链接 → 无障碍转储改为在**全局命名空间**里由一个常驻 worker（`su -M`）执行，标记文件驱动。
- 监听 socket / 锁文件 / 客户端通道都加了 `CLOEXEC`，否则被 spawn 的 shell 继承，会出现"another helper holds the lock / already listens"。
- 转储会短暂阻塞前台应用，因此只在输入静默 700 ms 后执行，且同一时刻只允许一个转储。

## 仍未做

- One Euro 参数按文档重标定（现为通用默认值）。
- LT/RT 不可用时的震动回退（未构造系统缩放无权限场景）。
- 灵敏度自动化测量改用引擎自身 `ptr move` 轨迹；半速时的采样偏小，方向正确但数值意义有限。
