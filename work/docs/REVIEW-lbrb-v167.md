# REVIEW-lbrb-v167 · t22 LB/RB 单一机制审查

> 任务：t24（审查 t22 + t23 证据）· attempt 1
> 审查人：reviewer · 时间：2026-11-24 14:05 CST · 设备：SM-F9360（adb 192.168.10.36:6666，横屏 2560×1600）
> 结论：**PASS（带 t15/t7 条件）**。t22 的“先滑再滚”混合已从源码删除，按压内 wheel/swipe 由 `holdTouchMode` 结构性互斥，vTouchScroll 在按压开始定一次、30s 不切换；X+LB/RB 与右摇杆滚动未改；ButtonDetail 400ms 与 `DOUBLE_WINDOW=400` 一致。**t22 原始 APK `20eddf98` 在 t23 只有 16/18（B-RB、C-MOVE FAIL），t26 修好滚轮锚点/RB 锚点、t28 修好 E-SPEED，t29 在最终 APK `df26e461` 上 22/22 PASS——t22 的 7 条 acceptance 由 t22+t26+t28 的最终态满足，t22 原始态不满足（见 R1/R2）。**
> 最终产物：APK **`df26e461bcfaf6243a50f0b6ee72e51a0d21eb0de0c74bf098a0422cfb3e3a9e`**（设备=本机，1.66/68）、helper `1bf7306f…`；发布/集成必须用该哈希，不能用 t22 原始 `20eddf98`。

## 0. 被审对象与三轮演进

| 轮次 | APK | 结果 | 关键差异 |
|---|---|---|---|
| t22 原始 | `20eddf98` | t23 16/18；B-RB、C-MOVE FAIL | “先滑再滚”已删；但 wheel 只对悬停窗口有效，指针隐藏后不滚；RB 锚点被底部子视图拦截 |
| t26 修复 | `8ea4cb07` | t27 21/22；E-SPEED 3300<3360 | `ensureWheelAnchor()` 隐藏/偏离时 showPointer+positionPointer(task 中心)；RB/LB 锚点自适应；E 因 540/560 交替差 1.8% |
| t28 修复 | `df26e461` | **t29 22/22 PASS** | 纵向行程固定 560px（横向 30%/70% 交替）；E=3360；其余不变 |

## 1. t22 的 7 条 acceptance 核对（最终态）

| # | acceptance | 判定 | 证据 |
|---|---|---|---|
| 1 | 同一按压内只一种机制（触屏=连续滑动 / 桌面=滚轮） | **PASS（最终态）** | t29 A-LB/A-RB：SWIPE=6（Z=6）/WHEEL=0，`mode=swipe`；C-WHEEL：WHEEL=9/SWIPE=0，`mode=wheel`；源码 `EngineService.kt:1404-1434` 按压分支二选一 |
| 2 | “先滑再滚”混合从源码删除，不是调参/if 掩盖 | **PASS** | 源码 L1404-1434：`if (holdTouchMode) {swipeHold=…; swipeStep} else {ensureWheelAnchor(); wheelHold=…}`；没有“先 doSwipe 再 wheelHold”顺序；释放 `wheelButtons`/`wheelHold`/`swipeHold` 清理（L1471-1477）；t29 A 互斥 6/0、0/9 |
| 3 | 机制选择由 vTouchScroll 稳定决定，按压期间不切换 | **PASS** | 源码 L1407 `holdTouchMode = cVTouch` 只在按压开始赋值；按压内所有 step 读同一 `holdTouchMode`；t29 D 触屏 5/5、滚轮 5/5，切换 0；t22 的 30s 稳定（24/0、0/36、mode ×3）仍有效 |
| 4 | 连续性/速度达标（6×560，周期 250ms，空档小） | **PASS（B-INT 贴边见 R3）** | t29 E-SPEED n=6 total=3360（单条 560）；t28 RB start-to-start 254/253/250/252/252ms；LB 256/255/257/254/251；t29 B-INT gaps 150/114/113/130/113ms，max=150ms 恰好贴阈值 |
| 5 | 不引入串扰（串行队列仍有效） | **PASS** | t29 A 每次按压 SWIPE=6（Z=6）/WHEEL=0，SWIPE_DROP=0；t22 原始 5 场景 overlaps=0；串行队列 `swipe_submit` 未改；X+LB/RB 的 V 仍走队列 |
| 6 | 横向翻页 X+LB/RB 仍走手势；右摇杆滚动未受影响 | **PASS** | 源码 L1456-1464 `WHEEL_LEFT/RIGHT -> doSwipe(false,±1)` 未改；t29 F1 X+LB dx=+1263、F2 X+RB dx=−1257；F3 右摇杆竖 Z=6/V=0/wheel=0，F4 横 V=3/Z=0/wheel=0 |
| 7 | ButtonDetail 双击文案 400ms 且与 DOUBLE_WINDOW 一致 | **PASS** | `ButtonDetailActivity.kt:122` 文案“（400 ms 内）”；`EngineService.kt:162` `DOUBLE_WINDOW = 400L`；t29 F6 X 双击→Recents（400ms 窗口）；原 320 已改 |

