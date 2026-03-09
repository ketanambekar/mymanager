const createError = require('http-errors');

const models = require('../models');
const { DEFAULT_TASK_STATUSES, normalizeStatusCode, ensureValidStatusCode } = require('../utils/taskStatus');

async function ensureDefaultStatuses(userId, transaction) {
  const count = await models.TaskStatus.count({ where: { user_id: userId }, transaction });
  if (count > 0) return;

  await models.TaskStatus.bulkCreate(
    DEFAULT_TASK_STATUSES.map((s) => ({ ...s, user_id: userId })),
    { transaction }
  );
}

async function listTaskStatuses(userId) {
  await ensureDefaultStatuses(userId);
  return models.TaskStatus.findAll({
    where: { user_id: userId },
    order: [['sort_order', 'ASC'], ['id', 'ASC']]
  });
}

async function ensureStatusExists(userId, statusCode) {
  await ensureDefaultStatuses(userId);
  const code = normalizeStatusCode(statusCode);
  ensureValidStatusCode(code);

  const row = await models.TaskStatus.findOne({ where: { user_id: userId, code } });
  if (!row) {
    throw createError(422, `Unknown task status: ${statusCode}`);
  }
  return row;
}

async function createTaskStatus(payload, user) {
  await ensureDefaultStatuses(user.id);

  const name = (payload.name || '').trim();
  if (!name) throw createError(422, 'Status name is required');

  const code = normalizeStatusCode(payload.code || name);
  ensureValidStatusCode(code);

  const exists = await models.TaskStatus.findOne({ where: { user_id: user.id, code } });
  if (exists) throw createError(409, 'Status code already exists');

  const sameName = await models.TaskStatus.findOne({ where: { user_id: user.id, name } });
  if (sameName) throw createError(409, 'Status name already exists');

  const maxSort = await models.TaskStatus.max('sort_order', { where: { user_id: user.id } });

  return models.TaskStatus.create({
    user_id: user.id,
    code,
    name,
    color: payload.color || null,
    sort_order: payload.sort_order ?? ((Number.isFinite(maxSort) ? maxSort : 0) + 1),
    is_system: false
  });
}

async function updateTaskStatus(statusId, payload, user) {
  const row = await models.TaskStatus.findByPk(statusId);
  if (!row || String(row.user_id) !== String(user.id)) throw createError(404, 'Task status not found');

  const next = {};

  if (payload.name !== undefined) {
    const name = (payload.name || '').trim();
    if (!name) throw createError(422, 'Status name is required');

    const duplicate = await models.TaskStatus.findOne({ where: { user_id: user.id, name } });
    if (duplicate && String(duplicate.id) !== String(row.id)) {
      throw createError(409, 'Status name already exists');
    }
    next.name = name;
  }

  if (payload.code !== undefined) {
    if (row.is_system) throw createError(403, 'Cannot change code of default status');

    const code = normalizeStatusCode(payload.code);
    ensureValidStatusCode(code);

    const duplicate = await models.TaskStatus.findOne({ where: { user_id: user.id, code } });
    if (duplicate && String(duplicate.id) !== String(row.id)) {
      throw createError(409, 'Status code already exists');
    }
    next.code = code;
  }

  if (payload.color !== undefined) next.color = payload.color || null;
  if (payload.sort_order !== undefined) next.sort_order = payload.sort_order;

  await row.update(next);
  return row;
}

async function deleteTaskStatus(statusId, user) {
  const row = await models.TaskStatus.findByPk(statusId);
  if (!row || String(row.user_id) !== String(user.id)) throw createError(404, 'Task status not found');
  if (row.is_system) throw createError(403, 'Cannot delete default status');

  const inUseCount = await models.Task.count({ where: { created_by: user.id, status: row.code } });
  if (inUseCount > 0) {
    throw createError(409, 'Status is in use by tasks. Update task statuses first.');
  }

  await row.destroy();
}

module.exports = {
  ensureDefaultStatuses,
  ensureStatusExists,
  listTaskStatuses,
  createTaskStatus,
  updateTaskStatus,
  deleteTaskStatus
};
