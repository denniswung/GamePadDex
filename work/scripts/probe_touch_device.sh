#!/system/bin/sh
PKG=com.dennis.dexpad
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }

# 先创建触摸设备
hcmd "q 2560 1600" >/dev/null 2>&1; sleep 0.4
hcmd "k 100 100 1" >/dev/null 2>&1; sleep 0.3; hcmd "k 100 100 0" >/dev/null 2>&1; sleep 0.5

echo "=== kernel 设备节点 ==="
grep -A4 -i 'Gamepad Touch Panel' /proc/bus/input/devices

echo "=== 框架侧识别结果 ==="
dumpsys input 2>/dev/null | grep -A12 -i 'Gamepad Touch Panel' | grep -iE 'Sources|Classes|Keyboard|Viewport|Axes|Device [0-9]+:|Name' | head -12

echo "=== 该设备的事件节点 ==="
EV=$(grep -A3 -i 'Gamepad Touch Panel' /proc/bus/input/devices | grep -o 'event[0-9]*' | head -1)
echo "node=$EV"
if [ -n "$EV" ]; then
  echo "--- 注入一次点击，抓原始事件 ---"
  ( timeout 2 getevent -l /dev/input/$EV > /data/local/tmp/touch_ev.txt 2>&1 & )
  sleep 0.4
  hcmd "k 100 100 1"; sleep 0.3; hcmd "k 100 100 0"; sleep 1.2
  cat /data/local/tmp/touch_ev.txt | head -20
fi
