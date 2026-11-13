import sys, io

p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()
old = '''# a fullscreen launcher may swallow the shade gesture: test it in Settings
am force-stop com.android.settings >/dev/null 2>&1
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2'''
new = '''# a fullscreen launcher may swallow the shade gesture: test it in Settings
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
svc power stayon true >/dev/null 2>&1
am force-stop com.android.settings >/dev/null 2>&1
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 3
WAKE2=$(dumpsys power 2>/dev/null | grep -m1 'mWakefulness=' | sed 's/.*mWakefulness=//')
TOP2=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')'''
assert old in s
s = s.replace(old, new, 1)
old2 = '''    bad "M2 notification shade ($SW, $M3)"'''
new2 = '''    bad "M2 notification shade ($SW, $M3, wake=$WAKE2 top=$TOP2)"'''
assert old2 in s
s = s.replace(old2, new2, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
