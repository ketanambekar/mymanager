const multer = require('multer');

function notFound(req, res, next) {
  const err = new Error(`Route not found: ${req.originalUrl}`);
  err.status = 404;
  next(err);
}

function errorHandler(err, req, res, next) {
  let status = err.status || err.statusCode || 500;

  if (err instanceof multer.MulterError) {
    status = err.code === 'LIMIT_FILE_SIZE' ? 413 : 400;
  }

  const payload = {
    success: false,
    message: err.message || 'Internal Server Error'
  };

  if (process.env.EXPOSE_ERROR_STACK === 'true' && err.stack) {
    payload.stack = err.stack;
  }

  res.status(status).json(payload);
}

module.exports = { notFound, errorHandler };
