#!/system/bin/sh
PKG=com.dennis.gamepadmouse
echo "== policy_control immersive.full for piliplus =="
settings put global policy_control immersive.full=com.example.piliplus
settings get global policy_control
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 6
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1)
cp "$F" /data/local/tmp/fs4.png
chmod 666 /data/local/tmp/fs4.png
echo "shot=$(stat -c%s /data/local/tmp/fs4.png)"
