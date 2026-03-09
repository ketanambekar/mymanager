const jwt = require('jsonwebtoken');
const env = require('../config/env');
const models = require('../models');

async function auth(req, res, next) {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    if (!token) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const payload = jwt.verify(token, env.jwt.secret);
    const session = await models.Session.findOne({ where: { token, user_id: payload.sub } });

    if (!session) {
      return res.status(401).json({ success: false, message: 'Invalid session' });
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
