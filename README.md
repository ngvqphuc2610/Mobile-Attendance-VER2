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
   ```

3. **Chạy ứng dụng:**
   ``
   *** chạy backend
   npm run dev
   npm run dev:ngrok

   *** chạy ui
   flutter run
   ```

## Database Schema

Ứng dụng sử dụng mysql


## Packages sử dụng

  flutter_bloc: ^8.1.6 
  equatable: ^2.0.5 # For value equality
  go_router: ^16.2.2 # Routing
  hive: ^2.2.3 # Local database
  hive_flutter: ^1.1.0 # Hive for Flutter
  camera: ^0.11.2  # Camera plugin
  image: ^4.5.4 # Image processing
  image_picker: ^1.0.8 # Pick images from gallery/camera 
  google_mlkit_face_detection: ^0.13.1 # Face detection
  tflite_flutter: ^0.11.0 # TensorFlow Lite plugin
  mobile_scanner: ^7.0.1 # QR code scanning
  local_auth: ^2.3.0 # Local authentication (fingerprint/face ID/biometric)
  flutter_secure_storage: ^9.2.4 # Secure storage
  path_provider: ^2.1.4 # Path provider
  shared_preferences: ^2.3.2 # Shared preferences
  permission_handler: ^11.3.1 # Permission handler
  crypto: ^3.0.5 # hashing
  get_it: ^7.7.0 # Dependency injection
  flutter_dotenv: ^6.0.0 # Environment variables
  flutter_spinkit: ^5.2.1 # Loading indicators
  awesome_dialog: ^3.2.1 # Beautiful dialogs
  cached_network_image: ^3.3.1 # Cached images
  shimmer: ^3.0.0 # Shimmer loading effect
  qr_flutter: ^4.1.0 # QR code generation
  # Date & Time
  intl: ^0.19.0 


## Tác giả


