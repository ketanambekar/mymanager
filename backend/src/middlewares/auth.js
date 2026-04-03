const jwt = require('jsonwebtoken');
const env = require('../config/env');
const models = require('../models');
const authRepository = require('../repositories/authRepository');

async function auth(req, res, next) {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    if (!token) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const payload = jwt.verify(token, env.jwt.secret);
    const session = await authRepository.findSessionByAccessToken(token);

    if (!session || String(session.user_id) !== String(payload.sub)) {
      return res.status(401).json({ success: false, message: 'Invalid session' });
    }

    if (new Date(session.expires_at).getTime() <= Date.now()) {
      await session.destroy();
      return res.status(401).json({ success: false, message: 'Session expired' });
    }

    const user = await models.User.findByPk(payload.sub);
    if (!user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }

    req.user = { id: user.id, role: user.role, email: user.email };
    req.token = token;
    next();
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Invalid token' });
  }
}

module.exports = auth;
