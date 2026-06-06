from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, time, date

import database
import models
import schemas
import auth_utils

router = APIRouter(prefix="/workers", tags=["Workers"])

# Helper class for availability update request body
class AvailabilityUpdate(BaseModel):
    is_available: bool

# Dependency to check if the current user is a worker
async def get_current_worker(current_user: models.User = Depends(auth_utils.get_current_user)):
    if current_user.role != models.RoleEnum.WORKER:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized as worker"
        )
    return current_user


# ==========================================
# CRUD FUNCTIONS (Internal Helpers)
# ==========================================

def create_worker(db: Session, worker_create: schemas.WorkerCreate, user_id: int) -> models.Worker:
    user = db.query(models.User).filter(models.User.id == user_id).first()
    
    db_worker = models.Worker(
        user_id=user_id,
        full_name=worker_create.full_name or (user.full_name if user else None),
        email=worker_create.email or (user.email if user else None),
        phone=worker_create.phone,
        avatar_url=worker_create.avatar_url,
        gender=worker_create.gender,
        birth_date=worker_create.birth_date,
        address=worker_create.address,
        city=worker_create.city,
        district=worker_create.district,
        job_title=worker_create.job_title,
        experience_years=worker_create.experience_years or 0,
        skills=worker_create.skills,
        description=worker_create.description,
        is_available=worker_create.is_available or False,
        latitude=worker_create.latitude,
        longitude=worker_create.longitude,
        identity_number=worker_create.identity_number,
        identity_front_image=worker_create.identity_front_image,
        identity_back_image=worker_create.identity_back_image,
        bank_name=worker_create.bank_name,
        bank_account_number=worker_create.bank_account_number,
        bank_account_holder=worker_create.bank_account_holder,
        status="approved"
    )
    db.add(db_worker)
    db.commit()
    db.refresh(db_worker)
    return db_worker

def get_worker_by_user_id(db: Session, user_id: int) -> models.Worker:
    return db.query(models.Worker).filter(models.Worker.user_id == user_id).first()

def update_worker(db: Session, db_worker: models.Worker, worker_update: schemas.WorkerUpdate) -> models.Worker:
    update_data = worker_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_worker, key, value)
    
    db_worker.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_worker)
    return db_worker


# ==========================================
# 1. DASHBOARD API
# ==========================================

@router.get("/dashboard")
async def get_worker_dashboard(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_worker)
):
    worker = get_worker_by_user_id(db, current_user.id)
    if not worker:
        # Auto-create if not exists
        worker_create = schemas.WorkerCreate(
            full_name=current_user.full_name,
            email=current_user.email
        )
        worker = create_worker(db, worker_create, current_user.id)
        
    # 1. Total Jobs (Count of all bookings assigned to this worker)
    total_jobs = db.query(models.Booking).filter(
        models.Booking.worker_id == worker.id
    ).count()
    
    # 2. Today's Jobs (Bookings assigned to this worker scheduled today)
    today = date.today()
    start_of_today = datetime.combine(today, time.min)
    end_of_today = datetime.combine(today, time.max)
    
    today_jobs = db.query(models.Booking).filter(
        models.Booking.worker_id == worker.id,
        models.Booking.scheduled_time >= start_of_today,
        models.Booking.scheduled_time <= end_of_today
    ).count()
    
    # 3. Completed Jobs (Bookings assigned to this worker with status = done)
    completed_jobs = db.query(models.Booking).filter(
        models.Booking.worker_id == worker.id,
        models.Booking.status == models.BookingStatusEnum.DONE
    ).count()
    
    # Sync worker model values
    if worker.total_jobs != total_jobs:
        worker.total_jobs = total_jobs
        db.commit()

    return {
        "worker_name": worker.full_name or current_user.full_name or "Nhân viên Thợ",
        "rating": worker.rating or 5.0,
        "total_jobs": total_jobs,
        "today_jobs": today_jobs,
        "completed_jobs": completed_jobs,
        "is_available": worker.is_available,
        "wallet_balance": worker.wallet_balance or 0.0
    }


# ==========================================
# 2. WORKER PROFILE APIs (GET & PUT)
# ==========================================

