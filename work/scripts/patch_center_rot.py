import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
old = """    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    int tx = maxX / 2, ty = maxY / 2;
    if (g_mouse < 0) {"""
new = """    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    /* read_pointer() 给的是"未旋转"坐标系（例如 1600x2560），
     * 而应用传进来的是旋转后的窗口尺寸（例如 2560x1600）：横屏时把宽高换回来。 */
    int bw = maxX, bh = maxY;
    if (rot == 1 || rot == 3) { bw = maxY; bh = maxX; }
    int tx = bw / 2, ty = bh / 2;
    if (g_mouse < 0) {"""
if old not in s:
    print("MISS"); sys.exit(1)
s = s.replace(old, new, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
