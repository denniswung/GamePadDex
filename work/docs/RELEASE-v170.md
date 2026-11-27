# RELEASE-v170 · v1.70 集成发布报告（integrator / t69）

> 目标：发布 v1.70（padtest 滚轮 + 控制通道拖拽产品级化）：版本 1.69→1.70（71→72）、三处助手副本对齐 `eb0b5dfc`、
> clean assembleRelease、发布四件套 + SHA256SUMS、装机 + reboot 哈希级校验、README / TEST-CASES-v1.70 / INSTALL-v170 / RELEASE-NOTES、
> 备份、GitHub Release v1.70、发布字节专项 + 回归冒烟。
> 设备：SM-F9360（Android 16），adb `192.168.10.36:6666`，app 空间 2560×1600（`dumpsys display` rotation 1）。

## 1 版本

| 项 | 值 | 校验 |
|---|---|---|
| `project/lsp-dexpad/app/build.gradle.kts` | `versionCode = 72` / `versionName = "1.70"` | 从 71/1.69 递增 |
| `project/ksu-module/module.prop` | `version=v1.70` / `versionCode=72` | 仓库 + 设备两处 |
| `work/scripts/set_version.py` | `VER="1.70"` / `CODE=72` | 同步 |
| `project/padtest/app/build.gradle.kts` | `1.4` / `5` | **未改**（合同要求：padtest 仍为 v1.4，不升 v1.5） |
| 设备 | versionName=1.70 / versionCode=72；module.prop v1.70/72 | 重启后复验 |

## 2 助手副本对齐 + 构建

- **对齐到 `eb0b5dfc6d5403b30d8200467f773e628729ea5290d1574aeb5651bf33c8c31c`（852976 B，t66 最终）**：
  `project/app/src/main/assets/gpminput`（已是）→ 覆盖 `project/ksu-module/gpminput`、`project/lsp-dexpad/app/src/main/assets/gpminput`（原 `b806f39b`）；
  `release/gpminput-v1.70`、模块 zip 内、APK `assets/gpminput`（解包校验）—— **六处同哈希**。
- 构建：`./gradlew --no-daemon --no-build-cache clean assembleRelease` → `BUILD_EXIT=0`；
  `app-release.apk` = `05f4f11f…eced876c`（2688107 B），`output-metadata.json` = versionCode 72 / versionName 1.70。
- 模块 zip 重打包（`gpminput / inject.dex / module.prop / post-fs-data.sh / service.sh`），`module.prop` = v1.70/72。

## 3 发布资产（与 `release/SHA256SUMS.txt` 一致，86 行、不含自身）

| 资产 | sha256 | 大小 |
|---|---|---|
| `dexpad-v1.70.apk` | `05f4f11f2e48b498556abc35ea58bbc873f032128529d83d6abe9ea5eced876c` | 2688107 B |
| `gpm_dex-v1.70.zip` | `60bdd8d30a9e453bafa139cf09eb7facef1b3dd4460e5d70dcec64fbfd9a9ac8` | 368446 B |
| `gpminput-v1.70` | `eb0b5dfc6d5403b30d8200467f773e628729ea5290d1574aeb5651bf33c8c31c` | 852976 B |
| `padtest-v1.4.apk` | `0f4a91911360cb4051fff9b54711508e4dc90de797be6ec0e55e83e9a967056d` | 956738 B |

**哈希链 / 三元组**

```
验证三元组（t72 采样，未变）：app d31e5128 (1.69/71) / helper eb0b5dfc / padtest 0f4a9191 (v1.4/5)
v1.70 发布字节：              app 05f4f11f (1.70/72) / helper eb0b5dfc（同） / padtest 0f4a9191（同）
helper: a1d06e2e (v1.68) → b806f39b (v1.69) → eb0b5dfc (v1.70, t66 控制通道拖拽产品级化)
```

> v1.70 与 v1.69 的应用源码相同，仅 versionCode/Name 与内置助手不同，所以 APK 哈希按发布重新计算；
> 发布字节上另跑 19 项专项 + 23 项冒烟（§5），不只依赖 t72 的 1.69 字节结论。

## 4 装机 + 重启验证（摘要，完整表见 `work/docs/INSTALL-v170.md`）

