import sqlite3, sys
path = sys.argv[1]
pkg = sys.argv[2] if len(sys.argv) > 2 else "com.dennis.dexpad"
con = sqlite3.connect(path)
cols = [c[1] for c in con.execute("pragma table_info(ForcedAppStandby)")]
rows = con.execute("select * from ForcedAppStandby").fetchall()
print("cols:", cols)
for r in rows:
    if pkg in str(r):
        print("MATCH:", r)
print("total rows:", len(rows))
