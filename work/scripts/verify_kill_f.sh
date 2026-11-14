#!/system/bin/sh
PKG=com.dennis.dexpad
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 2
TOP=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')
echo "前台=$TOP  进程=$(pidof com.dennis.padtest)"

: > /data/adb/gpm/helper.log
am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd 'f' >/dev/null 2>&1
sleep 4
echo "--- helper ---"
grep -aE 'FORCE_STOP|FORCE_KILL' /data/adb/gpm/helper.log | tail -3
P=$(pidof com.dennis.padtest)
if [ -n "$P" ]; then echo "之后进程=$P （还活着）"; else echo "之后进程=已死"; fi
echo "之后前台=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"
