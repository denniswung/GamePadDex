#!/system/bin/sh
# per-app swipe profile check: one stick-up gesture per app, print TOP + SWIPE dy
check() {
    pkg="$1"; act="$2"; name="$3"
    am start -n "$pkg/$act" >/dev/null 2>&1
    sleep 4
    L=$(wc -l < /data/adb/gpm/helper.log)
    /data/local/tmp/vgpad stick 4 20000 700 3000 >/dev/null 2>&1
    sleep 1.5
    sw=$(tail -n +$((L + 1)) /data/adb/gpm/helper.log | grep 'SWIPE ' | tail -1)
    top=$(grep 'TOP ' /data/adb/gpm/helper.log | tail -1)
    echo "$name: $top | $sw"
}

check app.lawnchair .Launcher lawnchair
check com.example.piliplus .MainActivity piliplus
check com.ss.android.ugc.aweme .splash.SplashActivity douyin
check com.phoenix.read .activity.MainActivity hongguo
