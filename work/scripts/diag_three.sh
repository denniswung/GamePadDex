#!/system/bin/sh
# 三件事的现状诊断：居中 / 杀应用 / 电源键
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
hover(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p'; }
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
wm dismiss-keyguard >/dev/null 2>&1
sleep 1
echo "唤醒: $(dumpsys power | grep -m1 -o 'mWakefulness=[A-Za-z]*')  size=$(wm size | tr '\n' ' ')"

am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2
echo "焦点: $(dumpsys window | grep mCurrentFocus | tail -1)"

# ---------- 1) 居中 ----------
$VG stick 0 20000 400 2000 >/dev/null 2>&1
sleep 0.3
$VG stick 4 20000 400 0 >/dev/null 2>&1
sleep 0.4
echo "A 起点 hover: $(hover)"
logcat -c
$VG key 317 100 1000 >/dev/null 2>&1
sleep 0.5
echo "  引擎: $(logcat -d -s DexPad | grep -a 'center pointer' | tail -1 | sed 's/^.*DexPad  : //')"
logcat -c
$VG stick 0 800 100 0 >/dev/null 2>&1
sleep 0.4
echo "B 居中后 hover: $(hover)  (期望约 1280,800)"

# ---------- 2) 杀应用 ----------
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1.5
echo "--- 前台: $(dumpsys activity activities | grep -m1 topResumedActivity) ---"
echo "--- 助手 t/f 输出 ---"
: > /data/adb/gpm/helper.log
hcmd "t"; sleep 0.8
hcmd "f"; sleep 1.2
grep -aE 'TOP|FORCE_STOP|FORCE_KILL' /data/adb/gpm/helper.log | tail -5
echo "--- 设置是否还活着 ---"
pidof com.android.settings >/dev/null && echo "settings 进程仍在" || echo "settings 已死"

# ---------- 3) 电源键 ----------
echo "--- 电源键（助手 p 命令）---"
: > /data/adb/gpm/helper.log
hcmd "p"; sleep 1.5
grep -a 'POWER' /data/adb/gpm/helper.log | tail -2
echo "唤醒状态: $(dumpsys power | grep -m1 -o 'mWakefulness=[A-Za-z]*')"
