from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime
from models import RoleEnum, BookingStatusEnum

# --- User Schemas ---
class UserBase(BaseModel):
    username: str
    email: EmailStr
    full_name: str
    role: RoleEnum = RoleEnum.CUSTOMER

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: int
    is_active: bool

    class Config:
        from_attributes = True

# --- Worker Profile Schemas ---
class WorkerProfileBase(BaseModel):
    skills: Optional[str] = None
    experience: Optional[str] = None
    is_available: bool = False
    avatar_url: Optional[str] = None
    lat: Optional[float] = None
    long: Optional[float] = None

class WorkerProfileUpdate(WorkerProfileBase):
    pass

class WorkerProfileResponse(WorkerProfileBase):
    id: int
    user_id: int
    rating: float

    class Config:
        from_attributes = True

# --- Service Schemas ---
class ServiceBase(BaseModel):
    name: str
    description: Optional[str] = None
    price: float

class ServiceCreate(ServiceBase):
    category_id: int

class ServiceResponse(ServiceBase):
    id: int
    category_id: int

    class Config:
        from_attributes = True

class ServiceCategoryBase(BaseModel):
    name: str
    description: Optional[str] = None

class ServiceCategoryResponse(ServiceCategoryBase):
    id: int
    services: List[ServiceResponse] = []

    class Config:
        from_attributes = True

# --- Booking Schemas ---
class BookingBase(BaseModel):
    service_id: int
    scheduled_time: datetime
    address: str

class BookingCreate(BookingBase):
    pass

class BookingResponse(BookingBase):
    id: int
    customer_id: int
    worker_id: Optional[int]
    status: BookingStatusEnum
    created_at: datetime

    class Config:
        from_attributes = True

# --- Review Schemas ---
class ReviewBase(BaseModel):
    rating: int
    comment: Optional[str] = None

class ReviewCreate(ReviewBase):
    booking_id: int

class ReviewResponse(ReviewBase):
    id: int
    booking_id: int
    created_at: datetime

    class Config:
        from_attributes = True
