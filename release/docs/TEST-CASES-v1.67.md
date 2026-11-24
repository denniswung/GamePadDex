# TEST-CASES-v1.67 · LB/RB 滚动统一（+ 双击文案）用例表与证据摘要

> 判据同 v1.66：每条都有客观真机证据（helper 计数 / 内容位移 / 前台组件 / 时间戳），阈值可证伪。
> 本轮只改 `EngineService.kt`（LB/RB 机制二选一、连续滑动、滚轮锚点）与 `ButtonDetailActivity.kt`（320→400ms），
> 助手、输入注入、横屏、居中、串扰、打开应用等路径**未改**。

## 0 版本与字节

| 项 | 值 |
|---|---|
| 应用 | `com.dennis.dexpad` · versionName **1.67** / versionCode **69** |
| **发布 APK** | `release/dexpad-v1.67.apk` sha256 = **`8aeef7b7d6d5ea01b650a26e18c0eb8f0c4233f647a0cb0a17048be1e2180312`**（2678947 B，`assembleRelease`） |
| 验证用 APK（同源码，debuggable） | `df26e461bcfaf6243a50f0b6ee72e51a0d21eb0de0c74bf098a0422cfb3e3a9e`（3150079 B；t29 的 22 项跑在这个字节上） |
| 中间字节（历史） | `20eddf98…`（t22 初版）、`8ea4cb07…`（t26 第二轮）——只作演进记录，不用于发布 |
| **发布助手** | `release/gpminput-v1.67` sha256 = `1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf`（851928 B，**本轮未改助手**） |
| 模块 | `release/gpm_dex-v1.67.zip`（内含同一助手哈希），`module.prop` version=v1.67 / versionCode=69 |

> 与 v1.66 发布同样的口径：发布包是 `assembleRelease`（`debuggable=false`），app 的 `DEBUG`/`HCMD` 广播被
> `DebugReceiver.kt:21-22` 主动忽略，因此**机制开关**（`v_touch_scroll`）在发布字节上用「改 prefs XML + 重启引擎」验证，
> 而不是调试广播；A~K 全量里依赖广播的少数用例仍归 v1.66/t15（源码未改）。

## 1 执行方法

```bash
# t29 的 LB/RB 22 项（debug 变体 df26e461，会做字节绑定）
adb push work/scripts/v167_lbrb_verify.sh /data/local/tmp/
EXPECT_APK=df26e461bcfaf6243a50f0b6ee72e51a0d21eb0de0c74bf098a0422cfb3e3a9e \
  adb shell "su -c 'sh /data/local/tmp/v167_lbrb_verify.sh'"

# 发布字节（release 8aeef7b7）上的 12 项：哈希/版本/横屏 + LB/RB 双机制 + 400ms 文案
adb push work/docs/evidence-v167/verify_v167_release.sh /data/local/tmp/
adb shell "su -c 'sh /data/local/tmp/verify_v167_release.sh'"

# 发布字节回归冒烟（23 项）
adb shell "su -c 'sh /data/local/tmp/verify_v167_smoke.sh'"
```

原始证据：`work/docs/evidence-lbrb/verify-v167-t29.log`（22 行 PASS）、`work/docs/evidence-v167/verify_v167_release.result.txt`、
`work/docs/evidence-v167/verify_v167_smoke.result.txt`、`work/docs/LBRB-v167.md`、`work/docs/VERIFY-lbrb-v167.md`。

