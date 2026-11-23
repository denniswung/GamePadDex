# LANDSCAPE-v166 · 横屏大屏默认适配（t8）真机证据

设备：SM-F9360（RFCT817KWEH，Android 16），单设备串行。
装机：versionName=1.66 / versionCode=68。

> **哈希链（t9 R1/R2 修正）**：t8 当时的装机 APK = `e8a9118592d07b4be10116f12ae93cccb864799da116425e1948ebd9fcf7b031`、helper = `4f261754…`；
> t16/t20 之后的应用字节 = `d2194406…`（debug），**v1.66 发布字节 = `73477ecaef948aa4b4a9ffdc5f51e8026200a66228cebd635b8aba8c79aa8bf5`（release 构建，2677039 B）**、
> 发布 helper = `1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf`（851928 B）。
> 本文档的横屏行为结论在发布字节上已由 `work/docs/evidence-v166-install/release_smoke.result.txt`（RS0-LAND / RS7-GUARD）复核。

## 1. 现状（诊断）

- `settings get global display_size_forced` = `1600,2560`（用户工具常驻；`wm size reset` / `settings put global display_size_forced null` 均无法清除——t1 已复现，三星保留）。
- `settings get system user_rotation` = 1，`accelerometer_rotation` = 0。
- 应用看到的 display 0：`dumpsys display` 的 `mOverrideDisplayInfo` → `rotation 1`、`app 2560 x 1600`（横屏、宽>高）。
- 应用日志：`geometry app=2560x1600 rot=1 panel=2316x904 scale=1.0000 offset=0.0,0.0`（EngineService.refreshGeometry）。
- **t1 的问题**：`force_landscape` 只在 helper ready 时写一次 `r 1`；之后外部把 `user_rotation` 改成 0 或打开 `accelerometer_rotation`，应用就停在竖屏 1600×2560（"当前好像被改成竖屏了"）——不是默认尺寸的问题，而是没有旋转守护。

> **横屏判定口径（t9 R2 统一）**：`dumpsys display` 的 `mOverrideDisplayInfo` 报 **rotation 1** + app bounds **2560×1600（宽>高）**，
> 且本机 `dumpsys window` 的 `DisplayRotation` 常量是 `mLandscapeRotation=ROTATION_0 / mPortraitRotation=ROTATION_270`
> （折叠屏的 WM 常量与 `Display.getRotation()` 差 1，属设备常量差异）。
> **不要再写 `dumpsys window mRotation=ROTATION_1`**——实测该值是 `ROTATION_0`；判断横屏一律以 `dumpsys display` 的 rotation/app + app bounds 宽高为准。
> `settings get system user_rotation=1 / accelerometer_rotation=0` 是配置侧证据，`cmd window user-rotation` 返回 `lock 1`。

## 2. 默认横屏 + 旋转守护（≤5s）

实现（EngineService）：`force_landscape=true`（默认）时，每 1s 复核 `Display.getRotation()`，不等于 1 就下发助手 `r 1`（助手会同时 `settings put system accelerometer_rotation 0; user_rotation 1`）。

真机复现（外部改设置）：
```
settings put system user_rotation 0
settings put system accelerometer_rotation 1
```
- t≈1s：`user_rotation=0, accelerometer_rotation=1`
- 引擎日志：`landscape guardian: rotation 3 -> 1 (force_landscape=true)`
- t≈4s：`user_rotation=1, accelerometer_rotation=0`，`geometry app=2560x1600 rot=1`
→ 外部扰动后 **≤5s 自动回到横屏**（实测 ~1.1s 下发 + 下个刷新周期确认）。

## 3. 指针空间 / 居中 / 四方向（在 forced=1600,2560 清不掉的前提下）

- 应用空间按 **2560×1600** 处理：`geometry app=2560x1600 rot=1`，助手 `c` 回包为同一逻辑坐标空间（helper v1.66 r2）。
- L3 居中目标 = 横屏中心 (1280,800)：真机点击 `1281,803`（误差 +1,+3），日志 `CENTER_OK ... targetLogical=1280,800 err=2,3`。
- 四方向：左 0 / 右 2559 / 下 1599 / 上 y=0 可达（t3 证据 v166_app_fixes.log，t8 构建回归 L3 仍 1281,803）。
- 助手命令 rot/display：`P` 用逻辑坐标（helper 内部换算），`V/Z` 带 display id；`O` 未使用（改用 P+闭环）。竖屏回落时 P/V/Z 仍用同一 display id，行为一致。

## 4. UI 分栏（横屏大屏，宽高比 >1.2）

- ConfigActivity：左栏 = 启用/状态/指针/滚动参数；右栏 = 按键映射列表/数据管理/提示。截图 `work/ui_config_land.png`（2560×1600，双列、滑块与开关可点）。
- ButtonDetailActivity：左栏 = 单击/双击/长按动作；右栏 = 组合键。截图 `work/ui_button_land.png`。

> **截图修正（t9 R1）**：`work/ui_button_land.png` 原先存的是**通知栏/快捷设置**画面（不是 ButtonDetailActivity）。
> 现已替换为真实 ButtonDetailActivity 横屏双列截图，来源 `work/docs/evidence-v166-verify/shots/J_button_land.png`
> （sha256 `17df9fe52ad5ce4e6ea3403a9f2ad0e01cfc7749fa5742fa65bcea22b6675688`，t4 J5 产出），
> 内容为左「单击动作 / 双击动作 / 长按动作」+ 右「组合键 / 添加组合…」。旧文件留档为 `work/ui_button_land_notifbar_OLD.png`（仅存档，勿引用）。
> 分栏行为本身由 t4 J5 的 uiautomator 计数（≥2 个半屏宽 ScrollView）判定，截图只是辅证。

