import os
import glob

replacements = {
    # Auth
    "'Welcome Back'": "'Chào mừng trở lại'",
    "'Sign in to your account'": "'Đăng nhập vào tài khoản của bạn'",
    "'Username'": "'Tên đăng nhập'",
    "'Password'": "'Mật khẩu'",
    "'Forgot Password?'": "'Quên mật khẩu?'",
    "'Login'": "'Đăng nhập'",
    "'Don\\'t have an account?'": "'Chưa có tài khoản?'",
    "'Sign Up'": "'Đăng ký'",
    "'Create Account'": "'Tạo tài khoản'",
    "'Join Smart Service Marketplace'": "'Tham gia vào Hệ sinh thái'",
    "'Email'": "'Email'",
    "'Full Name'": "'Họ và tên'",
    "'I am a Customer'": "'Tôi là Khách hàng'",
    "'I am a Worker'": "'Tôi là Thợ'",
    "'Register'": "'Đăng ký'",
    "'Already have an account?'": "'Đã có tài khoản?'",
    "'Sign In'": "'Đăng nhập'",
    "'Registration successful. Please login.'": "'Đăng ký thành công. Vui lòng đăng nhập.'",
    "'Registration failed: ": "'Đăng ký thất bại: ",
    "'Invalid credentials. Please try again.'": "'Tài khoản hoặc mật khẩu sai. Vui lòng thử lại.'",

    # main_screen customer
    "'Home'": "'Trang chủ'",
    "'Bookings'": "'Lịch hẹn'",
    "'Profile'": "'Hồ sơ'",

    # home_screen
    "'Good Morning,'": "'Xin chào,'",
    "'Find your service'": "'Tìm kiếm dịch vụ'",
    "'Search for cleaning, repair...'": "'Tìm dọn dẹp, sửa chữa...'",
    "'Categories'": "'Danh mục'",
    "'See All'": "'Tất cả'",
    "'Cleaning'": "'Dọn dẹp'",
    "'Repair'": "'Sửa chữa'",
    "'Plumbing'": "'Ống nước'",
    "'Electric'": "'Điện lạnh'",
    "'Popular Services'": "'Dịch vụ phổ biến'",
    "'Deep House Cleaning'": "'Dọn nhà tổng thể'",
    "'AC Maintenance'": "'Bảo dưỡng Điều hoà'",
    "'hr'": "'giờ'",
    "'/h'": "'/giờ'",

    # services, booking
    "'Book'": "'Đặt ngay'",
    "'Book Service'": "'Đặt dịch vụ'",
    "'Schedule Time'": "'Hẹn thời gian'",
    "'Select a Date'": "'Chọn ngày'",
    "'Address'": "'Địa chỉ'",
    "'123 Main St, City'": "'Nhập chi tiết số nhà, tên đường...'",
    "'Confirm Booking'": "'Xác nhận Đặt lịch'",
    "'Booking created successfully!'": "'Đã tạo lịch thành công!'",
    "'Please select time and enter address'": "'Vui lòng chọn thời gian và địa chỉ'",

    # Bookings screen
    "'My Bookings'": "'Các lịch đã đặt'",
    "'No bookings found.'": "'Chưa có lịch hẹn nào.'",
    "'Booking #'": "'Mã đơn #'",
    "'Service '": "'Dịch vụ '",

    # Profile
    "'My Profile'": "'Hồ sơ cá nhân'",
    "'Edit Profile'": "'Chỉnh sửa thông tin'",
    "'Settings'": "'Cài đặt ứng dụng'",
    "'Help & Support'": "'Trợ giúp & Hỗ trợ'",
    "'Log Out'": "'Đăng xuất'",

    # Worker
    "'Available Jobs'": "'Công việc quanh đây'",
    "'Jobs'": "'Công việc'",
    "'No jobs pending right now. Ensure your availability is ON.'": "'Hiện chưa có yêu cầu mới. Hãy chắc chắn bạn đang BẬT nhận việc.'",
    "'Accept Job'": "'Nhận Viêc Này'",
    "'Job accepted!'": "'Đã nhận việc thành công!'",
    "'Worker Profile'": "'Hồ sơ Thợ'",
    "'Role: Service Provider'": "'Vai trò: Thợ dịch vụ'",
    "'Available for Jobs'": "'Sẵn sàng nhận việc'",
    "'Turn on to receive nearby job requests'": "'Bật để nhận yêu cầu công việc ở gần bạn'",
    "'My Earnings & History'": "'Thu nhập & Lịch sử làm việc'",
    "'Worker Staff'": "'Nhân viên Thợ'",

    # Admin
    "'Admin Dashboard'": "'Bảng Quản trị Admin'",
    "'Tot. Users'": "'KH'",
    "'Workers'": "'Tổng Thợ'",
    "'Revenue'": "'Doanh thu'",
    "'Management Modules'": "'Tính năng quản lý'",
    "'All Bookings (Support)'": "'Tất cả Đặt lịch (Hỗ trợ)'",
    "'User Management'": "'Quản lý Người dùng'",
}

files = glob.glob('d:/Project/Smart-Service-Marketplace/flutter_application_1/lib/screens/**/*.dart', recursive=True)

for path in files:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    for k, v in replacements.items():
        content = content.replace(k, v)
        
    if content != original:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {path}")
