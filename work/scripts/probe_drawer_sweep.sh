#!/system/bin/sh
input keyevent KEYCODE_HOME
sleep 2
screencap -p /sdcard/base.png
base=$(ls -l /sdcard/base.png | awk '{print $5}')
echo "base=$base"
try() {
    input keyevent KEYCODE_HOME
    sleep 1
    input swipe "$1" "$2" "$1" "$3" "$4"
    sleep 1.5
    screencap -p /sdcard/try.png
    s=$(ls -l /sdcard/try.png | awk '{print $5}')
    if [ "$s" -lt 800000 ]; then r=OPEN; else r=closed; fi
    echo "x=$1 y=$2->$3 ms=$4 size=$s $r"
}
try 1280 1400 400 200
try 1280 1400 700 300
try 1280 1300 500 200
try 640 1400 400 200
try 1280 1500 500 400
