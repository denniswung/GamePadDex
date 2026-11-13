import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
old = """    /* 应用传进来的是旋转后的窗口尺寸；read_pointer/REL 都是"未旋转"坐标系，
     * 所以横屏时把宽高换回来再取中心。 */
    int bw = maxX, bh = maxY;
    if (rot == 1 || rot == 3) { bw = maxY; bh = maxX; }
    int tx = bw / 2, ty = bh / 2;"""
new = """    /* REL 位移作用在"窗口坐标系"，应用传进来的 maxX/maxY 就是窗口尺寸，
     * 所以直接取 midway（不要再按 rot 交换，那会把落点推到非中心）。 */
    int tx = maxX / 2, ty = maxY / 2;"""
if old not in s:
    print("MISS"); sys.exit(1)
s = s.replace(old, new, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
