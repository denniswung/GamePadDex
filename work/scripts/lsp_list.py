import sqlite3
db = r"E:\Dennis\GamePadDex复刻\work\lsp\m7.db"
con = sqlite3.connect(db); cur = con.cursor()
print("modules:")
for r in cur.execute("select mid,module_pkg_name,enabled,apk_path from modules order by mid"):
    print("  ", r[0], r[1], "enabled=" + str(r[2]), r[3][:60])
print("scope rows:", list(cur.execute("select count(*) from scope"))[0])
print("dexfs scope:", list(cur.execute("select * from scope where mid in (select mid from modules where module_pkg_name like '%dexfs%')")))
con.close()