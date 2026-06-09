from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

import database
import models
import schemas
import auth_utils

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("/my", response_model=List[schemas.UserNotificationResponse])
def get_my_notifications(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth_utils.get_current_user)
):
    """Lấy tất cả thông báo của người dùng hiện tại"""
    notifications = db.query(models.UserNotification).filter(
        models.UserNotification.user_id == current_user.id
    ).order_by(models.UserNotification.created_at.desc()).all()
    return notifications


@router.get("/my/unread", response_model=List[schemas.UserNotificationResponse])
def get_unread_notifications(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth_utils.get_current_user)
):
    """Lấy tất cả thông báo chưa đọc"""
    notifications = db.query(models.UserNotification).filter(
        models.UserNotification.user_id == current_user.id,
        models.UserNotification.is_read == False
    ).order_by(models.UserNotification.created_at.desc()).all()
    return notifications


@router.put("/my/{notification_id}/read", response_model=schemas.UserNotificationResponse)
def mark_notification_as_read(
    notification_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth_utils.get_current_user)
):
    """Đánh dấu thông báo đã đọc"""
    notif = db.query(models.UserNotification).filter(
        models.UserNotification.id == notification_id,
        models.UserNotification.user_id == current_user.id
    ).first()
    
    if not notif:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    
    notif.is_read = True
    db.commit()
    db.refresh(notif)
    return notif


@router.put("/my/read-all")
def mark_all_notifications_as_read(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth_utils.get_current_user)
):
    """Đánh dấu tất cả thông báo là đã đọc"""
    db.query(models.UserNotification).filter(
        models.UserNotification.user_id == current_user.id,
        models.UserNotification.is_read == False
    ).update({"is_read": True}, synchronize_session=False)
    
    db.commit()
    return {"message": "All notifications marked as read"}


@router.delete("/my/{notification_id}")
def delete_notification(
    notification_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth_utils.get_current_user)
):
    """Xóa một thông báo"""
    notif = db.query(models.UserNotification).filter(
        models.UserNotification.id == notification_id,
        models.UserNotification.user_id == current_user.id
    ).first()
    
    if not notif:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    
    db.delete(notif)
    db.commit()
    return {"message": "Notification deleted successfully"}


@router.get("/stats")
def get_notification_stats(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth_utils.get_current_user)
):
    """Lấy thống kê thông báo của người dùng"""
    total = db.query(models.UserNotification).filter(
        models.UserNotification.user_id == current_user.id
    ).count()
    
    unread = db.query(models.UserNotification).filter(
        models.UserNotification.user_id == current_user.id,
        models.UserNotification.is_read == False
    ).count()
    
    return {
        "total": total,
        "unread": unread,
        "read": total - unread
    }


# --- ADMIN: Gửi thông báo broadcast tới tất cả hoặc một nhóm người dùng ---

def get_current_admin(current_user: models.User = Depends(auth_utils.get_current_user)):
    if current_user.role != models.RoleEnum.ADMIN:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized as admin")
    return current_user


@router.post("/broadcast")
def broadcast_notification(
    payload: schemas.NotificationCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_admin)
):
    """
    ADMIN: Gửi thông báo broadcast tới:
    - "all": tất cả người dùng
    - "customer": tất cả khách hàng
    - "worker": tất cả thợ
    - "support": tất cả support
    """
    recipient_role = payload.recipient_role or "all"
    
    # Xác định target users
    if recipient_role == "all":
        target_users = db.query(models.User).filter(models.User.is_active == True).all()
    elif recipient_role == "customer":
        target_users = db.query(models.User).filter(
            models.User.role == models.RoleEnum.CUSTOMER,
            models.User.is_active == True
        ).all()
    elif recipient_role == "worker":
        target_users = db.query(models.User).filter(
            models.User.role == models.RoleEnum.WORKER,
            models.User.is_active == True
        ).all()
    elif recipient_role == "support":
        target_users = db.query(models.User).filter(
            models.User.role == models.RoleEnum.SUPPORT,
            models.User.is_active == True
        ).all()
    else:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid recipient_role")
    
    # Tạo notification cho mỗi user
    notifications = []
    for user in target_users:
        notif = models.UserNotification(
            user_id=user.id,
            title=payload.title,
            message=payload.message
        )
        notifications.append(notif)
    
    db.add_all(notifications)
    db.commit()
    
    return {
        "message": f"Broadcast notification sent to {len(notifications)} users",
        "recipient_role": recipient_role,
        "count": len(notifications)
    }


