from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from pydantic import BaseModel

import database
import models
import schemas
import auth_utils

router = APIRouter(prefix="/support", tags=["Support"])


def get_current_support(current_user: models.User = Depends(auth_utils.get_current_user)):
    if current_user.role not in [models.RoleEnum.SUPPORT, models.RoleEnum.ADMIN]:
        raise HTTPException(status_code=403, detail="Not authorized as support")
    return current_user

@router.get("/bookings")
def get_all_bookings(status: str = None, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    """Trả về danh sách đơn hàng kèm thông tin khách hàng và thợ"""
    query = db.query(models.Booking)
    if status is not None:
        query = query.filter(models.Booking.status == status)
    bookings = query.all()
    
    result = []
    for b in bookings:
        # Tên khách hàng
        customer_name = None
        customer_username = None
        if b.customer:
            customer_name = b.customer.full_name
            customer_username = b.customer.username
        
        # Tên thợ và thông tin
        worker_name = None
        if b.worker and b.worker.user:
            worker_name = b.worker.user.full_name
        elif b.worker_id:
            worker_name = f"Thợ #{b.worker_id}"
        
        # Tên dịch vụ và giá
        service_name = b.service.name if b.service else None
        price = float(b.service.price) if b.service and b.service.price is not None else 0.0
        
        result.append({
            "booking_id": b.id,
            "id": b.id,
            "customer_id": b.customer_id,
            "customer_name": customer_name,
            "customer_username": customer_username,
            "worker_id": b.worker_id,
            "worker_name": worker_name,
            "service_id": b.service_id,
            "service_name": service_name,
            "price": price,
            "scheduled_time": b.scheduled_time.isoformat() if b.scheduled_time else None,
            "address": b.address,
            "note": b.note,
            "status": b.status.value if hasattr(b.status, 'value') else b.status,
            "before_image": b.before_image,
            "after_image": b.after_image,
            "created_at": b.created_at.isoformat() if b.created_at else None,
            "updated_at": b.updated_at.isoformat() if b.updated_at else None,
        })
    
    return result

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


# --- Quản lý Chat và Hỗ trợ Khách hàng ---

@router.get("/bookings/{booking_id}/chat", response_model=List[schemas.ChatMessageResponse])
def get_booking_chat(booking_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    """Lấy lịch sử trò chuyện của một đơn hàng"""
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    messages = db.query(models.ChatMessage).filter(
        models.ChatMessage.booking_id == booking_id
    ).order_by(models.ChatMessage.created_at.asc()).all()
    return messages


@router.post("/bookings/{booking_id}/chat", response_model=schemas.ChatMessageResponse)
def send_support_message(booking_id: int, payload: schemas.ChatMessageCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    """Support gửi tin nhắn đến khách hàng/thợ về một đơn hàng"""
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    message = models.ChatMessage(
        booking_id=booking_id,
        sender_id=current_user.id,
        message_text=payload.message_text
    )
    db.add(message)
    db.commit()
    db.refresh(message)
    return message


# --- Quản lý Giao dịch và Ví ---

@router.get("/workers/{worker_id}/transactions", response_model=List[schemas.TransactionResponse])
def get_worker_transactions(worker_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    """Xem lịch sử giao dịch của một thợ"""
    worker = db.query(models.Worker).filter(models.Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    
    transactions = db.query(models.Transaction).filter(
        models.Transaction.worker_id == worker_id
    ).order_by(models.Transaction.created_at.desc()).all()
    return transactions


@router.get("/workers/{worker_id}/wallet")
def get_worker_wallet(worker_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    """Xem số dư ví của một thợ"""
    worker = db.query(models.Worker).filter(models.Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    
    return {
        "worker_id": worker.id,
        "balance": worker.wallet_balance or 0.0,
        "full_name": worker.full_name,
        "status": worker.status
    }


# --- Quản lý Hỗ trợ cho Khách hàng & Thợ ---

@router.post("/tickets/{ticket_id}/comment")
def add_ticket_comment(ticket_id: int, payload: BaseModel, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    """Thêm bình luận admin vào ticket"""
    from pydantic import Field
    
    class CommentPayload(BaseModel):
        comment: str
    
    ticket = db.query(models.Ticket).filter(models.Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    comment_payload = payload if isinstance(payload, dict) else {'comment': str(payload)}
    ticket.admin_comment = comment_payload.get('comment', '')
    ticket.updated_at = datetime.utcnow()
    
    log = models.SupportActivityLog(
        support_id=current_user.id,
        action="add_ticket_comment",
        details=f"Added comment to ticket {ticket_id}"
    )
    db.add(log)
    db.commit()
    db.refresh(ticket)
    
    return {"message": "Comment added successfully", "ticket": ticket}


@router.get("/support-stats")
def get_support_stats(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    """Lấy thống kê của team support"""
    total_tickets = db.query(models.Ticket).count()
    pending_tickets = db.query(models.Ticket).filter(models.Ticket.status == "pending").count()
    in_progress_tickets = db.query(models.Ticket).filter(models.Ticket.status == "in_progress").count()
    
    total_bookings = db.query(models.Booking).count()
    pending_bookings = db.query(models.Booking).filter(models.Booking.status.in_([
        models.BookingStatusEnum.PENDING_PAYMENT,
        models.BookingStatusEnum.PENDING
    ])).count()
    
    total_workers = db.query(models.Worker).count()
    pending_workers = db.query(models.Worker).filter(models.Worker.status == "pending").count()
    
    return {
        "total_tickets": total_tickets,
        "pending_tickets": pending_tickets,
        "in_progress_tickets": in_progress_tickets,
        "total_bookings": total_bookings,
        "pending_bookings": pending_bookings,
        "total_workers": total_workers,
        "pending_workers": pending_workers
    }


@router.post("/bookings/{booking_id}/unlock-worker")
def unlock_worker_for_booking(booking_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_support)):
    """Mở khóa thợ bị khóa để nhận công việc mới"""
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking or not booking.worker_id:
        raise HTTPException(status_code=404, detail="Booking or worker not found")
    
    worker = db.query(models.Worker).filter(models.Worker.id == booking.worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    
    worker.status = "approved"
    
    log = models.SupportActivityLog(
        support_id=current_user.id,
        action="unlock_worker",
        details=f"Unlocked worker ID {worker.id} for booking {booking_id}"
    )
    db.add(log)
    db.commit()
    db.refresh(worker)
    
    return {"message": "Worker unlocked successfully", "worker": worker}



