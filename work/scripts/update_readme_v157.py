import io, sys
P = "/mnt/e/Dennis/GamePadDex复刻/README.md"
s = io.open(P, encoding="utf-8").read()

def rep(old, new, tag):
    global s
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1); print("ok", tag)

rep("**当前版本：v1.56**", "**当前版本：v1.57**", "version")

rep("""| **v1.56** |""", """| **v1.57** | 左键真正改为鼠标事件（触摸点击变可选）、鼠标设备自动重建、光标不再被推出屏幕 |
| v1.56 |""", "history")

rep("""- 未在 DeX 外接屏（display 9）上做完整回归，仅验证了手机屏路径。""",
"""- 光标位置由引擎估算（读不到系统真实指针坐标），已做"不出屏"夹取，但长时间使用后仍可能有少量偏差；
  按 **L3** 会把光标和估计值一起拉回中心。
- 未在 DeX 外接屏（display 9）上做完整回归，仅验证了手机屏路径。""", "limits")

io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("README updated")
