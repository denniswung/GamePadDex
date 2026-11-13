#!/system/bin/sh
# keep pinging the engine so Freecess thaws it, then verify input keeps working
( while true; do sleep 8; am start-foreground-service -n com.dennis.dexpad/.EngineService >/dev/null 2>&1; done ) &
PING=$!
sleep 12
logcat -c
/data/local/tmp/vgpad key 304 150 3000 >/dev/null 2>&1
sleep 1
echo "== first press =="
logcat -d -s DexPad 2>/dev/null | grep -E 'button a|left button' | tail -2
sleep 25
logcat -c
/data/local/tmp/vgpad key 304 150 3000 >/dev/null 2>&1
sleep 1
echo "== press after 25s =="
logcat -d -s DexPad 2>/dev/null | grep -E 'button a|left button' | tail -2
kill $PING 2>/dev/null
