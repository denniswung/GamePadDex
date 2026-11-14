#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad

echo "=== DebugReceiver 日志 ==="
logcat -d -s DexPadDebug | tail -5

echo "=== prefs 里的 btn_r3 / target_package ==="
grep -oE 'name="[a-z_0-9]+" value="[^"]*"' /data/misc/*/prefs/$PKG/dexpad.xml | grep -E 'btn_r3|target_package' || echo "  (没有) "

echo "=== 按 R3(318) ==="
logcat -c; : > /data/adb/gpm/helper.log
$VG key 318 120 900 >/dev/null 2>&1
sleep 1.5
logcat -d -s DexPad | tail -5
echo "--- helper KEY ---"
grep -a 'KEY ' /data/adb/gpm/helper.log | tail -2

echo "=== 直接调用 ActionRouter 的 open_app（映射到 A 试一下）==="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es button a --es mapped open_app >/dev/null 2>&1
sleep 0.6
logcat -c
$VG key 304 120 900 >/dev/null 2>&1
sleep 2
logcat -d -s DexPad | tail -4
echo "前台: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es button a --es mapped left_click >/dev/null 2>&1
