import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"

h = io.open(H, encoding="utf-8").read()
old = """static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    int tx = maxX / 2, ty = maxY / 2;"""
new = """static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    int tx = maxX / 2, ty = maxY / 2;
    /* 指针可能正被「空闲隐藏」销毁了：居中前先确保设备存在，
     * 否则按键没反应（光标既不出现也不居中） */
    if (g_mouse < 0) {
        g_mouse = make_mouse();
        usleep(120 * 1000);
        out("POINTER on (center)");
    }
    if (g_abs_ptr < 0) g_abs_ptr = make_abs_pointer();"""
if old not in h:
    print("MISS center"); sys.exit(1)
h = h.replace(old, new, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(h)
print("helper ok")

e = io.open(E, encoding="utf-8").read()
if "Action.CENTER_CURSOR ->" in e and "showPointer()" not in e.split("Action.CENTER_CURSOR ->")[1][:200]:
    # 在居中动作前恢复指针
    idx = e.index("Action.CENTER_CURSOR ->")
    e = e[:idx] + "Action.CENTER_CURSOR -> {\n                showPointer()\n                " + e[idx + len("Action.CENTER_CURSOR ->"):]
    io.open(E, "w", encoding="utf-8", newline="\n").write(e)
    print("engine patched")
else:
    print("engine shape differs")
