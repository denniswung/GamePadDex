import io
root = r"E:\Dennis\GamePadDex复刻\project"
cp = root + r"\app\src\main\assets\gpminput.c"
c = io.open(cp, encoding="utf-8").read()
old = '"export LD_LIBRARY_PATH=/system/lib64:/system_ext/lib64:/product/lib64:/vendor/lib64; "'
assert old in c
new = '"export LD_LIBRARY_PATH=/apex/com.android.art/lib64:/system/lib64:/system_ext/lib64:/product/lib64:/vendor/lib64; "'
c = c.replace(old, new, 1)
io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
print("LD_LIBRARY_PATH now includes the ART apex")

sp = root + r"\ksu-module\service.sh"
s = io.open(sp, encoding="utf-8").read()
s = s.replace("export LD_LIBRARY_PATH=/system/lib64:/system_ext/lib64:/product/lib64:/vendor/lib64",
              "export LD_LIBRARY_PATH=/apex/com.android.art/lib64:/system/lib64:/system_ext/lib64:/product/lib64:/vendor/lib64")
io.open(sp, "w", encoding="utf-8", newline="\n").write(s)
print("service.sh updated")