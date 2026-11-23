# REVIEW-landscape-v166 · t8 横屏大屏默认适配审查

> 任务：t9（审查 t8：默认横屏、指针空间、UI 分栏、竖屏回落、无回归）· attempt 1
> 审查人：reviewer · 时间：2026-11-24 03:00 CST · 设备：SM-F9360（adb 192.168.10.36:6666）
> 结论：**PASS**（t8 的 6 条 acceptance 均成立；默认横屏/守护/指针空间/居中/四方向/UI 分栏/竖屏回落/回归均有真机证据）
> 非阻塞 findings：R1–R6（见 §6）。**R1 是 t8 自家截图/文档的假证据（`ui_button_land.png` 实际是通知栏，不是 ButtonDetailActivity；t4 的 `J_button_land.png` 才是正确分栏截图），必须在 t7 发布文档前替换/更正；R5 的 CPU 口径与 t6 R4 相同，release 复测前不得宣称资源不回退。**
> 被审 t8：应用 1.66/68，装机 base.apk sha256 `e8a9118592d07b4be10116f12ae93cccb864799da116425e1948ebd9fcf7b031`（= 本机 app-debug.apk，3130719 B，与 t4 基线一致）；源码 `EngineService.kt` `16ccc5b3…`、`ConfigActivity.kt` `0e7018e3…`、`ButtonDetailActivity.kt` `408e3eeb…`（与 t4 reviewedArtifacts 一致）。

## 1. 实测环境（审查时只读复核）

```
dumpsys display mOverrideDisplayInfo: rotation 1, app 2560 x 1600, state ON (display 0)
dumpsys window displays: overrideConfig ... land ... mBounds=Rect(0,0-2560,1600) mAppBounds=Rect(0,0-2560,1600)
                          mDisplayRotation=ROTATION_0 mRotation=ROTATION_0
                          init=2560x1600 base=2560x1600 cur=2560x1600 app=2560x1600
settings user_rotation=1 / accelerometer_rotation=0 / display_size_forced=1600,2560
wm size: Physical 904x2316 / Override 1600x2560
```

**关于 `ROTATION_1` 的裁定**：本折叠屏 `dumpsys window` 的 DisplayRotation 段是 `mLandscapeRotation=ROTATION_0 / mPortraitRotation=ROTATION_270`，所以横屏对应 WM 的 `mRotation=ROTATION_0`；`dumpsys display` 的 display rotation 仍是 **1**，app bounds **2560×1600**、overrideConfig `land`。t8 acceptance #1 写的是 `dumpsys window mRotation=ROTATION_1`，字面不成立；但“横屏”的权威证据是 **display rotation 1 + app bounds 宽>高 + settings user_rotation=1/accel=0**，t8 LANDSCAPE-v166.md:15 已明确这个设备常量差异，t4 J1/J2/J6/J7 也按此判定。**实际屏幕是横屏，acceptance 的文字需要改成 display rotation 1/app bounds（R2）**，不是行为失败。

## 2. t8 的 6 条 acceptance 核对

