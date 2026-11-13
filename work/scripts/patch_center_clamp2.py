import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
start = s.index("/* 一次性居中：读真实指针位置")
end = s.index("static void cmd_wheel(", start)
new = '''/* 居中：夹角 + 实测增益，两条 REL 事件连续发出（不 sleep，视觉上是一帧） */
static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    /* 应用传进来的是旋转后的窗口尺寸；read_pointer/REL 都是"未旋转"坐标系，
     * 所以横屏时把宽高换回来再取中心。 */
    int bw = maxX, bh = maxY;
    if (rot == 1 || rot == 3) { bw = maxY; bh = maxX; }
    int tx = bw / 2, ty = bh / 2;
    if (g_mouse < 0) {
        g_mouse = make_mouse();
        usleep(120 * 1000);
        out("POINTER on (center)");
    }
    cmd_mouse_move(-30000.0, -30000.0);
    usleep(15 * 1000);
    cmd_mouse_move(tx / 2.16, ty / 2.16);
    out("CENTER(clamp+gain 2.16) rot=%d -> %d,%d", rot, tx, ty);
}

'''
s = s[:start] + new + s[end:]
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
