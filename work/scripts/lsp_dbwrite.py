import sqlite3
db = r"E:\Dennis\GamePadDex复刻\work\lsp\m.db"
apk = None
con = sqlite3.connect(db)
cur = con.cursor()
# find the installed apk path from the module list we saw earlier
apk_path = "/data/app/~~b0qtwCAb421cDmA1kb5SeQ==/com.dennis.dexfs-f9OpYCARxwMPDUNukVDXxg==/base.apk"
cur.execute("select mid from modules where module_pkg_name=?", ("com.dennis.dexfs",))
row = cur.fetchone()
if row:
    mid = row[0]
    cur.execute("update modules set apk_path=?, enabled=1 where mid=?", (apk_path, mid))
    print("updated existing module mid", mid)
else:
    cur.execute("insert into modules(module_pkg_name, apk_path, enabled, auto_include) values(?,?,1,0)",
                ("com.dennis.dexfs", apk_path))
    mid = cur.lastrowid
    print("inserted module mid", mid)
for pkg in ("system", "com.android.systemui"):
    cur.execute("insert or ignore into scope(mid, app_pkg_name, user_id) values(?,?,0)", (mid, pkg))
con.commit()
for r in cur.execute("select * from modules where module_pkg_name='com.dennis.dexfs'"):
    print("module:", r)
for r in cur.execute("select * from scope where mid=?", (mid,)):
    print("scope:", r)
con.close()