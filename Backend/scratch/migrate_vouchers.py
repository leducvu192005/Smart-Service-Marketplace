import sqlite3

conn = sqlite3.connect('smart_service.db')
cur = conn.cursor()

# Check existing columns in vouchers
cur.execute('PRAGMA table_info(vouchers)')
cols = [r[1] for r in cur.fetchall()]
print('Existing voucher columns:', cols)

# Add missing columns if not exists
new_cols = [
    ('discount_value', 'REAL'),
    ('discount_type', 'TEXT DEFAULT "fixed"'),
    ('max_uses', 'INTEGER'),
    ('used_count', 'INTEGER DEFAULT 0'),
]
for col, ctype in new_cols:
    if col not in cols:
        try:
            cur.execute(f'ALTER TABLE vouchers ADD COLUMN {col} {ctype}')
            print(f'Added column: {col}')
        except Exception as e:
            print(f'Skip {col}: {e}')
    else:
        print(f'Column already exists: {col}')

conn.commit()
conn.close()
print('Migration complete!')
