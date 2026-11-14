#!/system/bin/sh
PKG=com.dennis.dexpad
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }

am force-stop $PKG; sleep 1
# 干净地重写 prefs：只保留必要项 + btn_y=open_app
cat > "$XML" <<'EOF'
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
    <boolean name="mode_on" value="true" />
    <boolean name="enabled" value="true" />
    <string name="target_package">com.android.settings</string>
    <string name="btn_y">open_app</string>
</map>
EOF
chmod 600 "$XML"
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
: > /data/adb/gpm/helper.log
logcat -c
/data/local/tmp/vgpad key 308 120 900 >/dev/null 2>&1
sleep 3
echo "--- 引擎 ---"
logcat -d -s DexPad | grep -aE 'button y|open app' | tail -4
echo "--- 助手 ---"
grep -a 'OPEN_APP' /data/adb/gpm/helper.log | tail -2
echo "--- 前台 ---"
dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity
