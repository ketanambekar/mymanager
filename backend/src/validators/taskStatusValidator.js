const Joi = require('joi');

const hexColor = Joi.string().pattern(/^#?[0-9A-Fa-f]{6}$/);

const createTaskStatusSchema = Joi.object({
  name: Joi.string().min(2).max(80).required(),
  code: Joi.string().min(2).max(64).optional(),
  color: hexColor.allow(null).optional(),
  sort_order: Joi.number().integer().min(0).optional()
});

const updateTaskStatusSchema = Joi.object({
  name: Joi.string().min(2).max(80).optional(),
  code: Joi.string().min(2).max(64).optional(),
  color: hexColor.allow('', null).optional(),
  sort_order: Joi.number().integer().min(0).optional()
}).min(1);

module.exports = {
  createTaskStatusSchema,
  updateTaskStatusSchema
};
