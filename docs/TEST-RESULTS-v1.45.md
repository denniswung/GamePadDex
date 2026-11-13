# v1.45 测试结果与实施对照（2026-11-13）

## 自动化结果（`work/scripts/v145_checklist.sh`，Debug，SM-F9360）

```
PASS L-01/04/09/10 link + A click
PASS K-03 X single no action
PASS K-03 X double = recents
PASS K-01 D-pad then A = focus
PASS K-10 L3 centre + stick lock
PASS K-12 R3 double play/pause
PASS K-12 R3 double cancelled by stick
PASS G-01 GUIDE long help
PASS X-01 X+GUIDE force stop
PASS C-11 SELECT+START screen toggle
PASS C-01 X+up volume repeat (8)
PASS C-05 X+LB wide swipe (1536px ≈ 60% 宽)
PASS X-05 X+left stick slow (44 < 290)
PASS R1 role swap (left=scroll right=pointer)
FAIL W-01 wake on connect (Dozing -> Dozing)
--------------------------------------------
PASS=14 FAIL=1
```

## 自动用例覆盖

- 链路：A 注入、点击、helper ready、屏幕状态、日志。
- 按键：X 单击无动作/双击多任务；A 焦点激活；L3 居中锁；R3 双击与摇杆取消；GUIDE 帮助；X+GUIDE 强停；SELECT+START 开关屏。
- 组合：X+↑ 音量（300ms 后连续，实测 8 次/1s）；X+LB 横滑 60% 屏宽（1536px/2560）。
- 摇杆：X+左摇杆慢速（约 0.15×）；角色互换（左=滑动、右=指针）。
- 接入点亮：失败（见下）。

## 未通过 / 限制

| 项 | 现象 | 结论 |
|---|---|---|
| W-01 接入点亮 | helper 在 `u:r:ksu:s0` 域内执行 `cmd power wakeup` / `su -c` / uinput KEY_WAKEUP 均不能点亮；adb shell 直接执行可点亮 | **未实现**：需要 App/Shizuku 侧或非 ksu 域执行点亮；建议后续把点亮交给 `am` 以外的授权通道，或改由前台 App 监听接入后调用 `KEYCODE_WAKEUP`（需权限） |

## 相对《通用控制器控制手机程序》尚未完成（如实列出）

- 5.1/5.2 长按（500ms）与四段配置页、组合命名空间/等价继承（当前组合仍是无序集合，X+A 与 A+X 等价）。
- 5.4 配置导入/导出、Profile（默认/精细/信息流）。
- 4.2 One Euro 滤波、X/Y 独立灵敏度、边缘减速未按文档参数重新标定（旧版沿用）。
- 4.4 焦点优先到“控件级”未实现（旧版为任务 bounds + 光标锚点）。
- 8.1 自检脚本尚未覆盖滚轮模式、权限缺失提示。
- W-01 接入点亮（见上）。

## 相对《手柄按键处理》已完成

- 单击表：A/B/X/Y/LB/RB/LT/RT/L3/R3/START/SELECT/GUIDE/SHARE/方向键全部按文档默认。
- 组合表：X+↑/↓/←/→、X+LB/RB（60% 宽、300ms 后连续）、X+左摇杆慢速、X 双击、X+GUIDE 1.5s、GUIDE 800ms 帮助、SELECT+START 1s、L3 居中锁、R3 双击取消。
- 明确不做项：未新增截图/亮度/LT+方向/L3+R3 前缀/LB+RB 强停/Share 长按帮助。
