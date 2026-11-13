import io, re

base = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/"


def repl(path, old, new, count=1):
    s = io.open(path, encoding="utf-8").read()
    assert old in s, (path, old[:60])
    s = s.replace(old, new, count)
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)


# ---------------- EngineState ----------------
repl(base + "EngineState.kt",
     "    @Volatile var dexConnected = false\n", "")

# ---------------- RootInput ----------------
p = base + "RootInput.kt"
s = io.open(p, encoding="utf-8").read()
s = s.replace("        /** real DeX display id, or -1 when the HDMI screen is only mirroring */\n        fun onDeX(displayId: Int)\n\n        /** currently focused display (cover/inner phone screen, or DeX) */\n        fun onFocus(displayId: Int)\n\n", "")
s = s.replace("""            line.startsWith("DEX ") -> {
                val id = line.removePrefix("DEX ").trim().toIntOrNull() ?: -1
                listener.onDeX(id)
            }
""", "")
s = s.replace("""            line.startsWith("FOCUS ") -> {
                val id = line.removePrefix("FOCUS ").trim().toIntOrNull() ?: -1
                listener.onFocus(id)
            }
""", "")
io.open(p, "w", encoding="utf-8", newline="\n").write(s)

# ---------------- EngineService ----------------
p = base + "EngineService.kt"
s = io.open(p, encoding="utf-8").read()
s = s.replace("import android.hardware.display.DisplayManager\n", "")
s = s.replace("    private lateinit var displayManager: DisplayManager\n", "")
s = s.replace("            Prefs.KEY_ENABLED, Prefs.KEY_AUTO_DEX -> {", "            Prefs.KEY_ENABLED -> {")
s = s.replace("                if (key == Prefs.KEY_AUTO_DEX) refreshDeX()\n", "")
s = s.replace("""    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) = refreshDeX()
        override fun onDisplayRemoved(displayId: Int) = refreshDeX()
        override fun onDisplayChanged(displayId: Int) = refreshDeX()
    }

""", "")
s = s.replace("        displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager\n", "")
s = s.replace("            displayManager.registerDisplayListener(displayListener, handler)\n", "")
s = s.replace("            displayManager.unregisterDisplayListener(displayListener)\n", "")
s = s.replace("        refreshDeX()\n", "")
s = s.replace("        prefs.enabled && prefs.modeOn && (EngineState.dexConnected || prefs.phoneMode)",
              "        prefs.enabled && prefs.modeOn")
s = s.replace("private fun activeDisplay(): Int = displayState.active(prefs.forcePhone)",
              "private fun activeDisplay(): Int = displayState.active()")
s = s.replace("    override fun onFocus(displayId: Int) = displayState.onFocus(displayId)\n", "")
s = s.replace("private fun onPhone(): Boolean = displayState.isPhone(prefs.forcePhone)",
              "private fun onPhone(): Boolean = true")
s = s.replace("        val speed = (if (onPhone()) prefs.speedPhone else prefs.speedDex) * scale",
              "        val speed = prefs.speedPhone * scale")
s = s.replace("        EngineState.dexConnected = displayState.dexConnected\n", "")
# drop refreshDeX() + onDeX() functions entirely
start = s.find("    private fun refreshDeX() {")
if start >= 0:
    end = s.find("    override fun onPadKey", start)
    if end < 0:
        end = s.find("    private fun", start + 10)
    s = s[:start] + s[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)

