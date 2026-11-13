#!/system/bin/sh
# 验证：销毁虚拟鼠标设备能否让系统指针消失
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad

ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 3
am start -n com.dennis.padtest/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 1.5

$VG key 317 100 2000 >/dev/null 2>&1   # 居中，让指针在屏幕中间
sleep 1
screencap -p /data/local/tmp/h1.png

echo "--- 发送 h（销毁虚拟鼠标）---"
am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd h >/dev/null 2>&1
sleep 1.5
screencap -p /data/local/tmp/h2.png
grep -a 'POINTER' /data/adb/gpm/helper.log | tail -1

echo "--- 发送 j（恢复虚拟鼠标）---"
am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd j >/dev/null 2>&1
sleep 1.5
screencap -p /data/local/tmp/h3.png
grep -a 'POINTER' /data/adb/gpm/helper.log | tail -1

echo "sizes: $(wc -c < /data/local/tmp/h1.png) $(wc -c < /data/local/tmp/h2.png) $(wc -c < /data/local/tmp/h3.png)"
