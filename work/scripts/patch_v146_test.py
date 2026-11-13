import io
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v146_checklist.sh"
s = io.open(p, encoding="utf-8").read()

s = s.replace("log() { logcat -d -s DexPad 2>/dev/null; }",
              "log() { logcat -d -s DexPad -s DexPadDebug 2>/dev/null; }")

s = s.replace('''# long press must not also fire the single action (a = left_click)''',
'''setpref lng_x none
setpref lng_a none
# long press must not also fire the single action (a = left_click)''')

start = s.index("# ---- 2. combo leader / inheritance ----")
end = s.index("# ---- 3. X/Y sensitivity ----")
new = '''# ---- 2. combo leader / inheritance (A is visible to the app; d-pad is native) ----
setpref mix_0_keys "x+a";   setpref mix_0_action volume_up
setpref mix_1_keys "a+x";   setpref mix_1_action volume_down
sleep 0.6
logcat -c
L=$(hcount)
$VG combo 307 304 700 2500 >/dev/null 2>&1
sleep 0.6
if hl "$L" | grep -q 'KEYON 0 24' && log | grep -q 'mix 0 x+a -> volume_up (direct)'; then
    ok "C-14 leader X -> direct slot"
else
    bad "combo leader direct (key=$(hl "$L" | grep -c 'KEYON 0 24') direct=$(log | grep -c direct))"
fi

logcat -c
L=$(hcount)
$VG combo 304 307 1200 2500 >/dev/null 2>&1
sleep 0.8
if hl "$L" | grep -q 'KEYON 0 25' && log | grep -q 'mix 1 a+x -> volume_down (direct)'; then
    ok "C-14 leader A -> independent slot"
else
    bad "combo leader independent (key=$(hl "$L" | grep -c 'KEYON 0 25') mix1=$(log | grep -c 'mix 1'))"
fi

setpref mix_1_action none
sleep 0.5
logcat -c
L=$(hcount)
$VG combo 304 307 1200 2500 >/dev/null 2>&1
sleep 0.8
if log | grep -q 'inherited' && hl "$L" | grep -q 'KEYON 0 24'; then
    ok "C-15 equivalent inheritance"
else
    bad "combo inheritance (inh=$(log | grep -c inherited) key=$(hl "$L" | grep -c 'KEYON 0 24'))"
fi

'''
s = s[:start] + new + s[end:]

s = s.replace('$VG stick 3 20000 400 2500 >/dev/null 2>&1', '$VG stick 0 20000 400 2500 >/dev/null 2>&1')
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
