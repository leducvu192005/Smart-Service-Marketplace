from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

import database
import models
import schemas
import auth_utils

router = APIRouter(prefix="/support", tags=["Support"])

def get_current_support(current_user: models.User = Depends(auth_utils.get_current_user)):
    if current_user.role not in [models.RoleEnum.SUPPORT, models.RoleEnum.ADMIN]:
        raise HTTPException(status_code=403, detail="Not authorized as support")
    return current_user

@router.get("/bookings", response_model=List[schemas.BookingResponse])
def get_all_bookings(status: models.BookingStatusEnum = None, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    query = db.query(models.Booking)
    if status is not None:
        query = query.filter(models.Booking.status == status)
    return query.all()

@router.post("/bookings/{booking_id}/cancel", response_model=schemas.BookingResponse)
def force_cancel_booking(booking_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    booking.status = models.BookingStatusEnum.CANCELLED
    db.commit()
    db.refresh(booking)
    return booking

@router.post("/bookings/{booking_id}/reassign", response_model=schemas.BookingResponse)
def reassign_worker(booking_id: int, new_worker_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    worker_profile = db.query(models.WorkerProfile).filter(models.WorkerProfile.user_id == new_worker_id).first()
    if not worker_profile:
        raise HTTPException(status_code=404, detail="New worker not found")
        
    booking.worker_id = new_worker_id
    booking.status = models.BookingStatusEnum.ACCEPTED
    db.commit()
    db.refresh(booking)
    return booking
