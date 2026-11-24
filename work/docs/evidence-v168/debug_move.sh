#!/system/bin/sh
# 内容位移探针：starts 后立即 dump（不 force-stop 引擎），再做 1.5s 拖拽后 dump
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3.0
cmd statusbar collapse >/dev/null 2>&1
sleep 0.5
echo "top=$(dumpsys activity activities | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"
for try in 1 2 3; do
  timeout 12 uiautomator dump /sdcard/p.xml >/dev/null 2>&1
  n=$(grep -c '第 1 页' /sdcard/p.xml 2>/dev/null)
  echo "try$try 页count=$n size=$(stat -c %s /sdcard/p.xml 2>/dev/null)"
  [ "$n" -gt 0 ] && break
  sleep 1.0
done
PY=$(sed 's/></>\n</g' /sdcard/p.xml 2>/dev/null | grep -m1 'text="第 1 页"' | sed -n 's/.*bounds="\[[0-9]*,\([0-9]*\)\].*/\1/p')
echo "PY_before=$PY"
logcat -c
$VG key 311 1500 400 >/dev/null 2>&1
sleep 1.5
timeout 12 uiautomator dump /sdcard/p2.xml >/dev/null 2>&1
PY2=$(sed 's/></>\n</g' /sdcard/p2.xml 2>/dev/null | grep -m1 'text="第 1 页"' | sed -n 's/.*bounds="\[[0-9]*,\([0-9]*\)\].*/\1/p')
T=$(logcat -d -s DexPad | grep -a 'drag end total=' | tail -1 | sed 's/^.*total=//;s/px.*//')
echo "PY_after=$PY2 engine_total=${T}px"
echo "dPY=$((PY - PY2))"
