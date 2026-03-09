const models = require('../models');

async function createProject(payload, transaction) {
  return models.Project.create(payload, { transaction });
}

async function updateProject(project, payload) {
  return project.update(payload);
}

async function deleteProject(project) {
  return project.destroy();
}

async function addMember(payload, transaction) {
  return models.ProjectMember.create(payload, { transaction });
}

module.exports = { createProject, updateProject, deleteProject, addMember };
