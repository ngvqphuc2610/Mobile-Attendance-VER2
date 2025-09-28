# Mobile Attendance App

Ứng dụng quản lý sinh viên và điểm danh thông minh sử dụng Flutter và Supabase.

## Tính năng chính

- 📚 **Quản lý sinh viên**: Thêm, sửa, xóa thông tin sinh viên
- 👤 **Nhận diện khuôn mặt**: Điểm danh bằng AI face recognition  
- 📱 **Quét mã vạch**: Điểm danh bằng QR code/barcode
- 📊 **Báo cáo**: Thống kê điểm danh theo thời gian
- 🔐 **Xác thực**: Hỗ trợ vân tay và face ID

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
   - Thêm Supabase URL và anon key:
   ```
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```

3. **Chạy ứng dụng:**
   ```bash
   flutter run
   ```

## Database Schema

Ứng dụng sử dụng Supabase PostgreSQL với các bảng chính:

- `profiles` - Thông tin sinh viên
- `classes` - Lớp học  
- `faculties` - Khoa
- `attendance` - Lịch sử điểm danh
- `face_embeddings` - Vector khuôn mặt

## Packages sử dụng

- **flutter_bloc** - State management
- **supabase_flutter** - Backend as a Service
- **camera** - Camera access
- **google_mlkit_face_detection** - Face detection
- **tflite_flutter** - TensorFlow Lite
- **mobile_scanner** - QR/Barcode scanning
- **local_auth** - Biometric authentication

## TODO

- [ ] Implement face recognition training
- [ ] Add barcode scanner
- [ ] Create attendance reports
- [ ] Add user authentication
- [ ] Implement offline mode
- [ ] Add push notifications

## Tác giả

Phát triển bởi nhóm Mobile Development
