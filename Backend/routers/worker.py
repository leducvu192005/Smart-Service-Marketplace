from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

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
        models.Booking.status == models.BookingStatusEnum.PENDING,
        models.Booking.worker_id == None
    ).all()
    return bookings

@router.post("/jobs/{booking_id}/accept", response_model=schemas.BookingResponse)
def accept_job(booking_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_worker)):
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    if booking.status != models.BookingStatusEnum.PENDING:
        raise HTTPException(status_code=400, detail="Booking is not pending")
        
    booking.worker_id = current_user.id
    booking.status = models.BookingStatusEnum.ACCEPTED
    db.commit()
    db.refresh(booking)
    return booking

@router.put("/jobs/{booking_id}/status", response_model=schemas.BookingResponse)
def update_job_status(booking_id: int, status_update: models.BookingStatusEnum, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_worker)):
    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id,
        models.Booking.worker_id == current_user.id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found or not assigned to you")
        
    booking.status = status_update
    db.commit()
    db.refresh(booking)
    return booking

@router.get("/history", response_model=List[schemas.BookingResponse])
def get_worker_history(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_worker)):
    bookings = db.query(models.Booking).filter(
        models.Booking.worker_id == current_user.id,
        models.Booking.status == models.BookingStatusEnum.DONE
    ).all()
    return bookings
