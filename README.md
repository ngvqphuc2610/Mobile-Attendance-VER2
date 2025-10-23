# Mobile Attendance App

Ứng dụng quản lý sinh viên và điểm danh thông minh sử dụng Flutter và Supabase.

## Tính năng chính

- 📚 **Quản lý sinh viên**: Thêm, sửa, xóa thông tin sinh viên
- 👤 **Nhận diện khuôn mặt**: Điểm danh bằng AI face recognition  
- 📱 **Quét mã vạch**: Điểm danh bằng QR code/barcode
- 📊 **Báo cáo**: Thống kê điểm danh theo thời gian
- 🔐 **Xác thực**: Hỗ trợ vân tay và face ID

- chạy backend : npm run dev
- chạy backend-ngrok : npm run dev:ngrok
- chạy flutter : flutter clean - flutter pub get -flutter run

## Cấu trúc dự án

```
lib/
├── core/
│   ├── constants/       # Hằng số, theme, strings
│   └── di/             # Dependency injection
├── data/
│   ├── models/         # Data models
│   ├── datasources/    # API calls
│   └── repositories/   # Repository pattern
└── presentation/
    ├── bloc/           # State management (BLoC)
    ├── pages/          # UI screens
    └── widgets/        # Reusable widgets
```

## Cài đặt

1. **Cài đặt dependencies:**
   ```bash
   flutter pub get
   ```

2. **Cấu hình Supabase:**
   - Tạo file `.env` trong thư mục root
  
   ```
   APP_NAME=Mobile Attendance
APP_VERSION=1.0.0

DB_HOST=localhost
DB_PORT=
DB_USERNAME=
DB_PASSWORD=
DB_NAME=

API_URL=
JWT_SECRET=
ESMS_API_KEY=
ESMS_SECRET_KEY=
   ```

3. **Chạy ứng dụng:**
   ``
   *** chạy backend + NGROK

   npm run dev:ngrok

   *** chạy ui
   flutter run
   ```

## Database Schema

Ứng dụng sử dụng mysql


## Packages sử dụng


## Tác giả


