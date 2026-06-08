from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine
import models
from routers import auth, customer, worker, support, admin, workers

# Create all tables in the database
models.Base.metadata.create_all(bind=engine)

# Auto migrate wallet_balance column if not exists
from sqlalchemy import inspect, text
inspector = inspect(engine)
if "workers" in inspector.get_table_names():
    columns = [col["name"] for col in inspector.get_columns("workers")]
    if "wallet_balance" not in columns:
        with engine.begin() as conn:
            conn.execute(text("ALTER TABLE workers ADD COLUMN wallet_balance FLOAT DEFAULT 0.0"))

# Auto migrate bookings table columns if not exists
if "bookings" in inspector.get_table_names():
    booking_columns = [col["name"] for col in inspector.get_columns("bookings")]
    if "before_image" not in booking_columns:
        with engine.begin() as conn:
            conn.execute(text("ALTER TABLE bookings ADD COLUMN before_image VARCHAR(255)"))
    if "after_image" not in booking_columns:
        with engine.begin() as conn:
            conn.execute(text("ALTER TABLE bookings ADD COLUMN after_image VARCHAR(255)"))

# Auto migrate tickets table columns if not exists
if "tickets" in inspector.get_table_names():
    ticket_columns = [col["name"] for col in inspector.get_columns("tickets")]
    if "admin_comment" not in ticket_columns:
        with engine.begin() as conn:
            conn.execute(text("ALTER TABLE tickets ADD COLUMN admin_comment TEXT"))

# Automatic data seeder
def seed_data():
    from database import SessionLocal
    db = SessionLocal()
    try:
        category_count = db.query(models.ServiceCategory).count()
        if category_count == 0:
            print("Seeding service categories and services...")
            # 1. Create Categories
            cleaning_cat = models.ServiceCategory(name="Dọn dẹp", description="Các dịch vụ vệ sinh và dọn dẹp nhà cửa chuyên nghiệp.")
            it_cat = models.ServiceCategory(name="Giải pháp IT", description="Cài đặt, sửa chữa máy tính và hỗ trợ kỹ thuật.")
            plumbing_cat = models.ServiceCategory(name="Sửa ống nước", description="Thông tắc bồn rửa, sửa đường ống nước rò rỉ.")
            electrical_cat = models.ServiceCategory(name="Sửa điện", description="Sửa chập điện, đi lại dây và thiết bị điện thông minh.")
            
            db.add_all([cleaning_cat, it_cat, plumbing_cat, electrical_cat])
            db.commit()
            db.refresh(cleaning_cat)
            db.refresh(it_cat)
            db.refresh(plumbing_cat)
            db.refresh(electrical_cat)
            
            # 2. Create Services
            services = [
                models.Service(category_id=cleaning_cat.id, name="Vệ sinh căn hộ chung cư", description="Dọn dẹp, lau chùi, hút bụi căn hộ chung cư trọn gói.", price=50000.0),
                models.Service(category_id=cleaning_cat.id, name="Dọn dẹp văn phòng theo giờ", description="Dọn dẹp vệ sinh không gian làm việc định kỳ hàng tuần.", price=60000.0),
                
                models.Service(category_id=it_cat.id, name="Cài đặt hệ điều hành & phần mềm", description="Cài Windows, MacOS, Office và diệt virus tận nơi.", price=100000.0),
                models.Service(category_id=it_cat.id, name="Sửa chữa phần cứng máy tính", description="Khắc phục hỏng hóc RAM, ổ cứng, màn hình máy tính.", price=120000.0),
                
                models.Service(category_id=plumbing_cat.id, name="Thông tắc bồn rửa & cống", description="Thông nghẹt lavabo, chậu rửa bát và cống thoát nước.", price=80000.0),
                models.Service(category_id=plumbing_cat.id, name="Sửa chữa đường ống nước rò rỉ", description="Khắc phục vòi nước rò rỉ, thay mới ống nước cũ hỏng.", price=90000.0),
                
                models.Service(category_id=electrical_cat.id, name="Lắp đặt đèn & thiết bị thông minh", description="Lắp đèn led, ổ cắm thông minh, công tắc cảm ứng.", price=70000.0),
                models.Service(category_id=electrical_cat.id, name="Sửa chập điện & đi dây âm tường", description="Xử lý sự cố mất điện, chập cháy nổ cầu chì aptomat.", price=85000.0),
            ]
            db.add_all(services)
            db.commit()
            print("Database seeded successfully with services and categories!")
    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
    finally:
        db.close()

seed_data()

from fastapi.staticfiles import StaticFiles
import os

app = FastAPI(
    title="Smart Service Marketplace API",
    description="API for the 4-role utility service app: Customer, Worker, Support, Admin.",
    version="1.0.0"
)

# Ensure static directory exists
os.makedirs("static", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

# Thêm cấu hình CORS để cho phép Flutter Edge/Chrome kết nối tới
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(customer.router)
app.include_router(worker.router)
app.include_router(workers.router)
app.include_router(support.router)
app.include_router(admin.router)


@app.get("/")
def read_root():
    return {"message": "Welcome to Smart Service Marketplace API. Use /docs to view Swagger documentation."}
