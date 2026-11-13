#!/system/bin/sh
# experiment: does DOWN+CANCEL at the pointer move keyboard focus there?
am start --display 6 -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
uiautomator dump /sdcard/s1.xml >/dev/null 2>&1
echo "focused before:"; grep -o 'focused="true"[^>]*bounds="[^"]*"' /sdcard/s1.xml | head -3
echo "clickable count:"; grep -o 'clickable="true"' /sdcard/s1.xml | wc -l
# move pointer to middle of the window via REL injection
sendevent /dev/input/event19 2 0 300
sendevent /dev/input/event19 2 1 300
sendevent /dev/input/event19 0 0 0
sleep 0.4
P=$(dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1)
echo "pointer: $P"
X=$(echo "$P" | sed -n 's/.*at (\([0-9]*\)\..*/\1/p')
Y=$(echo "$P" | sed -n 's/.*, \([0-9]*\)\..*/\1/p')
echo "x=$X y=$Y"
if [ -n "$X" ]; then
    input -d 6 motionevent DOWN $X $Y
    input -d 6 motionevent CANCEL $X $Y
fi
sleep 0.6
uiautomator dump /sdcard/s2.xml >/dev/null 2>&1
echo "focused after down+cancel:"; grep -o 'focused="true"[^>]*bounds="[^"]*"' /sdcard/s2.xml | head -3
input -d 6 keyevent 20
sleep 0.6
uiautomator dump /sdcard/s3.xml >/dev/null 2>&1
echo "focused after arrow:"; grep -o 'focused="true"[^>]*bounds="[^"]*"' /sdcard/s3.xml | head -3
