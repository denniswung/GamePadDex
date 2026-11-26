# v1.69 发布说明（2026-11-27）

包名：`com.dennis.dexpad`　versionCode **71** / versionName **1.69**
配套：KernelSU 模块 `gpm_dex` v1.69 · 助手 `gpminput` v1.69（`b806f39b`，含 P 闭环与 root 诊断通道）· 测试台 `com.dennis.padtest` **v1.4**（`0f4a9191`）

| 资产 | 文件 | sha256 | 大小 |
|---|---|---|---|
| 应用 | `dexpad-v1.69.apk` | `d31e51285a0a3baa71a75ed2b7dca1a7f88697685ae982c35e2f807bfc92c7fb` | 2687735 B |
| 模块 | `gpm_dex-v1.69.zip` | `b9785087b35f3e6e341d09bf7950334d18be384d6804e3f8481e51c1ee504097` | 368072 B |
| 助手 | `gpminput-v1.69` | `b806f39ba51278a73aad121be4019820b7961dcb0935971b64d3a02373cd2a4d` | 852960 B |
| 测试台 | `padtest-v1.4.apk` | `0f4a91911360cb4051fff9b54711508e4dc90de797be6ec0e55e83e9a967056d` | 956738 B |

模块 zip 内 `gpminput` 与 `gpminput-v1.69` 同哈希；APK 内 `assets/gpminput` 解包后亦为同一哈希（三处一致）。

## 0 覆盖率与门槛（先读这一段）

- **`product FAIL = 0`**：142 条用例里 **37 PASS / 5 FAIL / 100 BLOCKED**，5 条 FAIL 全部不是产品缺陷
  （3 条经维护者批准降级：MIX-009 / LOG-001 / RPT-002；1 条 padtest TXT 导出未实现：RPT-003；1 条启动时序：BTN-001 已在应用侧修 a11y，复测可见）。
- **发布门槛：未达**（P0 41.1%、P1 16.7%）；**经维护者（captain，2026-11-27）批准按偏差发布**，
  依据：`product FAIL = 0` + 100 条 BLOCKED 全部来自测试通道/自动化能力 + 关键行为已真机抽样覆盖。
- **可自动化上限 40–45/142**，其余以已知限制 + 真机抽样覆盖，**不虚报 PASS**。
- 明细：`work/docs/V169-FINAL.md`、`work/docs/V169-FINAL-VERIFY.md`（含 §5 用词约束），
  原始证据 `work/docs/evidence-v169/`（final_all.out、scr_final.out、report_s22*.json、ui_*.lines、截图）。

## 1 本轮修复（对应用户测试计划里的 FAIL 项）

### 1.1 `P` 绝对定位：开环增益偏差 34% → 闭环修正（t47）

- **问题**：`pointer_goto()` 用固定增益 `3.25`，本机 `pointer_speed=-1` 实测 ~2.14 → 落点偏小 34%
  （例：`P 400,1200` 落到 `264,796`；`P 2000,300` 落到 `1329,197`）。
- **改法**：读真实光标（`c`/`dumpsys input`）→ 朝屏幕内部 REL 80px 实测增益 → 每步用实际位移重估 → 最多 4 次修正
  （≤8px 提前退出）→ 落点回写悬停锚点（`g_ptr_x/g_ptr_y`，mmap 共享页对 fork 子进程可见）；
  日志 `POSPTR x,y closed gain=… final=… err=… iters=… anchor=…`（保留旧 `POSPTR x,y` 行）。
- **发布字节实测（六点，root 控制通道）**：`402,1202` / `2000,300` / `99,102` / `2445,1496` / `1280,802` / `694,999`，
  **最大误差 6px**（判据 ≤8px），`c` 回包与 `final` 一致（`CURSOR 402 1202` … `CURSOR 694 999`）。

### 1.2 SCR-022：右摇杆横向不驱动横向容器（t53）

- **根因**：横向与竖向共用 `swipeCooldownUntil` 被吞 + 外部 `P`/真实光标移动后引擎 `ptrX/ptrY` 估算未同步，锚点落在纵向列表。
- **改法**：横向独立冷却 `hSwipeCooldownUntil` + `doSwipe(ignoreCooldown=true)`；横向按住期间每 400ms 发 `c` 被动同步真实光标；
  新增 `hswipe dir/nx/anchor/hidden` 日志。
- **实测**：分页区锚点 `1282,1599` → `horizontal_scroll_x` **0→512→0**；纵向列表锚点 `1282,804` → scrollX 保持 0、不越界。

### 1.3 padtest v1.3 / v1.4（t55 / t60）

- **v1.3**：删除整页 `PassThroughScrollView`（它在 v1.2 引入分页回归），恢复普通 `ScrollView`；左右列表在 ACTION_DOWN 时
  `requestDisallowInterceptTouchEvent(true)` 保留独立滚动。注入式横向 swipe 回到 **0→512→0**。
- **v1.4**：`vList` 在 ACTION_DOWN 时也 `requestDisallowInterceptTouchEvent(true)`，内层列表手势不再被外层抢
  （内层 `vertical_offset 0→2`、外层标题 603 不动；外层锚点则外层滚动 603→42）。
