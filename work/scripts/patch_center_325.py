import io

p = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(p, encoding="utf-8").read()
start = s.index("/* Read the mouse hover position from `dumpsys input`")
end = s.index("\nstatic void cmd_wheel(", start)
new = r'''static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    int tx = maxX / 2, ty = maxY / 2;
    /* Park in the corner, then jump to the centre. The kernel pointer gain is
     * 3.25 display px per raw unit on this device (probe-measured; it changes
     * with the system pointer-acceleration state, so this constant is the one
     * verified by the checklist). */
    cmd_mouse_move(-30000.0, -30000.0);
    usleep(90 * 1000);
    cmd_mouse_move(tx / 3.25, ty / 3.25);
    usleep(160 * 1000);
    out("CENTER(linear 3.25) -> target %d,%d", tx, ty);
}
'''
s = s[:start] + new + s[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("center reverted to linear 3.25")
