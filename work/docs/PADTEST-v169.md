# PADTEST-v169 · padtest v1.2 埋点补齐

- 版本：**1.3 / versionCode 4**（上一版 1.1/2）
- APK sha256：**`8febba4761a1166c7741c825eead5a32d7d97680bde21a242c1a827a733644e2`**
- 路径：`project/padtest/app/build/outputs/apk/debug/app-debug.apk`（已装机）
- 主应用/助手：本轮**未改动**（`project/lsp-dexpad`、`project/app/src/main/assets/gpminput.c` 零改动）

## 1. 新增埋点

| 埋点 | 实现位置 | 暴露方式 |
|---|---|---|
| ACTION_MOVE 帧连续性 | `ProbeActivity.dispatchTouchEvent`：DOWN 重置、MOVE 累计帧数/最大间隔/路径、UP 写摘要 | Report JSON `instrumentation.touch`；logcat `PadProbe: .../touch-move-summary frames=… maxGap=…ms path=…px`；`CheckRegistry.TOUCH.MOVE`（PASS/FAIL/UNKNOWN） |
| 左/右列表各自 offset | `ScrollTestActivity`：保存两个 `ScrollView` 引用，`refresh()` 直接读 `scrollY`；不再依赖会被外层拦截的 listener | Report JSON `instrumentation.scroll.left_offset/right_offset`；页面状态行 `焦点：… · 左 offset=… · 右 offset=…` |
| 固定区域滚动计数 | `ScrollTestActivity.onWheelAt/onTouchDownAt/onTouchEndAt`（Activity 级落点判断 `inFixed()`），真实递增 | Report JSON `instrumentation.scroll.fixed_area_scrolls`（含 `fixed_area_wheel/touch`）；`CheckRegistry.SCROLL.FIXED`；logcat `fixed-area-scroll count=… by=…` |
| 页面级落点钩子 | `ProbeActivity` 新增 `onTouchDownAt/onTouchEndAt/onWheelAt`（子 View 被外层 `ScrollView` 拦截时仍可观测） | 供子类覆盖 |
| 外层滚动容器 | 新增 `view/PassThroughScrollView`：命中左右列表区域时不拦截手势，内嵌列表才能真实滚动 | 仅 ScrollTest 页面使用 |
| 自动化导出 | 新增 `core/ExportReceiver`（仅测试台 App）：`am broadcast -a com.dennis.padtest.EXPORT -n com.dennis.padtest/.core.ExportReceiver --es what report --es fmt json` | 写入 `getExternalFilesDir/export/report-*.json`，logcat 打印 `EXPORT path=… size=…` 与 `METRICS …` |

## 2. Report JSON 结构（新增字段）

```json
{
  "instrumentation": {
    "touch": {
      "frames": 24, "max_gap_ms": 18, "path_px": 65, "duration_ms": 275,
      "down_x": 400, "down_y": 810, "up_x": 400, "up_y": 745,
      "source": "touch", "continuous": true
    },
    "scroll": {
      "left_offset": 67, "right_offset": 0,
      "fixed_area_scrolls": 1, "fixed_area_wheel": 0, "fixed_area_touch": 1,
      "vertical_offset": 0, "horizontal_scroll_x": 0,
      "sides_independent": true
    }
  }
}
```

判定口径（套件可直接用）：
- **MOVE 连续性**：`touch.frames >= 2 && touch.max_gap_ms in 1..40` → `continuous=true`（TOUCH.MOVE PASS）；帧数 <2 判 UNKNOWN（单击），间隔 >40ms 判 FAIL。
- **固定区回退**：`fixed_area_scrolls > 0` 表示固定区确实收到滚动尝试（含 `fixed_area_wheel/touch` 分项）；0 表示未触发，套件应判 BLOCKED，不得伪造 PASS。
- **左右列表独立**：只滚一侧后 `left_offset`/`right_offset` 一侧 >0、另一侧 =0；`sides_independent` 由两边不等给出。注意 0 是合法值（未滚动），套件应结合基线/动作序列判读。

> **后续修复标注（t63）**：本节描述的 `PassThroughScrollView` 由 v1.2（t42）引入，**已在 v1.3（t55）删除**（该改动导致分页不响应注入式横向 swipe）；内层 `vList` 手势被外层拦截的问题由 **v1.4（t60）** 用 `requestDisallowInterceptTouchEvent(true)` 修复。**现行行为以 t55/t60 为准，勿按 v1.2 写法理解。**

## 3. 真机实测（v1.2，SM-F9360）

