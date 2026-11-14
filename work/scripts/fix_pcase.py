import io
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
fails = []

# 删掉我插入的重复 case 'P'
dup = """        case 'P': {
            /* P <x> <y> <maxX> <maxY> : 把光标放到绝对坐标（用于空闲隐藏后恢复上次位置） */
            int px = 0, py = 0, pw = 0, ph = 0;
            int n = sscanf(line, "%d %d %d %d", &px, &py, &pw, &ph);
            if (n >= 2) {
                if (pw <= 0) pw = 2560;
                if (ph <= 0) ph = 1600;
                pointer_goto(px, py, pw, ph);
                out("POSPTR %d,%d", px, py);
            }
            break;
        }
"""
if dup not in s:
    fails.append("remove-dup")
else:
    s = s.replace(dup, "", 1)

# 复用原来的死命令 'P'（injector_scroll 已经不会被执行）作为"绝对定位光标"
old = """        case 'P': {
            float px, py, pdy, pdx;
            int pdisp = 0;
            int pn = sscanf(line, "%f %f %f %f %d", &px, &py, &pdy, &pdx, &pdisp);
            if (pn >= 3) injector_scroll(px, py, pdy, pdx, pn >= 5 ? pdisp : 0);
            break;
        }"""
new = """        case 'P': {
            /* P <x> <y> <maxX> <maxY> : 把光标放到绝对坐标
             * （空闲隐藏会销毁鼠标设备，重建后用这条把光标放回"上次的位置"） */
            int px = 0, py = 0, pw = 0, ph = 0;
            int pn = sscanf(line, "%d %d %d %d", &px, &py, &pw, &ph);
            if (pn >= 2) {
                if (pw <= 0) pw = 2560;
                if (ph <= 0) ph = 1600;
                pointer_goto(px, py, pw, ph);
                out("POSPTR %d,%d", px, py);
            }
            break;
        }"""
if old not in s:
    fails.append("rewrite-P")
else:
    s = s.replace(old, new, 1)

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("FAILS:", fails if fails else "none")
