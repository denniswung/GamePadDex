D=/sdcard/s.xml; L=/sdcard/s.lines
am start -a android.settings.SETTINGS >/dev/null 2>&1; sleep 3
timeout 12 uiautomator dump $D >/dev/null 2>&1
sed 's/></>\n</g' $D > $L 2>/dev/null
echo "lines=$(wc -l < $L)"
echo "texts=$(grep -c 'text="[^"]' $L)"
grep -m8 'text="[^"]' $L | sed -E 's/.*text="([^"]*)".*bounds="\[[0-9]*,([0-9]+)\]\[[0-9]*,([0-9]+)\]".*/\1 | \2..\3/' 