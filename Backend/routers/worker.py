from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List
import os
import shutil
import time
from datetime import datetime, timedelta

import database
import models
import schemas
import auth_utils

router = APIRouter(prefix="/worker", tags=["Worker"])

def get_current_worker(current_user: models.User = Depends(auth_utils.get_current_user)):
    if current_user.role != models.RoleEnum.WORKER:
        raise HTTPException(status_code=403, detail="Not authorized as worker")
    return current_user

@router.get("/profile", response_model=schemas.WorkerProfileResponse)
def get_worker_profile(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_worker)):
    profile = db.query(models.WorkerProfile).filter(models.WorkerProfile.user_id == current_user.id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Worker profile not found")
    return profile

@router.put("/profile", response_model=schemas.WorkerProfileResponse)
def update_worker_profile(profile_update: schemas.WorkerProfileUpdate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_worker)):
    profile = db.query(models.WorkerProfile).filter(models.WorkerProfile.user_id == current_user.id).first()
    if not profile:
        profile = models.WorkerProfile(user_id=current_user.id)
        db.add(profile)
        
    if profile_update.skills is not None:
        profile.skills = profile_update.skills
    if profile_update.experience is not None:
        profile.experience = profile_update.experience
    if profile_update.lat is not None:
        profile.lat = profile_update.lat
    if profile_update.long is not None:
        profile.long = profile_update.long
    if profile_update.avatar_url is not None:
        profile.avatar_url = profile_update.avatar_url
    
    profile.is_available = profile_update.is_available
        
    db.commit()
    db.refresh(profile)
    return profile

@router.get("/jobs/pending", response_model=List[schemas.BookingResponse])
def get_pending_jobs(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_worker)):
    profile = db.query(models.WorkerProfile).filter(models.WorkerProfile.user_id == current_user.id).first()
    if not profile or not profile.is_available:
        return []
        
    # In a real app, distance calculation using lat/long would happen here
    bookings = db.query(models.Booking).filter(
        models.Booking.status == models.BookingStatusEnum.PENDING
    ).all()
    return bookings

