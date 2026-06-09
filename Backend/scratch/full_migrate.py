import sys
sys.path.insert(0, '.')
from database import engine
import models

# Create all missing tables
models.Base.metadata.create_all(bind=engine)
print("create_all done")

import sqlite3
conn = sqlite3.connect('smart_service.db')
cur = conn.cursor()
cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = sorted([r[0] for r in cur.fetchall()])
print('ALL TABLES:', tables)

if 'vouchers' in tables:
    cur.execute('PRAGMA table_info(vouchers)')
    cols = [r[1] for r in cur.fetchall()]
    print('Voucher cols:', cols)
    # Add missing columns
    needed = [
        ('discount_value', 'REAL'),
        ('discount_type', 'TEXT DEFAULT "fixed"'),
        ('max_uses', 'INTEGER'),
        ('used_count', 'INTEGER DEFAULT 0'),
    ]
    for col, ctype in needed:
        if col not in cols:
            cur.execute(f'ALTER TABLE vouchers ADD COLUMN {col} {ctype}')
            print(f'Added: {col}')
        else:
            print(f'Already exists: {col}')
    conn.commit()
else:
    print('vouchers table NOT FOUND even after create_all')

conn.close()
print('Done!')
