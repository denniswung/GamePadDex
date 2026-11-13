# 精细化测试案例：滑动 / 滚动 / 居中 / 横屏

> 目标：所有结论都用设备上的可复现证据判定（截图字节数、`uiautomator` 文本、助手日志），不依赖手感描述。
> 设备：SM-F9360，adb `192.168.10.36:6666`；测试脚本：`work/scripts/`。

## 0. 前置

```sh
adb connect 192.168.10.36:6666
adb shell sh /data/local/tmp/dexpad_restart_clean.sh    # 等输出出现 helper ready
```

`PointerProbeActivity` 是内置的指针探针（全屏、不显示在桌面）：它把收到的鼠标事件坐标写进界面文本，
测试用 `uiautomator dump` 读取，作为「光标到底在哪」的唯一事实来源。

启动：`adb shell am start -n com.dennis.dexpad/.PointerProbeActivity`

## 1. 光标居中（探针判定）

| 编号 | 步骤 | 期望 | 判定方式 |
|---|---|---|---|
| C1 | 启动探针 → 推一下左摇杆（产生 hover）→ 按 L3 | 探针文本 `x≈1280 y≈800`（横屏 2560×1600 的中心） | `probe_center.sh` 输出 `text="x=...,y=..."`，脚本比对 ±20 px |
| C2 | 连续按两次 L3 | 第二次仍在 1280,800（±5），不漂移 | 同上 |
| C3 | 先把指针推到屏幕右下角，再按 L3 | 仍回到 1280,800 | 同上 |
| C4 | 在竖屏 App（强制横屏关闭时）按 L3 | 452,1158（904×2316 的中心） | 同上（`r -1` 后测） |

脚本：`sh /data/local/tmp/probe_center.sh`

## 2. 桌面抽屉 / 通知栏

| 编号 | 步骤 | 期望 | 判定方式 |
|---|---|---|---|
| D1 | 桌面截图 → 右摇杆上推 → 截图 | 抽屉打开 | 截图 1.3 MB → < 0.8 MB（`probe_drawer.sh`） |
| D2 | 抽屉内按 B / 返回 | 回到桌面，截图恢复 > 1 MB | 同上 |
| D3 | 桌面 → 右摇杆下推 | 通知栏拉下 | 截图 > 2 MB（`checklist_run.sh` M2） |
| D4 | 抽屉打开后推右摇杆上滑一次 | 抽屉内列表滚动（截图变化） | 前后截图字节数不同 |

判定阈值来自实测：桌面 1.32 MB、抽屉 0.29 MB、通知栏 3.7 MB。

## 3. 信息流类 App（一条一次）

| 编号 | 步骤 | 期望 | 判定方式 |
|---|---|---|---|
| F1 | 打开抖音 → 右摇杆上推一次 | 助手 `SWIPE 0 1280,1040 -> 1280,560`（dy=480=30%×1600） | `grep SWIPE helper.log` + `TOP com.ss.android.ugc.aweme` |
| F2 | 同上，红果 | 若任务为竖屏：`SWIPE 0 904,1664 -> 904,896`（dy=768=30%×2560） | 同上 |
| F3 | 同上，PiliPlus | 同 F2 | 同上 |
| F4 | 任意 App 按住 LB（向上滑动+滚动） | 先 `SWIPE`（25% 屏/120 ms），随后每 80 ms 一次 `WHEEL -1`，松开停止 | 助手日志顺序 + WHEEL 计数 ≈ 15/1.5 s |

## 4. 强制横屏

| 编号 | 步骤 | 期望 | 判定方式 |
|---|---|---|---|
| R1 | 引擎启动后 | `user_rotation=1`、`accelerometer_rotation=0` | `settings get system` |
| R2 | 打开 PiliPlus / 红果（自锁竖屏的 App） | 截图 2560×1600，界面横屏渲染 | `screencap` + 图片尺寸，`wm get-ignore-orientation-request` 为 true |
| R3 | 停止引擎 | 恢复自动旋转、ignoreOrientationRequest false | `settings get system accelerometer_rotation`=1 |

## 5. 回归（原有 20 项）

`sh /data/local/tmp/checklist_run.sh`：A 链路、B 指针、C 方向键/焦点、D 滚动、E 居中、
F 切换/关闭、H 双击、I 模式切换、J 崩溃恢复，全部 `PASS` 才发布。

## 6. 本轮已定位的关键事实

- 指针的 **REL 位移按显示坐标轴**，实测增益 **3.25**（不是 1.8）：从角落 +`(屏宽/2)/3.25`、`(屏高/2)/3.25` 一次即到中心（实测 1278,800）。
- `dumpsys input` 的 `hoveringPointers` 是**窗口局部坐标**，跨窗口会跳到 904 等值，不能当反馈；探针 Activity 的 MotionEvent 坐标才是真值。
- 桌面抽屉手势必须**从屏幕下部起始**（横屏 y≈1400 起、上移 ≥600 px 才能开），从 65% 高度起会落在壁纸上、不触发。
