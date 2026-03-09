const Joi = require('joi');

const listNotificationQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional()
});

module.exports = { listNotificationQuerySchema };
