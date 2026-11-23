# TEST-CASES-v1.66 · 完整用例表与证据摘要（A~K + t10/t11/t12/t13/t15 + 发布字节冒烟）

> 判据：每条用例都有**客观真机证据**（坐标 / 计数 / 位移 / 前台组件 / 截图 / 时间戳），不以「日志出现」代替「行为正确」。
> 阈值可证伪：每条都有明确阈值与实测值，未达标即 FAIL。

## 0 版本与字节（发布绑定）

| 项 | 值 |
|---|---|
| 应用 | `com.dennis.dexpad` · versionName **1.66** / versionCode **68** |
| **发布 APK** | `release/dexpad-v1.66.apk` sha256 = **`73477ecaef948aa4b4a9ffdc5f51e8026200a66228cebd635b8aba8c79aa8bf5`**（2677039 B，`assembleRelease`） |
| 验证用 APK（同源码，debuggable） | `d2194406a3d45dd768b02137af2aa1cd47a6c6f6363948d4aefa13c7a50bb475`（3132059 B，t15/t20 全量 A~K 跑在这个字节上） |
| **发布助手** | `release/gpminput-v1.66` sha256 = **`1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf`**（851928 B） |
| 模块 | `release/gpm_dex-v1.66.zip`（内含同一助手哈希），`module.prop` version=v1.66 / versionCode=68 |
| 设备 | SM-F9360（Android 16），adb `192.168.10.36:6666`；app 空间 2560×1600（`dumpsys display` rotation 1） |

> **为什么有两套字节**：发布包是 `assembleRelease`（`debuggable=false`），而 app 的调试广播（`DEBUG` / `HCMD`）
> 在 `DebugReceiver.kt:21-22` 明确检查 `FLAG_DEBUGGABLE` 后直接返回，因此 **A~K 全量套件（依赖这些广播）只能跑在 debug 变体**上。
> 发布字节用 `work/docs/evidence-v166-install/release_smoke.sh`（只用 vgpad/padtest/uiautomator/helper.log 等公开手段）做 23 项冒烟复核，见 §14。
> 两个字节的差异只有构建变体标志与 `assets/gpminput` 资源，Kotlin 源码相同。

## 1 执行方法

```bash
# 全量 A~K（debug 变体，t15 口径）
adb push work/scripts/v166_auto_suite.sh /data/local/tmp/
adb shell "su -c 'sh /data/local/tmp/v166_auto_suite.sh all'"
# 发布字节冒烟（release 包）
adb push work/docs/evidence-v166-install/release_smoke.sh /data/local/tmp/v166_release_smoke.sh
adb shell "su -c 'sh /data/local/tmp/v166_release_smoke.sh'"
```

原始证据：
- 全量：`work/docs/evidence-v166-verify/final-auto_suite.result.txt`（run3 最终口径）、`final-auto_suite_console.txt`、`final-auto_suite.log`；截图 `work/docs/evidence-v166-final/shots_final/`
- 发布字节冒烟：`work/docs/evidence-v166-install/release_smoke.result.txt` / `release_smoke.log.txt`
- t20 修复点原始 uiautomator/logcat：`work/docs/evidence-v166-verify/t20-hidden-swipe/`
- 装机校验：`work/docs/INSTALL-v166.md`

三轮一致性（同一最终字节，A~K 68 条）：

| 轮次 | 口径 | 结果 |
|---|---|---|
| run1 | 最终口径（B1/C 修订前） | PASS=68 FAIL=0 |
| run2 | 最终口径（B1/C 修订前，前台） | PASS=68 FAIL=0 |
| **run3** | **最终口径（B1/C 修订后，前台）** | **PASS=68 FAIL=0，EXITCODE=0** |

关键指标三轮噪声内一致：A1 dPY 1335/1335/1335、A5 dPY 1415×3、B1 2478/2478/2478px、C3 ratio 1.029×3、D6 l3TookMs 524/521/578ms、H2 中位 140/116/204µs、H3 线程级 3.53/3.50/3.42%。

