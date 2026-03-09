const models = require('../models');

async function createTask(payload, transaction) {
  return models.Task.create(payload, { transaction });
}

async function createComment(payload, transaction) {
  return models.TaskComment.create(payload, { transaction });
}

async function createTaskFile(payload, transaction) {
  return models.TaskFile.create(payload, { transaction });
}

module.exports = { createTask, createComment, createTaskFile };