# ---------------- ActionRouter ----------------
p = base + "ActionRouter.kt"
s = io.open(p, encoding="utf-8").read()
s = s.replace("""            // DeX window shortcuts (the DeX shortcut service filters synthetic
            // CMD chords, so windows are arranged through `am task resize`).
            // On the phone these degrade to the closest phone action.
            Action.MAXIMIZE -> {
                if (host.isPhone()) log("maximize skipped on phone")
                else {
                    root.arrangeWindow(display, "max")
                    log("maximize window on display $display")
                }
            }
            Action.MINIMIZE -> {
                if (host.isPhone()) {
                    root.pointKey(display, KeyEvent.KEYCODE_HOME)
                    log("minimize -> home on display $display")
                } else {
                    combo(display, "minimize", KeyEvent.KEYCODE_META_LEFT, KeyEvent.KEYCODE_MINUS)
                }
            }
            Action.SNAP_LEFT -> {
                if (host.isPhone()) log("snap left skipped on phone")
                else {
                    root.arrangeWindow(display, "left")
                    log("snap window left on display $display")
                }
            }
            Action.SNAP_RIGHT -> {
                if (host.isPhone()) log("snap right skipped on phone")
                else {
                    root.arrangeWindow(display, "right")
                    log("snap window right on display $display")
                }
            }
            Action.CLOSE_WINDOW -> {
                if (host.isPhone()) {
                    root.closeApp()
                    log("close app on phone")
                } else {
                    combo(display, "close window", KeyEvent.KEYCODE_ALT_LEFT, KeyEvent.KEYCODE_F4)
                }
            }
            Action.TOGGLE_DEX -> {
                if (host.isPhone()) log("toggle DeX skipped on phone")
                else combo(display, "toggle DeX", KeyEvent.KEYCODE_META_LEFT, KeyEvent.KEYCODE_W)
            }
            Action.SCREENSHOT -> {
                if (host.isPhone()) {
                    root.pointKey(display, KeyEvent.KEYCODE_SYSRQ)
                    log("screenshot (SYSRQ) on display $display")
                } else {
                    combo(display, "screenshot", KeyEvent.KEYCODE_ALT_LEFT, KeyEvent.KEYCODE_SYSRQ)
                }
            }
""", """            Action.MINIMIZE -> {
                root.pointKey(display, KeyEvent.KEYCODE_HOME)
                log("minimize -> home on display $display")
            }
            Action.CLOSE_WINDOW -> {
                root.closeApp()
                log("close app on display $display")
            }
            Action.SCREENSHOT -> {
                root.pointKey(display, KeyEvent.KEYCODE_SYSRQ)
                log("screenshot (SYSRQ) on display $display")
            }
""")
io.open(p, "w", encoding="utf-8", newline="\n").write(s)

# ---------------- Actions ----------------
p = base + "Actions.kt"
s = io.open(p, encoding="utf-8").read()
for line in [
    '    // DeX window / system shortcuts taken from the DeX "键盘快捷键" page\n',
    '    const val MAXIMIZE = "maximize_window"      // CMD + =\n',
    '    const val SNAP_LEFT = "snap_left"           // CMD + [\n',
    '    const val SNAP_RIGHT = "snap_right"         // CMD + ]\n',
    '    const val TOGGLE_DEX = "toggle_dex"         // CMD + W\n',
]:
    s = s.replace(line, "")
s = s.replace("        MAXIMIZE, MINIMIZE, SNAP_LEFT, SNAP_RIGHT, CLOSE_WINDOW, TOGGLE_DEX, SCREENSHOT,",
              "        MINIMIZE, CLOSE_WINDOW, SCREENSHOT,")
for line in [
    '        MAXIMIZE -> "最大化窗口"\n',
    '        SNAP_LEFT -> "贴到左侧"\n',
    '        SNAP_RIGHT -> "贴到右侧"\n',
    '        TOGGLE_DEX -> "切换 DeX"\n',
]:
    s = s.replace(line, "")
io.open(p, "w", encoding="utf-8", newline="\n").write(s)

# ---------------- Prefs ----------------
p = base + "Prefs.kt"
s = io.open(p, encoding="utf-8").read()
s = s.replace('        const val KEY_AUTO_DEX = "auto_dex"\n', "")
s = s.replace('        const val KEY_PHONE_MODE = "phone_mode"\n', "")
s = s.replace('        const val KEY_FORCE_PHONE = "force_phone"\n', "")
s = re.sub(r"    /\*\* auto-enter mouse mode when DeX appears \*/\n    var autoDex: Boolean\n        get\(\) = shared\.getBoolean\(KEY_AUTO_DEX, true\)\n        set\(v\) = shared\.edit\(\)\.putBoolean\(KEY_AUTO_DEX, v\)\.apply\(\)\n\n", "", s)
s = re.sub(r"    var speedDex: Int\n        get\(\) = shared\.getInt\(KEY_SPEED_DEX[^\n]*\n        set\(v\) = shared\.edit\(\)\.putInt\(KEY_SPEED_DEX[^\n]*\n\n", "", s)
s = re.sub(r"    /\*\* allow mapping without a DeX screen \*/\n    var phoneMode: Boolean\n        get\(\) = shared\.getBoolean\(KEY_PHONE_MODE, true\)\n        set\(v\) = shared\.edit\(\)\.putBoolean\(KEY_PHONE_MODE, v\)\.apply\(\)\n\n", "", s)
s = re.sub(r"    /\*\* debug-only: pretend there is no DeX and target display 0 \*/\n    var forcePhone: Boolean\n        get\(\) = shared\.getBoolean\(KEY_FORCE_PHONE, false\)\n        set\(v\) = shared\.edit\(\)\.putBoolean\(KEY_FORCE_PHONE, v\)\.apply\(\)\n\n", "", s)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)

print("patched core")
