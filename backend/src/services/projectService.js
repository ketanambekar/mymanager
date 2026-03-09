const createError = require('http-errors');

const models = require('../models');
const projectRepository = require('../repositories/projectRepository');
const { getPagination, toPagedResponse } = require('../utils/pagination');
const { logActivity } = require('./activityService');
const { notify } = require('./notificationService');

async function ensureProjectAccess(projectId, userId) {
  const membership = await models.ProjectMember.findOne({ where: { project_id: projectId, user_id: userId } });
  if (!membership) throw createError(403, 'No access to this project');
  return membership;
}

async function createProject({ name, description, parent_project_id }, user) {
  const tx = await models.sequelize.transaction();
  try {
    if (parent_project_id) {
      await ensureProjectAccess(parent_project_id, user.id);
    }

    const project = await projectRepository.createProject(
      {
        name,
        description,
        parent_project_id: parent_project_id || null,
        created_by: user.id
      },
      tx
    );

    await projectRepository.addMember({ project_id: project.id, user_id: user.id, role: 'owner' }, tx);

    const board = await models.Board.create({ project_id: project.id, name: 'Main Board' }, { transaction: tx });
    await models.Column.bulkCreate([
      { board_id: board.id, name: 'To Do', order_index: 1 },
      { board_id: board.id, name: 'On Progress', order_index: 2 },
      { board_id: board.id, name: 'Done', order_index: 3 }
    ], { transaction: tx });

    await logActivity({
      user_id: user.id,
      project_id: project.id,
      action: 'project_created',
      metadata: { name },
      transaction: tx
    });

    await tx.commit();
    return project;
  } catch (error) {
    await tx.rollback();
    throw error;
  }
}

async function listProjects(userId, query) {
  const { page, limit, offset } = getPagination(query);

  const rows = await models.Project.findAndCountAll({
    include: [{
      model: models.User,
      as: 'members',
      through: { attributes: [] },
      where: { id: userId },
      attributes: []
    }],
    distinct: true,
    order: [['created_at', 'DESC']],
    limit,
    offset
  });

  return toPagedResponse({ ...rows, page, limit });
}

async function getProjectById(projectId, userId) {
  await ensureProjectAccess(projectId, userId);

  const project = await models.Project.findByPk(projectId, {
    include: [{
      model: models.User,
      as: 'members',
      attributes: ['id', 'name', 'email', 'role'],
      through: { attributes: ['role'] }
    }]
  });

  if (!project) throw createError(404, 'Project not found');
  return project;
}

async function updateProject(projectId, payload, user) {
  const membership = await ensureProjectAccess(projectId, user.id);
  if (membership.role !== 'owner' && user.role !== 'admin') {
    throw createError(403, 'Only owner/admin can update project');
  }

  const project = await models.Project.findByPk(projectId);
  if (!project) throw createError(404, 'Project not found');

  if (payload.parent_project_id) {
    if (Number(payload.parent_project_id) === Number(projectId)) {
      throw createError(400, 'Project cannot be its own parent');
    }
    await ensureProjectAccess(payload.parent_project_id, user.id);
  }

  await projectRepository.updateProject(project, payload);
  await logActivity({ user_id: user.id, project_id: project.id, action: 'project_updated', metadata: payload });
  return project;
}

async function deleteProject(projectId, user) {
  const membership = await ensureProjectAccess(projectId, user.id);
  if (membership.role !== 'owner' && user.role !== 'admin') {
    throw createError(403, 'Only owner/admin can delete project');
  }

  const project = await models.Project.findByPk(projectId);
  if (!project) throw createError(404, 'Project not found');

  await projectRepository.deleteProject(project);
  await logActivity({ user_id: user.id, project_id: projectId, action: 'project_deleted' });
}

async function inviteMember(projectId, email, invitedBy) {
  const membership = await ensureProjectAccess(projectId, invitedBy.id);
  if (membership.role !== 'owner' && invitedBy.role !== 'admin') {
    throw createError(403, 'Only owner/admin can invite');
  }

  const user = await models.User.findOne({ where: { email } });
  if (!user) throw createError(404, 'User not found with this email');

  const exists = await models.ProjectMember.findOne({ where: { project_id: projectId, user_id: user.id } });
  if (exists) throw createError(409, 'User already in project');

  const tx = await models.sequelize.transaction();
  try {
    const member = await projectRepository.addMember({ project_id: projectId, user_id: user.id, role: 'member' }, tx);

    await notify({ user_id: user.id, type: 'project_invite', reference_id: projectId, transaction: tx });
    await logActivity({
      user_id: invitedBy.id,
      project_id: projectId,
      action: 'member_invited',
      metadata: { invited_user_id: user.id },
      transaction: tx
    });

    await tx.commit();
    return member;
  } catch (error) {
    await tx.rollback();
    throw error;
  }
}

async function listProjectMembers(projectId, userId) {
  await ensureProjectAccess(projectId, userId);

  return models.ProjectMember.findAll({
    where: { project_id: projectId },
    include: [{ model: models.User, attributes: ['id', 'name', 'email', 'role'] }],
    order: [['created_at', 'ASC']]
  });
}

async function reorderColumns(boardId, columns, userId) {
  const board = await models.Board.findByPk(boardId);
  if (!board) throw createError(404, 'Board not found');

  await ensureProjectAccess(board.project_id, userId);

  const updates = columns.map((c) =>
    models.Column.update({ order_index: c.order_index }, { where: { id: c.id, board_id: boardId } })
  );
  await Promise.all(updates);

  return models.Column.findAll({ where: { board_id: boardId }, order: [['order_index', 'ASC']] });
}

async function listBoards(projectId, userId) {
  await ensureProjectAccess(projectId, userId);

  return models.Board.findAll({
    where: { project_id: projectId },
    include: [{ model: models.Column }],
    order: [['created_at', 'ASC'], [models.Column, 'order_index', 'ASC']]
  });
}

module.exports = {
  createProject,
  listProjects,
  getProjectById,
  updateProject,
  deleteProject,
  inviteMember,
  listProjectMembers,
  reorderColumns,
  listBoards,
  ensureProjectAccess
};
