#!/system/bin/sh
# v1.66 post-reboot diagnosis: window/activity state + helper selftest + cursor read
PKG=com.dennis.dexpad
echo "=== window ==="
dumpsys window | grep -m1 mCurrentFocus
dumpsys window | grep -m1 mFocusedApp
echo "=== top resumed ==="
dumpsys activity activities | grep -m2 topResumedActivity
echo "=== display state ==="
dumpsys display | grep -m1 'mDisplayState' 
dumpsys power | grep -m1 mWakefulness=
echo "=== keyguard ==="
dumpsys window | grep -m1 -E 'mDreamingLockscreen|mShowingLockscreen'
echo "=== services ==="
dumpsys activity services $PKG | grep -E 'ServiceRecord|isForeground|app=' | head -6
echo "=== logcat tail (dexpad) ==="
logcat -d -t 300 | grep -iE 'dexpad|engine' | tail -12
echo "=== helper selftest (?) ==="
am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "?" >/dev/null 2>&1
sleep 2
logcat -d -t 200 | grep -iE 'selftest|CAP ' | tail -8
tail -8 /data/adb/gpm/helper.log
echo "=== cursor read (c) ==="
am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "c" >/dev/null 2>&1
sleep 2
logcat -d -t 200 | grep -iE 'CURSOR|cursor' | tail -5
tail -5 /data/adb/gpm/helper.log
