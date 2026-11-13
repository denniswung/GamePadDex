import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\assets\gpminput.c"
s = io.open(p, encoding="utf-8").read()
old = """                    out("AX %d %d %.4f", g_devs[i].id, axis_to_android(&g_devs[i], ev->code),"""
assert old in s, "AX out not found"
new = """                    if (ev->code == 3 || ev->code == 4 || ev->code == 2 || ev->code == 5) {
                        out("AXMAP raw=%d android=%d rx=%d ry=%d name=%s",
                            ev->code, axis_to_android(&g_devs[i], ev->code),
                            g_devs[i].has_abs[3] ? 1 : 0, g_devs[i].has_abs[4] ? 1 : 0,
                            g_devs[i].name);
                    }
                    out("AX %d %d %.4f", g_devs[i].id, axis_to_android(&g_devs[i], ev->code),"""
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("AXMAP diagnostics added")