- **padtest 里程碑说明**：v1.2 的 `PassThroughScrollView` 引入了分页回归与 vList 手势被抢，已分别由 t55（删除整页 PassThrough）
  与 t60（vList `requestDisallowInterceptTouchEvent`）修复；**v1.3/v1.4 行为以 t55/t60 为准**，不要再引用 v1.2 的分页结论。

### 1.4 助手 root 诊断通道（t48 / t54）

- 新增 `/data/adb/gpm/gpmctl.sock`（目录 0700、socket 0600、`SO_PEERCRED` uid==0），与 App 通道并存、复用同一套命令语义；
  断开不影响 App 会话；`gpmctl.disabled` 存在时不创建。
- 用途：release 包（无调试广播）也能脚本化 `P` / `c` / `?` 等诊断；本次发布字节的六点与自检就是走这条通道。
- 客户端：`/data/local/tmp/gpmctl <sock> <cmd...>`（`work/docs/HELPER-v169.md` §6）。

## 2 发布字节验证（装机 + reboot 之后）

| 项目 | 结果 |
|---|---|
| 装机/自启/横屏 | base.apk == 本地 `d31e5128…`；`/data/adb/gpm` == 模块 == `b806f39b…`；module.prop v1.69/71；helper + EngineService 自启；`user_rotation=1`、`accel=0`、app 2560×1600、display rotation 1 |
| `P` 六点 | 6/6，最大误差 6px（≤8px） |
| `?` 自检 | CAP **13/13 = 1**、ERR=0；`INFO pointer device=off` 等 5 条 INFO 正常 |
| LB/RB 连续拖拽 | 100ms **74px**（≤150）、300ms **251px**（≤450）、1500ms **1636px**（1200–2200）；期间 `SWIPE=0 / WHEEL=0` |
| 滚轮模式 | RB 1.5s → **WHEEL=9 / SWIPE=0** |
| X+LB / X+RB | dx **+1260** / **−1260**（方向正确） |
| 回归冒烟 23 项 | 21 项直接 PASS；RS3-V / RS4-HIDDEN 的"外层 PY"判据因 padtest v1.4 手势归属改变失效，改用 v1.4 权威字段复测：`vertical_offset 0→14`、`touch.path_px 486`、helper `Z=4` → **判 PASS**（`verify_v169_recheck2.result.txt`） |
| 其它回归 | L3 `1281,804`、满推 `2559,801`、Y+上 PiliPlus / Y+下 抖音、d-pad+DPAD_CENTER、X 双击 Recents、I5 0px、SELECT `rc=0 dur=402ms`、横屏守护 ≈3250ms、60s 空闲 CPU **0.97%**、CURSORQ=0 |

证据：`work/docs/evidence-v169/`（`verify_v169_extra.result.txt` 16/16、`verify_v169_smoke.result.txt`、`verify_v169_recheck2.result.txt` 2/2、`selftest-cap.txt`）。

## 3 升级注意（重要）

- **助手必须与 APK 一起换**：v1.69 助手 `b806f39b` 含 P 闭环与 `gpmctl` 通道。升级顺序：装 APK → 刷 `gpm_dex-v1.69.zip` → **重启**。
- **padtest 直接装 v1.4**（同签名覆盖）；v1.2/v1.3 有已知回归，不要回退使用。
- 回退 v1.68：`adb install -r -d dexpad-v1.68.apk` + 刷 v1.68 模块 zip（助手回 `a1d06e2e`）+ 重启。

## 4 已知限制与盲区

- **100 条 BLOCKED 的分组**：`ctl-channel-drag-not-delivered` 32 条（helper 已发 `d/m/e`、测试台侧收不到，属测试通道）、
  `evidence-incomplete`（垂直滚轮 `S 8` 无 offset 字段）、`release-no-debug-channel`（v1.69 起有 `gpmctl` 可补）、
  UI 二级交互 40 条（CFG/BTN/LOG/RPT）、长压测 8、DeX/多屏 6、真手柄 1。
- **测试台盲区**：`uiautomator` 在指针 overlay 下会失败；`screencap` 在拖拽中是陈旧帧；padtest v1.4 内层列表会接住竖推（外层 PY 不动）。
  这些都必须用参数化/权威字段（`vertical_offset`、`horizontal_scroll_x`、`touch.path_px`）判定，不能用单一的"文本/标题位移"判据。
- 滚轮仍受指针悬停窗口限制（`ensureWheelAnchor` 已缓解）；`display_size_forced=1600,2560` 清不掉（v1.66 起 caveat）；
  DeX 外接屏未完整回归；触摸点击依赖估算坐标。

## 5 安装

```bash
adb install -r dexpad-v1.69.apk
adb install -r padtest-v1.4.apk
adb push gpm_dex-v1.69.zip /data/local/tmp/
adb shell "su -c '/data/adb/ksu/bin/ksud module install /data/local/tmp/gpm_dex-v1.69.zip'"
adb reboot
adb shell "su -c 'grep version /data/adb/modules/gpm_dex/module.prop; sha256sum /data/adb/gpm/gpminput'"
# 预期：version=v1.69 / versionCode=71；助手 sha256 = b806f39b…cd2a4d
```

校验和见同目录 `SHA256SUMS.txt`；装机校验表见 `work/docs/INSTALL-v169.md`。