| 检查 | 实测 | 证据 |
|---|---|---|
| MOVE 帧连续性 | `frames=24`, `max_gap_ms=18`, `path=65px`, `dur=275ms`；`TOUCH.MOVE=PASS`（reason `frames=25 maxGap=18ms`） | 导出 `m_one.json` / logcat `PadProbe ... touch-move-summary` |
| 只滚左列表 | `left_offset=67`, `right_offset=0`（独立） | `m_one.json` |
| 左+右都滚 | `left_offset=100`, `right_offset=86`（各自记录，不合并） | `report_v12g.json` |
| 固定区回退计数 | `fixed_area_scrolls=1`, `fixed_area_touch=1`, `fixed_area_wheel=0` | `report_v12g.json` |
| 7 页快速切换 20 次 | `rounds=20 pages=7 pid=18943 fatal=0 anr=0` | `/data/local/tmp/t42_pages` 输出 |

复现（设备）：
```
am start -n com.dennis.padtest/.ui.ScrollTestActivity
# 滚到两列表可见后，用真实触摸拖拽（helper d/m/e 或游戏手柄触摸后端）
am broadcast -a com.dennis.padtest.EXPORT -n com.dennis.padtest/.core.ExportReceiver --es what report --es fmt json
# 读取 logcat: PadProbe ... EXPORT path=... ；文件内 instrumentation.touch/scroll
```

## 4. 已知限制

- 本机 `adb shell input swipe` 被系统标记为 **MOUSE** 源（`PadProbe: MOUSE/click-down`），鼠标拖动不会滚动内嵌列表；套件应使用触摸后端（helper `d/m/e` 或真手柄触摸）来验证左右 offset。v1.2 曾加 `PassThroughScrollView`（**已在 v1.3 删除**，见上）；内层列表手势由 v1.4 的 `requestDisallowInterceptTouchEvent` 修复。
- `ExportReceiver` 仅存在于测试台 App（`com.dennis.padtest`），不影响主应用；发布主应用不包含它。
- `UNKNOWN` 保持 UNKNOWN：未产生 MOVE/未触发固定区时不会写 PASS。


## 5. v1.3：注入式横向 swipe 回归用例（必须保留）

**背景（t55）**：verifier 报告同一个 pager 坐标（1280,1507）下 X+RB 在 padtest 1.1 是 `scrollX 0→512`、1.2 是 `0→0`，导致 SCR-022 无法验收。定位到 t42 新增的 `PassThroughScrollView`（整页包一层，重写 `onInterceptTouchEvent`）改变了外层手势拦截链。

**修复（v1.3）**：
- 删除整页 `PassThroughScrollView`，恢复普通 `ScrollView`；
- 左右列表在 `ACTION_DOWN` 时 `parent.requestDisallowInterceptTouchEvent(true)`，保留“列表独立滚动”；
- 埋点（MOVE 连续性、双侧 offset、固定区计数、ExportReceiver）全部保留。

**回归验证（1.3 / code 4，APK `fae700df…`）**：
| 动作（pager 中心 1280,1507） | scrollX |
|---|---|
| base | 0 |
| X+RB（`vgpad combo 307 311 300 2600`） | **512** |
| X+LB（`vgpad combo 307 310 300 2600`） | **0** |
| 直接注入 `V 0 -640 120 2560 1600 -1 1280 1507` | 0→**512** |
| 反向 `V 0 +640 …` | 512→**0** |

- 7 页 ×20 次快速切换：`pid=1851 fatal=0 anr=0`。
- 右摇杆横向验收见 t53（`hswipe anchor` 已同步真实指针；本机 `P` 通道当前返回 CURSOR -1，未重复测 stick）。
- 本用例写入本文件 §5：**任何改动后，pager 中心注入式横向 swipe 必须仍能 0→512→0**，否则视为测试台回归。


## 6. t57 复测 SCR-022（像素法）与测量上下文

**测量方法（重要，避免再对不上）**
- 页面：`com.dennis.padtest/.ui.ScrollTestActivity` **前台**；pager `HorizontalScrollView` 实际 bounds=`[36,1415][2524,1600]`（新启动即在此，无需滚动）。
- 截图：`screencap -p` 前后各一张，裁剪 pager band `(36,1415)-(2524,1600)` 做像素差（Pillow），辅以 `uiautomator dump` 的「第 N 页」bounds。
- 输入：`vgpad combo 307 311 400 2600`（X+RB）、`307 310`（X+LB）；右摇杆 `vgpad stick 3 ±30000 2000`；指针用 HCMD `P 1280 1507 2560 1600`。
- **不是**读 ReportActivity 的 `horizontal_scroll_x`（verifier 的 0 读数是另一路径/时序）。

