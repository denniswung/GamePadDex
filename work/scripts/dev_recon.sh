#!/system/bin/sh
echo "===== 1. who has gamepad event devices open ====="
for p in /proc/[0-9]*; do
  pid=$(basename "$p")
  for f in "$p"/fd/*; do
    l=$(readlink "$f" 2>/dev/null)
    case "$l" in
      *input/event*) echo "PID $pid [$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null)] -> $l" ;;
    esac
  done
done 2>/dev/null | grep -E 'event19|event1[0-9]' 
echo
echo "===== 2. all event fds by process ====="
for p in /proc/[0-9]*; do
  pid=$(basename "$p")
  for f in "$p"/fd/*; do
    l=$(readlink "$f" 2>/dev/null)
    case "$l" in
      *input/event*) echo "$pid|$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null)|$l" ;;
    esac
  done
done 2>/dev/null | sort -t'|' -k3 | head -40
echo
echo "===== 3. input devices with SOURCE flags ====="
dumpsys input 2>/dev/null | grep -A3 'Device [0-9]*:' | head -40
echo
echo "===== 4. dex state ====="
dumpsys activity 2>/dev/null | grep -iE 'mDexMode|DesktopMode|dexMode' | head -10
getprop | grep -iE 'dex' | head -20
echo
echo "===== 5. gamepadmouse process info ====="
ps -A -o PID,USER,PPID,ARGS | grep -i gamepadmouse
