import io, sys
P = "/mnt/e/Dennis/GamePadDex复刻/README.md"
s = io.open(P, encoding="utf-8").read()
fails = []


def rep(old, new, tag):
    global s
    if old not in s:
        fails.append(tag)
        return
    s = s.replace(old, new, 1)


rep("**当前版本：v1.58**", "**当前版本：v1.59**", "version")

rep("""- 滑动时助手仍会同步查一次窗口边界（`dumpsys`），首帧可能有百毫秒级延迟。""",
    """- 滑动用的 task 边界有 2 秒缓存；切换应用后最多 2 秒内，非全屏（多窗口）场景的滑动边界可能还是旧的。""", "limits")

rep("""| **v1.58** | 映射列表精简（46→38）""",
    """| **v1.59** | 滑动不再同步 `dumpsys`（task 边界缓存 + 光标坐标随命令下发），滑动准备耗时 200–600ms → 0.4–1.1ms |
| v1.58 | 映射列表精简（46→38）""", "history")

if fails:
    print("FAILS:", fails); sys.exit(1)
io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("README updated OK")
