#!/system/bin/sh
PKG=com.dennis.dexpad
pos() { dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1; }
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.5
dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity
echo "pos0: $(pos)"
/data/local/tmp/vgpad key 317 100 2500 >/dev/null 2>&1
sleep 3.4
echo "pos1(after L3): $(pos)"
/data/local/tmp/vgpad stick 0 20000 300 2500 >/dev/null 2>&1
sleep 0.8
echo "pos2(after LY): $(pos)"
/data/local/tmp/vgpad stick 3 20000 300 2500 >/dev/null 2>&1
sleep 0.8
echo "pos3(after RX): $(pos)"
logcat -d -s DexPad 2>/dev/null | tail -4
