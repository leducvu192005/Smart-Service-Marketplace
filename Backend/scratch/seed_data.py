"""
Script seed data: Tạo worker, customer test accounts + sample bookings
Chạy: venv_win\Scripts\python.exe scratch\seed_data.py
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session
from dotenv import load_dotenv
load_dotenv()

import models, auth_utils, database

engine = create_engine(os.getenv("DATABASE_URL"), echo=False)

def seed():
    with Session(engine) as db:
        print("=== SEEDING TEST DATA ===")

        # --------------------------------------------------
        # 1. Worker account
        # --------------------------------------------------
        worker_user = db.query(models.User).filter_by(username="worker1").first()
        if not worker_user:
            worker_user = models.User(
                username="worker1",
                email="worker1@test.com",
                full_name="Nguyễn Thợ Một",
                hashed_password=auth_utils.get_password_hash("worker123"),
                role=models.RoleEnum.WORKER,
                phone="0901234567",
                is_active=True,
            )
            db.add(worker_user)
            db.flush()

            # Worker profile
            profile = db.query(models.WorkerProfile).filter_by(user_id=worker_user.id).first()
            if not profile:
                profile = models.WorkerProfile(
                    user_id=worker_user.id,
                    skills="Điện, Nước, Điều hòa",
                    experience="5 năm kinh nghiệm",
                    is_available=True,
                    rating=4.8,
                )
                db.add(profile)
            db.commit()
            print(f"  [+] Worker created: worker1 / worker123  (id={worker_user.id})")
        else:
            print(f"  [=] Worker exists: id={worker_user.id}")

        # --------------------------------------------------
        # 2. Customer account
        # --------------------------------------------------
        cust_user = db.query(models.User).filter_by(username="customer1").first()
        if not cust_user:
            cust_user = models.User(
                username="customer1",
                email="customer1@test.com",
                full_name="Trần Khách Hàng",
                hashed_password=auth_utils.get_password_hash("customer123"),
                role=models.RoleEnum.CUSTOMER,
                phone="0912345678",
                is_active=True,
            )
            db.add(cust_user)
            db.commit()
            print(f"  [+] Customer created: customer1 / customer123  (id={cust_user.id})")
        else:
            print(f"  [=] Customer exists: id={cust_user.id}")

        # --------------------------------------------------
        # 3. Support account
        # --------------------------------------------------
        sup_user = db.query(models.User).filter_by(username="support1").first()
        if not sup_user:
            sup_user = models.User(
                username="support1",
                email="support1@test.com",
                full_name="Lê Hỗ Trợ",
                hashed_password=auth_utils.get_password_hash("support123"),
                role=models.RoleEnum.SUPPORT,
                phone="0923456789",
                is_active=True,
            )
            db.add(sup_user)
            db.commit()
            print(f"  [+] Support created: support1 / support123  (id={sup_user.id})")
        else:
            print(f"  [=] Support exists: id={sup_user.id}")

        # --------------------------------------------------
        # 4. Service + Category
        # --------------------------------------------------
        cat = db.query(models.ServiceCategory).filter_by(name="Điện - Nước - Điều Hòa").first()
        if not cat:
            cat = models.ServiceCategory(name="Điện - Nước - Điều Hòa", description="Dịch vụ điện, nước, điều hòa")
            db.add(cat)
            db.flush()

        svc = db.query(models.Service).filter_by(name="Sửa điện tổng quát").first()
        if not svc:
            svc = models.Service(
                name="Sửa điện tổng quát",
                description="Kiểm tra và sửa chữa các vấn đề về điện",
                price=150000.0,
                category_id=cat.id,
            )
            db.add(svc)
            db.flush()
        db.commit()
        print(f"  [+] Service ready: id={svc.id}")

        # --------------------------------------------------
        # 5. Sample Bookings
        # --------------------------------------------------
        from datetime import datetime, timedelta

        # Booking 1: pending
        b1 = db.query(models.Booking).filter_by(customer_id=cust_user.id).first()
        if not b1:
            b1 = models.Booking(
                customer_id=cust_user.id,
                service_id=svc.id,
                scheduled_time=datetime.now() + timedelta(days=2),
                address="123 Lê Lợi, Q1, TP.HCM",
                note="Xin đến đúng giờ",
                status=models.BookingStatusEnum.PENDING,
            )
            db.add(b1)
            db.flush()

            # Booking 2: accepted + assigned worker
            b2 = models.Booking(
                customer_id=cust_user.id,
                service_id=svc.id,
                scheduled_time=datetime.now() + timedelta(hours=3),
                address="456 Trần Hưng Đạo, Q5, TP.HCM",
                note="Cầu dao bị hỏng",
                status=models.BookingStatusEnum.ACCEPTED,
                worker_id=worker_user.id,
            )
            db.add(b2)
            db.flush()

            # Booking 3: completed
            b3 = models.Booking(
                customer_id=cust_user.id,
                service_id=svc.id,
                scheduled_time=datetime.now() - timedelta(days=3),
                address="789 Nguyễn Huệ, Q1, TP.HCM",
                status=models.BookingStatusEnum.COMPLETED,
                worker_id=worker_user.id,
            )
            db.add(b3)
            db.commit()
            print(f"  [+] 3 bookings created (pending, accepted, completed)")
        else:
            print(f"  [=] Bookings already exist")

        # --------------------------------------------------
        # 6. Wallet for worker
        # --------------------------------------------------
        wallet = db.query(models.Wallet).filter_by(worker_id=worker_user.id).first() if hasattr(models, 'Wallet') else None
        if wallet is None and hasattr(models, 'Wallet'):
            wallet = models.Wallet(worker_id=worker_user.id, balance=500000.0)
            db.add(wallet)
            db.commit()
            print(f"  [+] Worker wallet: 500,000 VND")

        # --------------------------------------------------
        # 7. Sample Ticket
        # --------------------------------------------------
        ticket = db.query(models.SupportTicket).filter_by(creator_id=cust_user.id).first() if hasattr(models, 'SupportTicket') else None
        if ticket is None and hasattr(models, 'SupportTicket'):
            ticket = models.SupportTicket(
                creator_id=cust_user.id,
                title="Thợ đến trễ",
                description="Thợ hẹn 9h nhưng 10h30 mới đến",
                status="open",
            )
            db.add(ticket)
            db.commit()
            print(f"  [+] Sample ticket created")

        print()
        print("=== SEED COMPLETE ===")
        print("  admin_test / admin123  (role=admin)")
        print("  support1   / support123 (role=support)")
        print("  worker1    / worker123  (role=worker)")
        print("  customer1  / customer123 (role=customer)")

if __name__ == "__main__":
    seed()
