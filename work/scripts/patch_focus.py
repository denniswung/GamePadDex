import io, os
root = r"E:\Dennis\GamePadDex复刻\project"
svc = os.path.join(root, "app", "src", "main", "java", "com", "dennis", "gamepadmouse",
                   "MouseAccessibilityService.kt")
s = io.open(svc, encoding="utf-8").read()

# 1) helper: which display currently owns the input focus
if "private fun focusedDisplayId()" not in s:
    helper = """    /** display id that currently owns the input focus (-1 = unknown) */
    private fun focusedDisplayId(): Int {
        return try {
            windows?.firstOrNull { it.isFocused }?.displayId ?: -1
        } catch (t: Throwable) {
            -1
        }
    }

"""
    s = s.replace("    /** the one display we control", helper + "    /** the one display we control", 1)

# 2) pickDisplay: focus wins, then the biggest external, then the phone
old = """        var chosen: Display? = null
        for (d in all) {
            if (d.displayId != Display.DEFAULT_DISPLAY) { chosen = d; break }
        }
"""
new = """        var chosen: Display? = null
        val focusId = focusedDisplayId()
        if (focusId > 0) {
            chosen = all.firstOrNull { it.displayId == focusId }
        }
        if (chosen == null) {
            for (d in all) {
                if (d.displayId != Display.DEFAULT_DISPLAY) { chosen = d; break }
            }
        }
"""
assert old in s, "pickDisplay block not found"
s = s.replace(old, new, 1)

# 3) log the decision
old2 = '        Log.i(TAG, "pick: all=" + all.joinToString { "${it.displayId}/${it.state}" } + " -> " + target.displayId)'
if old2 not in s:
    old2 = '        Log.i(TAG, "pick: all=" + all.joinToString { "${it.displayId}/${it.state}" } + " -> " + (target.displayId))'
new2 = '        Log.i(TAG, "pick: focus=" + focusId + " all=" + all.joinToString { "${it.displayId}/${it.state}" } + " -> target=" + target.displayId)'
assert old2 in s, "pick log not found"
s = s.replace(old2, new2, 1)

io.open(svc, "w", encoding="utf-8", newline="\n").write(s)
print("focus detection patched")
