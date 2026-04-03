const dotenv = require('dotenv');

dotenv.config();

const defaultJwtSecret = 'change_this_in_production';
const jwtSecret = process.env.JWT_SECRET || defaultJwtSecret;

if (process.env.NODE_ENV === 'production' && jwtSecret === defaultJwtSecret) {
  throw new Error('JWT_SECRET must be set in production');
}

module.exports = {
  port: Number(process.env.PORT || 5000),
  nodeEnv: process.env.NODE_ENV || 'development',
  apiPrefix: process.env.API_PREFIX || '/api/v1',
  db: {
    host: process.env.DB_HOST || '127.0.0.1',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    name: process.env.DB_NAME || 'mymanager',
    dialect: 'mysql'
  },
  jwt: {
    secret: jwtSecret,
    accessExpires: process.env.JWT_ACCESS_EXPIRES || '15m',
    refreshExpires: process.env.JWT_REFRESH_EXPIRES || '7d'
  },
  corsOrigin: (process.env.CORS_ORIGIN || '*').split(','),
  rateLimit: {
    windowMs: Number(process.env.RATE_LIMIT_WINDOW_MS || 15 * 60 * 1000),
    max: Number(process.env.RATE_LIMIT_MAX || 200)
  }
};