## 2 A 组 · 滑动串扰（修 1）

| 用例 | 阈值 | 实测（run3） | 判定 |
|---|---|---|---|
| A0 | 判别力自检：顺序注入竖+横 → 两区都动（PY 变化>20 且 HS 变化>20） | PY 1415→369 (d=1046) HS 0→512 (d=512) | PASS |
| A1 | 只动纵向区（PY 变化≥1000 且 HS 变化≤20）且 helper 仅 Z（Zn≥1 Vn=0） | PY d=1335 HS d=0 Zn=2 Vn=0 | PASS |
| A2 | 只动横向区（HS 变化≥400 且 PY 变化≤20）且 helper 仅 V（Vn≥1 Zn=0） | PY d=0 HS d=512 Zn=0 Vn=1 | PASS |
| A3 | 双轴同时超阈（RX=0.36+RY=0.73）：只一区动（PY d≥1000 HS d≤20）且 helper 仅 Z（Zn≥3 Vn=0） | PY d=1415 HS d=0 Zn=5 Vn=0 | PASS |
| A4 | 双向连续 3 次（共 6 次推杆）：overlaps=0 且 starts==dones≥6 | starts=18 dones=18 overlaps=0 orphan=0 drops=0 queued=6 inflight=0 | PASS |
| A4B | 快速交替压力下丢弃 ≤1 且全部 reason=axis_guard（A1/A2 单轴推杆无丢弃，非靠丢弃掩盖） | drops=0 SWIPE_DROP=0 axis_guard=0 | PASS |
| A5 | 空闲隐藏后第一次竖推 dPY ≥1000px（隐藏状态 pointer device=off），随后横推 dHS ≥400px | pointer=off hidden=0→1 dPY=1415 dHS=512 Zn=4 | PASS |

## 3 B 组 · 光标 dpi（修 2）

| 用例 | 阈值 | 实测（run3） | 判定 |
|---|---|---|---|
| B1 | 满推 300ms 位移 ∈[0.9,1.2]×屏宽 = [2304,3072]px（贴边起手，撞边取下界） | 2478px（屏宽 2560；对照 d150=1144/d50=498/d80=873） | PASS |
| B2 | 半推(0.49) 300ms 位移 ∈[200, 屏宽]px（最小位移断言：–30% 以上杆位线性可用） | 520px | PASS |
| B3 | 0.24 推 300ms 位移 ∈[10,200]px（旧版为 0，亚像素丢弃已修） | 36px | PASS |
| B4 | 边缘减速率（屏幕中心同推 > 左边缘同推） | center=608px edge=520px（日志 `edge slow active … scale=0.6`） | PASS |
| B5 | 参数口径（条件检查）：prefs `speed_phone=48` 或未覆盖 且 边缘减速率成立 且 0.24 推 ≥10px | prefs speed_phone=48、mid=608>half=520、low=36px | PASS |

依据（源码常量，`EngineService.kt`）：`cSpeedPhoneInt=48`、`pow(n,1.6)`（γ=1.6）、亚像素阈值 `0.2px`、边缘减速 `scale=0.6`。
dpi 不撞边三方测量（t18/t16，见 `work/docs/APP-v166.md` §9.1）：direct 48/300ms = 2462/2485/2481px = 96.2/97.1/96.9% 屏宽；proxy B（speed_phone=16 线性外推）= 91.1–93.0%；proxy A（中心 150ms×2）= 89.1–89.9%（含起步加速，**低估，仅参考**）。

## 4 C 组 · 滑动速度（修 3）

