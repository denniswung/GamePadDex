import sqlite3
db = r"E:\Dennis\GamePadDex复刻\work\lsp\m11.db"
con = sqlite3.connect(db); cur = con.cursor()
mids = [r[0] for r in cur.execute("select mid from modules where module_pkg_name='com.dennis.dexfs'")]
for mid in mids:
    cur.execute("delete from scope where mid=?", (mid,))
    cur.execute("delete from modules where mid=?", (mid,))
con.commit()
print("removed mids:", mids)
print("modules now:", list(cur.execute("select mid,module_pkg_name,enabled from modules")))
con.close()