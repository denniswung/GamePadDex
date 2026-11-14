import io, sys
R = "/mnt/e/Dennis/GamePadDex复刻/README.md"
s = io.open(R, encoding="utf-8").read()
fails = []


def rep(old, new, tag):
    global s
    if old not in s:
        fails.append(tag)
        return
    s = s.replace(old, new, 1)


rep("**当前版本：v1.60**", "**当前版本：v1.61**", "version")
rep("""| **v1.60** |""", """| **v1.61** | 修复 d-pad 选中后 A 无法确认：确认键 `KEY_OK(352)` 在三星上无效 → 改 `KEY_ENTER(28)`；导航模式改粘性（推左摇杆才回鼠标点击） |
| v1.60 |""", "history")

rep("""## 9. 已知限制""", """## 8.5 d-pad 与鼠标怎么切换

| 想做的事 | 操作 |
|---|---|
| 用方向键选条目 | 按 d-pad（自动进入导航模式） |
| 确认选中的条目 | 按 **A**（此时注入 `DPAD_CENTER`，不是鼠标点击） |
| 回到鼠标模式 | 推一下**左摇杆**（A 立刻恢复为鼠标点击） |

## 9. 已知限制""", "dpadnote")

if fails:
    print("FAILS:", fails)
    sys.exit(1)
io.open(R, "w", encoding="utf-8", newline="\n").write(s)
print("README updated OK")
