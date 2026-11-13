import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

start = s.index("/* 居中：夹角 + 实测增益")
end = s.index("static void cmd_wheel(", start)
new = '''/* 居中：优先用绝对指针（一条 EV_ABS 到位，不受加速/增益影响）；
 * 绝对设备不可用时退回"有界夹角 + 2.16 增益"。 */
static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    int tx = maxX / 2, ty = maxY / 2;

    /* 指针可能正被「空闲隐藏」销毁了：居中前必须把设备重建，
     * 否则 L3 完全没反应（这正是上一版"光标没法居中"的原因）。 */
    if (g_mouse < 0) {
        g_mouse = make_mouse();
        usleep(120 * 1000);
        out("POINTER on (center)");
    }
    if (g_abs_ptr < 0) g_abs_ptr = make_abs_pointer();

    if (g_abs_ptr >= 0) {
        int ax = (int)((long)tx * 32767 / (maxX > 0 ? maxX : 1));
        int ay = (int)((long)ty * 32767 / (maxY > 0 ? maxY : 1));
        ev_emit(g_abs_ptr, EV_ABS, ABS_X, ax);
        ev_emit(g_abs_ptr, EV_ABS, ABS_Y, ay);
        ev_syn(g_abs_ptr);
        out("CENTER(abs %d,%d) -> %d,%d", ax, ay, tx, ty);
        return;
    }
    cmd_mouse_move(-(double)maxX * 1.5, -(double)maxY * 1.5);
    usleep(15 * 1000);
    cmd_mouse_move(tx / 2.16, ty / 2.16);
    out("CENTER(clamp+gain 2.16 fallback) -> %d,%d", tx, ty);
}

'''
s = s[:start] + new + s[end:]

# 启动时创建 + j 恢复时重建
if "g_abs_ptr = make_abs_pointer();\n    /* 手柄" not in s and "    g_pad = make_gamepad();\n    g_abs_ptr" not in s:
    s = s.replace("    g_pad = make_gamepad();", "    g_pad = make_gamepad();\n    g_abs_ptr = make_abs_pointer();", 1)
s = s.replace("""            if (g_mouse < 0) {
                g_mouse = make_mouse();
                usleep(120 * 1000);
                out("POINTER on");
            }""",
"""            if (g_mouse < 0) {
                g_mouse = make_mouse();
                usleep(120 * 1000);
                out("POINTER on");
            }
            if (g_abs_ptr < 0) g_abs_ptr = make_abs_pointer();""", 1)
s = s.replace("""            if (g_mouse >= 0) {
                ioctl(g_mouse, UI_DEV_DESTROY);
                close(g_mouse);
                g_mouse = -1;
                out("POINTER off");
            }""",
"""            if (g_mouse >= 0) {
                ioctl(g_mouse, UI_DEV_DESTROY);
                close(g_mouse);
                g_mouse = -1;
                out("POINTER off");
            }
            if (g_abs_ptr >= 0) {
                ioctl(g_abs_ptr, UI_DEV_DESTROY);
                close(g_abs_ptr);
                g_abs_ptr = -1;
            }""", 1)

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