| # | acceptance | 判定 | 证据 | 备注 |
|---|---|---|---|---|
| 1 | 默认（不手动改系统设置）装机启动后横屏：mRotation=ROTATION_1、mBounds 宽>高 | **PASS（等价证据）** | 审查时 `dumpsys display rotation 1`、`app 2560x1600`、`overrideConfig land`、`settings user_rotation=1/accel=0`；t8 LANDSCAPE-v166.md:10-12 `geometry app=2560x1600 rot=1`；t4 J1/J2/J7 | `dumpsys window` mRotation=0（设备常量），不是 1；t8 doc:15 + t4 J1 已说明；R2 |
| 2 | 外部改 user_rotation=0/accel=1 后 ≤5s 自动回横屏，不是只在 helper ready 写一次 | **PASS** | t8 LANDSCAPE-v166.md:21-29：外部改后 ~1s `landscape guardian: rotation 3 -> 1 (force_landscape=true)`，~4s settings 回 1/0；t4 J2 `recovered≈3250/3500ms (13×250ms)`、`engine=2560x1600` | 源码 `EngineService` 每 1s 复核 `Display.getRotation()`（t8 doc:19）；t4 J2 外部扰动 | 
| 3 | 在 display_size_forced=1600,2560 无法清除的前提下，应用空间按 2560×1600：居中=横屏中心、四方向可达、rot 参数正确 | **PASS（带 caveat）** | 审查时 `display_size_forced=1600,2560`、`wm size Override 1600x2560`、`dumpsys display app 2560x1600`；t4 J3 L3 点击 **1281,803**（err 2,3）；t4 E1–E4 real **0/2559/0/1599**，est-real 0–1px；t8 doc:33-36 `P` 逻辑坐标、`V/Z` display id、`O` 未用 | forced 竖屏 override 无法清除（t1/t8 doc:9）；应用空间 2560×1600，用户看到横屏；captain 已修订 acceptance #3 接受该前提 |
| 4 | UI 自适应：ConfigActivity/ButtonDetailActivity 横屏下分栏/双列，截图证据、控件可点 | **PASS（独立证据）** | t4 J4 `half_scrollviews=2` + `shots/J_config_land.png`（2560×1600，左设置/右映射双列）；t4 J5 `half_scrollviews=2` + `shots/J_button_land.png`（左单击/双击/长按、右组合键，双列）；t8 `work/ui_config_land.png` 也是双列 | **t8 自家 `work/ui_button_land.png` 是通知栏截图，不是 ButtonDetail**；t8 doc:41 把它当 ButtonDetail 证据是假的；t4 J5 真实（R1） |
| 5 | 竖屏/小屏回落：关闭强制横屏时不崩溃、控件可用 | **PASS（t8 自家截图 + t4 engine）** | t8 `work/ui_config_portrait.png`（1600×2560，ConfigActivity 单列，开关/滑杆可见）；t4 J6 `engine=1600x2560`、`half_scrollviews=0`、`pid` 存活、`shots/J_config_portrait.png` | t4 J6 的截图实际是 ButtonDetail（A 键）单列，不是 ConfigActivity；t8 自家 `ui_config_portrait.png` 才是 ConfigActivity 单列（R4） |
| 6 | 既有控制路径在横屏下不回归：光标、滑动、L3、Y+上/下、SELECT | **PASS** | t4 I1/I1B/I2/I3/I4/I5/I6 全 PASS；t4 J3 L3 1281,803；t8 doc:50-54 回归摘要；t4 J2/J7 恢复 | 与 t4 I/ t3 证据一致；无回归 |

## 3. UI 分栏截图核验（逐张）

- `work/ui_config_land.png`（235030 B，2560×1600）：ConfigActivity **真实双列**——左“启用/状态/指针/滚动”、右“A/B/X/Y/LB/RB/LT/RT 映射”；可见滑块/开关；**正确**。截图时间 00:24，左“链路自检 缺失: gesture”是 t10 前的 CAP 误报（t10 已修，不是 t8 的问题）。
- `work/ui_button_land.png`（2741972 B，2560×1600）：**实际是通知栏/快捷设置**（WLAN/蓝牙/Smart View/亮度/媒体），不是 ButtonDetailActivity；t8 doc:41 “ButtonDetailActivity ... 截图 work/ui_button_land.png（双列，添加组合…可点）”是**假证据**。t4 J5 `shots/J_button_land.png`（155259 B）才是 ButtonDetail 双列（左单击/双击/长按、右组合键）。**t8 的 ButtonDetail 分栏行为由 t4 J5 证明，但 t8 自家截图/文档必须替换/更正（R1）。**
- `work/ui_config_portrait.png`（248945 B，1600×2560）：ConfigActivity 单列（全宽设置行），正确；显示“Root 助手 未连接”是竖屏回落测试时助手/引擎被停掉，UI 仍可用（t8 doc:46）。
- `work/docs/evidence-v166-verify/shots/J_config_land.png`（235324 B）：ConfigActivity 双列，正确。
- `work/docs/evidence-v166-verify/shots/J_button_land.png`（155259 B）：ButtonDetail 双列，正确。
- `work/docs/evidence-v166-verify/shots/J_config_portrait.png`（159952 B）：实际是 ButtonDetail（A 键）单列，不是 ConfigActivity；t4 J6 的阈值写“ConfigActivity 单列”，截图与标签不符（R4）。t8 自家 `ui_config_portrait.png` 补上了 ConfigActivity 单列。

