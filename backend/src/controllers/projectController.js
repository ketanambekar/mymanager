const asyncHandler = require('../utils/asyncHandler');
const projectService = require('../services/projectService');

const createProject = asyncHandler(async (req, res) => {
  const project = await projectService.createProject(req.body, req.user);
  res.status(201).json({ success: true, data: project });
});

const listProjects = asyncHandler(async (req, res) => {
  const data = await projectService.listProjects(req.user.id, req.query);
  res.json({ success: true, ...data });
});

const getProject = asyncHandler(async (req, res) => {
  const data = await projectService.getProjectById(req.params.id, req.user.id);
  res.json({ success: true, data });
});

const updateProject = asyncHandler(async (req, res) => {
  const data = await projectService.updateProject(req.params.id, req.body, req.user);
  res.json({ success: true, data });
});

const deleteProject = asyncHandler(async (req, res) => {
  await projectService.deleteProject(req.params.id, req.user);
  res.json({ success: true, message: 'Project deleted' });
});

const inviteMember = asyncHandler(async (req, res) => {
  const data = await projectService.inviteMember(req.params.id, req.body.email, req.user);
  res.status(201).json({ success: true, data });
});

const listMembers = asyncHandler(async (req, res) => {
  const data = await projectService.listProjectMembers(req.params.id, req.user.id);
  res.json({ success: true, data });
});

const listBoards = asyncHandler(async (req, res) => {
  const data = await projectService.listBoards(req.params.id, req.user.id);
  res.json({ success: true, data });
});

const reorderColumns = asyncHandler(async (req, res) => {
  const data = await projectService.reorderColumns(req.params.boardId, req.body.columns, req.user.id);
  res.json({ success: true, data });
});

module.exports = {
  createProject,
  listProjects,
  getProject,
  updateProject,
  deleteProject,
  inviteMember,
  listMembers,
  listBoards,
  reorderColumns
};
