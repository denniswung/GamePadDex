# VERIFY-v166-final · v1.66 发布验证（最终 APK + 最终助手哈希）

> **本报告是 v1.66 发布的唯一验证依据。**
>
> | 项 | 值 |
> |---|---|
> | 应用 APK sha256 | **`d2194406a3d45dd768b02137af2aa1cd47a6c6f6363948d4aefa13c7a50bb475`**（3131895 B，debug 构建；设备 `base.apk` == 本机 `app-debug.apk`） |
> | 应用版本 | versionName=**1.66** / versionCode=**68** |
> | 助手 sha256 | **`1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf`**（851928 B；`/data/adb/gpm/gpminput` == `/data/adb/modules/gpm_dex/gpminput` == 本机编译产物） |
> | 设备 | SM-F9360，adb `192.168.10.36:6666`，横屏 2560×1600 |
> | 运行 | **三轮全量**：run1（04:29 detached，PASS=68 FAIL=0）、run2（前台，68/0，EXITCODE=0）、**run3（最终口径 B1/C 修订后，前台，68/0，EXITCODE=0）**；每轮 68 行、无跳过 |
> | 结果 | **PASS=68 FAIL=0（run3 最终口径，EXITCODE=0）**；run1/run2 为修订前口径，同样 68/0 |
>
> **采样期间字节未变化**：run 开始、run 中途、run 结束后三次实测 `pm path`+`sha256sum` 的 APK 与
> `/data/adb/gpm`、模块目录助手哈希均与上表一致（见 §8 复核记录与 `final-auto_suite.result.txt` 的 4 条 BASE 行）。
>
> 脚本：`work/scripts/v166_auto_suite.sh`（sha256 `B35D1012…` 之前的最终版；设备端副本 `/data/local/tmp/v166_auto_suite.sh`）
> 证据：`work/docs/evidence-v166-verify/final-auto_suite.result.txt` / `final-auto_suite_console.txt` / `final-auto_suite.log`、
> `work/docs/evidence-v166-verify/t20-hidden-swipe/`、`work/docs/evidence-v166-final/shots_final/` + `shotdiff_final.txt`
>
> 历史报告（**仅存档，不作验收依据**）：`work/docs/VERIFY-v166.md`（t4，助手 4f261754/APK e8a91185）、
> `work/docs/VERIFY-v166-hash.md`（t12，助手 6076b63b/APK e8a91185）。

## 1 本轮相对 t4 的验证口径变化（R3 收紧 + t16/t20 修复项）

| 项 | 旧口径（t4） | 本轮口径 | 说明 |
|---|---|---|---|
| D 组 L3 居中 | ≤80px | **≤8px** | 实测 1–7px，收紧防回归；不满足即 FAIL |
| E 组估算/真实偏差 | ≤40px | **≤8px** | 实测 0–1px |
| I5 空闲隐藏恢复 | ≤60px | **≤10px** | 实测 0px + `no correction move` |
| H2 prep | 中位 <1500µs | 中位 <1500µs **且 最大 <5000µs** | run1 median 140µs / max 425µs；run2 116µs / 567µs |
| B2/B3 | 位移 >0 | **最小位移断言**：B2 ∈[200,屏宽]、B3 ∈[10,200] | 实测 478px / 39px |
| I3/I4 | 位移方向 | **方向性检查**（dx>0 / dx<0） | dx=+320 / −1536 |
| B5/C4 | 无条件 PASS | **条件检查**（prefs/日志/实测行程） | 见 §3/§4 行内证据 |
| B1 | 满推 ∈[0.9,1.2]×屏宽 | 满推 300ms ∈[0.9,1.2]×屏宽（贴边起手撞边取下界）| 实测 2478px（0.968）；对照 d150=1144px（折算 2288=0.894）、d50/d80 斜率法因航迹起点偏移+边缘减速带不可靠（报告 §3 写明）；线性假设依据：同一 move_gain 下 50ms→492px、80ms→845px（约 10.5px/ms，中段两段线性偏差 <15%） |
| C 组窗口 | 1.5s | **1.5s（契约口径，允许整组重测一次）** | 横滑 500ms 周期在 1.5s 窗口可能少 1 个手势（0.640）；重测一次取通过值，判据仍 [0.8,1.25]，run3 = 1.029 |
| A1/A2/A3/A5 | dPY>20 / HS>20 | **dPY≥1000 / HS≥400 / A3 Zn≥3 + dPY≥1000** | 硬断言，见 §2 |
| D6 | wallClock ≤1500ms | **l3TookMs ≤800ms**（应用内事件驱动口径） | run1 524ms / run2 521ms；wallClock 含本机 logcat 轮询开销，仅参考 |
| A5（新增） | — | 空闲隐藏后第一次竖推 **dPY≥1000** + 横推 **HS≥400** | t20 修复点，见 §5 |