**结果（padtest v1.3 `fae700df`，pager band 像素差）**
| 动作 | band 差异 | 页面文本/bounds |
|---|---|---|
| X+RB | **82.27%** | 第 1 页 36→124（翻页） |
| X+LB | **82.27%** | 回到 第 1 页 36–636 |
| P(1280,1507)+stick+ | **82.27%** | 翻页 |
| P(1280,1507)+stick− | **82.27%** | 回第 1 页 |
| P(1282,802 列表)+stick+ | **82.27%**（意外） | 第 1 页 36→124 |

- 右摇杆 `hswipe anchor=1282,1509`（请求 1280,1507，误差 +2,+2 ≤8px），helper `SWIPE … axis=V`。
- 但 `HorizontalScrollView` 的 a11y bounds 只有 `[36,1415][2524,1600]`，列表 y=802 的 swipe 不应命中 pager，却仍翻页 → 怀疑 **helper 触摸面板 y 映射**（V 的锚点坐标与实际注入点不一致），属 helper/t46 域，不是 padtest/产品分页缺陷。

**其它 t57 复测**
- d/m/e：`?` 自检 `CAP gesture 1`、`INFO devices_grabbed=1`；三条独立序列各 `frames=30 maxGap=24–25ms`、helper `DRAG` 行 +32/条 → 通过（≥20/≥20）。
- 垂直滚轮 `S 8`：helper `WHEEL 8 h=0`、PadProbe `WHEEL/scroll-axis v=8.0 h=0.0` 均通过；padtest `纵向 offset=0→0` 未变化——HCMD `P 700 1000` 回读为 `CURSOR 171 171`，指针实际没落到列表（P 映射异常），第三项证据 BLOCKED(env)。
- MIX 内层/外层：`d 700 1000 + m -300/600` 后外层标题从 y=603 移到 y=14（**外层页面被滚**），内层 `vertical_offset` 仍 0 → vList 与外层 ScrollView 的嵌套拦截仍未解，MIX-001~008 未能用当前 d/m/e 解锁。

**结论**：SCR-022 的分页在像素法下对 X+RB/X+LB/右摇杆均成立，**无 padtest 分页缺陷**；列表隔离、S8 offset、MIX 内层三项受 helper 坐标映射/vList 嵌套拦截阻塞，需 helper/t46 与 padtest 后续处理。


## 7. v1.4：内层 vList 手势归属（MIX-001~003 判定方式）

**修复**：`ScrollTestActivity` 创建 `vList` 后加 `setOnTouchListener`，在 `ACTION_DOWN` 时 `v.parent?.requestDisallowInterceptTouchEvent(true)`；外层 `ScrollView` 不再抢内层列表的纵向手势。`HorizontalScrollView`/左右列表/固定区逻辑不变。

**实测（v1.4 / code 5，APK `0f4a9191…`）**
| 起手区域（HCMD d/m/e） | vList `vertical_offset` | 外层标题 bounds |
|---|---|---|
| base | 0 | `[36,603][2524,668]` |
| 内层 y≈1000，`m -300/600` | **0 → 2** | **603（未动）** |
| 外层 y≈300，`m -300/600` | 2（未动） | **603 → 42（外层滚动）** |

- pager 回归保持：X+RB（`combo 307 311`）pager band 像素差 **82.27%**，X+LB **82.27%** 回第 1 页（第 1 页 bounds 回到 `[36,1415][636,1600]`）。
- t42 埋点：v1.4 导出 `touch.frames=5 / max_gap=17ms / vertical_offset=29` 正常；左/右列表与固定区路径未改（v1.3 实测 left=262、right=253、fixed=1，继续有效）。
- 7 页×20 快速切换：`pid=6586 fatal=0 anr=0`。

**MIX-001~003 判定方式（供 t58 引用）**
1. 用 HCMD `d 0 700 1000` → `m 0 0 -300 600` → `e 0`（内层起手）：读 report `instrumentation.scroll.vertical_offset` 必须 **增大**，同时 `uiautomator` 的「纵向：200 项列表」标题 bounds y 必须 **不变**（≈603）。
2. 用 HCMD `d 0 700 300` → `m 0 0 -300 600` → `e 0`（外层起手）：`vertical_offset` 必须 **不变**，标题 bounds y 必须 **减小**（外层滚动）。
3. 以上两条即 MIX-001~003 的内外层归属判定；截图取标题 bounds 变化（外层）与列表首项序号（内层）。

## 8. 手势链回归（pager / vList，t63 新增，必须随埋点变更复跑）

> 目的：防止再次出现“修好一处、打断另一处”的外层手势链回归（v1.2 → v1.3/v1.4 的教训）。

