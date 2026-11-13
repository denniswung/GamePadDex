#!/system/bin/sh
PKG=com.dennis.dexpad
dump() { uiautomator dump --compressed /data/local/tmp/ui_dlg.xml >/dev/null 2>&1; }
xy() {
  tr '>' '\n' < /data/local/tmp/ui_dlg.xml 2>/dev/null | grep "text=\"$1" | head -1 |
    sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'
}
am force-stop $PKG
sleep 1
am start -W -n $PKG/.ConfigActivity >/dev/null 2>&1
sleep 2.5
i=0
while [ $i -lt 10 ]; do
  dump
  B=$(xy "保存为 Profile")
  [ -n "$B" ] && break
  input swipe 1280 1300 1280 500 200
  sleep 0.6
  i=$((i+1))
done
echo "swipes=$i row='$B'"
if [ -z "$B" ]; then
  echo "--- visible texts ---"
  tr '>' '\n' < /data/local/tmp/ui_dlg.xml | sed -n 's/.*text="\([^"]*\)".*/\1/p' | grep -v '^$' | head -20
  exit 1
fi
set -- $B
input tap $(( ($1+$3)/2 )) $(( ($2+$4)/2 ))
sleep 1.5
dump
echo "--- dialog nodes ---"
tr '>' '\n' < /data/local/tmp/ui_dlg.xml | grep -E 'EditText|确定|取消' | cut -c1-200
