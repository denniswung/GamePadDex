#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }

wake; sleep 1
echo "mode=$(modeval)  helper=$(ps -A -o NAME | grep -c gpminput)  app=$(pidof $PKG)"
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2
echo "before: $(top)"
L=$(wc -l < /data/adb/gpm/helper.log)
$VG key 308 150 1000 >/dev/null 2>&1
sleep 2
echo "after : $(top)"
echo "--- helper 新增行 ---"
tail -n +$((L+1)) /data/adb/gpm/helper.log | head -8
echo "--- engine ---"
logcat -d -s DexPad | grep -aE 'button y|home on|KEYUIN|volume' | tail -4
