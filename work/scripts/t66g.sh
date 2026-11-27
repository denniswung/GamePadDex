#!/system/bin/sh
uiautomator dump /sdcard/t66g.xml >/dev/null 2>&1
echo "== texts =="
grep -a -o 'text="[^"]*"' /sdcard/t66g.xml | sed -n '1,26p'
