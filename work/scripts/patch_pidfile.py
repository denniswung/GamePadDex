import io
p = r"E:\Dennis\GamePadDex复刻\project\ksu-module\service.sh"
s = io.open(p, encoding="utf-8").read()
if "helper.pid" not in s:
    s = s.replace("""# only one helper may run: a stale one would hold the grab and confuse the app
killall gpminput 2>/dev/null""",
"""# only one supervisor may run (a second one would spawn a second helper and the
# two would fight over the same EVIOCGRAB, making button input land nowhere)
PIDFILE=/data/adb/gpm/service.pid
if [ -f "$PIDFILE" ]; then
    OLD=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$OLD" ] && kill -0 "$OLD" 2>/dev/null; then
        exit 0
    fi
fi
echo $$ > "$PIDFILE"
# only one helper may run: a stale one would hold the grab and confuse the app
killall gpminput 2>/dev/null""", 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("pidfile guard added")