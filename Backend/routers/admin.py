from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

import database
import models
import schemas
import auth_utils

router = APIRouter(prefix="/admin", tags=["Admin"])

def get_current_admin(current_user: models.User = Depends(auth_utils.get_current_user)):
    if current_user.role != models.RoleEnum.ADMIN:
        raise HTTPException(status_code=403, detail="Not authorized as admin")
    return current_user

@router.get("/users", response_model=List[schemas.UserResponse])
def get_all_users(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    return db.query(models.User).all()

@router.put("/users/{user_id}/status", response_model=schemas.UserResponse)
def update_user_status(user_id: int, is_active: bool, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = is_active
    db.commit()
    db.refresh(user)
    return user

@router.post("/categories", response_model=schemas.ServiceCategoryResponse)
def create_category(category: schemas.ServiceCategoryBase, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    new_category = models.ServiceCategory(name=category.name, description=category.description)
    db.add(new_category)
    db.commit()
    db.refresh(new_category)
    return new_category

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

@router.get("/dashboard")
def get_dashboard_stats(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    total_users = db.query(models.User).filter(models.User.role == models.RoleEnum.CUSTOMER).count()
    total_workers = db.query(models.User).filter(models.User.role == models.RoleEnum.WORKER).count()
    total_bookings = db.query(models.Booking).count()
    
    # Calculate revenue
    bookings_done = db.query(models.Booking).filter(models.Booking.status == models.BookingStatusEnum.DONE).all()
    total_revenue = 0.0
    for b in bookings_done:
        if b.service and b.service.price is not None:
            total_revenue += float(b.service.price)
    
    return {
        "total_users": total_users,
        "total_workers": total_workers,
        "total_bookings": total_bookings,
        "total_revenue": total_revenue
    }


# --- Super Admin Management APIs ---

from datetime import datetime
from pydantic import BaseModel, EmailStr
from typing import Optional

class SupportAccountCreate(BaseModel):
    username: str
    email: EmailStr
    full_name: str
    password: str

class ServiceUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None


@router.get("/withdrawals", response_model=List[schemas.WithdrawalResponse])
def get_withdrawals(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    return db.query(models.WithdrawalRequest).all()


@router.post("/withdrawals/{request_id}/approve", response_model=schemas.WithdrawalResponse)
def approve_withdrawal(request_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    req = db.query(models.WithdrawalRequest).filter(models.WithdrawalRequest.id == request_id).first()
    if not req:
        raise HTTPException(status_code=404, detail="Withdrawal request not found")
        
    if req.status != "pending":
        raise HTTPException(status_code=400, detail="Request is already processed")
        
    worker = db.query(models.Worker).filter(models.Worker.id == req.worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
        
    if worker.wallet_balance < req.amount:
        raise HTTPException(status_code=400, detail="Insufficient wallet balance")
        
    req.status = "approved"
    req.updated_at = datetime.utcnow()
    
    # Deduct from wallet
    worker.wallet_balance -= req.amount
    
    # Record transaction
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
        raise HTTPException(status_code=404, detail="Withdrawal request not found")
        
    if req.status != "pending":
        raise HTTPException(status_code=400, detail="Request is already processed")
        
    req.status = "rejected"
    req.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(req)
    return req


@router.get("/refunds", response_model=List[schemas.RefundRequestResponse])
def get_refunds(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    return db.query(models.RefundRequest).all()


@router.post("/refunds/{request_id}/approve", response_model=schemas.RefundRequestResponse)
def approve_refund(request_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    req = db.query(models.RefundRequest).filter(models.RefundRequest.id == request_id).first()
    if not req:
        raise HTTPException(status_code=404, detail="Refund request not found")
        
    if req.status != "pending":
        raise HTTPException(status_code=400, detail="Request is already processed")
        
    req.status = "approved"
    req.updated_at = datetime.utcnow()
    
    # Deduct from worker if they got paid 90%
    booking = db.query(models.Booking).filter(models.Booking.id == req.booking_id).first()
    if booking and booking.worker_id:
        worker = db.query(models.Worker).filter(models.Worker.id == booking.worker_id).first()
        if worker:
            # Deduct the refund amount from worker
            worker.wallet_balance -= req.amount
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
        raise HTTPException(status_code=404, detail="Refund request not found")
        
    if req.status != "pending":
        raise HTTPException(status_code=400, detail="Request is already processed")
        
    req.status = "rejected"
    req.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(req)
    return req


@router.get("/financial-stats")
def get_financial_stats(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    # total revenue from completed bookings
    bookings_done = db.query(models.Booking).filter(models.Booking.status == models.BookingStatusEnum.DONE).all()
    total_revenue = sum([float(b.service.price or 0.0) for b in bookings_done if b.service])
    system_net_revenue = 0.1 * total_revenue
    
    total_withdrawn = db.query(models.WithdrawalRequest).filter(models.WithdrawalRequest.status == "approved").all()
    total_withdrawn_amount = sum([w.amount for w in total_withdrawn])
    
    total_refunded = db.query(models.RefundRequest).filter(models.RefundRequest.status == "approved").all()
    total_refunded_amount = sum([r.amount for r in total_refunded])
    
    workers = db.query(models.Worker).all()
    wallet_balances_sum = sum([w.wallet_balance for w in workers if w.wallet_balance])
    
    return {
        "total_revenue": total_revenue,
        "system_net_revenue": system_net_revenue,
        "total_withdrawn": total_withdrawn_amount,
        "total_refunded": total_refunded_amount,
        "wallet_balances_sum": wallet_balances_sum
    }


@router.post("/support-accounts", response_model=schemas.UserResponse)
def create_support_account(payload: SupportAccountCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    # Check if exists
    existing_user = db.query(models.User).filter(
        (models.User.username == payload.username) | (models.User.email == payload.email)
    ).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Username or email already exists")
        
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


@router.post("/vouchers", response_model=schemas.VoucherResponse)
def create_voucher(payload: schemas.VoucherCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    existing = db.query(models.Voucher).filter(models.Voucher.code == payload.code).first()
    if existing:
        raise HTTPException(status_code=400, detail="Voucher code already exists")
        
    voucher = models.Voucher(
        code=payload.code,
        discount_amount=payload.discount_amount,
        expiry_date=payload.expiry_date,
        is_active=True
    )
    db.add(voucher)
    db.commit()
    db.refresh(voucher)
    return voucher


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


@router.put("/services/{service_id}", response_model=schemas.ServiceResponse)
def update_service(service_id: int, payload: ServiceUpdate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_admin)):
    service = db.query(models.Service).filter(models.Service.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
        
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
        raise HTTPException(status_code=404, detail="Service not found")
        
    db.delete(service)
    db.commit()
    return {"message": f"Service {service_id} successfully deleted"}

