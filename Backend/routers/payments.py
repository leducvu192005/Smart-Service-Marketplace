"""
VNPay Payment Router
- POST /payments/create       → Tạo URL thanh toán VNPay cho booking
- GET  /payments/return       → Return URL (chỉ hiển thị kết quả, KHÔNG cập nhật DB)
- GET  /payments/ipn          → IPN callback (SERVER-TO-SERVER, nguồn chính xác nhận thanh toán)
- GET  /payments/{booking_id} → Xem trạng thái thanh toán của booking
"""

import hashlib
import hmac
import urllib.parse
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request, Query
from sqlalchemy.orm import Session

import database
import models
import schemas
import auth_utils

router = APIRouter(prefix="/payments", tags=["Payments"])

# ─────────────────────── VNPay Sandbox Config ───────────────────────
VNP_TMN_CODE = "R7LI1D7B"
VNP_HASH_SECRET = "BOUI8VRBS1V1G3481FS8K8H249GGW4LF"
VNP_URL = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html"
# Các URL này cần được cập nhật khi deploy hoặc dùng ngrok
VNP_RETURN_URL = "https://wielder-angles-garnet.ngrok-free.dev/payments/return"
VNP_IPN_URL = "https://wielder-angles-garnet.ngrok-free.dev/payments/ipn"


def _hmac_sha512(key: str, data: str) -> str:
    """Tạo HMAC SHA512 hash."""
    return hmac.new(
        key.encode("utf-8"),
        data.encode("utf-8"),
        hashlib.sha512,
    ).hexdigest()


def _build_vnpay_url(booking_id: int, amount: float, txn_ref: str, ip_addr: str) -> str:
    """
    Tạo URL thanh toán VNPay chuẩn.
    amount: tiền VND (sẽ nhân 100 vì VNPay yêu cầu đơn vị nhỏ nhất).
    """
    params = {
        "vnp_Version": "2.1.0",
        "vnp_Command": "pay",
        "vnp_TmnCode": VNP_TMN_CODE,
        "vnp_Amount": str(int(amount * 100)),   # VNPay yêu cầu nhân 100
        "vnp_CurrCode": "VND",
        "vnp_TxnRef": txn_ref,
        "vnp_OrderInfo": f"Thanh toan don hang #{booking_id}",
        "vnp_OrderType": "billpayment",
        "vnp_Locale": "vn",
        "vnp_ReturnUrl": VNP_RETURN_URL,
        "vnp_IpAddr": ip_addr,
        # Đổi từ datetime.utcnow() sang datetime.now() để lấy đúng múi giờ GMT+7 của Việt Nam
        "vnp_CreateDate": datetime.now().strftime("%Y%m%d%H%M%S"),
    }

    # 1. Sắp xếp theo key A-Z
    sorted_params = sorted(params.items())
    
    # 2. ĐÃ SỬA: Dùng quote_via=urllib.parse.quote_plus theo chuẩn VNPAY 2.1.0 (khoảng trắng thành dấu +)
    query_string = urllib.parse.urlencode(sorted_params, quote_via=urllib.parse.quote_plus)
    
    # 3. Tạo chữ ký trên chuỗi query đã encode
    secure_hash = _hmac_sha512(VNP_HASH_SECRET, query_string)

    return f"{VNP_URL}?{query_string}&vnp_SecureHash={secure_hash}"


def _verify_vnpay_hash(params: dict) -> bool:
    """Xác minh chữ ký vnp_SecureHash từ VNPay callback."""
    received_hash = params.pop("vnp_SecureHash", "")
    params.pop("vnp_SecureHashType", None)

    sorted_params = sorted(params.items())
    
    # ĐÃ SỬA: Thay đổi quote thành quote_plus để khớp hoàn toàn với chuỗi callback từ VNPAY gửi về
    query_string = urllib.parse.urlencode(sorted_params, quote_via=urllib.parse.quote_plus)
    expected_hash = _hmac_sha512(VNP_HASH_SECRET, query_string)

    return hmac.compare_digest(received_hash.lower(), expected_hash.lower())


# ─────────────────────── Endpoints ───────────────────────

@router.post("/create")
def create_payment(
    booking_id: int,
    request: Request,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth_utils.get_current_user),
):
    """
    Tạo URL thanh toán VNPay cho một booking.
    Chỉ booking có status = pending_payment mới được thanh toán.
    """
    # 1. Kiểm tra booking
    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id,
        models.Booking.customer_id == current_user.id,
    ).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking không tồn tại hoặc không phải của bạn")

    if booking.status != models.BookingStatusEnum.PENDING_PAYMENT:
        raise HTTPException(status_code=400, detail=f"Booking đang ở trạng thái '{booking.status}', không thể thanh toán")

    # 2. Kiểm tra payment đã tồn tại chưa
    existing_payment = db.query(models.Payment).filter(
        models.Payment.booking_id == booking_id,
        models.Payment.status == "paid",
    ).first()
    if existing_payment:
        raise HTTPException(status_code=400, detail="Booking này đã được thanh toán")

    # 3. Lấy giá dịch vụ
    service = db.query(models.Service).filter(models.Service.id == booking.service_id).first()
    if not service or not service.price:
        raise HTTPException(status_code=400, detail="Dịch vụ không có giá")
    amount = float(service.price)

    # 4. Tạo mã giao dịch unique (Sử dụng datetime.now() đồng bộ múi giờ Việt Nam)
    txn_ref = f"SSM{booking_id}T{int(datetime.now().timestamp())}"

    # 5. Xóa payment cũ (created/failed) nếu có → cho phép thanh toán lại
    old_payment = db.query(models.Payment).filter(
        models.Payment.booking_id == booking_id,
        models.Payment.status.in_(["created", "failed"]),
    ).first()
    if old_payment:
        db.delete(old_payment)
        db.flush()

    # 6. Tạo payment record
    payment = models.Payment(
        booking_id=booking_id,
        amount=amount,
        vnp_txn_ref=txn_ref,
        status="created",
    )
    db.add(payment)
    db.commit()
    db.refresh(payment)

    # 7. Tạo VNPay URL
    client_ip = request.client.host if request.client else "127.0.0.1"
    payment_url = _build_vnpay_url(booking_id, amount, txn_ref, client_ip)

    return {
        "payment_url": payment_url,
        "payment_id": payment.id,
        "txn_ref": txn_ref,
        "amount": amount,
    }