| 步骤 | 命令 | 期望 |
|---|---|---|
| P1 | `combo 307 311`（X+RB） | `horizontal_scroll_x` 0→512 |
| P2 | `combo 307 310`（X+LB） | `horizontal_scroll_x` 512→0 |
| P3 | `P 1280 1507` + 右摇杆横向 2s | `horizontal_scroll_x` ≥400，`vertical_offset` 不变 |
| P4 | `P 1280 800` + 右摇杆横向 2s | `horizontal_scroll_x` 不变 |
| V1 | `P 1000 1000` + 垂直手势/滚轮 | 内层 `vertical_offset` 变化，外层标题不动 |
| V2 | `P 1280 300` + 垂直手势/滚轮 | 外层标题变化，内层 `vertical_offset` 不变 |

读取：`am broadcast -a com.dennis.padtest.EXPORT -n com.dennis.padtest/.core.ExportReceiver --es what report --es fmt json` → `instrumentation.scroll.*` / `instrumentation.touch.*`。
判定：P1–P4 全过 = pager 链正常；V1–V2 全过 = vList 链正常；任一失败即阻塞发布。

## 8. t65 尝试与阻塞：纵向滚轮支持（未交付）

- 需求：ScrollTestActivity 的 200 项列表与 LogActivity 日志列表支持 ACTION_SCROLL，`S 8` 后 `vertical_offset` 增加 ≥200px（或首项 ≥2），`S -8` 回滚；同时保持 t55/t60。
- 已实现（未发布，已回退）：`ProbeActivity.onVerticalScroll` 钩子；ScrollTestActivity/LogActivity 处理 ACTION_SCROLL；`PadMetrics.verticalPx` 与 `vertical_offset` 上报；`gpmctl.sock 'S 8'` 实测 helper `WHEEL 8 h=0`、PadProbe `WHEEL/scroll v=8.0`。
- **阻塞**：ScrollTest 的 200 项列表嵌在外层 `ScrollView` 里，`ListView.scrollListBy/smoothScrollBy/setSelection` 与把 vList 改为 `ScrollView.scrollBy` 均未能让 `scrollY`/首项稳定变化（实测多次 0；偶发一次 672 但随后 S-8 又回到 0，读数不可复现）。触摸 d/m/e 拖拽该 vList 也仍为 0（外层/嵌套测量问题）。
- 为不破坏 t55（pager 0→512）与 t60（内层 y≈1000 offset 0→2、外层标题不动），本轮**已回退全部 t65 改动**，padtest 保持 v1.4（`0f4a9191…`）。
- 建议 t66：把“纵向滚轮验收”放到 LogActivity（整屏 ListView，非嵌套）或新增独立 WheelTestActivity（整屏 ScrollView + 固定高度内容），避免嵌套 ScrollView 的测量歧义；或在 ScrollTest 用 `requestDisallowIntercept` + 外层固定高度窗口化列表。


## 9. t70 尝试与阻塞：WheelTestActivity（未交付）

- 新增 `WheelTestActivity`（整屏 ScrollView + 200 固定高度行；顶部 `scrollY=…` 文本；ACTION_SCROLL → scrollBy；触摸走原生 ScrollView；`PadMetrics.verticalOffset = scrollY`）；已临时注册 manifest 并升到 v1.5 构建。
- 实测：`gpmctl.sock 'P 1280 800'` 后 `S 8`，helper `WHEEL 8 h=0`、PadProbe `WHEEL/scroll-axis v=8.0` 均出现；但页面 `scrollY=0`（dump 与 report 均 0），`S -8`、`d/m/e` 触摸拖拽同样为 0。
- 现象与 t65 一致：**padtest 窗口收到滚轮/触摸事件，但 ScrollView 不产生滚动**（WheelTest 已完全脱离嵌套，仍复现）。怀疑点：多显示/窗口 hover 归属（screencap 一直提示多 display）或测试台 window 未真正获得 scroll 焦点；不是布局嵌套。
- 为不破坏既有回归，已**回退全部 t70 改动**（删除 WheelTestActivity、manifest/build.gradle 还原），padtest 保持 v1.4 `0f4a9191…`。
- 建议 t66：先用 `input mouse scroll`/真鼠标在 padtest 上确认任意 ScrollView 能否滚动；若系统层面不派发滚动，改为在通道侧记录 `WHEEL` 并用 **padtest 自绘滚动量**（收到 ACTION_SCROLL 就 scrollBy 并记录请求量）作为“请求侧证据”，把“是否真的滚”交给截图/像素判定；或换用 `RecyclerView`/自定义 View 处理 `onGenericMotionEvent` 并 `requestFocus`。