## 2 LB/RB 用例（t29，绑定 df26e461 + 助手 1bf7306f，22/22 PASS）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| BASE-APK | 设备 base.apk == t26 报告哈希 | `df26e461…3e3a9e` | PASS |
| BASE-HELPER | 助手 == `1bf7306f…` 且 gpm==模块 | 一致 | PASS |
| A-LB | 一次按压内 SWIPE>0 且 WHEEL=0（同按只一种机制，触屏=连续滑动） | SWIPE=6 WHEEL=0 `mode=swipe` | PASS |
| A-RB | 同上 | SWIPE=6 WHEEL=0 `mode=swipe` | PASS |
| B-RB | RB 1.5s（页顶起手）竖向位移 dPY ≥1000px（SWIPE≥6，记录锚点日志） | PY 1415→0 d=1415 SWIPE=6 `anchorPct=40 cands 40/60y x30/70 anchorX=1792 stroke=560` | PASS |
| B-LB | LB 1.5s（页底起手）dPY ≥1000px | PY 0→1415 d=1415 SWIPE=6 `anchorPct=60 stroke=560` | PASS |
| B-INT | 相邻滑动空档 ≤150ms（按 click-down 时间戳扣 220ms 手势） | n=6 maxgap=**150ms** gaps=[150 114 113 130 113] | PASS（贴边） |
| C-PTR | 指针可见且悬停在设置列表区域 | `CURSOR 1282 800 display=0 space=logical` | PASS |
| C-WHEEL | 滚轮模式 LB 1.5s：WHEEL ≥8 且 SWIPE=0 | WHEEL=9 SWIPE=0 `mode=wheel` | PASS |
| C-MOVE | 滚轮模式内容连续位移（系统设置同一文本节点前后差 ≥200px） | dSET=**921px**（9 步 wheel） | PASS |
| D-STABLE | 30s 多次按压机制不切换 | touch 5/5、wheel 5/5、切换 0 | PASS |
| E-SPEED | 滑动模式竖 1.5s 总位移 ≥3360px（v1.66 基线） | **n=6 total=3360px**（单条 560） | PASS |
| E-WHEEL | 滚轮模式 1.5s 等效步数 ≥8 | WHEEL=9 | PASS |
| F1 | X+LB 上一页：横向手势 dx>0 | dx=**+1263** | PASS |
| F2 | X+RB 下一页：dx<0 | dx=**−1257** | PASS |
| F3 | 右摇杆竖滚：Z≥4 且无 V/wheel | Z=6 V=0 wheel=0 | PASS |
| F4 | 右摇杆横滚：V≥1 且无 Z/wheel | V=3 Z=0 wheel=0 | PASS |
| F5 | d-pad 粘性导航 + A 注入 DPAD_CENTER | mouse_click=0 key_enter=1 | PASS |
| F6 | X 双击 400ms → 多任务 | top=…RecentsActivity | PASS |
| F7 | 空闲隐藏原地恢复 0px + 无修正移动 | P1=P2=[1277 799] d=0px `pointer shown at last position (no correction move)` | PASS |
| F8 | SELECT 通知栏展开（NotificationShade） | shade 计数 12（截图前后同尺寸，行为由 v1.66/t7 的 `NOTIF rc=0` 互补证明） | PASS |
| G-grep | `grep -E` 交替可用（规避 toybox `\|` 假 0） | 自检=2 | PASS |

### 2.1 t22 的 30s 长稳（历史样本，与 t29 的 5/5 短稳分开引用）

| 模式 | 30s 内 3 次 2s 按压 | app 日志 | 机制切换 |
|---|---|---|---|
| 触摸滚动开 | `swipe=24 wheel=0` | `mode=swipe` ×3 | 0 |
| 触摸滚动关 | `swipe=0 wheel=36` | `mode=wheel` ×3 | 0 |

### 2.2 三轮演进（为什么发布用 df26e461）

| 轮次 | APK | 结果 | 关键缺口 → 修复 |
|---|---|---|---|
| t22 初版 | `20eddf98` | t23 16/18 | B-RB、C-MOVE FAIL（滚轮只作用于悬停窗口；RB 锚点落到内层 ListView）→ t26 |
| t26 | `8ea4cb07` | 修滚轮锚点 + 自适应锚点 | E 组 3300px < 3360（锚点把纵向行程夹短：LB 540 / RB 460）→ t28 |
| **t28（发布）** | **`df26e461`** | **t29 22/22** | 行程恒 560px（锚点只决定起点，横向 30%/70% 交替），1.5s = **3360px** |

## 3 发布字节（release 8aeef7b7）上的抽检 12 项