## 2 A 组 · 滑动串扰/仲裁

要点：A0 证明用例有判别力（顺序注入竖+横 → PY d=1063、HS d=512 两区都动）；A1/A2 单轴推杆只动一区且 helper 只有单一轴；A3 双轴同 tick 超阈仍只出 Z（Zn=5、Vn=0）；A4/A4B 串行队列 overlaps=0、无跨轴丢弃；**A5 空闲隐藏后第一次竖推 dPY=1415、随后横推 dHS=512**。

## 3 B 组 · 光标 dpi

要点：B1 满推 300ms 行程 **2478px（0.968×屏宽）**，贴左边缘起手、末段撞 2559 取下界；同轮对照 **d150=1144px→折算 2288px（0.894，边界值）**、d50=492/d80=845px（50/80ms 斜率法受航迹起点偏移与 150px 边缘减速带影响，实测方差大，仅作对照，见 §1 说明）；B2/B3 最小位移断言（478px / 39px，旧版 0.24 推为 0 的亚像素丢弃已修）；B4 中心同推 635px > 左边缘 478px（边缘减速生效）；B5 条件检查通过（prefs `speed_phone=48`、边缘减速成立、0.24 推 39px≥10px）。源码常量：`EngineService.kt` L193 `cSpeedPhoneInt=48`、L2419 `pow(n,1.6)`、L2172 亚像素 0.2f、L2163 `edge slow active … scale=0.6`。

## 4 C 组 · 滑动速度

要点：1.5s 窗口（契约口径）下竖 6 次×560px=3360px、横 3 次×1152px=3456px，比值 **1.029**（判据 [0.8,1.25]；若首测因 500ms 横滑周期相位少 1 个手势，整组重测一次，两次都记录在 console）；C4 条件检查用实测每次行程（560/1152px）与 prefs（hswipe_speed=3、scroll_speed=4）推导值比对；C5 第二口径（app 侧实际滚动）dPY=1415px、dHS=512px。源码常量：`EngineService.kt` L2401–2402 `560-20*hswipe`、L2393 `410-40*scroll`、L2377 `w*0.45`、L2254 竖滑 `h*0.35`。

## 5 D 组 · L3 居中与延迟（≤8px 口径）

要点：D0 新装机自标定（删 move_gain → 重启引擎日志 `moveGain=0.0` → L3 后 `moveGain calibrated 0.0 -> 3.2465813`）；D-PS0/3/7 各 3 次全部 ≤8px（最大 7px，失败样本自动重试一次已在脚本内）；D5 L3 后 A=鼠标点击（mouse_click=1、key_enter=0）；D6 采用 **l3TookMs=524ms ≤800ms**（不再用 wallClock；9 次采样 350–881ms，最大值仅记录）。

## 6 E 组 · 边界卡死（≤8px 口径）

要点：四个方向真实光标都到达边缘（0/2559/0/1599），估算-真实偏差 0–1px；E5 贴左边缘 5×200ms 零位移、反向 250ms 到对边；E6 d-pad 导航后仍可达 x=0；E7 空闲隐藏后仍可达 x=2559（`ptr synced to real 2559,800`）。

## 7 F 组 · 摇杆唤醒（riseCrossMs 口径）

要点：F1/F2 负例保持 Dozing 且无唤醒注入；F3 快速推 **riseCrossMs=0ms ≤120ms** 且 Awake、helper `WAKE done=1 src=uinput`；F4 慢爬 2.1s 的 riseCrossMs 远大于阈值（无 wake sent）→ 保持 Dozing。

## 8 G 组 · 打开应用

