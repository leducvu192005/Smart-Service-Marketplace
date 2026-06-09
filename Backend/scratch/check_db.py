import sqlite3

conn = sqlite3.connect('smart_service.db')
cur = conn.cursor()
cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [r[0] for r in cur.fetchall()]
print('Tables in DB:', tables)

# Check vouchers columns if exists
if 'vouchers' in tables:
    cur.execute('PRAGMA table_info(vouchers)')
    cols = [(r[1], r[2]) for r in cur.fetchall()]
    print('Voucher columns:', cols)
else:
    print('vouchers table NOT FOUND')
    # Add missing columns to whatever voucher-like table exists
    for t in tables:
        if 'vouch' in t.lower():
            print(f'Found similar table: {t}')

conn.close()
