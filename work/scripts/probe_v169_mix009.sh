#!/system/bin/sh
# probe_v169_mix009.sh -- t41锛歅 瀹氫綅鍒版í鍚戝垎椤垫潯鍚?V 婊戝姩锛岄獙璇?MIX-009
BIN=/data/adb/gpm/gpminput
OUT=/data/local/tmp/v169_mix_out.txt
FIFO=/data/local/tmp/v169_mix_in.fifo
RES=/data/local/tmp/v169_mix.txt
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
log "ready=$(grep -ac '^READY' "$OUT")"
send "q 2560 1600"; sleep 0.3
uiautomator dump /sdcard/v169_mix_a.xml >/dev/null 2>&1
log "-- before: $(grep -a -o '妯悜 scrollX=[0-9]*  椤碘増[0-9]*' /sdcard/v169_mix_a.xml)"
log "-- c before:"; send "c"; sleep 0.8; grep -a '^CURSOR ' "$OUT" | tail -1 | sed 's/^/  /' >> "$RES"
log "-- P 1280 1507 (妯悜鍒嗛〉鏉′腑蹇?:"
send "P 1280 1507 2560 1600"; sleep 1.5
grep -a -E 'POSPTR' "$OUT" | tail -1 | sed 's/^/  /' >> "$RES"
send "c"; sleep 0.8; grep -a '^CURSOR ' "$OUT" | tail -1 | sed 's/^/  /' >> "$RES"
log "-- V 0 600 (妯悜婊戝姩):"
send "V 0 600 250 2560 1600"; sleep 1.6
grep -a -E '^SWIPE 0 ' "$OUT" | tail -1 | sed 's/^/  /' >> "$RES"
uiautomator dump /sdcard/v169_mix_b.xml >/dev/null 2>&1
log "-- after: $(grep -a -o '妯悜 scrollX=[0-9]*  椤碘増[0-9]*' /sdcard/v169_mix_b.xml)"
# 鍐嶆潵涓€娆★紝鍚戝彸锛堝弽鍚戯級楠岃瘉涓嶆槸鍗曞悜鍋跺彂
send "V 0 -600 250 2560 1600"; sleep 1.6
uiautomator dump /sdcard/v169_mix_c.xml >/dev/null 2>&1
log "-- after reverse: $(grep -a -o '妯悜 scrollX=[0-9]*  椤碘増[0-9]*' /sdcard/v169_mix_c.xml)"
exec 3>&-
kill "$HPID" 2>/dev/null
sleep 0.5
setsid /system/bin/sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
sleep 4
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
log "restored helper=$(pidof gpminput) engine=$(pidof $PKG)"
log DONE