脚本 `work/docs/evidence-v167/verify_v167_release.sh`；结果文件 `verify_v167_release.result.txt`（PASS=12 FAIL=0）。
**这一节是"发布出去的那个包"自己的证据**（不是 debug 变体）。

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| V167-APK | 设备 base.apk == 发布 `dexpad-v1.67.apk` | `8aeef7b7…2180312` | PASS |
| V167-HELPER | 助手 gpm == 模块 == 发布 `gpminput-v1.67` | `1bf7306f…f4bf` / 同 | PASS |
| V167-VER | versionName=1.67 / versionCode=69，module.prop v1.67/69 | `1.67/69` + `version=v1.67 versionCode=69` | PASS |
| V167-LAND | 默认横屏：user_rotation=1、accel=0、app 2560×1600 | `rot=1 accel=0 app=2560x1600` | PASS |
| V167-LB-SWIPE | 触屏模式 LB 1.5s：SWIPE≥5、WHEEL=0、`mode=swipe` | SWIPE=6 WHEEL=0 dPY=1415 | PASS |
| V167-RB-SWIPE | 触屏模式 RB 1.5s：同上 | SWIPE=6 WHEEL=0 dPY=1415 | PASS |
| V167-RB-MOVE | 触屏模式内容确实滚动（dPY>0） | dPY=1415（PY 1415→0） | PASS |
| V167-VT-OFF | release 包上把 `v_touch_scroll` 设为 false 并生效（改 prefs + 重启引擎，不用调试广播） | `vtouch=false`，engine pid 21610 | PASS |
| V167-LB-WHEEL | 滚轮模式 LB 1.5s：WHEEL≥6、SWIPE=0、`mode=wheel` | SWIPE=0 WHEEL=9 | PASS |
| V167-RB-WHEEL | 滚轮模式 RB 1.5s：同上 | SWIPE=0 WHEEL=9 | PASS |
| V167-RESTORE | 恢复 `v_touch_scroll=true`（默认安装态） | `vtouch=true`，engine/helper 均在 | PASS |
| V167-DBLTEXT | ButtonDetail 双击说明为 400 ms | 真机文本 `连续按两下 A（400 ms 内）时触发` | PASS |

> 说明：发布包上切机制用 `sed` 改 `/data/misc/*/prefs/com.dennis.dexpad/dexpad.xml` 后 `am force-stop` +
> `am start-foreground-service .EngineService` 重启引擎（app 自己的存储，非调试通道），因此**两种机制都在发布字节上实测过**，
> 不是只引用 debug 变体。

## 4 发布字节回归冒烟（23 项，`verify_v167_smoke.sh`）→ **PASS=23 FAIL=0**

覆盖 v1.66 的 5 修 3 功能与 6 项不得回退，全部在发布字节 `8aeef7b7` 上重跑（脚本与 v1.66 相同，仅把期望 APK/版本改为 1.67/69）：

