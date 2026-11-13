import sqlite3
db = r"E:\Dennis\GamePadDex复刻\work\lsp\m7.db"
con = sqlite3.connect(db); cur = con.cursor()
cur.execute("delete from scope where mid=29")
cur.execute("insert or ignore into scope(mid, app_pkg_name, user_id) values(29,'android',0)")
cur.execute("insert or ignore into scope(mid, app_pkg_name, user_id) values(29,'com.android.systemui',0)")
con.commit()
print("dexfs scope now:", list(cur.execute("select * from scope where mid=29")))
con.close()