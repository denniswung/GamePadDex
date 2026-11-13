#!/system/bin/sh
PKG=com.dennis.dexpad
PREFS_DIR=/data/misc/f7a4f515-2be2-4c14-959e-dc82d9b3e434/prefs/$PKG
dump() { uiautomator dump --compressed /data/local/tmp/ui_dlg.xml >/dev/null 2>&1; }
xy() {
  tr '>' '\n' < /data/local/tmp/ui_dlg.xml 2>/dev/null | grep "$1" | head -1 |
    sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'
}
tapb() { set -- $1; input tap $(( ($1+$3)/2 )) $(( ($2+$4)/2 )); }
am force-stop $PKG; sleep 1
am start -W -n $PKG/.ConfigActivity >/dev/null 2>&1
sleep 2.5
i=0
while [ $i -lt 10 ]; do
  dump
  B=$(xy 'text="保存为 Profile')
  [ -n "$B" ] && break
  input swipe 1280 1300 1280 500 200
  sleep 0.6
  i=$((i+1))
done
tapb "$B"
sleep 1.5
dump
E=$(xy 'class="android.widget.EditText"')
echo "edit='$E'"
tapb "$E"
sleep 0.6
input text uitest
sleep 0.8
dump
echo "edit text now: $(tr '>' '\n' < /data/local/tmp/ui_dlg.xml | grep 'android.widget.EditText' | sed -n 's/.*text="\([^"]*\)".*/\1/p')"
O=$(xy 'text="确定"')
echo "ok btn='$O'"
tapb "$O"
sleep 1.5
dump
echo "dialog still open: $(tr '>' '\n' < /data/local/tmp/ui_dlg.xml | grep -c 'android.widget.EditText')"
echo "prefs profiles: $(grep -o 'name="profiles"[^/]*' $PREFS_DIR/dexpad.xml 2>/dev/null)"
