const asyncHandler = require('../utils/asyncHandler');
const taskStatusService = require('../services/taskStatusService');

const listTaskStatuses = asyncHandler(async (req, res) => {
  const data = await taskStatusService.listTaskStatuses(req.user.id);
  res.json({ success: true, data });
});

const createTaskStatus = asyncHandler(async (req, res) => {
  const data = await taskStatusService.createTaskStatus(req.body, req.user);
  res.status(201).json({ success: true, data });
});

const updateTaskStatus = asyncHandler(async (req, res) => {
  const data = await taskStatusService.updateTaskStatus(req.params.id, req.body, req.user);
  res.json({ success: true, data });
});

const deleteTaskStatus = asyncHandler(async (req, res) => {
  await taskStatusService.deleteTaskStatus(req.params.id, req.user);
  res.json({ success: true, message: 'Task status deleted' });
});

module.exports = {
  listTaskStatuses,
  createTaskStatus,
  updateTaskStatus,
  deleteTaskStatus
};
