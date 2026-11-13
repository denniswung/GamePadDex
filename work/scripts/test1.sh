#!/system/bin/sh
LOG=/data/local/tmp/gpm_test.log
: > $LOG
logit() { echo "----- $* -----" >> $LOG; }
snap() {
  logit "$1"
  dumpsys window windows 2>/dev/null | grep -A2 "com.pkyul13.gamepadmouse}" | grep -E "Window #|mAttrs=" >> $LOG
  echo "[focus] $(dumpsys window 2>/dev/null | grep -m2 -E 'mCurrentFocus|mFocusedApp')" >> $LOG
  echo "[top8] $(dumpsys activity activities 2>/dev/null | grep -A1 'Display #8' | tail -1)" >> $LOG
}

snap "A: baseline"
logcat -c
echo "== toggle L3 ==" >> $LOG
/data/local/tmp/vgpad key 106 150 2>>$LOG
sleep 1
snap "B: after L3 toggle"
echo "== left stick X max ==" >> $LOG
/data/local/tmp/vgpad stick 0 30000 1200 2>>$LOG
sleep 0.5
snap "C: after left stick"
echo "== dpad up (HAT) ==" >> $LOG
/data/local/tmp/vgpad hat 0 -1 800 2>>$LOG
sleep 0.5
snap "D: after hat up"
echo "== button A ==" >> $LOG
/data/local/tmp/vgpad key 304 120 2>>$LOG
sleep 0.8
snap "E: after BTN_A"
echo "===== logcat (gamepad-related) =====" >> $LOG
logcat -d 2>/dev/null | grep -Ei "mouse|gamepad|dex|pointer|inputreader" | grep -vi "selinux" | tail -80 >> $LOG
echo "===== getevent device list =====" >> $LOG
getevent -pl 2>/dev/null | grep -E "add device|name:" | tail -8 >> $LOG
cat $LOG
