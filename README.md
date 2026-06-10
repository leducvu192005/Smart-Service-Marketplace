# Smart Service Marketplace

Nền tảng kết nối và quản lý dịch vụ tiện ích gia đình & văn phòng trực tuyến với mô hình phân quyền **4 vai trò** (Khách hàng, Thợ, Nhân viên hỗ trợ, Quản trị viên). Hệ thống tích hợp cổng thanh toán trực tuyến **VNPay** và quy trình thực hiện công việc nghiêm ngặt kèm minh chứng ảnh.

---

## 📌 Thành phần dự án
1. **Backend (FastAPI)**: Thư mục `/Backend` - Cung cấp toàn bộ RESTful API, quản lý cơ sở dữ liệu SQLite (`smart_service.db`), xác thực JWT, lập lịch thông báo và cổng thanh toán VNPay Sandbox.
2. **Frontend (Flutter)**: Thư mục `/flutter_application_1` - Ứng dụng di động đa nền tảng (Android/iOS/Web) dành cho cả 4 đối tượng người dùng.

---

## 🛠️ Công nghệ sử dụng
* **Backend**: Python 3.9+, FastAPI, SQLAlchemy (ORM), Pydantic, Uvicorn, SQLite.
* **Frontend**: Flutter (Dart), Dio (Http Client), Google Fonts, Provider (State Management), Expansion Tiles, Carousel.
* **Tích hợp**: Cổng thanh toán **VNPay Sandbox** (Phiên bản v2.1.0 với cơ chế mã hóa HMAC-SHA512).

---

## 🌟 Tính năng chính theo Vai trò

### 1. Khách hàng (Customer)
* **Khám phá dịch vụ**: Xem các danh mục dịch vụ (Dọn dẹp, Sửa điện, Nước, IT), tìm kiếm và lọc dịch vụ.
* **Dịch vụ yêu thích**: Thêm các dịch vụ thường xuyên sử dụng vào danh sách yêu thích.
* **Địa chỉ đã lưu**: Quản lý nhiều địa chỉ làm việc (Nhà riêng, Văn phòng,...).
* **Quy trình đặt đơn & Thanh toán**:
  - Chọn dịch vụ, đặt ngày giờ làm việc, nhập ghi chú, áp dụng mã giảm giá (Voucher).
  - Thanh toán qua cổng trực tuyến **VNPay** một cách an toàn.
* **Theo dõi & Tương tác**: Theo dõi tiến độ đơn hàng thời gian thực, chat trực tiếp với thợ.
* **Đánh giá & Khiếu nại**: Đánh giá thợ bằng hệ thống sao (1-5★) kèm nhận xét; gửi ticket hỗ trợ/khiếu nại trực tiếp nếu có tranh chấp xảy ra.
* **Đăng ký làm thợ**: Gửi hồ sơ (CCCD, kỹ năng, kinh nghiệm) trực tiếp lên Admin duyệt ngay trong ứng dụng.

### 2. Thợ (Worker)
* **Quản lý trạng thái**: Bật/tắt trạng thái trực tuyến (`is_available`) để nhận/từ chối đơn hàng mới.
* **Nhận & Thực thi việc**:
  - Xem danh sách việc trống (`pending_jobs`) và tự động nhận việc.
  - Cập nhật quy trình làm việc: `Đang đi chuyển` → `Đã đến nơi` → `Đang làm` (bắt buộc tải ảnh **Trước khi làm**) → `Hoàn thành` (bắt buộc tải ảnh **Sau khi làm**).
* **Quản lý tài chính**: 
  - Xem số dư ví và chi tiết các giao dịch tăng/giảm số dư (Nhận 90% doanh thu đơn hàng, khấu trừ 10% phí nền tảng).
  - Gửi yêu cầu rút tiền về tài khoản ngân hàng đã thiết lập.
* **Lịch nghỉ (Calendar)**: Thiết lập ngày nghỉ phép cá nhân để hệ thống không chỉ định đơn hàng.

### 3. Nhân viên hỗ trợ (Support)
* **Điều phối công việc**: Thay đổi thợ, chỉ định thủ công thợ cho đơn hàng, hoặc hủy đơn nếu có sự cố bất khả kháng.
* **Duyệt hồ sơ thợ mới**: Xem các hồ sơ đăng ký của khách hàng, kiểm tra CCCD, phê duyệt để nâng cấp tài khoản của họ lên Thợ hoặc từ chối hồ sơ.
* **Giải quyết khiếu nại**: Tiếp nhận tickets hỗ trợ từ Khách hàng & Thợ, viết phản hồi giải pháp và đóng ticket.
* **Khóa/mở khóa Thợ**: Đình chỉ thợ vi phạm quy chế hoặc khôi phục hoạt động cho thợ.

