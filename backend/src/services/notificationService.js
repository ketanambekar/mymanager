const cache = require('../utils/cache');
const models = require('../models');
const notificationRepository = require('../repositories/notificationRepository');
const { getPagination, toPagedResponse } = require('../utils/pagination');

async function notify({ user_id, type, reference_id, transaction = null }) {
  const result = await notificationRepository.createNotification({ user_id, type, reference_id }, transaction);
  cache.del(`notifications:${user_id}`);
  return result;
}

async function listUserNotifications(userId, query) {
  const { page, limit, offset } = getPagination(query);
  const cacheKey = `notifications:${userId}:${page}:${limit}`;
  const cached = cache.get(cacheKey);
  if (cached) return cached;

  const result = await models.Notification.findAndCountAll({
    where: { user_id: userId },
    order: [['created_at', 'DESC']],
    limit,
    offset
  });

  const paged = toPagedResponse({ ...result, page, limit });
  cache.set(cacheKey, paged, 20);
  return paged;
}

async function markRead(userId, id) {
  const notification = await models.Notification.findOne({ where: { id, user_id: userId } });
  if (!notification) return null;
  await notification.update({ is_read: true });
  cache.del(`notifications:${userId}`);
  return notification;
}

async function deleteOne(userId, id) {
  const notification = await models.Notification.findOne({ where: { id, user_id: userId } });
  if (!notification) return 0;
  await notification.destroy();
  cache.del(`notifications:${userId}`);
  return 1;
}

async function deleteAll(userId) {
  const count = await models.Notification.destroy({ where: { user_id: userId } });
  cache.del(`notifications:${userId}`);
  return count;
}

module.exports = { notify, listUserNotifications, markRead, deleteOne, deleteAll };
