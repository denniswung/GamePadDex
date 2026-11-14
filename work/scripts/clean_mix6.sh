#!/system/bin/sh
PKG=com.dennis.dexpad
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
[ -z "$XML" ] && exit 1
am force-stop $PKG; sleep 1
awk '!/name="mix_6_/' "$XML" > /data/local/tmp/p6.xml
cat /data/local/tmp/p6.xml > "$XML"
chmod 600 "$XML"
sleep 0.3
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 3
cat "$XML"
echo "--- app: $(pidof $PKG) helper: $(ps -A -o PID,NAME | grep gpminput | grep -v grep) ---"
