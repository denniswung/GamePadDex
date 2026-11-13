# Gamepad Mouse · DeX 复刻版

对 `com.pkyul13.gamepadmouse`（Google Play "Gamepad mouse" v2.0.2）的净室复刻：
把有线 DeX 下的手柄变成鼠标/键盘，并解决原版「进入鼠标模式后手柄仍被 DeX 当方向键」的核心问题。

- 模块形态：**LSPosed 模块** `com.dennis.dexpad`（入口注入三星设置页）+ **root 助手** `gpminput`（EVIOCGRAB + uinput）
- 目标设备：SM-F9360（Android 16 / KernelSU），也支持手机（非 DeX）模式
- 详细说明：[LSP-手柄映射](docs/LSP-手柄映射.md) ｜ [代码结构](docs/ARCHITECTURE.md) ｜ [测试清单](docs/TEST-CHECKLIST.md) ｜ [测试结果](docs/TEST-RESULTS.md) ｜ [发布说明](release/RELEASE-NOTES.md)

## 1. 能力

- **鼠标**：左摇杆光标（死区 + 曲线可调）、A 左键、B 右键、中键、LB/RB 滚轮、L3 光标居中（含折叠屏旋转补偿）
- **滚动**：右摇杆上下 = 真实触摸拖动（竖向信息流/短剧能正常吸附翻页），左右 = 水平触摸拖动
- **方向键（原生）**：d-pad 在无其他按键按住时转发成系统方向键（原生焦点导航）；按住 X 等键时照常上报，
  `X+↑/↓/←/→` 组合可匹配；A 在原生导航态变为 `DPAD_CENTER` 激活焦点
- **模式**：全局鼠标模式开关；插入有线 DeX 自动开启；「手机上也启用（非 DeX）」默认开
- **DeX 判定**：用 `DexTaskbarWindow` 区分真 DeX 与 HDMI 屏幕镜像；镜像/手机时动作发往手机焦点屏
- **动作表**：音量/媒体、方向键、窗口（最大化/最小化/对齐/关闭/截图/切 DeX）、通知栏、切应用、组合键 24 槽、双击
- **手机降级**：最大化/对齐/切 DeX 跳过；最小化→HOME；关闭应用→force-stop 前台包；截图→SYSRQ
- **后台**：前台服务 + KSU 守护（8 s 轮询），关配置页/划掉任务不停止

## 2. 结构（详见 docs/ARCHITECTURE.md）

```
project/
  lsp-dexpad/                    LSPosed 模块（Kotlin，AGP 9.3.1 / JDK 17）
    app/src/main/java/com/dennis/dexpad/
      Hook.java                往三星设置页注入入口
      ConfigActivity / ButtonDetailActivity   配置页 / 单键详情
      EngineService.kt         8ms 映射循环（摇杆/滑动/缩放/组合调度）
      ActionRouter.kt          一次性动作执行（手机/DeX 分支）
      Actions.kt               动作表（唯一来源）
      DisplayState.kt          DeX/手机屏判定、尺寸、旋转、DEX/FOCUS 上报
      RootInput.kt             助手 socket 客户端
      KeyCodes.kt              Linux→Android、Android→按钮名
      Prefs.kt                 偏好
  app/src/main/assets/gpminput.c  root 助手源码（evdev/协议/注入）
  app/src/main/assets/display.c   助手显示辅助（DeX 判定/分辨率/任务栏）
  app/src/main/assets/gpminput    aarch64 静态二进制
  ksu-module/                    KernelSU 模块（service.sh 守护）
docs/                            模块说明、架构、注入速查
release/                         发布物 + SHA256SUMS + RELEASE-NOTES
backup/                          源码备份 zip
export/toolchain/                通用工具链（助手/脚本/测试/文档）
```

## 3. 构建

```bash
# 模块（WSL）
cd project/lsp-dexpad
JAVA_HOME=~/tools/jdk-17.0.20.1+1 ANDROID_HOME=~/android-sdk \
  ./gradlew --no-daemon --no-build-cache clean assembleRelease

# root 助手（aarch64 静态）
cd project/app/src/main/assets
aarch64-linux-gnu-gcc -O2 -static -o gpminput gpminput.c display.c -lm
```

## 4. 安装

```bash
adb install -r release/dexpad-v1.43.apk
adb shell /data/adb/lspd/cli modules enable com.dennis.dexpad
adb shell /data/adb/lspd/cli scope add com.dennis.dexpad com.android.settings/0
# KernelSU 里刷 gpm_dex-v1.43.zip，或手动：
adb push gpminput-v1.43 /data/adb/gpm/gpminput
adb shell chmod 755 /data/adb/gpm/gpminput
adb shell sh dexpad_start.sh
```

本机 KernelSU 是 late-load：**每次重启都要手动跑一次 `dexpad_start.sh`**（或重新打开无线调试后跑）。

## 5. 测试

```bash
# 虚拟手柄（aarch64）
vgpad key 304 150 3000        # A
vgpad hat 0 1 400 3000        # d-pad 下
vgpad combo 309 310 600 3000  # X+LB
vgpad double 307 60 90 3000   # 双击 X
```

回归脚本在 `work/scripts/`（组合、方向键、关闭应用、居中、滑动），发布前会在真机上逐项跑一遍。

## 6. 发布 / 备份（v1.43，2026-11-08）

| 文件 | 说明 |
|---|---|
| `release/dexpad-v1.43.apk` | LSPosed 模块（versionCode 31 / versionName 1.30，debug 证书签名，可覆盖升级） |
| `release/gpm_dex-v1.43.zip` | KernelSU 模块（v1.43 助手 + 守护） |
| `release/gpminput-v1.43` | root 助手二进制 |
| `release/dexpad_start.sh` | 重启后手动启动助手（含 Doze 白名单） |
| `release/SHA256SUMS.txt` | 校验 |
| `backup/GamePadDex-v1.43-src-*.zip` | 源码 + 文档 + 产物 |

**v1.43 改动**：A 键跟随焦点覆盖全部路径（助手 `PAD` + App 注入方向键都会进入 nativeNav），助手设备移除时清空“按键按住”状态。\n\n**v1.22 改动**：继续拆分——`ActionRouter.kt`（一次性动作执行）+ `KeyCodes.kt`（按键映射）+
助手 `display.c/gpminput.h`；`EngineService` 1166→965 行。回归测试：`X+↓`→`mix 1 x+down -> volume_down`、
单独 ↓→`PAD 108`（App 注入 0 次）、GUIDE→`alt+f4 -> close app on phone`→`CLOSE_APP ... rc=0`、
L3→`CENTER(park) -> 801,1272 (target 800,1280)`。

历史版本见 `release/RELEASE-NOTES.md`。
