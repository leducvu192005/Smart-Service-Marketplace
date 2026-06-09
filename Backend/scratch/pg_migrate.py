import sys
sys.path.insert(0, '.')

from database import engine, SQLALCHEMY_DATABASE_URL, is_supabase
from sqlalchemy import inspect, text
import models

print(f"DB Type: {'Supabase PostgreSQL' if is_supabase else 'SQLite'}")
print(f"DB URL prefix: {SQLALCHEMY_DATABASE_URL[:40]}...")

# Create all new tables
models.Base.metadata.create_all(bind=engine)
print("create_all done")

inspector = inspect(engine)
tables = sorted(inspector.get_table_names())
print(f"ALL TABLES ({len(tables)}): {tables}")

# Check and migrate vouchers
if 'vouchers' in tables:
    cols = [c['name'] for c in inspector.get_columns('vouchers')]
    print(f"Voucher columns: {cols}")
    
    needed = [
        ('discount_value', 'FLOAT'),
        ('discount_type', "VARCHAR(20) DEFAULT 'fixed'"),
        ('max_uses', 'INTEGER'),
        ('used_count', 'INTEGER DEFAULT 0'),
    ]
    with engine.begin() as conn:
        for col, ctype in needed:
            if col not in cols:
                try:
                    conn.execute(text(f'ALTER TABLE vouchers ADD COLUMN {col} {ctype}'))
                    print(f"Added column: {col}")
                except Exception as e:
                    print(f"Skip {col}: {e}")
            else:
                print(f"Already exists: {col}")
else:
    print("vouchers table NOT FOUND")

print("Migration complete!")
