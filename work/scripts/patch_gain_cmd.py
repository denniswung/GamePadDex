import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

# 增益可调（调试/标定用）
if "g_center_gain" not in s:
    s = s.replace("static int g_abs_ptr = -1;",
                  "static int g_abs_ptr = -1;\n/* 居中用的 raw->px 增益（可被命令 G 修改，用于标定） */\nstatic double g_center_gain = 2.16;", 1)

s = s.replace("""    cmd_mouse_move(-30000.0, -30000.0);
    usleep(15 * 1000);
    cmd_mouse_move(tx / 2.16, ty / 2.16);
    out("CENTER(clamp+gain 2.16) -> %d,%d", tx, ty);""",
"""    cmd_mouse_move(-30000.0, -30000.0);
    usleep(15 * 1000);
    cmd_mouse_move((double)tx / g_center_gain, (double)ty / g_center_gain);
    out("CENTER(clamp+gain %.2f) rot=%d -> %d,%d", g_center_gain, rot, tx, ty);""", 1)

# 新命令：G <gain>
if "case 'G': {\n            double g;" not in s:
    anchor = "        case 'P': {"
    add = """        case 'G': {
            /* 标定：设置居中增益（raw -> px） */
            double g = 0;
            if (sscanf(line, "%lf", &g) == 1 && g > 0.2 && g < 20.0) {
                g_center_gain = g;
                out("GAIN %.2f", g_center_gain);
            }
            break;
        }
"""
    idx = s.index(anchor)
    s = s[:idx] + add + s[idx:]

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
