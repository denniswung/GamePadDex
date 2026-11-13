import sqlite3, os
db = r"E:\Dennis\GamePadDex复刻\work\lsp\m.db"
con = sqlite3.connect(db)
cur = con.cursor()
print("tables:", [r[0] for r in cur.execute("select name from sqlite_master where type='table'")])
for t in ("modules", "scope"):
    try:
        cols = [c[1] for c in cur.execute(f"pragma table_info({t})")]
        print(t, cols)
        for row in cur.execute(f"select * from {t} limit 3"):
            print("   ", row)
    except Exception as e:
        print(t, "ERR", e)
con.close()