# REVIEW-hidden-swipe-v166 · t20 指针空闲隐藏后首次滑动审查

> 任务：t21（审查 t20：指针隐藏后首次滑动修复）· attempt 1
> 审查人：reviewer · 时间：2026-11-24 03:50 CST · 设备：SM-F9360（adb 192.168.10.36:6666，横屏 2560×1600）
> 结论：**PASS（带 t7 条件）**。t20 的 `doSwipe()` 隐藏分支加固成立（`pointerHidden` 时先 `showPointer()` 一次 `j`，无修正移动），新 APK `d2194406` 的隐藏首推竖 dPY=1415/横 dHS=512、可见竖推 1415、A 点击 1281,803（I5 0px）、越阈→SWIPE 57ms；APP §9.1/§9.2 已按 t19 修正。**但 t20 的真机证据目前只有 APP §10 摘要（无原始 uiautomator/logcat 文件），A1/A2/C 可见组未在新 APK d2194406 上重跑（t15 套件是 b7fa2662），APP §10:97 对“t18 dPY=0 真相”的解释混淆了两类 dPY=0；这些必须由 t7 的最终套件/原始日志闭合。**

## 0. 被审对象与产物

| 项 | 值 |
|---|---|
| APK | `d2194406a3d45dd768b02137af2aa1cd47a6c6f6363948d4aefa13c7a50bb475`（3132059 B；设备 base.apk = 本机 app-debug.apk） |
| 源码 | `EngineService.kt` sha256 `25D70F19…`（108507 B，03:37:14，仅 doSwipe 隐藏分支）；`RootInput.kt` `6C054476…`（15487 B，未改） |
| helper | `1bf7306f…`（未变） |
| 文档 | `APP-v166.md`（§10 新增；§9.1/§9.2 按 t19 修正；当前 101 行） |
| 证据 | `work/docs/evidence-v166-app/` 没有 t20 新日志；只有 `v166_t16_data.log`（t18 追加）；t20 的数字全在 APP §10 |
| 套件 | `v166_auto_suite.sh` `EXPECT_APK=d2194406…`（:36）；D6 `l3TookMs≤800`（:676-695）；B5/C4 条件化 |

## 1. t20 的 6 条 acceptance 核对

| # | acceptance | 判定 | 证据/说明 |
|---|---|---|---|
| 1 | 是否真的修好隐藏状态下第一次竖/横滑动（真机 uiautomator 前后差，不看 helper SWIPE 几何） | **PASS（APP §10 摘要；原始日志见 R1）** | APP §10:99 隐藏后首推竖 `PY 1415→0 dPY=1415`、横 `HS 0→512 dHS=512`；helper `SWIPE 0 1282,1040→1282,560 axis=Z`、`SWIPE 0 1282,803→130,803 axis=V`；APP §10 的数字是 uiautomator PY/HS 前后差，不是只看 helper SWIPE。**但原始 uiautomator/logcat 未落盘**（R1）。 |
| 2 | 不破坏“空闲隐藏=设备销毁、恢复=原地隐形出现且无修正移动”（日志 + 落点误差 ≤60px） | **PASS** | `EngineService.kt:605-617` hidePointer/showPointer 语义未改；`doSwipe` 隐藏分支 L2368-2372+ 只 `showPointer()` 一次；APP §10:101 隐藏后 A 点击 **1281,803**，日志 `pointer shown at last position (no correction move)`，0px 修正；t4 I5 旧证据 0px；落点误差 0–3px ≤60。 |
| 3 | 隐藏后第一次竖滑 dPY ≥1000、横滑 HS ≥400（真机 uiautomator） | **PASS（APP §10；原始日志见 R1）** | 竖 dPY=1415≥1000；横 HS=512≥400；APP §10:99；新 APK d2194406；`SWIPE_DROP=0`。 |
| 4 | 指针可见时滑动量/速度与修复前一致（A1/A2/C 不回退），且不引入每帧额外命令 | **PASS（带 t7 条件，R2）** | `doSwipe` 只在 `pointerHidden` 时 `showPointer()` 一次，不每帧；可见路径代码未改；t20 可见竖推 dPY=1415（APP §10:99）；**A1/A2/C 的完整套件是 t15 在 b7fa2662 上（A1 d=1352、A2 HS=512、C 1.029），未在 d2194406 重跑**；当前套件 EXPECT_APK 已改 d2194406，t7 必须重跑（R2）。 |
| 5 | 摇杆越阈→helper 收到 SWIPE ≤60ms（日志时间戳） | **PASS（APP §10；原始日志见 R1）** | APP §10:100 `57ms`；摇杆路径不新增命令（j 由既有 stickActive 恢复触发）；**按钮滑动路径最多一次 j**（见 R4）；原始时间戳未落盘（R1）。 |
| 6 | 代码只动 EngineService/RootInput 必要处，无副作用（滑动后遗留指针可见、POSPTR 冲突） | **PASS** | 只改 `EngineService.kt`（doSwipe 隐藏分支；`RootInput.kt` 未改）；`showPointer()` 只在 `pointerHidden` 时一次，`pointerHidden=false` 后不再发；POSPTR 只驱动居中校验（t16/t18 已核对），不参与 swipe 锚点；滑动后指针可见是“恢复”语义（A 点击/继续操作可见），idle 8s 后重新 hidePointer；无每帧命令。 |

