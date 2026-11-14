#!/system/bin/sh
PKG=com.dennis.dexpad
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }
tap(){ hcmd "k $1 $2 1"; sleep 0.18; hcmd "k $1 $2 0"; sleep 0.45; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
echo "wm size: $(wm size | tr '\n' ' ')"
echo "rotation: $(dumpsys input 2>/dev/null | grep -m1 -o 'SurfaceOrientation: [0-9]')"

: > /data/adb/gpm/helper.log
hcmd "q 2560 1600"; sleep 0.6
grep -a 'TOUCH_SIZE' /data/adb/gpm/helper.log | tail -1

# 依次在几个已知点注入，看应用侧报告什么坐标
for pt in "0 0" "2560 0" "0 1600" "2560 1600" "1280 800"; do
  set -- $pt
  logcat -c
  tap "$1" "$2"
  R=$(logcat -d -s PadProbe | grep -iE 'touch-(down|up)' | head -1 | sed 's/^.*PadProbe: //')
  echo "注入 ($1,$2) -> $R"
done
