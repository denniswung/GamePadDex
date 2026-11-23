# RELEASE-v166 · v1.66 集成发布报告（integrator / t7）

> 目标：版本递增到 1.66 / 68（只校验不递增）、重建发布包、刷新助手副本、文档与用例表、SHA256SUMS、备份包、
> GitHub Release、哈希级装机校验（含重启后）。
> 设备：SM-F9360（Android 16），adb `192.168.10.36:6666`，app 空间 2560×1600（`dumpsys display` rotation 1）。

## 1 版本

| 项 | 值 | 校验 |
|---|---|---|
| `project/lsp-dexpad/app/build.gradle.kts` | `versionCode = 68` / `versionName = "1.66"` | 未递增到 1.67 |
| `project/ksu-module/module.prop` | `version=v1.66` / `versionCode=68` | 仓库 + 设备两处 |
| 设备安装后 | `versionName=1.66` / `versionCode=68` | `dumpsys package com.dennis.dexpad` |
| 设备模块 | `grep '^version' /data/adb/modules/gpm_dex/module.prop` → `version=v1.66` / `versionCode=68` | 重启后复验 |

## 2 构建（clean assembleRelease）

```
cd project/lsp-dexpad
JAVA_HOME=/home/denniswung/jdk17 ANDROID_HOME=/home/denniswung/android-sdk \
  ./gradlew --no-daemon --no-build-cache clean assembleRelease
# BUILD SUCCESSFUL in 1m41s  (47 actionable tasks)
```

- 产物 `app/build/outputs/apk/release/app-release.apk`，`output-metadata.json` 里 `versionCode=68 / versionName=1.66`。
- 命名并入库：`release/dexpad-v1.66.apk`（2677039 B）、`release/gpminput-v1.66`（851928 B）、`release/gpm_dex-v1.66.zip`（362092 B）。
- 模块 zip 内容（与 v1.44–v1.65 一致）：`gpminput / inject.dex / module.prop / post-fs-data.sh / service.sh`。
- **打包前刷新助手副本**（t12 §6 指出的风险）：把 `project/app/src/main/assets/gpminput`（= 发布助手 `1bf7306f…`）
  覆盖到 `project/ksu-module/gpminput`（原 `b8d12518…`）与 `project/lsp-dexpad/app/src/main/assets/gpminput`（原 `10cbdba1…`）。
  结果：APK 内 `assets/gpminput`、模块 zip 内 `gpminput`、`release/gpminput-v1.66` 三者哈希相同。

## 3 发布资产（与 `release/SHA256SUMS.txt` 一致）

| 资产 | sha256 | 大小 |
|---|---|---|
| `dexpad-v1.66.apk` | `73477ecaef948aa4b4a9ffdc5f51e8026200a66228cebd635b8aba8c79aa8bf5` | 2677039 B |
| `gpm_dex-v1.66.zip` | `fd4fc2ebd0d06a17eb6d5fd1e3dd90d722526ac6b33ec70436bbd2b50463085f` | 362092 B |
| `gpminput-v1.66` | `1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf` | 851928 B |
| `padtest-v1.1.apk` | `27478cef1c51acddc88c7ef662980ead4720bc95ce38635b0aa816f67de32e50` | 949222 B |
| `SHA256SUMS.txt` | 73 行（不含自身） | 6035 B |

**哈希链（为什么发布 APK 不再是 d2194406）**

```
APK:    e8a91185 (t4/t8) → b7fa2662 (t16) → d2194406 (t20, debug 字节, t15 全量 A~K 跑这个)
        → 73477eca (v1.66 发布, assembleRelease；与 d2194406 的差异 = 构建变体标志 + assets/gpminput 刷新)
helper: 4f261754 (t2, t4 验证) → 139087e7 (t10) → 6076b63b (t11) → 1bf7306f (t20 前最终, t15/t20 绑定, 本次发布)
```

> 说明：acceptance 要求「打包前把所有助手副本刷新为 t15 绑定哈希」，因此 APK 必须重建一次，哈希必然变化。
> 重建只换了 APK 里的 `assets/gpminput`（851928 B）+ release 变体，**Kotlin 源码未改**（`git diff` 只有实现阶段已提交的改动）。
> 发布字节因此单独跑了一套 23 项冒烟（§4），而不是只引用 t15 在 debug 字节上的数字。

## 4 发布字节（release 包）装机冒烟：23/23

脚本 `work/docs/evidence-v166-install/release_smoke.sh`；原始结果 `release_smoke.result.txt`（PASS=23 FAIL=0）。
只用公开手段（vgpad 虚拟手柄 + padtest 真实注入事件 + uiautomator 真实页面位置 + `helper.log` + settings/dumpsys），
因为 **release 包 `debuggable=false`，app 的 `DEBUG`/`HCMD` 广播被 `DebugReceiver.kt:21-22` 主动忽略**。

