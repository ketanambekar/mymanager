const fs = require('fs');
const path = require('path');
const createError = require('http-errors');
const { Op } = require('sequelize');

const models = require('../models');
const taskRepository = require('../repositories/taskRepository');
const { getPagination, toPagedResponse } = require('../utils/pagination');
const { extractMentions } = require('../utils/mention');
const { notify } = require('./notificationService');
const { logActivity } = require('./activityService');
const { ensureProjectAccess } = require('./projectService');
const { ensureDefaultStatuses, ensureStatusExists } = require('./taskStatusService');
const { normalizeStatusCode } = require('../utils/taskStatus');
const {
  allowedTaskFileMimeTypes,
  maxTaskFileSizeBytes,
  resolveTaskUploadPath
} = require('../utils/taskFiles');

async function createTask(payload, user) {
  await ensureProjectAccess(payload.project_id, user.id);
  await ensureDefaultStatuses(user.id);

  const status = normalizeStatusCode(payload.status || 'todo');
  await ensureStatusExists(user.id, status);

  const tx = await models.sequelize.transaction();
  try {
    const task = await taskRepository.createTask({ ...payload, status, created_by: user.id }, tx);

    if (payload.assigned_to) {
      await notify({ user_id: payload.assigned_to, type: 'task_assigned', reference_id: task.id, transaction: tx });
    }

    await logActivity({ user_id: user.id, project_id: payload.project_id, task_id: task.id, action: 'task_created', metadata: { title: payload.title }, transaction: tx });
    await tx.commit();
    return task;
  } catch (error) {
    await tx.rollback();
    throw error;
  }
}

async function listTasks(query, user) {
  if (!query.project_id) throw createError(422, 'project_id is required');
  await ensureProjectAccess(query.project_id, user.id);
  await ensureDefaultStatuses(user.id);

  const { page, limit, offset } = getPagination(query);
  const where = { project_id: query.project_id };

  if (query.priority) where.priority = query.priority;
  if (query.assigned_to) where.assigned_to = query.assigned_to;
  if (query.status) {
    const normalized = normalizeStatusCode(query.status);
    await ensureStatusExists(user.id, normalized);
    where.status = normalized;
  }

  if (query.due_from || query.due_to) {
    where.due_date = {};
    if (query.due_from) where.due_date[Op.gte] = new Date(query.due_from);
    if (query.due_to) where.due_date[Op.lte] = new Date(query.due_to);
  }

  const result = await models.Task.findAndCountAll({
    where,
    include: [
      { model: models.User, as: 'assignee', attributes: ['id', 'name', 'email'] },
      { model: models.Column, attributes: ['id', 'name', 'order_index'] }
    ],
    order: [['order_index', 'ASC'], ['created_at', 'DESC']],
    limit,
    offset
  });

  return toPagedResponse({ ...result, page, limit });
}

async function updateTask(taskId, payload, user) {
  const task = await models.Task.findByPk(taskId);
  if (!task) throw createError(404, 'Task not found');

  await ensureProjectAccess(task.project_id, user.id);
  await ensureDefaultStatuses(user.id);

  if (payload.status !== undefined) {
    const normalized = normalizeStatusCode(payload.status);
    await ensureStatusExists(user.id, normalized);
    payload.status = normalized;
  }

  const previousAssignee = task.assigned_to;

  await task.update(payload);

  if (payload.assigned_to && String(payload.assigned_to) !== String(previousAssignee || '')) {
    await notify({ user_id: payload.assigned_to, type: 'task_assigned', reference_id: task.id });
    await logActivity({ user_id: user.id, project_id: task.project_id, task_id: task.id, action: 'user_assigned', metadata: { assigned_to: payload.assigned_to } });
  }

  await logActivity({ user_id: user.id, project_id: task.project_id, task_id: task.id, action: 'task_updated', metadata: payload });
  return task;
}

async function deleteTask(taskId, user) {
  const task = await models.Task.findByPk(taskId);
  if (!task) throw createError(404, 'Task not found');

  await ensureProjectAccess(task.project_id, user.id);
  await task.destroy();
  await logActivity({ user_id: user.id, project_id: task.project_id, task_id: task.id, action: 'task_deleted' });
}

