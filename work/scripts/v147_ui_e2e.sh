#!/system/bin/sh
# v1.47 UI end-to-end: export / profile save / profile load through the real UI
PKG=com.dennis.dexpad
PASS=0; FAIL=0
ok()  { echo "PASS  $*"; PASS=$((PASS+1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL+1)); }
dump() { uiautomator dump --compressed /data/local/tmp/ui_e2e.xml >/dev/null 2>&1; }
node_xy() {
    tr '>' '\n' < /data/local/tmp/ui_e2e.xml 2>/dev/null |
        grep "text=\"$1" | head -1 |
        sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'
}
tap_text() {
    bb=$(node_xy "$1")
    [ -z "$bb" ] && return 1
    set -- $bb
    input tap $(( ($1 + $3) / 2 )) $(( ($2 + $4) / 2 ))
    return 0
}
ensure_activity() {
    if ! dumpsys activity activities 2>/dev/null | grep -q 'topResumedActivity.*com.dennis.dexpad/.ConfigActivity'; then
        am start -W -n $PKG/.ConfigActivity >/dev/null 2>&1
        sleep 1.5
    fi
}
scroll_to() {
    ensure_activity
    i=0
    while [ $i -lt 10 ]; do
        dump
        [ -n "$(node_xy "$1")" ] && return 0
        input swipe 1300 1300 1300 500 200
        sleep 0.6
        i=$((i+1))
    done
    return 1
}
PREFS=/data/misc/f7a4f515-2be2-4c14-959e-dc82d9b3e434/prefs/$PKG/dexpad.xml
CFG=/data/data/$PKG/files/dexpad-config.json

wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake
input keyevent KEYCODE_HOME >/dev/null 2>&1
sleep 0.8
rm -f $CFG
am start -W -n $PKG/.ConfigActivity >/dev/null 2>&1
sleep 2.5
ok "UI opened"

# ---------- 1. 导出配置 ----------
ensure_activity
if scroll_to "导出配置"; then
    ok "export row visible"
    tap_text "导出配置"
    sleep 1.5
    if [ -s $CFG ]; then
        SZ=$(wc -c < $CFG)
        if grep -q 'btn_a' $CFG && grep -q 'mix_0_keys' $CFG; then
            ok "UI export wrote a complete snapshot (${SZ}B)"
        else
            bad "UI export content ($SZ B, incomplete)"
        fi
    else
        bad "UI export file missing"
    fi
else
    bad "export row not reachable"
fi

# ---------- 2. 保存 Profile (the name is pre-filled: one tap) ----------
ensure_activity
if scroll_to "保存为 Profile"; then
    tap_text "保存为 Profile"
    sleep 1.2
    dump
    if grep -q 'class="android.widget.EditText"' /data/local/tmp/ui_e2e.xml; then
        tap_text "确定" || input keyevent KEYCODE_ENTER
        sleep 1.5
        if grep -q 'name="profiles".*profile[0-9]' $PREFS 2>/dev/null; then
            NAME=$(sed -n 's/.*name="profiles">\([^<]*\)<.*/\1/p' $PREFS | head -1)
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

# ---------- 3. 加载 Profile ----------
# close the profile dialog only if it is still on screen
dump
if grep -q 'class="android.widget.EditText"' /data/local/tmp/ui_e2e.xml; then
    input keyevent KEYCODE_BACK >/dev/null 2>&1
    sleep 0.6
fi
ensure_activity
if scroll_to "加载 Profile"; then
    tap_text "加载 Profile"
    sleep 1.2
    dump
    NAME=$(sed -n 's/.*name="profiles">\([^<]*\)<.*/\1/p' $PREFS 2>/dev/null | head -1)
    NAME=${NAME%%,*}
    [ -z "$NAME" ] && NAME=profile1
    if tap_text "$NAME"; then
        sleep 1.5
        ok "UI load profile (tapped $NAME)"
    else
        bad "load profile list has no $NAME"
    fi
else
    bad "load profile row not reachable"
fi

input keyevent KEYCODE_BACK >/dev/null 2>&1
sleep 1
if [ -n "$(pidof $PKG)" ] && sh /data/local/tmp/dexpad_precondition.sh >/dev/null 2>&1; then
    ok "engine healthy after UI operations"
else
    bad "engine unhealthy after UI operations"
fi

input keyevent KEYCODE_HOME >/dev/null 2>&1
echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
