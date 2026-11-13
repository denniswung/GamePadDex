#!/system/bin/sh
# try hard to wake the displays, then dump the UI tree of the DeX display
input keyevent KEYCODE_WAKEUP
sleep 1
input keyevent 82            # menu: dismiss simple keyguard
sleep 1
wm dismiss-keyguard 2>/dev/null
sleep 1
dumpsys display 2>/dev/null | grep -m3 mScreenState
rm -f /data/local/tmp/ui.xml
uiautomator dump /data/local/tmp/ui.xml 2>&1 | tail -2
if [ -f /data/local/tmp/ui.xml ]; then
    echo "== caption candidates =="
    tr '>' '\n' < /data/local/tmp/ui.xml | grep -iE 'fullscreen|full screen|maximize|最大化|全屏|close|minimi' | head -12
    echo "== any node with bounds in the top strip =="
    tr '>' '\n' < /data/local/tmp/ui.xml | grep -E 'bounds="\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]"' | head -8
fi
