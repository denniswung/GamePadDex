import sys, io

# 1) helper: lowercase 'p' = press the power key (root)
h = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
src = io.open(h, encoding="utf-8").read()
anchor = "        case 'r': {"
assert anchor in src
new_case = '''        case 'p': {
            /* 模拟电源键：helper 以 root 运行，input 命令可以直接注入
             * KEYCODE_POWER(26)，屏幕亮灭都生效。 */
            system("input keyevent 26");
            out("POWER");
            break;
        }
        case 'r': {'''
src = src.replace(anchor, new_case, 1)
io.open(h, "w", encoding="utf-8", newline="\n").write(src)

# 2) RootInput: powerKey()
r = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt"
src = io.open(r, encoding="utf-8").read()
anchor = '''    /** force phone rotation: 1 landscape, 0 portrait, -1 automatic */'''
method = '''    /** press the power key (screen on/off), injected by the root helper */
    fun powerKey() {
        send("p")
    }

'''
assert anchor in src
src = src.replace(anchor, method + anchor, 1)
io.open(r, "w", encoding="utf-8", newline="\n").write(src)

# 3) Actions: POWER action
a = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/Actions.kt"
src = io.open(a, encoding="utf-8").read()
src = src.replace('''    /** alt+tab: switch to the previous app */''',
'''    /** simulate the power key: screen off / on */
    const val POWER = "power"

    /** alt+tab: switch to the previous app */''', 1)
src = src.replace("        CENTER_CURSOR, SWITCH_APP,", "        CENTER_CURSOR, SWITCH_APP, POWER,", 1)
src = src.replace('''        SWITCH_APP -> "切换软件"''', '''        SWITCH_APP -> "切换软件"
        POWER -> "开/关屏幕（电源键）"''', 1)
io.open(a, "w", encoding="utf-8", newline="\n").write(src)

# 4) ActionRouter: case POWER
ar = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ActionRouter.kt"
src = io.open(ar, encoding="utf-8").read()
anchor = '''            Action.SWITCH_APP -> {'''
assert anchor in src
src = src.replace(anchor, '''            Action.POWER -> {
                root.powerKey()
                log("power key (screen toggle)")
            }
            Action.SWITCH_APP -> {''', 1)
io.open(ar, "w", encoding="utf-8", newline="\n").write(src)

# 5) Prefs: default mix slot 6 = y+l3 -> power
p = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/Prefs.kt"
src = io.open(p, encoding="utf-8").read()
src = src.replace('''            5 -> "x+rb"
            else -> ""''', '''            5 -> "x+rb"
            // Y + L3 = 开/关屏幕（模拟电源键）
            6 -> "y+l3"
            else -> ""''', 1)
src = src.replace('''            5 -> Action.WHEEL_RIGHT   // X + RB = 向右滑动（下一页）
            else -> Action.NONE''', '''            5 -> Action.WHEEL_RIGHT   // X + RB = 向右滑动（下一页）
            6 -> Action.POWER         // Y + L3 = 开/关屏幕
            else -> Action.NONE''', 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(src)
print("ok")