## 4. 指针空间 / 居中 / 四方向

- 审查时 `dumpsys display` app=2560×1600，`dumpsys window` mBounds/mAppBounds=Rect(0,0-2560,1600)；`wm size` override 1600×2560（竖屏尺寸仍保留，但 display rotation 1 → app 2560×1600）。
- t4 J3：L3 目标 (1280,800) 真实 `click=[1281 803] err=2,3`（阈值 ≤80px，实际 ≤5px）；t4 D-PS 9/9 也覆盖横屏。
- t4 E1–E4：左 0 / 右 2559 / 上 y=0 / 下 1599，估算-真实 0–1px；E5 贴边零位移、反向到对边；E6 d-pad 后 x=0；E7 空闲隐藏后 x=2559。
- t4 K4 `c` 回包 `display=0 space=logical` 与 P 放置 max 3px；t8 doc:33-36 P 逻辑坐标、V/Z display id、O 未用。横屏指针空间与 t3 一致。
- `display_size_forced=1600,2560` 仍存在（t1/t8 已复现不可清除），但 display rotation 1 + app 2560×1600 是实际应用空间；用户不需要手动改设置（t4 J2 外部扰动自动恢复）。

## 5. 默认横屏与旋转守护

- 默认 `force_landscape=true`；`EngineService` 每 1s 复核 `Display.getRotation()`，不等于 1 就下发助手 `r 1`（助手同时 `settings put system accelerometer_rotation 0; user_rotation 1`）——t8 doc:19。
- t4 J2：外部 `user_rotation=0 + accelerometer_rotation=1` 后 `landscape guardian: rotation 3 -> 1 (force_landscape=true)`；`recovered≈3250/3500ms (13×250ms)`，settings 回 1/0，engine geometry 2560×1600。**不是一次性写**。
- t4 J1 的 `engine=n/a`：J1 阈值文字含“引擎 geometry 亦宽>高”，但该行实际 `engine=n/a`（logcat 已被前序用例清空）；PASS 依据是 dumpsys/settings。t8 doc:12 有 `geometry app=2560x1600 rot=1`，t4 J2/J7 也有 engine，但 J1 本身没测到（R3）。
- t4 J7 恢复默认：`dumpsys=2560x1600`、`engine=2560x1600`、prefs `force_landscape=true`。

## 6. Findings（非阻塞，t8 行为通过；R1 必须修文档/截图）

