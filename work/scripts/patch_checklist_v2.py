import io

p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/checklist_v2.sh"
s = io.open(p, encoding="utf-8").read()

# R1a: centre first, then push left so the pointer cannot be clamped at the edge
s = s.replace('''P0=$(pos)
/data/local/tmp/vgpad stick 0 20000 500 3000 >/dev/null 2>&1
sleep 1''', '''/data/local/tmp/vgpad key 317 100 3000 >/dev/null 2>&1
sleep 1
P0=$(pos)
/data/local/tmp/vgpad stick 0 -20000 500 3000 >/dev/null 2>&1
sleep 1''')

# K1c: one process, two quick presses on the same virtual pad
s = s.replace('''v2 --el double_window_ms 800; sleep 0.3
logcat -c
/data/local/tmp/vgpad key 304 60 3000 >/dev/null 2>&1
sleep 0.05
/data/local/tmp/vgpad key 304 60 3000 >/dev/null 2>&1
sleep 0.8''', '''v2 --el double_window_ms 280; sleep 0.3
logcat -c
/data/local/tmp/vgpad double 304 60 120 >/dev/null 2>&1
sleep 1.2''')

# K2/K3/K4: use the single-process chord helper
s = s.replace('''( /data/local/tmp/vgpad key 307 700 3000 >/dev/null 2>&1 & )
sleep 0.25
/data/local/tmp/vgpad key 304 120 3000 >/dev/null 2>&1
sleep 1.2
log | grep -q 'combo x+a -> volume_up' && ok "K2a X+A namespace" || bad "K2a X+A namespace"''',
'''/data/local/tmp/vgpad combo 307 304 500 >/dev/null 2>&1
sleep 1.2
log | grep -q 'combo x+a -> volume_up' && ok "K2a X+A namespace" || bad "K2a X+A namespace"''')

s = s.replace('''( /data/local/tmp/vgpad key 304 700 3000 >/dev/null 2>&1 & )
sleep 0.25
/data/local/tmp/vgpad key 307 120 3000 >/dev/null 2>&1
sleep 1.2
log | grep -q 'combo a+x -> volume_down' && ok "K2b A+X independent" || bad "K2b A+X independent"''',
'''/data/local/tmp/vgpad combo 304 307 500 >/dev/null 2>&1
sleep 1.2
log | grep -q 'combo a+x -> volume_down' && ok "K2b A+X independent" || bad "K2b A+X independent"''')

s = s.replace('''( /data/local/tmp/vgpad key 304 700 3000 >/dev/null 2>&1 & )
sleep 0.25
/data/local/tmp/vgpad key 307 120 3000 >/dev/null 2>&1
sleep 1.2
log | grep -q 'combo a+x -> volume_up' && ok "K3 A+X inherits X+A" || bad "K3 inheritance"''',
'''/data/local/tmp/vgpad combo 304 307 500 >/dev/null 2>&1
sleep 1.2
log | grep -q 'combo a+x -> volume_up' && ok "K3 A+X inherits X+A" || bad "K3 inheritance"''')

s = s.replace('''( /data/local/tmp/vgpad key 307 700 3000 >/dev/null 2>&1 & )
sleep 0.25
/data/local/tmp/vgpad key 304 120 3000 >/dev/null 2>&1
sleep 1.2
S=$(log | grep -c 'single a -> left_click')''',
'''/data/local/tmp/vgpad combo 307 304 500 >/dev/null 2>&1
sleep 1.2
S=$(log | grep -c 'single a -> left_click')''')

io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("checklist v2 updated")