## 2. 关键判断与证据质量

### 2.1 “隐藏首滑”是否真的修好

- t20 的结论是：t18 的 dPY=0 是**测试假象**——t18 的对照实验前页面已被 A1 滚到顶（PY=0），再向上推没有可滚空间；在 b7fa2662 上按“顶部起手 + 隐藏后首推”复测：竖 1415→0、横 0→512，**该缺陷在 b7fa2662 上并不存在**（摇杆路径 `stickActive` 时已 `showPointer()`，早于 doSwipe）。
- t20 仍做加固：`doSwipe()` 在发 V/Z 前若 `pointerHidden` 先 `showPointer()`（一次 `j`，只重建设备、不做任何修正移动），覆盖“隐藏后由按键动作触发滑动”的路径（摇杆路径原本已恢复，不重复发 j）。
- 审查判断：**加固代码正确、语义正确**（L2368-2372+；`showPointer` L613 只重建设备，不移动指针）；新 APK d2194406 的隐藏首推竖/横数字满足阈值。**但 t20 的“缺陷不存在”只对摇杆路径成立；t16 原始 dPY=0（PY 1415，pointer hidden + 未先 L3）与 t18 控制（PY 0，页面到顶）是两类不同假象，APP §10:97 把两者都归为“页面到顶”，解释不准确（R3）。**

### 2.2 隐形恢复语义

- hidePointer（L605-607）：`pointerHidden=true`，`root.hidePointer()` 销毁设备（瞬时消失）；showPointer（L613-617）：重建（`j`）并日志 `pointer shown at last position (no correction move)`，不写 REL/不移动。
- t20 的 doSwipe 隐藏分支：先 showPointer 再发 V/Z；因此“隐藏后第一次滑动”会先恢复指针（用户看到指针出现在最后位置），再做滑动；A 点击 1281,803 0px；符合“原地隐形出现、无修正移动”。
- 副作用检查：滑动后 `pointerHidden=false`，指针保持可见；下一次 idle 8s 后 `hidePointer`（L2032）重新销毁；不会每帧发 j；POSPTR 不参与锚点。**通过。**

### 2.3 延迟

- APP §10:100 `57ms`（越阈→helper 收到 SWIPE），满足 ≤60；摇杆路径不新增命令。
- **按钮滑动路径**（非摇杆，例如按键映射到 SCROLL_SWIPE_* / 组合键触发 doSwipe）在隐藏时多一次 `j`（设备重建设备约 120ms，`ensure_mouse` 同类）；这不是 t20 的 57ms 摇杆路径，t21 的验收只要求摇杆路径，但发布说明应区分（R4）。

### 2.4 代码范围

- t20 只改 `EngineService.kt`（doSwipe 隐藏分支）与 APP；`RootInput.kt` 未改；`Prefs.kt`/gpminput 未改；`doSwipe` 的其他路径（launcher/cooldown/几何）未动。
- 与 POSPTR 无冲突：POSPTR 只用于 L3 居中校验（t16 的 `onPositioned`），不设置 `ptrX/ptrY/pointerPos` 的 swipe 锚点；t20 的 showPointer 也不发 POSPTR。

