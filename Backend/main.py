from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine
import models
from routers import auth, customer, worker, support, admin

# Create all tables in the database
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Smart Service Marketplace API",
    description="API for the 4-role utility service app: Customer, Worker, Support, Admin.",
    version="1.0.0"
)

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
app.include_router(support.router)
app.include_router(admin.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to Smart Service Marketplace API. Use /docs to view Swagger documentation."}
