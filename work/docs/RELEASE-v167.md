# RELEASE-v167 · v1.67 集成发布报告（integrator / t25）

> 目标：版本 1.66→1.67（versionCode 68→69）、重建发布包、助手副本对齐、文档/用例表/SHA256SUMS、
> 备份、GitHub Release、哈希级装机校验（含重启后）。
> 设备：SM-F9360（Android 16），adb `192.168.10.36:6666`，app 空间 2560×1600（`dumpsys display` rotation 1）。

## 1 版本

| 项 | 值 | 校验 |
|---|---|---|
| `project/lsp-dexpad/app/build.gradle.kts` | `versionCode = 69` / `versionName = "1.67"` | 从 68/1.66 递增，未跳号 |
| `project/ksu-module/module.prop` | `version=v1.67` / `versionCode=69` | 仓库 + 设备两处 |
| `work/scripts/set_version.py` | `VER="1.67" / CODE=69` | 与本版一致 |
| 设备安装后 | `versionName=1.67` / `versionCode=69` | `dumpsys package com.dennis.dexpad` |
| 设备模块 | `version=v1.67` / `versionCode=69` | 重启后 `grep version /data/adb/modules/gpm_dex/module.prop` |

## 2 构建（clean assembleRelease）

```
cd project/lsp-dexpad
JAVA_HOME=/home/denniswung/jdk17 ANDROID_HOME=/home/denniswung/android-sdk \
  ./gradlew --no-daemon --no-build-cache clean assembleRelease
# BUILD SUCCESSFUL，产物 output-metadata.json: versionCode=69 / versionName=1.67
```

- 产物 `release/dexpad-v1.67.apk`（2678947 B）；`release/gpminput-v1.67`（851928 B）；`release/gpm_dex-v1.67.zip`（362092 B）。
- 模块 zip 重新打包（`gpminput / inject.dex / module.prop / post-fs-data.sh / service.sh`），`module.prop` 为 v1.67/69。
- **助手未改**（t22/t26/t28 只改 `EngineService.kt` + `ButtonDetailActivity.kt`），三处副本（`project/ksu-module/gpminput`、
  `project/lsp-dexpad/app/src/main/assets/gpminput`、`project/app/src/main/assets/gpminput`）仍是 `1bf7306f…`；
  APK 内 `assets/gpminput` 解包哈希 = `1bf7306f…`，与发布助手/zip 内完全一致。

## 3 发布资产（与 `release/SHA256SUMS.txt` 一致，76 行、不含自身）

| 资产 | sha256 | 大小 |
|---|---|---|
| `dexpad-v1.67.apk` | `8aeef7b7d6d5ea01b650a26e18c0eb8f0c4233f647a0cb0a17048be1e2180312` | 2678947 B |
| `gpm_dex-v1.67.zip` | `b39af5c500055568331b4acbe0d755510306e686d24c94d1d05eaaf9a58c0f19` | 362092 B |
| `gpminput-v1.67` | `1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf` | 851928 B |
| `padtest-v1.1.apk` | `27478cef1c51acddc88c7ef662980ead4720bc95ce38635b0aa816f67de32e50` | 949222 B |

**哈希链**

```
APK:    e8a91185 (t4/t8) → b7fa2662 (t16) → d2194406 (t20) → 73477eca (v1.66 release)
        → df26e461 (t28, debug 字节, t29 的 22 项跑这个) → 8aeef7b7 (v1.67 release)
helper: 4f261754 → 139087e7 (t10) → 6076b63b (t11) → 1bf7306f (v1.66 起未变，v1.67 沿用)
```

> 与 v1.66 相同的口径：发布包是 `assembleRelease`（debuggable=false），与 t29 验证的 debug 字节 `df26e461` 只差构建变体
> + `assets/gpminput`（本轮没变）。因此**发布字节上另外做了 12 项专项抽检 + 23 项回归冒烟**（§4）。

## 4 装机 + 重启验证（摘要，完整表见 `work/docs/INSTALL-v167.md`）