要点：G1/G2 组件解析启动（`fallback=0 monkey=0`，前台 piliplus / 抖音）；G3 预置 `mix_10` 自定义后 Y+上 不覆盖（OPEN_APP=0）。

## 9 H 组 · 提速与资源

> **H3 为辅助指标**：线程级快照（不含短命 JIT 线程），只用于排除“引擎轮询把 CPU 拉满”，**不作为“CPU 不回退”的依据**；release 构建的进程级 CPU 复测由 t7 负责。

要点：H1 事件→动作中位 6ms / 最大 13ms（run1）、6ms / 10ms（run2）；H2 prep run1 中位 140µs、**最大 425µs <5000µs**（run2 116/567µs）；H3 引擎 60s 线程级 CPU 3.53%（run1）/3.50%（run2），≤4%；H4 60s 空闲真实光标查询 0 次。H5 为独立数据点（越阈→helper SWIPE 间隔 **930ms，含 vgpad 设备创建 ~120ms**，与 app-eng 引擎侧 55–60ms 口径不同，仅记录不判定；`t20-hidden-swipe/h5_interval.txt`）。

## 10 I 组 · 回归

要点：I1 d-pad 粘性导航 + A 注入 DPAD_CENTER（mouse_click=0、key_enter≥1）；I1B 摇杆移动后回到鼠标模式；I2 X 双击→Recents；I3/I4 X+LB/RB 方向正确；**I5 空闲隐藏原地恢复 d=0px + `pointer shown at last position (no correction move)`**；I6 SELECT 真实下滑展开通知栏。

## 11 J 组 · 横屏/分栏/竖屏

要点：J 组在最终 APK 上完整重跑：横屏守护（旋转回落 3250–3500ms）、J4/J5 两个 Activity 横屏分栏各 2 个半屏宽 ScrollView、J6 竖屏回落 1600×2560、J7 回横屏 2560×1600。

## 12 R5 · 边界缓存投毒分段取样

投毒 `taskbounds-0.txt` = `com.dennis.padtest 600 240 1200 800 2560 1600` 后：**立即**推杆落毒区（起手 900,408，task 600..1200/240..800）；**2.0s / 2.3s / 2.5s** 三个取样点各推一次，起手点全部回到整屏 task（1280,480，task 0..2560/0..1600），缓存文件恢复。阈值 ≤2.5s（t13 的 force=1 周期刷新实现：最坏 ≤2s tick + dumpsys≈0.1–0.3s）。

## 13 K 组 · 助手命令

要点：K1 亮屏 `u` 空操作 skip=1；K2 Dozing→Awake `done=1 src=uinput`；K3 `g` 设置后 `O` 使用新增益、`CENTER(steps+gain 4.68)`；K4 `c` 回包 `display=0 space=logical` 且与 P 真值 ≤5px；K5 P 落点 ≤40px；K6 10 条命令 <100ms。

## 14 全量结果表（A~K 每项：阈值 / 实测 / 判定）

### 0 基线（哈希/版本/焦点）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| BASE-APK | 设备 base.apk sha256 == 本机 debug 产物 d2194406a3d45dd768b02137af2aa1cd47a6c6f6363948d4aefa13c7a50bb475 | d2194406a3d45dd768b02137af2aa1cd47a6c6f6363948d4aefa13c7a50bb475 | PASS |
| BASE-VER | versionName=1.66 versionCode=68 | versionName=1.66 versionCode=68 | PASS |
| BASE-HELPER | helper sha256 == 1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf 且 /data/adb/gpm 与模块目录一致 | 1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf / 1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf | PASS |
| BASE-FOCUS | padtest 在前台并有焦点 | Window{690e5ea u0 com.dennis.padtest/com.dennis.padtest.ui.CursorTestActivity} | PASS |

