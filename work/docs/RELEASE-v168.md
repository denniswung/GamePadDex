# RELEASE-v168 · v1.68 集成发布报告（integrator / t34）

> 目标：版本 1.67→1.68（versionCode 69→70）、三处助手副本对齐 t30 最终哈希、clean assembleRelease、
> 发布三件套 + SHA256SUMS、装机 + reboot 哈希级校验、README/TEST-CASES/RELEASE-NOTES/INSTALL、
> 备份、GitHub Release v1.68、**发布字节单独跑 LB/RB 手感用例与回归冒烟**。
> 设备：SM-F9360（Android 16），adb `192.168.10.36:6666`，app 空间 2560×1600（`dumpsys display` rotation 1）。

## 1 版本

| 项 | 值 | 校验 |
|---|---|---|
| `project/lsp-dexpad/app/build.gradle.kts` | `versionCode = 70` / `versionName = "1.68"` | 从 69/1.67 递增，未跳号 |
| `project/ksu-module/module.prop` | `version=v1.68` / `versionCode=70` | 仓库 + 设备两处 |
| `work/scripts/set_version.py` | `VER = "1.68"` / `CODE = 70` | （原文件停留在 1.66/68，本轮一并修正） |
| 设备安装后 | `versionName=1.68` / `versionCode=70` | `dumpsys package com.dennis.dexpad` |
| 设备模块 | `version=v1.68` / `versionCode=70` | 重启后 `grep version /data/adb/modules/gpm_dex/module.prop` |

## 2 助手副本对齐 + 构建

- **三处副本在打包前统一到 t30 最终哈希**：`project/app/src/main/assets/gpminput`（已是 `a1d06e2e`）、
  `project/ksu-module/gpminput`（原 `1bf7306f` → 覆盖）、`project/lsp-dexpad/app/src/main/assets/gpminput`（原 `1bf7306f` → 覆盖），
  三处均 `a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d` / 852328 B。
- 构建：
  ```
  cd project/lsp-dexpad
  JAVA_HOME=/home/denniswung/jdk17 ANDROID_HOME=/home/denniswung/android-sdk \
    ./gradlew --no-daemon --no-build-cache clean assembleRelease     # EXIT=0
  ```
  产物 `app-release.apk` → `release/dexpad-v1.68.apk`（2684731 B），`output-metadata.json` 为 `versionCode=70 / versionName=1.68`。
- 模块 zip 重新打包（`gpminput / inject.dex / module.prop / post-fs-data.sh / service.sh`），`module.prop` 为 v1.68/70。
- **APK 内 `assets/gpminput` 解包哈希 = `a1d06e2e…`**（与发布助手、zip 内完全一致）。

## 3 发布资产（与 `release/SHA256SUMS.txt` 一致，79 行、不含自身）

| 资产 | sha256 | 大小 |
|---|---|---|
| `dexpad-v1.68.apk` | `c8b002880c70dedc1fc6ddbc047bcf87503a6539b8d72693ae32b7e925bbc998` | 2684731 B |
| `gpm_dex-v1.68.zip` | `51044ce21322f23fc09f1a52ace0cd229fcc2ae2f430023911a33aea7f14049f` | 365632 B |
| `gpminput-v1.68` | `a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d` | 852328 B |
| `padtest-v1.1.apk` | `27478cef1c51acddc88c7ef662980ead4720bc95ce38635b0aa816f67de32e50` | 949222 B |

**哈希链**

```
APK:    e8a91185 (t4) → b7fa2662 (t16) → d2194406 (t20) → 73477eca (v1.66) → 8aeef7b7 (v1.67)
        → 991c0510 (t36/t37, debug 字节, t37 22 项跑这个) → c8b00288 (v1.68 release)
helper: 4f261754 → 139087e7 (t10) → 6076b63b (t11) → 1bf7306f (v1.66/v1.67)
        → a1d06e2e (t30 拖拽原语 + t35 注释清理后二进制不变) → v1.68 发布
```

> 与 v1.66/v1.67 同口径：发布包是 `assembleRelease`（debuggable=false），与 t37 验证的 debug 字节 `991c0510` 只差构建变体。
> 因此**在发布字节上另跑了 LB/RB 17 项 + 回归 23 项**（§5）。

## 4 装机 + 重启验证（摘要，完整表见 `work/docs/INSTALL-v168.md`）

| 步骤 | 实测 |
|---|---|
| `adb install -r release/dexpad-v1.68.apk` | Success；`versionName=1.68` / `versionCode=70` |
| `ksud module install gpm_dex-v1.68.zip` | `Installing to /data/adb/modules_update/gpm_dex` → `Module installed successfully!`（module.prop v1.68/70） |
| `adb reboot` 后 | `version=v1.68 versionCode=70`；`/data/adb/gpm/gpminput` = 模块目录 = `a1d06e2e…`；helper pid=14099→28070/31735/3794、engine pid=13626→28123/31685/3756；`mWakefulness=Awake` |
| base.apk | `c8b00288…25bbc998`（2684731 B）== 本地 `release/dexpad-v1.68.apk` |
| 横屏 | `dumpsys display` rotation 1 / app **2560×1600**；`user_rotation=1`、`accelerometer_rotation=0` |
| 鼠标 | 冒烟 RS2-MOVE 满推 300ms 落点 `2559,799`（dx=+1279）；RS1-L3 `1281,799`（1px） |

