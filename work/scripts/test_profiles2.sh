#!/system/bin/sh
check() {
    pkg="$1"; name="$2"
    monkey -p "$pkg" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
    sleep 5
    L=$(wc -l < /data/adb/gpm/helper.log)
    /data/local/tmp/vgpad stick 4 20000 700 3000 >/dev/null 2>&1
    sleep 1.5
    sw=$(tail -n +$((L + 1)) /data/adb/gpm/helper.log | grep 'SWIPE ' | tail -1)
    top=$(grep 'TOP ' /data/adb/gpm/helper.log | tail -1)
    echo "$name: $top | $sw"
}

check app.lawnchair lawnchair
check com.phoenix.read hongguo
check com.example.piliplus piliplus
