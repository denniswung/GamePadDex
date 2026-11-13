#!/system/bin/sh
# one push right, one push right again, one push left; log swipe count each time
DEX=4632669078734337540
shot() { screencap -p -d $DEX /sdcard/$1; }
push() {
    logcat -c
    /data/local/tmp/vgpad stick 3 $1 1000 6000 >/dev/null 2>&1
    sleep 1
    echo "stick $1 -> swipes=$(logcat -d -s DexPad 2>/dev/null | grep -c 'swipe ')"
}
push 30000
shot sw6.png
push 30000
shot sw7.png
push -30000
shot sw8.png
echo done