| 用例 | 阈值 | 实测（run3） | 判定 |
|---|---|---|---|
| C1 | 竖向 1.5s 注入手势数 ≥5（`scroll_speed=4` → 250ms/次） | n=6 total=3360px | PASS |
| C2 | 横向 1.5s 注入手势数 ≥3（`hswipe_speed=3` → 500ms/次） | n=3 total=3456px | PASS |
| C3 | 横/竖 1.5s **同一时间**总位移比 ∈[0.8,1.25] | ratio=1.029（3456 / 3360） | PASS |
| C4 | 参数口径（条件检查）：实测每次行程 竖∈[493,627]px、横∈[1014,1290]px（与 `w*0.45` / 560px 一致） | vpg=560px hpg=1152px hswipe=3 scroll=4 | PASS |
| C5 | 实际滚动（app 侧）：竖推 1.5s 页面位移 ≥1000px 且 横推 1.5s 分页位移 ≥400px | dPY=1415px dHS=512px | PASS |

参数：横滑 `dist=w*0.45`、`hSwipeRepeatMs=560-20*hswipe_speed`（用户 3 → 500ms）；竖滑 `dist=h*0.35`、`ms=220`、`cycle=max(ms+20,410-40*scroll_speed)`（4 → 250ms）。
**两种口径**：正式判据 = 同一时间（1.5s）总位移比 1.029；单手势 1152/560 = 2.057 属设计取舍（横向单次步长更大），不作判据。

## 5 D 组 · L3 居中（修 4，≤8px 口径）

| 用例 | 阈值 | 实测（run3） | 判定 |
|---|---|---|---|
| D0 | 新装机（无 move_gain）自标定后居中误差 ≤8px | click=[1278 800] err=-2,0；日志 `moveGain calibrated 0.0 -> 3.2465813 (src=l3-initial)` | PASS |
| D0B | 自标定日志出现且 prefs 重写 move_gain | pref `move_gain=3.2465813` | PASS |
| D-PS0 | pointer_speed=0 连续 3 次落点误差 ≤8px | 3/3 通过（err ≤3px），`l3TookMs=349` | PASS |
| D-PS3 | pointer_speed=3 连续 3 次落点误差 ≤8px | 3/3 通过（err ≤2px），`l3TookMs=347` | PASS |
| D-PS7 | pointer_speed=7 连续 3 次落点误差 ≤8px | 3/3 通过（err ≤5px），`l3TookMs=353` | PASS |
| D4 | 9/9 全部 ≤8px | 9/9 | PASS |
| D5 | L3 后按 A = 鼠标点击（mouse_click≥1 且 key_enter=0） | mouse_click=1 key_enter=0 | PASS |
| D6 | L3 端到端（应用内 l3TookMs，按下→落点稳定）≤800ms 且日志有值 | l3TookMs=578ms（wallClock≈530ms 含本机 logcat 轮询开销，仅参考） | PASS |

## 6 E 组 · 边界卡死（修 5，≤8px 口径）

| 用例 | 阈值 | 实测（run3） | 判定 |
|---|---|---|---|
| E1 | 左推 1400ms 真实光标到边缘 且 估算-真实 ≤8px | real=[0,803] est=[0 803] d=(0,0) | PASS |
| E2 | 右推 1400ms 到边缘 且 估算-真实 ≤8px | real=[2559,803] est=[2560 803] d=(1,0) | PASS |
| E3 | 上推 1400ms 到 y=0 且 ≤8px | real=[1285,0] est=[1285 0] d=(0,0) | PASS |
| E4 | 下推 1400ms 到 y=1599 且 ≤8px | real=[1285,1599] est=[1285 1600] d=(0,1) | PASS |
| E5 | 贴左边缘 5×200ms 零位移 且 反向 250ms 到对边 | P1=[0 800] P2=[0 800] P3=[2559 800] | PASS |
| E6 | d-pad 导航后再摇杆：仍可达左边缘 x=0 | real_x=0 click=[0 800] | PASS |
| E7 | 空闲隐藏后再摇杆：仍可达右边缘 x=2559 | real_x=2559（`ptr synced to real 2559,800`） | PASS |

## 7 F 组 · 摇杆唤醒（新功能 1）

