# v1.63 发布说明（2026-11-14）

包名：`com.dennis.dexpad`　versionCode **65** / versionName **1.63**
配套：KernelSU 模块 `gpm_dex` v1.63 · 助手 `gpminput` v1.63 · 测试台 `com.dennis.padtest` v1.1

## 1. 「打开应用」无效（Start + 上 → PiliPlus）

**根因**：助手用 `am start -a MAIN -c LAUNCHER -p <包名>` 启动目标应用。
这个写法对**部分应用会解析失败**（实测 PiliPlus 直接返回
`Error: Activity not started, unable to resolve Intent`），所以按了没反应。

**改法**：先解析出真正的启动 Activity，再按组件名启动：

```
cmd package resolve-activity --brief -a MAIN -c LAUNCHER <pkg>
  → com.example.piliplus/.MainActivity
am start -n com.example.piliplus/.MainActivity
```

解析失败时依次回退：`am start -p` → `monkey -p <pkg>`。
实测：

```
OPEN_APP com.example.piliplus via com.example.piliplus/.MainActivity rc=0
top: com.example.piliplus/.MainActivity
```

## 2. d-pad 确认后再用左摇杆，光标会在某些方向卡住

**根因**：空闲会自动隐藏光标（销毁虚拟鼠标设备）。等你用 d-pad 导航一段时间后，
光标早就被隐藏了；这时一推左摇杆，助手会**重建**鼠标设备——而系统里光标的真实位置
在重建后就变了（不可知），但引擎里的位置估算还停在旧地方。
位移夹取是按估算值做的，于是某个方向被"算成到边了"，光标就再也推不过去。

**改法**：鼠标设备重建后立刻
1. 用有界步进把真实光标**拉回屏幕中心**（和 L3 居中同一套逻辑）；
2. 同步引擎的位置估算到中心；
3. 300ms 内忽略摇杆（避免居中惯性把光标又推走）。

助手重启（重连）后也一样重居中。这样估算和真实光标始终一致，不会再"某些区域过不去"。

## 3. 测试（35/35 通过）

新增 3 条用例：

| ID | 用例 | 结果 |
|---|---|---|
| H1 | Start+上 → 打开 PiliPlus（组件解析启动） | PASS |
| H2 | 光标空闲隐藏 → 摇杆恢复时自动回中心 | PASS |
| H3 | 光标四方向都能移动（+x / -x / +y / -y 都有位移） | PASS |

完整：`PASS=35 FAIL=0`（A/B/F/G/H/C/D/E 各组全部通过）

## 4. 使用提示

- 「打开目标应用」现在对第三方 App（PiliPlus 等）也可靠了；如果某个应用连
  `resolve-activity` 都查不到启动入口，最后会用 `monkey` 兜底。
- 光标空闲隐藏后第一次推摇杆，会从**屏幕中心**出现（这是保证不卡边界的前提）。
