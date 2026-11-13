#!/system/bin/sh
PKG=com.dennis.gamepadmouse
TARGET=com.example.piliplus
echo "== set immersive policy, then cold-start the app =="
settings put global policy_control "immersive.full=$TARGET"
settings get global policy_control
am force-stop $TARGET
sleep 1
monkey -p $TARGET -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 8
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$F" /data/local/tmp/imm.png; chmod 666 /data/local/tmp/imm.png
echo "shot=$(stat -c%s /data/local/tmp/imm.png)"
