const Joi = require('joi');

const statusCode = Joi.string().trim().min(2).max(64).pattern(/^[A-Za-z0-9_\-\s]+$/);
const dueDateSchema = Joi.date().iso().min('now').allow(null);

const createTaskSchema = Joi.object({
  title: Joi.string().max(220).required(),
  description: Joi.string().allow('', null).optional(),
  priority: Joi.string().valid('low', 'medium', 'high').default('medium'),
  status: statusCode.default('todo'),
  project_id: Joi.number().integer().required(),
  column_id: Joi.number().integer().required(),
  assigned_to: Joi.number().integer().allow(null).optional(),
  due_date: dueDateSchema.optional(),
  order_index: Joi.number().integer().min(0).default(0)
});

const updateTaskSchema = Joi.object({
  title: Joi.string().max(220).optional(),
  description: Joi.string().allow('', null).optional(),
  priority: Joi.string().valid('low', 'medium', 'high').optional(),
  status: statusCode.optional(),
  column_id: Joi.number().integer().optional(),
  assigned_to: Joi.number().integer().allow(null).optional(),
  due_date: dueDateSchema.optional(),
  order_index: Joi.number().integer().min(0).optional()
});

const moveTaskSchema = Joi.object({
  column_id: Joi.number().integer().required(),
  status: statusCode.required(),
  order_index: Joi.number().integer().min(0).optional()
});

const commentSchema = Joi.object({
  comment: Joi.string().min(1).required()
});

const taskQuerySchema = Joi.object({
  project_id: Joi.number().integer().required(),
  priority: Joi.string().valid('low', 'medium', 'high').optional(),
  assigned_to: Joi.number().integer().optional(),
  status: statusCode.optional(),
  due_from: Joi.date().iso().optional(),
  due_to: Joi.date().iso().optional(),
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional()
});

module.exports = { createTaskSchema, updateTaskSchema, moveTaskSchema, commentSchema, taskQuerySchema };
