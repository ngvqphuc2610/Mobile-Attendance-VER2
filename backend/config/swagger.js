const fs = require('fs');
const path = require('path');
const swaggerJSDoc = require('swagger-jsdoc');

const pkg = require(path.join(__dirname, '..', 'package.json'));

const DEFAULT_API_PREFIX = '/api';
const DEFAULT_TITLE = 'Mobile Attendance API';
const DEFAULT_DESCRIPTION =
  'REST API specification for the Mobile Attendance backend service.';

const trimTrailingSlash = (value) => value.replace(/\/+$/, '');

const resolveServerUrl = () => {
  const explicitServerUrl = (process.env.SWAGGER_SERVER_URL || '').trim();
  if (explicitServerUrl) {
    return trimTrailingSlash(explicitServerUrl);
  }

  const protocol = (process.env.SWAGGER_SERVER_PROTOCOL || 'http').trim();
  const host = (process.env.SWAGGER_SERVER_HOST || 'localhost').trim();
  const port = Number(process.env.PORT || process.env.SWAGGER_SERVER_PORT || 3000);

  return `${protocol}://${host}:${port}`;
};

const resolveApiPrefix = () => {
  const configuredPrefix = (process.env.API_PREFIX || DEFAULT_API_PREFIX).trim();
  if (!configuredPrefix.startsWith('/')) {
    return `/${configuredPrefix}`;
  }
  return trimTrailingSlash(configuredPrefix) || DEFAULT_API_PREFIX;
};

const capitalize = (value) =>
  value
    .split(/[_-]/)
    .filter(Boolean)
    .map((segment) => {
      const lower = segment.toLowerCase();
      if (lower.length <= 3) {
        return lower.toUpperCase();
      }
      return lower.charAt(0).toUpperCase() + lower.slice(1);
    })
    .join(' ');

const methodVerbs = {
  get: 'Retrieve',
  post: 'Create',
  put: 'Update',
  patch: 'Update',
  delete: 'Delete',
};

const routeMetadata = [
  {
    file: 'auth.js',
    basePath: '/auth',
    tag: 'Auth',
    singular: 'Authentication',
    plural: 'Auth',
    defaultSecurity: false,
    securedPaths: [
      '/me',
      '/logout',
      '/totp/init',
      '/totp/enable',
      '/totp/disable',
      '/totp/verify',
    ],
  },
  {
    file: 'accounts.js',
    basePath: '/accounts',
    tag: 'Accounts',
    singular: 'Account',
    plural: 'Accounts',
    defaultSecurity: true,
  },
  {
    file: 'attendance.js',
    basePath: '/attendance',
    tag: 'Attendance',
    singular: 'Attendance Record',
    plural: 'Attendance',
    defaultSecurity: true,
  },
  {
    file: 'checkin.js',
    basePath: '/checkin',
    tag: 'Check-in',
    singular: 'Check-in',
    plural: 'Check-in',
    defaultSecurity: false,
  },
  {
    file: 'class_section.js',
    basePath: '/class-sections',
    tag: 'Class Sections',
    singular: 'Class Section',
    plural: 'Class Sections',
    defaultSecurity: true,
  },
  {
    file: 'classes.js',
    basePath: '/classes',
    tag: 'Classes',
    singular: 'Class',
    plural: 'Classes',
    defaultSecurity: true,
  },
  {
    file: 'enrollments.js',
    basePath: '/enrollments',
    tag: 'Enrollments',
    singular: 'Enrollment',
    plural: 'Enrollments',
    defaultSecurity: true,
  },
  {
    file: 'faculties.js',
    basePath: '/faculties',
    tag: 'Faculties',
    singular: 'Faculty',
    plural: 'Faculties',
    defaultSecurity: true,
  },
  {
    file: 'face_embeddings.js',
    basePath: '/face-embeddings',
    tag: 'Face Embeddings',
    singular: 'Face Embedding',
    plural: 'Face Embeddings',
    defaultSecurity: true,
  },
  {
    file: 'profiles.js',
    basePath: '/profiles',
    tag: 'Profiles',
    singular: 'Profile',
    plural: 'Profiles',
    defaultSecurity: true,
  },
  {
    file: 'rooms.js',
    basePath: '/rooms',
    tag: 'Rooms',
    singular: 'Room',
    plural: 'Rooms',
    defaultSecurity: true,
  },
  {
    file: 'section_schedules.js',
    basePath: '/section-schedules',
    tag: 'Section Schedules',
    singular: 'Section Schedule',
    plural: 'Section Schedules',
    defaultSecurity: true,
  },
  {
    file: 'session_checkin_token.js',
    basePath: '/session-checkin-tokens',
    tag: 'Session Check-in Tokens',
    singular: 'Session Check-in Token',
    plural: 'Session Check-in Tokens',
    defaultSecurity: true,
  },
  {
    file: 'session_instances.js',
    basePath: '/session-instances',
    tag: 'Session Instances',
    singular: 'Session Instance',
    plural: 'Session Instances',
    defaultSecurity: true,
  },
  {
    file: 'students.js',
    basePath: '/students',
    tag: 'Students',
    singular: 'Student',
    plural: 'Students',
    defaultSecurity: true,
  },
  {
    file: 'subjects.js',
    basePath: '/subjects',
    tag: 'Subjects',
    singular: 'Subject',
    plural: 'Subjects',
    defaultSecurity: true,
  },
  {
    file: 'teachers.js',
    basePath: '/teachers',
    tag: 'Teachers',
    singular: 'Teacher',
    plural: 'Teachers',
    defaultSecurity: true,
  },
  {
    file: 'teaching_assignments.js',
    basePath: '/teaching-assignments',
    tag: 'Teaching Assignments',
    singular: 'Teaching Assignment',
    plural: 'Teaching Assignments',
    defaultSecurity: true,
  },
];