| id | severity | problem | requiredFix | file:line |
|---|---|---|---|---|
| R1-T8-BUTTON-SHOT-FAKE | **medium** | `work/ui_button_land.png`（2741972 B）实际是通知栏/快捷设置截图，不是 ButtonDetailActivity；t8 LANDSCAPE-v166.md:41 和 t8 输出都把它当“ButtonDetail 双列、添加组合可点”的证据。t4 的 `shots/J_button_land.png`（155259 B）才是真实的 ButtonDetail 双列（左单击/双击/长按、右组合）。t8 的 UI 分栏行为由 t4 J5 证明，但 t8 自家交付截图/文档是假的。 | 用真实 ButtonDetail 横屏截图替换 `work/ui_button_land.png`（可直接复制 t4 `J_button_land.png` 或重拍），修正 LANDSCAPE-v166.md:41 与 t8 输出；发布文档引用 t4 J5。 | `work/ui_button_land.png`；`work/docs/LANDSCAPE-v166.md:41` |
| R2-ROTATION-LITERAL | low | t8 acceptance #1 写 `dumpsys window mRotation=ROTATION_1`；审查时 `dumpsys window` mRotation=ROTATION_0（mLandscapeRotation=ROTATION_0），`dumpsys display` rotation 1、app 2560×1600、overrideConfig land。字面 ROTATION_1 不成立；t8 doc:15 已解释，t4 J1 阈值也注明，但 acceptance/报告文字仍写 ROTATION_1。 | 把 acceptance/报告统一为“display rotation 1 + app bounds 宽>高 + user_rotation=1/accel=0”，并附 `dumpsys window mLandscapeRotation=ROTATION_0` 的设备说明；不要把 `dumpsys window mRotation=ROTATION_1` 当唯一判据。 | `work/docs/LANDSCAPE-v166.md:15`；`work/docs/VERIFY-v166.md:176` |
| R3-J1-ENGINE-NA | low | t4 J1 阈值写“默认配置即横屏...引擎 geometry 亦宽>高”，但结果行 `engine=n/a`（logcat 被清空），PASS 依据只有 dumpsys/settings；J1 本身没测到 engine。t8 doc:12 有 engine geometry、t4 J2/J7 也有，但 J1 的 PASS 与阈值不完全一致。 | t4 J1 改为读取 `logcat -d -s DexPad | grep 'geometry app='` 的本次行，或引用 t8 doc:12/J2/J7 的 engine 证据；不要在 J1 已 n/a 时仍按“引擎亦宽>高”PASS。 | `work/scripts/v166_auto_suite.sh` J1 段；`work/docs/VERIFY-v166.md:176` |
| R4-J6-SHOT-MISMATCH | low | t4 J6 阈值“ConfigActivity 竖屏单列”，但 `shots/J_config_portrait.png` 实际是 **ButtonDetail（A 键）单列**；t8 自家 `work/ui_config_portrait.png` 才是 ConfigActivity 单列。J6 的 engine 1600×2560/half_scrollviews=0 仍证明回落，但截图/标签不一致。 | 把 J6 截图改名为 `J_button_portrait.png`（ButtonDetail）并补拍 ConfigActivity 竖屏单列，或修正 J6 阈值文字；t8 自家 `ui_config_portrait.png` 可作 ConfigActivity 证据。 | `work/docs/evidence-v166-verify/shots/J_config_portrait.png`；`work/docs/VERIFY-v166.md:182` |
| R5-T8-CPU | low | LANDSCAPE-v166.md:60 写“空闲 60s 线程级 CPU 总 3.70/3.80%，低于基线+1%（<4%）”；t4 H3 同一 debug 构建的进程级 `/proc/<pid>/stat` 是 **6.03/5.97%**，超过 4%。线程级快照漏掉短命 JIT 线程（与 t6 R4 同因）。t8 的 task acceptance 未要求 CPU，但发布文档若引用该句会夸大“资源不回退”。 | 在 release 构建做进程级 60s 复测（utime+stime，说明 cutime/cstime），未复测前 LANDSCAPE/APP/README 不写 CPU <4% 或资源不回退；线程级数字标注“不含短命 JIT 线程，仅辅助”。 | `work/docs/LANDSCAPE-v166.md:60`；`work/docs/VERIFY-v166.md:155,158` |
| R6-FORCED-SIZE-CAVEAT | low | `display_size_forced=1600,2560`（竖屏 override）仍存在，wm size Override=1600×2560；t8 没有把它改成横向（也清不掉）。用户看到的是 2560×1600（display rotation 1），但系统层仍有一个竖屏 size override；t8 acceptance #1/#3 已按 captain 修订接受该前提，但发布说明需明确“不是把 display_size_forced 改横，而是 rotation 1 + app 空间的横屏”。 | 在 LANDSCAPE/README/INSTALL 文档写明该 caveat（t8 doc:9 已有，发布文档沿用）；不要把 forced size 写成已清除/已改横。 | `work/docs/LANDSCAPE-v166.md:9`；`work/docs/VERIFY-v166.md:19,176` |

