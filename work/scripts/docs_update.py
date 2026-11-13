import io
p = r"E:\Dennis\GamePadDex复刻\README.md"
s = io.open(p, encoding="utf-8").read()
add = """
## 2.6 按键映射（全键 + 组合）

- **全键映射**：A / B / X / Y / LB / RB / LT / RT / ↑ ↓ ← → / L3 / R3 / START / SELECT / GUIDE
  共 17 个按键，每个都能单独改成任意动作（默认行为、15 个内置动作，外加
  `鼠标左键点击`、`返回`、`切换鼠标模式`、`向上滚`、`向下滚`）。
  存储：`pref_btn_<name>_type` / `pref_btn_<name>_value`。
- **组合按键**：8 组，形式如 `X + A`、`LB + RB`，**组合优先于单键**（所有按键都按住时触发，
  单次按下只触发一次）。存储：`pref_combo_<i>_keys`（`+` 连接）/ `_type` / `_value`。
- 原版那 8 个 `X + 方向/肩键` 槽位仍然保留（Button Mapping 页上半部分），
  新增的"全键映射 / 组合按键"追加在同一个页面的下半部分。

## 2.7 守护与部署

- **KernelSU 模块** `project/ksu-module/`（id `gpm_dex`）：开机同步 `gpminput` + `inject.dex` 到
  `/data/adb/gpm/`，并阻塞式运行助手，退出即重启。
- **助手内 watchdog**：每 ~2s `waitpid(WNOHANG)` 检查 `ScrollInject` 子进程，死了立即重拉；
  管道写失败（EPIPE）同样重建，避免"注入器一死滚动永久失效"。
- **App 侧重连**：`rootRetry` 每 6/10s 检查助手，断线自动重连并切换 native/gesture 后端。
"""
if "2.6 按键映射" not in s:
    s = s.replace("## 3. 目录", add + "\n## 3. 目录", 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("readme updated")