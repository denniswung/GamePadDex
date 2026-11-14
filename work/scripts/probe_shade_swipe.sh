#!/system/bin/sh
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake; sleep 1
input keyevent 4 >/dev/null 2>&1; sleep 1
screencap -p /data/local/tmp/u0.png 2>/dev/null
echo "base=$(wc -c < /data/local/tmp/u0.png)"
echo "--- input swipe 1280 4 -> 1280 880 300 ---"
input swipe 1280 4 1280 880 300
sleep 2
screencap -p /data/local/tmp/u1.png 2>/dev/null
echo "after=$(wc -c < /data/local/tmp/u1.png)"
