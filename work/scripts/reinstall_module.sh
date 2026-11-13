#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
echo "== modules present =="
ls /data/adb/modules/ | head -10
if [ ! -f "$MOD/module.prop" ]; then
  echo "== recreating the KSU module =="
  mkdir -p "$MOD"
  cp -f /data/local/tmp/mod_module.prop    "$MOD/module.prop"
  cp -f /data/local/tmp/mod_service.sh     "$MOD/service.sh"
  cp -f /data/local/tmp/mod_post-fs-data.sh "$MOD/post-fs-data.sh"
  cp -f /data/local/tmp/gpminput           "$MOD/gpminput"
  cp -f /data/local/tmp/inject.dex         "$MOD/inject.dex"
  chmod 644 "$MOD/module.prop" "$MOD/inject.dex"
  chmod 755 "$MOD/service.sh" "$MOD/post-fs-data.sh" "$MOD/gpminput"
fi
ls -l "$MOD"
mkdir -p /data/adb/gpm
cp -f "$MOD/gpminput" /data/adb/gpm/gpminput
chmod 755 /data/adb/gpm/gpminput
pkill -9 -f 'gpm_dex/service.sh'
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p; done
sleep 2
rm -f /data/adb/gpm/helper.lock /data/data/$PKG/files/gpm.sock
setsid sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
sleep 6
echo "helpers=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 9
logcat -d -s GpmService:I GpmRootInput:I 2>/dev/null | grep -E "auto-entered|mouse mode ON|helper ready|grabbed" | tail -4
