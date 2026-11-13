#!/system/bin/sh
# chord with a slow second key: X down at 6.0s (held 3s), D-pad up at 6.5s
logcat -c
echo "before: $(cmd media_session volume --get 2>/dev/null | grep -o 'volume is [0-9]*')"
/data/local/tmp/vgpad key 307 3000 6000 >/dev/null 2>&1 &
sleep 0.2
/data/local/tmp/vgpad hat 0 -1 300 6500 >/dev/null 2>&1
wait
sleep 1
echo "== engine =="
logcat -d -s DexPad 2>/dev/null | grep -E 'deferred|cancelled|mix |recents|home|volume up' | tail -8
echo "after: $(cmd media_session volume --get 2>/dev/null | grep -o 'volume is [0-9]*')"
dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity
