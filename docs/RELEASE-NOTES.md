# v1.66 发布说明（2026-11-24）

包名：`com.dennis.dexpad`　versionCode **68** / versionName **1.66**
配套：KernelSU 模块 `gpm_dex` v1.66 · 助手 `gpminput` v1.66 · 测试台 `com.dennis.padtest` v1.1

| 资产 | 文件 | sha256 | 大小 |
|---|---|---|---|
| 应用 | `dexpad-v1.66.apk` | `73477ecaef948aa4b4a9ffdc5f51e8026200a66228cebd635b8aba8c79aa8bf5` | 2677039 B |
| 模块 | `gpm_dex-v1.66.zip` | `fd4fc2ebd0d06a17eb6d5fd1e3dd90d722526ac6b33ec70436bbd2b50463085f` | 362092 B |
| 助手 | `gpminput-v1.66` | `1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf` | 851928 B |
| 测试台 | `padtest-v1.1.apk` | `27478cef1c51acddc88c7ef662980ead4720bc95ce38635b0aa816f67de32e50` | 949222 B |

模块 zip 内 `gpminput` 与 `gpminput-v1.66` **同哈希**；APK 内 `assets/gpminput` 解包后亦为同一哈希（三处一致）。

## 1 本版修的 5 个真机问题

### ① 滑动串扰：斜推时同时触发竖/横两种手势
- **现象**：右摇杆斜推（RX 与 RY 同时超阈）会先后/同时发出竖向与横向手势，页面乱跳。
- **修法**：引擎侧单 tick 轴向仲裁（超阈轴唯一化），helper 侧再加一道串行队列与 `axis_guard` 丢弃（`SWIPE_DROP`），保证任一时刻只有一路手势在飞。
- **证据**：A1 只动纵向区（PY d=1335、HS d=0，helper 仅 Z）；A2 只动横向区（HS d=512、PY d=0，仅 V）；A3 双轴同超阈（RX=0.36+RY=0.73）仍只出 Z（Zn=5 Vn=0）；A4 双向连续 3 次 `starts=18 dones=18 overlaps=0`、A4B `drops=0`。

### ② 光标 dpi 偏慢：从屏左到屏右要推很久
- **修法**：`speed_phone` 30→**48**、响应曲线 γ 2.5→**1.6**、亚像素阈值 0.6→**0.2px**、保留边缘减速（`scale=0.6`）。
- **证据**：满推 300ms 位移 **2478px**（屏宽 2560 = 0.968×，判据 0.9–1.2）；半推 0.49 → 520px；0.24 推 → **36px**（旧版为 0，亚像素全丢）；中心同推 608px > 左边缘 520px（边缘减速生效）。
- **不撞边第三方测量**：direct 48/300ms = 2462/2485/2481px = 96.2/97.1/96.9% 屏宽；proxy B（16 速线性外推）91.1–93.0%；proxy A（中心 150ms×2）89.1–89.9% 属低估，仅参考。

### ③ 滑动速度不合适（横竖不一致、单次太短）
- **修法**：竖滑 `dist=h*0.35`、周期 `max(ms+20, 410-40*scroll_speed)`（用户 scroll_speed=4 → 250ms）；横滑 `dist=w*0.45`、`hSwipeRepeatMs=560-20*hswipe_speed`（用户 3 → 500ms）。
- **证据（同一时间口径，正式判据）**：1.5s 内竖 6×560=**3360px**、横 3×1152=**3456px**，比值 **1.029** ∈[0.8,1.25]。
  单手势 1152/560=2.057 是横向单次步长更大的**设计取舍**，不作为判据（不与「同一时间总位移」混用）。

### ④ L3 居中不准
- **修法**：运行时标定 REL→px 增益（新装机首次 L3 自标定写入 `move_gain`）、`P` 绝对定位 + `c` 真实光标闭环校验（误差 >8px 才补一次相对位移，最多 3 次），去掉旧的 220ms+520ms 固定等待。
- **证据**：9/9 次落点误差 ≤5px（D-PS0/3/7 各 3/3）；`l3TookMs=578ms`（判据 ≤800ms）；L3 后 A 仍是鼠标点击（`mouse_click=1 key_enter=0`）。

