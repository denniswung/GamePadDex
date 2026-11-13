import io, os
root = r"E:\Dennis\GamePadDex复刻\project"
J = root + r"\app\src\main\java\com\dennis\gamepadmouse"

# ---------- Prefs ----------
pp = J + r"\Prefs.kt"
s = io.open(pp, encoding="utf-8").read()
if '"key_combo"' not in s:
    s = s.replace('val EXTRA_ACTIONS = listOf("mouse_click", "back", "toggle_mouse", "scroll_up", "scroll_down")',
                  'val EXTRA_ACTIONS = listOf("mouse_click", "back", "toggle_mouse", "scroll_up", "scroll_down", "key_combo")', 1)
    io.open(pp, "w", encoding="utf-8", newline="\n").write(s)
    print("prefs ok")

# ---------- injector: meta state + modifier down/up ----------
jp = root + r"\tools\injector\ScrollInject.java"
j = io.open(jp, encoding="utf-8").read()
if "keyCombo" not in j:
    combo = r"""
    private static int keyCodeOf(String name) {
        return android.view.KeyEvent.keyCodeFromString("KEYCODE_" + name.toUpperCase());
    }

    /** ctrl+alt+f style combo, injected on one display */
    private static void keyCombo(int displayId, String combo) {
        String[] parts = combo.toLowerCase().split("\\+");
        int meta = 0;
        int main = -1;
        for (String p : parts) {
            p = p.trim();
            if (p.isEmpty()) continue;
            if (p.equals("ctrl") || p.equals("control")) meta |= android.view.KeyEvent.META_CTRL_ON;
            else if (p.equals("alt")) meta |= android.view.KeyEvent.META_ALT_ON;
            else if (p.equals("shift")) meta |= android.view.KeyEvent.META_SHIFT_ON;
            else if (p.equals("meta") || p.equals("win") || p.equals("super")) meta |= android.view.KeyEvent.META_META_ON;
            else main = keyCodeOf(p);
        }
        if (main < 0) { System.err.println("bad combo " + combo); return; }
        int[] mods = new int[0];
        java.util.ArrayList<Integer> m = new java.util.ArrayList<>();
        if ((meta & android.view.KeyEvent.META_CTRL_ON) != 0) m.add(android.view.KeyEvent.KEYCODE_CTRL_LEFT);
        if ((meta & android.view.KeyEvent.META_ALT_ON) != 0) m.add(android.view.KeyEvent.KEYCODE_ALT_LEFT);
        if ((meta & android.view.KeyEvent.META_SHIFT_ON) != 0) m.add(android.view.KeyEvent.KEYCODE_SHIFT_LEFT);
        if ((meta & android.view.KeyEvent.META_META_ON) != 0) m.add(android.view.KeyEvent.KEYCODE_META_LEFT);
        long now = SystemClock.uptimeMillis();
        for (int code : m) sendKey(displayId, code, android.view.KeyEvent.ACTION_DOWN, 0, now);
        if (meta != 0) {
            sendKey(displayId, main, android.view.KeyEvent.ACTION_DOWN, meta, now);
            sendKey(displayId, main, android.view.KeyEvent.ACTION_UP, meta, now);
        } else {
            sendKey(displayId, main, android.view.KeyEvent.ACTION_DOWN, 0, now);
            sendKey(displayId, main, android.view.KeyEvent.ACTION_UP, 0, now);
        }
        for (int i = m.size() - 1; i >= 0; i--) sendKey(displayId, m.get(i), android.view.KeyEvent.ACTION_UP, 0, now);
        System.err.println("combo " + combo + " dispatched on " + displayId);
    }

    private static void sendKey(int displayId, int keyCode, int action, int meta, long now) {
        android.view.KeyEvent ev = new android.view.KeyEvent(now, now, action, keyCode, 0, meta);
        try {
            android.view.KeyEvent.class.getMethod("setDisplayId", int.class).invoke(ev, displayId);
        } catch (Throwable ignored) {}
        try {
            inject.invoke(im, ev, 1);
        } catch (Throwable t) {
            System.err.println("key inject failed: " + t);
        }
    }

"""
    j = j.replace("    private static void keyEvent(", combo + "    private static void keyEvent(", 1)
    j = j.replace("""            if (line.startsWith("k ")) {""",
"""            if (line.startsWith("c ")) {
                // c <displayId> <combo>
                String[] cp = line.split("\\\\s+", 3);
                if (cp.length >= 3) keyCombo(Integer.parseInt(cp[1]), cp[2]);
                continue;
            }
            if (line.startsWith("k ")) {""", 1)
    io.open(jp, "w", encoding="utf-8", newline="\n").write(j)
    print("injector combo ok")

# ---------- helper: C command ----------
cp = root + r"\app\src\main\assets\gpminput.c"
c = io.open(cp, encoding="utf-8").read()
if "injector_combo" not in c:
    c = c.replace("static void injector_key(", """static void injector_combo(int displayId, const char *combo) {
    if (g_inject_fd < 0) { check_injector(); return; }
    char buf[160];
    int n = snprintf(buf, sizeof(buf), "c %d %s\\n", displayId, combo);
    if (n > 0) { ssize_t r = write(g_inject_fd, buf, (size_t)n); (void)r; out("COMBO %d %s", displayId, combo); }
}

static void injector_key(""", 1)
    c = c.replace("""        case 'E': {""", """        case 'X': {
            int xd = 0;
            char xc[96];
            if (sscanf(line, "%d %95s", &xd, xc) == 2) injector_combo(xd, xc);
            break;
        }
        case 'E': {""", 1)
    io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
    print("helper X ok")

# ---------- RootInput ----------
rp = J + r"\RootInput.kt"
r = io.open(rp, encoding="utf-8").read()
if "fun pointCombo(" not in r:
    r = r.replace("""    /** inject a key event on a specific display (root) */""",
"""    /** inject a keyboard combo ("ctrl+alt+f") on a display (root) */
    fun pointCombo(displayId: Int, combo: String): Boolean {
        if (!isRunning) return false
        send("X $displayId $combo")
        return helperReady
    }

    /** inject a key event on a specific display (root) */""", 1)
    io.open(rp, "w", encoding="utf-8", newline="\n").write(r)
    print("rootinput combo ok")

# ---------- service ----------
sp = J + r"\MouseAccessibilityService.kt"
v = io.open(sp, encoding="utf-8").read()
if "key_combo" not in v:
    v = v.replace("""            "home" -> fireGlobalKey(KeyEvent.KEYCODE_HOME)""",
"""            "key_combo" -> {
                val disp = display?.displayId ?: 0
                if (disp != 0) root?.pointCombo(disp, value.ifBlank { "ctrl+alt+f" })
                else Log.w(TAG, "key_combo needs a DeX display")
            }
            "home" -> fireGlobalKey(KeyEvent.KEYCODE_HOME)""", 1)
    io.open(sp, "w", encoding="utf-8", newline="\n").write(v)
    print("service combo ok")
