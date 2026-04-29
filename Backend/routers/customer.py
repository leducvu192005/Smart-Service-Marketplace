from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

import database
import models
import schemas
import auth_utils

router = APIRouter(prefix="/customer", tags=["Customer"])

def get_current_customer(current_user: models.User = Depends(auth_utils.get_current_user)):
    if current_user.role != models.RoleEnum.CUSTOMER:
        raise HTTPException(status_code=403, detail="Not authorized as customer")
    return current_user

@router.get("/categories", response_model=List[schemas.ServiceCategoryResponse])
def get_categories(db: Session = Depends(database.get_db)):
    categories = db.query(models.ServiceCategory).all()
    return categories

@router.get("/services", response_model=List[schemas.ServiceResponse])
def get_services(category_id: int = None, db: Session = Depends(database.get_db)):
    query = db.query(models.Service)
    if category_id:
        query = query.filter(models.Service.category_id == category_id)
    return query.all()

@router.post("/bookings", response_model=schemas.BookingResponse)
def create_booking(booking: schemas.BookingCreate, 
                  db: Session = Depends(database.get_db),
                  current_user: models.User = Depends(get_current_customer)):
    
    # check if service exists
    service = db.query(models.Service).filter(models.Service.id == booking.service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
        
    new_booking = models.Booking(
        customer_id=current_user.id,
        service_id=booking.service_id,
        scheduled_time=booking.scheduled_time,
        address=booking.address,
        status=models.BookingStatusEnum.PENDING
    )
    db.add(new_booking)
    db.commit()
    db.refresh(new_booking)
    return new_booking

@router.get("/bookings", response_model=List[schemas.BookingResponse])
def get_my_bookings(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_customer)):
    bookings = db.query(models.Booking).filter(models.Booking.customer_id == current_user.id).all()
    return bookings

@router.get("/bookings/{booking_id}", response_model=schemas.BookingResponse)
def get_booking_details(booking_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_customer)):
    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id,
        models.Booking.customer_id == current_user.id
    ).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking

@router.post("/reviews", response_model=schemas.ReviewResponse)
def create_review(review: schemas.ReviewCreate, 
                 db: Session = Depends(database.get_db),
                 current_user: models.User = Depends(get_current_customer)):
    
    # Verify booking belongs to customer and is DONE
    booking = db.query(models.Booking).filter(
        models.Booking.id == review.booking_id,
        models.Booking.customer_id == current_user.id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found or not yours")
        
    if booking.status != models.BookingStatusEnum.DONE:
        raise HTTPException(status_code=400, detail="Cannot review a booking that is not completed")
        
    # Check if review already exists
    existing_review = db.query(models.Review).filter(models.Review.booking_id == booking.id).first()
    if existing_review:
        raise HTTPException(status_code=400, detail="Review already exists for this booking")
        
    new_review = models.Review(
        booking_id=review.booking_id,
        rating=review.rating,
        comment=review.comment
    )
    db.add(new_review)
    
    # Update worker rating
    if booking.worker_id:
        worker_profile = db.query(models.WorkerProfile).filter(models.WorkerProfile.user_id == booking.worker_id).first()
        if worker_profile:
            worker_bookings = db.query(models.Booking).filter(
                models.Booking.worker_id == booking.worker_id,
                models.Booking.status == models.BookingStatusEnum.DONE
            ).all()
            
            booking_ids = [b.id for b in worker_bookings]
            all_reviews = db.query(models.Review).filter(models.Review.booking_id.in_(booking_ids)).all()
            
            total_rating = sum([r.rating for r in all_reviews]) + review.rating
            count = len(all_reviews) + 1
            worker_profile.rating = total_rating / count

    db.commit()
    db.refresh(new_review)
    return new_review