| 用例 | 阈值 | 实测（run3） | 判定 |
|---|---|---|---|
| F1 | 负例 0.37 持续 1.4s：保持 Dozing 且无唤醒注入(done=0) | wf=Dozing wa=none | PASS |
| F2 | 负例 0.73 持续 1.4s：保持 Dozing 且无唤醒注入 | wf=Dozing wa=none | PASS |
| F3 | 正例 0.92 快速推：riseCrossMs ≤120ms → Awake 且 helper `WAKE done=1` | riseCrossMs=0ms sinceStartMs=205ms before=Dozing after=Awake；helper done=1 src=uinput took=439ms | PASS |
| F4 | 负例 慢爬 2.1s：riseCrossMs>120 或无 wake → 保持 Dozing | before=Dozing after=Dozing riseCrossMs=none | PASS |

阈值：幅度 ≥0.80、保持 ≥200ms、上升时间 ≤120ms（prefs `wake_stick / wake_hold_ms / wake_rise_ms` 可调）。

## 8 G 组 · Y+上 / Y+下 打开应用（新功能 2/3）

| 用例 | 阈值 | 实测（run3） | 判定 |
|---|---|---|---|
| G1 | Y+上 → 前台 `com.example.piliplus` 且 helper 组件解析启动（fallback=0 monkey=0） | top=com.example.piliplus/.MainActivity；`OPEN_APP … via …MainActivity rc=0` | PASS |
| G2 | Y+下 → 前台 抖音 且 组件解析启动 | top=com.ss.android.ugc.aweme/.splash.SplashActivity；`OPEN_APP … rc=0` | PASS |
| G3 | 预置 mix_10 自定义后 Y+上 不覆盖（OPEN_APP=0） | top=me.efesser.flauncher/.MainActivity OPEN_APP=0 | PASS |

默认表：slot10 `y+up → open_app com.example.piliplus`、slot11 `y+down → open_app com.ss.android.ugc.aweme`（仅用户未自定义时生效）。

## 9 H 组 · 提速与资源

| 用例 | 阈值 | 实测（run3） | 判定 |
|---|---|---|---|
| H1 | 事件→动作中位 ≤7ms 且最大 ≤15ms（12 次） | median=7 max=14 samples: 7 7 7 8 14 8 10 10 5 5 5 6 | PASS |
| H2 | cmd_swipe prep 中位 <1500µs 且 最大 <5000µs | median=204µs max=437µs n=12 | PASS |
| H3 | engine 静置 60s CPU ≤4%（线程级求和，辅助口径） | 3.42%（engine 2.53%、silent-audio 0.73%）；注：这是线程级辅助指标 | PASS |
| H4 | 60s 空闲内真实光标查询 ≤15 次 | CURSORQ=0 CURSOR=0 | PASS |
| H5 | 越阈→helper 收到 SWIPE 间隔（**仅记录，不判定**） | 930ms（从 vgpad 进程启动算，含 uinput 设备创建 ≈120ms；app 侧引擎口径 55–60ms） | 记录 |

应用帧耗时（`perf tick`）：t15 debug 字节 `avg=128–149µs max=3.3–8.2ms`；**发布字节 60s 空闲 `avg=33–43µs max=2.1–3.9ms`**（RS8-TICK）。
`prefs_per_tick=0`（旧版每 tick 12+ 次 SharedPreferences 查询已去除）。
**进程级 CPU 对比见 `work/docs/RELEASE-v166.md` §5**：v1.66 release 0.82% vs v1.65 release 1.62%（60s 空闲、`utime+stime`、同口径）。

## 10 I 组 · 不得回退的 6 项