| 步骤 | 实测 |
|---|---|
| `adb install -r release/dexpad-v1.70.apk` | Success；versionName=1.70 / versionCode=72 |
| `ksud module install gpm_dex-v1.70.zip` | `Module installed successfully!`；staged module.prop = v1.70/72 |
| `adb reboot` 后 | `version=v1.70 versionCode=72`；`/data/adb/gpm` = 模块 = `eb0b5dfc…`；helper pid=12802、engine pid=12737；Awake |
| base.apk | `05f4f11f…`（2688107 B）== 本地 |
| 横屏 | rotation 1 / app **2560×1600** / user_rotation=1 / accel=0 |
| 鼠标 | RS2-MOVE 满推 300ms → `2559,801`（dx=+1279）；RS1-L3 `1281,804` |

## 5 发布字节验证

### 5.1 专项（`verify_v170_extra.sh`）→ **19/19 PASS**

- 基线：APK `05f4f11f` / 1.70·72 / 助手 `eb0b5dfc` / padtest 1.4·5 `0f4a9191` / 横屏。
- 拖拽三档 **74 / 254 / 1622px**（第二轮 71 / 246 / 1597px），`SWIPE=0 / WHEEL=0`。
- 滚轮模式 **WHEEL=9 / SWIPE=0**。
- **控制通道 d/m/e（本轮新特性）**：竖向 `vertical_offset 0→3`；横向 `horizontal_scroll_x 0→500`；
  auto-up `voff 3→5` + helper `why=auto-up` 6 条 + 后续 `OK e`；故障码 `ERR_ARG d` / `ERR_STATE m no-down`。
- P 六点最大 err **3px**；`?` 自检 CAP 13/13；X+LB **+1260** / X+RB **−1260**。

### 5.2 回归冒烟（`verify_v170_smoke.sh`，23 项）→ 21 项直接 PASS

L3 / 满推 / 横推 512 / 隐藏首推横推 / Y+上·下 / d-pad+DPAD_CENTER / X 双击 / X+LB +664 / X+RB −1536 / I5 0px /
SELECT（判据修正后 **PASS**，`shade=2`、`NOTIF rc=0 dur=389ms`）/ 横屏守护 ≈3750ms / CURSORQ=0。

**判据失效项（非产品问题）**：`RS3-V` / `RS4-HIDDEN` 读“外层 PY”，被 padtest v1.4 内层 `vList` 抢手势（外层不动）；
用 `verify_v170_recheck2.sh` 复测：`vertical_offset 0→14`、`touch.path_px 475`、helper `Z=4` → **2/2 PASS**。

**本轮修掉的一个测试脚本缺陷**：`shade()` 只匹配 `mCurrentFocus=Window{...NotificationShade`，但通知栏展开后
`dumpsys window` 给的是 `mFocusedWindow=NotificationShade` + `mCurrentFocus=null`，旧判据把正常展开误判成未展开。
已改为同时接受两种写法（随后 3/3 复现 `mFocusedWindow=NotificationShade`），并在 README §9 记录。

## 6 文档 / 备份

| 产物 | 说明 |
|---|---|
| `README.md` | 当前版本 v1.70；§4 安装文件名 + `gpminput-v1.70`（`eb0b5dfc`）；§8 测试表加 v1.70 两项；§9 新增「v1.70 滚轮两段结论（投递 PASS / 内容位移 BLOCKED）」「控制通道 d/m/e」「padtest 保持 v1.4」「SELECT 判据」；§10 新增 v1.70 行 |
| `docs/TEST-CASES-v1.70.md` | **继承 v1.69 用户原文 359 行（未改动）** + 附录 B：字节基线、**新增用例**（滚轮 4 向投递 + 内容位移 BLOCKED、控制通道 d/m/e 协议/auto-up/故障码、MIX-001/003、发布字节回归）、全量 37/5/100、发布清单（t65/t66/t71/t72 + t68）、已知限制、用词约束 |
| `release/RELEASE-NOTES.md`、`docs/RELEASE-NOTES.md` | v1.70 发布说明：开篇 `product FAIL = 0` / 门槛未达 + 偏差批准 / 上限 40–45/142；**滚轮明确写成“投递 PASS、内容位移 BLOCKED”**；控制通道协议与实测；升级注意；盲区。禁词扫描 0 hits |
| `work/docs/INSTALL-v170.md` | 装机校验表 27 行（APK/助手六处/zip 内/APK assets/重启后/横屏/拖拽三档/滚轮/ctl dme/P 六点/CAP/X+LB·RB/padtest/冒烟/CPU）+ 复跑命令 + 升级回退 + 通道安全 |
| `release/docs/TEST-CASES-v1.70.md`、`v170_verify_extra.sh`、`v170_verify_smoke.sh`、`v170_verify_recheck2.sh` | 发布目录副本 |
| `backup/self-backup/GamePadDex-v1.70-20261127-1430.zip` | **153.34 MB**（160792808 B），sha256 `82ef7bfa027cdfb8fd86a0773e92bcce37f31c5462458ba84326c225dadc17c9`，1719 条目 |

