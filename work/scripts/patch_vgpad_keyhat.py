import io
V = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/vgpad.c"
s = io.open(V, encoding="utf-8").read()
anchor = '    } else if (!strcmp(argv[1], "hatkey")) {'
if anchor not in s:
    print("MISS"); raise SystemExit(1)
add = '''    } else if (!strcmp(argv[1], "keyhat")) {
        // keyhat <keycode> <hatY> <holdMs> [pre] : 先按键再推方向（测 X+↑ 这类组合）
        int code = atoi(argv[2]), hat = atoi(argv[3]);
        int hold = argc > 4 ? atoi(argv[4]) : 200;
        int pre = argc > 5 ? atoi(argv[5]) : 0;
        if (pre > 0) sleep_ms(pre);
        emit(EV_KEY, code, 1); syn();
        sleep_ms(90);
        emit(EV_ABS, 16, hat); syn();
        sleep_ms(hold);
        emit(EV_ABS, 16, 0); syn();
        sleep_ms(60);
        emit(EV_KEY, code, 0); syn();
'''
s = s.replace(anchor, add + anchor, 1)
io.open(V, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
