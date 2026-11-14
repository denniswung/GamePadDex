#!/system/bin/sh
PKG=com.dennis.dexpad
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
[ -z "$XML" ] && exit 1
am force-stop $PKG; sleep 1
awk '!/name="btn_r3"/ && !/name="par_r3"/ && !/name="mix_6_/' "$XML" > /data/local/tmp/pc.xml
cat /data/local/tmp/pc.xml > "$XML"
chmod 600 "$XML"
sleep 0.5
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
echo "--- prefs ---"
cat "$XML"
echo "--- R3 映射（应为 volume_mute）---"
logcat -c
/data/local/tmp/vgpad key 318 120 900 >/dev/null 2>&1
sleep 1.5
logcat -d -s DexPad | grep -aE 'button r3' | tail -2
