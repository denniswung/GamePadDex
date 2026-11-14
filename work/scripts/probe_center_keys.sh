#!/system/bin/sh
PKG=com.dennis.dexpad
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }

try(){  # $1=label  $2=shell-cmd
  am force-stop com.android.settings; sleep 1
  am start -a android.settings.SETTINGS >/dev/null 2>&1
  sleep 2.5
  input keyevent 20 >/dev/null 2>&1; sleep 0.4
  input keyevent 20 >/dev/null 2>&1; sleep 0.4
  B=$(top)
  eval "$2"
  sleep 1.6
  echo "$1: $B -> $(top)"
}

wake; sleep 1
echo "=== 对照：shell 域 input keyevent 23 (DPAD_CENTER) ==="
try "input 23" "input keyevent 23"

echo
echo "=== 候选1：uinput KEY_OK(352) ==="
try "K 352" "hcmd 'K 352 1'; sleep 0.08; hcmd 'K 352 0'"

echo
echo "=== 候选2：uinput KEY_ENTER(28) ==="
try "K 28" "hcmd 'K 28 1'; sleep 0.08; hcmd 'K 28 0'"

echo
echo "=== 候选3：uinput KEY_SELECT(353) ==="
try "K 353" "hcmd 'K 353 1'; sleep 0.08; hcmd 'K 353 0'"

echo
echo "=== 候选4：uinput KEY_KPENTER(96) ==="
try "K 96" "hcmd 'K 96 1'; sleep 0.08; hcmd 'K 96 0'"