- **已知文案不一致（非 v1.66 回归，未在本次集成修）**：ButtonDetail 页面双击说明仍写「320 ms 内」，
  而 v1.62 起双击窗口实际是 **400 ms**（`APP-v166.md` §7 实测 `double x -> recents`）。属 UI 文案笔误，留待下个版本修。
- 实现：`resources.configuration.screenWidthDp > screenHeightDp * 1.2` 时两个 ScrollView 左右各 1 权重；否则原单列。

## 5. 竖屏/小屏回落（负例）

- `force_landscape=false`（调试广播，**仅 debuggable 构建可用**）后把 `user_rotation=0`：应用 window = 1600×2560（竖屏），ConfigActivity 正常打开、单列、控件可用，无崩溃；截图 `work/ui_config_portrait.png`。
- **截图口径（t9 R4）**：竖屏回落必须用 **ConfigActivity 单列** 截图 `work/ui_config_portrait.png`（t8 产出）；
  `work/docs/evidence-v166-verify/shots/J_config_portrait.png` 实际是 **ButtonDetail（A 键）单列**，只作旁证，不得当作 ConfigActivity 单列证据。
- 竖屏下引擎不写 rotation（守护关闭），指针/点击按 1600×2560 空间工作；恢复 `force_landscape=true` 后 ≤1s 回到横屏。

## 6. 回归（t8 构建）

- L3 居中：点击 1281,803（CENTER_OK err=2,3）✅
- Y+上 打开 PiliPlus：`mix 10 y+up -> open_app` → 前台 `com.example.piliplus/.MainActivity` ✅
- SELECT 通知栏：`NotificationShade` 出现（grep 计数 11）✅
- 其余 t3 回归（d-pad+DPAD_CENTER、X 双击、X+LB/RB、空闲隐藏无修正）代码路径未改动，t3 证据仍有效。

## 7. CPU / 查询次数（响应 captain 的 CPU 反向优化）

- 真实光标查询只在：L3 闭环、撞到夹取边界后一次同步；**空闲 30s 内 `CURSORQ=0` / `CURSOR=0`**（脚本 `probe_v166_app_idle_checks.sh`）。
  发布字节上 60s 空闲复测同样 `CURSORQ=0 / CURSOR=0`（`release_smoke.result.txt` RS8-Q）。
- 空闲循环从 8ms 自适应降到 16ms（有按键/摇杆/滚轮/居中立即回 8ms）：
  - t8 当时的**线程级**快照 **3.70% / 3.80%**（engine 2.73%/2.77%，silent-audio 0.83%）——**仅作辅助指标**（不含短命 JIT 线程，且当时测试环境不同）。
  - **t7 的发布字节 60s 进程级同口径对比**：v1.66 release `utime+stime` = **0.82%**（线程级 0.80%、`cutime+cstime` 0.00%）；
    v1.65 release 同法 = **1.62%**（线程级 1.58%）。→ 空闲 CPU 低于 v1.65，非“不回退”式口头结论，数字见 `work/docs/RELEASE-v166.md` §5。
  - 事件→动作（12 次 A）中位 **7ms**（最大 12–14ms），与 t3 持平；帧耗时 `perf tick avg=33–43µs max=2.1–3.9ms`（发布字节 RS8-TICK）。
- `move_gain` 是运行时标定结果（Prefs 默认值 0/未设置，新装机首次 L3 会自行标定），不是写死的默认值；prefs 里的值只是本机标定缓存。
- `hswipe_speed=3` 是用户原有自定义：新公式下 = 500ms/次（默认 7 = 420ms），保留不动。

## 7.1 已知 caveat（t9 R6）

- `settings get global display_size_forced` = `1600,2560` **无法清除**：`wm size reset`、`settings put global display_size_forced null`、
  `wm size 1600x2560` 再 reset 均无效（三星保留该 override，t1 复现）。
- 所以 v1.66 的“默认横屏”实现是 **`user_rotation=1` + `accelerometer_rotation=0` + 应用按 2560×1600 逻辑空间工作**，
  **不是清除竖屏 override**；`wm size` 仍显示 `Physical size: 904x2316 / Override size: 1600x2560`。
- 用户若手动改分辨率/强制尺寸（`wm size`、`display_size_forced`、DeX 外接屏），必须**重新校验指针空间与居中增益**
  （L3 会自行重标定 `move_gain`，但 app bounds 变化后请再按一次 L3 并复核落点）。

## 8. 复跑命令

```
python3 work/scripts/fix_crlf.py
cd project/lsp-dexpad && JAVA_HOME=... ANDROID_HOME=... ./gradlew --no-daemon --no-build-cache assembleRelease
adb -s 192.168.10.36:6666 shell "dumpsys display | grep -m1 mOverrideDisplayInfo"
adb -s 192.168.10.36:6666 shell "settings get system user_rotation; settings get system accelerometer_rotation; wm size"
adb -s 192.168.10.36:6666 shell "su -c 'sh /data/local/tmp/v166_release_smoke.sh'"
```

> 注：调试广播（`DEBUG`/`HCMD`）只在 **debuggable** 构建生效（`DebugReceiver.kt:21-22` 检查 `FLAG_DEBUGGABLE`），
> 发布用的 `assembleRelease` 包上这些命令被有意忽略；发布字节的验证用 `release_smoke.sh`（只用 vgpad/padtest/uiautomator/helper.log 等公开手段）。
