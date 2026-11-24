D=/sdcard/w.xml; L=/sdcard/w.lines
dump_txt(){ rm -f $D $L; timeout 12 uiautomator dump $D >/dev/null 2>&1; sed 's/></>\n</g' $D > $L 2>/dev/null; grep -ao 'text="[^"]\{1,30\}"[^>]*bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' $L 2>/dev/null | sed -E 's/.*text="([^"]*)".*bounds="\[[0-9]*,([0-9]+)\]\[[0-9]*,([0-9]+)\]".*/\1|\2/' | head -30; }
am force-stop com.dennis.padtest >/dev/null 2>&1
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.2
cmd statusbar collapse >/dev/null 2>&1
/data/local/tmp/vgpad key 317 100 800 >/dev/null 2>&1; sleep 1.2
dump_txt > /sdcard/w1.txt; echo "== padtest before (list items) =="; grep -m4 "列表项" /sdcard/w1.txt
: > /data/adb/gpm/helper.log
am broadcast -a com.dennis.dexpad.HCMD -n com.dennis.dexpad/.DebugReceiver --es cmd "WHEEL -10" >/dev/null 2>&1
sleep 1.3
dump_txt > /sdcard/w2.txt; echo "== after direct HCMD WHEEL -10 =="; grep -m4 "列表项" /sdcard/w2.txt
echo "helper wheel lines:"; grep -a "^WHEEL" /data/adb/gpm/helper.log | tail -3
echo "PY markers:"; grep -m2 "第 1 页" /sdcard/w1.txt; grep -m2 "第 1 页" /sdcard/w2.txt