| 用例 | 阈值 | 实测（run3） | 判定 |
|---|---|---|---|
| I1 | d-pad 粘性导航 + A 注入 DPAD_CENTER（mouse_click=0 key_enter≥1） | mouse_click=0 key_enter=1 | PASS |
| I1B | 摇杆移动后退回鼠标模式（A=鼠标点击） | mouse_click=1 key_enter=0 | PASS |
| I2 | X 双击（400ms 窗口）→ 多任务（RecentsActivity） | top=com.sec.android.app.launcher/com.android.quickstep.RecentsActivity | PASS |
| I3 | X+LB → 横向手势向右（dx>0，上一页方向） | `SWIPE 0 2163,803 -> 2540,803` dx=+377 | PASS |
| I4 | X+RB → 横向手势向左（dx<0，下一页方向） | `SWIPE 0 2163,803 -> 627,803` dx=−1536 | PASS |
| I5 | 空闲隐藏后原地恢复（同点误差 ≤10px，无修正移动日志） | P1=[2559 803] P2=[2559 803] d=0px `pointer shown at last position (no correction move)` | PASS |
| I6 | SELECT → 通知栏展开（NotificationShade）+ helper 真实下滑 rc=0 | shade=1 `NOTIF swipe rc=0 dur=428ms` | PASS |

## 11 J 组 · 横屏大屏默认适配

判定口径：`dumpsys display` rotation 1 + app bounds 宽>高（2560×1600）；本机 `mLandscapeRotation=ROTATION_0` 属设备常量差异（**不使用 `dumpsys window mRotation`**）。

| 用例 | 阈值 | 实测（run3） | 判定 |
|---|---|---|---|
| J1 | 默认配置即横屏：user_rotation=1、accel=0、app 宽>高 | user_rotation=1 accel=0 dumpsys=2560x1600 engine=n/a rotlock=lock 1 | PASS |
| J2 | 外部改竖屏后 ≤5s 自动回横屏（settings 回 1/0 且 app 宽>高） | recovered≈1500ms（6×250ms）dumpsys=2560x1600 engine=2560x1600 | PASS |
| J3 | 横屏居中目标=(1280,800)，落点误差 ≤8px | click=[1284 803] err=5,3 | PASS |
| J4 | ConfigActivity 横屏分栏（≥2 个半屏宽 ScrollView 并排） | count=2 shot=239153B（`work/ui_config_land.png`） | PASS |
| J5 | ButtonDetailActivity 横屏分栏（≥2 个半屏宽 ScrollView 并排） | count=2 shot=156243B（`work/docs/evidence-v166-verify/shots/J_button_land.png` = `work/ui_button_land.png`） | PASS |
| J6 | 竖屏回落可用（force_landscape=false + rotation 0 → 引擎 geometry 高>宽、单列、无崩溃） | engine=1600x2560 half_scrollviews=0 shot=161097B（ConfigActivity 单列：`work/ui_config_portrait.png`） | PASS |
| J7 | 恢复默认横屏（force_landscape=true + rotation 1 → dumpsys/引擎 geometry 宽>高） | dumpsys=2560x1600 engine=2560x1600 prefs force_landscape=true | PASS |

J1 的 `engine=n/a` 是 logcat 被清空后取不到 geometry，横屏结论由 `dumpsys display` + app bounds + settings 三重证据支撑（t9 R3 已记录）；
J2/J7 的 engine geometry 有值，可交叉验证。caveat（`display_size_forced` 清不掉）见 `work/docs/LANDSCAPE-v166.md` §7.1。

## 12 K 组 · 助手新命令（u / g→O 增益 / c / P / 10 条命令耗时）

| 用例 | 阈值 | 实测（run3） | 判定 |
|---|---|---|---|
| K1 | u 负例（屏幕已亮）：空操作 skip=1 且无 uinput 注入 | before=Awake after=Awake `WAKE … uinput=0 skip=1` | PASS |
| K2 | u 正例（Dozing）：→ Awake 且 `WAKE done=1 src=uinput` | off=Dozing after=Awake `done=1 src=uinput took=445ms` | PASS |
| K3 | g 0 4.68 后 O 居中日志使用新增益 4.68 | `GAIN effective=4.680` → `CENTER(steps+gain 4.68) -> 1280,800` | PASS |
| K4 | c 回包 `display=0 space=logical` 且与 P 放置真值误差 ≤5px（3/3） | 3/3 max=3px | PASS |
| K5 | P 绝对定位后点击落点误差 ≤40px（3/3） | 3/3 max=4px | PASS |
| K6 | 连续 10 条命令总耗时 <100ms | 50ms | PASS |