`release/SHA256SUMS.txt` 重生成（86 行，排除自身），逐行自检 **mismatch=0**。

## 7 GitHub

| 项 | 值 |
|---|---|
| 推送 | `git push` 直连不稳定，沿用 **Git Data API 树对比**（`work/docs/evidence-v167/push_via_api_tree.py`） |
| 提交 | 远端 main = **`ebe78f3d4a14941eec830f0b33cb626c195eaf21`**（父 `367c63c`），远端 tree `017e20c5…` == 本地 HEAD tree（`TREE MATCH`） |
| 标签 / Release | tag **v1.70** → `ebe78f3`；https://github.com/denniswung/GamePadDex/releases/tag/v1.70（非 draft/pre） |
| 资产 | 5 个；**重新下载 sha256 与本地 5/5 相同** |

## 8 偏差与边界（如实记录）

1. **padtest 未升 v1.5**：按合同（v1.5 未交付）保持 **v1.4 `0f4a9191`**；滚轮内容位移因此保持
   **BLOCKED(wheel-content-displacement-unmeasurable)**，没有为了凑结论去改测试台或改判据。
2. **滚轮结论按两段写**：投递 PASS、内容位移 BLOCKED；RELEASE-NOTES/README/TEST-CASES 三处都分开写，未合并成“S 8 内容 PASS”。
3. **发布门槛**：未达（P0 41.1% / P1 16.7% / 100 BLOCKED），按 `V169-FINAL-VERIFY.md` 的 `Maintainer override: captain, 2026-11-27` 偏差发布；
   发布文档只写 `product FAIL = 0` + 门檻事实 + 上限 40–45/142，禁词扫描 0 hits。
4. **RS3-V / RS4-HIDDEN / SELECT 三个判据问题**都是测试脚本层面（外层 PY 受 v1.4 手势归属影响、`mCurrentFocus` 展开后为 null），
   已分别用 v1.4 权威字段与修正后的焦点判据复测；产品侧未改动。
5. **CPU 采样 2.17%** 高于 v1.69 的 0.97%，但本轮冒烟与专项紧邻采样（设备仍在收尾），按“同口径记录、不设判据”处理，未据此下结论。
6. **v1.70 应用源码与 v1.69 相同**：本轮产品变化在助手（`eb0b5dfc`，控制通道拖拽产品级化）与测试台（滚轮支持，v1.4 已含）；
   APK 仅版本号变化，发布字节仍单独重跑 19 项 + 23 项。

## 9 acceptance 对照（t69 合同）

| # | 要求 | 结果 | 证据 |
|---|---|---|---|
| 1 | 版本 1.69→1.70（71→72），同步 build.gradle / module.prop（仓库与设备）；padtest 仍 v1.4 | PASS | §1、`INSTALL-v170.md` #1/#11/#24 |
| 2 | 三处助手副本与 release 助手对齐 `eb0b5dfc` | PASS | §2（六处同哈希） |
| 3 | release/ 产出 APK / 模块 zip / 助手 / padtest-v1.4 / SHA256SUMS（内容一致） | PASS | §3（86 行、mismatch=0） |
| 4 | 装机 + reboot：base.apk == 本地、助手六处同哈希、module.prop v1.70/72、自启/鼠标/横屏 | PASS | §4、`INSTALL-v170.md` #2–#17 |
| 5 | README v1.70 行 + TEST-CASES-v1.70（继承用户原文 + 新增用例/摘要）+ INSTALL-v170 校验表 | PASS | §6 |
| 6 | 发布说明写 `product FAIL = 0`、门槛状态、自动化上限；禁用「通过/全过/门槛通过/全部 PASS」 | PASS | §5.2、§8-3（禁词扫描 0 hits） |
| 7 | 备份包 + GitHub Release v1.70（5 资产、SHA256SUMS 0 mismatch） | PASS | §6、§7 |
