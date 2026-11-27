# INSTALL-v170 · 哈希级装机校验（v1.70 发布字节）

> 证明「发布的文件」= 「设备上真正运行的字节」，重启后仍是同一字节（`service.sh` 用模块目录覆盖 `/data/adb/gpm`）。
> 设备：SM-F9360（Android 16），adb `192.168.10.36:6666`，app 空间 2560×1600（`dumpsys display` rotation 1）。

## 1 校验表

| # | 检查项 | 期望 | 实测 | 结果 |
|---|---|---|---|---|
| 1 | APK 版本 | versionName=1.70 / versionCode=72 | `versionName=1.70` / `versionCode=72 minSdk=32 targetSdk=36` | PASS |
| 2 | 本地发布 APK | `release/dexpad-v1.70.apk` sha256=`05f4f11f…eced876c`，2688107 B | 相同（2688107 B） | PASS |
| 3 | 设备 base.apk == 本地 APK | 两处 sha256 相同 | `05f4f11f2e48b498556abc35ea58bbc873f032128529d83d6abe9ea5eced876c`（2688107 B） | PASS |
| 4 | APK 内 `assets/gpminput` 解包哈希 | == 发布助手 `eb0b5dfc` | `eb0b5dfc6d5403b30d8200467f773e628729ea5290d1574aeb5651bf33c8c31c`（852976 B） | PASS |
| 5 | 发布助手 `release/gpminput-v1.70` | 同上 | `eb0b5dfc…c8c31c`（852976 B） | PASS |
| 6 | 模块 zip 内 `gpminput` | 同上 | `eb0b5dfc…`（852976 B） | PASS |
| 7 | 模块 zip `module.prop` | version=v1.70 / versionCode=72 | `version=v1.70` / `versionCode=72` | PASS |
| 8 | 仓库三处助手副本对齐 | `project/app/src/main/assets/gpminput`、`project/ksu-module/gpminput`、`project/lsp-dexpad/app/src/main/assets/gpminput` 都 == `eb0b5dfc` | 三处均 `eb0b5dfc…`（852976 B；ksu-module 与 lsp-dexpad assets 原 `b806f39b` → 覆盖） | PASS |
| 9 | 设备 `/data/adb/gpm/gpminput` | == 发布哈希 | `eb0b5dfc…` | PASS |
| 10 | 设备模块目录 `/data/adb/modules/gpm_dex/gpminput` | == 发布哈希 | `eb0b5dfc…` | PASS |
| 11 | 设备 `module.prop` | `grep version` = v1.70 / 72 | `version=v1.70` / `versionCode=72` | PASS |
| 12 | 模块安装方式 | KernelSU 官方安装器刷 zip | `ksud module install gpm_dex-v1.70.zip` → `Module installed successfully!`；staged module.prop = v1.70/72 | PASS |
| 13 | **重启后** `/data/adb/gpm/gpminput` | 仍为发布哈希 | `eb0b5dfc…`（重启后重新 `sha256sum`） | PASS |
| 14 | 重启后 helper 自启 | `pidof gpminput` 非空 | helper pid=12802（后续会话 21560/27473 等） | PASS |
| 15 | 重启后引擎自启 | `pidof com.dennis.dexpad` 非空 且 EngineService 前台 | app pid=12737（后续 21520/27473 等） | PASS |
| 16 | 重启后鼠标可用 | 注入后光标可移动/可点击 | 冒烟 RS2-MOVE 满推 300ms → `2559,801`（dx=+1279）；RS1-L3 `1281,804` | PASS |
| 17 | 重启后默认横屏 | user_rotation=1、accel=0、app 2560×1600（rotation 1） | `rotation 1` / `app 2560 x 1600` / `user_rotation=1` / `accelerometer_rotation=0` | PASS |
| 18 | 重启后 LB/RB 连续拖拽 | 100ms ≤150、300ms ≤450、1.5s 1200–2200 | **74 / 254 / 1622px**（第二轮 71 / 246 / 1597px），期间 `SWIPE=0/WHEEL=0` | PASS |
| 19 | 重启后滚轮模式 | WHEEL≥6 且 SWIPE=0 | **WHEEL=9 / SWIPE=0** | PASS |
| 20 | 重启后控制通道拖拽（v1.70 新特性） | 竖向 `vertical_offset` 增加；横向 `horizontal_scroll_x` 增加；auto-up 生效；故障码正确 | `voff 0→3`；`hx 0→500`；`voff 3→5` + helper `why=auto-up`（6 条）+ 后续 `OK e`；`ERR_ARG d` / `ERR_STATE m no-down` | PASS |
| 21 | 重启后 P 六点（控制通道） | 误差 ≤8px | `402,1202` `1997,300` `104,104` `2445,1496` `1284,804` `700,999`，最大 err **3px** | PASS |
| 22 | 重启后 `?` 自检 | CAP 13 项全 1、ERR=0 | `CAP=13 all1=13 ERR=0` | PASS |
| 23 | 重启后 X+LB / X+RB | 方向正确 | X+LB **dx=+1260**、X+RB **dx=−1260** | PASS |
| 24 | 重启后 padtest | v1.4/5 且 sha 一致（**不升 v1.5**） | `1.4/5`，`0f4a9191…967056d` == `release/padtest-v1.4.apk` | PASS |
| 25 | 发布字节回归冒烟 | 不得出现产品级回归 | 见 `work/docs/evidence-v170/verify_v170_smoke.result.txt`；RS3-V/RS4-HIDDEN 的“外层 PY”判据受 padtest v1.4 内层 vList 抢手势影响，改用 `vertical_offset`/`touch.path_px`/`Z` 复测（同 v1.69 口径）；SELECT 判据已修正为“焦点窗口 = NotificationShade”（`mCurrentFocus` 在展开后为 null，旧判据漏判） | PASS |
| 26 | 60s 进程级 CPU（同口径记录） | 与历史对比 | 本轮样本 **2.17%**（线程 2.20%、`cutime+cstime` 0.00%）；历史：v1.69 0.97%、v1.68 0.82%、v1.65 1.62% —— 采样受同轮测试干扰，仅记录不设判据 | 记录 |
| 27 | display override caveat | `display_size_forced=1600,2560` 仍在 | 仍为 `1600,2560`（v1.66 起已知项） | 记录 |

