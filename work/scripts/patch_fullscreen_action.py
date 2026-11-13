import io
root = r"E:\Dennis\GamePadDex复刻\project"
J = root + r"\app\src\main\java\com\dennis\gamepadmouse"

# ---- helper: F <display> <pkg/cls> -> am start --windowingMode 1 ----
cp = root + r"\app\src\main\assets\gpminput.c"
c = io.open(cp, encoding="utf-8").read()
if "case 'F':" not in c:
    c = c.replace("        case 'X': {", """        case 'F': {
            int fd = 0;
            char fcomp[192];
            if (sscanf(line, "%d %191s", &fd, fcomp) == 2 && fd > 0) {
                char cmd[420];
                snprintf(cmd, sizeof(cmd),
                    "/system/bin/am start --display %d --windowingMode 1 -n %s >/dev/null 2>&1",
                    fd, fcomp);
                int rc = system(cmd);
                out("FULLSCREEN %d %s rc=%d", fd, fcomp, rc);
            }
            break;
        }
        case 'X': {""", 1)
    io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
    print("helper F ok")

# ---- RootInput ----
rp = J + r"\RootInput.kt"
r = io.open(rp, encoding="utf-8").read()
if "fun relaunchFullscreen" not in r:
    r = r.replace("    /** inject a keyboard combo", """    /** relaunch a component in fullscreen windowing mode on a display (root) */
    fun relaunchFullscreen(displayId: Int, component: String): Boolean {
        if (!isRunning) return false
        send("F $displayId $component")
        return helperReady
    }

    /** inject a keyboard combo""", 1)
    io.open(rp, "w", encoding="utf-8", newline="\n").write(r)
    print("rootinput ok")

# ---- service: track the foreground component per display + the action ----
sp = J + r"\MouseAccessibilityService.kt"
s = io.open(sp, encoding="utf-8").read()
if "lastFgComponent" not in s:
    s = s.replace("    private val pressedButtons = HashSet<Int>()",
"""    private val pressedButtons = HashSet<Int>()
    /** package/activity currently in front on the DeX display */
    private var lastFgComponent: String? = null""", 1)
    # remember it from window-state events
    s = s.replace("""            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,""",
"""            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,""", 1)
    s = s.replace("""    override fun onAccessibilityEvent(event: AccessibilityEvent?) {""",
"""    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val pkg = event.packageName?.toString()
            val cls = event.className?.toString()
            val disp = try { event.displayId } catch (t: Throwable) { 0 }
            if (!pkg.isNullOrBlank() && !cls.isNullOrBlank() &&
                cls.startsWith(pkg) && disp != 0 && disp == targetDisplayId()
            ) {
                lastFgComponent = pkg + "/" + cls
            }
        }""", 1)
    s = s.replace("""            "key_combo" -> {""",
"""            "dex_fullscreen" -> {
                val disp = targetDisplayId()
                val comp = lastFgComponent
                if (comp != null) {
                    root?.relaunchFullscreen(disp, comp)
                    Log.i(TAG, "dex fullscreen " + comp + " on display " + disp)
                } else {
                    Log.w(TAG, "dex fullscreen: no foreground component yet")
                }
            }
            "key_combo" -> {""", 1)
    io.open(sp, "w", encoding="utf-8", newline="\n").write(s)
    print("service ok")

# ---- prefs: expose the action ----
pp = J + r"\Prefs.kt"
p = io.open(pp, encoding="utf-8").read()
if "dex_fullscreen" not in p:
    p = p.replace('"scroll_up", "scroll_down", "key_combo")',
                  '"scroll_up", "scroll_down", "key_combo", "dex_fullscreen")', 1)
    io.open(pp, "w", encoding="utf-8", newline="\n").write(p)
    print("prefs ok")

# ---- label ----
xp = root + r"\app\src\main\res\values\strings_extra.xml"
x = io.open(xp, encoding="utf-8").read()
if "action_dex_fullscreen" not in x:
    x = x.replace("</resources>", "    <string name=\"action_dex_fullscreen\">DeX 全屏</string>\n</resources>", 1)
    io.open(xp, "w", encoding="utf-8", newline="\n").write(x)
    print("strings ok")

mp = J + r"\MainActivity.kt"
m = io.open(mp, encoding="utf-8").read()
if "action_dex_fullscreen" not in m:
    m = m.replace('        "key_combo" -> getString(R.string.action_key_combo)',
                  '        "key_combo" -> getString(R.string.action_key_combo)\n        "dex_fullscreen" -> getString(R.string.action_dex_fullscreen)', 1)
    io.open(mp, "w", encoding="utf-8", newline="\n").write(m)
    print("mainactivity ok")