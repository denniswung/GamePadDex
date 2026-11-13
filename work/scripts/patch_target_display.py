import io
root = r"E:\Dennis\GamePadDex复刻\project"
J = root + r"\app\src\main\java\com\dennis\gamepadmouse"
sp = J + r"\MouseAccessibilityService.kt"
s = io.open(sp, encoding="utf-8").read()

# resolve the DeX display at injection time (ids drift: 8/9/6/...)
if "private fun targetDisplayId()" not in s:
    s = s.replace("    /** display id that currently owns the input focus (-1 = unknown) */",
"""    /** the display every injected event must target: the external/DeX one when present */
    fun targetDisplayId(): Int {
        return try {
            val dm = getSystemService(DisplayManager::class.java)
            val all = dm.displays
            val ext = all.firstOrNull { it.displayId != Display.DEFAULT_DISPLAY && it.state == Display.STATE_ON }
                ?: all.firstOrNull { it.displayId != Display.DEFAULT_DISPLAY }
            ext?.displayId ?: display?.displayId ?: Display.DEFAULT_DISPLAY
        } catch (t: Throwable) {
            display?.displayId ?: Display.DEFAULT_DISPLAY
        }
    }

    /** display id that currently owns the input focus (-1 = unknown) */""", 1)

# combo goes to the fresh DeX id, never silently to the phone
s = s.replace("""            "key_combo" -> {
                val disp = display?.displayId ?: 0
                if (disp != 0) root?.pointCombo(disp, value.ifBlank { "ctrl+alt+f" })
                else Log.w(TAG, "key_combo needs a DeX display")
            }""",
"""            "key_combo" -> {
                val disp = targetDisplayId()
                root?.pointCombo(disp, value.ifBlank { "ctrl+alt+f" })
                Log.i(TAG, "key_combo " + value + " -> display " + disp)
            }""", 1)

# global keys: same fresh resolution
s = s.replace("""    fun fireGlobalKey(keyCode: Int) {
        val disp = display?.displayId ?: 0""",
"""    fun fireGlobalKey(keyCode: Int) {
        val disp = targetDisplayId()""", 1)

# scroll: anchor + display from the fresh id as well
s = s.replace("""                root?.pointScroll(e.pos.x, e.pos.y, dy, 0f, display?.displayId ?: 0)""",
"""                root?.pointScroll(e.pos.x, e.pos.y, dy, 0f, targetDisplayId())""", 1)

io.open(sp, "w", encoding="utf-8", newline="\n").write(s)
print("service: fresh display for every injected event")

# PointerEngine: use the provider for the scroll display id too
ep = J + r"\PointerEngine.kt"
e = io.open(ep, encoding="utf-8").read()
if "displayIdProvider" not in e:
    e = e.replace("    var injectorProvider: (() -> ScrollInjector?)? = null",
                  """    var injectorProvider: (() -> ScrollInjector?)? = null
    /** resolves the display every injection must target (DeX drifts) */
    var displayIdProvider: (() -> Int)? = null""", 1)
    e = e.replace("            val dispId = display?.displayId ?: 0",
                  "            val dispId = (try { displayIdProvider?.invoke() } catch (t: Throwable) { null }) ?: display?.displayId ?: 0", 1)
    io.open(ep, "w", encoding="utf-8", newline="\n").write(e)
    print("engine: display id provider")

sp2 = J + r"\MouseAccessibilityService.kt"
v = io.open(sp2, encoding="utf-8").read()
if "e.displayIdProvider" not in v:
    v = v.replace("        e.injectorProvider = { injector }",
                  "        e.injectorProvider = { injector }\n        e.displayIdProvider = { targetDisplayId() }", 1)
    io.open(sp2, "w", encoding="utf-8", newline="\n").write(v)
    print("service: engine provider wired")