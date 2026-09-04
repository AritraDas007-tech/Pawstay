import sqlite3
conn = sqlite3.connect('pawstay.db')
cursor = conn.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [r[0] for r in cursor.fetchall()]
print("Tables:", tables)
for table in tables:
    cursor.execute(f"PRAGMA table_info({table})")
    cols = [r[1] for r in cursor.fetchall()]
    print(f"{table} columns: {cols}")

# Check user count and sample data
cursor.execute("SELECT id, email, role, is_verified, password_hash IS NOT NULL FROM users LIMIT 5")
rows = cursor.fetchall()
print("\nUsers:")
for r in rows:
    print(f"  id={r[0]}, email={r[1]}, role={r[2]}, verified={r[3]}, has_password={r[4]}")

conn.close()
