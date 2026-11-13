import io, os
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\MainActivity.kt"
s = io.open(p, encoding="utf-8").read()
s = s.replace('actionLabelOf(prefs.getString(Prefs.btnType(name), "default"))',
              'actionLabel(prefs.getString(Prefs.btnType(name), "default") ?: "default")', 1)
old = """        val current = (prefs.getString(Prefs.comboKeys(i), "") ?: "").split("+")
            .mapNotNull { k -> names.indexOfFirst { it == k.trim() }.takeIf { it >= 0 } }
            .toBooleanArray()
        val checked = BooleanArray(names.size) { current.getOrElse(it) { false } }"""
new = """        val existing = (prefs.getString(Prefs.comboKeys(i), "") ?: "").split("+")
        val checked = BooleanArray(names.size)
        for (idx in names.indices) {
            for (k in existing) {
                if (k.trim() == names[idx]) checked[idx] = true
            }
        }"""
assert old in s, "combo picker block not found"
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("fixed")