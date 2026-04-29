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
    IN_PROGRESS = "in_progress"
    DONE = "done"
    CANCELLED = "cancelled"

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
    bookings_as_customer = relationship("Booking", foreign_keys="[Booking.customer_id]", back_populates="customer")
    bookings_as_worker = relationship("Booking", foreign_keys="[Booking.worker_id]", back_populates="worker")

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
    customer_id = Column(Integer, ForeignKey("users.id"))
    worker_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    service_id = Column(Integer, ForeignKey("services.id"))
    scheduled_time = Column(DateTime)
    address = Column(String(255))
    status = Column(Enum(BookingStatusEnum), default=BookingStatusEnum.PENDING)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    customer = relationship("User", foreign_keys=[customer_id], back_populates="bookings_as_customer")
    worker = relationship("User", foreign_keys=[worker_id], back_populates="bookings_as_worker")
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
