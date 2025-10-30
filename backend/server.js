const path = require('path');
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const swaggerUi = require('swagger-ui-express');
const dotenv = require('dotenv');

// Load env files (backend/.env takes priority, then project root .env)
[
  path.resolve(__dirname, '.env'),
  path.resolve(__dirname, '..', '.env'),
].forEach((envPath) => {
  dotenv.config({ path: envPath, override: false });
});

const db = require('./config/database');
const socketHandler = require('./sockets/socket');
const { swaggerSpec, swaggerUiOptions } = require('./config/swagger');

const routes = {
  auth: require('./routes/auth'),
  students: require('./routes/students'),
  teachers: require('./routes/teachers'),
  attendance: require('./routes/attendance'),
  classes: require('./routes/classes'),
  faculties: require('./routes/faculties'),
  accounts: require('./routes/accounts'),
  rooms: require('./routes/rooms'),
  subjects: require('./routes/subjects'),
  enrollments: require('./routes/enrollments'),
  'class-sections': require('./routes/class_section'),
  'section-schedules': require('./routes/section_schedules'),
  'session-instances': require('./routes/session_instances'),
  'teaching-assignments': require('./routes/teaching_assignments'),
  'session-checkin-tokens': require('./routes/session_checkin_token'),
  checkin: require('./routes/checkin'),
  profiles: require('./routes/profiles'),
  'face-embeddings': require('./routes/face_embeddings'),
};

const app = express();

const ensureLeadingSlash = (value, fallback) => {
  if (!value) {
    return fallback;
  }
  const trimmed = value.trim();
  if (!trimmed) {
    return fallback;
  }
  return trimmed.startsWith('/') ? trimmed : `/${trimmed}`;
};

const normalizePrefix = (prefix) => {
  if (!prefix) {
    return '/api';
  }
  const trimmed = prefix.trim();
  if (!trimmed) {
    return '/api';
  }
  const withLeading = trimmed.startsWith('/') ? trimmed : `/${trimmed}`;
  return withLeading.replace(/\/+$/, '') || '/api';
};

const apiPrefix = normalizePrefix(process.env.API_PREFIX);
const swaggerRoute = ensureLeadingSlash(
  process.env.SWAGGER_ROUTE,
  `${apiPrefix}/docs`,
);
const swaggerJsonPath = ensureLeadingSlash(
  process.env.SWAGGER_JSON_PATH,
  '/openapi.json',
);
const bodyLimit = process.env.REQUEST_BODY_LIMIT || '10mb';
const rateLimitWindowMs = Number(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000;
const rateLimitMax = Number(process.env.RATE_LIMIT_MAX) || 100;

const allowedOrigins = (process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

const corsConfig = {
  origin: allowedOrigins.length > 0 ? allowedOrigins : true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
};

const server = http.createServer(app);
const io = new Server(server, { cors: corsConfig });

app.set('trust proxy', Number(process.env.TRUST_PROXY || 1));
app.disable('x-powered-by');

app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  }),
);

app.use(cors(corsConfig));

app.use(
  rateLimit({
    windowMs: rateLimitWindowMs,
    limit: rateLimitMax,
    standardHeaders: true,
    legacyHeaders: false,
  }),
);

app.use(express.json({ limit: bodyLimit }));
app.use(express.urlencoded({ extended: true, limit: bodyLimit }));

app.set('io', io);

app.get('/health', (_req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.use(swaggerRoute, swaggerUi.serve, swaggerUi.setup(swaggerSpec, swaggerUiOptions));
app.get(swaggerJsonPath, (_req, res) => res.json(swaggerSpec));
app.get('/', (_req, res) => res.redirect(swaggerRoute));

Object.entries(routes).forEach(([segment, router]) => {
  app.use(`${apiPrefix}/${segment}`, router);
});

app.use((req, res, next) => {
  if (res.headersSent) {
    return next();
  }
  res.status(404).json({ error: 'Route not found' });
});

app.use((err, req, res, _next) => {
  console.error('Unhandled error:', err);
  const status = err.status || err.statusCode || 500;
  res.status(status).json({
    error: err.name || 'InternalServerError',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong!',
    ...(process.env.NODE_ENV === 'development' && err.stack ? { stack: err.stack } : {}),
  });
});

const tokenSweepIntervalMs =
  Number(process.env.SESSION_TOKEN_SWEEP_INTERVAL_MS) || 30 * 1000;

const expireActiveTokens = async () => {
  try {
    await db.execute(
      `
        UPDATE session_checkin_tokens
        SET is_active = 0
        WHERE is_active = 1
          AND expires_at <= NOW()
      `,
    );
  } catch (error) {
    console.error('expireTokens job error:', error);
  }
};

let sweepTimer;
let started = false;
const scheduleTokenSweep = () => {
  if (!sweepTimer) {
    sweepTimer = setInterval(expireActiveTokens, tokenSweepIntervalMs);
  }
  return sweepTimer;
};

socketHandler(io);

const port = Number(process.env.PORT) || 3000;
const host = process.env.HOST || '0.0.0.0';

const start = () => {
  if (started) {
    return server;
  }
  started = true;
  scheduleTokenSweep();
  server.listen(port, host, () => {
    const baseUrl = `http://${host === '0.0.0.0' ? 'localhost' : host}:${port}`;
    console.log(`Server listening on ${baseUrl}`);
    console.log(`Swagger UI available at ${baseUrl}${swaggerRoute}`);
    console.log(`OpenAPI JSON available at ${baseUrl}${swaggerJsonPath}`);
    console.log(`Health check available at ${baseUrl}/health`);
  });
  return server;
};

const shutdown = () => {
  if (sweepTimer) {
    clearInterval(sweepTimer);
    sweepTimer = undefined;
  }
  if (server.listening) {
    server.close(() => {
      console.log('HTTP server closed.');
    });
  }
  io.close(() => {
    console.log('Socket server closed.');
  });
};

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
process.on('uncaughtException', (error) => {
  console.error('Uncaught exception:', error);
});
process.on('unhandledRejection', (reason) => {
  console.error('Unhandled promise rejection:', reason);
});

if (require.main === module) {
  start();
}

module.exports = {
  app,
  server,
  io,
  start,
  shutdown,
};
