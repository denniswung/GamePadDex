#!/system/bin/sh
PKG=com.dennis.gamepadmouse
DEX=/data/adb/gpm/inject.dex
DISP=${1:-8}
COMBO=${2:-meta+enter}
snap() {
  am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
  sleep 2.5
  ls -t /data/data/$PKG/files/snap_*.png | head -1
}
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display $DISP >/dev/null 2>&1
sleep 6
echo "window before:"
dumpsys window windows 2>/dev/null | grep -E "mCurrentFocus|Frames: containing" | head -4
rm -f /data/data/$PKG/files/snap_*.png
A=$(snap); cp "$A" /data/local/tmp/a.png
echo "A=$(stat -c%s /data/local/tmp/a.png)"
echo "== inject $COMBO on display $DISP =="
echo "c $DISP $COMBO" | app_process -Djava.class.path=$DEX /system/bin ScrollInject --stdio 2>/data/local/tmp/inj.log
sleep 2
B=$(snap); cp "$B" /data/local/tmp/b.png
chmod 666 /data/local/tmp/a.png /data/local/tmp/b.png
echo "B=$(stat -c%s /data/local/tmp/b.png)"
echo "window after:"
dumpsys window windows 2>/dev/null | grep -E "mCurrentFocus|Frames: containing" | head -4