覆盖与结果（详见 `docs/TEST-CASES-v1.66.md` §14）：哈希/版本/横屏基线；L3 居中 1281,799（1px）+ A=鼠标点击；
左摇杆满推 300ms → 落点 2559,799（dx=+1279）；竖推 dPY=1415（helper 仅 Z）、横推 dHS=512（仅 V）；
空闲隐藏（POINTER off + 设备不存在）后首次竖推 dPY=1415；Y+上 PiliPlus / Y+下 抖音；
d-pad+A→DPAD_CENTER、X 双击→Recents、X+LB dx=+672、X+RB dx=−1536、隐藏恢复 0px、SELECT 通知栏 `rc=0 dur=389ms`；
外部改竖屏 ≈2000ms 自动回横屏；60s 空闲 CPU 0.82% / CURSORQ=0。

## 5 60s 进程级 CPU（release 构建，与 v1.65 同口径）

方法（`work/docs/evidence-v166-install/v166_cpu60.sh`）：先静置 20s 让空闲节流生效，再取 60s 增量。

| 版本 | 进程级 `utime+stime` | 线程级求和 | `cutime+cstime`（子进程） | 备注 |
|---|---|---|---|---|
| **v1.66 release**（73477eca） | **0.82%** / 0.92% / 0.95%（三次，含 RS8） | 0.80% | 0.00% | 空闲 60s，padtest 已停 |
| **v1.65 release**（ec79e94a） | **1.62%** | 1.58% | 0.00% | 同法、同设备、紧接着测 |

口径说明（回应 t6 R4 / t9 R5 / t19 R4）：
- **进程级** = `/proc/<pid>/stat` 字段 14+15 的 60s 增量 / 60 → 主句柄；
- **`cutime+cstime`**（字段 16+17）单列并实测 **0.00%**：证明没有把短命子进程（`am`/`input` 等）的 CPU 混进来；
- **线程级求和** = 逐 `/proc/<pid>/task/*/stat` 求和，包含 Kotlin/JIT 短命线程，仅辅助；
- t15 里的 `H3 = 3.42%` 是**线程级**且在“边测边跑探针”的负载下取的，不可与本次空闲段直接比较，故发布说明只引用本次同口径对比。

结论：v1.66 空闲 CPU **低于** v1.65（0.82% vs 1.62%），可以写「CPU/资源不回退」。

## 6 文档 / 用例表 / 备份

| 产物 | 说明 |
|---|---|
| `README.md` | 版本行 → v1.66；`§2` 写入 dpi 数值（speed_phone=48、γ=1.6、亚像素 0.2px、边缘 0.6）与滑动参数（竖 560px/250ms、横 w*0.45/500ms、1.5s 横竖比 1.029、两种口径说明）；`§3` 新增 Y+上/Y+下/摇杆唤醒；`§9` 新增默认横屏 + `display_size_forced` caveat + release 包不响应调试广播 + 400ms 双击文案笔误；`§10` 新增 v1.66 行 |
| `docs/TEST-CASES-v1.66.md` | A~K 完整用例表（阈值/实测/判定）+ 三轮一致性 + t10/t11/t12/t13/t15/t20 补充 + 发布字节 23 项 + 复跑命令 |
| `release/RELEASE-NOTES.md`、`docs/RELEASE-NOTES.md` | v1.66 发布说明（5 修 3 功能 + 提速数字 + caveat + 安装步骤 + 哈希表） |
| `work/docs/INSTALL-v166.md` | 装机校验表 20 项（APK / 助手三处 / zip 内 / APK assets / 重启后 / 横屏 / 自启 / CPU） |
| `work/docs/LANDSCAPE-v166.md` | 按 t9 R1/R2/R4/R5/R6 修正：`ui_button_land.png` 换成真实 ButtonDetail 双列截图（旧图留档 `work/ui_button_land_notifbar_OLD.png`）、横屏判定统一为 `dumpsys display rotation 1 + app bounds 2560×1600 + mLandscapeRotation=ROTATION_0`、竖屏回落用 ConfigActivity 单列截图、CPU 口径重写、新增 §7.1 caveat |
| `work/docs/APP-v166.md` | 补充发布哈希链注记（原文头部是 b7fa2662 时期） |
| `backup/self-backup/GamePadDex-v1.66-20261124-0606.zip` | **66.17 MB**（69389160 B），sha256 `3e5dc617fed7ab99a3bf7c7914003699a98e23a4f78f46b957bb4de5a795ff4f`；含源码（`project/**/src`、gradle 配置）、`docs/`、`release/`、`work/scripts`、`work/docs`，不含 build/.gradle/.git/backup |

`release/SHA256SUMS.txt` 已按 release/ 目录实际文件重生成（73 行，排除自身）。

## 7 GitHub

