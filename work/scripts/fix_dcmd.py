import io
root = r"E:\Dennis\GamePadDex复刻\project"
cp = root + r"\app\src\main\assets\gpminput.c"
c = io.open(cp, encoding="utf-8").read()
c = c.replace("""        case 'K': {
            int kd = 0, kc = 0;
            if (sscanf(line, "%d %d", &kd, &kc) == 2) injector_key(kd, kc);
            break;
        }
""", """        case 'D': {
            int kd, kc;
            if (sscanf(line, "%d %d", &kd, &kc) == 2) injector_key(kd, kc);
            break;
        }
""", 1)
io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
rp = root + r"\app\src\main\java\com\dennis\gamepadmouse\RootInput.kt"
r = io.open(rp, encoding="utf-8").read()
r = r.replace('send("K $displayId $keyCode")', 'send("D $displayId $keyCode")', 1)
io.open(rp, "w", encoding="utf-8", newline="\n").write(r)
print("D command fixed")