## 3. Findings（非阻塞，t7 关闭）

| id | severity | problem | requiredFix | file:line |
|---|---|---|---|---|
| R1-T20-RAW-EVIDENCE | **medium** | t20 的隐藏首推/可见/A/I5/57ms 只有 APP §10 摘要；`work/docs/evidence-v166-app/` 没有 t20 的原始 uiautomator/logcat 文件（只有 t18 的 t16_data.log）。t21 无法独立复核 PY/HS、57ms、1281,803 的原始行。 | t7/ t20 把隐藏首推竖/横的 uiautomator before/after、A 点击 1281,803 日志、越阈→SWIPE 的 logcat 时间戳存到 `evidence-v166-app/v166_t20_*.log`；最终套件 result 保存到 `evidence-v166-verify`；不要只用 APP 摘要。 | `work/docs/APP-v166.md:94-101`；`work/docs/evidence-v166-app/` |
| R2-T20-NEW-APK-T4 | **medium** | t15 的完整套件（67 PASS/1 FAIL D6）是 **b7fa2662**；t20 新 APK `d2194406` 只做了隐藏首推/可见竖推/A 点击，A1/A2/C 可见组未在 d2194406 重跑；当前套件 EXPECT_APK 已改 d2194406，但无 d2194406 的 result。 | t7 用 `EXPECT_APK=d2194406` + helper 1bf7306f 重跑完整套件，保存 result/console，确认 A1/A2/C/D5/I5/D6 全 PASS；D6 l3TookMs≤800；B5/C4 条件化；不得用 b7fa2662 的 67/1 代替。 | `work/scripts/v166_auto_suite.sh:36`；`work/docs/APP-v166.md:94-101`；`work/docs/evidence-v166-verify/` |
| R3-T20-EXPLANATION | **medium** | APP §10:97 把“t18 的 dPY=0 真相”归为“页面已被 A1 滚到顶（PY=0）”；但 t16/t18 原始 `v166_t16_data.log` 的竖向 dPY=0 是在 **PY 1415**（指针隐藏 + 未先 L3），页面并非到顶；t18 的“idle 10s 后 PY 0→0”才是页面到顶的控制。两类假象被混为一谈；t20 的“缺陷在 b7fa2662 不存在”只对摇杆路径（stickActive showPointer）成立，不是对 t16 原始脚本成立。 | 把 §10:97 改成两类：①t16 原始 dPY=0 = PY 1415 + pointerHidden + 未先 L3（摇杆路径不触发 stickActive 分支）；②t18 控制 dPY=0 = 页面已到顶 PY=0（不可滚）；t20 的 pre-fix 顶部起手 1415/512 证明隐藏首推本身可滚，t20 加固覆盖按钮路径。不要用“页面到顶”解释 t16 的 PY 1415 dPY=0。 | `work/docs/APP-v166.md:97`；`work/docs/evidence-v166-app/v166_t16_data.log:21-24` |
| R4-T20-BUTTON-J | low | t20 的 57ms 是摇杆路径；按钮触发 doSwipe 的隐藏分支会先 `j`（设备重建，约 120ms）再发 V/Z，按钮路径的“越阈→SWIPE”不是 57ms。APP §10:100 已提“按钮滑动路径最多一次 j”，但发布说明不要把 57ms 泛化到所有滑动。 | APP/发布说明区分：摇杆路径 ≤60ms（57）；按钮触发隐藏首滑多一次 j（约 120ms 设备重建），可接受但需标注；若要求按钮路径也 ≤60ms，则需预热设备或不为按钮路径 showPointer（会牺牲锚点一致性）。 | `work/docs/APP-v166.md:100`；`EngineService.kt:2368-2372` |
| R5-T20-SEMANTICS | low | 隐藏首滑的 showPointer 会让指针在滑动开始前可见（这是“恢复”语义）；滑动结束后 pointerHidden=false，指针保持可见，直到下一次 idle 8s 再销毁。t20 的“隐形恢复”应明确“恢复后可见是预期，不是遗留副作用”；不影响 A 点击/I5。 | APP §10 写清：隐藏首滑 → showPointer（原地最后位置，0 修正）→ 滑动；滑动后指针保持可见，idle 8s 再销毁；A 点击 1281,803 0px；与“空闲隐藏=设备销毁、恢复=原地出现”一致。 | `work/docs/APP-v166.md:98-101`；`EngineService.kt:613-617,2032` |
| R6-T20-APP9 | low | t20 已按 t19 修正 §9.1（direct/proxy 标注；proxy A 低估仅参考）与 §9.2（同一时间 1.029 正式；单手势 2.057 设计取舍）；t19 的 R1/R2 关闭。但 t19 的 R3（t15 原始 result/D6）与 R4（release CPU）仍归 t7。 | t7 落 t15/t20 的最终套件 result、release CPU；发布说明统一 b7fa2662→d2194406 的新哈希，§9.1/§9.2 口径保留。 | `work/docs/APP-v166.md:75-85`；`work/docs/REVIEW-app-v166-r3.md` |
| R7-T20-PREMISE | info | t20 的“缺陷”在 t16/t18 的原始脚本里是探针假象（pointerHidden/页面到顶），摇杆路径本身在 b7fa2662 已可首滑；t20 的加固针对按钮触发 doSwipe 路径，仍是有价值的防御。 | 保留加固；发布说明不要写“修复了隐藏首滑失效”（会误导为所有路径都坏过），改为“隐藏后首滑恢复指针（按钮路径加固），摇杆路径原本已恢复”。 | `work/docs/APP-v166.md:94-101` |