@router.post("/send-to-role")
def send_notification_to_role(
    role: str,
    payload: schemas.NotificationCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_admin)
):
    """
    ADMIN: Gửi thông báo tới một nhóm role cụ thể
    """
    role_map = {
        "customer": models.RoleEnum.CUSTOMER,
        "worker": models.RoleEnum.WORKER,
        "support": models.RoleEnum.SUPPORT,
        "admin": models.RoleEnum.ADMIN
    }
    
    if role not in role_map:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid role")
    
    target_users = db.query(models.User).filter(
        models.User.role == role_map[role],
        models.User.is_active == True
    ).all()
    
    notifications = []
    for user in target_users:
        notif = models.UserNotification(
            user_id=user.id,
            title=payload.title,
            message=payload.message
        )
        notifications.append(notif)
    
    db.add_all(notifications)
    db.commit()
    
    return {
        "message": f"Notification sent to {len(notifications)} {role}(s)",
        "role": role,
        "count": len(notifications)
    }


# --- SUPPORT: Gửi thông báo cho khách hàng/thợ liên quan tới đơn hàng ---

def get_current_support(current_user: models.User = Depends(auth_utils.get_current_user)):
    if current_user.role not in [models.RoleEnum.SUPPORT, models.RoleEnum.ADMIN]:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized as support")
    return current_user


@router.post("/booking/{booking_id}/notify-all")
def notify_booking_parties(
    booking_id: int,
    payload: schemas.NotificationCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_support)
):
    """
    SUPPORT: Gửi thông báo tới khách hàng và thợ của một đơn hàng
    """
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    
    notifications = []
    
    # Thông báo cho khách hàng
    cust_notif = models.UserNotification(
        user_id=booking.customer_id,
        title=payload.title,
        message=payload.message
    )
    notifications.append(cust_notif)
    
    # Thông báo cho thợ (nếu có)
    if booking.worker_id:
        worker = db.query(models.Worker).filter(models.Worker.id == booking.worker_id).first()
        if worker:
            worker_notif = models.UserNotification(
                user_id=worker.user_id,
                title=payload.title,
                message=payload.message
            )
            notifications.append(worker_notif)
    
    db.add_all(notifications)
    db.commit()
    
    return {
        "message": f"Notification sent to {len(notifications)} people (customer + worker)",
        "booking_id": booking_id,
        "count": len(notifications)
    }


@router.post("/booking/{booking_id}/notify-customer")
def notify_customer(
    booking_id: int,
    payload: schemas.NotificationCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_support)
):
    """
    SUPPORT: Gửi thông báo chỉ cho khách hàng của một đơn hàng
    """
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    
    notif = models.UserNotification(
        user_id=booking.customer_id,
        title=payload.title,
        message=payload.message
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)
    
    return {
        "message": "Notification sent to customer",
        "booking_id": booking_id,
        "notification": notif
    }


@router.post("/booking/{booking_id}/notify-worker")
def notify_worker(
    booking_id: int,
    payload: schemas.NotificationCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_support)
):
    """
    SUPPORT: Gửi thông báo chỉ cho thợ của một đơn hàng
    """
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    
    if not booking.worker_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="This booking has no assigned worker")
    
    worker = db.query(models.Worker).filter(models.Worker.id == booking.worker_id).first()
    if not worker:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Worker not found")
    
    notif = models.UserNotification(
        user_id=worker.user_id,
        title=payload.title,
        message=payload.message
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)
    
    return {
        "message": "Notification sent to worker",
        "booking_id": booking_id,
        "notification": notif
    }
