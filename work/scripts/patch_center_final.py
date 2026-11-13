import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

start = s.index("/* 居中：优先用绝对指针")
end = s.index("static void cmd_wheel(", start)
new = '''/* 居中：夹角 + 2.16 增益（相对于系统真实分辨率，配合 wm size 未被强制时准确） */
static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2316;
    if (maxY <= 0) maxY = 904;
    int tx = maxX / 2, ty = maxY / 2;
    /* 指针可能正被「空闲隐藏」销毁了：先恢复设备，否则 L3 完全没反应 */
    if (g_mouse < 0) {
        g_mouse = make_mouse();
        usleep(120 * 1000);
        out("POINTER on (center)");
    }
    cmd_mouse_move(-30000.0, -30000.0);
    usleep(15 * 1000);
    cmd_mouse_move(tx / 2.16, ty / 2.16);
    out("CENTER(clamp+gain 2.16) -> %d,%d", tx, ty);
}

'''
s = s[:start] + new + s[end:]
# 移除绝对设备的创建（保留函数但不实例化，避免它抢指针）
s = s.replace("    g_abs_ptr = make_abs_pointer();\n", "", 1)
s = s.replace("            if (g_abs_ptr < 0) g_abs_ptr = make_abs_pointer();\n", "", 1)
s = s.replace("""            if (g_abs_ptr >= 0) {
                ioctl(g_abs_ptr, UI_DEV_DESTROY);
                close(g_abs_ptr);
                g_abs_ptr = -1;
            }
""", "", 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
