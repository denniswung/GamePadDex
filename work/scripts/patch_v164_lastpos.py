import io

H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
R = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt"
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
fails = []


def patch(path, pairs, name):
    global fails
    s = io.open(path, encoding="utf-8").read()
    for old, new, tag in pairs:
        if old not in s:
            fails.append(f"{name}:{tag}")
            continue
        s = s.replace(old, new, 1)
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)


# ---------------- helper：任意坐标绝对定位（有界到左上角 + 一次增益移动） ----------------
patch(H, [(
    '''static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    double gain = g_center_gain > 0.2 ? g_center_gain : 2.16;
    int tx = maxX / 2, ty = maxY / 2;
    if (g_mouse < 0) {
        g_mouse = make_mouse();
        usleep(120 * 1000);
        out("POINTER on (center)");
    }
    /* 1) 有界步进到左上角：总量约 1.2 屏，分成 40 步，每步很小 */
    double totalX = -(double)maxX * 1.2 / gain;
    double totalY = -(double)maxY * 1.2 / gain;
    const int STEPS = 40;
    for (int i = 0; i < STEPS; i++) {
        cmd_mouse_move(totalX / STEPS, totalY / STEPS);
        usleep(6 * 1000);
    }
    usleep(40 * 1000);
    /* 2) 从(0,0)一步到中心 */
    cmd_mouse_move((double)tx / gain, (double)ty / gain);
    out("CENTER(steps+gain %.2f) rot=%d -> %d,%d", gain, rot, tx, ty);
}''',
    '''/* 把指针放到屏幕上的任意绝对坐标：先有界步进到左上角(0,0)，再按增益一步到 (tx,ty)。
 * 因为「到左上角」是有界且会撞到屏幕边缘的，所以不管指针当前在哪都能对齐到 (0,0)，
 * 这样重建鼠标设备后也能精确地把光标放回"上次的位置"。 */
static void pointer_goto(int tx, int ty, int maxX, int maxY) {
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    if (tx < 0) tx = 0;
    if (ty < 0) ty = 0;
    if (tx > maxX) tx = maxX;
    if (ty > maxY) ty = maxY;
    double gain = g_center_gain > 0.2 ? g_center_gain : 2.16;
    if (g_mouse < 0) {
        g_mouse = make_mouse();
        usleep(120 * 1000);
        out("POINTER on (goto)");
    }
    double totalX = -(double)maxX * 1.2 / gain;
    double totalY = -(double)maxY * 1.2 / gain;
    const int STEPS = 40;
    for (int i = 0; i < STEPS; i++) {
        cmd_mouse_move(totalX / STEPS, totalY / STEPS);
        usleep(6 * 1000);
    }
    usleep(40 * 1000);
    cmd_mouse_move((double)tx / gain, (double)ty / gain);
}

static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    double gain = g_center_gain > 0.2 ? g_center_gain : 2.16;
    pointer_goto(maxX / 2, maxY / 2, maxX, maxY);
    out("CENTER(steps+gain %.2f) rot=%d -> %d,%d", gain, rot, maxX / 2, maxY / 2);
}''', "pointer_goto")], "helper")

# 新增 P 命令
patch(H, [(
    """        case 'T': {""",
    """        case 'P': {
            /* P <x> <y> <maxX> <maxY> : 把光标放到绝对坐标（用于空闲隐藏后恢复上次位置） */
            int px = 0, py = 0, pw = 0, ph = 0;
            int n = sscanf(line, "%d %d %d %d", &px, &py, &pw, &ph);
            if (n >= 2) {
                if (pw <= 0) pw = 2560;
                if (ph <= 0) ph = 1600;
                pointer_goto(px, py, pw, ph);
                out("POSPTR %d,%d", px, py);
            }
            break;
        }
        case 'T': {""", "case-P")], "helper")

# ---------------- RootInput：positionPointer ----------------
patch(R, [(
    """    fun pointKey(displayId: Int, keyCode: Int) = send("D $displayId $keyCode")""",
    """    fun pointKey(displayId: Int, keyCode: Int) = send("D $displayId $keyCode")

    /** 把光标放到绝对坐标（助手内部：有界到左上角再一步到位） */
    fun positionPointer(x: Int, y: Int, w: Int, h: Int) = send("P $x $y $w $h")""", "positionPointer")], "rootInput")

# ---------------- Engine：恢复上次位置而不是回中心 ----------------
patch(E, [(
    '''        val display = activeDisplay()
        val (vw, vh) = displaySize(display)
        val rot = displayState.rotation(display)
        root.centerCursor(vw, vh, onPhone(), rot, prefs.centerGain)
        ptrX = vw / 2f
        ptrY = vh / 2f
        centerLock = true
        centerLockUntil = SystemClock.elapsedRealtime() + 300
        Log.i(TAG, "pointer shown + re-centred ${vw}x$vh (rot $rot)")''',
    '''        val display = activeDisplay()
        val (vw, vh) = displaySize(display)
        // 恢复到"上次的位置"：重建设备后指针真实位置未知，但助手可以先把光标
        // 有界推到左上角(0,0)，再按增益一步放到 (ptrX, ptrY) —— 绝对定位。
        val tx = (if (ptrX.isNaN()) vw / 2f else ptrX).coerceIn(0f, vw.toFloat())
        val ty = (if (ptrY.isNaN()) vh / 2f else ptrY).coerceIn(0f, vh.toFloat())
        root.positionPointer(tx.toInt(), ty.toInt(), vw, vh)
        ptrX = tx
        ptrY = ty
        centerLock = true
        centerLockUntil = SystemClock.elapsedRealtime() + 260
        Log.i(TAG, "pointer shown at last position ${tx.toInt()},${ty.toInt()} (${vw}x$vh)")''', "showPointer")], "engine")

patch(E, [(
    '''        runCatching {
            val display = activeDisplay()
            val (vw, vh) = displaySize(display)
            root.centerCursor(vw, vh, onPhone(), displayState.rotation(display), prefs.centerGain)
            ptrX = vw / 2f
            ptrY = vh / 2f
            centerLock = true
            centerLockUntil = SystemClock.elapsedRealtime() + 300
            Log.i(TAG, "helper ready: pointer re-centred ${vw}x$vh")
        }''',
    '''        runCatching {
            val display = activeDisplay()
            val (vw, vh) = displaySize(display)
            val tx = (if (ptrX.isNaN()) vw / 2f else ptrX).coerceIn(0f, vw.toFloat())
            val ty = (if (ptrY.isNaN()) vh / 2f else ptrY).coerceIn(0f, vh.toFloat())
            root.positionPointer(tx.toInt(), ty.toInt(), vw, vh)
            ptrX = tx
            ptrY = ty
            centerLock = true
            centerLockUntil = SystemClock.elapsedRealtime() + 260
            Log.i(TAG, "helper ready: pointer restored at ${tx.toInt()},${ty.toInt()}")
        }''', "onReady")], "engine")

print("FAILS:", fails if fails else "none")