const routeDir = path.join(__dirname, '..', 'routes');

const buildOperationId = (basePath, method, expressPath) =>
  `${basePath.replace(/[\\/]/g, '_')}_${method}_${expressPath
    .replace(/[\\/]/g, '_')
    .replace(/[:{}]/g, '')
    .replace(/_{2,}/g, '_')
    .replace(/^_|_$/g, '') || 'root'}`
    .replace(/^-+|-+$/g, '')
    .replace(/_{2,}/g, '_')
    .replace(/^_+|_+$/g, '');

const matchPath = (patterns = [], target) =>
  patterns.some((pattern) => {
    if (pattern instanceof RegExp) {
      return pattern.test(target);
    }
    const normalized = pattern.trim();
    if (normalized.endsWith('*')) {
      const prefix = normalized.slice(0, -1);
      return target.startsWith(prefix);
    }
    return normalized === target;
  });

const buildSummary = (meta, method, expressPath) => {
  const normalizedPath = expressPath === '/' ? '' : expressPath;
  if (!normalizedPath) {
    if (method === 'get') {
      return `List ${meta.plural}`;
    }
    if (method === 'post') {
      return `Create ${meta.singular}`;
    }
    if (method === 'delete') {
      return `Delete ${meta.singular}`;
    }
    return `${methodVerbs[method]} ${meta.singular}`;
  }

  const segments = normalizedPath
    .replace(/^\//, '')
    .split('/')
    .filter(Boolean);

  const hasParam = segments.some((segment) => segment.startsWith(':'));
  const descriptiveSegments = segments
    .filter((segment) => !segment.startsWith(':'))
    .map((segment) => capitalize(segment));

  if (!descriptiveSegments.length && hasParam) {
    return `${methodVerbs[method]} ${meta.singular} by ID`;
  }

  const detail = descriptiveSegments.join(' ');
  return `${methodVerbs[method]} ${meta.singular}${detail ? ` ${detail}` : ''}`;
};

const buildResponses = (meta, method, hasId) => {
  const responses = {
    200: { description: 'Request successful.' },
    400: { $ref: '#/components/responses/ValidationError' },
    401: { $ref: '#/components/responses/UnauthorizedError' },
    500: { $ref: '#/components/responses/ServerError' },
  };

  if (method === 'post') {
    responses[201] = { description: 'Resource created successfully.' };
    delete responses[200];
  }

  if (method === 'delete') {
    responses[200] = { description: 'Resource deleted successfully.' };
  }

  if (meta.defaultSecurity) {
    responses[403] = { $ref: '#/components/responses/ForbiddenError' };
  }

  if (hasId) {
    responses[404] = { $ref: '#/components/responses/NotFoundError' };
  }

  return responses;
};

const extractParameters = (expressPath) => {
  const matches = [...expressPath.matchAll(/:([A-Za-z0-9_]+)/g)];
  if (!matches.length) {
    return [];
  }

  return matches.map(([, name]) => {
    const cleaned = name
      .replace(/_/g, ' ')
      .replace(/([a-z])([A-Z])/g, '$1 $2')
      .toLowerCase();
    const descriptorBase = cleaned === 'id' ? 'resource' : cleaned;
    const descriptor = descriptorBase.replace(/\sid$/, '');

    return {
      name,
      in: 'path',
      required: true,
      schema: { type: 'string' },
      description: `Identifier for the ${descriptor}.`,
    };
  });
};

const determineSecurity = (meta, expressPath) => {
  const normalized = expressPath === '/' ? '' : expressPath;
  if (!meta.defaultSecurity) {
    if (matchPath(meta.securedPaths, normalized)) {
      return [{ bearerAuth: [] }];
    }
    return [];
  }

  if (matchPath(meta.publicPaths, normalized)) {
    return [];
  }

  return [{ bearerAuth: [] }];
};

const generatePaths = () => {
  const paths = {};

  routeMetadata.forEach((meta) => {
    const filePath = path.join(routeDir, meta.file);
    if (!fs.existsSync(filePath)) {
      return;
    }

    const source = fs.readFileSync(filePath, 'utf8');
    const matcher =
      /router\.(get|post|put|patch|delete)\s*\(\s*['"`]([^'"`]+)['"`]/gi;

    let match;
    while ((match = matcher.exec(source)) !== null) {
      const method = match[1].toLowerCase();
      const expressPath = match[2] === '' ? '/' : match[2];
      const joinedPath =
        meta.basePath + (expressPath === '/' ? '' : expressPath);
      const openApiPath = joinedPath.replace(/:([A-Za-z0-9_]+)/g, '{$1}');

      paths[openApiPath] = paths[openApiPath] || {};

      const parameters = extractParameters(expressPath);
      const operationId = buildOperationId(meta.basePath, method, expressPath);
      const summary = buildSummary(meta, method, expressPath);
      const responses = buildResponses(meta, method, parameters.length > 0);
      const security = determineSecurity(meta, expressPath);
      const requiresBody =
        method === 'post' || method === 'put' || method === 'patch';

      const operation = {
        tags: [meta.tag],
        summary,
        description: `${summary}.`,
        operationId,
        responses,
      };

      if (parameters.length) {
        operation.parameters = parameters;
      }

      if (requiresBody) {
        operation.requestBody = {
          required: method !== 'patch',
          content: {
            'application/json': {
              schema: {
                type: 'object',
                description: 'Request payload.',
                additionalProperties: true,
              },
            },
          },
        };
      }

      if (security.length) {
        operation.security = security;
      } else {
        operation.security = [];
      }

      paths[openApiPath][method] = operation;
    }
  });

  return paths;
};

const serverUrl = resolveServerUrl();
const apiPrefix = resolveApiPrefix();

const swaggerDefinition = {
  openapi: '3.0.3',
  info: {
    title: process.env.SWAGGER_TITLE || DEFAULT_TITLE,
    version: pkg.version || '1.0.0',
    description: process.env.SWAGGER_DESCRIPTION || DEFAULT_DESCRIPTION,
    contact: {
      name: process.env.SWAGGER_CONTACT_NAME || 'API Support',
      email: process.env.SWAGGER_CONTACT_EMAIL || 'support@example.com',
    },
  },
  servers: [
    {
      url: `${serverUrl}${apiPrefix}`,
      description: process.env.SWAGGER_SERVER_DESCRIPTION || 'Primary API server',
    },
  ],
  tags: [
    { name: 'Auth', description: 'Authentication and account security' },
    { name: 'Accounts', description: 'Account provisioning and role management' },
    { name: 'Attendance', description: 'Attendance tracking and reporting' },
    { name: 'Check-in', description: 'Student check-in workflows' },
    { name: 'Classes', description: 'Class and section management' },
    { name: 'Class Sections', description: 'Class section lifecycle management' },
    { name: 'Enrollments', description: 'Enrollment management endpoints' },
    { name: 'Faculties', description: 'Faculty administration' },
    { name: 'Face Embeddings', description: 'Face embedding dataset operations' },
    { name: 'Profiles', description: 'Profile information management' },
    { name: 'Rooms', description: 'Classroom and room management' },
    { name: 'Section Schedules', description: 'Section schedule management' },
    {
      name: 'Session Check-in Tokens',
      description: 'One-time tokens used during attendance check-in',
    },
    {
      name: 'Session Instances',
      description: 'Session instance lifecycle and metadata',
    },
    { name: 'Students', description: 'Student management endpoints' },
    { name: 'Subjects', description: 'Subject management endpoints' },
    { name: 'Teachers', description: 'Teacher management endpoints' },
    {
      name: 'Teaching Assignments',
      description: 'Teacher-to-section assignment operations',
    },
  ],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description:
          'Include the JWT access token returned during login in the Authorization header as `Bearer <token>`.',
      },
    },
    schemas: {
      LoginRequest: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email', example: 'user@example.com' },
          password: { type: 'string', format: 'password', example: 'Secret123!' },
          totp: {
            type: 'string',
            description: 'Optional 6-digit TOTP code when 2FA is enabled.',
            example: '123456',
          },
        },
      },
      LoginResponse: {
        type: 'object',
        properties: {
          token: { type: 'string', description: 'JWT access token for authenticated requests.' },
          user: {
            type: 'object',
            properties: {
              id: { type: 'string', format: 'uuid' },
              email: { type: 'string', format: 'email' },
              full_name: { type: 'string' },
              role: { type: 'string', example: 'student' },
              phone_verified: { type: 'boolean' },
              totp_enabled: { type: 'boolean' },
            },
          },
        },
      },
      ErrorResponse: {
        type: 'object',
        properties: {
          error: { type: 'string', example: 'ValidationError' },
          message: { type: 'string', example: 'Invalid request payload.' },
        },
      },
    },
    responses: {
      UnauthorizedError: {
        description: 'Authentication credentials are missing or invalid.',
        content: {
          'application/json': {
            schema: { $ref: '#/components/schemas/ErrorResponse' },
          },
        },
      },
      ValidationError: {
        description: 'The request failed validation checks.',
        content: {
          'application/json': {
            schema: { $ref: '#/components/schemas/ErrorResponse' },
          },
        },
      },
      ForbiddenError: {
        description: 'The authenticated user does not have permission to perform this action.',
        content: {
          'application/json': {
            schema: { $ref: '#/components/schemas/ErrorResponse' },
          },
        },
      },
      NotFoundError: {
        description: 'The requested resource could not be found.',
        content: {
          'application/json': {
            schema: { $ref: '#/components/schemas/ErrorResponse' },
          },
        },
      },
      ServerError: {
        description: 'An unexpected error occurred while processing the request.',
        content: {
          'application/json': {
            schema: { $ref: '#/components/schemas/ErrorResponse' },
          },
        },
      },
    },
  },
  security: [{ bearerAuth: [] }],
  paths: generatePaths(),
};

const swaggerOptions = {
  definition: swaggerDefinition,
  apis: [
    path.join(__dirname, '..', 'routes', '**', '*.js'),
    path.join(__dirname, '..', 'controllers', '**', '*.js'),
    path.join(__dirname, '..', 'models', '**', '*.js'),
  ],
};

const swaggerSpec = swaggerJSDoc(swaggerOptions);

const swaggerUiOptions = {
  explorer: true,
  customSiteTitle: process.env.SWAGGER_SITE_TITLE || 'Mobile Attendance API Docs',
};

module.exports = {
  swaggerDefinition,
  swaggerOptions,
  swaggerSpec,
  swaggerUiOptions,
};