## 2. 源码结构核对

### 2.1 混合删除 / 互斥

```kotlin
// EngineService.kt:1404-1434（t22/t26/t28 最终）
wheelButtons.add(name)
holdTouchMode = cVTouch
Action.SCROLL_SWIPE_UP -> {
    if (holdTouchMode) { swipeHold=-1; lastSwipeHoldAt=0; swipeHoldStep(-1) }
    else { ensureWheelAnchor(); wheelHold=-1; lastWheelHoldAt=0 }
    Log.i(..., "hold-scroll $mapped by $name mode=${if (holdTouchMode) "swipe" else "wheel"}")
}
Action.SCROLL_SWIPE_DOWN -> { ... 对称 ... }
```
- 按压内**只有一条分支**执行；`swipeHold` 与 `wheelHold` 不同时非 0；释放 `wheelButtons` 清空时 `wheelHold=0; swipeHold=0`（L1471-1477）。**结构性互斥，不是只靠日志观察。**
- t22 原来的“先 `doSwipe` 再 `wheelHold`”在最终源码不存在；`doSwipe` 只由 `SCROLL_SWIPE_LEFT/RIGHT`、`WHEEL_LEFT/RIGHT`（一次性翻页）和 doSwipe 路径调用，不在 LB/RB 按住滚动路径里。

### 2.2 机制稳定

- `holdTouchMode = cVTouch` 只在 `onPress` 的 LB/RB 分支赋值（L1407）；`cVTouch` 从 prefs `v_touch_scroll` 同步（L457）；按压期间没有其它写 `holdTouchMode` 的路径。
- 30s 稳定性：t22 的 `24/0`、`0/36`、`mode=swipe/wheel ×3`；t29 D 8 组 5/5、切换 0。

### 2.3 X+LB/RB 与右摇杆

- `WHEEL_LEFT/RIGHT`（L1456-1464）仍是 `doSwipe(false,±1)`（横向翻页），与 LB/RB 的 `SCROLL_SWIPE`/`WHEEL` 分支分离；t29 F1/F2 +1263/−1257。
- 右摇杆滚动路径（`vScrollDir`/`doSwipe` 的既有 `scroll` 分支）未改；t29 F3/F4 Z=6/V=3、wheel=0。

### 2.4 ButtonDetail 400ms

- `ButtonDetailActivity.kt:122` “连续按两下 …（400 ms 内）”；`EngineService.kt:162` `DOUBLE_WINDOW = 400L`；t22 把 320 改 400；t29 F6 X 双击→Recents；与 `DOUBLE_WINDOW` 一致。

## 3. Findings（t22 原始态的真实缺口；最终态已由 t26/t28 闭合；t15/t7 收尾）

