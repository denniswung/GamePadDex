import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
P = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/Prefs.kt"
fails = []

# ---------- helper：APP_SWITCH 的正确 linux 键码是 580（Generic.kl: key 580 APP_SWITCH） ----------
h = io.open(H, encoding="utf-8").read()
old = "        case 187: return 125;  /* APP_SWITCH */"
if old not in h:
    fails.append("187")
else:
    h = h.replace(old, "        case 187: return 580;  /* APP_SWITCH（多任务/最近任务）*/", 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(h)

# ---------- 默认组合 X+LB / X+RB 对调 ----------
p = io.open(P, encoding="utf-8").read()
old4 = '''            4 -> Action.WHEEL_LEFT    // X + LB = 向左滑动（上一页）
            5 -> Action.WHEEL_RIGHT   // X + RB = 向右滑动（下一页）'''
new4 = '''            4 -> Action.WHEEL_RIGHT   // X + LB = 内容向右（上一页）
            5 -> Action.WHEEL_LEFT    // X + RB = 内容向左（下一页）'''
if old4 not in p:
    fails.append("mix45")
else:
    p = p.replace(old4, new4, 1)
# 双击窗口放宽一点（人手双击 300ms 左右很常见）
p2 = io.open("/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt", encoding="utf-8").read()
oldw = "private val DOUBLE_WINDOW = 320L"
if oldw in p2:
    p2 = p2.replace(oldw, "private val DOUBLE_WINDOW = 400L", 1)
    io.open("/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt", "w", encoding="utf-8", newline="\n").write(p2)
else:
    fails.append("dblwindow")
io.open(P, "w", encoding="utf-8", newline="\n").write(p)
print("FAILS:", fails if fails else "none")
