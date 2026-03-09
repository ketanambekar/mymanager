const createError = require('http-errors');

const DEFAULT_TASK_STATUSES = [
  { code: 'todo', name: 'Todo', color: '#6366F1', sort_order: 1, is_system: true },
  { code: 'on_progress', name: 'In Progress', color: '#F59E0B', sort_order: 2, is_system: true },
  { code: 'done', name: 'Completed', color: '#22C55E', sort_order: 3, is_system: true }
];

function normalizeStatusCode(input) {
  const raw = (input || '').toString().trim().toLowerCase();
  return raw
    .replace(/[^a-z0-9\s_-]/g, '')
    .replace(/[\s-]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '');
}

function ensureValidStatusCode(code) {
  if (!code) {
    throw createError(422, 'Status code is required');
  }
  if (!/^[a-z0-9_]{2,64}$/.test(code)) {
    throw createError(422, 'Status code must be 2-64 chars: a-z, 0-9, underscore');
  }
}

module.exports = {
  DEFAULT_TASK_STATUSES,
  normalizeStatusCode,
  ensureValidStatusCode
};
