#!/system/bin/sh
# open the Samsung DeX settings page on the phone display
am force-stop com.android.settings
sleep 1
input keyevent KEYCODE_WAKEUP
cmd window dismiss-keyguard 2>/dev/null
sleep 1
am start -n 'com.android.settings/.Settings$DexModeActivity'
sleep 3
dumpsys activity activities | grep -m3 topResumedActivity