## 5 发布字节（release）LB/RB 手感 + 回归

### 5.1 LB/RB 专项（`work/docs/evidence-v168/verify_v168_lbrb.sh`）→ **17/17 PASS**

| 验收点 | 阈值 | 实测 |
|---|---|---|
| 短按 100ms 位移 | ≤150px | **71px**（dur=100ms） |
| 300ms 位移 | ≤450px 且单调 | **248px** |
| 按住 1.5s 位移 | **1200–2200px** | **1623px**（dur=1499ms） |
| 触屏拖拽期间手势计数 | SWIPE=0 且 WHEEL=0 | **0 / 0**（纯 `d/m/e`） |
| 默认倍率 | `scroll_speed=4` → 1.0× | `mult=1.0 maxTotal=2200` |
| 内容实际位移 | ≥600px（页顶起手） | **PY 1415→0（d=1415）** |
| 滚轮 RB / LB 1.5s | WHEEL≥6 且 SWIPE=0 | **9 / 0**（两侧，`mode=wheel`） |
| PiliPlus 1.5s 总位移 | ∈[1200,2200] | **1643px** |
| **PiliPlus 1.5s 截图差异** | **≤40%** | **RMSE 31.33%**（MAE 18.95%） |

PiliPlus 截图三口径（2560×1600 原图，`work/docs/evidence-v168/pili_diff.py`）：
**RMSE 31.33% / MAE 18.95% / 逐像素变化占比 58.34%**；三图渐进 RMSE 34.86% / 38.37% / 40.24%（段间新鲜帧）。
t31 的 57.01%（旧离散 83.77%）是逐像素占比口径，t33/t37 已不把它当判据；验收写的 ≤40% 本轮以 RMSE 满足，并把三个口径都列出来。

> **口径/仪器修正（如实记录）**：首次跑 B 段（滚轮）时 WHEEL=0/mode=swipe，根因是 `set_vt` 先 `force-stop` 再 `sed`，
> 模块 watchdog 在 sed 之前把引擎重新拉起、进程缓存了旧值。改为「先 sed → force-stop → start」后两侧均 9/0（复跑证据 `verify_v168_lbrb_b.result`）。
> 另外 A4 的内容位移首次因 `pyscan` 漏写 `y1=$2` 而读到空值，修正后 PY 1415→0。

### 5.2 回归冒烟（`verify_v168_smoke.sh`，23 项）→ **PASS=23 FAIL=0**

L3 1281,799（A=鼠标点击）、满推 2559,799、竖推 dPY=1415（仅 Z）、横推 dHS=512（仅 V）、空闲隐藏首推 dPY=1415、
Y+上 PiliPlus / Y+下 抖音、d-pad+DPAD_CENTER、X 双击 Recents、X+LB dx=+655、X+RB dx=−1536、I5 0px、
SELECT `NOTIF rc=0 dur=391ms`、横屏守护 ≈1000ms、60s 空闲 CURSORQ=0。

### 5.3 60s 进程级 CPU（release，同口径）

| 版本 | 进程级 `utime+stime` | 线程级 | `cutime+cstime` |
|---|---|---|---|
| v1.68（c8b00288） | **0.82%** | 0.88% | 0.00% |
| v1.67（8aeef7b7） | 0.90% | 0.93% | 0.00% |
| v1.66（73477eca） | 0.82% | 0.80% | 0.00% |
| v1.65（ec79e94a） | 1.62% | 1.58% | 0.00% |

结论：v1.68 与 v1.66/v1.67 同量级，仍显著低于 v1.65，**CPU 不回退**。帧耗时 `perf tick avg=29–33µs max=1.3–2.5ms`。

## 6 文档 / 用例表 / 备份

| 产物 | 说明 |
|---|---|
| `README.md` | 当前版本 v1.68；§2 LB/RB 改为「触摸开=连续拖拽（速度爬升/倍率/续拖/封顶）、触摸关=纯滚轮」；§8 测试表加 v1.68 两项；§9 新增拖拽边界、PiliPlus 截图口径、滚轮悬停限制、padtest 页底 LB 限制；§10 新增 v1.68 行 |
| `docs/TEST-CASES-v1.68.md` | 发布字节 17 项表 + PiliPlus 三口径 + t37 22 项（debug 字节）+ 助手原语（t30）+ 回归 23 项 + 已知限制 |
| `release/RELEASE-NOTES.md`、`docs/RELEASE-NOTES.md` | v1.68 发布说明（规则/参数/实测/口径说明/安装与升级警示/哈希表） |
| `work/docs/INSTALL-v168.md` | 装机校验表 23 行（APK / 助手三处 / zip 内 / APK assets / 重启后 / 横屏 / 拖拽 / 滚轮 / PiliPlus / 冒烟 / CPU） |
| `release/docs/TEST-CASES-v1.68.md`、`v168_verify_lbrb.sh`、`v168_verify_smoke.sh`、`v168_pili_diff.py` | 发布目录内的用例与复跑脚本副本 |
| `backup/self-backup/GamePadDex-v1.68-20261125-0105.zip` | **145.38 MB**（152440117 B），sha256 `308484be91d1ee9ea5bb5c0c650e4e9eacc4cbd8b096903dffd6d61b526a4f0e`，1485 条目（含 v1.68/v1.67 证据截图）；含源码/docs/release/work 脚本；不含 build/.gradle/.git/backup |