async function moveTask(taskId, { column_id, status, order_index }, user) {
  const task = await models.Task.findByPk(taskId);
  if (!task) throw createError(404, 'Task not found');

  await ensureProjectAccess(task.project_id, user.id);
  await ensureDefaultStatuses(user.id);

  const normalizedStatus = normalizeStatusCode(status);
  await ensureStatusExists(user.id, normalizedStatus);

  await task.update({ column_id, status: normalizedStatus, order_index: order_index || task.order_index });

  await logActivity({ user_id: user.id, project_id: task.project_id, task_id: task.id, action: 'task_moved', metadata: { column_id, status: normalizedStatus, order_index } });
  return task;
}

async function addComment(taskId, comment, user) {
  const task = await models.Task.findByPk(taskId);
  if (!task) throw createError(404, 'Task not found');

  await ensureProjectAccess(task.project_id, user.id);

  const tx = await models.sequelize.transaction();
  try {
    const row = await taskRepository.createComment({ task_id: taskId, user_id: user.id, comment }, tx);
    await logActivity({ user_id: user.id, project_id: task.project_id, task_id: taskId, action: 'comment_added', metadata: { comment_id: row.id }, transaction: tx });

    const emails = extractMentions(comment);
    if (emails.length) {
      const users = await models.User.findAll({ where: { email: emails } });
      await Promise.all(users.map((u) => notify({ user_id: u.id, type: 'comment_mention', reference_id: row.id, transaction: tx })));
    }

    await tx.commit();
    return row;
  } catch (error) {
    await tx.rollback();
    throw error;
  }
}

async function listComments(taskId, user) {
  const task = await models.Task.findByPk(taskId);
  if (!task) throw createError(404, 'Task not found');
  await ensureProjectAccess(task.project_id, user.id);

  return models.TaskComment.findAll({
    where: { task_id: taskId },
    include: [{ model: models.User, as: 'author', attributes: ['id', 'name', 'email'] }],
    order: [['created_at', 'ASC']]
  });
}

async function updateComment(commentId, comment, user) {
  const row = await models.TaskComment.findByPk(commentId);
  if (!row) throw createError(404, 'Comment not found');
  if (String(row.user_id) !== String(user.id) && user.role !== 'admin') throw createError(403, 'Cannot edit this comment');

  await row.update({ comment });
  return row;
}

async function deleteComment(commentId, user) {
  const row = await models.TaskComment.findByPk(commentId);
  if (!row) throw createError(404, 'Comment not found');
  if (String(row.user_id) !== String(user.id) && user.role !== 'admin') throw createError(403, 'Cannot delete this comment');

  await row.destroy();
}

async function uploadTaskFile(taskId, file, user) {
  const task = await models.Task.findByPk(taskId);
  if (!task) throw createError(404, 'Task not found');

  await ensureProjectAccess(task.project_id, user.id);

  if (!allowedTaskFileMimeTypes.includes(file.mimetype)) {
    throw createError(415, 'Unsupported file type');
  }

  if (file.size > maxTaskFileSizeBytes) {
    throw createError(413, 'File exceeds 10MB limit');
  }

  const row = await taskRepository.createTaskFile({
    task_id: taskId,
    uploaded_by: user.id,
    original_name: file.originalname,
    file_name: file.filename,
    mime_type: file.mimetype,
    size: file.size
  });

  return row;
}

async function deleteTaskFile(fileId, user) {
  const file = await models.TaskFile.findByPk(fileId);
  if (!file) throw createError(404, 'File not found');

  const task = await models.Task.findByPk(file.task_id);
  await ensureProjectAccess(task.project_id, user.id);

  const absPath = resolveTaskUploadPath(file.file_name);
  const tx = await models.sequelize.transaction();

  try {
    if (fs.existsSync(absPath)) {
      fs.unlinkSync(absPath);
    }

    await file.destroy({ transaction: tx });
    await tx.commit();
  } catch (error) {
    await tx.rollback();
    throw error;
  }
}

async function downloadTaskFile(fileId, user) {
  const file = await models.TaskFile.findByPk(fileId);
  if (!file) throw createError(404, 'File not found');

  const task = await models.Task.findByPk(file.task_id);
  await ensureProjectAccess(task.project_id, user.id);

  return {
    file,
    absPath: resolveTaskUploadPath(file.file_name)
  };
}

module.exports = {
  createTask,
  listTasks,
  updateTask,
  deleteTask,
  moveTask,
  addComment,
  listComments,
  updateComment,
  deleteComment,
  uploadTaskFile,
  deleteTaskFile,
  downloadTaskFile
};