@router.get("/return")
def payment_return(request: Request, db: Session = Depends(database.get_db)):
    """
    VNPay redirect customer về đây sau khi thanh toán.
    Cập nhật DB trực tiếp ở đây để phục vụ việc test dưới local tiện lợi hơn.
    """
    params = dict(request.query_params)
    is_valid = _verify_vnpay_hash(params.copy())

    response_code = params.get("vnp_ResponseCode", "")
    txn_ref = params.get("vnp_TxnRef", "")
    vnp_transaction_no = params.get("vnp_TransactionNo", "")

    if not is_valid:
        return {
            "success": False,
            "message": "Chữ ký không hợp lệ. Vui lòng kiểm tra lại.",
            "txn_ref": txn_ref,
        }

    # Tìm payment trong DB
    payment = db.query(models.Payment).filter(
        models.Payment.vnp_txn_ref == txn_ref,
    ).first()

    if response_code == "00":
        # Thanh toán thành công
        if payment and payment.status != "paid":
            payment.status = "paid"
            payment.vnp_transaction_no = vnp_transaction_no

            # Cập nhật booking status → paid_confirmed
            booking = db.query(models.Booking).filter(
                models.Booking.id == payment.booking_id,
            ).first()
            if booking:
                booking.status = models.BookingStatusEnum.PAID_CONFIRMED

                # Tạo notification cho customer
                notif = models.UserNotification(
                    user_id=booking.customer_id,
                    title="Thanh toán thành công",
                    message=f"Đơn hàng #{booking.id} đã thanh toán {payment.amount:,.0f}đ. Đang chờ thợ nhận việc.",
                )
                db.add(notif)
            db.commit()

        return {
            "success": True,
            "message": "Thanh toán thành công! Đơn hàng đã được cập nhật.",
            "txn_ref": txn_ref,
        }
    else:
        # Thanh toán thất bại
        if payment and payment.status not in ["paid", "failed"]:
            payment.status = "failed"
            payment.vnp_transaction_no = vnp_transaction_no
            db.commit()

        return {
            "success": False,
            "message": f"Thanh toán thất bại (mã lỗi: {response_code})",
            "txn_ref": txn_ref,
        }


@router.get("/ipn")
def payment_ipn(request: Request, db: Session = Depends(database.get_db)):
    """
    VNPay IPN (Instant Payment Notification) — SERVER-TO-SERVER.
    Đây là nguồn DUY NHẤT để xác nhận thanh toán.
    VNPay gọi endpoint này sau khi khách hàng thanh toán.
    """
    params = dict(request.query_params)

    # 1. Verify chữ ký HMAC-SHA512
    if not _verify_vnpay_hash(params.copy()):
        return {"RspCode": "97", "Message": "Invalid Checksum"}

    # 2. Lấy thông tin giao dịch
    vnp_txn_ref = params.get("vnp_TxnRef", "")
    vnp_amount = int(params.get("vnp_Amount", "0"))      # đã nhân 100
    vnp_response_code = params.get("vnp_ResponseCode", "")
    vnp_transaction_no = params.get("vnp_TransactionNo", "")

    # 3. Tìm payment trong DB
    payment = db.query(models.Payment).filter(
        models.Payment.vnp_txn_ref == vnp_txn_ref,
    ).first()
    if not payment:
        return {"RspCode": "01", "Message": "Order not Found"}

    # 4. Kiểm tra đã xử lý chưa (idempotent)
    if payment.status == "paid":
        return {"RspCode": "02", "Message": "Order already confirmed"}

    # 5. Kiểm tra số tiền khớp
    expected_amount = int(payment.amount * 100)
    if vnp_amount != expected_amount:
        return {"RspCode": "04", "Message": "Invalid Amount"}

    # 6. Xử lý kết quả
    if vnp_response_code == "00":
        # ✅ Thanh toán thành công
        payment.status = "paid"
        payment.vnp_transaction_no = vnp_transaction_no

        # Cập nhật booking status → paid_confirmed
        booking = db.query(models.Booking).filter(
            models.Booking.id == payment.booking_id,
        ).first()
        if booking:
            booking.status = models.BookingStatusEnum.PAID_CONFIRMED

            # Tạo notification cho customer
            notif = models.UserNotification(
                user_id=booking.customer_id,
                title="Thanh toán thành công",
                message=f"Đơn hàng #{booking.id} đã thanh toán {payment.amount:,.0f}đ. Đang chờ thợ nhận việc.",
            )
            db.add(notif)

        db.commit()
        return {"RspCode": "00", "Message": "Confirm Success"}
    else:
        # ❌ Thanh toán thất bại
        payment.status = "failed"
        payment.vnp_transaction_no = vnp_transaction_no
        db.commit()
        return {"RspCode": "00", "Message": "Confirm Success"}


@router.get("/{booking_id}", response_model=schemas.PaymentResponse)
def get_payment_status(
    booking_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth_utils.get_current_user),
):
    """Xem trạng thái thanh toán của một booking."""
    payment = db.query(models.Payment).filter(
        models.Payment.booking_id == booking_id,
    ).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Chưa có thông tin thanh toán cho booking này")
    return payment