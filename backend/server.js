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

const socketHandler = require('./sockets/socket'); // ✅ CommonJS

const app = express();
const server = http.createServer(app);              // ✅ tạo HTTP server
const io = new Server(server, {                    // ✅ gắn socket.io
  cors: {
    origin: (process.env.ALLOWED_ORIGINS?.split(',')) || '*',
    methods: ['GET', 'POST'],
    credentials: true,
  },
});

// Nếu cần dùng io trong route handlers:
app.set('io', io);

// Security middleware
app.use(helmet());
app.use(cors({
  origin: (process.env.ALLOWED_ORIGINS?.split(',')) || '*',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 100
});
app.use(limiter);

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/teachers', teacherRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/classes', classRoutes);
app.use('/api/faculties', facultyRoutes);
app.use('/api/accounts', accountRoutes);

// Health check
app.get('/health', (req, res) => {
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
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// ✅ Khởi động socket handler
socketHandler(io);

// ✅ Listen qua HTTP server (không dùng app.listen)
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📱 Health check: http://localhost:${PORT}/health`);
  if (process.env.NODE_ENV === 'development') {
    console.log('🌐 Start ngrok: npm run ngrok');
  }
});