@router.get("/me", response_model=schemas.WorkerResponse)
async def get_worker_me(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_worker)
):
    worker = get_worker_by_user_id(db, current_user.id)
    if not worker:
        worker_create = schemas.WorkerCreate(
            full_name=current_user.full_name,
            email=current_user.email
        )
        worker = create_worker(db, worker_create, current_user.id)
    return worker


@router.put("/me", response_model=schemas.WorkerResponse)
async def update_worker_me(
    worker_update: schemas.WorkerUpdate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_worker)
):
    worker = get_worker_by_user_id(db, current_user.id)
    if not worker:
        worker_create = schemas.WorkerCreate(**worker_update.model_dump())
        worker = create_worker(db, worker_create, current_user.id)
    else:
        worker = update_worker(db, worker, worker_update)
        
    # Sync legacy WorkerProfile is_available to remain backward compatible
    if worker_update.is_available is not None:
        legacy_profile = db.query(models.WorkerProfile).filter(models.WorkerProfile.user_id == current_user.id).first()
        if legacy_profile:
            legacy_profile.is_available = worker_update.is_available
            db.commit()
            
    return worker


@router.put("/me/availability", response_model=schemas.WorkerResponse)
async def update_my_availability(
    payload: AvailabilityUpdate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_worker)
):
    worker = get_worker_by_user_id(db, current_user.id)
    if not worker:
        worker_create = schemas.WorkerCreate(is_available=payload.is_available)
        worker = create_worker(db, worker_create, current_user.id)
    else:
        worker.is_available = payload.is_available
        worker.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(worker)
        
    # Sync legacy WorkerProfile is_available to remain backward compatible
    legacy_profile = db.query(models.WorkerProfile).filter(models.WorkerProfile.user_id == current_user.id).first()
    if legacy_profile:
        legacy_profile.is_available = payload.is_available
        db.commit()
        
    return worker


# ==========================================
# 3. PENDING JOBS API
# ==========================================

@router.get("/jobs/pending")
async def get_pending_jobs(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_worker)
):
    # Fetch all bookings with status 'pending', joined with services
    pending_bookings = db.query(models.Booking).join(models.Service).filter(
        models.Booking.status == models.BookingStatusEnum.PENDING
    ).all()
    
    result = []
    for b in pending_bookings:
        result.append({
            "booking_id": b.id,
            "service_name": b.service.name if b.service else "Dịch vụ tiện ích",
            "address": b.address,
            "scheduled_time": b.scheduled_time,
            "price": b.service.price if b.service else 0.0,
            "status": b.status,
            "note": b.note
        })
    return result


# ==========================================
# 4. ACCEPT JOB API
# ==========================================

@router.post("/jobs/{booking_id}/accept")
async def accept_job(
    booking_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_worker)
):
    worker = get_worker_by_user_id(db, current_user.id)
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Worker profile not found"
        )

    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    if booking.status != models.BookingStatusEnum.PENDING or booking.worker_id is not None:
        raise HTTPException(status_code=400, detail="Booking is not pending or already accepted")
        
    booking.worker_id = worker.id
    booking.status = models.BookingStatusEnum.ACCEPTED
    db.commit()
    db.refresh(booking)
    
    return {
        "booking_id": booking.id,
        "service_name": booking.service.name if booking.service else "Dịch vụ tiện ích",
        "address": booking.address,
        "scheduled_time": booking.scheduled_time,
        "price": booking.service.price if booking.service else 0.0,
        "status": booking.status,
        "note": booking.note
    }


# ==========================================
# 5. CURRENT JOB API
# ==========================================

@router.get("/current-job")
async def get_current_job(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_worker)
):
    worker = get_worker_by_user_id(db, current_user.id)
    if not worker:
        return None
        
    # Fetch job with status IN ('accepted', 'in_progress') for the current worker, joined with services
    current_booking = db.query(models.Booking).join(models.Service).filter(
        models.Booking.worker_id == worker.id,
        models.Booking.status.in_([models.BookingStatusEnum.ACCEPTED, models.BookingStatusEnum.IN_PROGRESS])
    ).first()
    
    if not current_booking:
        return None
        
    return {
        "booking_id": current_booking.id,
        "service_name": current_booking.service.name if current_booking.service else "Dịch vụ tiện ích",
        "address": current_booking.address,
        "scheduled_time": current_booking.scheduled_time,
        "price": current_booking.service.price if current_booking.service else 0.0,
        "status": current_booking.status,
        "note": current_booking.note
    }


