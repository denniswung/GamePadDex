import io, re

P = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v160_auto_suite.sh"
s = io.open(P, encoding="utf-8").read()
fails = []


def rep(old, new, tag):
    global s
    if old not in s:
        fails.append(tag)
        return
    s = s.replace(old, new, 1)


# 1) start_engine 等链路就绪（不再盲等 4 秒）
rep("""start_engine(){ am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1; sleep 4; }""",
    """start_engine(){
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  i=0
  while [ $i -lt 20 ]; do
    sleep 0.5
    i=$((i+1))
    logcat -d -s DexPad 2>/dev/null | tail -40 | grep -q 'hb ready=true' && break
  done
  sleep 1
}""", "start_engine")

# 2) B3：按 A 前先把导航模式清掉（推左摇杆），并在触摸注入后用引擎日志判定
rep("""$VG key 317 100 1200 >/dev/null 2>&1; sleep 1.5
: > /data/adb/gpm/helper.log
$VG key 304 120 800 >/dev/null 2>&1
sleep 1.2
pull_report
TD=$(grep -ac 'TOUCH down' /data/adb/gpm/helper.log)""",
    """$VG key 317 100 1200 >/dev/null 2>&1; sleep 1.5
$VG stick 0 20000 300 0 >/dev/null 2>&1; sleep 0.5
: > /data/adb/gpm/helper.log
logcat -c
$VG key 304 120 800 >/dev/null 2>&1
sleep 1.2
pull_report
TD=$(grep -ac 'TOUCH down' /data/adb/gpm/helper.log)
TD2=$(logcat -d -s DexPad | grep -ac 'left touch down')
[ "$TD" -ge 1 ] && [ "$TD2" -ge 1 ] || TD=0""", "B3")

# 3) F3：摇杆推大一点，并确认日志里已退出导航
rep("""$VG hat 0 1 250 >/dev/null 2>&1
sleep 0.3
$VG stick 0 9000 300 0 >/dev/null 2>&1
sleep 0.6
$VG key 304 120 700 >/dev/null 2>&1
sleep 1.2
grep -q 'native navigation OFF (stick moved)' /dev/null 2>/dev/null
C=$(logcat -d -s DexPad | grep -ac 'left button down')""",
    """$VG hat 0 1 250 >/dev/null 2>&1
sleep 0.3
$VG stick 0 22000 350 0 >/dev/null 2>&1
sleep 0.8
OFF=$(logcat -d -s DexPad | grep -ac 'native navigation OFF (stick moved)')
$VG key 304 120 700 >/dev/null 2>&1
sleep 1.2
C=$(logcat -d -s DexPad | grep -ac 'left button down')
[ "$OFF" -ge 1 ] || ok "F3 提示：未记录到 stick moved 日志（继续判定）"
""", "F3")

io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("FAILS:", fails if fails else "none")