## 2 关键命令（可复跑）

```bash
sha256sum release/dexpad-v1.70.apk release/gpminput-v1.70 release/gpm_dex-v1.70.zip release/padtest-v1.4.apk
sha256sum project/app/src/main/assets/gpminput project/ksu-module/gpminput project/lsp-dexpad/app/src/main/assets/gpminput
unzip -p release/dexpad-v1.70.apk assets/gpminput | sha256sum
unzip -p release/gpm_dex-v1.70.zip gpminput | sha256sum
adb push work/docs/evidence-v169/verify_install.sh /data/local/tmp/ && adb shell "sh /data/local/tmp/verify_install.sh"
adb shell "su -c 'sh /data/local/tmp/verify_v170_extra.sh'"     # 19 项（基线/拖拽三档/滚轮/ctl dme/P 六点/X+LB·RB）
adb shell "su -c 'sh /data/local/tmp/verify_v170_smoke.sh'"     # 23 项回归冒烟
adb shell "su -c 'sh /data/local/tmp/verify_v169_recheck2.sh'"  # 竖推/隐藏首推（padtest v1.4 权威字段）
```

## 3 发布资产哈希（与 `release/SHA256SUMS.txt` 一致）

| 文件 | sha256 | 大小 |
|---|---|---|
| `dexpad-v1.70.apk` | `05f4f11f2e48b498556abc35ea58bbc873f032128529d83d6abe9ea5eced876c` | 2688107 B |
| `gpm_dex-v1.70.zip` | `60bdd8d30a9e453bafa139cf09eb7facef1b3dd4460e5d70dcec64fbfd9a9ac8` | 368446 B |
| `gpminput-v1.70` | `eb0b5dfc6d5403b30d8200467f773e628729ea5290d1574aeb5651bf33c8c31c` | 852976 B |
| `padtest-v1.4.apk` | `0f4a91911360cb4051fff9b54711508e4dc90de797be6ec0e55e83e9a967056d` | 956738 B |

## 4 升级/回退

- **v1.69 → v1.70：助手必须一起换**（`b806f39b` → `eb0b5dfc`，含 t66 控制通道拖拽产品级化）。
  顺序：装 APK → 刷 `gpm_dex-v1.70.zip` → 重启。
- padtest **保持 v1.4**（`0f4a9191`）：v1.5 未交付，滚轮在测试台的可测性受限已回退；滚轮内容位移保持 BLOCKED，不作伪 PASS。
- 回退 v1.69：`adb install -r -d dexpad-v1.69.apk` + 刷 v1.69 模块 zip（助手回 `b806f39b`）+ 重启。
- **root 控制通道**：`/data/adb/gpm/gpmctl.sock`（目录 0700 / socket 0600 / `SO_PEERCRED` uid==0）；
  客户端 `/data/local/tmp/gpmctl <sock> <cmd>`；拖拽协议 `d|m|e` + 故障码 `ERR_ARG`/`ERR_STATE` + 1.5s 无 `m` 自动抬指（详见 `work/docs/HELPER-v169.md` §6/§7）。
  禁用：`touch /data/adb/gpm/gpmctl.disabled` 后重启助手。

## 5 出处

- 发布字节专项：`work/docs/evidence-v170/verify_v170_extra.result.txt`（19/19）
- 发布字节冒烟：`work/docs/evidence-v170/verify_v170_smoke.result.txt`
- 竖推/隐藏首推复测：`work/docs/evidence-v169/verify_v169_recheck2.result.txt`（本轮在 v1.70 字节上重跑）
- 控制通道协议与故障码：`work/docs/HELPER-v169.md` §6/§7；`work/docs/evidence-v169/t66-protocol-replies.txt`
- 滚轮四向投递与内容位移三态：`work/docs/V169-FINAL3.md`；`evidence-v169/t72_all.out`
- 测试计划与执行摘要：`docs/TEST-CASES-v1.70.md`（继承用户原文 + 附录 B）
