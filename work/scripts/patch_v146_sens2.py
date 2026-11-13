import io
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v146_checklist.sh"
s = io.open(p, encoding="utf-8").read()

start = s.index("# ---- 3. X/Y sensitivity ----")
end = s.index("# ---- 4. export / profile ----")
new = '''# ---- 3. X/Y sensitivity (measured from the engine's own pointer trail) ----
setpref mix_0_action none; setpref mix_1_action none
ptravel() { # $1 = sens_x percent -> sum of |dx|+|dy| logged while pushing LY
    setprefi sens_x "$1"; sleep 0.6
    logcat -c
    /data/local/tmp/vgpad stick 0 20000 900 2500 >/dev/null 2>&1
    sleep 0.8
    logcat -d -s DexPad 2>/dev/null | grep 'ptr move' |
        awk '{for(i=1;i<=NF;i++){if($i ~ /^dx=/){sub("dx=","",$i); dx=$i} if($i ~ /^dy=/){sub("dy=","",$i); dy=$i}} if(dx<0)dx=-dx; if(dy<0)dy=-dy; s+=dx+dy} END{printf "%.0f", s+0}'
}
DA=0; DB=0
for attempt in 1 2 3; do
    DA=$(ptravel 100)
    DB=$(ptravel 50)
    [ -n "$DA" ] && [ "$DA" -gt 0 ] && break
    sleep 0.5
done
if [ -n "$DA" ] && [ "$DA" -gt 0 ] && [ "$DB" -lt $((DA * 70 / 100)) ]; then
    ok "S-11 X sensitivity 50% (trail $DB < $DA)"
else
    bad "S-11 sens (trail $DA vs $DB)"
fi
setprefi sens_x 100
sleep 0.4

'''
s = s[:start] + new + s[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
