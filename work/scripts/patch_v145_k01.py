import io
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v145_checklist.sh"
s = io.open(p, encoding="utf-8").read()
old = """$VG hat 0 1 400 2500 >/dev/null 2>&1
sleep 0.5
$VG key 304 200 2500 >/dev/null 2>&1
sleep 0.8
log | grep -q 'A -> DPAD_CENTER' && ok "K-01 D-pad then A = focus" || bad "K-01 A focus"
"""
new = """# 方向键与 A 必须在「焦点窗口」(默认 1.2s) 内连续发生才算激活焦点，
# 分两次独立注入会各自等 2.5s 设备就绪，窗口早已过期 —— 用同一次爆发验证。
$VG hatkey 1 304 2500 >/dev/null 2>&1
sleep 0.8
log | grep -q 'A -> DPAD_CENTER' && ok "K-01 D-pad+A 同爆发 = focus" || bad "K-01 A focus"
# 窗口过期后 A 必须恢复为左键
logcat -c
sleep 2.2
$VG key 304 200 0 >/dev/null 2>&1
sleep 0.8
if log | grep -q 'left button down' && ! log | grep -q 'A -> DPAD_CENTER'; then
    ok "K-01b 窗口过期后 A = 左键"
else
    bad "K-01b A after window"
fi
am start -n com.dennis.dexpad/.GamepadTestActivity >/dev/null 2>&1
sleep 1.0
"""
if old not in s:
    print("MISS"); raise SystemExit(1)
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