| 项 | 值 |
|---|---|
| 提交 | 远端提交 **`fbef712f2ea5764e69db4caf51f6f580c45eb7b6`**（v1.66 内容提交 `4d7ff5c` + 集成文档提交），**远端 tree = `7635c176…` = 本地 HEAD tree**（逐字节一致） |
| 父提交 | `4d7ff5c`（内容）← `4f99b17`（远端原 head） |
| 推送方式 | `git push` 直连 github.com:443 被网络重置/超时（重试 3 次均失败）→ 改用 **GitHub REST Git Data API**（`work/docs/evidence-v166-install/push_via_api.py`：blob→tree→commit→ref），并校验 tree 相同 |
| 标签 / Release | tag **v1.66** → `fbef712`；https://github.com/denniswung/GamePadDex/releases/tag/v1.66 （`isDraft=false isPrerelease=false`） |
| 资产 | `dexpad-v1.66.apk`、`gpm_dex-v1.66.zip`、`gpminput-v1.66`、`padtest-v1.1.apk`、`SHA256SUMS.txt`；**重新下载后 sha256 与本地逐一相同**（5/5 match=True） |

## 8 残留偏差（如实记录，不阻塞发布）

1. **t15/t20 的 A~K 全量数字来自 debug 字节 `d2194406`**（同源码）。发布字节是 `assembleRelease` 包，用 23 项冒烟覆盖同样的用户可见行为；
   发布说明引用的 H1/H2/帧耗时来自 t15 报告，另有本次 release 的帧耗时（33–43µs）与 CPU 同口径数据。
2. **release 包不响应 `DEBUG`/`HCMD` 调试广播**（设计如此）。因此 A5 的 `INFO pointer device=off` 探针、G3 的自定义映射保护、
   J6/J7 的 `force_landscape` 切换这三处只在 debug 变体上验证（t15 68/68 内），发布字节用 POINTER off + `getevent` + 页面位移替代 A5 探针。
3. `work/docs/APP-v166.md` 头部装机哈希是 b7fa2662（t16 时期），已在文件头加注“发布字节 73477eca / 助手 1bf7306f”；正文行为数字未改（同源码）。
4. ButtonDetail 页面双击说明文案仍是「320 ms 内」，实际窗口 400 ms —— UI 文案笔误（未改代码，写入 README 已知限制与 LANDSCAPE 文档）。
5. 早期一次 API 推送失败留下两个孤儿 Git 对象（blob/tree，无 commit 引用）：`34191b57…`、`a3f6ea9…`；不影响仓库内容。
6. 本地 `git` 分支提交 `f79b8a8` 与远端 `4d7ff5c` 内容相同但对象不同（提交时间/父不同）。后续如需 `git push`，先 `git fetch` 再 rebase 到远端即可。

## 9 acceptance 对照（t7 合同）

| # | 要求 | 结果 | 证据 |
|---|---|---|---|
| 1 | versionName=1.66 / versionCode=68，module.prop v1.66/68（设备一致，不递增到 1.67） | PASS | §1、`INSTALL-v166.md` #1/#11 |
| 2 | 打包前刷新两个助手副本到 t15 最终哈希 | PASS | §2、`INSTALL-v166.md` #8 |
| 3 | 哈希级校验（设备 APK == 本地 APK；助手三处一致；APK assets 一致） | PASS | `INSTALL-v166.md` #2–#10 |
| 4 | 重启验证（模块 zip 安装后 reboot，助手仍最终哈希，自启 + 鼠标可用） | PASS | `INSTALL-v166.md` #12–#16 |
| 5 | release/ 五件套齐全且 SHA256SUMS 与实际一致 | PASS | §3、§6 |
| 6 | README 版本历史 + 横屏 + dpi/滑动数值；TEST-CASES 含 A~K + 补充验证 | PASS | §6 |
| 7 | 修正 t9 R1/R2/R4 三处文档/证据问题 | PASS | `LANDSCAPE-v166.md` §4/§5/§1 |
| 8 | t9 R6 caveat（display_size_forced 清不掉） | PASS | `LANDSCAPE-v166.md` §7.1、`README.md` §9 |
| 9 | 提速数字来自绑定发布哈希的报告 | PASS（附变体说明） | §8-1、§5；t15 报告 + release 复测 |
| 10 | release 构建 60s 进程级 CPU 与 v1.65 同口径对比 | PASS | §5 |
| 11 | `work/docs/INSTALL-v166.md` 装机校验表（含五项） | PASS | 该文件 #1–#20 |
| 12 | 备份包存在且含源码/文档/release 脚本，大小记录 | PASS | §6（66.17 MB） |
| 13 | GitHub Release v1.66 资产齐全，哈希一致 | PASS | §7 |
| 14 | 装机后默认横屏（user_rotation=1、accel=0、app 2560×1600） | PASS | `INSTALL-v166.md` #17 |
