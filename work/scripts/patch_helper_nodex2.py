import io

p = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(p, encoding="utf-8").read()

old = '''        /* tell the app whether the external screen is real DeX or just a
         * mirror; the app targets the focused phone screen when DeX is off */
        out("DEX %d", dex_display_id());
        out("FOCUS %d", focused_display());
'''
if old in s:
    s = s.replace(old, "", 1)

s = s.replace('''    int last_dex = dex_display_id();
    char last_top[160] = {0};
    int last_focus = focused_display();
    int dex_tick = 0;
''', '''    char last_top[160] = {0};
''', 1)

start = s.find("            if (++dex_tick % 3 == 0) {")
if start > 0:
    end = s.find("\n            }\n", start)
    assert end > start
    s = s[:start] + s[end + len("\n            }\n"):]

start = s.find("        case 'A': {")
if start > 0:
    end = s.find("        case 'K': {", start)
    assert end > start
    s = s[:start] + s[end:]

start = s.find("/* arrange the focused window")
if start > 0:
    end = s.find("\n}\n", start) + 3
    s = s[:start] + s[end:]

io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("helper patched; dex refs left:", s.count('dex_display_id') + s.count('focused_display') + s.count('cmd_arrange'))