@router.post("/jobs/{booking_id}/accept", response_model=schemas.BookingResponse)
def accept_job(booking_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_worker)):
    worker = db.query(models.Worker).filter(models.Worker.user_id == current_user.id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker profile not found")
        
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    if booking.status != models.BookingStatusEnum.PAID_CONFIRMED:
        raise HTTPException(status_code=400, detail="Chỉ nhận việc khi khách đã thanh toán")
        
    booking.worker_id = worker.id
    booking.status = models.BookingStatusEnum.ACCEPTED
    db.commit()
    db.refresh(booking)
    return booking

@router.put("/jobs/{booking_id}/status", response_model=schemas.BookingResponse)
def update_job_status(booking_id: int, status_update: models.BookingStatusEnum, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_worker)):
    worker = db.query(models.Worker).filter(models.Worker.user_id == current_user.id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker profile not found")
        
    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id,
        models.Booking.worker_id == worker.id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found or not assigned to you")
        
    current_status = booking.status
    
    if status_update == models.BookingStatusEnum.ON_THE_WAY:
        if current_status != models.BookingStatusEnum.ACCEPTED:
            raise HTTPException(status_code=400, detail="Cannot start travel unless booking is accepted")
            
    elif status_update == models.BookingStatusEnum.ARRIVED:
        if current_status != models.BookingStatusEnum.ON_THE_WAY:
            raise HTTPException(status_code=400, detail="Cannot mark arrived unless on the way")
            
    elif status_update == models.BookingStatusEnum.IN_PROGRESS:
        if current_status != models.BookingStatusEnum.ARRIVED:
            raise HTTPException(status_code=400, detail="Cannot start progress unless arrived")
        if not booking.before_image:
            raise HTTPException(status_code=400, detail="Vui lòng chụp và tải ảnh trước khi làm việc")
            
    elif status_update == models.BookingStatusEnum.DONE:
        if current_status != models.BookingStatusEnum.IN_PROGRESS:
            raise HTTPException(status_code=400, detail="Cannot mark completed unless in progress")
        if not booking.after_image:
            raise HTTPException(status_code=400, detail="Vui lòng chụp và tải ảnh hoàn thành công việc")
            
        # Kiểm tra payment: CHỈ cộng tiền khi đã thanh toán qua VNPay
        service = db.query(models.Service).filter(models.Service.id == booking.service_id).first()
        price = float(service.price) if service and service.price else 0.0

        payment = db.query(models.Payment).filter(
            models.Payment.booking_id == booking.id,
            models.Payment.status == "paid",
        ).first()

        if payment and price > 0:
            # ✅ Đã thanh toán → release tiền cho worker (90%)
            worker_earnings = price * 0.90
            platform_fee = price * 0.10

            worker.wallet_balance = (worker.wallet_balance or 0.0) + worker_earnings
            worker.total_jobs = (worker.total_jobs or 0) + 1

            # Giao dịch thu nhập
            tx = models.Transaction(
                worker_id=worker.id,
                booking_id=booking.id,
                amount=worker_earnings,
                type="earnings",
                description=f"90% thu nhập đơn #{booking.id} ({worker_earnings:,.0f}đ) — Phí nền tảng 10%: {platform_fee:,.0f}đ"
            )
            db.add(tx)

            # Worker notification
            work_notif = models.UserNotification(
                user_id=current_user.id,
                title="Nhận thu nhập mới",
                message=f"Bạn nhận {worker_earnings:,.0f}đ (90%) từ đơn #{booking.id}."
            )
            db.add(work_notif)
        else:
            # ⚠️ Chưa thanh toán hoặc giá = 0 → DONE nhưng không cộng tiền
            worker.total_jobs = (worker.total_jobs or 0) + 1

        # Customer notification
        cust_notif = models.UserNotification(
            user_id=booking.customer_id,
            title="Dịch vụ hoàn tất",
            message=f"Dịch vụ {service.name if service else ''} đã hoàn tất. Vui lòng để lại đánh giá!"
        )
        db.add(cust_notif)
        
    booking.status = status_update
    db.commit()
    db.refresh(booking)
    return booking

@router.get("/history", response_model=List[schemas.BookingResponse])
def get_worker_history(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_worker)):
    worker = db.query(models.Worker).filter(models.Worker.user_id == current_user.id).first()
    if not worker:
        return []
        
    bookings = db.query(models.Booking).filter(
        models.Booking.worker_id == worker.id,
        models.Booking.status == models.BookingStatusEnum.DONE
    ).all()
    return bookings

@router.get("/jobs/my", response_model=List[schemas.BookingResponse])
def get_my_jobs(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_worker)):
    worker = db.query(models.Worker).filter(models.Worker.user_id == current_user.id).first()
    if not worker:
        return []
        
    bookings = db.query(models.Booking).filter(
        models.Booking.worker_id == worker.id
    ).order_by(models.Booking.id.desc()).all()
    return bookings

@router.get("/reviews", response_model=List[schemas.ReviewResponse])
def get_worker_reviews(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_worker)):
    worker = db.query(models.Worker).filter(models.Worker.user_id == current_user.id).first()
    if not worker:
        return []
        
    worker_bookings = db.query(models.Booking).filter(
        models.Booking.worker_id == worker.id,
        models.Booking.status == models.BookingStatusEnum.DONE
    ).all()
    booking_ids = [b.id for b in worker_bookings]
    reviews = db.query(models.Review).filter(models.Review.booking_id.in_(booking_ids)).all()
    return reviews


# ==========================================
# EXTRA WORKER CALENDAR / WALLET / UPLOAD API
# ==========================================

