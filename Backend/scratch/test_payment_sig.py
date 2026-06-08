import urllib.parse
import hashlib
import hmac
from datetime import datetime

VNP_HASH_SECRET = "BOUI8VRBS1V1G3481FS8K8H249GGW4LF"
VNP_TMN_CODE = "R7LI1D7B"
VNP_URL = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html"

def _hmac_sha512(key: str, data: str) -> str:
    return hmac.new(
        key.encode("utf-8"),
        data.encode("utf-8"),
        hashlib.sha512,
    ).hexdigest()

def _build_vnpay_url(booking_id: int, amount: float, txn_ref: str, ip_addr: str) -> str:
    params = {
        "vnp_Version": "2.1.0",
        "vnp_Command": "pay",
        "vnp_TmnCode": VNP_TMN_CODE,
        "vnp_Amount": str(int(amount * 100)),
        "vnp_CurrCode": "VND",
        "vnp_TxnRef": txn_ref,
        "vnp_OrderInfo": f"Thanh toan don hang #{booking_id}",
        "vnp_OrderType": "billpayment",
        "vnp_Locale": "vn",
        "vnp_ReturnUrl": "http://localhost:8000/payments/return",
        "vnp_IpAddr": ip_addr,
        "vnp_CreateDate": datetime.now().strftime("%Y%m%d%H%M%S"),
    }
    sorted_params = sorted(params.items())
    query_string = urllib.parse.urlencode(sorted_params, quote_via=urllib.parse.quote)
    secure_hash = _hmac_sha512(VNP_HASH_SECRET, query_string)
    return f"{VNP_URL}?{query_string}&vnp_SecureHash={secure_hash}"

def _verify_vnpay_hash(params: dict) -> bool:
    received_hash = params.pop("vnp_SecureHash", "")
    params.pop("vnp_SecureHashType", None)
    sorted_params = sorted(params.items())
    query_string = urllib.parse.urlencode(sorted_params, quote_via=urllib.parse.quote)
    expected_hash = _hmac_sha512(VNP_HASH_SECRET, query_string)
    return hmac.compare_digest(received_hash.lower(), expected_hash.lower())

# Run verification test
url = _build_vnpay_url(27, 50000.0, "SSM27T1780916351", "127.0.0.1")
print("Generated URL:")
print(url)

# Parse parameters back
parsed_url = urllib.parse.urlparse(url)
params = urllib.parse.parse_qs(parsed_url.query)
# parse_qs parses values into lists, convert to string
parsed_params = {k: v[0] for k, v in params.items()}

# Verify
is_valid = _verify_vnpay_hash(parsed_params)
print("\nVerification of generated URL params:")
print(f"Is signature valid? {is_valid}")
if not is_valid:
    print("WARNING: Verification failed!")
else:
    print("SUCCESS: Verification passed!")

# Check if there is any '+' in the query string instead of %20
if "+" in parsed_url.query:
    print("WARNING: Found '+' in query string! That might cause signature mismatch with VNPay.")
else:
    print("SUCCESS: No '+' found in query string for spaces.")
