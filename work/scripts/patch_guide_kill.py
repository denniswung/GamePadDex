import io, sys
P = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/Prefs.kt"
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"

p = io.open(P, encoding="utf-8").read()
old = '            "guide" -> Action.NONE'
if old not in p:
    print("MISS guide"); sys.exit(1)
p = p.replace(old, '            "guide" -> Action.FORCE_STOP   // Xbox 键 = 杀掉前台应用', 1)
io.open(P, "w", encoding="utf-8", newline="\n").write(p)
print("prefs ok")

s = io.open(H, encoding="utf-8").read()
# cmd_close_app：包名解析失败/被 whitelist 跳过时，也尝试直接用缓存的 top 包名
old2 = '''    if (strstr(pkg, "com.dennis.dexpad") || strstr(pkg, "launcher") ||
        strstr(pkg, "systemui") || strstr(pkg, "sec.android.app.launcher")) {
        out("CLOSE_APP skip %s", pkg);
        return;
    }'''
new2 = '''    if (strstr(pkg, "com.dennis.dexpad") || strstr(pkg, "launcher") ||
        strstr(pkg, "systemui") || strstr(pkg, "sec.android.app.launcher")) {
        out("CLOSE_APP skip %s", pkg);
        return;
    }
    /* 真正杀：am force-stop + 直接 SIGKILL 兜底（保证"确实死了"） */
    {
        int n = kill_pkg_procs(pkg);
        out("CLOSE_APP sigkill %s n=%d", pkg, n);
    }'''
if old2 in s:
    s = s.replace(old2, new2, 1)
    io.open(H, "w", encoding="utf-8", newline="\n").write(s)
    print("helper close_app ok")
else:
    print("helper close_app MISS")