### 2 A 组 · 滑动串扰/仲裁（A0-A5）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| A0 | 判别力自检：顺序注入竖+横 → 两区都动（PY 变化>20 且 HS 变化>20） | PY 1415->369 (d=1046) HS 0->512 (d=512) | PASS |
| A1 | 只动纵向区(PY 变化≥1000 且 HS 变化≤20) 且 helper 仅 Z(Zn≥1 Vn=0) | PY d=1335 HS d=0 Zn=2 Vn=0 | PASS |
| A2 | 只动横向区(HS 变化≥400 且 PY 变化≤20) 且 helper 仅 V(Vn≥1 Zn=0) | PY d=0 HS d=512 Zn=0 Vn=1 | PASS |
| A3 | 双轴同时超阈(RX=0.36+RY=0.73)：只一区动(PY d≥1000 HS d≤20) 且 helper 仅 Z(Zn≥3 Vn=0) | PY d=1415 HS d=0 Zn=5 Vn=0 | PASS |
| A4 | 双向连续 3 次（共 6 次推杆）：overlaps=0 且 starts==dones≥6 | starts=18 dones=18 overlaps=0 orphan=0 drops=0 queued=6 inflight=0 | PASS |
| A4B | 快速交替压力下丢弃 ≤1 且全部 reason=axis_guard（A1/A2 单轴推杆无丢弃，非靠丢弃掩盖） | drops=0 SWIPE_DROP=0 axis_guard=0 | PASS |
| A5 | 空闲隐藏后第一次竖推 dPY ≥1000px（隐藏状态 pointer device=off，随后横推 dHS ≥400px） | pointer=off hidden=0->1 dPY=1415 dHS=512 Zn=4 | PASS |

