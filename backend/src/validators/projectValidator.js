const Joi = require('joi');
const emailSchema = Joi.string().email({ tlds: { allow: false } });

const createProjectSchema = Joi.object({
  name: Joi.string().min(2).max(180).required(),
  description: Joi.string().allow('', null).optional(),
  parent_project_id: Joi.number().integer().positive().allow(null).optional()
});

const updateProjectSchema = Joi.object({
  name: Joi.string().min(2).max(180).optional(),
  description: Joi.string().allow('', null).optional(),
  parent_project_id: Joi.number().integer().positive().allow(null).optional()
});

const inviteMemberSchema = Joi.object({
  email: emailSchema.required()
});

const reorderColumnsSchema = Joi.object({
  columns: Joi.array().items(Joi.object({
    id: Joi.number().integer().required(),
    order_index: Joi.number().integer().min(0).required()
  })).min(1).required()
});

module.exports = { createProjectSchema, updateProjectSchema, inviteMemberSchema, reorderColumnsSchema };
