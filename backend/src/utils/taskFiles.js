const path = require('path');
const crypto = require('crypto');

const allowedTaskFileMimeTypes = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'application/pdf',
  'text/plain',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
];

const maxTaskFileSizeBytes = 10 * 1024 * 1024;
const taskUploadDir = path.join(process.cwd(), 'uploads', 'tasks');

function buildStoredTaskFileName(originalName) {
  const baseName = path.basename(originalName || 'file');
  const sanitizedName = baseName.replace(/[^A-Za-z0-9._-]+/g, '-');
  return `${Date.now()}-${crypto.randomUUID()}-${sanitizedName}`;
}

function resolveTaskUploadPath(fileName) {
  const normalizedFileName = path.basename(fileName || '');
  if (!normalizedFileName || normalizedFileName !== fileName) {
    throw new Error('Invalid file path');
  }

  const resolvedPath = path.resolve(taskUploadDir, normalizedFileName);
  const uploadsRoot = `${path.resolve(taskUploadDir)}${path.sep}`;
  if (!resolvedPath.startsWith(uploadsRoot)) {
    throw new Error('Invalid file path');
  }

  return resolvedPath;
}

module.exports = {
  allowedTaskFileMimeTypes,
  maxTaskFileSizeBytes,
  taskUploadDir,
  buildStoredTaskFileName,
  resolveTaskUploadPath
};