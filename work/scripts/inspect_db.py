import sqlite3, sys

path = sys.argv[1] if len(sys.argv) > 1 else "fas.db"
con = sqlite3.connect(path)
tables = [r[0] for r in con.execute("select name from sqlite_master where type='table'")]
print("tables:", tables)
for t in tables:
    try:
        cols = [c[1] for c in con.execute(f"pragma table_info({t})")]
        rows = con.execute(f"select * from {t} limit 5").fetchall()
        print(f"\n== {t} {cols}")
        for r in rows:
            print(r)
    except Exception as e:
        print(t, "ERR", e)