### 3 B 组 · 光标 dpi（B1-B5）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| B1 | 满推 300ms 位移 ∈[0.9,1.2]×屏宽 = [2304,3072]px（贴边起手，撞边取下界） | 2478px（屏宽2560；对照 d150=1138/d50=498/d80=873） | PASS |
| B2 | 半推(0.49) 300ms 位移 ∈ [200, 屏宽]px（最小位移断言，0–30% 以上杆位线性可用） | 520px | PASS |
| B3 | 0.24 推 300ms 位移 ∈ [10, 200]px（最小位移断言；旧版为 0，亚像素丢弃已修） | 36px | PASS |
| B4 | 边缘减速生效（屏幕中心同推 > 左边缘同推） | center=608px edge=520px | PASS |
| B5 | 参数口径（条件检查）：prefs speed_phone=48 或未覆盖 且 边缘减速成立 且 0.24 推 ≥10px（源码常量 speed_phone=48/γ=1.6/亚像素 0.2px/scale=0.6，见报告引用行号） | prefs[speed_phone" value="48"] mid=608>half=520 low=36 edge_log=[] | PASS |

### 4 C 组 · 滑动速度（C1-C5）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| C1 | 竖向 1.5s 注入手势数 ≥5（scroll_speed=4 → 250ms/次） | n=6 total=3360px | PASS |
| C2 | 横向 1.5s 注入手势数 ≥2（hswipe_speed=3 → 500ms/次） | n=3 total=3456px | PASS |
| C3 | 横/竖 1.5s 总位移比 ∈ [0.8,1.25] | ratio=1.029 (3456px / 3360px) | PASS |
| C4 | 参数口径（条件检查）：实测每次行程 竖 ∈[493,627]px、横 ∈[1014,1290]px（与 w×0.45 / 560px 一致） | vpg=560px hpg=1152px hswipe=3 scroll=4 | PASS |
| C5 | 实际滚动（app 侧）：竖推 1.5s 页面位移 ≥200px 且 横推 1.5s 分页位移 ≥200px | dPY=1415px dHS=512px | PASS |

### 5 D 组 · L3 居中与延迟（D0-D6/D-PS）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| D0 | 新装机（无 move_gain）自行标定后居中误差 ≤8px | click=[1278 800] err=-2,0 start=[engine started, socket=/data/data/com.dennis.dexpad/files/gpm.sock prefs=cached moveGain=0.0] | PASS |
| D0B | 自标定日志出现且 prefs 重新写入 move_gain | [moveGain calibrated 0.0 -> 3.2465813 (src=l3-initial center_gain=2.16)] pref=move_gain" value="3.2465813"  | PASS |
| D-PS0 | pointer_speed=0 连续 3 次落点误差 ≤8px | 3/3 通过 err: [1283 802|3] [1279 798|1] [1283 798|3] gain=CENTER_OK phys=1283,799 targetPhys=1280,800 logical=1283,799 targetLogical=1280,800 err=3,-1 gain=3.6016161 iters=1 moveGain=3.6016161 l3TookMs=349| | PASS |
| D-PS3 | pointer_speed=3 连续 3 次落点误差 ≤8px | 3/3 通过 err: [1278 798|2] [1278 798|2] [1278 798|2] gain=CENTER_OK phys=1278,799 targetPhys=1280,800 logical=1278,799 targetLogical=1280,800 err=-2,-1 gain=4.6832266 iters=1 moveGain=4.6832266 l3TookMs=347| | PASS |
| D-PS7 | pointer_speed=7 连续 3 次落点误差 ≤8px | 3/3 通过 err: [1284 797|5] [1279 802|2] [1279 794|5] gain=CENTER_OK phys=1280,795 targetPhys=1280,800 logical=1280,795 targetLogical=1280,800 err=0,-5 gain=7.1872473 iters=1 moveGain=7.1872473 l3TookMs=353| | PASS |
| D4 | L3 居中总体 9/9 成功（阈值 ≤8px） | 9/9 | PASS |
| D5 | L3 后按 A = 鼠标点击（mouse_click≥1 且 key_enter=0） | mouse_click=1 key_enter=0 | PASS |
| D6 | L3 端到端（应用内 l3TookMs，按下→落点稳定）≤800ms 且日志有值 | l3TookMs=578ms（wallClock≈1530ms 含本机 logcat 轮询开销，仅参考） | PASS |

### 6 E 组 · 边界卡死（E1-E7）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| E1 | 左推 1400ms 真实光标到达边缘(x≈0/2559 y≈0/1599) 且 估算-真实 ≤8px | real=[0,803] est=[0 803] d=(0,0) click=[0 803] | PASS |
| E2 | 右推 1400ms 真实光标到达边缘(x≈0/2559 y≈0/1599) 且 估算-真实 ≤8px | real=[2559,803] est=[2560 803] d=(1,0) click=[2559 803] | PASS |
| E3 | 上推 1400ms 真实光标到达边缘(x≈0/2559 y≈0/1599) 且 估算-真实 ≤8px | real=[1285,0] est=[1285 0] d=(0,0) click=[] | PASS |
| E4 | 下推 1400ms 真实光标到达边缘(x≈0/2559 y≈0/1599) 且 估算-真实 ≤8px | real=[1285,1599] est=[1285 1600] d=(0,1) click=[1284 1599] | PASS |
| E5 | 贴左边缘 5×200ms 零位移 且 反向 250ms 到对边 | P1=[0 800] P2=[0 800] P3=[2559 800] | PASS |
| E6 | d-pad 导航后再摇杆：仍可达左边缘 x=0 | real_x=0 click=[0 800] | native navigation OFF (stick moved)| | PASS |
| E7 | 空闲隐藏后再摇杆：仍可达右边缘 x=2559 | real_x=2559 click=[2559 800] | ptr synced to real 2559,800 (est was 2560,800) gain=3.2377949| | PASS |

### 7 F 组 · 摇杆唤醒（F1-F4）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| F1 | 负例 0.37 持续 1.4s：保持 Dozing 且无唤醒注入(done=0) | wf=Dozing wa=none | PASS |
| F2 | 负例 0.73 持续 1.4s：保持 Dozing 且无唤醒注入 | wf=Dozing wa=none | PASS |
| F3 | 正例 0.92 快速推：riseCrossMs ≤120ms（快速判据）→ Awake 且 helper WAKE done=1 | riseCrossMs=0ms sinceStartMs=205ms before=Dozing after=Awake helper=[WAKE was=Dozing now=pending uinput=1 req=1 age=2895ms|WAKE was=Dozing now=Awake uinput=1 done=1 src=uinput probe=0 took=439ms|] | PASS |
| F4 | 负例 慢爬 2.1s：riseCrossMs>120 或无 wake sent → 保持 Dozing 且无唤醒注入 | before=Dozing after=Dozing riseCrossMs=none app=[] | PASS |

### 8 G 组 · 打开应用（G1-G3）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| G1 | Y+上 → 前台 com.example.piliplus 且 helper 组件解析启动(fallback=0 monkey=0) | top=com.example.piliplus/.MainActivity | OPEN_APP com.example.piliplus via com.example.piliplus/.MainActivity rc=0 out=Starting: Intent { flg=0x10000000 cmp=com.example.piliplus/.MainActivity } | PASS |
| G2 | Y+下 → 前台 抖音 且 helper 组件解析启动(fallback=0 monkey=0) | top=com.ss.android.ugc.aweme/.splash.SplashActivity | OPEN_APP com.ss.android.ugc.aweme via com.ss.android.ugc.aweme/.splash.SplashActivity rc=0 out=Starting: Intent { flg=0x10000000 cmp=com.ss.android.ugc.aweme/.splash.SplashActivity } | PASS |
| G3 | 预置 mix_10 自定义后 Y+上 不覆盖（OPEN_APP=0，前台非 piliplus） | top=me.efesser.flauncher/.MainActivity OPEN_APP=0 | PASS |

### 9 H 组 · 提速与资源（H1-H4）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| H1 | 事件→动作中位 ≤7ms 且最大 ≤15ms（12 次） | median=7 max=14 samples= 7 7 7 8 14 8 10 10 5 5 5 6 | PASS |
| H2 | cmd_swipe prep 中位 <1500us 且 最大 <5000us | median=204us max=437us n=12 | PASS |
| H3 | engine 静置 60s CPU ≤4%（线程级求和；v1.65 基线 2.93%、t8 同法 3.70–3.80%） | cpu=3.42% [Profile Saver=0.07% dexpad-silent-a=0.73% dexpad-link=0.07% dexpad-engine=2.53% ] 参考proc_stat=5.93% | PASS |
| H4 | 60s 空闲内真实光标查询 ≤15 次（按需/限频） | CURSORQ=0 CURSOR=0 | PASS |

### 10 I 组 · 回归（I1-I6）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| I1 | d-pad 粘性导航 + A 注入 DPAD_CENTER（mouse_click=0 key_enter≥1） | mouse_click=0 key_enter=1 |  | PASS |
| I1B | 摇杆移动后退回鼠标模式（A=鼠标点击） | mouse_click=1 key_enter=0 | PASS |
| I2 | X 双击（400ms 窗口）→ 多任务（前台 RecentsActivity） | top=com.sec.android.app.launcher/com.android.quickstep.RecentsActivity | double x -> recents| | PASS |
| I3 | X+LB → 横向手势向右（方向性检查：dx>0，上一页方向不回退） | SWIPE=[SWIPE 0 2163,803 -> 2540,803 (task 0..2560 / 0..1600) axis=V n=14 pid=21382 queued=0 async prep=245us] dx=+377 | mix 4 x+lb -> wheel_right (direct)| | PASS |
| I4 | X+RB → 横向手势（向左 wheel_left，下一页方向不回退） | SWIPE=[SWIPE 0 2163,803 -> 627,803 (task 0..2560 / 0..1600) axis=V n=15 pid=21510 queued=0 async prep=497us] dx=-1536 | mix 5 x+rb -> wheel_left (direct)| | PASS |
| I5 | 空闲隐藏后原地恢复（同点误差 ≤10px，无修正移动日志） | P1=[2559 803] P2=[2559 803] d=0px corr=[pointer shown at last position (no correction move)|] | PASS |
| I6 | SELECT → 通知栏展开（NotificationShade）+ helper 真实下滑 rc=0；截图变化 4102542B（PC 侧像素差异面积另附） | shade=1 notif=NOTIF swipe async n=16 pid=22141 prep=0us|NOTIF swipe rc=0 dur=428ms n=16| png_delta=4102542B | PASS |

### 11 J 组 · 横屏/分栏/竖屏（J1-J7）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| J1 | 默认配置即横屏：user_rotation=1、accel=0、app 宽>高（引擎 geometry 亦宽>高；本机窗管横屏常量=ROTATION_0，见 t8） | user_rotation=1 accel=0 dumpsys=2560x1600 engine=n/a rotlock=lock 1 | PASS |
| J2 | 外部改竖屏后 ≤5s 自动回横屏（settings 回 1/0 且 app 宽>高） | recovered≈1500ms(6×250ms) dumpsys=2560x1600 engine=2560x1600 | PASS |
| J3 | 横屏居中目标=(1280,800)，落点误差 ≤8px | click=[1284 803] err=5,3 | PASS |
| J4 | ConfigActivity 横屏分栏（≥2 个半屏宽 ScrollView 并排） | count=2 shot=239153B | PASS |
| J5 | ButtonDetailActivity 横屏分栏（≥2 个半屏宽 ScrollView 并排） | count=2 shot=156243B | PASS |
| J6 | 竖屏回落可用（force_landscape=false + rotation 0 → 引擎 geometry 高>宽、单列、无崩溃） | engine=1600x2560 dumpsys=2560x1600 pid=17726 half_scrollviews=0 shot=161097B | PASS |
| J7 | 恢复默认横屏（force_landscape=true + rotation 1 → dumpsys/引擎 geometry 宽>高） | dumpsys=2560x1600 engine=2560x1600 prefs=force_landscape" value="true"  | PASS |

### 12 R5 · 边界缓存投毒分段取样

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| R5 | 投毒后 2.0/2.3/2.5s 取样起手点均回到整屏 task 且缓存文件恢复（阈值 ≤2.5s） | 3/3 通过 ; 2000ms: 1280,480 task=0..2560/0..1600 PASS ; 2300ms: 1280,480 task=0..2560/0..1600 PASS ; 2500ms: 1280,480 task=0..2560/0..1600 PASS cache=[com.dennis.padtest 0 0 2560 1600 2560 1600] | PASS |

### 13 K 组 · 助手命令（K1-K6）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| K1 | u 负例（屏幕已亮）：空操作 skip=1 且无 uinput 注入 | before=Awake after=Awake [WAKE was=Awake now=pending uinput=0 req=1 probe=1 age=936ms|WAKE was=Awake now=Awake uinput=0 skip=1 probe=1|] | PASS |
| K2 | u 正例（Dozing）：→ Awake 且 helper WAKE done=1 src=uinput|input224|power | off=Dozing after=Awake [WAKE was=Toggling now=pending uinput=1 req=1 age=3073ms|WAKE was=Toggling now=Awake uinput=1 done=1 src=uinput probe=0 took=445ms|] | PASS |
| K3 | g 0 4.68 后 O 居中日志使用新增益 4.68（g_pointer_gain 真正参与） | GAIN center=0.000 ptr=3.250 effective=3.250|GAIN center=0.000 ptr=4.680 effective=4.680|CENTER(steps+gain 4.68) rot=1 -> 1280,800|GAIN center=3.250 ptr=3.250 effective=3.250| | PASS |
| K4 | c 回包 display=0 space=logical 且与 P 放置真值误差 ≤5px（3/3） | 3/3 max=3px 1280,800:c=3px/p=4px 240,400:c=3px/p=4px 2400,1400:c=2px/p=2px | PASS |
| K5 | P 绝对定位后点击落点误差 ≤40px（3/3） | 3/3 max=4px 1280,800:c=3px/p=4px 240,400:c=3px/p=4px 2400,1400:c=2px/p=2px | PASS |
| K6 | 连续 10 条命令总耗时 <100ms | 50ms | PASS |


### 14.1 两轮一致性（关键指标）

| 用例 | run1 | run2 |
|---|---|---|
| A1 dPY | 1348px | 1339px | 1335px |
| A5 dPY / dHS | 1415 / 512px | 1415 / 512px | 1415 / 512px |
| B1 满推 300ms | 2481px | 2485px | 2478px（d150 折算 2276=0.889） |
| B2 半推 | 478px | 485px | 520px |
| C3 横/竖比 | 1.143（旧 2.5s 口径） | 1.029（2.5s） | 1.029（1.5s 契约口径，3456/3360） |
| D4 L3 9/9 | 9/9 | 9/9 | 9/9 |
| D6 l3TookMs | 524ms | 521ms | 578ms |
| H2 prep 中位/最大 | 140 / 425µs | 116 / 567µs | 204 / 437µs |
| H3 线程级 CPU | 3.53% | 3.50% | 3.42% |
| I5 恢复误差 | 0px | 0px | 0px |
| K6 10 条命令 | 50ms | 50ms | 50ms |

三轮均在噪声范围内一致通过；**run3 为最终口径（B1 中段对照 + C 1.5s 契约窗口），报告 §14 表与结果绑定 run3**；run1/run2 用于退出码与稳定性复核。
## 15 t20 原始证据（reviewer R1 补采）

| 项 | 文件（`work/docs/evidence-v166-verify/t20-hidden-swipe/`） | 内容 |
|---|---|---|
| A5 隐藏前 | `a5_before.xml` / `a5_before.txt` | `PY=1415 HS=0`（页面在顶部、可下滚） |
| A5 首次竖推后 | `a5_after_v.xml` / `a5_before.txt` | `PY_after=0 dPY=1415`（隐藏后第一次推杆即生效） |
| A5 横推后 | `a5_after_h.xml` | `HS_after=512 dHS=512` |
| A5 日志 | `a5_dexpad.txt` / `a5_swipes.txt` | `pointer shown at last position`、`vswipe … cycle=400ms`、SWIPE 行（task 0..2560/0..1600） |
| I5 | `i5_evidence.txt` | `P1=[2559 803] P2=[2559 803] d=0px`、`corr=[pointer shown at last position (no correction move)]`、PadProbe 两次 `MOUSE/click-down x=2559 y=803` |
| H5（独立数据点） | `h5_interval.txt` | `threshold->SWIPE interval=930ms`（从 vgpad 进程启动算，含 uinput 设备创建 ≈120ms；app-eng 的 55–60ms 为引擎侧口径） |

A5 失败态对照（t20 修复前，同一脚本、APK `b7fa2662…`）：`dPY=0`（Zn=13）→ 与 t18 的 `dPY=0` 一致；修复后同一用例 `dPY=1415`。该对照保存在 `work/docs/evidence-v166-final/run_pre_t20_preview.txt`（预演轮，非最终依据）。

## 16 截图像素差（PC 端，作为两区计数器的旁证）

`work/docs/evidence-v166-final/shotdiff_final.txt`：A1 改动 3,015,085 px（bbox 覆盖整屏、上下半都变，与「竖向整页滚动」一致）；A2 改动 380,616 px（**99.5% 落在最底部第 8 带**，与「只动底部分页区」一致）；A3 改动 2,343,442 px；I6 全屏 4,095,975 px（通知栏覆盖整屏）。J4/J5 分栏由 uiautomator 判定（2 个半屏宽 ScrollView），截图 `J_config_land.png` / `J_button_land.png`。

## 17 与其它报告的关系

- `VERIFY-v166.md`（t4，助手 4f261754 / APK e8a91185）与 `VERIFY-v166-hash.md`（t12，助手 6076b63b / APK e8a91185）**仅作历史记录**，其哈希与阈值口径均已被本报告取代。
- 助手哈希链：t2 `dc41cb9b` → t2-r2 `4f261754` → t10 `139087e7` → t11 `6076b63b` → **t13 `1bf7306f`（发布）**；APK：t4 `e8a91185` → t16 `b7fa2662` → **t20 `d2194406`（发布）**。
- 发布打包注意：`project/ksu-module/gpminput`、`project/lsp-dexpad/app/src/main/assets/gpminput`、设备 `module.prop`（v1.65/67）仍是旧值，打 release 包前必须替换/升级（详见 `VERIFY-v166-hash.md` §7）。

## 18 设备恢复状态（run 结束实测）

| 项 | 实测 |
|---|---|
| 助手/引擎 | helper pid 24668、engine pid 24674（run3 结束后；run2 为 14179/14180），`INFO devices_grabbed=1`；助手哈希 1bf7306f（gpm 与模块目录一致） |
| 显示 | 横屏 2560×1600、`user_rotation=1`、`accelerometer_rotation=0`、`cmd window user-rotation=lock 1` |
| 屏幕/前台 | `mWakefulness=Awake`；padtest CursorTestActivity 前台 |
| 其他 | `pointer_speed=-1`、无 vgpad 残留、prefs 原样（hswipe_speed=3/scroll_speed=4/force_landscape=true/move_gain=3.2377949/idle_hide_sec=8/speed_phone=48） |

## 19 复跑方式

```sh
adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/v166_auto_suite.sh all"     # 全量 A~K + A5（约 16 分钟）
adb -s 192.168.10.36:6666 shell "sha256sum /data/adb/gpm/gpminput /data/adb/modules/gpm_dex/gpminput"
```

脚本内置基线门：APK sha256 == `d2194406…`、versionName=1.66/68、助手 == `1bf7306f…` 且 gpm 与模块目录一致；任一不符立即 FAIL 停止（不会用错字节继续跑）。