| 组 | 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|---|
| RS0-APK | 设备 base.apk == 发布 APK | `8aeef7b7…2180312` | 同（2678947 B） | PASS |
| RS0-VER | versionName=1.67 / versionCode=69 | — | `1.67 / 69` | PASS |
| RS0-HELPER | gpm == 模块 == 发布助手 | `1bf7306f…f4bf` | 两处一致 | PASS |
| RS0-LAND | 默认横屏 user_rotation=1/accel=0/app 宽>高 | — | `rot=1 accel=0 app=2560x1600 engine=2560x1600` | PASS |
| RS1-L3 | L3 落点距 (1280,800) ≤40px 且 A=鼠标点击 | — | click=1281,799（1px）mouse_click=1 key_enter=0 | PASS |
| RS2-MOVE | 满推左摇杆 300ms 后落点右移 ≥1000px | — | click=2559,799（dx=+1279） | PASS |
| RS3-V | 竖推 1.5s 页面下移 ≥1000px 且 helper 仅 Z | — | PY 1415→0 d=1415 Zn=4 Vn=0 | PASS |
| RS3-H | 横推 1.5s 分页位移 ≥400px 且 helper 仅 V | — | HS 0→512 Vn=3 Zn=0 | PASS |
| RS4-HIDDEN | 空闲隐藏后首次竖推仍滚页 ≥1000px | — | POINTER off 0→1、设备不存在、dPY=1415 | PASS |
| RS4-HIDDEN-H | 隐藏首推后横推 ≥400px | — | dHS=512 | PASS |
| RS5-YUP | Y+上 → PiliPlus | — | top=com.example.piliplus/.MainActivity | PASS |
| RS5-YDOWN | Y+下 → 抖音 | — | top=com.ss.android.ugc.aweme/.splash.SplashActivity | PASS |
| RS6-I1 | d-pad 粘性 + A 注入 DPAD_CENTER | mouse_click=0 key_enter≥1 | 0 / 1 | PASS |
| RS6-I1B | 摇杆后 A 恢复鼠标点击 | mouse_click≥1 key_enter=0 | 1 / 0 | PASS |
| RS6-I2 | X 双击 → Recents | — | …RecentsActivity | PASS |
| RS6-I3 | X+LB → dx>0 | — | dx=+651（1889,800→2540,800） | PASS |
| RS6-I4 | X+RB → dx<0 | — | dx=−1536（1889,800→353,800） | PASS |
| RS6-I5 | 空闲隐藏原地恢复 ≤10px + 无修正移动 | — | P1=P2=[1916 799] d=0px | PASS |
| RS6-I6 | SELECT → NotificationShade + 真实下滑 rc=0 | — | shade=1 `NOTIF swipe rc=0 dur=391ms` | PASS |
| RS7-GUARD | 外部改竖屏后 ≤5s 回横屏 | ≤5000ms | recovered≈2000ms | PASS |
| RS8-CPU | 60s 空闲进程级 CPU（release） | 记录并与 v1.65 同口径 | **0.93%**（线程 0.93%、cutime+cstime 0.00%） | PASS |
| RS8-Q | 60s 空闲光标查询 ≤15 次 | ≤15 | CURSORQ=0 CURSOR=0 | PASS |
| RS8-TICK | 引擎帧耗时日志存在 | — | `perf tick avg=36–40µs max=2.0–3.0ms` | PASS |

> 与 v1.66 的 release 测量（0.82%）相比，本轮 0.93% 属同量级噪声；两者都远低于 v1.65 的 1.62%，"CPU 不回退"结论保持。

## 5 回归结论

- LB/RB 之外**代码未改**（`git diff` 仅 `EngineService.kt` + `ButtonDetailActivity.kt`），v1.66 的 A~K 68/68 与 t7 的 release 冒烟 23/23 仍然有效；
- 本轮 t29 的 F1–F8 又把 6 项不得回退在**新字节**上重验了一遍（X+LB/RB、右摇杆竖横、DPAD_CENTER、Recents、隐藏恢复、通知栏）；
- 助手字节未变（`1bf7306f`），`?` 自检语义、`u`/`g`/`c`/`P` 命令、串行队列均沿用 v1.66 证据。

## 6 已知贴边项（如实记录）

- **B-INT maxgap=150ms** 恰好等于阈值（≤150ms）。t22 的另一组样本是 30–38ms；发布说明写 **250–259ms 周期 / 30–39ms 典型空档，最坏 150ms**，不写"30–38ms"当普遍值。
- **C-MOVE** 的位移证据来自系统设置（多显示设备上 uiautomator 默认附 display 0，靠同一文本节点前后 921px）；padtest 内层列表 #001→#006 为旁证。
- **F8** 在 t29 里截图前后尺寸相同（通知栏在同一 display 上未反映到 screencap），行为以 `NotificationShade` 焦点计数与 v1.66/t7 `NOTIF swipe rc=0` 为准。

## 7 复跑

```bash
# 发布字节 12 项
adb shell "su -c 'sh /data/local/tmp/verify_v167_release.sh'"
# 发布字节 23 项冒烟
adb shell "su -c 'sh /data/local/tmp/verify_v167_smoke.sh'"
# 装机校验表
adb push work/docs/evidence-v167/verify_install.sh /data/local/tmp/ && adb shell "sh /data/local/tmp/verify_install.sh"
```
