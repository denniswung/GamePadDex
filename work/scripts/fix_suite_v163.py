import io

P = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v160_auto_suite.sh"
s = io.open(P, encoding="utf-8").read()
fails = []


def rep(old, new, tag):
    global s
    if old not in s:
        fails.append(tag)
        return
    s = s.replace(old, new, 1)


rep("""stop_engine(){ am force-stop $PKG; sleep 1; }""",
    """stop_engine(){
  am force-stop $PKG >/dev/null 2>&1
  i=0
  while [ $i -lt 12 ]; do
    sleep 0.4
    [ -z "$(pidof $PKG)" ] && break
    i=$((i+1))
  done
  sleep 0.4
}""", "stop_engine")

rep("""start_engine(){
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  i=0
  while [ $i -lt 20 ]; do
    sleep 0.5
    i=$((i+1))
    logcat -d -s DexPad 2>/dev/null | tail -40 | grep -q 'hb ready=true' && break
  done
  sleep 1
}""",
    """start_engine(){
  logcat -c 2>/dev/null
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  i=0
  while [ $i -lt 20 ]; do
    sleep 0.5
    i=$((i+1))
    logcat -d -s DexPad 2>/dev/null | grep -q 'hb ready=true' && break
  done
  sleep 1
}""", "start_engine")

io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("FAILS:", fails if fails else "none")
