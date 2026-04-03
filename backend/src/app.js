const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const path = require('path');
const swaggerUi = require('swagger-ui-express');

const env = require('./config/env');
const routes = require('./routes');
const swaggerSpec = require('./docs/swagger');
const { notFound, errorHandler } = require('./middlewares/errorHandler');

const app = express();

const privateNetworkPattern = /^(127\.0\.0\.1|localhost|192\.168\.|10\.|172\.(1[6-9]|2\d|3[0-1])\.)/;

function isPrivateNetworkHost(hostname) {
  return privateNetworkPattern.test(hostname);
}

function isAllowedOrigin(origin) {
  if (!origin) return true;

  try {
    const parsed = new URL(origin);

    if (env.corsOrigin.includes(origin)) return true;

    if (env.corsOrigin.includes('*')) {
      return env.nodeEnv === 'production' ? true : isPrivateNetworkHost(parsed.hostname);
    }

    if (env.nodeEnv !== 'production' && isPrivateNetworkHost(parsed.hostname)) {
      return true;
    }
  } catch (_) {
    return false;
  }

  return false;
}

app.use(helmet());
app.use(cors({
  origin(origin, callback) {
    if (isAllowedOrigin(origin)) {
      callback(null, true);
      return;
    }
    console.warn(`CORS blocked for origin: ${origin}`);
    callback(null, false);
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  optionsSuccessStatus: 200,
  credentials: true
}));
app.use(morgan('combined'));
app.use(cookieParser());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

app.use(rateLimit({
  windowMs: env.rateLimit.windowMs,
  max: env.rateLimit.max,
  standardHeaders: true,
  legacyHeaders: false
}));

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.use(env.apiPrefix, routes);

app.get('/health', (req, res) => {
  res.json({ success: true, message: 'Service healthy' });
});

app.use(notFound);
app.use(errorHandler);

module.exports = app;
