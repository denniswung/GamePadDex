# INSTALL-v169 · 哈希级装机校验（v1.69 发布字节）

> 证明「发布的文件」= 「设备上真正运行的字节」，重启后仍是同一字节（`service.sh` 用模块目录覆盖 `/data/adb/gpm`）。
> 设备：SM-F9360（Android 16），adb `192.168.10.36:6666`，app 空间 2560×1600（`dumpsys display` rotation 1）。
> 探针：`work/docs/evidence-v169/verify_install.sh`（只读）。

## 1 校验表

| # | 检查项 | 期望 | 实测 | 结果 |
|---|---|---|---|---|
| 1 | APK 版本 | versionName=1.69 / versionCode=71 | `versionName=1.69` / `versionCode=71 minSdk=32 targetSdk=36` | PASS |
| 2 | 本地发布 APK | `release/dexpad-v1.69.apk` sha256=`d31e5128…c92c7fb`，2687735 B | 相同（2687735 B） | PASS |
| 3 | 设备 base.apk == 本地 APK | 两处 sha256 相同 | 设备 `base.apk` sha256=`d31e5128…`（2687735 B） | PASS |
| 4 | APK 内 `assets/gpminput` 解包哈希 | == 发布助手 | `b806f39ba51278a73aad121be4019820b7961dcb0935971b64d3a02373cd2a4d`（852960 B） | PASS |
| 5 | 发布助手 `release/gpminput-v1.69` | 同上 | `b806f39b…cd2a4d`（852960 B） | PASS |
| 6 | 模块 zip 内 `gpminput` | 同上 | `b806f39b…`（852960 B） | PASS |
| 7 | 模块 zip `module.prop` | version=v1.69 / versionCode=71 | `version=v1.69` / `versionCode=71` | PASS |
| 8 | 仓库三处助手副本对齐 | `project/app/src/main/assets/gpminput`、`project/ksu-module/gpminput`、`project/lsp-dexpad/app/src/main/assets/gpminput` 都 == 发布哈希 | 三处均 `b806f39b…`（852960 B） | PASS |
| 9 | 设备 `/data/adb/gpm/gpminput` | == 发布哈希 | `b806f39b…` | PASS |
| 10 | 设备模块目录 `/data/adb/modules/gpm_dex/gpminput` | == 发布哈希 | `b806f39b…` | PASS |
| 11 | 设备 `module.prop` | `grep version` = v1.69 / 71 | `version=v1.69` / `versionCode=71` | PASS |
| 12 | 模块安装方式 | KernelSU 官方安装器刷 zip | `ksud module install gpm_dex-v1.69.zip` → `Installing to /data/adb/modules_update/gpm_dex` → `Module installed successfully!`；staged module.prop = v1.69/71 | PASS |
| 13 | **重启后** `/data/adb/gpm/gpminput` | 仍为发布哈希 | `b806f39b…`（重启后重新 `sha256sum`） | PASS |
| 14 | 重启后 helper 自启 | `pidof gpminput` 非空 | helper pid=13910（后续会话 4204/7703 等重启后新 pid） | PASS |
| 15 | 重启后引擎自启 | `pidof com.dennis.dexpad` 非空 且 EngineService 前台 | app pid=13969（后续 4162/7703 等） | PASS |
| 16 | 重启后鼠标可用 | 真机注入后光标可移动/可点击 | 冒烟 RS2-MOVE：满推 300ms 落点 `2559,801`（dx=+1279）；RS1-L3 `1281,804` | PASS |
| 17 | 重启后默认横屏 | user_rotation=1、accel=0、app 2560×1600（rotation 1） | `rotation 1` / `app 2560 x 1600` / `user_rotation=1` / `accelerometer_rotation=0` | PASS |
| 18 | 重启后 P 绝对定位（六点） | 误差 ≤8px | 402,1202 / 2000,300 / 99,102 / 2445,1496 / 1280,802 / 694,999 → 最大 err **6px**（六点全过，`c` 复核一致） | PASS |
| 19 | 重启后 `?` 自检 | CAP 13 项全 1、ERR=0 | `CAP=13 all1=13 ERR=0`（`INFO pointer device=off` 等 5 条 INFO 正常） | PASS |
| 20 | 重启后 LB/RB 连续拖拽 | 100ms ≤150、300ms ≤450、1.5s 1200–2200 | **74 / 251 / 1636px**；期间 `SWIPE=0/WHEEL=0` | PASS |
| 21 | 重启后滚轮模式 | WHEEL≥6 且 SWIPE=0 | **WHEEL=9 / SWIPE=0**（`v_touch_scroll=false`，改 prefs + 强制重启引擎） | PASS |
| 22 | 重启后 X+LB / X+RB | 方向正确 | X+LB **dx=+1260**、X+RB **dx=−1260** | PASS |
| 23 | 重启后 padtest | v1.4/5 且 sha 一致 | `1.4/5`，`0f4a9191…967056d` == `release/padtest-v1.4.apk` | PASS |
| 24 | 发布字节回归冒烟 | 不出现产品级回归 | 23 项中 21 项直接 PASS；RS3-V/RS4-HIDDEN 因 padtest v1.4 手势归属改变（内层 vList 抢手势）判据失效，改用 v1.4 权威字段复测 **voff 0→14 / Z=4 / path 486px** → 判 PASS（见 `verify_v169_recheck2.result.txt`） | PASS |
| 25 | 60s 进程级 CPU | 与历史同口径，不超基线 | **0.97%**（线程 1.00%、`cutime+cstime` 0.00%）；v1.68 0.82% / v1.65 1.62% | PASS |
| 26 | display override caveat（如实记录） | `display_size_forced=1600,2560` 仍在 | 仍为 `1600,2560`（清不掉，v1.66 起的已知项） | 记录 |