| 步骤 | 实测 |
|---|---|
| `adb install -r release/dexpad-v1.67.apk` | Success；`versionName=1.67` / `versionCode=69` |
| `ksud module install gpm_dex-v1.67.zip` | `Installing to /data/adb/modules_update/gpm_dex` → `Module installed successfully!`（module.prop v1.67/69） |
| `adb reboot` 后 | `version=v1.67 versionCode=69`；`/data/adb/gpm/gpminput` = 模块目录 = `1bf7306f…`；helper pid=12636、engine pid=13450（后续会话 22455/22420）；`mWakefulness=Awake` |
| base.apk | `8aeef7b7…2180312`（2678947 B）== 本地 `release/dexpad-v1.67.apk` |
| 横屏 | `dumpsys display` rotation 1 / app **2560×1600**；`user_rotation=1`、`accelerometer_rotation=0`、`cmd window user-rotation=lock 1` |
| 鼠标 | release 冒烟 RS2-MOVE 满推 300ms → 落点 `2559,799`（dx=+1279）；RS1-L3 `1281,799`（1px） |

## 5 发布字节（release）验证

### 5.1 LB/RB 专项 + 文案（`work/docs/evidence-v167/verify_v167_release.sh`）→ **12/12 PASS**

- 触屏模式（`v_touch_scroll=true`，默认）：LB `SWIPE=6/WHEEL=0` dPY=1415、RB `SWIPE=6/WHEEL=0` dPY=1415，`mode=swipe`。
- 滚轮模式（release 包上用「改 prefs XML + 重启引擎」，因为调试广播被忽略）：LB/RB 均 `SWIPE=0/WHEEL=9`，`mode=wheel`。
- 恢复默认 `v_touch_scroll=true`；ButtonDetail 真机文本 `连续按两下 A（400 ms 内）时触发`。
- 基线：APK/助手/版本/横屏四项全 PASS。

### 5.2 回归冒烟（`work/docs/evidence-v167/verify_v167_smoke.sh`，23 项）→ **PASS=23 FAIL=0**

L3 1281,799（A=鼠标点击）、满推 2559,799、竖推 dPY=1415（仅 Z）、横推 dHS=512（仅 V）、空闲隐藏首推 dPY=1415、
Y+上 PiliPlus / Y+下 抖音、d-pad+DPAD_CENTER、X 双击 Recents、X+LB dx=+651、X+RB dx=−1536、I5 0px、
SELECT `NOTIF rc=0 dur=391ms`、横屏守护 ≈2000ms、60s 空闲 CURSORQ=0。

### 5.3 60s 进程级 CPU（release，同口径）

| 版本 | 进程级 `utime+stime` | 线程级 | `cutime+cstime` |
|---|---|---|---|
| v1.67（8aeef7b7） | **0.93%** | 0.93% | 0.00% |
| v1.66（73477eca，t7） | 0.82% | 0.80% | 0.00% |
| v1.65（ec79e94a，t7） | 1.62% | 1.58% | 0.00% |

结论：v1.67 与 v1.66 同量级（0.93% vs 0.82%，属噪声），仍显著低于 v1.65，**CPU 不回退**结论保持。
帧耗时 `perf tick avg=36–40µs max=2.0–3.0ms`（v1.66 为 33–43µs / 2.1–3.9ms）。

## 6 文档 / 用例表 / 备份

| 产物 | 说明 |
|---|---|
| `README.md` | 当前版本 v1.67；`§2` 写入 LB/RB 新规则（触摸开=连续滑动 220ms/560px/250ms 周期、触摸关=纯滚轮 186ms/步 9 步、机制按下定死、滚轮锚点、X+LB/RB 不变）；`§3`/`§4` 安装文件名；`§8` 测试表新增 v1.67 两项；`§9` 新增 LB/RB 空档贴边（150ms）与滚轮适用范围 caveat、400ms 文案已修；`§10` 新增 v1.67 行 |
| `docs/TEST-CASES-v1.67.md` | LB/RB 22 项（t29 表）+ t22 30s 长稳 + 三轮演进 + 发布字节 12 项 + 发布字节 23 项 + 回归结论 + 贴边项 |
| `release/RELEASE-NOTES.md`、`docs/RELEASE-NOTES.md` | v1.67 发布说明（规则表、锚点/滚轮细节、验证数字、caveat、安装步骤、哈希表） |
| `work/docs/INSTALL-v167.md` | 装机校验表 22 行（APK / 助手三处 / zip 内 / APK assets / 重启后 / 横屏 / LB-RB 双机制 / 文案 / CPU） |
| `release/docs/TEST-CASES-v1.67.md`、`v167_verify_release.sh`、`v167_verify_smoke.sh` | 发布目录内的用例与复跑脚本副本 |
| `backup/self-backup/GamePadDex-v1.67-20261124-1413.zip` | **68.09 MB**（71395594 B），sha256 `651d113c454ff19b47281b0dd4c18748ee9d9b8aac1aae3e539cd2cab9a1c03a`，1310 条目；含源码（`project/**/src`、gradle 配置）、`docs/`、`release/`、`work/scripts`、`work/docs`；不含 build/.gradle/.git/backup |

