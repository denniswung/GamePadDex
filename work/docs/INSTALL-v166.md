# INSTALL-v166 · 哈希级装机校验（v1.66 发布字节）

> 目的：证明「发布的文件」= 「设备上真正运行的字节」，且重启后仍是同一字节（`service.sh` 用模块目录覆盖 `/data/adb/gpm`）。
> 设备：SM-F9360（Android 16），adb `192.168.10.36:6666`，app 空间 2560×1600（`dumpsys display` rotation 1）。
> 探针脚本：`work/docs/evidence-v166-install/verify_install.sh`（只读检查，不写任何设备状态）。

## 1 校验表

| # | 检查项 | 期望 | 实测 | 结果 |
|---|---|---|---|---|
| 1 | APK 版本 | versionName=1.66 / versionCode=68 | `versionName=1.66` / `versionCode=68 minSdk=32 targetSdk=36` | PASS |
| 2 | 本地发布 APK | `release/dexpad-v1.66.apk` sha256=73477eca…aa8bf5，2677039 B | `73477ecaef948aa4b4a9ffdc5f51e8026200a66228cebd635b8aba8c79aa8bf5`，2677039 B | PASS |
| 3 | 设备 base.apk == 本地 APK | 两处 sha256 相同 | `pm path` → `/data/app/~~Rf31UtKaBQ1-6nPSgsV7XA==/com.dennis.dexpad-rug-UytGffTra3s_QWhTkA==/base.apk` sha256=`73477eca…aa8bf5`（size 2677039） | PASS |
| 4 | APK 内 `assets/gpminput` 解包哈希 | == 发布助手哈希 | `1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf`（851928 B） | PASS |
| 5 | 发布助手文件 `release/gpminput-v1.66` | 同上 | `1bf7306f…f4bf`（851928 B） | PASS |
| 6 | 模块 zip 内 `gpminput` | 同上 | `1bf7306f…f4bf`（解包后计算） | PASS |
| 7 | 模块 zip `module.prop` | version=v1.66 / versionCode=68 | `version=v1.66` / `versionCode=68` | PASS |
| 8 | 仓库内两个旧助手副本已刷新 | `project/ksu-module/gpminput`、`project/lsp-dexpad/app/src/main/assets/gpminput` 都 == 发布哈希（原 b8d12518 / 10cbdba1） | 两处均 `1bf7306f…f4bf`（851928 B，与 `project/app/src/main/assets/gpminput` 相同） | PASS |
| 9 | 设备 `/data/adb/gpm/gpminput` | == 发布哈希 | `1bf7306f…f4bf` | PASS |
| 10 | 设备模块目录 `/data/adb/modules/gpm_dex/gpminput` | == 发布哈希 | `1bf7306f…f4bf` | PASS |
| 11 | 设备 `module.prop` | `grep version` = v1.66 / 68 | `version=v1.66` / `versionCode=68` | PASS |
| 12 | 模块安装方式 | 用 KernelSU 官方安装器刷 zip（非手工解压） | `ksud module install /data/local/tmp/gpm_dex-v1.66.zip` → `Installing to /data/adb/modules_update/gpm_dex` → `Module installed successfully!` | PASS |
| 13 | **重启后** `/data/adb/gpm/gpminput` | 仍为发布哈希（`service.sh` 从模块目录覆盖） | `1bf7306f…f4bf`（重启后重新 `sha256sum`） | PASS |
| 14 | 重启后 helper 自启 | `pidof gpminput` 非空 | helper pid=12578（后续复测 15729） | PASS |
| 15 | 重启后引擎自启 | `pidof com.dennis.dexpad` 非空 且 EngineService 前台 | app pid=13260；`ServiceRecord … EngineService isForeground=true foregroundId=1001` | PASS |
| 16 | 重启后鼠标可用（抽检） | 真机注入后光标可移动/可点击 | `release_smoke` RS2-MOVE：满推 300ms → 真实点击落点 `2559,799`（dx=+1279px，夹到右边缘）；RS1-L3 `1281,799` | PASS |
| 17 | 重启后默认横屏 | user_rotation=1、accelerometer_rotation=0、app bounds 2560×1600（`dumpsys display` rotation 1） | `user_rotation=1` / `accelerometer_rotation=0` / `app 2560 x 1600` / `rotation 1` / rotlock=`lock 1` | PASS |
| 18 | 重启后 display override 状态（caveat 记录） | `display_size_forced=1600,2560` 仍在（清不掉，属已知） | `display_size_forced=1600,2560`；`wm size` = `Physical size: 904x2316 / Override size: 1600x2560` | 记录 |
| 19 | 发布字节冒烟（整体） | 全通过 | `PASS=23 FAIL=0`（`release_smoke.result.txt`） | PASS |
| 20 | 60s 进程级 CPU（发布构建） | 与 v1.65 同口径对比，不超基线 | v1.66 = 0.82%（线程 0.80%、`cutime+cstime` 0.00%）；v1.65 = 1.62%（线程 1.58%） | PASS |