## 13 R5 · 边界缓存投毒分段取样

| 用例 | 阈值 | 实测（run3） | 判定 |
|---|---|---|---|
| R5 | 投毒后 2.0/2.3/2.5s 取样起手点均回到整屏 task 且缓存文件恢复（阈值 ≤2.5s） | 3/3 通过（2000/2300/2500ms 均 1280,480 task=0..2560/0..1600），cache 恢复 | PASS |

## 14 发布字节（release APK）冒烟 23 项

脚本 `work/docs/evidence-v166-install/release_smoke.sh`，原始结果 `release_smoke.result.txt`（PASS=23 FAIL=0）。
只用公开手段：vgpad（uinput 手柄）+ padtest（真实注入的指针事件）+ uiautomator（真实页面位置）+ `helper.log` + settings/dumpsys。

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| RS0-APK | 设备 base.apk sha256 == 发布 dexpad-v1.66.apk | 73477eca…（2677039 B） | PASS |
| RS0-VER | versionName=1.66 versionCode=68 | 1.66 / 68 | PASS |
| RS0-HELPER | `/data/adb/gpm` == 模块目录 == 发布 gpminput-v1.66 | 1bf7306f… / 1bf7306f… | PASS |
| RS0-LAND | 默认启动即横屏：user_rotation=1、accel=0、app 宽>高 | user_rotation=1 accel=0 app=2560x1600 dumpsys_rot=1 | PASS |
| RS1-L3 | L3 落点距 (1280,800) ≤40px 且 A=鼠标点击 | click=[1281 799] d=1px mouse_click=1 key_enter=0 | PASS |
| RS2-MOVE | 300ms 满推左摇杆后落点相对中心右移 ≥1000px | click=[2559 799] dx=+1279px（夹到右边缘） | PASS |
| RS3-V | 竖推 1.5s 页面下移 ≥1000px（HS 变化 ≤20）且 helper 仅 Z | PY 1415→0 d=1415 HS d=0 Zn=4 Vn=0 | PASS |
| RS3-H | 横推 1.5s 分页位移 ≥400px 且 helper 仅 V | HS 0→512 d=512 Vn=3 Zn=0 | PASS |
| RS4-HIDDEN | 空闲隐藏（POINTER off、设备不存在）后第一次竖推仍滚页 ≥1000px | POINTER off 0→1 ptr_dev=0 PY 1415→0 d=1415 Zn=4 | PASS |
| RS4-HIDDEN-H | 隐藏首推后横推仍生效 ≥400px | HS 0→512 d=512 | PASS |
| RS5-YUP | Y+上 → 前台 PiliPlus（helper OPEN_APP 组件启动） | top=com.example.piliplus/.MainActivity rc=0 | PASS |
| RS5-YDOWN | Y+下 → 前台 抖音 | top=com.ss.android.ugc.aweme/.splash.SplashActivity rc=0 | PASS |
| RS6-I1 | d-pad 粘性 + A 注入 DPAD_CENTER | mouse_click=0 key_enter=1 | PASS |
| RS6-I1B | 摇杆后 A 恢复鼠标点击 | mouse_click=1 key_enter=0 | PASS |
| RS6-I2 | X 双击 → RecentsActivity | top=…RecentsActivity | PASS |
| RS6-I3 | X+LB → dx>0 | dx=+672（`1875,802 → 2540,802`） | PASS |
| RS6-I4 | X+RB → dx<0 | dx=−1536（`1875,802 → 339,802`） | PASS |
| RS6-I5 | 空闲隐藏原地恢复 ≤10px 且无修正移动 | P1=P2=[1896 799] d=0px | PASS |
| RS6-I6 | SELECT → NotificationShade + helper 下滑 rc=0 | shade=1 `NOTIF swipe rc=0 dur=389ms` | PASS |
| RS7-GUARD | 外部改竖屏后 ≤5s 自动回横屏 | recovered≈2000ms app=2560x1600 | PASS |
| RS8-CPU | 发布字节 60s 空闲进程级 CPU 记录（与 v1.65 同口径） | 0.82%（线程 0.80%、child 0.00%） | PASS |
| RS8-Q | 60s 空闲光标查询 ≤15 次 | CURSORQ=0 CURSOR=0 | PASS |
| RS8-TICK | 引擎帧耗时日志存在 | `perf tick avg=33–43µs max=2.1–3.9ms` | PASS |

