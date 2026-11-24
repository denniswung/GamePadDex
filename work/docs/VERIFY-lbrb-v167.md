# VERIFY-lbrb-v167 · LB/RB 机制互斥 / 连续性 / 速度 / 回归（最终复验）

> 任务 t29（verification round 3）· 设备 SM-F9360（adb `192.168.10.36:6666`，横屏 2560×1600）
> **结论：PASS=22 / FAIL=0 → 通过**（t27 的唯一 FAIL E-SPEED 已由 t28 闭环：3300→**3360px**）
> 原始证据：`work/docs/evidence-lbrb/` — `verify-v167-t29.log`、`console-v167-t29.txt`、`raw-v167-t29/`；历史轮次 `verify-v167.log`、`raw-v167/`

## 0 绑定与环境（本报告 = 发布依据）

| 项 | 值 |
|---|---|
| 应用 APK sha256 | **`df26e461bcfaf6243a50f0b6ee72e51a0d21eb0de0c74bf098a0422cfb3e3a9e`**（设备 `base.apk` == 本机 `app-debug.apk`；契约的 `gradlew assembleDebug` 重跑产物同哈希；versionName=1.66 / versionCode=68） |
| 助手 sha256 | **`1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf`**（`/data/adb/gpm` == `/data/adb/modules/gpm_dex`） |
| 屏幕 / 唤醒 | 2560×1600、Awake、user_rotation=1、accelerometer_rotation=0、无 vgpad |
| prefs | `v_touch_scroll`（脚本内切换）、`mode_on=true`、`enabled=true` |
| 脚本 | `work/scripts/v167_lbrb_verify.sh` + `run_v167_lbrb.sh`（`EXPECT_APK`/`EXPECT_HELPER` 门 + `G-grep` 自检） |

**采样期间字节未变**：开跑前与结束后各核对一次 APK/助手哈希；`BASE-APK`、`BASE-HELPER` 两行 PASS（不匹配会 exit 9）。

## 1 全量结果（22/22 PASS）

| 用例 | 阈值 | 实测 | 判定 |
|---|---|---|---|
| A-LB 互斥 | SWIPE>0 且 WHEEL=0 | SWIPE=6（Z=6）/WHEEL=0，`mode=swipe` | PASS |
| A-RB 互斥 | SWIPE>0 且 WHEEL=0 | SWIPE=6（Z=6）/WHEEL=0，`mode=swipe` | PASS |
| B-RB 页顶 | dPY ≥1000 | **PY 1415→0，d=1415**，6 SWIPE，`anchorPct=40 (cands 40/60y x30/70) anchorX=1792` | PASS |
| B-LB 页底 | dPY ≥1000 | **PY 0→1415，d=1415**，6 SWIPE，`anchorPct=60 (cands 40/60y x30/70)` | PASS |
| B-INT 空档 | ≤150ms | n=6，gaps 150/114/113/130/113ms（扣 220ms 手势），max **150ms**（贴边通过） | PASS |
| B-RB 中段（记录） | — | PY 655→0，d=655（理论上限 min(655,759)） | 记录 |
| C-PTR 指针 | x∈[100,2460]、y∈[300,1300] | `CURSOR 1282 800 display=0 space=logical` | PASS |
| C-WHEEL | WHEEL≥8 且 SWIPE=0 | **WHEEL=9**、SWIPE=0，`mode=wheel` | PASS |
| C-MOVE | dSET ≥200px | **dSET=921px**（设置列表、wheel、无点击；`raw-v167-t29/C2_before/after.txt`） | PASS |
| D 不切换 | 切换=0 | 触屏 5/5、滚轮 5/5，bad=0 | PASS |
| **E-SPEED** | **≥3360px/1.5s** | **n=6，total=3360px**（单条 560px） | PASS |
| E-WHEEL | ≥8 步 | 9 步/1.5s | PASS |
| F1 X+LB | dx>0 | dx=**+1263** | PASS |
| F2 X+RB | dx<0 | dx=**−1257** | PASS |
| F3 右摇杆竖滚 | Z≥4、V=0、wheel=0 | Z=6、V=0、wheel=0 | PASS |
| F4 右摇杆横滚 | V≥1、Z=0、wheel=0 | V=3、Z=0、wheel=0 | PASS |
| F5 d-pad+DPAD_CENTER | key_enter≥1、mouse_click=0 | key_enter=1、mouse_click=0 | PASS |
| F6 X 双击 400ms | Recents | `com.sec.android.app.launcher/com.android.quickstep.RecentsActivity` | PASS |
| F7 空闲隐藏恢复 | 0px + no correction | P1=P2=[1277 799]，d=0px，`pointer shown at last position (no correction move)` | PASS |
| F8 SELECT 通知栏 | NotificationShade | 命中 12 处；截图 `raw-v167-t29/lbrb_before/after.png` | PASS |
| G-grep | `grep -E` 可用 | 自检=2（规避 toybox 不支持 `\|` 的假 0） | PASS |
| BASE-APK / BASE-HELPER | 哈希绑定 | 见 §0 | PASS |

## 2 三轮演进（供 reviewer/t7 对照）

| 轮次 | APK | 结果 | 关键差异 |
|---|---|---|---|
| t23（v166 报告） | 20eddf98 | 16/18，B-RB、C-MOVE FAIL | wheel 未验证内容位移；RB 锚点被底部子视图拦截 |
| t27（本文件前一轮） | 8ea4cb07 | 21/22，E-SPEED 3300<3360 | t26 修好 wheel 锚点与 RB 锚点；E 因 540/560 交替差 1.8% |
| **t29（本表）** | **df26e461** | **22/22** | t28 把纵向行程固定 560px（横向 30%/70% 交替），E=3360 |

## 3 关键证据文件

| 文件（`work/docs/evidence-lbrb/`） | 内容 |
|---|---|
| `verify-v167-t29.log` / `console-v167-t29.txt` | 22 行逐条判定（阈值/实测/判定）与运行日志 |
| `raw-v167-t29/A_LB_helper.log`、`A_RB_helper.log` | A 组原始 helper.log（各 6 条 SWIPE、0 条 WHEEL） |
| `raw-v167-t29/B_intervals.txt` | 手势 click-down 空档（max 150ms） |
| `raw-v167-t29/B_rb_mid.txt` | 中段记录（d=655，理论上限 759） |
| `raw-v167-t29/C2_before.txt` / `C2_after.txt` | 设置列表 wheel 前后（dSET=921，无点击） |
| `raw-v167-t29/lbrb_before.png` / `lbrb_after.png` | SELECT 通知栏截图 |

## 4 设备恢复

`v_touch_scroll=true`、`mode_on=true`、`enabled=true`；横屏 2560×1600、Awake、rotation=1/accel=0、无 vgpad、helper 4948 + engine 4907、padtest ScrollTestActivity 前台。

## 5 复跑

```sh
adb -s 192.168.10.36:6666 push work/scripts/v167_lbrb_verify.sh work/scripts/run_v167_lbrb.sh /data/local/tmp/
adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/run_v167_lbrb.sh"     # 输出 v167_console.txt / v166_lbrb.log / lbrb_raw/
wsl -d Ubuntu-24.04 -e bash -c "cd '/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad' && JAVA_HOME=~/tools/jdk-17.0.20.1+1 ANDROID_HOME=~/android-sdk ./gradlew --no-daemon --no-build-cache assembleDebug"
adb -s 192.168.10.36:6666 shell "ps -A -o PID,NAME | grep -c vgpad"       # 0
```
