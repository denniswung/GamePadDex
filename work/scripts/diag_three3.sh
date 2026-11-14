#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }
btn(){ $VG key 309 100 800 >/dev/null 2>&1; }   # 309 = BTN_MODE? 先用 SHARE=310? 这里只做开关

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1
sleep 1
echo "=== 打开监听开关 ==="
am broadcast -a $PKG.MODE -n $PKG/.DebugReceiver --ez enabled true >/dev/null 2>&1
sleep 1.5
logcat -c
$VG stick 0 5000 200 0 >/dev/null 2>&1
sleep 0.5
echo "mode 状态: $(logcat -d -s DexPad | grep -aE 'mouse mode|mode=' | tail -2 | tr '\n' ' ')"

echo
echo "=== 1) L3 居中（mode 开） ==="
logcat -c
$VG key 317 100 1000 >/dev/null 2>&1
sleep 1
logcat -d -s DexPad | grep -a 'center pointer' | tail -2

echo
echo "=== 2) 电源键 p（先看它会不会卡住助手） ==="
: > /data/adb/gpm/helper.log
hcmd "p"
sleep 3
echo "  helper 是否有 POWER: $(grep -ac 'POWER' /data/adb/gpm/helper.log)"
echo "  试探助手是否还活着（发 t）:"
hcmd "t"
sleep 3
echo "  helper 最近 3 行:"; tail -3 /data/adb/gpm/helper.log

echo
echo "=== 3) 杀前台（settings） ==="
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
echo "  前台: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/\/.*//')"
: > /data/adb/gpm/helper.log
hcmd "f"
sleep 5
grep -aE 'FORCE_STOP|FORCE_KILL|none' /data/adb/gpm/helper.log | tail -3
pidof com.android.settings >/dev/null && echo "  settings 仍在（没杀掉）" || echo "  settings 已死"
