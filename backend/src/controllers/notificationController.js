const asyncHandler = require('../utils/asyncHandler');
const notificationService = require('../services/notificationService');

const listNotifications = asyncHandler(async (req, res) => {
  const data = await notificationService.listUserNotifications(req.user.id, req.query);
  res.json({ success: true, ...data });
});

const markRead = asyncHandler(async (req, res) => {
  const data = await notificationService.markRead(req.user.id, req.params.id);
  if (!data) return res.status(404).json({ success: false, message: 'Notification not found' });
  return res.json({ success: true, data });
});

const deleteOne = asyncHandler(async (req, res) => {
  const count = await notificationService.deleteOne(req.user.id, req.params.id);
  if (!count) return res.status(404).json({ success: false, message: 'Notification not found' });
  return res.json({ success: true, message: 'Notification deleted' });
});

const deleteAll = asyncHandler(async (req, res) => {
  const count = await notificationService.deleteAll(req.user.id);
  return res.json({ success: true, message: `${count} notifications deleted` });
});

module.exports = { listNotifications, markRead, deleteOne, deleteAll };
