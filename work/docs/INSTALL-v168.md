# INSTALL-v168 · 哈希级装机校验（v1.68 发布字节）

> 证明「发布的文件」= 「设备上真正运行的字节」，且重启后仍是同一字节（`service.sh` 用模块目录覆盖 `/data/adb/gpm`）。
> 设备：SM-F9360（Android 16），adb `192.168.10.36:6666`，app 空间 2560×1600（`dumpsys display` rotation 1）。
> 探针：`work/docs/evidence-v168/verify_install.sh`（只读）。

## 1 校验表

| # | 检查项 | 期望 | 实测 | 结果 |
|---|---|---|---|---|
| 1 | APK 版本 | versionName=1.68 / versionCode=70 | `versionName=1.68` / `versionCode=70 minSdk=32 targetSdk=36` | PASS |
| 2 | 本地发布 APK | `release/dexpad-v1.68.apk` sha256=`c8b00288…25bbc998`，2684731 B | 相同（2684731 B） | PASS |
| 3 | 设备 base.apk == 本地 APK | 两处 sha256 相同 | `pm path` → `/data/app/~~glGmAKD3yIPcbr9Ihj6ypQ==/com.dennis.dexpad-slHAOmez7fLE6cQwU03Ulg==/base.apk` sha256=`c8b00288…`（2684731 B） | PASS |
| 4 | APK 内 `assets/gpminput` 解包哈希 | == 发布助手哈希 | `a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d`（852328 B） | PASS |
| 5 | 发布助手 `release/gpminput-v1.68` | 同上 | `a1d06e2e…bd06d`（852328 B） | PASS |
| 6 | 模块 zip 内 `gpminput` | 同上 | `a1d06e2e…bd06d`（852328 B） | PASS |
| 7 | 模块 zip `module.prop` | version=v1.68 / versionCode=70 | `version=v1.68` / `versionCode=70` | PASS |
| 8 | 仓库内三处助手副本对齐 | `project/app/src/main/assets/gpminput`、`project/ksu-module/gpminput`、`project/lsp-dexpad/app/src/main/assets/gpminput` 都 == 发布哈希 | 三处均 `a1d06e2e…bd06d`（852328 B） | PASS |
| 9 | 设备 `/data/adb/gpm/gpminput` | == 发布哈希 | `a1d06e2e…bd06d` | PASS |
| 10 | 设备模块目录 `/data/adb/modules/gpm_dex/gpminput` | == 发布哈希 | `a1d06e2e…bd06d` | PASS |
| 11 | 设备 `module.prop` | `grep version` = v1.68 / 70 | `version=v1.68` / `versionCode=70` | PASS |
| 12 | 模块安装方式 | 用 KernelSU 官方安装器刷 zip（非手工解压） | `ksud module install /data/local/tmp/gpm_dex-v1.68.zip` → `Installing to /data/adb/modules_update/gpm_dex` → `Module installed successfully!` | PASS |
| 13 | **重启后** `/data/adb/gpm/gpminput` | 仍为发布哈希（`service.sh` 从模块目录覆盖） | `a1d06e2e…bd06d`（重启后重新 `sha256sum`） | PASS |
| 14 | 重启后 helper 自启 | `pidof gpminput` 非空 | helper pid=14099（后续会话 28070/31735/3794） | PASS |
| 15 | 重启后引擎自启 | `pidof com.dennis.dexpad` 非空 且 EngineService 前台 | app pid=13626（后续 28123/31685/3756） | PASS |
| 16 | 重启后鼠标可用 | 真机注入后光标可移动/可点击 | 冒烟 RS2-MOVE 满推 300ms 落点 `2559,799`（dx=+1279）；RS1-L3 `1281,799` | PASS |
| 17 | 重启后默认横屏 | user_rotation=1、accelerometer_rotation=0、app 2560×1600（`dumpsys display` rotation 1） | `rotation 1` / `app 2560 x 1600` / `user_rotation=1` / `accelerometer_rotation=0` | PASS |
| 18 | 重启后 LB/RB 连续拖拽 | 100ms ≤150px、1.5s ∈[1200,2200]、SWIPE=0/WHEEL=0 | 100ms **71px**、1.5s **1623px**、SWIPE=0 WHEEL=0 | PASS |
| 19 | 重启后滚轮模式 | WHEEL=9 / SWIPE=0（改 prefs + 强制重启引擎） | LB/RB 均 **9 / 0**，`mode=wheel` | PASS |
| 20 | 重启后 PiliPlus 1.5s | 总位移 ∈[1200,2200]；截图差异 ≤40% | total **1643px**；截图 **RMSE 31.33%**（MAE 18.95%） | PASS |
| 21 | 发布字节回归冒烟（整体） | 全通过 | `PASS=23 FAIL=0`（`verify_v168_smoke.result.txt`） | PASS |
| 22 | 60s 进程级 CPU（发布构建） | 与 v1.65 同口径，不超基线 | v1.68=`0.82%`（线程 0.88%、`cutime+cstime` 0.00%）；v1.67=0.90%；v1.66=0.82%；v1.65=1.62% | PASS |
| 23 | display override caveat（如实记录） | `display_size_forced=1600,2560` 仍在（清不掉） | `display_size_forced=1600,2560`；`wm size` Override 1600x2560 | 记录 |

