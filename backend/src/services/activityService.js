const activityRepository = require('../repositories/activityRepository');
const models = require('../models');
const { getPagination, toPagedResponse } = require('../utils/pagination');

async function logActivity({ user_id, project_id = null, task_id = null, action, metadata = null, transaction = null }) {
  return activityRepository.addActivity({ user_id, project_id, task_id, action, metadata }, transaction);
}

async function listActivityLogs({ project_id, task_id, page = 1, limit = 20 }) {
  const pagination = getPagination({ page, limit });
  const where = {};
  if (project_id) where.project_id = project_id;
  if (task_id) where.task_id = task_id;

  const result = await models.ActivityLog.findAndCountAll({
    where,
    include: [{ model: models.User, attributes: ['id', 'name', 'email'] }],
    order: [['created_at', 'DESC']],
    limit: pagination.limit,
    offset: pagination.offset
  });

  return toPagedResponse({ ...result, page: pagination.page, limit: pagination.limit });
}

module.exports = { logActivity, listActivityLogs };
