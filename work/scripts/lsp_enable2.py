import sqlite3
db = r"E:\Dennis\GamePadDex复刻\work\lsp\m5.db"
apk = "/data/app/~~z18S6Uu7RNdChP1mNsA9xg==/com.dennis.dexfs-OF9ckEgmIuqFRHVYk9YcIg==/base.apk"
con = sqlite3.connect(db); cur = con.cursor()
cur.execute("select mid from modules where module_pkg_name='com.dennis.dexfs'")
row = cur.fetchone()
if row:
    mid = row[0]
    cur.execute("update modules set apk_path=?, enabled=1 where mid=?", (apk, mid))
    print("updated mid", mid)
else:
    cur.execute("insert into modules(module_pkg_name, apk_path, enabled, auto_include) values(?,?,1,0)", ("com.dennis.dexfs", apk))
    mid = cur.lastrowid
    print("inserted mid", mid)
for pkg in ("system", "com.android.systemui"):
    cur.execute("insert or ignore into scope(mid, app_pkg_name, user_id) values(?,?,0)", (mid, pkg))
con.commit()
print(list(cur.execute("select mid,module_pkg_name,enabled from modules where module_pkg_name='com.dennis.dexfs'")))
print(list(cur.execute("select * from scope where mid=?", (mid,))))
con.close()