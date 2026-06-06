"""
Test script: Admin & Support API Flow Test
Run: python test_admin_support.py
"""
import sys
import io
import requests
import json

# Fix encoding for Windows terminal
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

BASE = "http://localhost:8000"
session = requests.Session()

def p(label, resp):
    ok = "OK" if resp.status_code < 300 else "FAIL"
    try:
        data = resp.json()
    except:
        data = resp.text
    print(f"[{ok}] [{resp.status_code}] {label}")
    if resp.status_code >= 400:
        print(f"   => Error: {data}")
    return data

def login(username, password):
    resp = session.post(f"{BASE}/auth/login", data={"username": username, "password": password})
    data = p(f"Login as: {username}", resp)
    if isinstance(data, dict) and "access_token" in data:
        session.headers.update({"Authorization": f"Bearer {data['access_token']}"})
    return data

def register(username, email, fullname, password, role="customer"):
    resp = requests.post(f"{BASE}/auth/register", json={
        "username": username, "email": email,
        "full_name": fullname, "password": password, "role": role
    })
    return p(f"Register [{role}]: {username}", resp)

print("=" * 60)
print("SMART SERVICE MARKETPLACE - ADMIN/SUPPORT FLOW TEST")
print("=" * 60)

# 1. Register admin
print("\n--- 1. Register Admin account ---")
register("admin_test", "admin_test@test.com", "System Admin", "admin123", "admin")

# 2. Login admin
print("\n--- 2. Login as Admin ---")
admin_data = login("admin_test", "admin123")
if not isinstance(admin_data, dict) or "access_token" not in admin_data:
    print("CRITICAL: Cannot login as admin. Stopping.")
    sys.exit(1)

# 3. Admin Dashboard
print("\n--- 3. Admin Dashboard ---")
resp = session.get(f"{BASE}/admin/dashboard")
data = p("GET /admin/dashboard", resp)
if resp.status_code == 200:
    print(f"   Users: {data.get('total_users',0)} | Workers: {data.get('total_workers',0)} | Bookings: {data.get('total_bookings',0)}")

# 4. Financial stats
print("\n--- 4. Financial Stats ---")
resp = session.get(f"{BASE}/admin/financial-stats")
data = p("GET /admin/financial-stats", resp)
if resp.status_code == 200:
    print(f"   Revenue: {data.get('total_revenue',0)} | System Net (10%): {data.get('system_net_revenue',0)}")
    print(f"   Withdrawn: {data.get('total_withdrawn',0)} | Wallet Sum: {data.get('wallet_balances_sum',0)}")

# 5. Create Support account
print("\n--- 5. Create Support account ---")
resp = session.post(f"{BASE}/admin/support-accounts", json={
    "username": "support_test",
    "email": "support_test@test.com",
    "full_name": "Support Staff One",
    "password": "support123"
})
p("POST /admin/support-accounts", resp)

# 6. Create Voucher
print("\n--- 6. Create Voucher ---")
resp = session.post(f"{BASE}/admin/vouchers", json={
    "code": "SALE2026",
    "discount_amount": 50.0,
    "expiry_date": "2026-12-31T23:59:59"
})
p("POST /admin/vouchers", resp)

# 7. Broadcast Notification
print("\n--- 7. Broadcast Notification ---")
resp = session.post(f"{BASE}/admin/notifications", json={
    "title": "Summer 2026 Promo",
    "message": "50% off all services in June!",
    "recipient_role": "all"
})
p("POST /admin/notifications", resp)

# 8. List all users
print("\n--- 8. List all Users ---")
resp = session.get(f"{BASE}/admin/users")
data = p("GET /admin/users", resp)
if resp.status_code == 200:
    print(f"   Total accounts: {len(data)}")
    for u in data[:5]:
        print(f"   - [{u['role']}] {u['username']} | active={u['is_active']}")

# 9. Withdrawals list
print("\n--- 9. Withdrawal Requests ---")
resp = session.get(f"{BASE}/admin/withdrawals")
data = p("GET /admin/withdrawals", resp)
print(f"   Pending withdrawals: {len([w for w in data if w.get('status')=='pending'])}")

# 10. Refunds list
print("\n--- 10. Refund Requests ---")
resp = session.get(f"{BASE}/admin/refunds")
data = p("GET /admin/refunds", resp)
print(f"   Pending refunds: {len([r for r in data if r.get('status')=='pending'])}")

