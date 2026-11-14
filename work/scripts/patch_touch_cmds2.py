import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
if "TOUCH_SIZE" in s:
    print("already inserted")
    sys.exit(0)
anchor = "        case 'g': {"
if anchor not in s:
    print("MISS anchor"); sys.exit(1)
cmds = """        case 'q': {
            /* q <w> <h> : 触摸面尺寸（像素 -> 触摸坐标） */
            int tw = 0, th = 0;
            if (sscanf(line, "%d %d", &tw, &th) == 2 && tw > 0 && th > 0) {
                g_touch_w = tw;
                g_touch_h = th;
                out("TOUCH_SIZE %d %d", g_touch_w, g_touch_h);
            }
            break;
        }
        case 'k': {
            /* k <x> <y> <down> : 单指触摸（点击 / 长按） */
            int tx = 0, ty = 0, dn = 0;
            if (sscanf(line, "%d %d %d", &tx, &ty, &dn) == 3) touch_single(tx, ty, dn);
            break;
        }
        case 'l': {
            /* l <dir> <x> <y> : 双指缩放，dir 0=停止 1=放大 -1=缩小 */
            int dir = 0, px = 0, py = 0;
            if (sscanf(line, "%d %d %d", &dir, &px, &py) == 3) {
                if (dir == 0) pinch_stop();
                else pinch_start(dir, px, py);
            }
            break;
        }
"""
s = s.replace(anchor, cmds + anchor, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("inserted q/k/l")