### ⑤ 光标撞边界后卡死
- **修法**：每帧 clamp 用**运行时增益**（不再固定 2.16），估算位置与 `c` 真实位置同步（移动中每 1.2s、停止后立即、L3 闭环）。
- **证据**：四方向都到真边（0 / 2559 / 0 / 1599），估算-真实 0–1px；贴左边缘 5×200ms 零位移、反向 250ms 一步到对边；d-pad 导航后仍可达 x=0；空闲隐藏后仍可达 x=2559。

## 2 本版新增的 3 个功能

### 摇杆大幅快速移动点亮屏幕
- 阈值：幅度 **≥0.80**、保持 **≥200ms**、上升时间 **≤120ms**（`riseCrossMs ≤120ms`），prefs `wake_stick / wake_hold_ms / wake_rise_ms` 可调。
- 证据：0.92 快推 → `riseCrossMs=0ms`、Dozing→Awake、helper `WAKE done=1 src=uinput`；0.37/0.73 慢推与 2.1s 慢爬 **保持 Dozing**（不会误亮屏）。

### Y+上 打开 PiliPlus、Y+下 打开抖音
- 默认槽位：`mix 10 y+up → open_app com.example.piliplus`、`mix 11 y+down → open_app com.ss.android.ugc.aweme`。
- 启动方式：解析启动 Activity 后 `am start -n`（非 `monkey`/非 `-p` 兜底），`fallback=0 monkey=0`。
- 证据：Y+上 → 前台 `com.example.piliplus/.MainActivity`；Y+下 → 前台 `com.ss.android.ugc.aweme/.splash.SplashActivity`；用户自定义过的组合**不被覆盖**（预置 `mix_10` 后 `OPEN_APP=0`）。

## 3 整体提速

- **事件→动作**（手柄按下 → 系统点击，12 次）：中位 **7ms**、最大 **14ms**（v1.65 中位 8ms / 最大 20ms）。
- **helper 滑动准备** `prep`：中位 **204µs**、最大 **437µs**（判据 中位<1500µs、最大<5000µs）。
- **应用帧耗时**：`perf tick avg=33–43µs max=2.1–3.9ms`（发布字节 60s 空闲）；旧版每 tick 12+ 次 SharedPreferences 查询已消除（`prefs_per_tick=0`）。
- **60s 进程级 CPU**（`/proc/<pid>/stat` 的 `utime+stime`，同口径对比 v1.65）：
  - v1.66 release：**0.82%**（线程级求和 0.80%，`cutime+cstime` 增量 0.00% —— 子进程不参与，口径干净）
  - v1.65 release：**1.62%**（线程级 1.58%）
  - 口径说明：进程级 = `/proc/<pid>/stat` 字段 14+15 的 60s 增量；`cutime+cstime`（字段 16+17）单列，用于证明没有把短命子进程的 CPU 计入；线程级 = 逐 `/proc/<pid>/task/*/stat` 求和，会包含 Kotlin/JIT 短命线程，仅作辅助。
- 空闲时真实光标查询 60s 内 **0 次**（`CURSORQ=0 CURSOR=0`）；空闲循环自适应 8ms→16ms，有输入立即回 8ms。

## 4 默认横屏大屏适配（新）

- 默认 `force_landscape=true`：每 1s 复核 `Display.getRotation()`，不等于 1 就下发助手 `r 1`（同时写 `accelerometer_rotation=0 / user_rotation=1`）。外部把系统改回竖屏后 **≈2–3.5s 自动回横屏**（判据 ≤5s）。
- UI 分栏：`screenWidthDp > screenHeightDp*1.2` 时 ConfigActivity / ButtonDetailActivity 各两个半屏宽 ScrollView 左右并排；竖屏回落单列正常。
- 判定口径：`dumpsys display` rotation 1 + app bounds **2560×1600（宽>高）**；本机 `mLandscapeRotation=ROTATION_0` 属设备常量差异（**不要**用 `dumpsys window mRotation` 判断）。
- **caveat**：`display_size_forced=1600,2560` 在这台机器上**清不掉**（`wm size reset` / 置 null 均无效），横屏 = rotation 1 + 应用逻辑空间 2560×1600，**不是**清除竖屏 override。用户手动改分辨率/强制尺寸后需重新校验指针空间与居中（按一次 L3 会重标定增益）。

