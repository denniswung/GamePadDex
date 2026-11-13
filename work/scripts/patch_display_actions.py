import io, os
root = r"E:\Dennis\GamePadDex复刻\project"
J = os.path.join(root, "app", "src", "main", "java", "com", "dennis", "gamepadmouse")

# ---------- 1) injector: key events with an explicit display ----------
jp = os.path.join(root, "tools", "injector", "ScrollInject.java")
s = io.open(jp, encoding="utf-8").read()
if "private static void keyEvent(" not in s:
    s = s.replace("""            String[] p = line.split("\\\\s+");
            if (p.length < 3) continue;
            try {""",
"""            if (line.startsWith("k ")) {
                // k <displayId> <androidKeyCode>
                String[] kp = line.split("\\\\s+");
                if (kp.length >= 3) keyEvent(Integer.parseInt(kp[1]), Integer.parseInt(kp[2]));
                continue;
            }
            String[] p = line.split("\\\\s+");
            if (p.length < 3) continue;
            try {""", 1)

    s = s.replace("    private static void scroll(", """    private static void keyEvent(int displayId, int keyCode) {
        long now = SystemClock.uptimeMillis();
        for (int action : new int[]{android.view.KeyEvent.ACTION_DOWN, android.view.KeyEvent.ACTION_UP}) {
            android.view.KeyEvent ev = new android.view.KeyEvent(now, now, action, keyCode, 0);
            try {
                android.view.KeyEvent.class.getMethod("setDisplayId", int.class).invoke(ev, displayId);
            } catch (Throwable ignored) {}
            try {
                inject.invoke(im, ev, 1);
                System.err.println("key " + keyCode + " disp=" + displayId + " action=" + action);
            } catch (Throwable t) {
                System.err.println("key inject failed: " + t);
            }
        }
    }

    private static void scroll(""", 1)
    io.open(jp, "w", encoding="utf-8", newline="\n").write(s)
    print("injector: key events ok")

# ---------- 2) C helper: forward K commands ----------
cp = os.path.join(root, "app", "src", "main", "assets", "gpminput.c")
c = io.open(cp, encoding="utf-8").read()
if "injector_key" not in c:
    c = c.replace("static void injector_scroll(", """static void injector_key(int displayId, int androidKeyCode) {
    if (g_inject_fd < 0) { check_injector(); return; }
    char buf[64];
    int n = snprintf(buf, sizeof(buf), "k %d %d\\n", displayId, androidKeyCode);
    if (n > 0) { ssize_t r = write(g_inject_fd, buf, (size_t)n); (void)r; }
}

static void injector_scroll(""", 1)
    c = c.replace("""        case 'P': {""", """        case 'K': {
            int kd = 0, kc = 0;
            if (sscanf(line, "%d %d", &kd, &kc) == 2) injector_key(kd, kc);
            break;
        }
        case 'P': {""", 1)
    io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
    print("helper: K command ok")

# ---------- 3) RootInput: pointKey ----------
rp = os.path.join(J, "RootInput.kt")
r = io.open(rp, encoding="utf-8").read()
if "fun pointKey(" not in r:
    r = r.replace("""    /** ask the root injector for a real ACTION_SCROLL event at (x,y) */""",
"""    /** inject a key event on a specific display (root) */
    fun pointKey(displayId: Int, keyCode: Int): Boolean {
        if (!isRunning) return false
        send("K $displayId $keyCode")
        return helperReady
    }

    /** ask the root injector for a real ACTION_SCROLL event at (x,y) */""", 1)
    io.open(rp, "w", encoding="utf-8", newline="\n").write(r)
    print("rootinput ok")

# ---------- 4) service: global keys go to the controlled display ----------
sp = os.path.join(J, "MouseAccessibilityService.kt")
v = io.open(sp, encoding="utf-8").read()
if "fun fireGlobalKey" not in v:
    v = v.replace("""    /** runs a mapped action, including the pseudo actions handled here */""",
"""    /**
     * global actions (home / recents / back) are performed on the display we
     * control, otherwise they land on the phone's screen while DeX is active
     */
    fun fireGlobalKey(keyCode: Int) {
        val disp = display?.displayId ?: 0
        if (disp != 0 && root?.helperReady == true) {
            root?.pointKey(disp, keyCode)
            Log.i(TAG, "global key " + keyCode + " -> display " + disp)
            return
        }
        when (keyCode) {
            KeyEvent.KEYCODE_HOME -> performGlobalAction(GLOBAL_ACTION_HOME)
            KeyEvent.KEYCODE_APP_SWITCH -> performGlobalAction(GLOBAL_ACTION_RECENTS)
            KeyEvent.KEYCODE_BACK -> performGlobalAction(GLOBAL_ACTION_BACK)
            else -> performGlobalAction(GLOBAL_ACTION_HOME)
        }
    }

    /** runs a mapped action, including the pseudo actions handled here */""", 1)
    # route the mapped home/recents/back through it
    v = v.replace('            "back" -> ActionDispatcher.back(this)',
                  '            "back" -> fireGlobalKey(KeyEvent.KEYCODE_BACK)', 1)
    v = v.replace('            else -> ActionDispatcher.run(this, prefs, action, value, "")',
                  """            "home" -> fireGlobalKey(KeyEvent.KEYCODE_HOME)
            "recents" -> fireGlobalKey(KeyEvent.KEYCODE_APP_SWITCH)
            else -> ActionDispatcher.run(this, prefs, action, value, "")""", 1)
    io.open(sp, "w", encoding="utf-8", newline="\n").write(v)
    print("service ok")
