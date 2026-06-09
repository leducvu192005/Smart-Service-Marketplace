from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timezone, timedelta
from pydantic import BaseModel, EmailStr
import random
import string
from collections import defaultdict

import database
import models
import schemas
import auth_utils

# --- Pydantic Schemas dùng riêng cho Admin ---

class SupportAccountCreate(BaseModel):
    username: str
    email: EmailStr
    full_name: str
    password: str

class ServiceUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None


# --- Khởi tạo Router ---

router = APIRouter(prefix="/admin", tags=["Admin"])


# --- Hàm kiểm tra quyền hạn Admin (Dependency) ---

def get_current_admin(current_user: models.User = Depends(auth_utils.get_current_user)):
    if current_user.role != models.RoleEnum.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Not authorized as admin"
        )
    return current_user


# --- Hệ thống Quản lý Người dùng & Dashboard ---

@router.get("/users", response_model=List[schemas.UserResponse])
def get_all_users(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    return db.query(models.User).all()


@router.get("/support-accounts", response_model=List[schemas.UserResponse])
def get_support_accounts(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    """Lấy danh sách tất cả tài khoản Support"""
    return db.query(models.User).filter(models.User.role == models.RoleEnum.SUPPORT).all()


@router.put("/users/{user_id}/status", response_model=schemas.UserResponse)
def update_user_status(user_id: int, is_active: bool, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    user.is_active = is_active
    db.commit()
    db.refresh(user)
    return user


@router.put("/users/{user_id}/toggle-active", response_model=schemas.UserResponse)
def toggle_user_active(user_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    """Đảo ngược trạng thái kích hoạt tài khoản (khóa / mở khóa)"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    if user.role == models.RoleEnum.ADMIN:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cannot deactivate admin account")
    user.is_active = not user.is_active
    db.commit()
    db.refresh(user)
    return user


@router.post("/users/{user_id}/reset-password")
def reset_user_password(user_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    """Đặt lại mật khẩu cho người dùng và trả về mật khẩu mới"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    
    # Tạo mật khẩu ngẫu nhiên 8 ký tự (chữ + số)
    chars = string.ascii_letters + string.digits
    new_password = ''.join(random.choices(chars, k=8))
    user.hashed_password = auth_utils.get_password_hash(new_password)
    db.commit()
    
    return {"message": "Password reset successfully", "new_password": new_password, "user_id": user_id}


@router.get("/dashboard")
def get_dashboard_stats(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    total_users = db.query(models.User).filter(models.User.role == models.RoleEnum.CUSTOMER).count()
    total_workers = db.query(models.User).filter(models.User.role == models.RoleEnum.WORKER).count()
    total_bookings = db.query(models.Booking).count()
    
    # Tính toán doanh thu an toàn, chống lỗi giá trị rỗng (None)
    bookings_done = db.query(models.Booking).filter(models.Booking.status == models.BookingStatusEnum.DONE).all()
    total_revenue = 0.0
    for b in bookings_done:
        if b.service and b.service.price is not None:
            total_revenue += float(b.service.price)
    
    # Thống kê pending để hiển thị trên dashboard
    pending_tickets = db.query(models.Ticket).filter(models.Ticket.status == "pending").count()
    pending_withdrawals = db.query(models.WithdrawalRequest).filter(models.WithdrawalRequest.status == "pending").count()
    pending_refunds = db.query(models.RefundRequest).filter(models.RefundRequest.status == "pending").count()
    pending_workers = db.query(models.Worker).filter(models.Worker.status == "pending").count()
    
    return {
        "total_users": total_users,
        "total_workers": total_workers,
        "total_bookings": total_bookings,
        "total_revenue": total_revenue,
        "pending_tickets": pending_tickets,
        "pending_withdrawals": pending_withdrawals,
        "pending_refunds": pending_refunds,
        "pending_workers": pending_workers
    }


# --- Quản lý Danh mục & Dịch vụ vụ ---

@router.post("/categories", response_model=schemas.ServiceCategoryResponse)
def create_category(category: schemas.ServiceCategoryBase, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    new_category = models.ServiceCategory(name=category.name, description=category.description)
    db.add(new_category)
    db.commit()
    db.refresh(new_category)
    return new_category


@router.delete("/categories/{category_id}")
def delete_category(category_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    """Xóa danh mục dịch vụ. Cảnh báo nếu còn dịch vụ bên trong."""
    category = db.query(models.ServiceCategory).filter(models.ServiceCategory.id == category_id).first()
    if not category:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    service_count = db.query(models.Service).filter(models.Service.category_id == category_id).count()
    if service_count > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot delete category with {service_count} services. Delete services first."
        )
    db.delete(category)
    db.commit()
    return {"message": f"Category {category_id} deleted successfully"}


@router.post("/services", response_model=schemas.ServiceResponse)
def create_service(service: schemas.ServiceCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    new_service = models.Service(
        category_id=service.category_id,
        name=service.name,
        description=service.description,
        price=service.price
    )
    db.add(new_service)
    db.commit()
    db.refresh(new_service)
    return new_service


@router.put("/services/{service_id}", response_model=schemas.ServiceResponse)
def update_service(service_id: int, payload: ServiceUpdate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    service = db.query(models.Service).filter(models.Service.id == service_id).first()
    if not service:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Service not found")
        
    if payload.name is not None:
        service.name = payload.name
    if payload.description is not None:
        service.description = payload.description
    if payload.price is not None:
        service.price = payload.price
        
    db.commit()
    db.refresh(service)
    return service


@router.delete("/services/{service_id}")
def delete_service(service_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    service = db.query(models.Service).filter(models.Service.id == service_id).first()
    if not service:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Service not found")
        
    db.delete(service)
    db.commit()
    return {"message": f"Service {service_id} successfully deleted"}


# --- Quản lý Yêu cầu Rút tiền (Withdrawals) ---

@router.get("/withdrawals")
def get_withdrawals(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    """Trả về danh sách yêu cầu rút tiền kèm tên thợ"""
    requests = db.query(models.WithdrawalRequest).order_by(models.WithdrawalRequest.created_at.desc()).all()
    result = []
    for req in requests:
        worker_name = None
        worker_phone = None
        worker_wallet = None
        if req.worker:
            if req.worker.user:
                worker_name = req.worker.user.full_name
            worker_phone = req.worker.phone
            worker_wallet = req.worker.wallet_balance
        result.append({
            "id": req.id,
            "worker_id": req.worker_id,
            "worker_name": worker_name,
            "worker_phone": worker_phone,
            "worker_wallet": worker_wallet,
            "amount": req.amount,
            "status": req.status,
            "created_at": req.created_at.isoformat() if req.created_at else None,
            "updated_at": req.updated_at.isoformat() if req.updated_at else None,
        })
    return result


@router.post("/withdrawals/{request_id}/approve", response_model=schemas.WithdrawalResponse)
def approve_withdrawal(request_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    req = db.query(models.WithdrawalRequest).filter(models.WithdrawalRequest.id == request_id).first()
    if not req:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Withdrawal request not found")
        
    if req.status != "pending":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Request is already processed")
        
    worker = db.query(models.Worker).filter(models.Worker.id == req.worker_id).first()
    if not worker:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Worker not found")
        
    # Xử lý giá trị ví rỗng nếu có
    current_balance = worker.wallet_balance if worker.wallet_balance is not None else 0.0
    if current_balance < req.amount:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Insufficient wallet balance")
        
    req.status = "approved"
    req.updated_at = datetime.now(timezone.utc)
    
    # Trừ tiền trong ví thợ
    worker.wallet_balance = current_balance - req.amount
    
    # Lưu vết lịch sử giao dịch
    txn = models.Transaction(
        worker_id=worker.id,
        amount=-req.amount,
        type="withdrawal",
        description=f"Rút tiền từ ví (Mã yêu cầu #{req.id})"
    )
    db.add(txn)
    db.commit()
    db.refresh(req)
    return req


@router.post("/withdrawals/{request_id}/reject", response_model=schemas.WithdrawalResponse)
def reject_withdrawal(request_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    req = db.query(models.WithdrawalRequest).filter(models.WithdrawalRequest.id == request_id).first()
    if not req:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Withdrawal request not found")
        
    if req.status != "pending":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Request is already processed")
        
    req.status = "rejected"
    req.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(req)
    return req


# --- Quản lý Hoàn tiền (Refunds) ---

@router.get("/refunds")
def get_refunds(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    """Trả về danh sách yêu cầu hoàn tiền kèm thông tin khách hàng và dịch vụ"""
    requests = db.query(models.RefundRequest).order_by(models.RefundRequest.created_at.desc()).all()
    result = []
    for req in requests:
        customer_name = None
        service_name = None
        worker_name = None
        booking_status = None
        if req.booking:
            booking_status = req.booking.status.value if hasattr(req.booking.status, 'value') else req.booking.status
            if req.booking.customer:
                customer_name = req.booking.customer.full_name
            if req.booking.service:
                service_name = req.booking.service.name
            if req.booking.worker and req.booking.worker.user:
                worker_name = req.booking.worker.user.full_name
        result.append({
            "id": req.id,
            "booking_id": req.booking_id,
            "booking_status": booking_status,
            "customer_name": customer_name,
            "worker_name": worker_name,
            "service_name": service_name,
            "reason": req.reason,
            "amount": req.amount,
            "status": req.status,
            "created_at": req.created_at.isoformat() if req.created_at else None,
            "updated_at": req.updated_at.isoformat() if req.updated_at else None,
        })
    return result


@router.post("/refunds/{request_id}/approve", response_model=schemas.RefundRequestResponse)
def approve_refund(request_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    req = db.query(models.RefundRequest).filter(models.RefundRequest.id == request_id).first()
    if not req:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Refund request not found")
        
    if req.status != "pending":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Request is already processed")
        
    req.status = "approved"
    req.updated_at = datetime.now(timezone.utc)
    
    # Khấu trừ tiền từ ví của Worker nếu đơn hàng đã được thanh toán trước đó
    booking = db.query(models.Booking).filter(models.Booking.id == req.booking_id).first()
    if booking and booking.worker_id:
        worker = db.query(models.Worker).filter(models.Worker.id == booking.worker_id).first()
        if worker:
            current_balance = worker.wallet_balance if worker.wallet_balance is not None else 0.0
            worker.wallet_balance = current_balance - req.amount
            
            txn = models.Transaction(
                worker_id=worker.id,
                booking_id=booking.id,
                amount=-req.amount,
                type="refund",
                description=f"Khấu trừ hoàn tiền đơn hàng #{booking.id} (Mã hoàn tiền #{req.id})"
            )
            db.add(txn)
            
    db.commit()
    db.refresh(req)
    return req


@router.post("/refunds/{request_id}/reject", response_model=schemas.RefundRequestResponse)
def reject_refund(request_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    req = db.query(models.RefundRequest).filter(models.RefundRequest.id == request_id).first()
    if not req:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Refund request not found")
        
    if req.status != "pending":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Request is already processed")
        
    req.status = "rejected"
    req.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(req)
    return req


# --- Duyệt hồ sơ Thợ (Admin cũng có quyền) ---

@router.get("/workers/pending", response_model=List[schemas.WorkerResponse])
def get_pending_workers_admin(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    """Admin lấy danh sách thợ chờ duyệt"""
    return db.query(models.Worker).filter(models.Worker.status == "pending").all()


@router.post("/workers/{worker_id}/approve", response_model=schemas.WorkerResponse)
def approve_worker_admin(worker_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    """Admin duyệt hồ sơ thợ"""
    worker = db.query(models.Worker).filter(models.Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    worker.status = "approved"

    legacy_profile = db.query(models.WorkerProfile).filter(models.WorkerProfile.user_id == worker.user_id).first()
    if legacy_profile:
        legacy_profile.is_available = True

    log = models.SupportActivityLog(
        support_id=current_user.id,
        action="approve_worker",
        details=f"Admin approved worker ID {worker_id}"
    )
    db.add(log)
    db.commit()
    db.refresh(worker)
    return worker


@router.post("/workers/{worker_id}/reject", response_model=schemas.WorkerResponse)
def reject_worker_admin(worker_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    """Admin từ chối hồ sơ thợ"""
    worker = db.query(models.Worker).filter(models.Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    worker.status = "rejected"

    log = models.SupportActivityLog(
        support_id=current_user.id,
        action="reject_worker",
        details=f"Admin rejected worker ID {worker_id}"
    )
    db.add(log)
    db.commit()
    db.refresh(worker)
    return worker


# --- Quản lý Ticket từ Khách hàng (Admin xem) ---

@router.get("/tickets")
def get_all_tickets_admin(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    """Admin lấy toàn bộ ticket của khách hàng và thợ"""
    tickets = db.query(models.Ticket).order_by(models.Ticket.created_at.desc()).all()
    result = []
    for t in tickets:
        creator_name = None
        creator_role = None
        if t.creator:
            creator_name = t.creator.full_name
            creator_role = t.creator.role.value if hasattr(t.creator.role, 'value') else str(t.creator.role)
        result.append({
            "id": t.id,
            "creator_id": t.creator_id,
            "creator_name": creator_name,
            "creator_role": creator_role,
            "booking_id": t.booking_id,
            "title": t.title,
            "description": t.description,
            "status": t.status,
            "admin_comment": t.admin_comment,
            "created_at": t.created_at.isoformat() if t.created_at else None,
            "updated_at": t.updated_at.isoformat() if t.updated_at else None,
        })
    return result


# --- Thống kê Tài chính Hệ thống ---

@router.get("/financial-stats")
def get_financial_stats(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    bookings_done = db.query(models.Booking).filter(models.Booking.status == models.BookingStatusEnum.DONE).all()
    total_revenue = sum([float(b.service.price or 0.0) for b in bookings_done if b.service])
    system_net_revenue = 0.1 * total_revenue
    
    total_withdrawn = db.query(models.WithdrawalRequest).filter(models.WithdrawalRequest.status == "approved").all()
    total_withdrawn_amount = sum([w.amount for w in total_withdrawn])
    
    total_refunded = db.query(models.RefundRequest).filter(models.RefundRequest.status == "approved").all()
    total_refunded_amount = sum([r.amount for r in total_refunded])
    
    workers = db.query(models.Worker).all()
    wallet_balances_sum = sum([w.wallet_balance for w in workers if w.wallet_balance is not None])
    
    return {
        "total_revenue": total_revenue,
        "system_net_revenue": system_net_revenue,
        "total_withdrawn": total_withdrawn_amount,
        "total_refunded": total_refunded_amount,
        "wallet_balances_sum": wallet_balances_sum
    }


@router.get("/revenue-chart")
def get_revenue_chart(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    """Lấy dữ liệu doanh thu theo tháng trong 12 tháng gần nhất"""
    now = datetime.now(timezone.utc)
    months = []
    for i in range(11, -1, -1):
        # Tính tháng: now - i tháng
        month_date = now.replace(day=1) - timedelta(days=i * 30)
        months.append((month_date.year, month_date.month))

    bookings_done = db.query(models.Booking).filter(
        models.Booking.status == models.BookingStatusEnum.DONE
    ).all()

    # Gộp doanh thu theo tháng
    revenue_by_month = defaultdict(float)
    bookings_count_by_month = defaultdict(int)
    for b in bookings_done:
        if b.created_at and b.service and b.service.price:
            key = (b.created_at.year, b.created_at.month)
            revenue_by_month[key] += float(b.service.price)
            bookings_count_by_month[key] += 1

    result = []
    for (year, month) in months:
        key = (year, month)
        result.append({
            "label": f"{month:02d}/{year}",
            "month": month,
            "year": year,
            "revenue": revenue_by_month.get(key, 0.0),
            "platform_fee": revenue_by_month.get(key, 0.0) * 0.1,
            "bookings_count": bookings_count_by_month.get(key, 0),
        })
    return result


@router.get("/bookings-chart")
def get_bookings_chart(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    """Lấy thống kê đơn hàng theo trạng thái"""
    statuses = [
        ("pending", "Chờ"),
        ("accepted", "Đã nhận"),
        ("in_progress", "Đang làm"),
        ("done", "Hoàn thành"),
        ("cancelled", "Đã hủy"),
    ]
    result = []
    for status_val, label in statuses:
        count = db.query(models.Booking).filter(models.Booking.status == status_val).count()
        result.append({"status": status_val, "label": label, "count": count})
    return result


# --- Quản lý Tài khoản Điều hành viên (Support) & Vouchers ---

@router.post("/support-accounts", response_model=schemas.UserResponse)
def create_support_account(payload: SupportAccountCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    existing_user = db.query(models.User).filter(
        (models.User.username == payload.username) | (models.User.email == payload.email)
    ).first()
    if existing_user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username or email already exists")
        
    hashed_pwd = auth_utils.get_password_hash(payload.password)
    user = models.User(
        username=payload.username,
        email=payload.email,
        full_name=payload.full_name,
        hashed_password=hashed_pwd,
        role=models.RoleEnum.SUPPORT,
        is_active=True
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.get("/support-logs", response_model=List[schemas.SupportActivityLogResponse])
def get_support_logs(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    return db.query(models.SupportActivityLog).order_by(models.SupportActivityLog.created_at.desc()).all()


@router.get("/vouchers", response_model=List[schemas.VoucherResponse])
def get_vouchers(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    """Lấy danh sách tất cả voucher"""
    return db.query(models.Voucher).order_by(models.Voucher.created_at.desc()).all()


@router.post("/vouchers", response_model=schemas.VoucherResponse)
def create_voucher(payload: schemas.VoucherCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    existing = db.query(models.Voucher).filter(models.Voucher.code == payload.code).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Voucher code already exists")
    
    # Hỗ trợ cả 2 field name: discount_value (từ Marketing Page) và discount_amount (backward compat)
    disc_value = payload.discount_value if payload.discount_value is not None else (payload.discount_amount or 0.0)
    
    voucher = models.Voucher(
        code=payload.code,
        discount_amount=disc_value,       # Backward compat
        discount_value=disc_value,        # New field
        discount_type=payload.discount_type or "fixed",
        max_uses=payload.max_uses,
        used_count=0,
        expiry_date=payload.expiry_date,
        is_active=True
    )
    db.add(voucher)
    db.commit()
    db.refresh(voucher)
    return voucher


@router.delete("/vouchers/{voucher_id}")
def delete_voucher(voucher_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    """Xóa voucher theo ID"""
    voucher = db.query(models.Voucher).filter(models.Voucher.id == voucher_id).first()
    if not voucher:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Voucher not found")
    db.delete(voucher)
    db.commit()
    return {"message": f"Voucher {voucher_id} deleted successfully"}


@router.get("/notifications", response_model=List[schemas.NotificationResponse])
def get_notifications(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    """Lấy danh sách tất cả thông báo đã gửi"""
    return db.query(models.Notification).order_by(models.Notification.created_at.desc()).all()


@router.post("/notifications", response_model=schemas.NotificationResponse)
def create_notification(payload: schemas.NotificationCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    notification = models.Notification(
        title=payload.title,
        message=payload.message,
        recipient_role=payload.recipient_role
    )
    db.add(notification)
    db.commit()
    db.refresh(notification)
    return notification