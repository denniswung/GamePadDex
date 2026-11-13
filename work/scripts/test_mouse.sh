#!/system/bin/sh
cur() {
  dumpsys window windows 2>/dev/null | grep -A1 "com.dennis.gamepadmouse}" | grep -E "mAttrs=" | head -4
}
echo "== windows before ==" ; cur
echo "== send L3 (toggle) =="
/data/local/tmp/vgpad key 106 120 2>/dev/null
sleep 1
echo "== windows after toggle ==" ; cur
echo "== log =="
logcat -d -s GpmService:V GpmPointer:V GpmRootInput:V 2>/dev/null | tail -12
echo "== move left stick right =="
/data/local/tmp/vgpad stick 0 30000 1500 2>/dev/null
echo "== windows after stick ==" ; cur
echo "== log2 =="
logcat -d -s GpmService:V GpmPointer:V 2>/dev/null | tail -8
