import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
start = s.index("/* 居中：闭环")
end = s.index("static void cmd_wheel(", start)
new = '''/* 居中：先用一次超大位移把指针顶到左上角，再按实测增益一步走到中心。
 * 这台设备(1600x2560 强制分辨率 + 指针加速)下 raw→px 增益约 2.16。 */
static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
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
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
