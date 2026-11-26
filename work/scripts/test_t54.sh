#!/system/bin/sh
RES=/data/local/tmp/t54.txt
G=/data/local/tmp/gpmctl
S=/data/adb/gpm/gpmctl.sock
LOG=/data/adb/gpm/helper.log
PAD=com.dennis.padtest
log() { echo "$@" | tee -a "$RES"; }
dump() { uiautomator dump /sdcard/t54_$1.xml >/dev/null 2>&1; }
item() { grep -a -o '列表项 #[0-9]*' /sdcard/t54_$1.xml | head -1; }
: > "$RES"
log "== t54 $(date) helper=$(pidof gpminput) engine=$(pidof com.dennis.dexpad) =="
PID0=$(pidof gpminput)
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3

# A) 10 commands stability
FAIL=0
for i in 1 2 3 4 5; do
    out=$(timeout 5 "$G" "$S" c 2>&1); rc=$?
    [ $rc -ne 0 ] && FAIL=$((FAIL+1))
    out2=$(timeout 5 "$G" "$S" "?" 2>&1); rc2=$?
    [ $rc2 -ne 0 ] && FAIL=$((FAIL+1))
done
PID1=$(pidof gpminput)
log "A) 10 cmds: FAIL=$FAIL pid $PID0 -> $PID1 (same=$([ "$PID0" = "$PID1" ] && echo yes || echo no))"

# B) detached drag: 3 connections
dump a
log "B) before: $(item a)"
timeout 5 "$G" "$S" d 0 1280 1000 >/dev/null 2>&1
sleep 0.1
timeout 5 "$G" "$S" m 0 0 -400 300 >/dev/null 2>&1
sleep 0.8
timeout 5 "$G" "$S" e 0 >/dev/null 2>&1
sleep 0.8
dump b
log "B) after:  $(item b)"
grep -a -E '^DRAG (down|move|up)' "$LOG" | tail -3 | sed 's/^/  /' >> "$RES"

# C) 1.5s auto-up (d without m)
timeout 5 "$G" "$S" d 0 1280 900 >/dev/null 2>&1
sleep 2.0
log "C) auto-up: $(grep -a '^DRAG up' "$LOG" | tail -1)"
log DONE
