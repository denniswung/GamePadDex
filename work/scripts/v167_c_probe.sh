#!/system/bin/sh
# C-MOVE 专项（无点击，纯 hover）：设置列表滚轮模式，LB 1.5s，uiautomator 前后差
VG=/data/local/tmp/vgpad
RAW=/data/local/tmp/lbrb_raw
D=/sdcard/c.xml; L=/sdcard/c.lines
dump_txt(){ rm -f $D $L; timeout 12 uiautomator dump $D >/dev/null 2>&1; sed 's/></>\n</g' $D > $L 2>/dev/null; grep -ao 'text="[^"]\{1,40\}"[^>]*bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' $L 2>/dev/null | sed -E 's/.*text="([^"]*)".*bounds="\[[0-9]*,([0-9]+)\]\[[0-9]*,([0-9]+)\]".*/\1|\2/' | head -40; }
am broadcast -a com.dennis.dexpad.DEBUG -n com.dennis.dexpad/.DebugReceiver --es pref v_touch_scroll --ez bval false >/dev/null 2>&1
sleep 1.2
echo "vtouch=$(grep -ao 'v_touch_scroll" value="[a-z]*"' /data/misc/*/prefs/com.dennis.dexpad/dexpad.xml)"
am force-stop com.android.settings >/dev/null 2>&1
am start -a android.settings.SETTINGS >/dev/null 2>&1; sleep 3.0
input swipe 1280 1200 1280 500 300 >/dev/null 2>&1; sleep 1.2
$VG key 317 100 800 >/dev/null 2>&1; sleep 1.2
# 只做鼠标移动建立 hover，不点击
am broadcast -a com.dennis.dexpad.HCMD -n com.dennis.dexpad/.DebugReceiver --es cmd "P 1280 700 2560 1600" >/dev/null 2>&1; sleep 0.3
am broadcast -a com.dennis.dexpad.HCMD -n com.dennis.dexpad/.DebugReceiver --es cmd "P 1280 800 2560 1600" >/dev/null 2>&1; sleep 0.5
am broadcast -a com.dennis.dexpad.HCMD -n com.dennis.dexpad/.DebugReceiver --es cmd "c" >/dev/null 2>&1; sleep 0.8
echo "cursor: $(grep -a '^CURSOR ' /data/adb/gpm/helper.log | tail -1)"
dump_txt > $RAW/C2_before.txt
: > /data/adb/gpm/helper.log
$VG key 310 1500 400 >/dev/null 2>&1
sleep 1.2
dump_txt > $RAW/C2_after.txt
echo "wheel=$(grep -ac '^WHEEL' /data/adb/gpm/helper.log) swipe=$(grep -ac '^SWIPE ' /data/adb/gpm/helper.log)"
d=$(awk -F'|' 'NR==FNR{ b[$1]=$2; next } { if ($1 in b && b[$1]!="" && $2!="") { d=b[$1]-$2; if(d<0)d=-d; if(d>m) m=d } } END{ print (m==""?0:m) }' $RAW/C2_before.txt $RAW/C2_after.txt)
echo "dSET=$d"
echo "--- before ---"; head -8 $RAW/C2_before.txt
echo "--- after ---"; head -8 $RAW/C2_after.txt
