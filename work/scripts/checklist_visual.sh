#!/system/bin/sh
# extra visual checks: B4 wheel scroll, D3 horizontal swipe
D=4630946213010294403
input keyevent KEYCODE_WAKEUP
svc power stayon true >/dev/null 2>&1

# B4: wheel scroll in a list
am start -n me.zhanghai.android.files/.filelist.FileListActivity >/dev/null 2>&1
sleep 2
screencap -p -d $D /sdcard/w1.png
/data/local/tmp/vgpad key 310 900 3000 >/dev/null 2>&1
sleep 1
screencap -p -d $D /sdcard/w2.png
echo "B4 wheel: $(ls -l /sdcard/w1.png /sdcard/w2.png | awk '{print $5, $8}' | tr '\n' ' ')"

# D3: X+RB horizontal swipe
L=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad key 307 5000 2600 >/dev/null 2>&1 &
sleep 3.2
/data/local/tmp/vgpad key 311 200 2600 >/dev/null 2>&1
sleep 1.5
tail -n "+$((L + 1))" /data/adb/gpm/helper.log | grep -E 'SWIPE .*-> .*' | tail -2
wait
svc power stayon false >/dev/null 2>&1
