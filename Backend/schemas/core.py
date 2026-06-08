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
    phone: Optional[str] = None

    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None

class WorkerApplicationCreate(BaseModel):
    full_name: str
    phone: str
    skills: str               # Danh sách kỹ năng (dấu phẩy)
    experience: str           # Mô tả kinh nghiệm
    id_card_number: str       # Số CCCD/CMND
    address: str              # Địa chỉ thường trú
    bio: Optional[str] = None # Giới thiệu bản thân

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
    price: Optional[float] = None

class ServiceResponse(ServiceBase):
    id: int
    category_id: Optional[int] = None

    class Config:
        from_attributes = True

class ServiceCreate(ServiceBase):
    category_id: Optional[int] = None

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
    note: Optional[str] = None

class BookingCreate(BookingBase):
    pass

class BookingResponse(BookingBase):
    id: int
    customer_id: int
    worker_id: Optional[int] = None
    status: BookingStatusEnum
    before_image: Optional[str] = None
    after_image: Optional[str] = None
    created_at: datetime
    updated_at: datetime

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


class SkillCategoryResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    is_active: bool

    class Config:
        from_attributes = True


class TicketCreate(BaseModel):
    booking_id: Optional[int] = None
    title: str
    description: str


class TicketResponse(BaseModel):
    id: int
    creator_id: int
    booking_id: Optional[int] = None
    title: str
    description: str
    status: str
    admin_comment: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class WithdrawalCreate(BaseModel):
    amount: float


class WithdrawalResponse(BaseModel):
    id: int
    worker_id: int
    amount: float
    status: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class RefundRequestCreate(BaseModel):
    booking_id: int
    reason: str
    amount: float


class RefundRequestResponse(BaseModel):
    id: int
    booking_id: int
    reason: str
    amount: float
    status: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class VoucherCreate(BaseModel):
    code: str
    discount_amount: float
    expiry_date: Optional[datetime] = None


class VoucherResponse(BaseModel):
    id: int
    code: str
    discount_amount: float
    is_active: bool
    expiry_date: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True


class NotificationCreate(BaseModel):
    title: str
    message: str
    recipient_role: Optional[str] = "all"


class NotificationResponse(BaseModel):
    id: int
    title: str
    message: str
    recipient_role: str
    created_at: datetime

    class Config:
        from_attributes = True


class SupportActivityLogResponse(BaseModel):
    id: int
    support_id: int
    action: str
    details: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class TransactionResponse(BaseModel):
    id: int
    worker_id: int
    booking_id: Optional[int] = None
    amount: float
    type: str
    description: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class FavoriteCreate(BaseModel):
    service_id: int


class FavoriteResponse(BaseModel):
    id: int
    customer_id: int
    service_id: int
    created_at: datetime

    class Config:
        from_attributes = True


class SavedAddressCreate(BaseModel):
    label: str
    address_text: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class SavedAddressResponse(BaseModel):
    id: int
    customer_id: int
    label: str
    address_text: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    created_at: datetime

    class Config:
        from_attributes = True


class ChatMessageCreate(BaseModel):
    message_text: str


class ChatMessageResponse(BaseModel):
    id: int
    booking_id: int
    sender_id: int
    message_text: str
    created_at: datetime

    class Config:
        from_attributes = True


class UserNotificationResponse(BaseModel):
    id: int
    user_id: int
    title: str
    message: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True


class WorkerCalendarCreate(BaseModel):
    date: str  # Format: YYYY-MM-DD
    is_off: bool
    note: Optional[str] = None


class WorkerCalendarResponse(BaseModel):
    id: int
    worker_id: int
    date: str
    is_off: bool
    note: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


# --- Payment Schemas (VNPay) ---
class PaymentResponse(BaseModel):
    id: int
    booking_id: int
    amount: float
    vnp_txn_ref: str
    vnp_transaction_no: Optional[str] = None
    status: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
