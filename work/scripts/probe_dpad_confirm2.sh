#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }

wake; sleep 1
echo "=== 0) DPAD_CENTER 是否能真的确认：设置列表 → 焦点 → KEY_OK(352) ==="
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
echo "before: $(top)"
input keyevent 20 >/dev/null 2>&1; sleep 0.3   # 系统方向键下（建立焦点）
hcmd "K 352 1"; sleep 0.08; hcmd "K 352 0"
sleep 1.5
echo "after KEY_OK: $(top)"

echo
echo "=== 1) d-pad 后 2 秒按 A（原来窗口 1.2s 会失效）==="
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
logcat -c
$VG hat 0 1 250 >/dev/null 2>&1
sleep 2.2
$VG key 304 120 800 >/dev/null 2>&1
sleep 1.5
echo "engine: $(logcat -d -s DexPad | grep -aE 'A pressed|A -> DPAD_CENTER|left button down|native navigation' | tail -5 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "after: $(top)"

echo
echo "=== 2) d-pad 后 5 秒按 A ==="
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
logcat -c
$VG hat 0 1 250 >/dev/null 2>&1
sleep 5
$VG key 304 120 800 >/dev/null 2>&1
sleep 1.5
echo "engine: $(logcat -d -s DexPad | grep -aE 'A pressured|A pressed|A -> DPAD_CENTER|left button down' | tail -4 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "after: $(top)"

echo
echo "=== 3) d-pad 后用左摇杆 = 回到鼠标模式，A 变回点击 ==="
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
logcat -c
$VG hat 0 1 250 >/dev/null 2>&1
sleep 0.3
$VG stick 0 8000 300 0 >/dev/null 2>&1
sleep 0.6
$VG key 304 120 800 >/dev/null 2>&1
sleep 1.2
echo "engine: $(logcat -d -s DexPad | grep -aE 'A pressed|A -> DPAD_CENTER|left button down|OFF \(stick moved\)' | tail -4 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