# 11. Support logs
print("\n--- 11. Support Activity Logs ---")
resp = session.get(f"{BASE}/admin/support-logs")
data = p("GET /admin/support-logs", resp)
print(f"   Log entries: {len(data)}")

# 12. Services management
print("\n--- 12. Services Management ---")
resp = session.get(f"{BASE}/customer/categories")
cats = p("GET /customer/categories", resp)
if resp.status_code == 200 and cats:
    for cat in cats[:2]:
        print(f"   Category: {cat['name']} ({len(cat.get('services',[]))} services)")
    # Update a service
    if cats and cats[0].get('services'):
        svc = cats[0]['services'][0]
        resp2 = session.put(f"{BASE}/admin/services/{svc['id']}", json={
            "name": svc['name'],
            "price": svc['price'],
            "description": "Updated description by Admin test"
        })
        p(f"PUT /admin/services/{svc['id']}", resp2)

# 13. Login as Support
print("\n--- 13. Login as Support ---")
login("support_test", "support123")

# 14. Support: Get pending workers
print("\n--- 14. Support: Get Pending Workers ---")
resp = session.get(f"{BASE}/support/workers/pending")
data = p("GET /support/workers/pending", resp)
print(f"   Pending workers: {len(data)}")
if data:
    worker_id = data[0]['id']
    print(f"\n--- 14b. Support: Approve Worker #{worker_id} ---")
    resp2 = session.post(f"{BASE}/support/workers/{worker_id}/approve")
    p(f"POST /support/workers/{worker_id}/approve", resp2)

# 15. Support: All workers (approved)
print("\n--- 15. Support: All Approved Workers ---")
resp = session.get(f"{BASE}/support/workers")
data = p("GET /support/workers", resp)
print(f"   Approved workers: {len(data)}")

# 16. Support: All bookings
print("\n--- 16. Support: All Bookings ---")
resp = session.get(f"{BASE}/support/bookings")
data = p("GET /support/bookings", resp)
print(f"   Total bookings: {len(data)}")
if data:
    booking = data[0]
    booking_id = booking.get('id') or booking.get('booking_id')
    b_status = booking.get('status', '')
    print(f"   First booking #{booking_id} status: {b_status}")

    # Confirm payment on a non-cancelled booking
    if b_status not in ['cancelled']:
        print(f"\n--- 16b. Support: Confirm Payment for Booking #{booking_id} ---")
        resp2 = session.post(f"{BASE}/support/bookings/{booking_id}/confirm-payment")
        p(f"POST /support/bookings/{booking_id}/confirm-payment", resp2)

# 17. Support: Tickets
print("\n--- 17. Support: All Tickets ---")
resp = session.get(f"{BASE}/support/tickets")
data = p("GET /support/tickets", resp)
print(f"   Total tickets: {len(data)}")
if data:
    ticket_id = data[0]['id']
    t_status = data[0]['status']
    next_status = 'in_progress' if t_status == 'pending' else 'closed'
    print(f"\n--- 17b. Support: Update Ticket #{ticket_id} -> {next_status} ---")
    resp2 = session.put(f"{BASE}/support/tickets/{ticket_id}/status", json={"status": next_status})
    p(f"PUT /support/tickets/{ticket_id}/status", resp2)

# 18. Support: Propose refund on done booking
print("\n--- 18. Support: Propose Refund ---")
# Re-fetch to find a done booking
resp = session.get(f"{BASE}/support/bookings")
bookings = resp.json() if resp.status_code == 200 else []
done_bookings = [b for b in bookings if b.get('status') == 'done']
if done_bookings:
    bid = done_bookings[0].get('id') or done_bookings[0].get('booking_id')
    resp2 = session.post(f"{BASE}/support/bookings/{bid}/propose-refund", json={
        "reason": "Customer complaint - service not satisfactory",
        "amount": 10.0
    })
    p(f"POST /support/bookings/{bid}/propose-refund", resp2)
else:
    print("   No DONE bookings found to propose refund on")

print("\n" + "=" * 60)
print("ALL TESTS COMPLETED")
print("=" * 60)
print("Swagger UI: http://localhost:8000/docs")
print("=" * 60)
