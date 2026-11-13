import io
p = r"E:\Dennis\GamePadDex复刻\project\ksu-module\service.sh"
s = io.open(p, encoding="utf-8").read()
if "pgrep -f" not in s:
    s = s.replace('PIDFILE=/data/adb/gpm/service.pid',
'''# a second supervisor is useless: it would only spawn helpers that exit on the lock
RUNNING=$(pgrep -f 'gpm_dex/service.sh' | grep -v "^$$$" | wc -l)
if [ "$RUNNING" -gt 0 ]; then
    exit 0
fi
PIDFILE=/data/adb/gpm/service.pid''', 1)
    s = s.replace("""    /data/adb/gpm/gpminput --socket "$SOCK" >>/data/local/tmp/gpm-module.log 2>&1
    echo "helper exited, restarting" >>/data/local/tmp/gpm-module.log
    sleep 2""",
"""    /data/adb/gpm/gpminput --socket "$SOCK" >>/data/local/tmp/gpm-module.log 2>&1
    echo "helper exited, restarting" >>/data/local/tmp/gpm-module.log
    # a helper that exits at once means another one owns the flock: back off
    sleep 20""", 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("service.sh: single supervisor + backoff")