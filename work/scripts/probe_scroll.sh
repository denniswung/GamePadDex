#!/system/bin/sh
PKG=com.dennis.dexpad
dump() { uiautomator dump --compressed /data/local/tmp/ui_sc.xml >/dev/null 2>&1; }
has() { tr '>' '\n' < /data/local/tmp/ui_sc.xml 2>/dev/null | grep -c "text=\"$1"; }
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am start -W -n $PKG/.ConfigActivity >/dev/null 2>&1
sleep 2
dump
echo "start: export=$(has 导出配置) save=$(has 保存为)"
for x in 2530 60 1280; do
  input swipe $x 1300 $x 500 250
  sleep 0.8
  dump
  echo "after swipe x=$x: export=$(has 导出配置) save=$(has 保存为)"
done
# try keyboard paging
input keyevent KEYCODE_PAGE_DOWN
sleep 0.8
dump
echo "after page_down: export=$(has 导出配置) save=$(has 保存为)"
