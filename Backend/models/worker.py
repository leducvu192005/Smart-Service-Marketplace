from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey, DateTime, Date, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class Worker(Base):
    __tablename__ = "workers"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    
    # Personal Info
    full_name = Column(String(100), nullable=True)
    phone = Column(String(20), nullable=True)
    email = Column(String(100), nullable=True)
    avatar_url = Column(String(255), nullable=True)
    gender = Column(String(10), nullable=True)
    birth_date = Column(Date, nullable=True)
    
    # Address
    address = Column(String(255), nullable=True)
    city = Column(String(100), nullable=True)
    district = Column(String(100), nullable=True)
    
    # Professional Profile
    job_title = Column(String(150), nullable=True)
    experience_years = Column(Integer, default=0)
    skills = Column(Text, nullable=True) # Comma separated list of skills
    description = Column(Text, nullable=True)
    is_available = Column(Boolean, default=False)
    
    # Geolocation
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    # Ratings & Jobs
    rating = Column(Float, default=0.0)
    total_reviews = Column(Integer, default=0)
    total_jobs = Column(Integer, default=0)
    
    # Identification
    identity_number = Column(String(50), nullable=True)
    identity_front_image = Column(String(255), nullable=True)
    identity_back_image = Column(String(255), nullable=True)
    
    # Payout Details
    bank_name = Column(String(100), nullable=True)
    bank_account_number = Column(String(50), nullable=True)
    bank_account_holder = Column(String(100), nullable=True)
    
    # Status & Timestamps
    status = Column(String(20), default="pending") # e.g. pending, active, suspended
    wallet_balance = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship to user
    user = relationship("User", back_populates="worker_info")
    bookings = relationship("Booking", back_populates="worker")