### 4. Quản trị viên (Admin)
* **Báo cáo tài chính & Doanh thu**: Biểu đồ doanh thu trực quan, biểu đồ tăng trưởng đơn hàng, thống kê số lượng người dùng.
* **Duyệt giao dịch**: Phê duyệt hoặc từ chối các yêu cầu rút tiền của Thợ, yêu cầu hoàn tiền cho Khách hàng.
* **Quản lý danh mục & Dịch vụ**: Thêm mới, chỉnh sửa thông tin hoặc xóa các dịch vụ và danh mục tương ứng.
* **Quản lý tài khoản**: Quản lý tất cả tài khoản người dùng, tạo tài khoản cho nhân viên hỗ trợ (Support), bật/tắt kích hoạt tài khoản.
* **Chiến dịch tiếp thị**: Phát hành mã giảm giá (Vouchers) theo số tiền cố định hoặc tỷ lệ phần trăm.
* **Gửi thông báo đẩy**: Phát thông báo (Broadcast) đến toàn bộ hệ thống hoặc theo vai trò cụ thể.

---

## ⚙️ Hướng dẫn cài đặt & Chạy ứng dụng

### 1. Khởi động Backend (FastAPI)
1. Di chuyển vào thư mục Backend:
   ```bash
   cd Backend
   ```
2. Tạo và kích hoạt môi trường ảo:
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # Trên macOS/Linux
   # Hoặc: venv\Scripts\activate  # Trên Windows
   ```
3. Cài đặt các thư viện cần thiết:
   ```bash
   pip install -r requirements.txt
   ```
4. Khởi chạy Server:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```
   *Lưu ý: Hệ thống sẽ tự động khởi tạo cơ sở dữ liệu `smart_service.db`, tự động chạy các bước cập nhật bảng (auto-migration) và nạp dữ liệu mẫu cho danh mục/dịch vụ cốt lõi.*

### 2. Khởi chạy Ứng dụng di động (Flutter)
1. Di chuyển vào thư mục ứng dụng Flutter:
   ```bash
   cd flutter_application_1
   ```
2. Cài đặt các gói phụ thuộc (Dependencies):
   ```bash
   flutter pub get
   ```
3. Cấu hình IP máy chủ API:
   - Mở file `lib/services/api_service.dart` (hoặc file cấu hình tương ứng).
   - Đảm bảo địa chỉ Base URL trỏ đúng về địa chỉ IP cục bộ của máy tính chạy backend (ví dụ: `http://192.168.1.X:8000`). Tránh sử dụng `localhost` nếu chạy trên thiết bị vật lý thật.
4. Chạy ứng dụng:
   ```bash
   flutter run
   ```

---

## 🔑 Tài khoản thử nghiệm mặc định
Khi máy chủ backend khởi động lần đầu, hệ thống sẽ tự động chạy tập lệnh tạo sẵn các tài khoản thử nghiệm sau để bạn dễ dàng kiểm thử các tính năng quản trị và hỗ trợ:

| Vai trò | Tên đăng nhập (Username) | Mật khẩu (Password) |
|---|---|---|
| **Quản trị viên (Admin)** | `admin_test` | `admin123` |
| **Nhân viên hỗ trợ (Support)** | `support_test` | `support123` |

*Đối với vai trò **Khách hàng** và **Thợ**, bạn có thể dễ dàng đăng ký tài khoản mới ngay trên giao diện ứng dụng di động.*

---

## 🗂️ Quy trình luồng tiền tệ chính (Financial Workflow)
1. **Khách đặt lịch**: Đơn hàng tạo ở trạng thái `pending_payment`.
2. **Khách thanh toán qua VNPay**: Cổng VNPay xác thực giao dịch, gọi IPN xác nhận về server backend, chuyển trạng thái đơn hàng thành `paid_confirmed`.
3. **Thợ nhận và làm việc**: Sau khi thợ hoàn thành đơn hàng và tải lên đầy đủ hình ảnh minh chứng trước/sau khi làm, trạng thái chuyển thành `done`.
4. **Cộng tiền vào ví**: Hệ thống tự động trích **90%** giá trị đơn hàng cộng vào ví của Thợ. **10%** còn lại giữ lại làm phí dịch vụ nền tảng.
5. **Thợ rút tiền**: Thợ tạo yêu cầu rút tiền trên ứng dụng di động. Admin kiểm tra thông tin số tài khoản và duyệt lệnh rút tiền để hoàn tất giao dịch thực tế ngoài đời.
