am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2
rm -f /sdcard/r1.xml; timeout 20 uiautomator dump /sdcard/r1.xml 2>&1 | tail -1; echo "engine-on size=$(stat -c %s /sdcard/r1.xml 2>/dev/null)"
am force-stop com.dennis.dexpad
sleep 1.5
rm -f /sdcard/r2.xml; timeout 20 uiautomator dump /sdcard/r2.xml 2>&1 | tail -1; echo "engine-off size=$(stat -c %s /sdcard/r2.xml 2>/dev/null)"
sed 's/></>\n</g' /sdcard/r2.xml > /sdcard/r2.lines 2>/dev/null
echo "第count=$(grep -ac '第 ' /sdcard/r2.lines)"
am start-foreground-service -n com.dennis.dexpad/.EngineService >/dev/null 2>&1; sleep 3
echo "engine back: $(pidof com.dennis.dexpad)"