> R1 是 **t8 自家交付截图/文档** 的假证据，t4 的 J5 已独立证明 ButtonDetail 分栏行为，所以 t8 的实现/行为本身 PASS；但发布文档不能引用 `work/ui_button_land.png` 当 ButtonDetail 证据。R2–R4 是验收文字/截图标签问题，R5/R6 是资源/尺寸 caveat；都不影响 t8 的横屏/守护/指针/UI/回落结论。

## 7. 回归确认

- t4 I1 d-pad 粘性 + A=DPAD_CENTER（mouse_click=0/key_enter=1）；I1B 摇杆后鼠标；I2 X 双击→Recents；I3 X+LB dx=+359/wheel_right；I4 X+RB dx=-1536/wheel_left；I5 空闲隐藏 P1=P2=2559,803（0px）+ no correction move；I6 SELECT→NotificationShade（NOTIF rc=0 + 截图 4,124,291B）。
- t4 J3 L3 1281,803；t4 J2/J7 横屏/恢复；t8 doc:50-54 回归摘要与 t4 一致。
- 未发现 t8 引入的回退；t8 的旋转守护是新增的自动恢复，不是一次性写。

## 8. 结论与给 t7 的条件

**t8 的 6 条 acceptance 均成立**：默认横屏（display rotation 1 + app 2560×1600 + settings）、旋转守护 ≤5s、forced 尺寸不可清除前提下的横屏应用空间、指针/居中/四方向、UI 双列、竖屏回落、既有控制无回退。t8 **不是靠用户手动改设置，也不是仅“控件没崩”**：t4 J2 外部扰动自动恢复、t4 J4/J5 双列截图 + `half_scrollviews=2`、t4 J3/E 点击/边缘证据。

**t7 前必须处理**：
1. 替换 `work/ui_button_land.png` 为真实 ButtonDetail 横屏截图（t4 `J_button_land.png` 可用），修 LANDSCAPE-v166.md:41 和 t8 输出（R1）。
2. 统一 `ROTATION_1` 文字为 display rotation 1 + app bounds，并保留设备常量说明（R2）。
3. t4 J1 补 engine geometry（或引用 t8 doc:12/J2/J7），J6 截图/标签修正（R3/R4）。
4. release 构建进程级 CPU 复测前，LANDSCAPE/APP/README 不写 CPU <4%/资源不回退（R5）。
5. 发布文档写明 `display_size_forced=1600,2560` 的 caveat：横屏是 rotation 1 + app 空间，不是清除 forced size（R6）。

## 9. 复现命令

```sh
adb -s 192.168.10.36:6666 shell "dumpsys display | grep -m1 mOverrideDisplayInfo"
adb -s 192.168.10.36:6666 shell "dumpsys window displays | grep -m1 -E 'mRotation=|mLandscapeRotation=|mBounds='"
adb -s 192.168.10.36:6666 shell "settings get system user_rotation; settings get system accelerometer_rotation; wm size; settings get global display_size_forced"
# t4 J 组（当前 helper 已被 t10/t13 重建，t7 用最终 helper + e8a91185 APK 重跑）
adb -s 192.168.10.36:6666 push work/scripts/v166_auto_suite.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/v166_auto_suite.sh J"
```

## 10. 限制与未覆盖

- 审查期间 t10/t13 正在改 helper，t16/t17 为 t6 的后续；本报告只审 t8 的 LANDSCAPE/UI/rotation 与 t4 J 组，不覆盖 helper 的 t10/t13。
- 未在设备上重放 UI/旋转实验（设备被 helper 测试占用）；t4 J2/J3/J4/J5/J6/J7 + t8 自家截图/文档为原始证据；本次做了只读 dumpsys/settings 复核和截图逐张查看。
- t8 自家 `ui_button_land.png` 是通知栏（R1）；t4 `J_button_land.png` 是正确 ButtonDetail 双列。t8 自家 `ui_config_portrait.png` 是正确 ConfigActivity 单列；t4 J6 的 `J_config_portrait.png` 是 ButtonDetail 单列（R4）。
