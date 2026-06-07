from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

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
        
    worker_info = db.query(models.Worker).filter(models.Worker.id == new_worker_id).first()
    if not worker_info:
        raise HTTPException(status_code=404, detail="New worker not found")
        
    booking.worker_id = new_worker_id
    booking.status = models.BookingStatusEnum.ACCEPTED
    db.commit()
    db.refresh(booking)
    return booking


# --- Support Management APIs ---

from pydantic import BaseModel
class RescheduleRequest(BaseModel):
    scheduled_time: datetime

class TicketStatusUpdate(BaseModel):
    status: str

class ProposeRefundRequest(BaseModel):
    reason: str
    amount: float


@router.get("/workers/pending", response_model=List[schemas.WorkerResponse])
def get_pending_workers(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    return db.query(models.Worker).filter(models.Worker.status == "pending").all()


@router.post("/workers/{worker_id}/approve", response_model=schemas.WorkerResponse)
def approve_worker(worker_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    worker = db.query(models.Worker).filter(models.Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    worker.status = "approved"
    
    # Sync legacy profile Availability
    legacy_profile = db.query(models.WorkerProfile).filter(models.WorkerProfile.user_id == worker.user_id).first()
    if legacy_profile:
        legacy_profile.is_available = True
    
    # Log support activity
    log = models.SupportActivityLog(
        support_id=current_user.id,
        action="approve_worker",
        details=f"Approved worker ID {worker_id}"
    )
    db.add(log)
    db.commit()
    db.refresh(worker)
    return worker


@router.post("/workers/{worker_id}/reject", response_model=schemas.WorkerResponse)
def reject_worker(worker_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    worker = db.query(models.Worker).filter(models.Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    worker.status = "rejected"
    
    log = models.SupportActivityLog(
        support_id=current_user.id,
        action="reject_worker",
        details=f"Rejected worker ID {worker_id}"
    )
    db.add(log)
    db.commit()
    db.refresh(worker)
    return worker


@router.put("/bookings/{booking_id}/reschedule", response_model=schemas.BookingResponse)
def reschedule_booking(booking_id: int, payload: RescheduleRequest, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    old_time = booking.scheduled_time
    booking.scheduled_time = payload.scheduled_time
    
    log = models.SupportActivityLog(
        support_id=current_user.id,
        action="reschedule_booking",
        details=f"Rescheduled booking {booking_id} from {old_time} to {payload.scheduled_time}"
    )
    db.add(log)
    db.commit()
    db.refresh(booking)
    return booking


@router.get("/tickets", response_model=List[schemas.TicketResponse])
def get_all_tickets(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    return db.query(models.Ticket).all()


@router.put("/tickets/{ticket_id}/status", response_model=schemas.TicketResponse)
def update_ticket_status(ticket_id: int, payload: TicketStatusUpdate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    ticket = db.query(models.Ticket).filter(models.Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    ticket.status = payload.status
    ticket.updated_at = datetime.utcnow()
    
    log = models.SupportActivityLog(
        support_id=current_user.id,
        action="update_ticket_status",
        details=f"Updated ticket {ticket_id} status to {payload.status}"
    )
    db.add(log)
    db.commit()
    db.refresh(ticket)
    return ticket


@router.post("/bookings/{booking_id}/confirm-payment")
def confirm_payment(booking_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    if booking.status == models.BookingStatusEnum.CANCELLED:
         raise HTTPException(status_code=400, detail="Cannot confirm payment for cancelled booking")
         
    # Update status to DONE
    booking.status = models.BookingStatusEnum.DONE
    
    # Calculate amount & commission
    price = float(booking.service.price or 0.0) if booking.service else 0.0
    worker_earnings = 0.9 * price
    
    # Add to worker wallet
    if booking.worker_id:
        worker = db.query(models.Worker).filter(models.Worker.id == booking.worker_id).first()
        if worker:
            if worker.wallet_balance is None:
                worker.wallet_balance = 0.0
            worker.wallet_balance += worker_earnings
            
            # Create transaction record
            txn = models.Transaction(
                worker_id=worker.id,
                booking_id=booking.id,
                amount=worker_earnings,
                type="earnings",
                description=f"Thu nhập 90% từ đơn hàng #{booking.id}"
            )
            db.add(txn)
    
    log = models.SupportActivityLog(
        support_id=current_user.id,
        action="confirm_payment",
        details=f"Confirmed payment for booking {booking_id}. Worker earnings: {worker_earnings}"
    )
    db.add(log)
    db.commit()
    db.refresh(booking)
    
    return {
        "message": "Payment confirmed and worker wallet updated",
        "booking": booking
    }


@router.post("/bookings/{booking_id}/propose-refund", response_model=schemas.RefundRequestResponse)
def propose_refund(booking_id: int, payload: ProposeRefundRequest, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    refund = models.RefundRequest(
        booking_id=booking_id,
        reason=payload.reason,
        amount=payload.amount,
        status="pending"
    )
    db.add(refund)
    
    log = models.SupportActivityLog(
        support_id=current_user.id,
        action="propose_refund",
        details=f"Proposed refund for booking {booking_id} of amount {payload.amount}"
    )
    db.add(log)
    db.commit()
    db.refresh(refund)
    return refund


@router.post("/workers/{worker_id}/lock", response_model=schemas.WorkerResponse)
def lock_worker(worker_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    worker = db.query(models.Worker).filter(models.Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    
    worker.status = "suspended"
    
    log = models.SupportActivityLog(
        support_id=current_user.id,
        action="lock_worker",
        details=f"Suspended worker ID {worker_id}"
    )
    db.add(log)
    db.commit()
    db.refresh(worker)
    return worker


@router.get("/workers", response_model=List[schemas.WorkerResponse])
def get_all_workers(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    return db.query(models.Worker).filter(models.Worker.status == "approved").all()


