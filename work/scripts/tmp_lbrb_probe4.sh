#!/system/bin/sh
VG=/data/local/tmp/vgpad
D=/sdcard/q.xml; L=/sdcard/q.lines
dump(){ timeout 15 uiautomator dump $D >/dev/null 2>&1; sed 's/></>\n</g' $D > $L 2>/dev/null; }
txts(){ grep -ao 'text="[^"]\{1,40\}"[^>]*bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' $L 2>/dev/null | sed -E 's/.*text="([^"]*)".*\[[0-9]*,([0-9]+)\]\[[0-9]*,([0-9]+)\].*/\1|\2|\3/' | head -40; }
am start -n com.example.piliplus/.MainActivity >/dev/null 2>&1; sleep 3.5
cmd statusbar collapse >/dev/null 2>&1; sleep 0.5
$VG key 317 100 800 >/dev/null 2>&1; sleep 1.2
dump
echo "PiliPlus before (top 12 text nodes):"; txts | head -12
B1=$(txts | head -40 | md5sum 2>/dev/null | awk '{print $1}')
: > /data/adb/gpm/helper.log
$VG key 311 1500 400 >/dev/null 2>&1; sleep 1.5
dump
echo "PiliPlus after RB 1.5s:"; txts | head -12
B2=$(txts | head -40 | md5sum 2>/dev/null | awk '{print $1}')
echo "content hash before=$B1 after=$B2"
grep -a '^SWIPE ' /data/adb/gpm/helper.log | tail -2
