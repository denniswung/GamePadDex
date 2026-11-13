import io
h = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(h, encoding="utf-8").read()
s = s.replace('snprintf(kc, sizeof(kc), "/system/bin/sh -c \\"for p in $(/system/bin/pidof %s); do /system/bin/kill -9 $p; done\\"", pkg);',
              'snprintf(kc, sizeof(kc), "/system/bin/sh -c \\"PATH=/system/bin pkill -9 %s\\"", pkg);')
io.open(h, "w", encoding="utf-8", newline="\n").write(s)

v = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/vgpad.c"
z = io.open(v, encoding="utf-8").read()
if "r3rstick" not in z:
    anchor = '    } else if (!strcmp(argv[1], "holdstick")) {'
    add = '''    } else if (!strcmp(argv[1], "r3rstick")) {
        // r3rstick <axis> <value> <pre>: one R3 press, then move the right stick at once
        int axis = atoi(argv[2]);
        int val = atoi(argv[3]);
        int pre = argc > 4 ? atoi(argv[4]) : 0;
        if (pre > 0) sleep_ms(pre);
        emit(EV_KEY, 318, 1); syn(); sleep_ms(40);
        emit(EV_KEY, 318, 0); syn();
        sleep_ms(50);
        emit(EV_ABS, axis, val); syn();
        sleep_ms(250);
        emit(EV_ABS, axis, 0); syn();
'''
    if anchor not in z:
        print("MISS vgpad"); raise SystemExit(1)
    z = z.replace(anchor, add + anchor, 1)
    io.open(v, "w", encoding="utf-8", newline="\n").write(z)
print("ok")
