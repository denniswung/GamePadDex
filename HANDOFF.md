# GamePadDex 交接说明（换模型用）

最后更新：2026-11-13 · 版本 **v1.46**

## 一句话状态

在 v1.43 骨架上补齐了《手柄按键处理》全部按键/组合，并按《通用控制器控制手机程序》实现了长按四段模型、组合命名空间/继承、导入导出/Profile、摇杆灵敏度/边缘减速/One Euro、角色互换、接入点亮。Debug 两套新测试 **15/15** 与 **10/10** 全绿；Release 已安装并能用。

## 设备

- SM-F9360（Android 16、KernelSU），序列号 **RFCT817KWEH**，adb `192.168.10.36:6666`。
- **写入前必须核对**：`getprop ro.product.model` = SM-F9360、`getprop ro.serialno` = RFCT817KWEH；不匹配立即停止（曾误连 192.168.10.10 的另一台手机）。
- KernelSU 是 late-load：模块 service.sh 开机不执行，助手需手动启动。

## 关键路径

| 路径 | 内容 |
|---|---|
| `project/lsp-dexpad/` | LSPosed 模块（Kotlin，包 `com.dennis.dexpad`） |
| `project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/` | EngineService（核心）、ActionRouter、Prefs、RootInput、ConfigActivity、ButtonDetailActivity、DebugReceiver |
| `project/app/src/main/assets/gpminput.c` | root 助手源码（evdev 抓取 + uinput 鼠标/键盘 + socket 协议） |
| `project/ksu-module/` | KernelSU 模块 `gpm_dex` |
| `项目重构/` | 需求文档（手柄按键处理 / 左右摇杆处理 / 通用控制器控制手机程序） |
| `work/scripts/` | 测试脚本与 vgpad/助手构建脚本 |
| `docs/` | 架构、默认值、测试用例与结果 |
| `release/` | v1.46 APK / KSU zip / 助手二进制 |

## 构建

```bash
# WSL Ubuntu-24.04
mv ~/.gradle/init.gradle ~/.gradle/init.gradle.bak   # 避免仓库策略冲突
cd /mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad
JAVA_HOME=~/tools/jdk-17.0.20.1+1 ANDROID_HOME=~/android-sdk \
  ./gradlew --no-daemon --no-build-cache clean assembleDebug
mv ~/.gradle/init.gradle.bak ~/.gradle/init.gradle
```

助手：

```bash
cd /mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets
aarch64-linux-gnu-gcc -O2 -static -o gpminput gpminput.c display.c -lm
```

## 安装 / 启动（每次改代码后）

```bash
adb -s 192.168.10.36:6666 install -r -d release/dexpad-v1.46.apk
adb push project/app/src/main/assets/gpminput /data/adb/gpm/gpminput
adb push project/app/src/main/assets/gpminput /data/adb/modules/gpm_dex/gpminput
adb shell chmod 755 /data/adb/gpm/gpminput /data/adb/modules/gpm_dex/gpminput
adb shell "ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print \$1}' | xargs -r kill -9"
adb shell "setsid /data/adb/gpm/gpminput --socket /data/data/com.dennis.dexpad/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &"
adb shell "am force-stop com.dennis.dexpad; am start-foreground-service -n com.dennis.dexpad/.EngineService"
```

注意：
- **`assembleRelease` 的 clean 会删掉 debug APK**；跑 DebugReceiver 测试前先 `assembleDebug`。
- 安装后必须 `am force-stop` 再起服务，否则旧进程继续跑旧代码。
- 真实首选项在 `/data/misc/<user>/prefs/com.dennis.dexpad/dexpad.xml`；要回默认就 force-stop 后删这个 xml（`/data/data/.../shared_prefs` 是空壳）。

## 测试

```bash
adb push work/scripts/v145_checklist.sh /data/local/tmp/
adb push work/scripts/v146_checklist.sh /data/local/tmp/
adb push work/scripts/dexpad_precondition.sh /data/local/tmp/
adb push work/scripts/vgpad /data/local/tmp/vgpad
adb shell "chmod 755 /data/local/tmp/v14*.sh /data/local/tmp/vgpad"
adb shell "sh /data/local/tmp/v145_checklist.sh"   # Debug：15/15
adb shell "sh /data/local/tmp/v146_checklist.sh"   # Debug：10/10
```

- `v145` 需要 Debug APK（用到 DebugReceiver 的 `role_swap`）。
- 老版 25 项回归：`work/scripts/checklist_run.sh`（v1.43 基线，预期 25/25）。
- vgpad 常用命令：`key/hold/double/combo/holdstick/hat/hatkey/dblstick/r3rstick`。
- **时序坑**：虚拟手柄设备由 vgpad 创建，helper 用 inotify 秒抓；`pre` 参数=发送前等待，单进程组合（`combo`/`holdstick`）比两次调用可靠。
- 屏幕旋转为横屏时，左摇杆 X 轴影响的是指针 **Y**（测试里用 `hy()`）。

## 已实现（v1.46）

按键（默认）：A=左键（D-pad 后=激活焦点）、B=返回、X 单击无/双击多任务/长按可配、Y=Home、LB/RB=上下滑（按住连续）、LT/RT=缩放、L3=居中（250ms 锁）、R3=静音+双击播放（右摇杆取消）、START=上个应用、SELECT=通知栏、GUIDE 单击无/长按 800ms 帮助、SHARE=鼠标模式。
组合：X+↑/↓ 音量（300ms 后 100ms 连续）、X+←/→ 切歌、X+LB/RB 60% 屏宽横滑（300ms 后 120ms 连续）、X+左摇杆慢速、X+GUIDE 1.5s 强停、SELECT+START 1s 开关屏、Y+L3 电源（保留）。
通用：长按 300–1000ms、组合发起键/等价继承、导入导出 JSON、Profile、角色互换、X/Y 灵敏度、边缘减速、One Euro、接入点亮、inotify 热插拔、强停白名单。

## 未完成（下一模型继续）

1. 控件级焦点（当前任务 bounds + 光标锚点，未做到控件焦点）。
2. 滚轮模式的链路自检 + 权限缺失的显式提示。
3. 导入/导出的 UI 点击流程端到端（API/文件已测）。
4. 10 分钟连续运行、端到端延迟 <50ms 的性能实测。
5. 可选：把 `docs/TEST-CASES-v1.45-full.md` 里 ❌ 项逐条勾掉。

## 绝对不要做

- 不要开飞行模式/关 Wi-Fi（会断 adb）。
- 不要对未核对型号/序列号的 `IP:6666` 写入。
- 不要用 `adb install` 降级不带 `-d`（versionCode 47 > 旧版会 INSTALL_FAILED_VERSION_DOWNGRADE）。
