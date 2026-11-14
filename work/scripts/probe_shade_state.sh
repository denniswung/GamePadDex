#!/system/bin/sh
PKG=com.dennis.dexpad
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
foc(){ dumpsys window 2>/dev/null | grep -m1 mCurrentFocus; }
panel(){ dumpsys window 2>/dev/null | grep -m1 'mExpandedPanel'; }
vis(){ dumpsys window 2>/dev/null | grep -c 'NotificationShade'; }
wake; sleep 1
input keyevent 4 >/dev/null 2>&1; sleep 1   # 先收起可能开着的面板
echo "closed:  $(foc)"
echo "  panel: $(panel)"
echo "  count: $(vis)"
screencap -p /data/local/tmp/a0.png 2>/dev/null
hcmd "N"
sleep 2
echo "opened:  $(foc)"
echo "  panel: $(panel)"
echo "  count: $(vis)"
screencap -p /data/local/tmp/a1.png 2>/dev/null
echo "sizes: $(wc -c < /data/local/tmp/a0.png) -> $(wc -c < /data/local/tmp/a1.png)"
input keyevent 4 >/dev/null 2>&1; sleep 1
echo "closed2: $(foc)"
