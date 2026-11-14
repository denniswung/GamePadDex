import io, sys

H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
V = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/vgpad.c"
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


# ---------------- 1) helper：打开应用先解析启动 Activity（-p 形式对部分应用解析失败） ----------------
patch(H, [(
    '''                char cmd4[400];
                snprintf(cmd4, sizeof(cmd4),
                         "/system/bin/am start -a android.intent.action.MAIN "
                         "-c android.intent.category.LAUNCHER -p %s >/dev/null 2>&1", pkg3);
                pid_t ch = fork();
                if (ch == 0) {
                    int rc = system(cmd4);
                    out("OPEN_APP %s rc=%d", pkg3, rc);
                    _exit(0);
                }''',
    '''                pid_t ch = fork();
                if (ch == 0) {
                    /* 先解析出启动 Activity 再 am start -n：
                     * `am start -p <pkg>` 对部分应用会 "unable to resolve Intent"（实测 PiliPlus），
                     * 解析后用组件名启动最可靠。 */
                    char comp[256] = {0};
                    char rcmd[460];
                    snprintf(rcmd, sizeof(rcmd),
                             "/system/bin/cmd package resolve-activity --brief -a android.intent.action.MAIN "
                             "-c android.intent.category.LAUNCHER %s 2>/dev/null | /system/bin/tail -1", pkg3);
                    FILE *pr = popen(rcmd, "r");
                    if (pr) {
                        if (fgets(comp, sizeof(comp), pr)) {
                            char *nl = strpbrk(comp, "\\r\\n");
                            if (nl) *nl = 0;
                        }
                        pclose(pr);
                    }
                    int rc = -1;
                    if (strchr(comp, '/')) {
                        char cmd4[520];
                        snprintf(cmd4, sizeof(cmd4),
                                 "/system/bin/am start -n %s -f 0x10000000 >/dev/null 2>&1", comp);
                        rc = system(cmd4);
                        out("OPEN_APP %s via %s rc=%d", pkg3, comp, rc);
                    } else {
                        char cmd4[420];
                        snprintf(cmd4, sizeof(cmd4),
                                 "/system/bin/am start -a android.intent.action.MAIN "
                                 "-c android.intent.category.LAUNCHER -p %s >/dev/null 2>&1", pkg3);
                        rc = system(cmd4);
                        out("OPEN_APP %s (pkg) rc=%d", pkg3, rc);
                    }
                    if (rc != 0) {
                        /* 最后兜底：monkey 启动（老办法，几乎总能拉起主界面） */
                        char cmd5[320];
                        snprintf(cmd5, sizeof(cmd5),
                                 "/system/bin/monkey -p %s -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1", pkg3);
                        int rc2 = system(cmd5);
                        out("OPEN_APP %s monkey rc=%d", pkg3, rc2);
                    }
                    _exit(0);
                }''', "open-resolve")], "helper")

# ---------------- 2) engine：指针被空闲隐藏后重建时，把光标拉回中心并同步估算 ----------------
patch(E, [(
    '''    private fun showPointer() {
        if (!pointerHidden || !root.helperReady) return
        root.raw("j")
        pointerHidden = false
        Log.i(TAG, "pointer shown (mouse device recreated)")
    }''',
    '''    private fun showPointer() {
        if (!pointerHidden || !root.helperReady) return
        root.raw("j")
        pointerHidden = false
        // 关键：销毁再重建鼠标设备后，系统里光标的真实位置是不可知的（会被重置），
        // 而我们的估算还停在旧位置——位移夹取就会把某些方向锁死（"有些区域过不去"）。
        // 所以重建后直接把光标拉回屏幕中心，并同步估算值。
        val display = activeDisplay()
        val (vw, vh) = displaySize(display)
        val rot = displayState.rotation(display)
        root.centerCursor(vw, vh, onPhone(), rot, prefs.centerGain)
        ptrX = vw / 2f
        ptrY = vh / 2f
        lockCenterFor(300)
        Log.i(TAG, "pointer shown + re-centred ${vw}x$vh (rot $rot)")
    }''', "showPointer")], "engine")

# onReady 里也同步一次（助手重启后设备也是新的）
patch(E, [(
    '''        pointerHidden = false
        touchSizeSent = ""
        root.raw("j")''',
    '''        pointerHidden = false
        touchSizeSent = ""
        root.raw("j")
        runCatching {
            val display = activeDisplay()
            val (vw, vh) = displaySize(display)
            root.centerCursor(vw, vh, onPhone(), displayState.rotation(display), prefs.centerGain)
            ptrX = vw / 2f
            ptrY = vh / 2f
            lockCenterFor(300)
            Log.i(TAG, "helper ready: pointer re-centred ${vw}x$vh")
        }''', "onReady")], "engine")

# ---------------- 3) vgpad：keyvhat（按住某键 + 方向键"上/下"）用于测 Start+上 ----------------
patch(V, [(
    '''    } else if (!strcmp(argv[1], "keyhat")) {''',
    '''    } else if (!strcmp(argv[1], "keyvhat")) {
        // keyvhat <keycode> <hatY> <holdMs> [pre] : 先按键再推竖直方向（HAT0Y）
        int code = atoi(argv[2]), hy = atoi(argv[3]);
        int hold = argc > 4 ? atoi(argv[4]) : 400;
        int pre = argc > 5 ? atoi(argv[5]) : 2600;
        if (pre > 0) sleep_ms(pre);
        emit(EV_KEY, code, 1); syn();
        sleep_ms(90);
        emit(EV_ABS, 17, hy); syn();
        sleep_ms(hold);
        emit(EV_ABS, 17, 0); syn();
        sleep_ms(60);
        emit(EV_KEY, code, 0); syn();
    } else if (!strcmp(argv[1], "keyhat")) {''', "keyvhat")], "vgpad")

print("FAILS:", fails if fails else "none")
