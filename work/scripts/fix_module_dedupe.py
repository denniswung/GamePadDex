import io
p = r"E:\Dennis\GamePadDex复刻\project\ksu-module\service.sh"
s = io.open(p, encoding="utf-8").read()
if "killall gpminput" not in s:
    s = s.replace("mkdir -p /data/adb/gpm", """# only one helper may run: a stale one would hold the grab and confuse the app
killall gpminput 2>/dev/null
pkill -f ScrollInject 2>/dev/null
sleep 1
mkdir -p /data/adb/gpm""", 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("service.sh dedupes the helper")