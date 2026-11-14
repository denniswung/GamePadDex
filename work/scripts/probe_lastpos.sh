#!/system/bin/sh
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' "$XML" 2>/dev/null | sed 's/.*value="//;s/"//'; }
wake; sleep 1
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }

am force-stop $PAD; sleep 1
am start -n $PAD/.ui.ProbeActivity >/dev/null 2>&1
sleep 2.5
$VG key 317 100 1200 >/dev/null 2>&1     # 先居中（1280,800）
sleep 1.2
logcat -c; : > /data/adb/gpm/helper.log
echo "=== 1) 把光标移动到别处（偏右下）==="
$VG stick 0 20000 700 2000 >/dev/null 2>&1
$VG stick 1 20000 500 0 >/dev/null 2>&1
sleep 0.5
LAST=$(logcat -d -s DexPad | grep -a 'ptr move' | tail -1)
echo "最后估算: $LAST"
EST=$(echo "$LAST" | sed -n 's/.*at \([0-9]*\),\([0-9]*\)/x=\1 y=\2/p')
echo "估算坐标: $EST"
echo "padtest 真实光标: $(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -1)"

echo
echo "=== 2) 空闲 10 秒让指针隐藏 ==="
sleep 10
logcat -c; : > /data/adb/gpm/helper.log
echo "=== 3) 轻推摇杆让指针恢复，看是否回到上次位置 ==="
$VG stick 0 3000 200 2000 >/dev/null 2>&1
sleep 1.2
echo "engine: $(logcat -d -s DexPad | grep -aE 'pointer shown|restored' | tail -2 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "helper: $(grep -a 'POSPTR' /data/adb/gpm/helper.log | tail -1)"
sleep 0.5
echo "padtest 真实光标: $(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -2 | tr '\n' '|')"
echo
echo "=== 4) 点一下看落点 ==="
logcat -c
$VG key 304 120 700 >/dev/null 2>&1
sleep 1
echo "padtest click: $(logcat -d -s PadProbe | grep -a 'click-down' | tail -1)"
