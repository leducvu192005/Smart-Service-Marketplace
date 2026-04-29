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
    total_revenue = 0
    for b in bookings_done:
        if b.service:
            total_revenue += b.service.price
            
    return {
        "total_users": total_users,
        "total_workers": total_workers,
        "total_bookings": total_bookings,
        "total_revenue": total_revenue
    }
