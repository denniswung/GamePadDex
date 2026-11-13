import sqlite3
db = r"E:\Dennis\GamePadDex复刻\work\lsp\m3.db"
con = sqlite3.connect(db); cur = con.cursor()
cur.execute("update modules set enabled=0 where module_pkg_name='com.dennis.dexfs'")
con.commit()
for r in cur.execute("select mid,module_pkg_name,enabled from modules where module_pkg_name like '%dexfs%'"):
    print("module:", r)
con.close()