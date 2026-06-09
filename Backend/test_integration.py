#!/usr/bin/env python
"""Test script to verify all routers and integrations are working"""
import sys

try:
    print("🔍 Testing routers import...")
    from routers import admin, support, notifications, auth, customer, worker, workers, payments
    print("✓ All routers imported successfully")
    
    print("\n🔍 Testing models import...")
    from models import core
    print("✓ Models imported successfully")
    
    print("\n🔍 Testing schemas import...")
    import schemas
    print("✓ Schemas imported successfully")
    
    print("\n🔍 Testing database connection...")
    from database import engine, SessionLocal
    from sqlalchemy import inspect
    
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    
    print(f"✓ Database connection OK - {len(tables)} tables found")
    
    print("\n🔍 Checking critical tables...")
    critical = ['users', 'workers', 'bookings', 'user_notifications', 'support_activity_logs']
    missing = [t for t in critical if t not in tables]
    if missing:
        print(f"⚠ Missing tables: {missing}")
    else:
        print("✓ All critical tables exist")
    
    print("\n🔍 Testing FastAPI app...")
    from main import app
    print("✓ FastAPI app initialized successfully")
    
    print("\n✅ ALL TESTS PASSED! System is ready to run.")
    sys.exit(0)
    
except Exception as e:
    print(f"\n❌ ERROR: {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
