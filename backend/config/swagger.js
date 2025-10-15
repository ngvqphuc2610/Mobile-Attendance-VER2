// backend/config/swagger.js (CommonJS)
const swaggerJSDoc = require('swagger-jsdoc');

const swaggerSpec = swaggerJSDoc({
    definition: {
        openapi: '3.0.3',
        info: {
            title: 'Mobile Attendance API',
            version: '1.0.0',
            description: 'OpenAPI docs cho backend điểm danh',
        },
        servers: [
            { url: 'http://localhost:3000', description: 'Local' },
            // { url: 'https://your-ngrok-or-prod', description: 'Prod' },
        ],
        components: {
            securitySchemes: {
                bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
            },
            schemas: {
                LoginRequest: {
                    type: 'object',
                    required: ['email', 'password'],
                    properties: {
                        email: { type: 'string', format: 'email' },
                        password: { type: 'string', format: 'password' },
                    },
                },
                LoginResponse: {
                    type: 'object',
                    properties: {
                        token: { type: 'string' },
                        user: {
                            type: 'object',
                            properties: {
                                id: { type: 'string', format: 'uuid' },
                                email: { type: 'string' },
                                roles: { type: 'array', items: { type: 'string' } },
                            },
                        },
                    },
                },
                AttendanceCreate: {
                    type: 'object',
                    required: ['user_id', 'section_id', 'method'],
                    properties: {
                        user_id: { type: 'string', format: 'uuid' },
                        section_id: { type: 'string', format: 'uuid' },
                        method: { type: 'string', enum: ['face', 'barcode', 'manual'] },
                        confidence_score: { type: 'number', minimum: 0, maximum: 1 },
                        note: { type: 'string' },
                    },
                },
            },
        },
    },
    apis: [
        './backend/routes/*.js',        // scan JSDoc in routes
        './backend/controller/*.js',    // (if you describe in controllers)
    ],
});

module.exports = { swaggerSpec };
