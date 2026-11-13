#!/system/bin/sh
P=com.dennis.padtest
VG=/data/local/tmp/vgpad
run() { # $1 desc, $2.. command
    logcat -c
    L=$(wc -l < /data/adb/gpm/helper.log)
    shift
    "$@"
    sleep 0.9
    HOME=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEYON 0 3')
    echo "--- $DESC home=$HOME"
    logcat -d -s DexPad | grep -E 'button |single |home on display|deferred|cancel' | sed 's/^.*DexPad  : //' | head -6
}

am start -n $P/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 1.5

DESC="1) A click 80ms, gap 0ms, Y 120ms"
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
( $VG key 304 80 2000 >/dev/null 2>&1 & )
sleep 2.0
$VG key 308 120 0 >/dev/null 2>&1
sleep 1.0
echo "--- $DESC home=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEYON 0 3')"
logcat -d -s DexPad | grep -E 'button |single |home on display|cancel' | sed 's/^.*DexPad  : //' | head -6

DESC="2) A 120ms 与 Y 60ms 重叠（Y 在 A 按下期间）"
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
( $VG key 304 300 2000 >/dev/null 2>&1 & )
sleep 2.05
$VG key 308 60 0 >/dev/null 2>&1
sleep 1.2
echo "--- $DESC home=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEYON 0 3')"
logcat -d -s DexPad | grep -E 'button |single |home on display|cancel' | sed 's/^.*DexPad  : //' | head -8

DESC="3) 单独 Y 40ms（很短）"
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
$VG key 308 40 2000 >/dev/null 2>&1
sleep 1.0
echo "--- $DESC home=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEYON 0 3')"
logcat -d -s DexPad | grep -E 'button |single |home on display|cancel' | sed 's/^.*DexPad  : //' | head -6

DESC="4) A 80ms 后 30ms 再 Y 40ms"
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
$VG key 304 80 2000 >/dev/null 2>&1
$VG key 308 40 30 >/dev/null 2>&1
sleep 1.0
echo "--- $DESC home=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEYON 0 3')"
logcat -d -s DexPad | grep -E 'button |single |home on display|cancel' | sed 's/^.*DexPad  : //' | head -6
