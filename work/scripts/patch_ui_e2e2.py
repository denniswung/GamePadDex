import io
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v147_ui_e2e.sh"
s = io.open(p, encoding="utf-8").read()

start = s.index("# ---------- 2. 保存 Profile ----------")
end = s.index("# ---------- 3. 加载 Profile ----------")
new = '''# ---------- 2. 保存 Profile (the name is pre-filled: one tap) ----------
ensure_activity
if scroll_to "保存为 Profile"; then
    tap_text "保存为 Profile"
    sleep 1.2
    dump
    if grep -q 'class="android.widget.EditText"' /data/local/tmp/ui_e2e.xml; then
        tap_text "确定" || input keyevent KEYCODE_ENTER
        sleep 1.5
        if grep -q 'name="profiles".*profile[0-9]' $PREFS 2>/dev/null; then
            NAME=$(sed -n 's/.*name="profiles">\\([^<]*\\)<.*/\\1/p' $PREFS | head -1)
            ok "UI save profile ($NAME saved)"
        else
            bad "UI save profile (prefs has no profile entry)"
        fi
    else
        bad "save profile dialog missing"
    fi
else
    bad "save profile row not reachable"
fi

'''
s = s[:start] + new + s[end:]

s = s.replace('''    if tap_text "uitest"; then
        sleep 1.5
        ok "UI load profile (tapped uitest)"
    else
        bad "load profile list has no uitest"
    fi''',
'''    NAME=$(sed -n 's/.*name="profiles">\\([^<]*\\)<.*/\\1/p' $PREFS 2>/dev/null | head -1)
    NAME=${NAME%%,*}
    [ -z "$NAME" ] && NAME=profile1
    if tap_text "$NAME"; then
        sleep 1.5
        ok "UI load profile (tapped $NAME)"
    else
        bad "load profile list has no $NAME"
    fi''')
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