## 2 关键命令（可复跑）

```bash
sha256sum release/dexpad-v1.69.apk release/gpminput-v1.69 release/gpm_dex-v1.69.zip release/padtest-v1.4.apk
sha256sum project/app/src/main/assets/gpminput project/ksu-module/gpminput project/lsp-dexpad/app/src/main/assets/gpminput
unzip -p release/dexpad-v1.69.apk assets/gpminput | sha256sum
unzip -p release/gpm_dex-v1.69.zip gpminput | sha256sum
adb push work/docs/evidence-v169/verify_install.sh /data/local/tmp/ && adb shell "sh /data/local/tmp/verify_install.sh"
adb shell "su -c 'sh /data/local/tmp/verify_v169_extra.sh'"     # 16 项（P 六点/CAP/拖拽/滚轮/X+LB/RB）
adb shell "su -c 'sh /data/local/tmp/verify_v169_smoke.sh'"     # 23 项回归冒烟
adb shell "su -c 'sh /data/local/tmp/verify_v169_recheck2.sh'"  # 竖推/隐藏首推（padtest v1.4 权威字段）
```

## 3 发布资产哈希（与 `release/SHA256SUMS.txt` 一致）

| 文件 | sha256 | 大小 |
|---|---|---|
| `dexpad-v1.69.apk` | `d31e51285a0a3baa71a75ed2b7dca1a7f88697685ae982c35e2f807bfc92c7fb` | 2687735 B |
| `gpm_dex-v1.69.zip` | `b9785087b35f3e6e341d09bf7950334d18be384d6804e3f8481e51c1ee504097` | 368072 B |
| `gpminput-v1.69` | `b806f39ba51278a73aad121be4019820b7961dcb0935971b64d3a02373cd2a4d` | 852960 B |
| `padtest-v1.4.apk` | `0f4a91911360cb4051fff9b54711508e4dc90de797be6ec0e55e83e9a967056d` | 956738 B |

## 4 升级/回退

- **v1.68 → v1.69：助手必须一起换**。v1.69 助手 = `b806f39b`（含 t47 P 闭环、t48/t54 root 控制通道 `gpmctl.sock`、t59 触摸映射结论）。
  升级顺序：装 APK → 刷 `gpm_dex-v1.69.zip` → 重启（`service.sh` 从模块目录覆盖 `/data/adb/gpm`）。
- padtest 从 v1.1 直接装 `padtest-v1.4.apk`（同签名覆盖安装）；v1.2/v1.3 有已知回归，不要回退使用。
- 回退 v1.68：`adb install -r -d dexpad-v1.68.apk` + 刷 v1.68 模块 zip（助手回到 `a1d06e2e`）+ 重启。
- **root 控制通道**：`/data/adb/gpm/gpmctl.sock`（目录 0700 / socket 0600 / SO_PEERCRED uid==0）；
  可用 `/data/local/tmp/gpmctl <sock> <cmd>` 发 `P`/`c`/`?` 等命令（详见 `work/docs/HELPER-v169.md` §6）。
  不需要时 `touch /data/adb/gpm/gpmctl.disabled` 后重启助手即不创建 socket。

## 5 出处

- 装机检查脚本与本次会话记录（摘要见 `work/docs/RELEASE-v169.md` §4）
- 发布字节专项：`work/docs/evidence-v169/verify_v169_extra.result.txt`（16/16）
- 发布字节冒烟：`work/docs/evidence-v169/verify_v169_smoke.result.txt`（21 直接 PASS + 2 判据失效项）
- 判据失效项复测：`work/docs/evidence-v169/verify_v169_recheck2.result.txt`（2/2 PASS）
- 自检原始回包：`work/docs/evidence-v169/selftest-cap.txt`（CAP 13 + INFO 5 + ERR=0）
- 测试计划与执行摘要：`docs/TEST-CASES-v1.69.md`（用户原文 + 附录 A）
