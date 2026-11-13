#!/system/bin/sh
PKG=com.dennis.dexpad
px() { dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1; }
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.5
echo "before: $(px)"
am broadcast -a $PKG.INJECT -n $PKG/.DebugReceiver --es kind stick --ef lx 0 --ef ly 1 --ef rx 0 --ef ry 0 >/dev/null 2>&1
sleep 0.5
echo "after:  $(px)"
am broadcast -a $PKG.INJECT -n $PKG/.DebugReceiver --es kind stick --ef lx 0 --ef ly 0 --ef rx 0 --ef ry 0 >/dev/null 2>&1
logcat -d -s DexPadV2 2>/dev/null | tail -5