# ==========================================
# 6. UPDATE JOB STATUS API
# ==========================================

@router.put("/jobs/{booking_id}/status")
async def update_job_status(
    booking_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_worker)
):
    worker = get_worker_by_user_id(db, current_user.id)
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Worker profile not found"
        )

    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id,
        models.Booking.worker_id == worker.id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found or not assigned to you")
        
    if booking.status == models.BookingStatusEnum.ACCEPTED:
        booking.status = models.BookingStatusEnum.IN_PROGRESS
    elif booking.status == models.BookingStatusEnum.IN_PROGRESS:
        booking.status = models.BookingStatusEnum.DONE
    else:
        raise HTTPException(status_code=400, detail=f"Cannot transition status from {booking.status}")
        
    db.commit()
    db.refresh(booking)
    
    return {
        "booking_id": booking.id,
        "service_name": booking.service.name if booking.service else "Dịch vụ tiện ích",
        "address": booking.address,
        "scheduled_time": booking.scheduled_time,
        "price": booking.service.price if booking.service else 0.0,
        "status": booking.status,
        "note": booking.note
    }


# ==========================================
# 7. JOB HISTORY API
# ==========================================

@router.get("/history")
async def get_worker_history(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_worker)
):
    worker = get_worker_by_user_id(db, current_user.id)
    if not worker:
        return []
        
    # Fetch all finished bookings assigned to this worker, joined with services
    history_bookings = db.query(models.Booking).join(models.Service).filter(
        models.Booking.worker_id == worker.id,
        models.Booking.status == models.BookingStatusEnum.DONE
    ).all()
    
    result = []
    for b in history_bookings:
        result.append({
            "booking_id": b.id,
            "service_name": b.service.name if b.service else "Dịch vụ tiện ích",
            "address": b.address,
            "scheduled_time": b.scheduled_time,
            "price": b.service.price if b.service else 0.0,
            "status": b.status,
            "note": b.note
        })
    return result


# ==========================================
# 8. GET ACTIVE SKILL CATEGORIES
# ==========================================

@router.get("/skills/categories", response_model=List[schemas.SkillCategoryResponse])
async def get_skill_categories(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth_utils.get_current_user)
):
    return db.query(models.SkillCategory).filter(models.SkillCategory.is_active == True).all()


# ==========================================
# 9. GET WORKER BY ID (Public Route)
# ==========================================

@router.get("/{worker_id}", response_model=schemas.WorkerResponse)
async def get_worker_profile_by_id(
    worker_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth_utils.get_current_user)
):
    worker = db.query(models.Worker).filter(models.Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Worker profile not found"
        )
    return worker


# ==========================================
# 10. SUBMIT WITHDRAWAL REQUEST
# ==========================================

@router.post("/withdraw", response_model=schemas.WithdrawalResponse)
async def withdraw_money(
    payload: schemas.WithdrawalCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_worker)
):
    worker = get_worker_by_user_id(db, current_user.id)
    if not worker:
        raise HTTPException(status_code=404, detail="Worker profile not found")
        
    if worker.wallet_balance is None:
        worker.wallet_balance = 0.0
        
    if worker.wallet_balance < payload.amount:
        raise HTTPException(status_code=400, detail="Insufficient wallet balance")
        
    req = models.WithdrawalRequest(
        worker_id=worker.id,
        amount=payload.amount,
        status="pending"
    )
    db.add(req)
    db.commit()
    db.refresh(req)
    return req


# ==========================================
# 11. SUBMIT TICKET / COMPLAINT
# ==========================================

@router.post("/tickets", response_model=schemas.TicketResponse)
async def create_worker_ticket(
    ticket: schemas.TicketCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_worker)
):
    new_ticket = models.Ticket(
        creator_id=current_user.id,
        booking_id=ticket.booking_id,
        title=ticket.title,
        description=ticket.description,
        status="pending"
    )
    db.add(new_ticket)
    db.commit()
    db.refresh(new_ticket)
    return new_ticket

