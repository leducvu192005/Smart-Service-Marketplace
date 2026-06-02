from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import date, datetime

class WorkerBase(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    avatar_url: Optional[str] = None
    gender: Optional[str] = None
    birth_date: Optional[date] = None
    address: Optional[str] = None
    city: Optional[str] = None
    district: Optional[str] = None
    job_title: Optional[str] = None
    experience_years: Optional[int] = 0
    skills: Optional[str] = None
    description: Optional[str] = None
    is_available: Optional[bool] = False
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    identity_number: Optional[str] = None
    identity_front_image: Optional[str] = None
    identity_back_image: Optional[str] = None
    bank_name: Optional[str] = None
    bank_account_number: Optional[str] = None
    bank_account_holder: Optional[str] = None

class WorkerCreate(WorkerBase):
    pass

class WorkerUpdate(WorkerBase):
    status: Optional[str] = None

class WorkerResponse(WorkerBase):
    id: int
    user_id: int
    rating: float
    total_reviews: int
    total_jobs: int
    status: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
