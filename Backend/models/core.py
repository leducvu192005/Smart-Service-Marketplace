from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey, DateTime, Text, Enum
from sqlalchemy.orm import relationship
import enum
from datetime import datetime
from database import Base

class RoleEnum(str, enum.Enum):
    CUSTOMER = "customer"
    WORKER = "worker"
    SUPPORT = "support"
    ADMIN = "admin"

class BookingStatusEnum(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    ON_THE_WAY = "on_the_way"
    ARRIVED = "arrived"
    IN_PROGRESS = "in_progress"
    DONE = "done"
    CANCELLED = "cancelled"
    REVIEWED = "reviewed"

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True)
    email = Column(String(100), unique=True, index=True)
    full_name = Column(String(100))
    hashed_password = Column(String(255))
    role = Column(Enum(RoleEnum), default=RoleEnum.CUSTOMER)
    is_active = Column(Boolean, default=True)
    
    worker_profile = relationship("WorkerProfile", back_populates="user", uselist=False)
    worker_info = relationship("Worker", back_populates="user", uselist=False)
    bookings_as_customer = relationship("Booking", foreign_keys="[Booking.customer_id]", back_populates="customer")

class WorkerProfile(Base):
    __tablename__ = "worker_profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    skills = Column(Text, nullable=True) # JSON or comma separated
    experience = Column(Text, nullable=True)
    lat = Column(Float, nullable=True)
    long = Column(Float, nullable=True)
    is_available = Column(Boolean, default=False)
    avatar_url = Column(String(255), nullable=True)
    rating = Column(Float, default=0.0)
    
    user = relationship("User", back_populates="worker_profile")

class ServiceCategory(Base):
    __tablename__ = "service_categories"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True)
    description = Column(Text, nullable=True)
    
    services = relationship("Service", back_populates="category")

class Service(Base):
    __tablename__ = "services"
    
    id = Column(Integer, primary_key=True, index=True)
    category_id = Column(Integer, ForeignKey("service_categories.id"))
    name = Column(String(150))
    description = Column(Text, nullable=True)
    price = Column(Float)
    
    category = relationship("ServiceCategory", back_populates="services")
    bookings = relationship("Booking", back_populates="service")

class Booking(Base):
    __tablename__ = "bookings"
    
    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    worker_id = Column(Integer, ForeignKey("workers.id", ondelete="SET NULL"), nullable=True)
    service_id = Column(Integer, ForeignKey("services.id", ondelete="RESTRICT"), nullable=False)
    scheduled_time = Column(DateTime, nullable=False)
    address = Column(Text, nullable=False)
    note = Column(Text, nullable=True)
    status = Column(String(30), default="pending", nullable=False)
    before_image = Column(String(255), nullable=True)
    after_image = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    customer = relationship("User", foreign_keys=[customer_id], back_populates="bookings_as_customer")
    worker = relationship("Worker", foreign_keys=[worker_id], back_populates="bookings")
    service = relationship("Service", back_populates="bookings")
    review = relationship("Review", back_populates="booking", uselist=False)

class Review(Base):
    __tablename__ = "reviews"
    
    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"))
    rating = Column(Integer) # 1 to 5
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    booking = relationship("Booking", back_populates="review")


class SkillCategory(Base):
    __tablename__ = "skill_categories"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Ticket(Base):
    __tablename__ = "tickets"
    
    id = Column(Integer, primary_key=True, index=True)
    creator_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    booking_id = Column(Integer, ForeignKey("bookings.id", ondelete="SET NULL"), nullable=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    status = Column(String(30), default="pending")  # pending, in_progress, closed
    admin_comment = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    creator = relationship("User", foreign_keys=[creator_id])
    booking = relationship("Booking")


class WithdrawalRequest(Base):
    __tablename__ = "withdrawal_requests"
    
    id = Column(Integer, primary_key=True, index=True)
    worker_id = Column(Integer, ForeignKey("workers.id", ondelete="CASCADE"), nullable=False)
    amount = Column(Float, nullable=False)
    status = Column(String(30), default="pending")  # pending, approved, rejected
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    worker = relationship("Worker")


class RefundRequest(Base):
    __tablename__ = "refund_requests"
    
    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id", ondelete="CASCADE"), nullable=False)
    reason = Column(Text, nullable=False)
    amount = Column(Float, nullable=False)
    status = Column(String(30), default="pending")  # pending, approved, rejected
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    booking = relationship("Booking")


class Voucher(Base):
    __tablename__ = "vouchers"
    
    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(50), unique=True, index=True, nullable=False)
    discount_amount = Column(Float, nullable=False)
    is_active = Column(Boolean, default=True)
    expiry_date = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class Notification(Base):
    __tablename__ = "notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    recipient_role = Column(String(50), default="all")  # all, customer, worker
    created_at = Column(DateTime, default=datetime.utcnow)


class SupportActivityLog(Base):
    __tablename__ = "support_activity_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    support_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    action = Column(String(100), nullable=False)
    details = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    support = relationship("User")


class Transaction(Base):
    __tablename__ = "transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    worker_id = Column(Integer, ForeignKey("workers.id", ondelete="CASCADE"), nullable=False)
    booking_id = Column(Integer, ForeignKey("bookings.id", ondelete="SET NULL"), nullable=True)
    amount = Column(Float, nullable=False)  # positive for earnings, negative for deductions/withdrawals
    type = Column(String(50), nullable=False)  # earnings, commission, withdrawal, refund
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    worker = relationship("Worker")
    booking = relationship("Booking")


class Favorite(Base):
    __tablename__ = "favorites"
    
    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    service_id = Column(Integer, ForeignKey("services.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    customer = relationship("User", foreign_keys=[customer_id], backref="favorites")
    service = relationship("Service", foreign_keys=[service_id], backref="favorited_by")


class SavedAddress(Base):
    __tablename__ = "saved_addresses"
    
    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    label = Column(String(50), nullable=False)  # e.g., Home, Office
    address_text = Column(Text, nullable=False)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    customer = relationship("User", foreign_keys=[customer_id], backref="saved_addresses")


class ChatMessage(Base):
    __tablename__ = "chat_messages"
    
    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id", ondelete="CASCADE"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    message_text = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    booking = relationship("Booking", foreign_keys=[booking_id], backref="chat_messages")
    sender = relationship("User", foreign_keys=[sender_id], backref="sent_messages")


class UserNotification(Base):
    __tablename__ = "user_notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", foreign_keys=[user_id], backref="user_notifications")


class WorkerCalendar(Base):
    __tablename__ = "worker_calendars"
    
    id = Column(Integer, primary_key=True, index=True)
    worker_id = Column(Integer, ForeignKey("workers.id", ondelete="CASCADE"), nullable=False)
    date = Column(String(10), nullable=False)  # Format: YYYY-MM-DD
    is_off = Column(Boolean, default=False)
    note = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    worker = relationship("Worker", foreign_keys=[worker_id], backref="calendar_slots")


