const jwt = require('jsonwebtoken');
const env = require('../config/env');

function createAccessToken(user) {
  return jwt.sign({ role: user.role, email: user.email }, env.jwt.secret, {
    subject: String(user.id),
    expiresIn: env.jwt.accessExpires
  });
}

function createRefreshToken(user) {
  return jwt.sign({ type: 'refresh' }, env.jwt.secret, {
    subject: String(user.id),
    expiresIn: env.jwt.refreshExpires
  });
}

module.exports = { createAccessToken, createRefreshToken };
