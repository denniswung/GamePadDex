import io
root = r"E:\Dennis\GamePadDex复刻\project"
cp = root + r"\app\src\main\assets\gpminput.c"
c = io.open(cp, encoding="utf-8").read()
c = c.replace('if (strstr(line, "Sprite")) near_sprite = 1;',
              'if (strstr(line, "LayerFE ([BBQ] Sprite")) near_sprite = 1;', 1)
io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
print("parser anchored on the LayerFE sprite line")