`release/SHA256SUMS.txt` 已重生成（79 行，排除自身），逐行自检 **mismatch=0**。

## 7 GitHub

| 项 | 值 |
|---|---|
| 推送 | `git push` 直连 github.com:443 在本环境不稳定，沿用 t7/v1.67 的 **Git Data API 树对比**推送（`work/docs/evidence-v167/push_via_api_tree.py`：远端 tree vs 本地 `git ls-tree -r` → 只传差异 blob → tree/commit/ref） |
| 提交 | 远端 main = **`b140bd37312e0fe56d91dae0852a1df798306db5`**（父 `bc04134`），**远端 tree = `a2652868…` = 本地 HEAD tree**（`TREE MATCH`） |
| 标签 / Release | tag **v1.68** → `b140bd3`；https://github.com/denniswung/GamePadDex/releases/tag/v1.68 （`isDraft=false` / `isPrerelease=false`） |
| 资产 | `dexpad-v1.68.apk`、`gpm_dex-v1.68.zip`、`gpminput-v1.68`、`padtest-v1.1.apk`、`SHA256SUMS.txt`；**重新下载后 sha256 与本地 5/5 相同** |

## 8 残留偏差（如实记录，不阻塞发布）

1. **t37 的 22 项跑在 debug 字节 `991c0510`**（同源码）。发布字节 `c8b00288` 另做 17 项 LB/RB + 23 项回归冒烟；两套脚本、两套证据都在仓库里。
2. **PiliPlus 截图口径**：RMSE 31.33% / MAE 18.95% 满足 ≤40%；逐像素变化占比 58.34%（= t31 口径，旧离散 83.77%）不作为判据。三个口径都写进 RELEASE/TEST-CASES/README。
3. **拖拽中 screencap 是陈旧帧**（t37 §5），"mid"用分次累计 + 段间截图；**cap 2218 vs 2200** = 0.5% 容差，发布口径 ≈2200×倍率（±1%）。
4. **助手与 APK 必须同版本**：`d/m/e` 是 v1.68 助手能力；旧助手 + 新 APK 会让触屏 LB/RB 无动作。升级顺序：APK → 模块 zip → 重启。
5. **padtest 页底 LB 锚点**落内层 ListView（外层 PY 不动），真实 App 两方向已验；滚轮仍受指针悬停窗口限制。
6. `display_size_forced=1600,2560` 仍清不掉（v1.66 起 caveat，横屏 = rotation 1 + 应用逻辑空间 2560×1600）。
7. `set_version.py` 原先停在 1.66/68（v1.67 未同步），本轮已改为 1.68/70。

## 9 acceptance 对照（t34 合同）

| # | 要求 | 结果 | 证据 |
|---|---|---|---|
| 1 | 版本递增 1.67→1.68（69→70），同步 build.gradle / module.prop（仓库与设备） | PASS | §1、`INSTALL-v168.md` #1/#11 |
| 2 | 打包前把三处助手副本与 release 助手对齐 t30 最终哈希 | PASS | §2、`INSTALL-v168.md` #8（三处 `a1d06e2e`） |
| 3 | release/ 产出 APK / 模块 zip / 助手 / SHA256SUMS（内容一致） | PASS | §3（79 行、mismatch=0） |
| 4 | 装机 + reboot：base.apk == 本地、助手五处同哈希、module.prop v1.68/70、自启/鼠标/横屏 | PASS | §4、`INSTALL-v168.md` #2–#17 |
| 5 | **发布字节实测 LB/RB**：100ms ≤150、1.5s 1200–2200、PiliPlus 截图 ≤40%、滚轮 9/0 | PASS | §5.1（71px / 1623px / RMSE 31.33% / 9-0 两侧） |
| 6 | README（v1.68 行 + 拖拽规则与速度参数）、TEST-CASES-v1.68、RELEASE-NOTES、INSTALL-v168 | PASS | §6 |
| 7 | 备份包 `GamePadDex-v1.68-<stamp>.zip`，大小记录 | PASS | §6（145.38 MB，sha256 `308484be…`） |
| 8 | GitHub Release v1.68 资产齐全，5/5 哈希复核 | PASS | §7 |
| 9 | SHA256SUMS 自检 0 mismatch | PASS | §6 |
