#!/system/bin/sh
PKG=com.dennis.dexpad
ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
rm -f /data/adb/gpm/uia_selftest.log /data/adb/gpm/uia.log
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
echo "--- daemon uid/ns ---"
pidof gpminput
echo "--- selftest uia line ---"
grep -a 'CAP uia' /data/adb/gpm/helper.log | tail -2
echo "--- selftest log ---"
cat /data/adb/gpm/uia_selftest.log 2>/dev/null | tail -3 || echo none
echo "--- dump file ---"
ls -l /data/local/tmp/gpm_st.xml 2>&1
