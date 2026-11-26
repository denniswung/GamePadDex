# V169-HARNESS4 · d/m/e 坐标触摸评估与横向定性（t50）

> 字节：app `3ea7f324…` / helper `a88c544a…` / padtest 1.2；设备 2560×1600 横屏
> 套件：`work/scripts/v169_suite.sh`；证据：`work/docs/evidence-v169/t_mix3.out` 等

## 0 结论

1. **`d/m/e` 经 root 通道可下发**（`DRAG down/move/up` 日志齐全），但 **帧不发射**：控制连接打开期间 helper 主循环阻塞在 read 上，`m` 的 30 帧在 `e` 到达前 `emitted=0`（`DRAG up … frames=0 emitted=0 dur=0ms`）。因此坐标级**拖拽滚动**暂不可用；`P`/`c`/`H`/`WHEEL` 等瞬时命令可用。
2. **右摇杆横向 0→0 定性 = (c)**：不是应用回归，也不是 padtest v1.2 命中变化。右摇杆横向从来只驱动“光标移动/滚动”而非 `HorizontalScrollView`；分页的正确通道是**水平滚轮**（`H n`）——手动实测 `P(1280,1509)` + `H 8` → **scrollX 0→512**。t15 A2 的 `HS 0→512` 是 LB/RB 横向 swipe（X+LB/RB 组合）测的，与右摇杆不是同一路径。
3. 覆盖率：**≈40/142**；MIX 主体仍受限于“坐标拖拽帧不发射”。

## 1 d/m/e 实测（可复现）

```sh
S=/data/adb/gpm/gpmctl.sock
{ printf 'j\n'; printf 'd 0 1280 1000\n'; sleep 0.25; printf 'm 0 0 -400 300\n'; sleep 0.8; printf 'e 0\n'; } | nc -U $S
```
输出：
```
POINTER on
DRAG down display=0 x=1280,y=1000 rect=20..2540/20..1580
DRAG move display=0 dx=0 dy=-400 ms=300 steps=30 step_ms=10 pending=0,-400
DRAG up display=0 x=1280,y=1000 frames=0 emitted=0 dur=0ms why=cmd-e
```
- `d` 与 `e` 生效；`m` 登记了 30 步但 **emitted=0** → 列表未滚动（`列表项 #001` 不变）。
- 分两条连接发 `d` 再 `m` → `ERR drag move (no down)`：连接关闭即 abort 拖拽。

**给 helper-eng 的建议**：控制连接期间把 `m` 的帧发射放到独立线程/非阻塞处理，或提供“detached drag”（`d`/`m`/`e` 之间允许断开且状态保留）。否则坐标级拖拽在自动化里不可用。

## 2 右摇杆横向定性（三选一）

| 选项 | 判定 | 证据 |
|---|---|---|
| (a) padtest v1.2 PassThroughScrollView 改变命中 | 否 | 同版本下 `H 8` 命中分页并滚动 512 |
| (b) 应用侧横向滚动回归 | **否**（非 P0） | 水平滚轮与 X+LB 横向 swipe 均能滚动分页；无产品侧回归迹象 |
| (c) 指针未悬停分页区 / 通道选错 | **是** | `stick 3 ±30000` 全程 scrollX=0、PadProbe 无横向滚动事件；`P(1280,1509)+H 8` → 0→512 |

可复现命令：见 §1；手动分页复现：
```sh
G=/data/local/tmp/gpmctl; S=/data/adb/gpm/gpmctl.sock
$G $S 'j'; $G $S 'P 1280 1509 2560 1600'; $G $S 'H 8'   # → WHEEL 8 h=1
# dump 后 scrollX=512（第 1 页文本仍显示 1，因为 max scrollX=512<600）
```

## 3 MIX-009/010 套件状态

- 手动：PASS 口径成立（scrollX 0→512）。
- 套件：`P` 后 `c` 仍回 `CURSOR -1 -1`（引擎重启后指针 show 未生效）→ H 被吞，scrollX 0→0；已加“等引擎 ready + H 连发两次”，但指针 show 时序仍不稳。**下一步**：ptr_to 里改为 `M 0 0`（相对移动强制 cursor 更新）+ `P` + 重试 `c` 直到非 -1。

## 4 仍 BLOCKED（原因更新）

| 类别 | 条数 | 原因 |
|---|---|---|
| MIX-001~008（内外层归属） | 8 | d/m/e 帧不发射（§1）；垂直滚轮在 padtest 不滚动 |
| MIX-011~024（分页/AxisLock） | 14 | 分页可解（水平滚轮），AxisLock 需坐标**拖拽** → 受 §1 限制 |
| MIX-025~029（左右/固定区） | 5 | 需 v1.2 ExportReceiver 埋点 + 坐标拖拽 |
| MIX-030~034（浮层） | 5 | UI 点击 + 状态保持 |
| SCR-009/010/012/013 | 4 | release 无 DebugReceiver（debug 探索待做） |
| UI 二级 49 条 / 环境 15 条 | 64 | 同前 |

## 5 结论与建议

- **≥90/142 仍不可达**：核心缺口是坐标级拖拽（d/m/e 帧发射）与纵向滚轮；两者都在 helper/padtest 侧。
- 可稳定自动化上限 ≈45/142；建议 helper-eng 优先修 `m` 的帧发射（控制连接非阻塞），之后 MIX-001~008/015~024 可一次性铺开。
- 右摇杆横向 0→0 **不是产品回归**，无需 P0；若产品期望“右摇杆横向翻页”，需在引擎侧把横向输入映射到 HorizontalScrollView（产品需求，非缺陷）。

---

## 6 SCR-022：baseline FAIL → 已修复（样例）

> 来源：t53（app-eng）修复，APK `da1e52d3…`；本节数据由 captain 核验，最终复测在 t52 全量中给出。

| 场景 | swipe 锚点 | scrollX |
|---|---|---|
| 修复前（v1.68 baseline） | `1280,800`（列表区，任务中心估算） | 0→0 |
| 修复后：指针在分页区（真实光标 1282,1599） | **1282,1599** | **0→512（next）→0（prev），Δ512** |
| 修复后：指针在纵向列表（1282,804） | 1282,804 | 保持 0、不越界 |

**根因**（与 t49/t50 的定位一致）：
1. 横向与竖向共用 `swipeCooldownUntil`——刚竖滑后横向被冷却吞掉；
2. 引擎 `ptrX/ptrY` 是估算值，外部 `P`/真实光标移动后未同步，`doSwipe` 用旧估算当锚点 → 落在列表上。

**修法**：横向独立冷却 + `ignoreCooldown` 强制发；横向按住期间每 400ms 被动同步一次 `c`（CURSOR→ptrX/ptrY）；日志新增 `hswipe dir/nx/anchor/hidden`。

**复测口径（t52 执行）**：`v169_scr022_recheck.sh`，并强制校验 `hswipe … anchor=` 与 `P` 目标坐标 ±8px，否则 scrollX 变化可能只是运气；同时保留 X+RB 0→512 作基准。

> 这一条是本套件“baseline FAIL → 确认产品问题 → 修复 → 复测”的完整样例，可作为后续 FAIL 处理的模板。
