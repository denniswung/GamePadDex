import io
p = r"E:\Dennis\GamePadDex复刻\project\lsp-dexfullscreen\app\src\main\java\com\dennis\dexfs\Hook.java"
s = io.open(p, encoding="utf-8").read()
old = """        if (done) return;
        if (!"android".equals(lp.packageName)) return;"""
assert old in s, "guard not found"
new = """        if (done) return;
        // WM Shell (windowdecor / desktopmode) lives inside SystemUI on Android 12+
        String pkg = lp.packageName;
        if (!"android".equals(pkg) && !"com.android.systemui".equals(pkg)) return;"""
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("hook now also loads in com.android.systemui")