## 4. 结论与给 t7 的条件

t20 的加固代码正确、语义正确：隐藏后 doSwipe 先 showPointer 一次 j，无修正移动；A 点击 1281,803 0px；隐藏首推竖 1415/横 512；可见竖推 1415；摇杆越阈 57ms；只改 EngineService + APP；POSPTR 无冲突。**t21 判 PASS（带 t7 条件）**。

t7 发布前必须：
1. 在 `d2194406`+`1bf7306f` 上重跑完整套件并保存 result/console，确认 A1/A2/C/D5/I5/D6 全 PASS（R2）；D6 l3TookMs≤800；B5/C4 条件化。
2. 把隐藏首推/可见/A/I5/57ms 的原始 uiautomator/logcat 存到 evidence（R1）。
3. 修正 APP §10:97 的两类 dPY=0 解释（R3）；区分摇杆 57ms 与按钮路径的一次 j（R4）；写清恢复后可见是预期（R5）；发布说明不要把“隐藏首滑失效”泛化（R7）。
4. release 进程级 CPU 与最终 hash（d2194406 + 1bf7306f）由 t7 统一（R6）；b7fa2662 的 67/1 不能再当最终 APK 证据。

## 5. 复现

```sh
# 只读复核（本审查执行）
adb -s 192.168.10.36:6666 shell 'p=$(pm path com.dennis.dexpad | head -1 | sed s/package://); sha256sum "$p"'
#   d2194406…（= 本机 app-debug.apk，3132059 B）
sha256sum project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt  # 25D70F19…
sha256sum project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt      # 6C054476…（未改）
# 隐藏首推复现：顶部起手 + idle 9s 隐藏 + 竖/横推
adb -s 192.168.10.36:6666 shell 'settings put secure dexpad_idle_hide_sec 8' # 或 Config UI
# 见 work/scripts 的 t16/t20 探针（需先 starts/L3 或等 idle 隐藏）
```

## 6. 限制

- 未在设备上重放隐藏首推/57ms（设备在 t20/t7 使用中）；t20 的 APP §10 摘要、t20 的 t16_data.log（t18 追加）、EngineService 源码、t4/t15/t19 证据为审查材料；本次做了只读 APK/源码 hash、doSwipe/showPointer 源码行、APP §9/§10 逐项核对。
- t20 的原始 uiautomator/logcat 未落盘，R1 的 PASS 是“APP §10 数字 + 源码 + 既有 t4/t15 语义”的合议，不是独立重放；t7 必须补原始证据。
- 按钮触发 doSwipe 的隐藏分支多一次 j 的 120ms 未实测；APP §10 只写“最多一次 j”，R4 需 t7 在按钮路径补一次时延。
