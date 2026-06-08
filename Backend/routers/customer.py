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
        note=booking.note,
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
        worker_info = db.query(models.Worker).filter(models.Worker.id == booking.worker_id).first()
        if worker_info:
            worker_bookings = db.query(models.Booking).filter(
                models.Booking.worker_id == booking.worker_id,
                models.Booking.status == models.BookingStatusEnum.DONE
            ).all()
            
            booking_ids = [b.id for b in worker_bookings]
            all_reviews = db.query(models.Review).filter(models.Review.booking_id.in_(booking_ids)).all()
            
            total_rating = sum([r.rating for r in all_reviews]) + review.rating
            count = len(all_reviews) + 1
            avg_rating = total_rating / count
            
            worker_info.rating = avg_rating
            worker_info.total_reviews = count
            
            # Sync to legacy WorkerProfile for backward compatibility
            worker_profile = db.query(models.WorkerProfile).filter(models.WorkerProfile.user_id == worker_info.user_id).first()
            if worker_profile:
                worker_profile.rating = avg_rating

    db.commit()
    db.refresh(new_review)
    return new_review


# ==========================================
# EXTRA CUSTOMER / CHAT / NOTIFICATION API
# ==========================================

@router.get("/favorites", response_model=List[schemas.ServiceResponse])
def get_favorites(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_customer)):
    favorites = db.query(models.Favorite).filter(models.Favorite.customer_id == current_user.id).all()
    service_ids = [fav.service_id for fav in favorites]
    services = db.query(models.Service).filter(models.Service.id.in_(service_ids)).all()
    return services

@router.post("/favorites", response_model=schemas.FavoriteResponse)
def add_favorite(fav_in: schemas.FavoriteCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_customer)):
    service = db.query(models.Service).filter(models.Service.id == fav_in.service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    existing = db.query(models.Favorite).filter(
        models.Favorite.customer_id == current_user.id,
        models.Favorite.service_id == fav_in.service_id
    ).first()
    if existing:
        return existing
    new_fav = models.Favorite(customer_id=current_user.id, service_id=fav_in.service_id)
    db.add(new_fav)
    db.commit()
    db.refresh(new_fav)
    return new_fav

@router.delete("/favorites/{service_id}")
def remove_favorite(service_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_customer)):
    existing = db.query(models.Favorite).filter(
        models.Favorite.customer_id == current_user.id,
        models.Favorite.service_id == service_id
    ).first()
    if not existing:
        raise HTTPException(status_code=404, detail="Favorite not found")
    db.delete(existing)
    db.commit()
    return {"message": "Success"}

@router.get("/addresses", response_model=List[schemas.SavedAddressResponse])
def get_saved_addresses(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_customer)):
    addresses = db.query(models.SavedAddress).filter(models.SavedAddress.customer_id == current_user.id).all()
    return addresses

@router.post("/addresses", response_model=schemas.SavedAddressResponse)
def add_saved_address(addr_in: schemas.SavedAddressCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_customer)):
    new_addr = models.SavedAddress(
        customer_id=current_user.id,
        label=addr_in.label,
        address_text=addr_in.address_text,
        latitude=addr_in.latitude,
        longitude=addr_in.longitude
    )
    db.add(new_addr)
    db.commit()
    db.refresh(new_addr)
    return new_addr

@router.get("/bookings/{booking_id}/chat", response_model=List[schemas.ChatMessageResponse])
def get_chat_messages(booking_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth_utils.get_current_user)):
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    is_authorized = (booking.customer_id == current_user.id or 
                     (booking.worker_id is not None and booking.worker.user_id == current_user.id) or
                     current_user.role in [models.RoleEnum.SUPPORT, models.RoleEnum.ADMIN])
    if not is_authorized:
        raise HTTPException(status_code=403, detail="Not authorized to view this chat")
        
    messages = db.query(models.ChatMessage).filter(models.ChatMessage.booking_id == booking_id).order_by(models.ChatMessage.created_at.asc()).all()
    return messages

@router.post("/bookings/{booking_id}/chat", response_model=schemas.ChatMessageResponse)
def send_chat_message(booking_id: int, msg_in: schemas.ChatMessageCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth_utils.get_current_user)):
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    is_authorized = (booking.customer_id == current_user.id or 
                     (booking.worker_id is not None and booking.worker.user_id == current_user.id) or
                     current_user.role in [models.RoleEnum.SUPPORT, models.RoleEnum.ADMIN])
    if not is_authorized:
        raise HTTPException(status_code=403, detail="Not authorized to chat in this booking")
        
    new_msg = models.ChatMessage(
        booking_id=booking_id,
        sender_id=current_user.id,
        message_text=msg_in.message_text
    )
    db.add(new_msg)
    
    recipient_id = None
    if current_user.id == booking.customer_id:
        if booking.worker_id:
            recipient_id = booking.worker.user_id
    else:
        recipient_id = booking.customer_id
        
    if recipient_id:
        notif = models.UserNotification(
            user_id=recipient_id,
            title=f"Tin nhắn mới từ {current_user.full_name}",
            message=msg_in.message_text[:100]
        )
        db.add(notif)
        
    db.commit()
    db.refresh(new_msg)
    return new_msg

@router.get("/notifications", response_model=List[schemas.UserNotificationResponse])
def get_user_notifications(db: Session = Depends(database.get_db), current_user: models.User = Depends(auth_utils.get_current_user)):
    notifications = db.query(models.UserNotification).filter(models.UserNotification.user_id == current_user.id).order_by(models.UserNotification.created_at.desc()).all()
    return notifications

@router.put("/notifications/{notification_id}/read", response_model=schemas.UserNotificationResponse)
def mark_notification_read(notification_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth_utils.get_current_user)):
    notif = db.query(models.UserNotification).filter(
        models.UserNotification.id == notification_id,
        models.UserNotification.user_id == current_user.id
    ).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")
    notif.is_read = True
    db.commit()
    db.refresh(notif)
    return notif


@router.post("/tickets", response_model=schemas.TicketResponse)
def create_ticket(ticket: schemas.TicketCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_customer)):
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