| id | severity | problem | requiredFix | file:line |
|---|---|---|---|---|
| R1-T22-ORIGINAL-B-RB-C-MOVE | **medium** | t22 原始 APK `20eddf98` 在 t23 是 16/18：B-RB（RB 页顶）与 C-MOVE（滚轮内容位移）FAIL——wheel 只对指针悬停窗口有效，空闲隐藏后不滚；RB 锚点被底部子视图拦截。t22 的 7 条 acceptance 在原始态不满足。 | t26 已修：`ensureWheelAnchor()` 隐藏/偏离时 showPointer + positionPointer(task 中心)，RB/LB 锚点自适应；t29 C-WHEEL 9/0、C-MOVE dSET=921、B-RB/LB dPY=1415。发布说明以 t29 的最终态为准，t22 原始 16/18 只作历史。 | `work/docs/LBRB-v167.md` §3.6/§3.7；`work/docs/VERIFY-lbrb-v167.md:50`；`EngineService.kt:1481` |
| R2-T22-ORIGINAL-E-SPEED | **medium** | t22 原始 E 为 3300<3360（t27 21/22 的唯一 FAIL）；t26 的候选 LB 65/55、RB 30/40 让纵向行程被 task 边界夹短（540/560 交替差 1.8%）。 | t28 已修：纵向行程固定 560px（横向 30%/70% 交替），t29 E=3360（6×560）。发布说明用 t29 的 3360，不用 t22/t27 的 3300。 | `work/docs/VERIFY-lbrb-v167.md:51-52`；`EngineService.kt:1501` |
| R3-T22-BINT-150 | low | t29 B-INT max=150ms **恰好贴阈值**（≤150）；gaps 150/114/113/130/113；t22 的 start-to-start 250-258ms、手势 220ms、空档 30-38ms 是另一组（更小）样本。t29 的 150 是真实按压批次，余量为 0。 | t29 已提示；t15/t7 可把 B-INT 窗口收紧到 120ms 或加“平均空档”记录；发布说明写 max=150ms（贴边），不要写成 30-38ms。 | `work/docs/VERIFY-lbrb-v167.md:27`；`work/docs/evidence-lbrb/raw-v167-t29/B_intervals.txt` |
| R4-T22-FINAL-HASH | low | t22 原始 `20eddf98`；t26 `8ea4cb07`；t28/t29 最终 `df26e461`。t22 输出说“新字节需 t15/发布重绑”；t29 已绑定最终哈希，但 t22 的旧哈希仍在 LBRB 文档历史里。 | t15/t7 发布用 `df26e461` + helper `1bf7306f`；LBRB/VERIFY/Release 统一，t22 的 20eddf98 只作历史；不要把 20eddf98 当发布候选。 | `work/docs/VERIFY-lbrb-v167.md:11`；`work/docs/LBRB-v167.md` |
| R5-T22-BINT/30S | low | t22 的“30s 稳定 24/0、0/36”与 t29 的 A/D 8 组 5/5 是两组证据；t29 没有重复 30s 长稳，只有 5/5 短稳。 | t15/t7 如需 30s 长稳，用 t22 的 24/0、0/36 作历史，t29 的 5/5 作最终；两者不冲突。 | `work/docs/LBRB-v167.md` §3.4；`work/docs/VERIFY-lbrb-v167.md:32` |

> 源码/回归项（混合删除、互斥、vTouchScroll、X+LB/RB、右摇杆、400ms）均 PASS，不列 finding。

## 4. 结论与给 t15/t7 的条件

t22 的**结构性改动正确**：混合删除、按压内 `holdTouchMode` 二选一、vTouchScroll 按压开始定一次、X+LB/RB 与右摇杆未改、400ms 文案与 `DOUBLE_WINDOW` 一致。**t22 原始 20eddf98 的 t23 16/18 是真实缺口，t26/t28 已修，t29 在 df26e461 上 22/22 PASS；t24 判 PASS（带条件）。**

t15/t7 发布前：
1. 绑定 **df26e461 + 1bf7306f**（t29 已做）；不要用 t22 的 20eddf98 或 t26 的 8ea4cb07。
2. B-INT 记录 max=150ms（贴边）；如需余量收紧到 120ms 或加平均空档（R3）。
3. LBRB/VERIFY/Release 统一最终哈希；t22/t23 的 16/18、t27 的 21/22 只作历史演进表（R1/R2/R4）。
4. 30s 长稳可用 t22 的 24/0、0/36 作历史，t29 的 5/5 作最终（R5）。

## 5. 复现

```sh
# 只读复核（本审查执行）
adb -s 192.168.10.36:6666 shell 'p=$(pm path com.dennis.dexpad | head -1 | sed s/package://); sha256sum "$p"'
#   df26e461…（= 本机 app-debug.apk）
adb -s 192.168.10.36:6666 shell su -c 'sha256sum /data/adb/gpm/gpminput /data/adb/modules/gpm_dex/gpminput'
#   1bf7306f… / 1bf7306f…
grep -n 'holdTouchMode\|ensureWheelAnchor\|swipeHold\|wheelHold\|DOUBLE_WINDOW' \
  project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt | head
grep -n '400 ms' project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ButtonDetailActivity.kt
# 复跑 t29 见 VERIFY-lbrb-v167.md §5
```

## 6. 限制

- 未在设备上重放 t29（设备在 t15/t7 使用中）；t29 的 verify/console/raw、LBRB-v167、源码、t22/t23/t26/t28 输出为审查材料；本次做了只读 APK/helper hash、源码 L1404-1434/1481/1501/1456-1464/162、ButtonDetail L122、t29 22/22 逐项核对。
- t22 原始 20eddf98 的 t23 16/18 是历史；t24 的 PASS 是“t22+t26+t28 最终态 + t29 22/22”，不是 t22 原始态单独 PASS。
- B-INT 的 150ms 贴边是 t29 的真实样本；t22 的 30-38ms 是另一组（start-to-start 250-258、手势 220），不要混用。
