import io
p = r"E:\Dennis\GamePadDex复刻\work\scripts\vgpad.c"
s = io.open(p, encoding="utf-8").read()
old = '''        int hold = argc > 4 ? atoi(argv[4]) : 600;
        emit(EV_KEY, k1, 1); syn();'''
new = '''        int hold = argc > 4 ? atoi(argv[4]) : 600;
        int pre = argc > 5 ? atoi(argv[5]) : 2600;
        if (pre > 0) sleep_ms(pre);   /* let the helper discover the device */
        emit(EV_KEY, k1, 1); syn();'''
assert old in s
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("vgpad combo delay added")