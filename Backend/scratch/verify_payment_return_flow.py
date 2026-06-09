import urllib.parse
import hashlib
import hmac
import requests
import os
import sys
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
import database
import models.core

VNP_HASH_SECRET = "BOUI8VRBS1V1G3481FS8K8H249GGW4LF"
BASE_URL = "http://localhost:8000"

def _hmac_sha512(key: str, data: str) -> str:
    return hmac.new(
        key.encode("utf-8"),
        data.encode("utf-8"),
        hashlib.sha512,
    ).hexdigest()

# 1. Check initial status of booking 27
db = next(database.get_db())
booking = db.query(models.core.Booking).filter(models.core.Booking.id == 27).first()
if not booking:
    print("Booking 27 not found!")
    exit(1)

print(f"Initial booking 27 status: {booking.status}")

# 2. Find payment for booking 27
payment = db.query(models.core.Payment).filter(models.core.Payment.booking_id == 27).first()
if not payment:
    print("Payment for booking 27 not found!")
    exit(1)

txn_ref = payment.vnp_txn_ref
amount_str = str(int(payment.amount * 100))
print(f"Payment txn_ref: {txn_ref}, amount: {payment.amount} (vnp_Amount: {amount_str})")

# Close the session to release database locks during HTTP call
db.close()

# 3. Construct VNPay success response parameters
params = {
    "vnp_Amount": amount_str,
    "vnp_BankCode": "NCB",
    "vnp_BankTranNo": "VNP12345678",
    "vnp_CardType": "ATM",
    "vnp_OrderInfo": f"Thanh toan don hang 27",
    "vnp_PayDate": "20260608180000",
    "vnp_ResponseCode": "00",
    "vnp_TmnCode": "R7LI1D7B",
    "vnp_TransactionNo": "12345678",
    "vnp_TransactionStatus": "00",
    "vnp_TxnRef": txn_ref,
}

# 4. Generate signature (sorting alphabetically, using quote for space/special chars)
sorted_params = sorted(params.items())
query_string = urllib.parse.urlencode(sorted_params, quote_via=urllib.parse.quote)
secure_hash = _hmac_sha512(VNP_HASH_SECRET, query_string)

# Add secure hash to parameters
params["vnp_SecureHash"] = secure_hash

# 5. Send GET request to return URL
return_url = f"{BASE_URL}/payments/return"
print(f"Sending GET to return URL: {return_url}")
response = requests.get(return_url, params=params)

print(f"Response status code: {response.status_code}")
print(f"Response JSON: {response.json()}")

# 6. Verify database update (open new session)
db = next(database.get_db())
booking = db.query(models.core.Booking).filter(models.core.Booking.id == 27).first()
payment = db.query(models.core.Payment).filter(models.core.Payment.booking_id == 27).first()

print(f"\nAfter payment callback:")
print(f"Booking 27 status: {booking.status}")
print(f"Payment status: {payment.status}")

if booking.status == "paid_confirmed" and payment.status == "paid":
    print("\nSUCCESS: Payment returned successfully and database updated to 'paid_confirmed'!")
else:
    print("\nFAILURE: Database was not updated correctly!")
db.close()
