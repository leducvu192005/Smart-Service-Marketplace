"""
WebSocket Chat Router
Real-time bidirectional messaging between customer and worker for a booking.
Authentication: JWT token passed as query parameter ?token=<jwt>
"""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, HTTPException
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from typing import Dict, List
import json
from datetime import datetime

import database
import models
import auth_utils

router = APIRouter(prefix="/ws", tags=["WebSocket Chat"])

# ---------------------------------------------------------------------------
# Connection Manager — maintains per-booking rooms
# ---------------------------------------------------------------------------
class ConnectionManager:
    def __init__(self):
        # booking_id -> list of active WebSocket connections
        self.rooms: Dict[int, List[WebSocket]] = {}

    async def connect(self, booking_id: int, websocket: WebSocket):
        await websocket.accept()
        if booking_id not in self.rooms:
            self.rooms[booking_id] = []
        self.rooms[booking_id].append(websocket)

    def disconnect(self, booking_id: int, websocket: WebSocket):
        if booking_id in self.rooms:
            self.rooms[booking_id].discard(websocket) if hasattr(self.rooms[booking_id], 'discard') else None
            try:
                self.rooms[booking_id].remove(websocket)
            except ValueError:
                pass
            if not self.rooms[booking_id]:
                del self.rooms[booking_id]

    async def broadcast(self, booking_id: int, message: dict):
        """Send a JSON message to every client connected to this booking room."""
        if booking_id not in self.rooms:
            return
        dead = []
        for connection in self.rooms[booking_id]:
            try:
                await connection.send_json(message)
            except Exception:
                dead.append(connection)
        for d in dead:
            self.disconnect(booking_id, d)


manager = ConnectionManager()


# ---------------------------------------------------------------------------
# Helper: authenticate user from JWT token (query param)
# ---------------------------------------------------------------------------
def get_user_from_token(token: str, db: Session) -> models.User:
    credentials_exception = HTTPException(status_code=401, detail="Invalid token")
    try:
        payload = jwt.decode(token, auth_utils.SECRET_KEY, algorithms=[auth_utils.ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(models.User).filter(models.User.username == username).first()
    if user is None:
        raise credentials_exception
    return user


# ---------------------------------------------------------------------------
# WebSocket endpoint
# URL: ws://host/ws/chat/{booking_id}?token=<jwt>
# ---------------------------------------------------------------------------
@router.websocket("/chat/{booking_id}")
async def websocket_chat(booking_id: int, websocket: WebSocket, token: str = ""):
    # 1. Authenticate
    db: Session = next(database.get_db())
    try:
        current_user = get_user_from_token(token, db)
    except HTTPException:
        await websocket.close(code=4001)
        return

    # 2. Authorise — only customer, worker, support, or admin for this booking
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        await websocket.close(code=4004)
        return

    is_authorized = (
        booking.customer_id == current_user.id
        or (booking.worker_id is not None and booking.worker.user_id == current_user.id)
        or current_user.role in [models.RoleEnum.SUPPORT, models.RoleEnum.ADMIN]
    )
    if not is_authorized:
        await websocket.close(code=4003)
        return

    # 3. Accept connection and join room
    await manager.connect(booking_id, websocket)
    try:
        # Send chat history upon connection
        history = (
            db.query(models.ChatMessage)
            .filter(models.ChatMessage.booking_id == booking_id)
            .order_by(models.ChatMessage.created_at.asc())
            .all()
        )
        history_payload = [
            {
                "type": "history",
                "id": m.id,
                "booking_id": m.booking_id,
                "sender_id": m.sender_id,
                "message_text": m.message_text,
                "created_at": m.created_at.isoformat(),
            }
            for m in history
        ]
        await websocket.send_json({"type": "history", "messages": history_payload})

        # 4. Listen for messages
        while True:
            data = await websocket.receive_json()
            message_text = data.get("message_text", "").strip()
            if not message_text:
                continue

            # Save to database
            new_msg = models.ChatMessage(
                booking_id=booking_id,
                sender_id=current_user.id,
                message_text=message_text,
            )
            db.add(new_msg)

            # Also create notification for the other party
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
                    message=message_text[:100],
                )
                db.add(notif)

            db.commit()
            db.refresh(new_msg)

            # Broadcast to all clients in this room
            broadcast_payload = {
                "type": "message",
                "id": new_msg.id,
                "booking_id": new_msg.booking_id,
                "sender_id": new_msg.sender_id,
                "message_text": new_msg.message_text,
                "created_at": new_msg.created_at.isoformat(),
            }
            await manager.broadcast(booking_id, broadcast_payload)

    except WebSocketDisconnect:
        manager.disconnect(booking_id, websocket)
    except Exception as e:
        print(f"[WS] Error in chat room {booking_id}: {e}")
        manager.disconnect(booking_id, websocket)
    finally:
        db.close()
