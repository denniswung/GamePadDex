import io
p = '/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c'
s = io.open(p, encoding='utf-8').read()
old = "        case 'G': {\n            /* 标定：设置居中增益（raw -> px） */"
new = "        case 'g': {\n            /* 标定：设置居中增益（raw -> px） */"
if old not in s:
    print("MISS"); raise SystemExit(1)
s = s.replace(old, new, 1)
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("renamed")
