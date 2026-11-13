import sqlite3, sys
db = sqlite3.connect(r'E:\Dennis\GamePadDex复刻\work\probe\lspcfg\modules_config.db')
for (name,) in db.execute("select name from sqlite_master where type='table'"):
    print('TABLE', name)
    cols = [r[1] for r in db.execute('pragma table_info(%s)' % name)]
    print('  cols', cols)
    for row in db.execute('select * from %s' % name):
        print('  ', row)
