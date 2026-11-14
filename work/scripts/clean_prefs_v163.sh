#!/system/bin/sh
PKG=com.dennis.dexpad
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
am force-stop $PKG
i=0; while [ $i -lt 12 ]; do sleep 0.4; [ -z "$(pidof $PKG)" ] && break; i=$((i+1)); done
awk '!/name="(btn_|par_|mix_|left_touch|combo_|dbl_|lng_)/' "$XML" > /data/local/tmp/pc.xml
cat /data/local/tmp/pc.xml > "$XML"; chmod 600 "$XML"
sleep 0.3
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 3
echo "--- 清理后 prefs ---"
cat "$XML"
