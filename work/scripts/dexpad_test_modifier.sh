#!/system/bin/sh
echo "== X held + left stick, release =="
logcat -c
/data/local/tmp/vgpad key 307 4000 5000 >/dev/null 2>&1 &
sleep 0.3
/data/local/tmp/vgpad stick 0 20000 800 5300 >/dev/null 2>&1 &
wait
sleep 1
logcat -d 2>/dev/null | grep -E 'single|mix |recents' | tail -8
echo "top: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
echo "== X tap alone =="
logcat -c
/data/local/tmp/vgpad key 307 200 5000 >/dev/null 2>&1
sleep 1
logcat -d 2>/dev/null | grep -E 'single|recents' | tail -4
echo "top: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
