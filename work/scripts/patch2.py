import io, os
root = r"E:\Dennis\GamePadDex复刻\project"

# --- Kotlin: remove the inner gate that blocked horizontal dispatch ---
pk = os.path.join(root, "app", "src", "main", "java", "com", "dennis", "gamepadmouse", "PointerEngine.kt")
s = io.open(pk, encoding="utf-8").read()
old = """            if (horizontal) {
                // Android apps almost never handle AXIS_HSCROLL, so horizontal
                // scrolling goes through a real touch swipe instead
                if (now - lastScrollAt >= 90) {
                    val sweep = (40f + 160f * scrollMag) * (scrollSpeed / 2f)
                    gesture.scroll(ax, ay, sx, 0f, sweep)
                }
                ok = true
            } else {"""
new = """            if (horizontal) {
                // Android apps almost never handle AXIS_HSCROLL, so horizontal
                // scrolling goes through a real touch swipe instead
                if (now - lastHScrollAt >= 90) {
                    lastHScrollAt = now
                    val sweep = (40f + 160f * scrollMag) * (scrollSpeed / 2f)
                    gesture.scroll(ax, ay, sx, 0f, sweep)
                }
                ok = true
            } else {"""
assert old in s, "kotlin horizontal block not found"
s = s.replace(old, new, 1)
s = s.replace("    private var lastScrollAt = 0L", "    private var lastScrollAt = 0L\n    private var lastHScrollAt = 0L", 1)
io.open(pk, "w", encoding="utf-8", newline="\n").write(s)
print("kotlin patched")

# --- C: spawn the injector only once ---
cp = os.path.join(root, "app", "src", "main", "assets", "gpminput.c")
c = io.open(cp, encoding="utf-8").read()
if "g_inject_fd >= 0) return;" not in c:
    c = c.replace("static void spawn_injector(void) {",
                  "static void spawn_injector(void) {\n    if (g_inject_fd >= 0) return;   // already running", 1)
    io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
    print("c patched")
else:
    print("c already guarded")