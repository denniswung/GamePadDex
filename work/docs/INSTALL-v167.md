# INSTALL-v167 · 哈希级装机校验（v1.67 发布字节）

> 证明「发布的文件」= 「设备上真正运行的字节」，且重启后仍是同一字节（`service.sh` 用模块目录覆盖 `/data/adb/gpm`）。
> 设备：SM-F9360（Android 16），adb `192.168.10.36:6666`，app 空间 2560×1600（`dumpsys display` rotation 1）。
> 探针：`work/docs/evidence-v167/verify_install.sh`（只读）。

## 1 校验表

| # | 检查项 | 期望 | 实测 | 结果 |
|---|---|---|---|---|
| 1 | APK 版本 | versionName=1.67 / versionCode=69 | `versionName=1.67` / `versionCode=69 minSdk=32 targetSdk=36` | PASS |
| 2 | 本地发布 APK | `release/dexpad-v1.67.apk` sha256=`8aeef7b7…2180312`，2678947 B | 相同（2678947 B） | PASS |
| 3 | 设备 base.apk == 本地 APK | 两处 sha256 相同 | `pm path` → `/data/app/~~Lhqe-OnC74mbMWKsgWtziw==/com.dennis.dexpad-O28Hp88AkpRzPC_tXES7lA==/base.apk` sha256=`8aeef7b7…2180312`（2678947 B） | PASS |
| 4 | APK 内 `assets/gpminput` 解包哈希 | == 发布助手哈希 | `1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf`（851928 B） | PASS |
| 5 | 发布助手 `release/gpminput-v1.67` | 同上 | `1bf7306f…f4bf`（851928 B） | PASS |
| 6 | 模块 zip 内 `gpminput` | 同上 | `1bf7306f…f4bf`（851928 B） | PASS |
| 7 | 模块 zip `module.prop` | version=v1.67 / versionCode=69 | `version=v1.67` / `versionCode=69` | PASS |
| 8 | 仓库内三处助手副本对齐 | `project/ksu-module/gpminput`、`project/lsp-dexpad/app/src/main/assets/gpminput`、`project/app/src/main/assets/gpminput` 都 == 发布哈希 | 三处均 `1bf7306f…f4bf`（851928 B） | PASS |
| 9 | 设备 `/data/adb/gpm/gpminput` | == 发布哈希 | `1bf7306f…f4bf` | PASS |
| 10 | 设备模块目录 `/data/adb/modules/gpm_dex/gpminput` | == 发布哈希 | `1bf7306f…f4bf` | PASS |
| 11 | 设备 `module.prop` | `grep version` = v1.67 / 69 | `version=v1.67` / `versionCode=69` | PASS |
| 12 | 模块安装方式 | 用 KernelSU 官方安装器刷 zip（非手工解压） | `ksud module install /data/local/tmp/gpm_dex-v1.67.zip` → `Installing to /data/adb/modules_update/gpm_dex` → `Module installed successfully!` | PASS |
| 13 | **重启后** `/data/adb/gpm/gpminput` | 仍为发布哈希（`service.sh` 从模块目录覆盖） | `1bf7306f…f4bf`（重启后重新 `sha256sum`） | PASS |
| 14 | 重启后 helper 自启 | `pidof gpminput` 非空 | helper pid=12636（后续会话 22455） | PASS |
| 15 | 重启后引擎自启 | `pidof com.dennis.dexpad` 非空 且 EngineService 前台 | app pid=13450（后续 22420） | PASS |
| 16 | 重启后鼠标可用 | 真机注入后光标可移动/可点击 | release 冒烟 RS2-MOVE：满推 300ms 落点 `2559,799`（dx=+1279）；RS1-L3 `1281,799` | PASS |
| 17 | 重启后默认横屏 | user_rotation=1、accelerometer_rotation=0、app 2560×1600（`dumpsys display` rotation 1） | `rotation 1` / `app 2560 x 1600` / `user_rotation=1` / `accelerometer_rotation=0` / `cmd window user-rotation=lock 1` | PASS |
| 18 | 重启后 LB/RB 双机制 | 触摸开=Swipe-only、触摸关=Wheel-only（发布包，改 prefs + 重启引擎） | `SWIPE=6/WHEEL=0`（LB、RB），`WHEEL=9/SWIPE=0`（LB、RB），恢复 `v_touch_scroll=true` | PASS |
| 19 | 重启后双击文案 | ButtonDetail 显示 400 ms | 真机文本 `连续按两下 A（400 ms 内）时触发` | PASS |
| 20 | 发布字节回归冒烟（整体） | 全通过 | `PASS=23 FAIL=0`（`verify_v167_smoke.result.txt`） | PASS |
| 21 | 60s 进程级 CPU（发布构建） | 与 v1.65 同口径，不超基线 | v1.67=`0.93%`（线程 0.93%、`cutime+cstime` 0.00%）；v1.66=0.82%；v1.65=1.62% | PASS |
| 22 | display override caveat（如实记录） | `display_size_forced=1600,2560` 仍在（清不掉） | `display_size_forced=1600,2560`；`wm size` = `Physical … / Override size: 1600x2560` | 记录 |

