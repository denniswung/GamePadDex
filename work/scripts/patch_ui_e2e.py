import io
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v147_ui_e2e.sh"
s = io.open(p, encoding="utf-8").read()

# a BACK press would finish the activity, not close a (non-existent) dialog
s = s.replace("""# ---------- 2. 保存 Profile ----------
input keyevent KEYCODE_BACK >/dev/null 2>&1
sleep 0.5
""", """# ---------- 2. 保存 Profile ----------
""")

s = s.replace("""# ---------- 3. 加载 Profile ----------
input keyevent KEYCODE_BACK >/dev/null 2>&1
sleep 0.6
""", """# ---------- 3. 加载 Profile ----------
# close the profile dialog only if it is still on screen
dump
if grep -q 'class="android.widget.EditText"' /data/local/tmp/ui_e2e.xml; then
    input keyevent KEYCODE_BACK >/dev/null 2>&1
    sleep 0.6
fi
""")

# make sure the activity is still resumed before each scroll section
s = s.replace("""scroll_to() {
    i=0""", """ensure_activity() {
    if ! dumpsys activity activities 2>/dev/null | grep -q 'topResumedActivity.*com.dennis.dexpad/.ConfigActivity'; then
        am start -W -n $PKG/.ConfigActivity >/dev/null 2>&1
        sleep 1.5
    fi
}
scroll_to() {
    ensure_activity
    i=0""")

# tap the row then re-open the page from the top for the next section
s = s.replace("""if scroll_to "保存为 Profile"; then""", """ensure_activity
if scroll_to "保存为 Profile"; then""")
s = s.replace("""if scroll_to "加载 Profile"; then""", """ensure_activity
if scroll_to "加载 Profile"; then""")
s = s.replace("""if scroll_to "导出配置"; then""", """ensure_activity
if scroll_to "导出配置"; then""")

io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
