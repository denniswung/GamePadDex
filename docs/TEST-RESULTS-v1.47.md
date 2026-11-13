# v1.47 测试结果（2026-11-13，方案 B：无 uiautomator）

## 结论

```
v145_checklist.sh    PASS=15 FAIL=0     (按键/组合/摇杆/点亮/居中)
v146_checklist.sh    PASS=10 FAIL=0     (长按/组合命名空间/灵敏度/导入导出)
v147_checklist.sh    PASS=9  FAIL=0     (自检/后端/任务范围/延迟/无崩溃)
v147_ui_e2e.sh       PASS=6  FAIL=0     (导出/保存 Profile/加载 Profile)
Release 冒烟          link ok, fatal=0
```

## 本轮变更（方案 B）

删除 uiautomator 相关全部实现（worker、转储、缓存、焦点协议、开关与状态行），控件级焦点的替代实现：

- 滑动起点优先取光标（在任务内时），起点与终点都被夹在前台任务矩形内；
- 无光标时从任务中心起手；
- 滚轮直接作用于光标位置。

保留：链路自检（9 项）、能力缺失提示、手势/滚轮双后端、完整快照导出、Profile 预填名、端到端延迟采样。

## 证据

- `S-01 链路自检 (9 caps, 0 missing)`
- `S-03 gesture/wheel backends (swipe=2 wheel=2)`
- `S-04 swipe inside task (1280,1040 -> 1280,480 in 0..2560 / 0..1600)`
- `S-05 continuous scroll output (20 swipes)`
- `S-06 wheel backend (wheel=5 swipe=0)`
- `S-07 input latency avg=1ms < 50ms`
- `S-08 no fatal exception`
- UI：`UI export wrote a complete snapshot`、`UI save profile (profile1 saved)`、`UI load profile (tapped profile1)`

## 关于之前的崩溃

长跑期间日志里的 6 次 `FATAL EXCEPTION: java.lang.IllegalStateException: UiAutomationService ... already registered!`
全部来自 uiautomator 转储进程（UiAutomation 单例冲突），不是主 App。本版已彻底移除该路径；
完整回归与 Release 冒烟期间 `FATAL EXCEPTION` 计数为 0。

## 未做

- 10 分钟长跑未重跑（按要求不做长时间测试）；改为短回归 + `fatal` 计数验收。
- One Euro 参数未按文档重标定（沿用通用默认）。
- LT/RT 不可用时的震动回退未构造场景。
