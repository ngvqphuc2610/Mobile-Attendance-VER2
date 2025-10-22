const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const studentRoutes = require('./routes/students');
const teacherRoutes = require('./routes/teachers');
const attendanceRoutes = require('./routes/attendance');
const classRoutes = require('./routes/classes');
const facultyRoutes = require('./routes/faculties');
const accountRoutes = require('./routes/accounts');
const roomRoutes = require('./routes/rooms');
const subjectRoutes = require('./routes/subjects');
const enrollmentRoutes = require('./routes/enrollments');
const classSectionRoutes = require('./routes/class_section');
const sectionScheduleRoutes = require('./routes/section_schedules');
const sessionInstanceRoutes = require('./routes/session_instances');
const teachingAssignmentRoutes = require('./routes/teaching_assignments');
const sessionCheckinTokenRoutes = require('./routes/session_checkin_token.js');

const socketHandler = require('./sockets/socket');
const swaggerUi = require('swagger-ui-express');
// nếu file swagger của bạn là CJS thì dùng './config/swagger.cjs'
const { swaggerSpec } = require('./config/swagger.js');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: (process.env.ALLOWED_ORIGINS?.split(',')) || '*',
    methods: ['GET', 'POST'],
    credentials: true,
  },
});

// 🔹(1) Bật trust proxy vì đang đi qua ngrok (1 lớp proxy)
app.set('trust proxy', 1);

// (tùy chọn) nếu helmet chặn asset từ Swagger, mở chính sách nhẹ nhàng hơn
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));

app.use(cors({
  origin: (process.env.ALLOWED_ORIGINS?.split(',')) || '*',
  credentials: true
}));

// 🔹(2) Rate limiting – chuẩn header + tránh xff lỗi
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 100,
  standardHeaders: true,   // gửi RateLimit-* headers chuẩn
  legacyHeaders: false,    // tắt X-RateLimit-* cũ
  // Nếu vẫn thấy cảnh báo trong dev, có thể bật dòng dưới:
  // validate: { xForwardedForHeader: false },
});
app.use(limiter);

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Cho phép dùng io trong routes
app.set('io', io);

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/teachers', teacherRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/classes', classRoutes);
app.use('/api/faculties', facultyRoutes);
app.use('/api/accounts', accountRoutes);
app.use('/api/rooms', roomRoutes);
app.use('/api/subjects', subjectRoutes);
app.use('/api/enrollments', enrollmentRoutes);
app.use('/api/class-sections', classSectionRoutes);
app.use('/api/section-schedules', sectionScheduleRoutes);
app.use('/api/session-instances', sessionInstanceRoutes);
app.use('/api/teaching-assignments', teachingAssignmentRoutes);
app.use('/api/session-checkin-tokens', sessionCheckinTokenRoutes);

// Swagger UI
app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.get('/openapi.json', (_req, res) => res.json(swaggerSpec)); // tiện export

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Errors
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Something went wrong!',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404
app.use('*', (_req, res) => res.status(404).json({ error: 'Route not found' }));

// Socket handler
socketHandler(io);

// 🔹(3) Bind 0.0.0.0 để device thật có thể gọi qua ngrok / IP LAN
const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📱 Health check: http://localhost:${PORT}/health`);
  if (process.env.NODE_ENV === 'development') console.log('🌐 Start ngrok: npm run dev:ngrok');
});
