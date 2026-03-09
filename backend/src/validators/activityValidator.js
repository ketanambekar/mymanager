const Joi = require('joi');

const activityQuerySchema = Joi.object({
  project_id: Joi.number().integer().optional(),
  task_id: Joi.number().integer().optional(),
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional()
});

module.exports = { activityQuerySchema };