## 2 关键命令（可复跑）

```bash
# 本地哈希
sha256sum release/dexpad-v1.68.apk release/gpminput-v1.68 release/gpm_dex-v1.68.zip
sha256sum project/app/src/main/assets/gpminput project/ksu-module/gpminput project/lsp-dexpad/app/src/main/assets/gpminput
unzip -p release/dexpad-v1.68.apk assets/gpminput | sha256sum
unzip -p release/gpm_dex-v1.68.zip gpminput | sha256sum
# 设备侧（一条命令出全部）
adb push work/docs/evidence-v168/verify_install.sh /data/local/tmp/
adb shell "sh /data/local/tmp/verify_install.sh"
# 设备 base.apk
adb shell 'p=$(pm path com.dennis.dexpad | head -1 | cut -d: -f2); echo $p; sha256sum $p'
```

## 3 发布资产哈希（与 `release/SHA256SUMS.txt` 一致）

| 文件 | sha256 | 大小 |
|---|---|---|
| `dexpad-v1.68.apk` | `c8b002880c70dedc1fc6ddbc047bcf87503a6539b8d72693ae32b7e925bbc998` | 2684731 B |
| `gpm_dex-v1.68.zip` | `51044ce21322f23fc09f1a52ace0cd229fcc2ae2f430023911a33aea7f14049f` | 365632 B |
| `gpminput-v1.68` | `a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d` | 852328 B |
| `padtest-v1.1.apk` | `27478cef1c51acddc88c7ef662980ead4720bc95ce38635b0aa816f67de32e50` | 949222 B |

## 4 升级/回退（重要）

- **v1.67 → v1.68 必须换助手**：`d`/`m`/`e` 是 v1.68 助手的新命令。旧助手配 v1.68 APK 时，触屏 LB/RB 的 drag 命令会被拒（`ERR d args` / 未知命令），
  表现为"按住 LB/RB 没反应"；反之 v1.68 助手 + v1.67 APK 仍能工作（旧路径不受影响）。
  所以升级顺序：装 APK → 刷 `gpm_dex-v1.68.zip` → **重启**。
- 回退 v1.67：`adb install -r -d dexpad-v1.67.apk` + 刷 v1.67 模块 zip（助手回到 `1bf7306f`）+ 重启。
- 模块 zip 内容：`gpminput / inject.dex / module.prop / post-fs-data.sh / service.sh`（与 v1.44–v1.67 一致）。
- 触摸面板标定与本机面板方向绑定（`touch_panel_xy` 针对 2560×1600 折叠屏内屏）；换设备/换分辨率会退化为恒等映射，需要重新标定。

## 5 出处

- 装机检查脚本与原始输出：`work/docs/evidence-v168/verify_install.sh` + 本次会话记录（摘录见 `work/docs/RELEASE-v168.md` §4）
- 发布字节 LB/RB 17 项：`work/docs/evidence-v168/verify_v168_lbrb.result.txt`
- 发布字节回归冒烟 23 项：`work/docs/evidence-v168/verify_v168_smoke.result.txt`
- PiliPlus 截图度量：`work/docs/evidence-v168/shots/` + `pili_diff.py`
- t37 复验（debug 字节）：`work/docs/VERIFY-drag-v168-t37.md`
