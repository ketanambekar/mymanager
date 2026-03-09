const models = require('../models');

async function createNotification(payload, transaction) {
  return models.Notification.create(payload, { transaction });
}

module.exports = { createNotification };
