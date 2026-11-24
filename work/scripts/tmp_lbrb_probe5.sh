#!/system/bin/sh
VG=/data/local/tmp/vgpad
D=/sdcard/p.xml; L=/sdcard/p.lines
dump(){ timeout 12 uiautomator dump $D >/dev/null 2>&1; sed 's/></>\n</g' $D > $L 2>/dev/null; }
tops(){ grep -ao 'text="\(左列表 #[0-9]*\|右列表 #[0-9]*\|固定 #[0-9]*\)"[^>]*bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' $L 2>/dev/null | sed -E 's/.*text="([^"]*)".*\[[0-9]*,([0-9]+)\]\[[0-9]*,([0-9]+)\].*/\1|\2|\3/' | head -20; }
am force-stop com.dennis.padtest >/dev/null 2>&1
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.2
cmd statusbar collapse >/dev/null 2>&1; sleep 0.3
$VG key 317 100 800 >/dev/null 2>&1; sleep 1.2
$VG stick 4 24000 1500 >/dev/null 2>&1; sleep 1.2
dump; echo "== bottom state tops =="; tops
: > /data/adb/gpm/helper.log
$VG key 311 1500 400 >/dev/null 2>&1; sleep 1.4
dump; echo "== after RB 1.5s =="; tops
grep -a '^SWIPE ' /data/adb/gpm/helper.log | tail -2