## 5 助手（gpminput v1.66）改动

- 新增/修正命令：`u`（唤醒，已亮时 `skip=1` 不重复注入）、`g` / `O`（增益参与居中）、`c`（真实光标回包 `display=0 space=logical`）、`P`（绝对定位）、`?` 自检。
- `?` 自检语义修正：CAP 行只报**能力**（`/dev/uinput` 可写、`/system/bin/input` 可执行、能读 `mWakefulness` 等），运行时状态单独一行 `INFO pointer device=on|off`、`INFO gesture busy/queued`、`INFO devices_grabbed`；
  因此**空闲隐藏指针后设置页不再误报「缺失：mouse，wheel」**（修复前误报，见 `work/docs/HELPER-v166.md` §1.6）。
- 串行手势队列：`starts==dones`、`overlaps=0`、`drops=0`；`SWIPE_DROP` 只允许 `axis_guard` 一种原因。

## 6 验证（可复跑）

| 项目 | 结果 | 证据 |
|---|---|---|
| A~K 全量（同源码 debug 变体 d2194406） | **PASS=68 FAIL=0**（三轮） | `work/docs/VERIFY-v166-final.md`、`work/docs/evidence-v166-verify/final-auto_suite.result.txt` |
| **发布字节**（release 73477eca）装机冒烟 | **PASS=23 FAIL=0** | `work/docs/evidence-v166-install/release_smoke.result.txt` |
| 哈希级装机校验（APK / 助手 3 处 / zip 内 / APK assets / 重启后） | 全部一致 | `work/docs/INSTALL-v166.md` |
| 重启后自启 + 鼠标可用 + 默认横屏 | 通过 | 同上 §4 |

```bash
# 全量（debug 变体）
adb shell "su -c 'sh /data/local/tmp/v166_auto_suite.sh all'"
# 发布字节冒烟
adb shell "su -c 'sh /data/local/tmp/v166_release_smoke.sh'"
```

## 7 已知限制 / 注意事项

- **发布包（release）不响应调试广播**：`DEBUG` / `HCMD` 在非 debuggable 构建里被 `DebugReceiver` 主动忽略（安全设计）。
  需要 `c` / `P` / `?` 等调试命令时请用 debug 构建或直接与助手进程交互。
- **隐藏后首次滑动**：指针空闲隐藏（8s）后第一次推杆会**先原地恢复指针**（零修正移动），恢复后指针保持可见，再空闲 8s 才再次销毁——这是预期行为。
  摇杆路径本就可用；v1.66 额外加固的是「按钮动作触发滑动」的隐藏分支（多发一次 `j`，约 120ms 设备重建）。越阈→SWIPE 的 57ms 只是**摇杆路径**的数字，不要泛化到按钮路径。
- ButtonDetail 页面双击说明文案仍写「320 ms 内」，实际双击窗口是 **400 ms**（v1.62 起），属文案笔误，下个版本修。
- `display_size_forced` caveat 见 §4；DeX 外接屏（display 9）未做完整回归；触摸点击/双指缩放依赖估算坐标，长距离移动后可能点偏（默认用鼠标事件可避免）。
- 助手用 `EVIOCGRAB` 独占手柄，其它 App 看不到手柄输入（屏蔽系统默认行为的代价）。

## 8 安装

```bash
# 1) 安装 APK
adb install -r dexpad-v1.66.apk
# 2) 安装 KernelSU 模块（或用 KernelSU/Magisk App 刷 gpm_dex-v1.66.zip）
adb push gpm_dex-v1.66.zip /data/local/tmp/
adb shell "su -c '/data/adb/ksu/bin/ksud module install /data/local/tmp/gpm_dex-v1.66.zip'"
# 3) 重启，确认模块生效
adb reboot
adb shell "su -c 'grep version /data/adb/modules/gpm_dex/module.prop; sha256sum /data/adb/gpm/gpminput'"
# 预期：version=v1.66 / versionCode=68；助手 sha256 = 1bf7306f…f4bf
```

校验和一览见同目录 `SHA256SUMS.txt`；装机校验表见 `work/docs/INSTALL-v166.md`。
