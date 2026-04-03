const fs = require('fs');
const multer = require('multer');
const createError = require('http-errors');

const {
  allowedTaskFileMimeTypes,
  maxTaskFileSizeBytes,
  taskUploadDir,
  buildStoredTaskFileName
} = require('../utils/taskFiles');

if (!fs.existsSync(taskUploadDir)) {
  fs.mkdirSync(taskUploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: taskUploadDir,
  filename: (req, file, cb) => {
    cb(null, buildStoredTaskFileName(file.originalname));
  }
});

const upload = multer({
  storage,
  limits: { fileSize: maxTaskFileSizeBytes },
  fileFilter: (req, file, cb) => {
    if (!allowedTaskFileMimeTypes.includes(file.mimetype)) {
      cb(createError(415, 'Unsupported file type'));
      return;
    }
    cb(null, true);
  }
});

module.exports = upload;