`release/SHA256SUMS.txt` 已重生成（76 行，排除自身），逐行自检 mismatch=0。

## 7 GitHub

| 项 | 值 |
|---|---|
| 推送 | `git push` 直连 github.com:443 在本环境不稳定，沿用 t7 的 **Git Data API** 方案（`work/docs/evidence-v166-install/push_via_api.py`：blob→tree→commit→ref），并校验 **远端 tree == 本地 HEAD tree** |
| 标签 / Release | tag **v1.67**；https://github.com/denniswung/GamePadDex/releases/tag/v1.67 （非 draft / 非 prerelease） |
| 资产 | `dexpad-v1.67.apk`、`gpm_dex-v1.67.zip`、`gpminput-v1.67`、`padtest-v1.1.apk`、`SHA256SUMS.txt`；重新下载后逐个 sha256 与本地一致 |

## 8 残留偏差（如实记录，不阻塞发布）

1. **t29 的 22 项跑在 debug 字节 `df26e461`**（同源码）。发布字节 `8aeef7b7` 另做 12 项专项 + 23 项回归冒烟；两套脚本、两套证据都在仓库里。
2. **B-INT 贴边**：t29 最坏空档 150ms（阈值 ≤150ms），t22 另一组样本 30–38ms。发布说明写"典型 30–39ms、最坏 150ms"，不写成普适 30–38ms。
3. **F8（SELECT）** 在 t29 里 `screencap` 前后同尺寸（多显示设备 screencap 只附 display 0），行为以 `NotificationShade` 计数与 v1.66/t7 的 `NOTIF swipe rc=0` 互补证明；v1.67 发布字节冒烟里 SELECT 已独立 PASS（`shade=1`、`rc=0 dur=391ms`）。
4. **滚轮适用范围**：`REL_WHEEL` 只作用于指针悬停窗口；`ensureWheelAnchor` 已缓解空闲隐藏场景，但若目标列表不在 task 中心仍可能滚不动（README 已写）。
5. ButtonDetail 文案在 v1.67 已改为 400ms；t22 的 `20eddf98`、t26 的 `8ea4cb07` 只作演进记录，不用于发布。
6. `display_size_forced=1600,2560` 仍清不掉（v1.66 起的 caveat，横屏 = rotation 1 + 应用逻辑空间 2560×1600）。

## 9 acceptance 对照（t25 合同）

| # | 要求 | 结果 | 证据 |
|---|---|---|---|
| 1 | 版本递增 v1.66→v1.67（68→69），同步 build.gradle.kts / module.prop（仓库与设备），不跳号不重号 | PASS | §1、`INSTALL-v167.md` #1/#11 |
| 2 | 打包前把两处助手副本与 `project/app` 副本全部对齐当前最终助手哈希 | PASS | §2、`INSTALL-v167.md` #8（三处 `1bf7306f`） |
| 3 | release/ 产出 APK / 模块 zip / 助手 / padtest 沿用 / SHA256SUMS（内容一致） | PASS | §3（76 行、自检 mismatch=0） |
| 4 | 装机 + reboot：base.apk == 本地 APK、助手同哈希、module.prop v1.67/69、自启/鼠标/横屏 | PASS | §4、`INSTALL-v167.md` #2–#17 |
| 5 | README 版本历史（含 LB/RB 统一说明与机制选择规则）、docs/TEST-CASES-v1.67.md、release/RELEASE-NOTES.md | PASS | §6 |
| 6 | 备份包 `GamePadDex-v1.67-<stamp>.zip`，大小记录 | PASS | §6（68.09 MB，sha256 `651d113c…`） |
| 7 | GitHub Release v1.67 资产齐全，哈希与本地一致 | PASS | §7 |
| 8 | `work/docs/INSTALL-v167.md` 装机校验表 | PASS | 该文件 22 行 |
