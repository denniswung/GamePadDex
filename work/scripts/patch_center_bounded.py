import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
old = """    cmd_mouse_move(-30000.0, -30000.0);
    usleep(15 * 1000);
    cmd_mouse_move(tx / 2.16, ty / 2.16);"""
new = """    /* 有界的夹角：只走 1.5 屏，避免超大位移触发指针加速把光标甩到屏幕外
     * （实测 -30000 那条会让光标彻底消失，后续再动也回不来）。 */
    cmd_mouse_move(-(double)maxX * 1.5, -(double)maxY * 1.5);
    usleep(15 * 1000);
    cmd_mouse_move(tx / 2.16, ty / 2.16);"""
if old not in s:
    print("MISS"); sys.exit(1)
s = s.replace(old, new, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