> 第 22 行是已知 caveat（v1.66 起记录）：三星保留用户早期的 `display_size_forced`，`wm size reset` / 置 null 均无效；
> v1.67 的横屏实现仍是 rotation 1 + 应用逻辑空间 2560×1600。

## 2 关键命令（可复跑）

```bash
# 本地哈希
sha256sum release/dexpad-v1.67.apk release/gpminput-v1.67 release/gpm_dex-v1.67.zip
sha256sum project/ksu-module/gpminput project/lsp-dexpad/app/src/main/assets/gpminput project/app/src/main/assets/gpminput
unzip -p release/dexpad-v1.67.apk assets/gpminput | sha256sum
unzip -p release/gpm_dex-v1.67.zip gpminput | sha256sum
# 设备侧（一条命令出全部）
adb push work/docs/evidence-v167/verify_install.sh /data/local/tmp/
adb shell "sh /data/local/tmp/verify_install.sh"
# 设备 base.apk
adb shell 'p=$(pm path com.dennis.dexpad | head -1 | cut -d: -f2); echo $p; sha256sum $p'
```

## 3 发布资产哈希（与 `release/SHA256SUMS.txt` 一致）

| 文件 | sha256 | 大小 |
|---|---|---|
| `dexpad-v1.67.apk` | `8aeef7b7d6d5ea01b650a26e18c0eb8f0c4233f647a0cb0a17048be1e2180312` | 2678947 B |
| `gpm_dex-v1.67.zip` | `b39af5c500055568331b4acbe0d755510306e686d24c94d1d05eaaf9a58c0f19` | 362092 B |
| `gpminput-v1.67` | `1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf` | 851928 B |
| `padtest-v1.1.apk` | `27478cef1c51acddc88c7ef662980ead4720bc95ce38635b0aa816f67de32e50` | 949222 B |

## 4 升级/回退

- 从 v1.66 升级：`adb install -r dexpad-v1.67.apk` + 刷 `gpm_dex-v1.67.zip` + 重启。
  助手字节与 v1.66 **完全相同**（`1bf7306f`），因此模块 zip 只更新了 `module.prop` 的版本号与脚本时间戳，不涉及运行时行为。
- 回退 v1.66：`adb install -r -d dexpad-v1.66.apk` + 刷 v1.66 模块 zip；助手无需变动。
- 模块 zip 内容仍为 `gpminput / inject.dex / module.prop / post-fs-data.sh / service.sh`（与 v1.44–v1.66 一致）。

## 5 出处

- 装机检查脚本与原始输出：`work/docs/evidence-v167/verify_install.sh` + 本次会话记录（摘录见 `work/docs/RELEASE-v167.md` §4）
- 发布字节抽检：`work/docs/evidence-v167/verify_v167_release.result.txt`（12/12）
- 发布字节回归冒烟：`work/docs/evidence-v167/verify_v167_smoke.result.txt`（23/23）
- LB/RB 专项（debug 变体）：`work/docs/VERIFY-lbrb-v167.md`（22/22）
