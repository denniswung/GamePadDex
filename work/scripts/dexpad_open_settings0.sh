#!/system/bin/sh
# bring the Samsung DeX settings page to the foreground on the phone display
am start --display 0 -n 'com.android.settings/.Settings$DexModeActivity'
sleep 3
dumpsys activity activities 2>/dev/null | grep -E 'topResumedActivity' | head -3
