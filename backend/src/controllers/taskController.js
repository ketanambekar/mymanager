const fs = require('fs');
const asyncHandler = require('../utils/asyncHandler');
const taskService = require('../services/taskService');

const createTask = asyncHandler(async (req, res) => {
  const data = await taskService.createTask(req.body, req.user);
  res.status(201).json({ success: true, data });
});

const listTasks = asyncHandler(async (req, res) => {
  const data = await taskService.listTasks(req.query, req.user);
  res.json({ success: true, ...data });
});

const updateTask = asyncHandler(async (req, res) => {
  const data = await taskService.updateTask(req.params.id, req.body, req.user);
  res.json({ success: true, data });
});

const deleteTask = asyncHandler(async (req, res) => {
  await taskService.deleteTask(req.params.id, req.user);
  res.json({ success: true, message: 'Task deleted' });
});

const moveTask = asyncHandler(async (req, res) => {
  const data = await taskService.moveTask(req.params.id, req.body, req.user);
  res.json({ success: true, data });
});

const addComment = asyncHandler(async (req, res) => {
  const data = await taskService.addComment(req.params.id, req.body.comment, req.user);
  res.status(201).json({ success: true, data });
});

const listComments = asyncHandler(async (req, res) => {
  const data = await taskService.listComments(req.params.id, req.user);
  res.json({ success: true, data });
});

const updateComment = asyncHandler(async (req, res) => {
  const data = await taskService.updateComment(req.params.commentId, req.body.comment, req.user);
  res.json({ success: true, data });
});

const deleteComment = asyncHandler(async (req, res) => {
  await taskService.deleteComment(req.params.commentId, req.user);
  res.json({ success: true, message: 'Comment deleted' });
});

const uploadFile = asyncHandler(async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'File is required (field name: file)' });
  }
  const data = await taskService.uploadTaskFile(req.params.id, req.file, req.user);
  res.status(201).json({ success: true, data });
});

const deleteFile = asyncHandler(async (req, res) => {
  await taskService.deleteTaskFile(req.params.fileId, req.user);
  res.json({ success: true, message: 'File deleted' });
});

const downloadFile = asyncHandler(async (req, res) => {
  const data = await taskService.downloadTaskFile(req.params.fileId, req.user);
  if (!fs.existsSync(data.absPath)) {
    return res.status(404).json({ success: false, message: 'File missing on disk' });
  }
  return res.download(data.absPath, data.file.original_name);
});

module.exports = {
  createTask,
  listTasks,
  updateTask,
  deleteTask,
  moveTask,
  addComment,
  listComments,
  updateComment,
  deleteComment,
  uploadFile,
  deleteFile,
  downloadFile
};
