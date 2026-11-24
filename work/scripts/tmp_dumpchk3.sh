settings put global window_animation_scale 0
settings put global transition_animation_scale 0
settings put global animator_duration_scale 0
sleep 0.5
rm -f /sdcard/z2.xml
timeout 20 uiautomator dump /sdcard/z2.xml 2>&1 | tail -1
echo "padtest size=$(stat -c %s /sdcard/z2.xml 2>/dev/null)"
am start -a android.settings.SETTINGS >/dev/null 2>&1; sleep 2.5
rm -f /sdcard/z3.xml
timeout 20 uiautomator dump /sdcard/z3.xml 2>&1 | tail -1
echo "settings size=$(stat -c %s /sdcard/z3.xml 2>/dev/null)"
settings put global window_animation_scale 1; settings put global transition_animation_scale 1; settings put global animator_duration_scale 1