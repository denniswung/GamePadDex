#!/system/bin/sh
PKG=com.dennis.dexpad
dump() { uiautomator dump --compressed /data/local/tmp/ui_dlg.xml >/dev/null 2>&1; }
xy() {
  tr '>' '\n' < /data/local/tmp/ui_dlg.xml 2>/dev/null | grep "$1" | head -1 |
    sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'
}
tapb() { set -- $1; input tap $(( ($1+$3)/2 )) $(( ($2+$4)/2 )); }
edtext() { tr '>' '\n' < /data/local/tmp/ui_dlg.xml | grep 'android.widget.EditText' | sed -n 's/.*text="\([^"]*\)".*/\1/p'; }
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
tapb "$B"; sleep 1.5; dump
tapb "$(xy 'class="android.widget.EditText"')"
sleep 0.5
echo "IME state: $(dumpsys input_method 2>/dev/null | grep -m1 mInputShown)"
input keyevent KEYCODE_A
sleep 0.4
input keyevent KEYCODE_B
sleep 0.4
dump
echo "after keyevents: '$(edtext)'"
input text "xyz"
sleep 0.6
dump
echo "after input text: '$(edtext)'"
