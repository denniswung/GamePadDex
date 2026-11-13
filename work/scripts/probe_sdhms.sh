#!/system/bin/sh
D=/data/data/com.sec.android.sdhms/databases
ls -l "$D" 2>&1
echo "== sqlite3 =="
which sqlite3 2>&1
echo "== xml prefs =="
ls -l /data/data/com.sec.android.sdhms/shared_prefs 2>&1 | head
