#!/system/bin/sh
ui(){ timeout 12 uiautomator dump /sdcard/v168.xml >/dev/null 2>&1; sed 's/></>\n</g' /sdcard/v168.xml > /sdcard/v168.lines 2>/dev/null; }
PY=-1
pyscan(){ PY=-1; local n l b y1
  for n in 1 2 3 4; do l=$(grep -m1 "text=\"第 $n 页\"" /sdcard/v168.lines 2>/dev/null); [ -z "$l" ] && continue
    b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'); [ -z "$b" ] && continue
    set -- $b; [ "$PY" = "-1" ] && PY=$y1; done; }
echo "before: PY=[$PY]"
ui; echo "dump size=$(stat -c %s /sdcard/v168.xml 2>/dev/null) lines=$(wc -l < /sdcard/v168.lines 2>/dev/null) pages=$(grep -c '第 1 页' /sdcard/v168.lines 2>/dev/null)"
pyscan
echo "after: PY=[$PY]"
