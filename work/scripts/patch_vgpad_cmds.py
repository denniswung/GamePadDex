import io
v = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/vgpad.c"
s = io.open(v, encoding="utf-8").read()
anchor = '    } else if (!strcmp(argv[1], "seq")) {'
if "holdstick" in s:
    print("already"); raise SystemExit(0)
add = r'''    } else if (!strcmp(argv[1], "holdstick")) {
        // holdstick <keycode> <axis> <value> <holdMs> [pre]
        int code = atoi(argv[2]), axis = atoi(argv[3]), val = atoi(argv[4]);
        int ms = argc > 5 ? atoi(argv[5]) : 2000;
        int pre = argc > 6 ? atoi(argv[6]) : 0;
        if (pre > 0) sleep_ms(pre);
        emit(EV_KEY, code, 1); syn();
        sleep_ms(150);
        emit(EV_ABS, axis, val); syn();
        sleep_ms(ms);
        emit(EV_ABS, axis, 0); syn();
        sleep_ms(80);
        emit(EV_KEY, code, 0); syn();
    } else if (!strcmp(argv[1], "hatkey")) {
        // hatkey <hatValue> <keycode> [pre]
        int hat = atoi(argv[2]), code = atoi(argv[3]);
        int pre = argc > 4 ? atoi(argv[4]) : 0;
        if (pre > 0) sleep_ms(pre);
        emit(EV_ABS, 16, hat); syn();
        sleep_ms(80);
        emit(EV_KEY, code, 1); syn();
        sleep_ms(80);
        emit(EV_KEY, code, 0); syn();
        emit(EV_ABS, 16, 0); syn();
    } else if (!strcmp(argv[1], "dblstick")) {
        // dblstick <keycode> <gapMs> <axis> <value> [pre]
        int code = atoi(argv[2]), gap = atoi(argv[3]);
        int axis = atoi(argv[4]), val = atoi(argv[5]);
        int pre = argc > 6 ? atoi(argv[6]) : 0;
        if (pre > 0) sleep_ms(pre);
        emit(EV_KEY, code, 1); syn(); sleep_ms(40);
        emit(EV_KEY, code, 0); syn(); sleep_ms(gap);
        emit(EV_KEY, code, 1); syn(); sleep_ms(40);
        emit(EV_KEY, code, 0); syn();
        sleep_ms(60);
        emit(EV_ABS, axis, val); syn();
        sleep_ms(300);
        emit(EV_ABS, axis, 0); syn();
    } else if (!strcmp(argv[1], "r3rstick")) {
        // r3rstick <axis> <value> [pre]: one R3 press, then move the right stick
        int axis = atoi(argv[2]), val = atoi(argv[3]);
        int pre = argc > 4 ? atoi(argv[4]) : 0;
        if (pre > 0) sleep_ms(pre);
        emit(EV_KEY, 318, 1); syn(); sleep_ms(40);
        emit(EV_KEY, 318, 0); syn();
        sleep_ms(50);
        emit(EV_ABS, axis, val); syn();
        sleep_ms(250);
        emit(EV_ABS, axis, 0); syn();
'''
if anchor not in s:
    print("MISS anchor"); raise SystemExit(1)
s = s.replace(anchor, add + anchor, 1)
io.open(v, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
