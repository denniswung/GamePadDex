#!/system/bin/sh
for f in /data/data/com.dennis.dexpad/shared_prefs/dexpad.xml \
         /data/misc/f7a4f515-2be2-4c14-959e-dc82d9b3e434/prefs/com.dennis.dexpad/dexpad.xml; do
    echo "== $f"
    ls -l "$f" 2>&1
    grep -E 'force_phone|phone_mode' "$f" 2>&1
done