> 说明：第 18 行为**如实记录的 caveat**，不是失败项——三星保留了用户早期的 `display_size_forced`，`wm size reset` /
> `settings put global display_size_forced null` 均无效（t1 复现）。v1.66 的横屏实现是 rotation 1 + 应用逻辑空间 2560×1600。

## 2 关键命令（可复跑）

```bash
# 本地哈希
sha256sum release/dexpad-v1.66.apk release/gpminput-v1.66 release/gpm_dex-v1.66.zip
sha256sum project/ksu-module/gpminput project/lsp-dexpad/app/src/main/assets/gpminput
# APK 内 assets 助手
unzip -p release/dexpad-v1.66.apk assets/gpminput | sha256sum
# 模块 zip 内助手
unzip -p release/gpm_dex-v1.66.zip gpminput | sha256sum
# 设备侧（一条命令出全部）
adb push work/docs/evidence-v166-install/verify_install.sh /data/local/tmp/
adb shell "sh /data/local/tmp/verify_install.sh"
# 设备 base.apk
adb shell 'p=$(pm path com.dennis.dexpad | head -1 | cut -d: -f2); echo $p; sha256sum $p'
```

## 3 发布资产哈希（与 `release/SHA256SUMS.txt` 一致）

| 文件 | sha256 | 大小 |
|---|---|---|
| `dexpad-v1.66.apk` | `73477ecaef948aa4b4a9ffdc5f51e8026200a66228cebd635b8aba8c79aa8bf5` | 2677039 B |
| `gpm_dex-v1.66.zip` | `fd4fc2ebd0d06a17eb6d5fd1e3dd90d722526ac6b33ec70436bbd2b50463085f` | 362092 B |
| `gpminput-v1.66` | `1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf` | 851928 B |
| `padtest-v1.1.apk` | `27478cef1c51acddc88c7ef662980ead4720bc95ce38635b0aa816f67de32e50` | 949222 B |

## 4 升级路径与注意

- 从 v1.65 升级：直接 `adb install -r dexpad-v1.66.apk`（同签名 debug keystore），再刷 `gpm_dex-v1.66.zip`，重启。
- **助手与 APK 必须同版本**：v1.66 的 `u` / `g`/`O` / `c` / `?` 是 v1.66 助手能力；旧助手配新 APK 会退化为旧行为（不会崩，但唤醒/自检/增益命令不可用）。
- 旧版本回退：`adb install -r -d dexpad-v1.65.apk` 后再刷 v1.65 模块 zip（本次 t7 为做 CPU 同口径对比实测过这条路径，回装 v1.66 后哈希复验一致）。
- 模块 zip 内**没有** `system/` 等额外目录，只有 `gpminput / inject.dex / module.prop / post-fs-data.sh / service.sh`（与 v1.44–v1.65 一致）。

## 5 出处

- 装机校验原始输出：`work/docs/evidence-v166-install/verify_install.sh`（脚本）+ 本次会话记录（见 `work/docs/RELEASE-v166.md` §4 摘录）
- 发布字节冒烟：`work/docs/evidence-v166-install/release_smoke.result.txt` / `release_smoke.log.txt`
- CPU 同口径对比：`work/docs/evidence-v166-install/v166_cpu60.sh` + `work/docs/RELEASE-v166.md` §5
- 全量 A~K：`work/docs/VERIFY-v166-final.md`
