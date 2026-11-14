import io, sys
P = "/mnt/e/Dennis/GamePadDex复刻/README.md"
s = io.open(P, encoding="utf-8").read()

def rep(old, new, tag):
    global s
    if old not in s:
        print("MISS", tag)
        sys.exit(1)
    s = s.replace(old, new, 1)
    print("ok", tag)

# 顶部版本号
rep("**当前版本：v1.53**", "**当前版本：v1.54**", "version")

# 功能：鼠标段落里补 A 键点击
rep("""- 右摇杆上下 = **真实触摸拖动**（竖向信息流、短剧能正常吸附翻页）；左右 = 水平拖动""",
"""- **A 键 = 屏幕点击**：在光标位置注入真实触摸（按下→抬起），按住就是**长按**；
  d-pad 模式下 A 仍是「确认焦点」（`DPAD_CENTER`）
- 右摇杆上下 = **真实触摸拖动**（竖向信息流、短剧能正常吸附翻页）；左右 = 水平拖动""", "a click")

# 功能：缩放
rep("""- 扳机 LT/RT = 缩小 / 放大""",
"""- 扳机 **LT / RT = 以光标为中心的双指缩放**：按住连续缩放，松手立即结束；
  d-pad 模式下自动改为 **Ctrl + - / Ctrl + +**
- 动作表新增 **「打开目标应用」**（默认不绑键）：在设置页选好目标 App，绑到任意按键即可一键打开""", "zoom/openapp")

# 键位表
rep("""| A | 鼠标左键 | |""",
"""| A | 屏幕点击（触摸） | 可长按；d-pad 模式 = 确认焦点 |""", "table a")
rep("""| LT / RT | 缩小 / 放大 | `Ctrl+-` / `Ctrl++`，进程内 uinput |""",
"""| LT / RT | 双指缩小 / 放大 | 以光标为基准、按住连续；d-pad 模式 = `Ctrl+-` / `Ctrl++` |""", "table zoom")

# 表格后补一行说明
rep("""| Y + L3 | 开 / 关屏幕 | 走虚拟键盘 KEY_POWER |""",
"""| Y + L3 | 开 / 关屏幕 | 走虚拟键盘 KEY_POWER |

> 「打开目标应用」是动作表里的一项（`open_app`），默认不绑定按键：
> 在「设置 → 手柄鼠标 → 打开目标应用」选好 App，再到按键映射里绑一个键即可。""", "table note")

# 版本历史
rep("""| **v1.53** | GUIDE 短按杀应用（+SIGKILL 兜底）、电源键改走 uinput `KEY_POWER`、L3 改「有界小步归零 + 一步居中」 |""",
"""| **v1.54** | 新增虚拟触摸屏：A = 屏幕点击（可长按）、LT/RT = 以光标为基准的双指缩放（d-pad 模式走 `Ctrl±`）、新增「打开目标应用」动作 |
| v1.53 | GUIDE 短按杀应用（+SIGKILL 兜底）、电源键改走 uinput `KEY_POWER`、L3 改「有界小步归零 + 一步居中」 |""", "history")

# 已知限制补一条
rep("""- 未在 DeX 外接屏（display 9）上做完整回归，仅验证了手机屏路径。""",
"""- 未在 DeX 外接屏（display 9）上做完整回归，仅验证了手机屏路径。
- 触摸点击/双指缩放走"默认显示"的虚拟触摸屏，DeX 外接屏上的这两个功能暂未验证。
- 带双击动作的按键（如 R3）单击会延迟一个双击窗口（320 ms）才触发。""", "limits")

io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("README updated")
