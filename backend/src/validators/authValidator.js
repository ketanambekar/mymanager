const Joi = require('joi');
const emailSchema = Joi.string().email({ tlds: { allow: false } });

const registerSchema = Joi.object({
  name: Joi.string().min(2).max(120).required(),
  email: emailSchema.required(),
  password: Joi.string().min(8).max(64).required()
});

const loginSchema = Joi.object({
  email: emailSchema.required(),
  password: Joi.string().required()
});

const refreshSchema = Joi.object({
  refresh_token: Joi.string().optional()
});

const requestEmailOtpSchema = Joi.object({
  email: emailSchema.required(),
  name: Joi.string().min(2).max(120).optional()
});

const verifyEmailOtpSchema = Joi.object({
  email: emailSchema.required(),
  otp: Joi.string().pattern(/^\d{6}$/).required(),
  name: Joi.string().min(2).max(120).optional()
});

module.exports = {
  registerSchema,
  loginSchema,
  refreshSchema,
  requestEmailOtpSchema,
  verifyEmailOtpSchema
};
