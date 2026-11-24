#!/system/bin/sh
VG=/data/local/tmp/vgpad
D=/sdcard/w.xml; L=/sdcard/w.lines
dump_txt(){ timeout 12 uiautomator dump $D >/dev/null 2>&1; sed 's/></>\n</g' $D > $L 2>/dev/null; grep -ao 'text="[^"]\{1,40\}"[^>]*bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' $L 2>/dev/null | sed -E 's/.*text="([^"]*)".*bounds="\[[0-9]*,([0-9]+)\]\[[0-9]*,([0-9]+)\]".*/\1|\2/' | head -30; }
am start -a android.settings.SETTINGS >/dev/null 2>&1; sleep 3
$VG key 317 100 800 >/dev/null 2>&1; sleep 1.2
dump_txt > /sdcard/w1.txt
echo "== before =="; head -6 /sdcard/w1.txt
am broadcast -a com.dennis.dexpad.HCMD -n com.dennis.dexpad/.DebugReceiver --es cmd "WHEEL 5" >/dev/null 2>&1
sleep 1.2
dump_txt > /sdcard/w2.txt
echo "== after HCMD WHEEL 5 =="; head -6 /sdcard/w2.txt
am broadcast -a com.dennis.dexpad.HCMD -n com.dennis.dexpad/.DebugReceiver --es cmd "WHEEL -8" >/dev/null 2>&1
sleep 1.2
dump_txt > /sdcard/w3.txt
echo "== after HCMD WHEEL -8 =="; head -6 /sdcard/w3.txt
tail -6 /data/adb/gpm/helper.log
