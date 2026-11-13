import sqlite3
db = r"E:\Dennis\GamePadDex复刻\work\lsp\m9.db"
apk = "/data/app/~~rirnOs6Zr8pHcEjwpUevJA==/com.dennis.dexfs-pIbgg65gtHnA5TH5gugfvA==/base.apk"
con = sqlite3.connect(db); cur = con.cursor()
cur.execute("update modules set apk_path=?, enabled=1 where module_pkg_name='com.dennis.dexfs'", (apk,))
print("rows:", list(cur.execute("select mid,module_pkg_name,enabled,substr(apk_path,1,45) from modules where module_pkg_name='com.dennis.dexfs'")))
con.commit(); con.close()