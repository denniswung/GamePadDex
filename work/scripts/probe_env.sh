#!/system/bin/sh
T=/data/local/tmp/envt.xml
echo "== default env =="
uiautomator dump --compressed $T 2>&1 | tail -1
echo "== env -i =="
env -i /system/bin/uiautomator dump --compressed $T 2>&1 | tail -1
echo "== env -i + LD_LIBRARY_PATH =="
env -i LD_LIBRARY_PATH=/apex/com.android.art/lib64:/apex/com.android.i18n/lib64:/system/lib64:/system_ext/lib64 \
  /system/bin/uiautomator dump --compressed $T 2>&1 | tail -1
echo "== env -i + ANDROID_ROOT/DATA =="
env -i ANDROID_ROOT=/system ANDROID_DATA=/data \
  LD_LIBRARY_PATH=/apex/com.android.art/lib64:/apex/com.android.i18n/lib64:/system/lib64:/system_ext/lib64 \
  /system/bin/uiautomator dump --compressed $T 2>&1 | tail -1
echo "== su -c =="
su -c "uiautomator dump --compressed $T" 2>&1 | tail -1
echo "== current LD_LIBRARY_PATH =="
echo "$LD_LIBRARY_PATH"
echo "== BOOTCLASSPATH len =="
echo "${#BOOTCLASSPATH}"