> 发布包上 **G3（自定义映射保护）、J6/J7（force_landscape 切换）** 需要调试广播，release 包按设计忽略；
> 这三项由 t15 在**同一份 Kotlin 源码**的 debug 变体上验证（§8 G3、§11 J6/J7），发布包不重复。
> **A5 的 pointer device 探针**同理改用 `helper.log POINTER off/on` + `getevent` 设备缺失 + 页面位移三重证据（RS4-HIDDEN），行为判据不变。

## 15 t10 / t11 / t12 / t13 / t15 补充验证

| 任务 | 内容 | 结论 |
|---|---|---|
| t10 | `?` 自检 CAP 语义改为「能力」：`CAP gesture` 不再上报运行时 busy，新增 `INFO gesture busy/queued`、`INFO devices_grabbed` | 设置页「链路自检」由「缺失：gesture」→ **全部通过（12 项）**；helper `139087e7`（851880 B） |
| t11 | `CAP mouse/wheel/kbd` 改用 `uinput_capable()`（`/dev/uinput` 可写），空闲隐藏指针不再误报；`CAP gamepad` 新增 `/dev/input` 可读；运行时状态移到 `INFO pointer device=on|off` | 三态对照 CAP 行逐字相同全 1；隐藏状态设置页 **全部通过（13 项）**；发布 helper `6076b63b` → 后续 `1bf7306f`（t20 之前最终） |
| t12 | t10/t11 后的最终哈希复验：自检两态 + K 组 + 控制面抽检 | PASS=10 + PASS=8，两态 CAP 全 1、ERR=0；报告 `work/docs/VERIFY-v166-hash.md` |
| t13 | 指针无关的边界/漂移抽检（`probe_v166_helper_poison_t13.sh` 等） | 边界夹取与 POINTER 恢复无回归 |
| t15 | 最终字节（APK d2194406 / helper 1bf7306f）全量 A~K **三轮** | **PASS=68 FAIL=0**（run3 最终口径，EXITCODE=0）；报告 `work/docs/VERIFY-v166-final.md` |
| t20 | 指针空闲隐藏后首次滑动加固（`doSwipe` 隐藏分支 `showPointer()` 一次，无修正移动） | 隐藏首推竖 dPY=1415 / 横 dHS=512；A 点击 1281,803 + `no correction move`；越阈→SWIPE 57ms（摇杆路径） |
| t7（本任务） | 集成发布 + 发布字节冒烟 + 60s 进程级 CPU + 哈希级装机校验 | `release_smoke` 23/23 PASS；CPU v1.66 0.82% vs v1.65 1.62%；`work/docs/INSTALL-v166.md` |

## 16 复跑命令

```bash
# 全量（debug 变体，需要 debuggable 才能用调试广播）
adb shell "su -c 'sh /data/local/tmp/v166_auto_suite.sh all'"

# 发布字节（release 包）冒烟
adb shell "su -c 'sh /data/local/tmp/v166_release_smoke.sh'"

# 装机校验（哈希/dump 表）
adb push work/docs/evidence-v166-install/verify_install.sh /data/local/tmp/
adb shell "sh /data/local/tmp/verify_install.sh"

# 60s 进程级 CPU（可对任一版本跑，参数是标签）
adb shell "su -c 'sh /data/local/tmp/v166_cpu60.sh v1.66-release'"
```
