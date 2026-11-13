import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

# 1) 不再创建绝对指针设备（它抢走了 hover/光标，导致居中失效且应用收不到指针事件）
s = s.replace("    g_abs_ptr = make_abs_pointer();\n", "", 1)
s = s.replace("            if (g_abs_ptr < 0) g_abs_ptr = make_abs_pointer();\n", "", 1)
s = s.replace("""            if (g_abs_ptr >= 0) {
                ioctl(g_abs_ptr, UI_DEV_DESTROY);
                close(g_abs_ptr);
                g_abs_ptr = -1;
            }
""", "", 1)

# 2) 居中改回相对鼠标：先夹到左上角，再一次性跳到中心；两次事件紧挨着（不 sleep），
#    视觉上只是一帧，没有"跳"的过程。
start = s.index("static void cmd_center(int maxX, int maxY, int park, int rot) {")
end = s.index("static void cmd_wheel(", start)
new = '''static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    int tx = maxX / 2, ty = maxY / 2;
    /* 指针可能正被「空闲隐藏」销毁了：先恢复设备，否则按键毫无反应 */
    if (g_mouse < 0) {
        g_mouse = make_mouse();
        usleep(120 * 1000);
        out("POINTER on (center)");
    }
    /* 相对鼠标没有绝对坐标，所以先用一个超大负位移把指针夹到 (0,0)，
     * 再按实测增益一步走到中心。两条事件之间不 sleep，避免用户看到"先回角再跳"。 */
    cmd_mouse_move(-30000.0, -30000.0);
    cmd_mouse_move(tx / 2.16, ty / 2.16);
    out("CENTER(clamp+gain 2.16) -> %d,%d", tx, ty);
}

'''
s = s[:start] + new + s[end:]
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
