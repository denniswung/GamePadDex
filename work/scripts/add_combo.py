import io
p = r"E:\Dennis\GamePadDex复刻\work\scripts\vgpad.c"
s = io.open(p, encoding="utf-8").read()
if '"combo"' not in s:
    add = '''    } else if (!strcmp(argv[1], "combo")) {
        // vgpad combo <k1> <k2> <holdMs>
        int k1 = atoi(argv[2]);
        int k2 = atoi(argv[3]);
        int hold = argc > 4 ? atoi(argv[4]) : 600;
        emit(EV_KEY, k1, 1); syn();
        sleep_ms(300);
        emit(EV_KEY, k2, 1); syn();
        sleep_ms(hold);
        emit(EV_KEY, k2, 0); syn();
        sleep_ms(50);
        emit(EV_KEY, k1, 0); syn();
'''
    s = s.replace('    } else if (!strcmp(argv[1], "seq")) {', add + '    } else if (!strcmp(argv[1], "seq")) {', 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("vgpad combo mode added")