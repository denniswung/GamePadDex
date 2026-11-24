#!/system/bin/sh
VG=/data/local/tmp/vgpad
D=/sdcard/p.xml; L=/sdcard/p.lines
dump(){ timeout 12 uiautomator dump $D >/dev/null 2>&1; sed 's/></>\n</g' $D > $L 2>/dev/null; }
am force-stop com.dennis.padtest >/dev/null 2>&1
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.2
cmd statusbar collapse >/dev/null 2>&1; sleep 0.3
$VG key 317 100 800 >/dev/null 2>&1; sleep 1.2
$VG stick 4 24000 1500 >/dev/null 2>&1; sleep 1.2
dump
echo "== nodes intersecting y=480..1040 (bottom state) =="
grep -o 'text="[^"]*" resource-id="[^"]*" class="[^"]*" package="[^"]*" content-desc="[^"]*"[^>]*bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' $L 2>/dev/null | sed -E 's/text="([^"]*)".*class="([^"]*)".*bounds="\[[0-9]*,([0-9]+)\]\[[0-9]*,([0-9]+)\]".*/\1 | \2 | \3..\4/' | awk -F'|' '{split($3,a," "); if(a[1]+0<1040 && a[2]+0>480) print}' | head -15
echo "== classes only =="
grep -o 'class="[^"]*"[^>]*bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' $L 2>/dev/null | sed -E 's/class="([^"]*)".*\[[0-9]*,([0-9]+)\]\[[0-9]*,([0-9]+)\].*/\1 | \2..\3/' | awk -F'|' '{split($2,a," "); if(a[1]+0<1040 && a[2]+0>480) print}' | head -15
