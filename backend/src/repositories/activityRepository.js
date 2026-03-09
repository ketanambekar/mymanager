const models = require('../models');

async function addActivity(payload, transaction) {
  return models.ActivityLog.create(payload, { transaction });
}

module.exports = { addActivity };
