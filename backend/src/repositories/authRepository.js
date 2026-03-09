const models = require('../models');
const { Op } = require('sequelize');

async function findUserByEmail(email) {
  return models.User.findOne({ where: { email } });
}

async function createUser(payload, transaction) {
  return models.User.create(payload, { transaction });
}

async function createSession(payload, transaction) {
  return models.Session.create(payload, { transaction });
}

async function findSessionByRefreshToken(refresh_token) {
  return models.Session.findOne({ where: { refresh_token } });
}

async function deleteSessionByToken(token) {
  return models.Session.destroy({ where: { token } });
}

async function findLatestSessionByUserId(userId) {
  return models.Session.findOne({
    where: { user_id: userId },
    paranoid: false,
    order: [['updated_at', 'DESC']]
  });
}

async function upsertEmailOtpCode({ email, otp_code, expires_at }) {
  const existing = await models.EmailOtpCode.findOne({ where: { email }, paranoid: false });
  if (existing) {
    if (existing.deleted_at) {
      await existing.restore();
    }
    await existing.update({ otp_code, expires_at, deleted_at: null });
    return existing;
  }
  return models.EmailOtpCode.create({ email, otp_code, expires_at });
}

async function findEmailOtpCode(email) {
  return models.EmailOtpCode.findOne({ where: { email } });
}

async function deleteEmailOtpCode(email) {
  return models.EmailOtpCode.destroy({ where: { email }, force: true });
}

async function deleteExpiredEmailOtps() {
  return models.EmailOtpCode.destroy({ where: { expires_at: { [Op.lt]: new Date() } }, force: true });
}

module.exports = {
  findUserByEmail,
  createUser,
  createSession,
  findSessionByRefreshToken,
  deleteSessionByToken,
  findLatestSessionByUserId,
  upsertEmailOtpCode,
  findEmailOtpCode,
  deleteEmailOtpCode,
  deleteExpiredEmailOtps
};
