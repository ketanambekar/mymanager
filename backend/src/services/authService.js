const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const createError = require('http-errors');

const env = require('../config/env');
const models = require('../models');
const authRepository = require('../repositories/authRepository');
const { createAccessToken, createRefreshToken } = require('../utils/jwt');
const { toMilliseconds } = require('../utils/time');

function createOtpCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

async function issueSession(user) {
  const accessToken = createAccessToken(user);
  const refreshToken = createRefreshToken(user);

  await authRepository.createSession({
    user_id: user.id,
    token: accessToken,
    refresh_token: refreshToken,
    expires_at: new Date(Date.now() + toMilliseconds(env.jwt.refreshExpires))
  });

  return {
    user: { id: user.id, name: user.name, email: user.email, role: user.role },
    access_token: accessToken,
    refresh_token: refreshToken
  };
}

async function register({ name, email, password }) {
  const existing = await authRepository.findUserByEmail(email);
  if (existing) throw createError(409, 'Email already registered');

  const password_hash = await bcrypt.hash(password, 12);
  const tx = await models.sequelize.transaction();

  try {
    const user = await authRepository.createUser({ name, email, password_hash, role: 'member' }, tx);
    await tx.commit();
    return { id: user.id, name: user.name, email: user.email, role: user.role };
  } catch (error) {
    await tx.rollback();
    throw error;
  }
}

async function login({ email, password }) {
  const user = await authRepository.findUserByEmail(email);
  if (!user) throw createError(401, 'Invalid credentials');

  const ok = await bcrypt.compare(password, user.password_hash);
  if (!ok) throw createError(401, 'Invalid credentials');

  return issueSession(user);
}

async function requestEmailOtp({ email }) {
  await authRepository.deleteExpiredEmailOtps();

  const normalizedEmail = email.toLowerCase();
  const user = await authRepository.findUserByEmail(normalizedEmail);
  const otp = createOtpCode();
  const expiresAt = Date.now() + 5 * 60 * 1000;

  await authRepository.upsertEmailOtpCode({
    email: normalizedEmail,
    otp_code: otp,
    expires_at: new Date(expiresAt)
  });

  return {
    email: normalizedEmail,
    is_existing_user: Boolean(user),
    otp,
    otp_expires_in_seconds: 300,
    message: 'Dummy OTP generated. Display only for development.'
  };
}

async function verifyEmailOtp({ email, otp, name }) {
  const normalizedEmail = email.toLowerCase();
  const entry = await authRepository.findEmailOtpCode(normalizedEmail);
  if (!entry) throw createError(400, 'OTP not requested for this email');
  if (Date.now() > new Date(entry.expires_at).getTime()) {
    await authRepository.deleteEmailOtpCode(normalizedEmail);
    throw createError(400, 'OTP expired');
  }
  if (entry.otp_code !== otp) throw createError(400, 'Invalid OTP');

  let user = await authRepository.findUserByEmail(normalizedEmail);
  let isNewUser = false;

  if (!user) {
    const generatedName = (name || normalizedEmail.split('@')[0] || 'User').trim();
    const passwordHash = await bcrypt.hash(crypto.randomBytes(24).toString('hex'), 12);
    user = await authRepository.createUser({
      name: generatedName,
      email: normalizedEmail,
      password_hash: passwordHash,
      role: 'member'
    });
    isNewUser = true;
  } else if (name && !user.name) {
    await user.update({ name: name.trim() });
  }

  await authRepository.deleteEmailOtpCode(normalizedEmail);
  const session = await issueSession(user);
  return { ...session, is_new_user: isNewUser };
}

async function refreshToken(refreshToken) {
  if (!refreshToken) throw createError(401, 'Refresh token required');

  const payload = jwt.verify(refreshToken, env.jwt.secret);
  const session = await authRepository.findSessionByRefreshToken(refreshToken);
  if (!session || String(session.user_id) !== String(payload.sub)) {
    throw createError(401, 'Invalid refresh token');
  }

  const user = await models.User.findByPk(payload.sub);
  if (!user) throw createError(401, 'Invalid user');

  const accessToken = createAccessToken(user);
  const newRefresh = createRefreshToken(user);

  await session.update({
    token: accessToken,
    refresh_token: newRefresh,
    expires_at: new Date(Date.now() + toMilliseconds(env.jwt.refreshExpires))
  });

  return { access_token: accessToken, refresh_token: newRefresh };
}

async function logout(token) {
  if (!token) return;
  await authRepository.deleteSessionByToken(token);
}

async function me(userId) {
  const user = await models.User.findByPk(userId);
  if (!user) throw createError(404, 'User not found');

  const latestSession = await authRepository.findLatestSessionByUserId(userId);
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role,
    created_at: user.created_at,
    last_active_at: latestSession?.updated_at || user.updated_at
  };
}

module.exports = {
  register,
  login,
  requestEmailOtp,
  verifyEmailOtp,
  refreshToken,
  logout,
  me
};
