#!/system/bin/sh
PKG=com.dennis.gamepadmouse
DEX=/data/adb/gpm/inject.dex
DISP=${1:-8}
X=${2:-2445}
Y=${3:-30}
snap() {
  am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
  sleep 2.5
  F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1)
  cp "$F" /data/local/tmp/$1
  chmod 666 /data/local/tmp/$1
  echo "$1=$(stat -c%s /data/local/tmp/$1)"
}
echo "== before =="
snap clk_before.png
echo "== click $X,$Y on display $DISP =="
echo "m $DISP $X $Y 1" | app_process -Djava.class.path=$DEX /system/bin ScrollInject --stdio 2>&1 | tail -2
sleep 2
echo "== after =="
snap clk_after.png
