import io, re

# ---------- helper: drop TOP/HOME reporting ----------
p = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(p, encoding="utf-8").read()

# 1) remove both functions (from their comment/definition to the closing brace line)
for marker in ["/* package of the current HOME app (default launcher) */",
               "/* package of the activity currently resumed on the focused display */"]:
    i = s.find(marker)
    assert i > 0, marker
    j = s.find("\n}\n", i)
    assert j > i
    s = s[:i] + s[j + 3:]

# 2) READY HOME block
i = s.find("        {\n            char home[160];")
assert i > 0
j = s.find("\n        }\n", i)
assert j > i
s = s[:i] + s[j + len("\n        }\n"):]

# 3) periodic TOP block + last_top declaration
i = s.find("            {\n                char topnow[160];")
assert i > 0
j = s.find("\n            }\n", i)
assert j > i
s = s[:i] + s[j + len("\n            }\n"):]
s = s.replace("    char last_top[160] = {0};\n", "")

io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("helper patched; top/home left:", s.count("read_top_package"), s.count("read_home_package"))

# ---------- Kotlin ----------
base = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/"

def load(n):
    return io.open(base + n, encoding="utf-8").read()

def save(n, s):
    io.open(base + n, "w", encoding="utf-8", newline="\n").write(s)

# RootInput
s = load("RootInput.kt")
s = s.replace("""        /** foreground package on the focused display changed */
        fun onTop(pkg: String)

        /** default launcher package (HOME app) reported by the helper */
        fun onHome(pkg: String)

""", "")
s = s.replace("""            line.startsWith("TOP ") -> listener.onTop(line.removePrefix("TOP ").trim())
""", "")
s = s.replace("""            line.startsWith("HOME ") -> listener.onHome(line.removePrefix("HOME ").trim())
""", "")
save("RootInput.kt", s)

# EngineService
s = load("EngineService.kt")
s = s.replace("""    /** foreground package of the focused display (helper reports TOP ...) */
    private var topPkg: String = ""

    /** default launcher package (helper reports HOME ...) */
    private var homePkg: String = ""

    override fun onHome(pkg: String) {
        if (pkg != homePkg) {
            homePkg = pkg
            Log.i(TAG, "home package: $pkg")
        }
    }

    override fun onTop(pkg: String) {
        if (pkg != topPkg) {
            topPkg = pkg
            Log.i(TAG, "top package: $pkg")
        }
    }

""", "")

old_block = """                    // per-app tuning: feeds (抖音/红果/PiliPlus) and the launcher
                    // need roughly one item / one drawer-step per gesture, so a
                    // shorter, faster drag reads as a flick; other apps keep the
                    // long page-flip drag
                    val feed = topPkg == "com.ss.android.ugc.aweme" ||
                        topPkg == "com.phoenix.read" ||
                        topPkg == "com.example.piliplus"
                    val launcher = topPkg.isNotEmpty() && topPkg == (homePkg.ifEmpty { "app.lawnchair" })
                    val short = feed || launcher
                    // the launcher drawer gesture only triggers when the finger
                    // starts low on the screen, so use a bottom-anchored drag
                    val down = ny <= 0
                    val dist = when {
                        launcher -> (h * 0.45f).toInt().coerceIn(320, 1200)
                        feed -> (h * 0.30f).toInt().coerceIn(320, 1000)
                        down -> (h * 0.45f).toInt().coerceIn(320, 1200)
                        else -> (h * 0.35f).toInt().coerceIn(360, 1200)
                    }
                    val pct = when {
                        launcher -> if (down) 3 else 88
                        feed -> if (down) 35 else 65
                        down -> 3          // pull-down: shade needs the top edge
                        else -> 65
                    }
                    // feeds snap one item per swipe; pulling down is a single
                    // shade gesture; scrolling up drags slowly and repeats
                    val ms = when {
                        launcher -> 200
                        feed -> 150
                        down -> 200
                        else -> 450
                    }
                    val dy = if (down) dist else -dist
                    root.swipeV(display, dy, ms, w, h, pct)
                    vSwipeCooldownUntil = now + when {
                        launcher -> swipeRepeatMs()   // one drawer step per push
                        feed -> swipeRepeatMs()       // one video per swipe
                        down -> swipeRepeatMs()       // one shade pull per push
                        else -> ms + 40L              // continuous: no idle gap
                    }"""

new_block = """                    // app-agnostic gesture policy: pull down = one shade pull
                    // from the top edge; push up = one long slow drag, repeated
                    // back-to-back so the content keeps moving
                    val down = ny <= 0
                    val dist = if (down) (h * 0.45f).toInt().coerceIn(320, 1200)
                               else (h * 0.35f).toInt().coerceIn(360, 1200)
                    val pct = if (down) 3 else 65
                    val ms = if (down) 200 else 450
                    val dy = if (down) dist else -dist
                    root.swipeV(display, dy, ms, w, h, pct)
                    vSwipeCooldownUntil = now + if (down) swipeRepeatMs() else ms + 40L"""

assert old_block in s
s = s.replace(old_block, new_block, 1)
save("EngineService.kt", s)
print("kotlin patched")
