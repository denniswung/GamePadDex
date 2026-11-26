#!/system/bin/sh
# probe_v169_mix009b.sh -- MIX-009 对照：不定位（对照）vs P 定位到分页条（修复后）
BIN=/data/adb/gpm/gpminput
OUT=/data/local/tmp/v169_mixb_out.txt
FIFO=/data/local/tmp/v169_mixb_in.fifo
RES=/data/local/tmp/v169_mixb.txt
PAD=com.dennis.padtest
PKG=com.dennis.dexpad
MOD=/data/adb/modules/gpm_dex
log() { echo "$@" | tee -a "$RES"; }
: > "$RES"
for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
am force-stop $PKG >/dev/null 2>&1
am force-stop $PAD >/dev/null 2>&1
for p in $(pgrep -f 'gpminput --socket'); do kill -9 "$p" 2>/dev/null; done
for p in $(pgrep -f 'gpminput$'); do kill -9 "$p" 2>/dev/null; done
for p in $(pgrep -f vgpad); do kill -9 "$p" 2>/dev/null; done
sleep 1
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
rm -f "$FIFO"; mkfifo "$FIFO"; : > "$OUT"
$BIN < "$FIFO" > "$OUT" 2>/dev/null &
HPID=$!
exec 3> "$FIFO"
sleep 1
send() { echo "$*" >&3; }
send "q 2560 1600"; sleep 0.3
uiautomator dump /sdcard/v169_mixb_a.xml >/dev/null 2>&1
log "A) 起始: $(grep -a -o '横向 scrollX=[0-9]*' /sdcard/v169_mixb_a.xml | head -1)"
# 对照：不 P，直接横向滑动（旧行为，起手点在屏幕中心=列表区）
send "V 0 -600 250 2560 1600"; sleep 1.8
uiautomator dump /sdcard/v169_mixb_b.xml >/dev/null 2>&1
log "B) 未定位直接滑: $(grep -a -o '横向 scrollX=[0-9]*' /sdcard/v169_mixb_b.xml | head -1)"
grep -a '^SWIPE 0 ' "$OUT" | tail -1 | sed 's/^/   /' >> "$RES"
# 修复后：P 到分页条中心，再横向滑动（左滑）
send "P 1280 1507 2560 1600"; sleep 1.5
send "V 0 -600 250 2560 1600"; sleep 1.8
uiautomator dump /sdcard/v169_mixb_c.xml >/dev/null 2>&1
log "C) P 定位后滑: $(grep -a -o '横向 scrollX=[0-9]*' /sdcard/v169_mixb_c.xml | head -1)"
grep -a '^SWIPE 0 ' "$OUT" | tail -1 | sed 's/^/   /' >> "$RES"
grep -a 'POSPTR' "$OUT" | tail -1 | sed 's/^/   /' >> "$RES"
exec 3>&-
kill "$HPID" 2>/dev/null
sleep 0.5
setsid /system/bin/sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
sleep 4
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
log "restored helper=$(pidof gpminput) engine=$(pidof $PKG)"
log DONE
