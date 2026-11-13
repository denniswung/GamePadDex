#!/system/bin/sh
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2.5
dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity
rm -f /data/adb/gpm/focus.txt /data/local/tmp/gpm_focus_ui.xml
(echo q; sleep 7) | timeout 10 /data/adb/gpm/gpminput 2>&1 | grep -aE 'FOCUS' | head -3
echo "--- dump ---"
ls -l /data/local/tmp/gpm_focus_ui.xml 2>&1
grep -c 'scrollable="true"' /data/local/tmp/gpm_focus_ui.xml 2>/dev/null
echo "--- focus file ---"
cat /data/adb/gpm/focus.txt 2>/dev/null || echo none