@router.get("/calendar", response_model=List[schemas.WorkerCalendarResponse])
def get_worker_calendar(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_worker)):
    worker = db.query(models.Worker).filter(models.Worker.user_id == current_user.id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker profile not found")
    calendar = db.query(models.WorkerCalendar).filter(models.WorkerCalendar.worker_id == worker.id).all()
    return calendar

@router.post("/calendar/register-off", response_model=schemas.WorkerCalendarResponse)
def register_off_day(calendar_in: schemas.WorkerCalendarCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_worker)):
    worker = db.query(models.Worker).filter(models.Worker.user_id == current_user.id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker profile not found")
    
    # Check if entry already exists
    existing = db.query(models.WorkerCalendar).filter(
        models.WorkerCalendar.worker_id == worker.id,
        models.WorkerCalendar.date == calendar_in.date
    ).first()
    
    if existing:
        existing.is_off = calendar_in.is_off
        existing.note = calendar_in.note
        db.commit()
        db.refresh(existing)
        return existing
        
    new_slot = models.WorkerCalendar(
        worker_id=worker.id,
        date=calendar_in.date,
        is_off=calendar_in.is_off,
        note=calendar_in.note
    )
    db.add(new_slot)
    db.commit()
    db.refresh(new_slot)
    return new_slot

@router.get("/earnings/stats")
def get_worker_earnings_stats(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_worker)):
    worker = db.query(models.Worker).filter(models.Worker.user_id == current_user.id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker profile not found")
        
    # Get all earnings transactions
    txs = db.query(models.Transaction).filter(
        models.Transaction.worker_id == worker.id,
        models.Transaction.type == "earnings"
    ).all()
    
    now = datetime.utcnow()
    # Start of today, start of week (Monday), start of month
    start_of_today = datetime(now.year, now.month, now.day)
    start_of_week = start_of_today - timedelta(days=now.weekday())
    start_of_month = datetime(now.year, now.month, 1)
    
    today_total = 0.0
    week_total = 0.0
    month_total = 0.0
    
    chart_data = [] # List of {"label": str, "amount": float} for last 7 days
    # Let's populate last 7 days chart data
    last_7_days = []
    for i in range(6, -1, -1):
        day_date = start_of_today - timedelta(days=i)
        last_7_days.append(day_date)
        chart_data.append({"label": day_date.strftime("%d/%m"), "amount": 0.0})
        
    for tx in txs:
        tx_time = tx.created_at
        if tx_time >= start_of_today:
            today_total += tx.amount
        if tx_time >= start_of_week:
            week_total += tx.amount
        if tx_time >= start_of_month:
            month_total += tx.amount
            
        for idx, day_date in enumerate(last_7_days):
            if tx_time.date() == day_date.date():
                chart_data[idx]["amount"] += tx.amount
                
    return {
        "today": today_total,
        "this_week": week_total,
        "this_month": month_total,
        "chart_data": chart_data
    }

@router.get("/wallet/transactions", response_model=List[schemas.TransactionResponse])
def get_worker_wallet_transactions(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_worker)):
    worker = db.query(models.Worker).filter(models.Worker.user_id == current_user.id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker profile not found")
        
    txs = db.query(models.Transaction).filter(models.Transaction.worker_id == worker.id).order_by(models.Transaction.created_at.desc()).all()
    return txs

UPLOAD_DIR = "static/uploads"

@router.post("/bookings/{booking_id}/upload-photos")
def upload_booking_photo(
    booking_id: int,
    photo_type: str = Form(...), # "before" or "after"
    file: UploadFile = File(...),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_worker)
):
    if photo_type not in ["before", "after"]:
        raise HTTPException(status_code=400, detail="Invalid photo type. Must be 'before' or 'after'")
        
    worker = db.query(models.Worker).filter(models.Worker.user_id == current_user.id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker profile not found")
        
    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id,
        models.Booking.worker_id == worker.id
    ).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found or not assigned to you")
        
    # Create directory if not exists
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    
    # Save file
    file_ext = os.path.splitext(file.filename)[1]
    filename = f"{booking_id}_{photo_type}_{int(time.time())}{file_ext}"
    filepath = os.path.join(UPLOAD_DIR, filename)
    
    with open(filepath, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    relative_path = f"/static/uploads/{filename}"
    
    if photo_type == "before":
        booking.before_image = relative_path
    else:
        booking.after_image = relative_path
        
    db.commit()
    db.refresh(booking)
    
    return {"image_url": relative_path, "message": "Tải ảnh lên thành công"}

@router.put("/bookings/{booking_id}/state", response_model=schemas.BookingResponse)
def update_booking_state_alias(
    booking_id: int,
    status_update: models.BookingStatusEnum,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_worker)
):
    return update_job_status(booking_id, status_update, db, current_user)
