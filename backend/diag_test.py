"""Quick diagnostic test for backend endpoints"""
import sys
sys.path.insert(0, '.')

# Test 1: Can we import main?
try:
    # Don't run the app, just test imports
    from database.db import get_db, engine
    from database.models import User, OtpCode, Pet, Service, Booking, Review, Payment, Notification
    print("[OK] All model imports successful")
except Exception as e:
    print(f"[FAIL] Import error: {e}")
    import traceback; traceback.print_exc()

# Test 2: Can we create a DB session and query users?
try:
    from sqlalchemy.orm import sessionmaker
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    users = db.query(User).all()
    print(f"[OK] DB query OK - found {len(users)} users")
    
    # Test password check on a known user
    user = db.query(User).filter(User.email == 'aritradas99231@gmail.com').first()
    if user:
        print(f"[OK] Found user: {user.email}, role: {user.role}, verified: {user.is_verified}")
        result = user.check_password("Password123")
        print(f"[INFO] Password 'Password123' check: {result}")
    db.close()
except Exception as e:
    print(f"[FAIL] DB error: {e}")
    import traceback; traceback.print_exc()

# Test 3: Test schema migration code
try:
    from sqlalchemy import inspect, text
    inspector = inspect(engine)
    table_names = inspector.get_table_names()
    print(f"\n[OK] Tables: {table_names}")
    
    pets_cols = {col['name'] for col in inspector.get_columns('pets')}
    print(f"[OK] Pets columns: {pets_cols}")
    
    users_cols = {col['name'] for col in inspector.get_columns('users')}
    print(f"[OK] Users columns: {users_cols}")
except Exception as e:
    print(f"[FAIL] Schema inspect error: {e}")
    import traceback; traceback.print_exc()

# Test 4: Simulate login logic
try:
    from sqlalchemy.orm import sessionmaker
    from sqlalchemy import String
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    
    identifier = 'aritradas99231@gmail.com'
    user = db.query(User).filter(
        (User.email == identifier) | 
        (User.username == identifier)
    ).first()
    
    if user:
        print(f"\n[LOGIN SIM] Found user by email: {user.full_name}")
        print(f"[LOGIN SIM] Password hash exists: {bool(user.password_hash)}")
        pwd_ok = user.check_password("Aritra@123")
        print(f"[LOGIN SIM] Password check for 'Aritra@123': {pwd_ok}")
    else:
        print("[LOGIN SIM] User not found")
    db.close()
except Exception as e:
    print(f"[FAIL] Login simulation error: {e}")
    import traceback; traceback.print_exc()
