#!/system/bin/sh
PKG=com.dennis.dexpad
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.5
dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity
echo "before: $(dumpsys input | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)"
i=0
while [ $i -lt 12 ]; do
  am broadcast -a $PKG.INJECT -n $PKG/.DebugReceiver --es kind stick --ef lx 0 --ef ly 1 --ef rx 0 --ef ry 0 >/dev/null 2>&1
  sleep 0.15
  i=$((i+1))
done
echo "after:  $(dumpsys input | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)"
am broadcast -a $PKG.INJECT -n $PKG/.DebugReceiver --es kind stick --ef lx 0 --ef ly 0 --ef rx 0 --ef ry 0 >/dev/null 2>&1
logcat -d -s DexPadV2 2>/dev/null | grep -E 'ptr|reset' | tail -4
